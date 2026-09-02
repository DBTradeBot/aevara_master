// functions/core/anchors.js
// Anchors & model config loaders (robust + cached) + slow-anchors contribution helpers
// Node 20 / ESM / Firebase Functions v2

import { db } from "./firebase_admin.js";
import {
  round, clamp, clamp01, normalizeUnits, memoizeTtl,
  valueToPercentile,
} from "./ddc_utils.js";

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Cache TTLs â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
const MODEL_TTL  = 10 * 60 * 1000; // 10 min
const ANCHOR_TTL =  5 * 60 * 1000; // 5 min

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Baseline VA EMA (user-level) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
const BASELINE_VA_EMA_ALPHA      = 0.15; // ~15% / refresh (monthly)
const BASELINE_VA_EMA_MIN_DAYS   = 28;   // at least ~monthly
const BASELINE_VA_MAX_STEP       = 0.7;  // max |Î"| per refresh (years)

const INITIAL_BASELINE_MIN_VALID = 21;   // need â‰¥21 VA days
const INITIAL_BASELINE_WINDOW    = 30;   // earliest 30 â†' median

const RECENT_MEDIAN_LOOKBACK     = 90;   // up to 90 most-recent day docs
const RECENT_MEDIAN_MIN_VALID    = 21;   // need â‰¥21 VA days

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Model config loader â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */

export async function loadModelConfig(modelVersion = "v1") {
  return memoizeTtl("modelConfig", modelVersion, MODEL_TTL, async () => {
    try {
      const ref = db.doc(`reference/config/models_${modelVersion}`);
      const snap = await ref.get();
      if (snap.exists) return normalizeModelConfig(snap.data() || {});
      const single = await db.doc("reference/config/models").get();
      if (single.exists) {
        const obj = single.data() || {};
        return normalizeModelConfig(obj?.[modelVersion] || obj?.default || {});
      }
    } catch (e) {}
    // Safe defaults
    return normalizeModelConfig({
      version: "v1",
      scale_years: 12,              // tighter scale to reduce "age inflation"
      pivot_risk: 0.22,
      groups: { recovery: 0.35, sleep: 0.30, activity: 0.20, affect: 0.15 },
      caps: { daily_va_abs: 1.0, total_va_abs: 10 },
      change_cooldown_sec: 0,
      flags: {
        sex_norms_enabled: true,
        slow_anchors_enabled: true,
        crf_enabled: true,
        baseline_va_ema_enabled: true,
      },
      // Slow anchors default blend weights (sum â‰¤ 0.35 recommended).
      weights_anchors: { body_comp: 0.08, bp: 0.08, glucose: 0.08 },
      // Cardiorespiratory fitness (VO2max / fitness-age) additional weight
      weights_crf: 0.15,
      // Target values for anchors (in medical-ish reasonable ranges)
      anchors_targets: {
        // Body comp derived
        bmi_opt: 22.0,         // kg/m^2
        whtr_opt: 0.45,        // waist-to-height
        // Blood pressure
        bp_sys_opt: 110,       // systolic
        bp_dia_opt: 70,        // diastolic
        // Glucose surrogate
        hba1c_opt: 5.2,        // %
        fasting_glucose_opt_mmol: 4.9,
        // VO2max (sex-aware handled separately)
        vo2max_opt_male: 45,
        vo2max_opt_female: 38,
      },
    });
  });
}

function normalizeModelConfig(cfg) {
  const v = String(cfg?.version || "v1");
  const scale_years = Number(cfg?.scale_years ?? 12) || 12;
  const pivot_risk = Number(cfg?.pivot_risk ?? 0.22) || 0.22;
  const groups = {
    recovery: Number(cfg?.groups?.recovery ?? 0.35),
    sleep:    Number(cfg?.groups?.sleep    ?? 0.30),
    activity: Number(cfg?.groups?.activity ?? 0.20),
    affect:   Number(cfg?.groups?.affect   ?? 0.15),
  };
  const caps = {
    daily_va_abs: Number(cfg?.caps?.daily_va_abs ?? 1.0),
    total_va_abs: Number(cfg?.caps?.total_va_abs ?? 10),
  };
  const change_cooldown_sec = Number(cfg?.change_cooldown_sec ?? 0) || 0;

  const flagsRaw = cfg?.flags || {};
  const flags = {
    sex_norms_enabled:      !!flagsRaw.sex_norms_enabled,
    slow_anchors_enabled:   !!flagsRaw.slow_anchors_enabled,
    crf_enabled:            !!flagsRaw.crf_enabled,
    baseline_va_ema_enabled: (flagsRaw.baseline_va_ema_enabled === undefined) ? true : !!flagsRaw.baseline_va_ema_enabled,
  };

  const weights_anchors = {
    body_comp: Number(cfg?.weights_anchors?.body_comp ?? 0.08),
    bp:        Number(cfg?.weights_anchors?.bp        ?? 0.08),
    glucose:   Number(cfg?.weights_anchors?.glucose   ?? 0.08),
  };
  const weights_crf = Number(cfg?.weights_crf ?? 0.15);

  const anchors_targets = {
    bmi_opt:                 Number(cfg?.anchors_targets?.bmi_opt ?? 22.0),
    whtr_opt:                Number(cfg?.anchors_targets?.whtr_opt ?? 0.45),
    bp_sys_opt:              Number(cfg?.anchors_targets?.bp_sys_opt ?? 110),
    bp_dia_opt:              Number(cfg?.anchors_targets?.bp_dia_opt ?? 70),
    hba1c_opt:               Number(cfg?.anchors_targets?.hba1c_opt ?? 5.2),
    fasting_glucose_opt_mmol:Number(cfg?.anchors_targets?.fasting_glucose_opt_mmol ?? 4.9),
    vo2max_opt_male:         Number(cfg?.anchors_targets?.vo2max_opt_male ?? 45),
    vo2max_opt_female:       Number(cfg?.anchors_targets?.vo2max_opt_female ?? 38),
  };

  return { version: v, scale_years, pivot_risk, groups, caps, change_cooldown_sec, flags, weights_anchors, weights_crf, anchors_targets };
}

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Anchors loader (+ baseline VA EMA) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */

function computeAgeYearsFromDobIso(dobIso, now = new Date()) {
  if (!dobIso) return null;
  const dob = new Date(dobIso);
  if (!Number.isFinite(dob.getTime())) return null;
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const mNow = now.getUTCMonth(), dNow = now.getUTCDate();
  const mDob = dob.getUTCMonth(), dDob = dob.getUTCDate();
  if (mNow < mDob || (mNow === mDob && dNow < dDob)) age -= 1;
  return age;
}

function toIso(x) {
  if (!x) return null;
  if (typeof x === "string") return x;
  if (x?.toDate) return x.toDate().toISOString();
  if (Number.isFinite(x?.seconds)) return new Date(x.seconds * 1000).toISOString();
  try { return new Date(x).toISOString(); } catch (e) { return null; }
}

function daysBetweenUtc(isoA, isoB) {
  try {
    const a = new Date(isoA).getTime();
    const b = new Date(isoB).getTime();
    if (!Number.isFinite(a) || !Number.isFinite(b)) return 0;
    return Math.floor((b - a) / 86400000);
  } catch (e) { return 0; }
}

function median(xs = []) {
  const arr = xs.filter((n) => Number.isFinite(n)).sort((a,b)=>a-b);
  if (!arr.length) return null;
  const m = Math.floor(arr.length / 2);
  return (arr.length % 2) ? arr[m] : (arr[m - 1] + arr[m]) / 2;
}

export async function loadAnchors(uid) {
  if (!uid) throw new Error("loadAnchors: missing uid");

  return memoizeTtl("anchors", uid, ANCHOR_TTL, async () => {
    const userRef = db.doc(`users/${uid}`);
    const userSnap = await userRef.get();
    const u = userSnap.exists ? (userSnap.data() || {}) : {};

    // Sex/gender
    const sexRaw = (u.sex ?? u.gender ?? "").toString().toLowerCase();
    const sex =
      sexRaw === "male" || sexRaw === "m" ? "male" :
      sexRaw === "female" || sexRaw === "f" ? "female" : "unknown";

    // DOB â†' age
    let dobIso = null;
    if (u.dob) {
      if (typeof u.dob === "string") dobIso = u.dob;
      else if (u.dob?.toDate) dobIso = u.dob.toDate().toISOString();
    } else if (u.birthdate) {
      dobIso = String(u.birthdate);
    }
    const age_years = computeAgeYearsFromDobIso(dobIso);

    // Height/weight normalization + waist
    const nu = normalizeUnits({
      height_cm: u.height_cm ?? u.height ?? null,
      weight_kg: u.weight_kg ?? u.weight ?? null
    });
    const height_cm = nu.height_cm ?? null;
    const weight_kg = nu.weight_kg ?? null;

    let waist_cm = null;
    if (u.waist_cm != null && Number.isFinite(Number(u.waist_cm))) {
      waist_cm = round(Number(u.waist_cm), 1);
    } else if (u.waist_in != null && Number.isFinite(Number(u.waist_in))) {
      waist_cm = round(Number(u.waist_in) * 2.54, 1);
    }

    // Latest BP
    let bp = null;
    try {
      const bpSnap = await db.collection(`users/${uid}/biometrics_bp`).orderBy("measured_at_utc","desc").limit(1).get();
      if (!bpSnap.empty) {
        const d = bpSnap.docs[0].data() || {};
        const sys = d.systolic ?? d.sys ?? null;
        const dia = d.diastolic ?? d.dia ?? null;
        if (Number.isFinite(Number(sys)) && Number.isFinite(Number(dia))) bp = { sys: Number(sys), dia: Number(dia) };
      }
    } catch (e) {}

    // Latest glucose
    let glucose = null;
    try {
      const gSnap = await db.collection(`users/${uid}/biometrics_glucose`).orderBy("measured_at_utc","desc").limit(1).get();
      if (!gSnap.empty) {
        const d = gSnap.docs[0].data() || {};
        if (d.hba1c_pct != null && Number.isFinite(Number(d.hba1c_pct))) {
          glucose = { hba1c_pct: Number(d.hba1c_pct) };
        } else if (d.value != null) {
          const unit = (d.unit || "").toLowerCase();
          let fasting_mmol_L = null;
          if (unit === "mmol_l" || unit === "mmol/l") fasting_mmol_L = Number(d.value);
          else if (unit === "mg_dl" || unit === "mg/dl") fasting_mmol_L = Number(d.value) * 0.0555;
          if (Number.isFinite(fasting_mmol_L)) glucose = { fasting_mmol_L: Number(fasting_mmol_L.toFixed(2)) };
        }
      }
    } catch (e) {}

    // VO2max / Fitness age (recent days)
    let vo2max_ml_kg_min = null, fitness_age_years = null;
    try {
      const daysCol = db.collection(`users/${uid}/days`);
      const snap = await daysCol.orderBy("__name__", "desc").limit(45).get();
      for (const doc of snap.docs) {
        const d = doc.data() || {};
        if (vo2max_ml_kg_min == null && Number.isFinite(Number(d.vo2max_ml_kg_min))) vo2max_ml_kg_min = Number(d.vo2max_ml_kg_min);
        if (fitness_age_years == null && Number.isFinite(Number(d.fitness_age_years))) fitness_age_years = Number(d.fitness_age_years);
        if (vo2max_ml_kg_min != null && fitness_age_years != null) break;
      }
    } catch (e) {}

    // Persist baseline chrono once
    const needsBaselineChrono =
      Number.isFinite(Number(age_years)) &&
      (u.baseline_age_years == null || !Number.isFinite(Number(u.baseline_age_years)));
    if (needsBaselineChrono) {
      try {
        await userRef.set(
          { baseline_age_years: Number(age_years), baseline_started_at_utc: new Date().toISOString() },
          { merge: true }
        );
      } catch (e) {}
    }

    // Baseline vitality age (median of earliest 30 valid)
    let baseline_vitality_age_years =
      Number.isFinite(Number(u.baseline_vitality_age_years)) ? Number(u.baseline_vitality_age_years) : null;

    if (baseline_vitality_age_years == null) {
      try {
        const earlySnap = await db
          .collection(`users/${uid}/days`)
          .orderBy("__name__")
          .limit(INITIAL_BASELINE_WINDOW + 10)
          .get();

        const vaVals = earlySnap.docs
          .map(d => Number((d.data() || {}).vitality_age))
          .filter(n => Number.isFinite(n));
        const firstWindow = vaVals.slice(0, INITIAL_BASELINE_WINDOW);

        if (firstWindow.length >= INITIAL_BASELINE_MIN_VALID) {
          const m = median(firstWindow);
          if (Number.isFinite(m)) {
            baseline_vitality_age_years = round(m, 1);
            await userRef.set(
              {
                baseline_vitality_age_years,
                baseline_va_ema_refreshed_at_utc: new Date().toISOString(),
              },
              { merge: true }
            );
          }
        }
      } catch (e) {}
    }

    // Monthly EMA refresh toward recent median (guarded)
    const cfg = await loadModelConfig("v1").catch(() => ({ flags: { baseline_va_ema_enabled: true } }));
    const emaEnabled = !!cfg?.flags?.baseline_va_ema_enabled;

    if (emaEnabled && Number.isFinite(Number(baseline_vitality_age_years))) {
      const lastRefreshIso = u.baseline_va_ema_refreshed_at_utc ? toIso(u.baseline_va_ema_refreshed_at_utc) : null;
      const daysSinceRefresh = lastRefreshIso ? daysBetweenUtc(lastRefreshIso, new Date().toISOString()) : Infinity;

      if (daysSinceRefresh >= BASELINE_VA_EMA_MIN_DAYS) {
        try {
          const recentSnap = await db
            .collection(`users/${uid}/days`)
            .orderBy("__name__", "desc")
            .limit(RECENT_MEDIAN_LOOKBACK)
            .get();

          const vaRecent = recentSnap.docs
            .map(d => Number((d.data() || {}).vitality_age))
            .filter(n => Number.isFinite(n));

          if (vaRecent.length >= RECENT_MEDIAN_MIN_VALID) {
            const target = median(vaRecent);
            if (Number.isFinite(target)) {
              const oldBase = Number(baseline_vitality_age_years);
              const rawEma = (1 - BASELINE_VA_EMA_ALPHA) * oldBase + BASELINE_VA_EMA_ALPHA * target;
              const delta = clamp(rawEma - oldBase, -BASELINE_VA_MAX_STEP, BASELINE_VA_MAX_STEP);
              const newBase = round(oldBase + delta, 1);

              if (Number.isFinite(newBase) && newBase !== oldBase) {
                baseline_vitality_age_years = newBase;
                await userRef.set(
                  {
                    baseline_vitality_age_years: newBase,
                    baseline_va_ema_refreshed_at_utc: new Date().toISOString(),
                    baseline_va_ema_meta: {
                      alpha: BASELINE_VA_EMA_ALPHA,
                      target_recent_median: round(target, 2),
                      delta_applied: round(delta, 2),
                      lookback_days: RECENT_MEDIAN_LOOKBACK,
                      min_valid_days: RECENT_MEDIAN_MIN_VALID,
                    },
                  },
                  { merge: true }
                );
              } else if (!lastRefreshIso) {
                await userRef.set(
                  { baseline_va_ema_refreshed_at_utc: new Date().toISOString() },
                  { merge: true }
                );
              }
            }
          }
        } catch (e) {}
      }
    }

    // Derived body-comp metrics (for contributions)
    const bmi = (Number.isFinite(Number(weight_kg)) && Number.isFinite(Number(height_cm)) && height_cm > 0)
      ? round(Number(weight_kg) / Math.pow(Number(height_cm) / 100, 2), 1)
      : null;

    const whtr = (Number.isFinite(Number(waist_cm)) && Number.isFinite(Number(height_cm)) && height_cm > 0)
      ? round(Number(waist_cm) / Number(height_cm), 3)
      : null;

    return {
      anchors_version: "a3", // bump
      sex,
      dob: dobIso,
      age_years,
      height_cm,
      weight_kg,
      waist_cm,
      bmi,
      whtr,
      baseline_age_years: Number.isFinite(Number(u.baseline_age_years)) ? Number(u.baseline_age_years) : (age_years ?? null),
      baseline_vitality_age_years: Number.isFinite(Number(baseline_vitality_age_years)) ? Number(baseline_vitality_age_years) : null,
      baseline_started_at_utc: u.baseline_started_at_utc ?? null,
      bp,         // { sys, dia } or null
      glucose,    // { hba1c_pct } or { fasting_mmol_L } or null
      extras: {
        ...(Number.isFinite(vo2max_ml_kg_min) ? { vo2max_ml_kg_min } : {}),
        ...(Number.isFinite(fitness_age_years) ? { fitness_age_years } : {}),
      },
    };
  });
}

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Slow-anchors â†' risk contribution (0..1) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
   This *does not* penalize missing data. If a sub-anchor is missing,
   it simply contributes 0 weight to the anchors blend (i.e., neutral).
*/
export function computeSlowAnchorsContrib(anchors, cfg) {
  const flags   = cfg?.flags || {};
  const wA      = cfg?.weights_anchors || { body_comp: 0.08, bp: 0.08, glucose: 0.08 };
  const wCrf    = Number(cfg?.weights_crf ?? 0.15);
  const targets = cfg?.anchors_targets || {};

  const out = {
    body_comp: { score: null, weight: 0, details: {} },
    bp:        { score: null, weight: 0, details: {} },
    glucose:   { score: null, weight: 0, details: {} },
    crf:       { score: null, weight: 0, details: {} },
    blended:   { risk: 0, weight_sum: 0 },
  };

  // Helper: convert "goodness" to risk (1 - pct)
  const toRisk = (goodPct) => (goodPct == null ? null : clamp01(1 - clamp01(goodPct)));

  /* Body composition: BMI + WHtR â†' simple average goodness */
  if (flags.slow_anchors_enabled) {
    const bmiPct  = Number.isFinite(Number(anchors?.bmi))
      ? clamp01(1 - Math.abs(Number(anchors.bmi) - Number(targets.bmi_opt ?? 22)) / 10) // ~Â±10 as soft band
      : null;
    const whtrPct = Number.isFinite(Number(anchors?.whtr))
      ? clamp01(1 - Math.abs(Number(anchors.whtr) - Number(targets.whtr_opt ?? 0.45)) / 0.15) // ~Â±0.15 band
      : null;

    const goods = [bmiPct, whtrPct].filter((x) => x != null);
    if (goods.length) {
      const good = goods.reduce((a,b)=>a+b,0) / goods.length;
      out.body_comp.score  = toRisk(good);
      out.body_comp.weight = Number(wA.body_comp || 0);
      out.body_comp.details = { bmi: anchors?.bmi ?? null, bmiPct, whtr: anchors?.whtr ?? null, whtrPct };
    }
  }

  /* Blood pressure: closer to (sys, dia) targets is better */
  if (flags.slow_anchors_enabled && anchors?.bp?.sys != null && anchors?.bp?.dia != null) {
    const sysT = Number(targets.bp_sys_opt ?? 110);
    const diaT = Number(targets.bp_dia_opt ?? 70);

    const sysGood = clamp01(1 - Math.abs(Number(anchors.bp.sys) - sysT) / 25); // Â±25 mmHg band
    const diaGood = clamp01(1 - Math.abs(Number(anchors.bp.dia) - diaT) / 15); // Â±15 mmHg band
    const good = (sysGood + diaGood) / 2;

    out.bp.score  = toRisk(good);
    out.bp.weight = Number(wA.bp || 0);
    out.bp.details = { sys: anchors.bp.sys, dia: anchors.bp.dia, sysGood, diaGood };
  }

  /* Glucose: prefer A1c if available; else fasting glucose */
  if (flags.slow_anchors_enabled) {
    let good = null;
    if (anchors?.glucose?.hba1c_pct != null) {
      const tgt = Number(targets.hba1c_opt ?? 5.2);
      good = clamp01(1 - Math.abs(Number(anchors.glucose.hba1c_pct) - tgt) / 1.0); // Â±1.0% band
    } else if (anchors?.glucose?.fasting_mmol_L != null) {
      const tgt = Number(targets.fasting_glucose_opt_mmol ?? 4.9);
      good = clamp01(1 - Math.abs(Number(anchors.glucose.fasting_mmol_L) - tgt) / 1.3); // Â±1.3 mmol/L band
    }
    if (good != null) {
      out.glucose.score  = toRisk(good);
      out.glucose.weight = Number(wA.glucose || 0);
      out.glucose.details = { ...anchors.glucose, good };
    }
  }

  /* CRF: VO2max preferred; fallback to fitness-age vs chrono-age delta */
  if (flags.crf_enabled) {
    let good = null;
    if (Number.isFinite(Number(anchors?.extras?.vo2max_ml_kg_min))) {
      const v = Number(anchors.extras.vo2max_ml_kg_min);
      const target = String(anchors?.sex) === "female" ? Number(cfg?.anchors_targets?.vo2max_opt_female ?? 38)
                                                       : Number(cfg?.anchors_targets?.vo2max_opt_male   ?? 45);
      // map VO2max to (0..1) goodness with gentle banding
      good = clamp01((v - (target - 10)) / 15); // target-10 .. target+5
      out.crf.details = { vo2max_ml_kg_min: v, target };
    } else if (Number.isFinite(Number(anchors?.extras?.fitness_age_years)) && Number.isFinite(Number(anchors?.age_years))) {
      const delta = Number(anchors.extras.fitness_age_years) - Number(anchors.age_years); // negative is better
      good = clamp01(1 - clamp01((delta + 10) / 20)); // map [-10..+10] years roughly
      out.crf.details = { fitness_age_years: anchors.extras.fitness_age_years, chrono_age: anchors.age_years };
    }
    if (good != null) {
      out.crf.score  = toRisk(good);
      out.crf.weight = Number(wCrf || 0);
    }
  }

  // Blend available components (missing parts simply contribute 0 weight)
  const parts = [out.body_comp, out.bp, out.glucose, out.crf].filter(Boolean);
  const weightSum = parts.reduce((s,p)=> s + (Number(p.weight) || 0), 0);
  const risk = weightSum > 0
    ? clamp01(parts.reduce((s,p)=> s + (Number(p.score ?? 0) * Number(p.weight || 0)), 0) / weightSum)
    : 0;

  out.blended.risk = risk;
  out.blended.weight_sum = round(weightSum, 4);
  return out;
}



