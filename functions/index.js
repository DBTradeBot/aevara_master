/**
 * Vitalis backend – Node 20 / Gen 2 / ESM
 * Future-proof scoring:
 *  - Domains: Recovery(HRV+RHR), Sleep(Duration±Regularity), Activity(Steps, saturating),
 *             Wellbeing(1–5; 5=bad), optional CRF(VO2max/FitnessAge)
 *  - Dynamic config (models/v1): weights, pivot, scale, dynamic_span, daily caps
 *  - EMA + staleness + confidence; 30d healthy days
 *  - Transparent outputs: wused.*, constants.*, score_* fields
 *  - Social/community, leaderboards, normalization triggers preserved
 */

import { onRequest, onCall } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";

// ✅ Guarded Admin init
import { initializeApp, applicationDefault, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue, FieldPath } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

if (!getApps().length) {
  initializeApp({ credential: applicationDefault() });
}
const db = getFirestore();

// Ensure Fitbit endpoints are exported so deploy analyzer sees them
export * from "./fitbit_oauth.js";



/* ========================= Shared helpers ========================= */

const round = (n, d = 2) => (typeof n === "number" ? Number(n.toFixed(d)) : n);
const pad2 = (n) => String(n).padStart(2, "0");
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const clamp01 = (x) => clamp(x, 0, 1);

// Dates / TZ
const DEFAULT_TZ = "America/Los_Angeles";
function todayKeyInTZ(tz = DEFAULT_TZ) {
  const now = new Date();
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(now).reduce((acc, p) => ((acc[p.type] = p.value), acc), {});
  return `${parts.year}-${parts.month}-${parts.day}`;
}

// EMA & staleness
const EMA_DECAY = 0.7;
const STALE_DAY_THRESHOLD1 = 1;
const STALE_DAY_THRESHOLD2 = 3;
const STALE_DAY_THRESHOLD3 = 4;

function calcEMA(prev, curr) {
  if (prev == null) return curr == null ? null : Number(curr);
  if (curr == null) return Number(prev);
  return EMA_DECAY * Number(curr) + (1 - EMA_DECAY) * Number(prev);
}
function stalenessPenalty(staleDays) {
  if (staleDays == null) return 0;
  if (staleDays <= STALE_DAY_THRESHOLD1) return 0;
  if (staleDays <= STALE_DAY_THRESHOLD2) return 0.1;
  if (staleDays >= STALE_DAY_THRESHOLD3) return 0.25;
  return 0.25;
}
function reCalcConfidence(weightsObservedFrac, staleMap = {}) {
  const keys = Object.keys(staleMap);
  const avgPenalty = keys.length === 0 ? 0
    : keys.reduce((s, k) => s + stalenessPenalty(staleMap[k]), 0) / keys.length;
  return Math.round(clamp01(weightsObservedFrac) * (1 - avgPenalty) * 100);
}

// Health window
function healthyDaysFromWindow(docs) {
  let healthy = 0;
  for (const d of docs) {
    const r = d?.risk_index;
    if (typeof r === "number") healthy += r < 0.5 ? 1 : 0;
    else if (d?.score?.recovery != null) healthy += d.score.recovery >= 70 ? 1 : 0;
  }
  return healthy;
}

// Inputs tracking (backward-compat included)
const RAW_INPUT_KEYS = [
  // core daily
  "sleep_total_hours", "steps_count", "hrv_rmssd_ms", "rhr_bpm",
  // legacy affect inputs
  "stress_level_1to5", "mood_level_1to5", "energy_level_1to5",
  // new single wellbeing + extras
  "wellbeing_level_1to5",
  "sleep_regularity_pct",         // 0–100; optional
  "vo2max_ml_kg_min",             // optional slow-moving
  "fitness_age_years",            // optional vendor-provided
];

// shallow pick
function shallowPick(obj, keys) {
  const out = {};
  for (const k of keys) if (obj?.[k] !== undefined) out[k] = obj[k];
  return out;
}
function inputsChanged(prevDoc, nextInputs) {
  for (const k of RAW_INPUT_KEYS) {
    const a = prevDoc?.[k];
    const b = nextInputs?.[k];
    if (a !== undefined || b !== undefined) if (a !== b) return true;
  }
  return false;
}

// small math helpers
const logistic01 = (x, mid, slope) => 1 / (1 + Math.exp(-(x - mid) / slope)); // 0..1
const sleepDurationUCurve01 = (h) => clamp01(1 - Math.pow((h - 7.5) / 2.5, 2)); // vertex 7.5h

// age from DOB (YYYY-MM-DD or ISO)
function ageFromDob(dob) {
  if (!dob) return null;
  const d = new Date(dob);
  if (isNaN(d)) return null;
  const now = new Date();
  let a = now.getUTCFullYear() - d.getUTCFullYear();
  const m = now.getUTCMonth() - d.getUTCMonth();
  if (m < 0 || (m === 0 && now.getUTCDate() < d.getUTCDate())) a--;
  return a;
}

// percentiles util
function percentile(sortedNums, p01to99) {
  if (!sortedNums?.length) return null;
  const idx = clamp((p01to99 / 100) * (sortedNums.length - 1), 0, sortedNums.length - 1);
  const lo = Math.floor(idx), hi = Math.ceil(idx);
  if (lo === hi) return sortedNums[lo];
  const frac = idx - lo;
  return sortedNums[lo] * (1 - frac) + sortedNums[hi] * frac;
}

/* ========================= Scoring core ========================= */

// Load model config (weights/pivot/scale/flags); trivial cache
let _modelCache = null;
let _modelCacheAt = 0;
async function loadModelConfig() {
  const FRESH_MS = 60_000; // 1m cache
  const now = Date.now();
  if (_modelCache && now - _modelCacheAt < FRESH_MS) return _modelCache;
  const snap = await db.doc("models/v1").get();
  _modelCache = snap.exists ? (snap.data() || {}) : {};
  _modelCacheAt = now;
  return _modelCache;
}

function computeScores(snapshot, options) {
  const s = snapshot || {};
  const {
    model = {},
    ageYears: ageDefault = 35,
    dynamic = {},
  } = options || {};

  // ---- Domain scoring ----

  // Recovery: HRV up (clamped), RHR down (clamped). Simple robust map; future: age/sex norms.
  const recovery = (() => {
    const rawHRV = Number(s.hrv_rmssd_ms ?? s?.ema7?.hrv_rmssd_ms ?? 30);
    const rawRHR = Number(s.rhr_bpm ?? s?.ema7?.rhr_bpm ?? 70);
    const hrv = clamp(rawHRV, 15, 200);
    const rhr = clamp(rawRHR, 35, 110);
    // HRV: map ~20→0 … ~80→1 (with clamp); RHR: ~45→1 … ~85→0 (with clamp)
    const hrvScore01 = clamp01((hrv - 20) / (80 - 20));
    const rhrScore01 = 1 - clamp01((rhr - 45) / (85 - 45));
    return Math.round((0.6 * hrvScore01 + 0.4 * rhrScore01) * 100);
  })();

  // Sleep: duration U-curve + optional regularity (70:30)
  const sleep = (() => {
    const h = Number(s.sleep_total_hours ?? s?.ema7?.sleep_total_hours ?? 7.5);
    const dur01 = sleepDurationUCurve01(h);
    let score01 = dur01;
    const regularityPct = s.sleep_regularity_pct;
    if (regularityPct != null && !Number.isNaN(Number(regularityPct))) {
      const reg01 = clamp01(Number(regularityPct) / 100);
      score01 = clamp01(0.7 * dur01 + 0.3 * reg01);
    }
    return Math.round(score01 * 100);
  })();

  // Activity: steps saturating logistic; mid ≈ 7.5k, slope ≈ 1.5k
  const activity = (() => {
    const steps = Number(s.steps_count ?? s?.ema7?.steps_count ?? 6000);
    const sc01 = logistic01(steps, 7500, 1500); // 50 @ 7.5k; ~73 @ 9k; ~88 @ 11k
    return Math.round(sc01 * 100);
  })();

  // Wellbeing: single 1–5 where 5 = bad. Convex penalty toward bad end.
  // Back-compat: if wellbeing not present, derive from mood (1–5; high=good) + stress (1–5; low=good).
  const wellbeing = (() => {
    const wb = s.wellbeing_level_1to5;
    if (wb != null) {
      const v = clamp(Number(wb), 1, 5);
      // map: 1→100, 2→85, 3→70, 4→45, 5→20
      const table = { 1: 100, 2: 85, 3: 70, 4: 45, 5: 20 };
      return table[v] ?? Math.round(clamp01(1 - (v - 1) / 4) ** 1.3 * 100);
    }
    // fallback from mood+stress if present
    const mood = Number(s.mood_level_1to5 ?? s?.ema7?.mood_level_1to5 ?? 3);     // higher is better
    const stress = Number(s.stress_level_1to5 ?? s?.ema7?.stress_level_1to5 ?? 3); // lower is better
    const mood01 = clamp01((mood - 1) / 4);
    const stress01 = 1 - clamp01((stress - 1) / 4);
    return Math.round((0.6 * mood01 + 0.4 * stress01) * 100);
  })();

  // CRF (optional): prefer VO2max if present; else fitness_age vs chrono
  const ageYears = Number(s.profile_age_years ?? ageDefault);
  let crf = null;
  const vo2 = s.vo2max_ml_kg_min ?? s?.ema7?.vo2max_ml_kg_min;
  const fitAge = s.fitness_age_years ?? s?.ema7?.fitness_age_years;
  if (vo2 != null && !Number.isNaN(Number(vo2))) {
    const minV = Number(model?.crf?.min_vo2 ?? 20);
    const maxV = Number(model?.crf?.max_vo2 ?? 55);
    const vo2Clamped = clamp(Number(vo2), minV, maxV);
    const sc01 = clamp01((vo2Clamped - minV) / (maxV - minV));
    crf = Math.round(sc01 * 100);
  } else if (fitAge != null && !Number.isNaN(Number(fitAge)) && !Number.isNaN(Number(ageYears))) {
    const delta = Number(ageYears) - Number(fitAge); // younger-than-chrono is better
    // Map −5..+5 years → 0..100 (clamped)
    const sc01 = clamp01((delta + 5) / 10);
    crf = Math.round(sc01 * 100);
  }

  // ---- Weights & Risk ----
  const hasCRF = typeof crf === "number";
  const weightsBase = model?.weights_base ?? { recovery: 0.35, sleep: 0.30, activity: 0.20, wellbeing: 0.15 };
  const weightsCRF  = model?.weights_with_crf ?? { recovery: 0.30, sleep: 0.25, activity: 0.15, wellbeing: 0.15, crf: 0.15 };
  const w = hasCRF ? weightsCRF : weightsBase;

  // available domain scores for this day
  const scores = { recovery, sleep, activity, wellbeing, ...(hasCRF ? { crf } : {}) };
  const observed = Object.entries(scores).filter(([, v]) => v != null);
  const sumWAll = Object.values(w).reduce((s, x) => s + x, 0);
  const sumWObs = observed.reduce((s, [k]) => s + (w[k] ?? 0), 0) || 1;

  // risk index (0..1): 1 - weighted average of domain scores
  const riskIndex = 1 - observed.reduce((s, [k, v]) => s + ((w[k] ?? 0) * v) / 100, 0) / sumWObs;

  // ---- Map to Vitality Age ----
  // Defaults from model with optional dynamic override + guard rails
  let pivotRisk  = Number(dynamic?.pivot_risk ?? model?.neutral_risk ?? 0.22);
  let scaleYears = Number(dynamic?.scale_years ?? model?.scale_years ?? 16);

  // clamp pivot into safe band
  const pivotMin = Number(model?.limits?.pivot_min ?? 0.18);
  const pivotMax = Number(model?.limits?.pivot_max ?? 0.28);
  pivotRisk = clamp(pivotRisk, pivotMin, pivotMax);

  // raw mapping
  const vitalityAgeRaw = Number(ageYears) + scaleYears * (riskIndex - pivotRisk);

  // absolute cap: don't drift unrealistically far from chronological age
  const vaAbsMax = Number(model?.limits?.va_offset_abs_max ?? 10); // ±years
  const vitalityAge = Math.round(clamp(vitalityAgeRaw, Number(ageYears) - vaAbsMax, Number(ageYears) + vaAbsMax) * 10) / 10;

  // transparency packs
  const wused = Object.fromEntries(Object.keys(scores).map((k) => [k, w[k] ?? 0]));
  const constants = {
    pivot_risk: round(pivotRisk, 3),
    scale_years: round(scaleYears, 2),
    cap_va_abs_offset: round(vaAbsMax, 1),
  };
  if (dynamic?.window) {
    constants.window_p5 = dynamic.window.p5;
    constants.window_p95 = dynamic.window.p95;
  }

  return {
    score: scores,          // recovery, sleep, activity, wellbeing, [crf?]
    risk_index: round(riskIndex, 3),
    vitality_age: vitalityAge,
    wused,
    constants,
    weightsObservedFrac: clamp01(sumWObs / sumWAll),
  };
}

/* ======================= computeDailyHttp ======================= */

export const computeDailyHttp = onRequest(
  { cors: true, region: "us-central1" },
  async (req, res) => {
    const startedIso = new Date().toISOString();
    try {
      const body = (req.method === "POST" && req.body) || {};
      const tz = body.tz || DEFAULT_TZ;
      const dateKey = body.date_local || todayKeyInTZ(tz);

      // target users
      let userIds = [];
      if (body.userId) {
        userIds = [String(body.userId)];
      } else {
        const tops = await db.collection("users").listDocuments();
        userIds = tops.map((d) => d.id);
      }

      const results = [];
      let processed_fail = 0;

      for (const uid of userIds) {
        try {
          const r = await runForUserDay({ userId: uid, dateKey, tz });
          results.push({ userId: uid, ...r });
        } catch (e) {
          processed_fail += 1;
          logger.error("computeDaily per-user error", { userId: uid, dateKey, message: e?.message });
          results.push({ userId: uid, error: String(e?.message || e) });
        }
      }

      const processed_ok = userIds.length - processed_fail;
      const totalWrites = results.reduce((s, r) => s + (r?.writes ?? 0), 0);

      await db.collection("system_runs").doc("daily").collection("runs").doc(dateKey).set({
        date_local: dateKey, tz, triggered_at_utc: startedIso, finished_at_utc: new Date().toISOString(),
        status: processed_fail ? "partial" : "ok", processed_ok, processed_fail, processed_missing: 0, notes: "scheduler/http run",
      }, { merge: true });

      logger.info("computeDailyHttp batch finished", {
        at_utc: new Date().toISOString(), dateKey, users: userIds.length, totalWrites, processed_ok, processed_fail,
      });

      res.status(200).json({ ok: true, date_local: dateKey, tz, users: userIds.length, results, processed_ok, processed_fail, totalWrites });
    } catch (err) {
      logger.error("computeDailyHttp error", { message: err?.message, stack: err?.stack });
      res.status(500).json({ ok: false, error: String(err?.message || err) });
    }
  }
);

async function runForUserDay({ userId, dateKey, tz = DEFAULT_TZ }) {
  const start = Date.now();
  let writes = 0;

  const [model, userSnap] = await Promise.all([
    loadModelConfig(),
    db.doc(`users/${userId}`).get(),
  ]);
  const user = userSnap.exists ? (userSnap.data() || {}) : {};
  const ageYears = user?.profile_age_years ?? ageFromDob(user?.dob) ?? 35;

  const daysCol = db.collection("users").doc(userId).collection("days");
  const docRef = daysCol.doc(dateKey);
  const snap = await docRef.get();
  const prev = snap.exists ? snap.data() : {};

  const currentInputs = shallowPick(prev, RAW_INPUT_KEYS);

  // yesterday for EMA/stale and daily caps
  const yKey = (() => {
    const [y, m, d] = dateKey.split("-").map((x) => Number(x));
    const dt = new Date(Date.UTC(y, m - 1, d));
    dt.setUTCDate(dt.getUTCDate() - 1);
    return `${dt.getUTCFullYear()}-${pad2(dt.getUTCMonth() + 1)}-${pad2(dt.getUTCDate())}`;
  })();
  const ySnap = await daysCol.doc(yKey).get();
  const yDoc = ySnap.exists ? ySnap.data() : null;

  // EMA + staleness roll-forward
  const stale = { ...(prev.stale_days || {}) };
  const ema7 = { ...(prev.ema7 || {}) };
  for (const k of RAW_INPUT_KEYS) {
    const hasToday = prev[k] != null;
    stale[k] = hasToday ? 0 : Math.min((stale[k] ?? (yDoc?.stale_days?.[k] ?? 0)) + 1, 365);
    const prevEma = prev?.ema7?.[k] ?? yDoc?.ema7?.[k] ?? null;
    const currVal = hasToday ? prev[k] : null;
    ema7[k] = calcEMA(prevEma, currVal);
  }

  const changed = inputsChanged(yDoc, currentInputs) || inputsChanged(prev, currentInputs);

  // 30-day window (ascending ids)
  const id = FieldPath.documentId();
  const since = new Date(); since.setUTCDate(since.getUTCDate() - 29);
  const sinceKey = `${since.getUTCFullYear()}-${pad2(since.getUTCMonth() + 1)}-${pad2(since.getUTCDate())}`;
  const forward = await daysCol.orderBy(id).startAt(sinceKey).limit(60).get();
  const docsAsc = forward.docs;
  const last30Docs = docsAsc.slice(-30).map((d) => d.data());

  // dynamic pivot/scale (optional) with guard rails
  let dynamic = {};
  try {
    const risks = last30Docs
      .map((d) => d?.risk_index)
      .filter((x) => typeof x === "number")
      .sort((a, b) => a - b);

    // Dynamic scale
    const enoughForScale = risks.length >= Number(model?.dynamic_scale?.min_days ?? 14);
    if (model?.dynamic_scale?.enabled && enoughForScale) {
      const p5 = percentile(risks, 5), p95 = percentile(risks, 95);
      const span = Math.max(1e-6, p95 - p5);
      const targetSpanYears = Number(model?.dynamic_scale?.target_span_years ?? 8); // map p5→−4, p95→+4
      const minScale = Number(model?.limits?.dynamic_scale_min ?? 10);
      const maxScale = Number(model?.limits?.dynamic_scale_max ?? 20); // tighter than 24 to reduce extremes
      const scaleYears = clamp(targetSpanYears / span, minScale, maxScale);
      dynamic.scale_years = scaleYears;
      dynamic.window = { p5: round(p5, 3), p95: round(p95, 3) };
    }

    // Dynamic pivot (after calibration), shrunk toward neutral and clamped
    const calOK = (user?.calibration_status || "").toString() === "complete";
    const enoughForPivot = risks.length >= Number(model?.dynamic_pivot?.min_days ?? 21);
    if (model?.dynamic_pivot?.enabled && calOK && enoughForPivot) {
      const med = percentile(risks, 50);
      const neutral = Number(model?.neutral_risk ?? 0.22);
      const pivMin = Number(model?.limits?.pivot_min ?? 0.18);
      const pivMax = Number(model?.limits?.pivot_max ?? 0.28);
      const shrink = clamp01(Number(model?.dynamic_pivot?.shrink_to_neutral ?? 0.5));
      const medClamped = clamp(round(med, 3), pivMin, pivMax);
      // shrink toward neutral to avoid runaway pivoting
      dynamic.pivot_risk = round(neutral * shrink + medClamped * (1 - shrink), 3);
    }
  } catch (e) {
    logger.warn("dynamic pivot/scale calc failed", { userId, dateKey, message: e?.message });
  }

  // compute
  let outputs = {};
  if (changed) {
    outputs = computeScores(
      { ...prev, ema7, profile_age_years: ageYears },
      { model, ageYears, dynamic }
    );
    // Daily change caps
    const MAX_VA_DELTA = Number(model?.caps?.max_daily_va_delta ?? 1.0);
    const MAX_RISK_DELTA = Number(model?.caps?.max_daily_risk_delta ?? 0.12);
    if (yDoc?.vitality_age != null && outputs?.vitality_age != null) {
      const delta = outputs.vitality_age - yDoc.vitality_age;
      if (Math.abs(delta) > MAX_VA_DELTA) {
        outputs.vitality_age = round(yDoc.vitality_age + Math.sign(delta) * MAX_VA_DELTA, 1);
      }
    }
    if (yDoc?.risk_index != null && outputs?.risk_index != null) {
      const deltaR = outputs.risk_index - yDoc.risk_index;
      if (Math.abs(deltaR) > MAX_RISK_DELTA) {
        outputs.risk_index = round(yDoc.risk_index + Math.sign(deltaR) * MAX_RISK_DELTA, 3);
      }
    }
  } else {
    outputs = {
      score: prev.score ?? undefined,
      risk_index: prev.risk_index ?? undefined,
      vitality_age: prev.vitality_age ?? undefined,
      wused: prev.wused ?? undefined,
      constants: prev.constants ?? undefined,
      weightsObservedFrac: prev.weightsObservedFrac ?? undefined,
    };
  }

  // confidence (use observed domain weights, not raw inputs count)
  const weightsObservedFrac = outputs?.weightsObservedFrac ?? 0;
  const score_confidence = reCalcConfidence(weightsObservedFrac, stale);

  // 30-day healthy days
  const healthy_days_30 = healthyDaysFromWindow(last30Docs);

  // flatten maps for FF convenience
  const nowIso = new Date().toISOString();
  const emaFlat = {}, staleFlat = {};
  for (const k of RAW_INPUT_KEYS) {
    emaFlat[`ema7_${k}`] = ema7[k] ?? null;
    staleFlat[`stale_${k}`] = stale[k] ?? 0;
  }
  const scoreFlat = outputs?.score ? {
    score_recovery: outputs.score.recovery ?? null,
    score_sleep: outputs.score.sleep ?? null,
    score_activity: outputs.score.activity ?? null,
    score_wellbeing: outputs.score.wellbeing ?? null,
    // back-compat alias
    score_affect: outputs.score.wellbeing ?? null,
    score_crf: outputs.score.crf ?? null,
  } : {};

  // write
  const baseUpdate = {
    computed_at_utc: nowIso, last_scheduler_run_utc: nowIso,
    ema7, stale_days: stale, ...emaFlat, ...staleFlat,
    score_confidence, healthy_days_30,
    weightsObservedFrac: outputs?.weightsObservedFrac ?? null,
    wused: outputs?.wused ?? null,
    constants: outputs?.constants ?? null,
    score: outputs?.score ?? null,
  };
  const toWrite = { ...baseUpdate, risk_index: outputs?.risk_index, vitality_age: outputs?.vitality_age };
  Object.keys(toWrite).forEach((k) => { if (toWrite[k] === undefined) delete toWrite[k]; });

  await docRef.set(toWrite, { merge: true }); writes += 1;

  await db.collection("user_events").doc(userId).collection("events").add({
    type: "computeDailyHttp",
    date_key: dateKey, tz, changed, writes, at_utc: nowIso,
    path: `users/${userId}/days/${dateKey}`,
  }); writes += 1;

  const ms = Date.now() - start;
  logger.info("computeDaily cost meter", { userId, dateKey, writes, ms, changed });
  return { writes, ms, changed, healthy_days_30, score_confidence };
}

/* =================== Unit normalization triggers =================== */
// converters
const toKm = (v, u) => v==null?null: (u||"").toLowerCase()==="km"?round(v,3)
  : ["m"].includes((u||"").toLowerCase())?round(v/1000,3)
  : ["mi","mile","miles"].includes((u||"").toLowerCase())?round(v*1.60934,3):null;
const paceToMinPerKm = (v, u) => {
  if (v==null||!u) return null;
  const U=u.toLowerCase();
  if (U==="min_per_km") return round(v,2);
  if (U==="min_per_mile"||U==="min_per_mi") return round(v/1.60934,2);
  if (U==="km_per_hour"||U==="kph") return v<=0?null:round(60/v,2);
  return null;
};
const toKg = (v,u)=> v==null?null: ["kg"].includes((u||"").toLowerCase())?round(v,2)
  : ["g"].includes((u||"").toLowerCase())?round(v/1000,3)
  : ["lb","lbs","pound","pounds"].includes((u||"").toLowerCase())?round(v*0.45359237,2):null;
const toCm = (v,u)=> v==null?null: ["cm"].includes((u||"").toLowerCase())?round(v,2)
  : ["m"].includes((u||"").toLowerCase())?round(v*100,2)
  : ["in","inch","inches"].includes((u||"").toLowerCase())?round(v*2.54,2)
  : ["ft","feet"].includes((u||"").toLowerCase())?round(v*30.48,2):null;
const toMl = (v,u)=> v==null?null: ["ml"].includes((u||"").toLowerCase())?round(v,1)
  : ["l","liter","litre"].includes((u||"").toLowerCase())?round(v*1000,1)
  : ["oz","fl_oz","fluid_oz"].includes((u||"").toLowerCase())?round(v*29.5735,1):null;
const toC = (v,u)=> v==null?null: ["c","°c"].includes((u||"").toLowerCase())?round(v,2)
  : ["f","°f"].includes((u||"").toLowerCase())?round((v-32)*(5/9),2):null;
const mgdLtoMmolL = (v,u)=> v==null?null: ["mmol_l","mmol/l"].includes((u||"").toLowerCase())?round(v,2)
  : ["mg_dl","mg/dl"].includes((u||"").toLowerCase())?round(v*0.0555,2):null;

const needMerge = (afterData, patch) => {
  if (!afterData) return true;
  for (const [k, v] of Object.entries(patch)) {
    const curr = afterData[k];
    if (curr === undefined) return true;
    if (typeof v === "number" && typeof curr === "number") {
      if (Math.abs(v - curr) > 1e-9) return true;
    } else if (JSON.stringify(curr) !== JSON.stringify(v)) return true;
  }
  return false;
};

export const normMeasurements = onDocumentWritten(
  "users/{uid}/measurements/{docId}",
  async (event) => {
    const after = event.data?.after; if (!after) return;
    const data = after.data() || {};
    const { kind, value, unit } = data;
    let patch = {};
    if (kind === "weight") {
      const kg = toKg(value, unit); if (kg != null) patch.kg = kg;
    } else if (["height", "waist", "hip", "chest"].includes(kind)) {
      const cm = toCm(value, unit); if (cm != null) patch.cm = cm;
    }
    if (Object.keys(patch).length && needMerge(data, patch)) {
      patch.updated_at_utc = FieldValue.serverTimestamp();
      await after.ref.set(patch, { merge: true });
      logger.info("normMeasurements merged", { id: after.id, patch });
    }
  }
);

export const normWorkouts = onDocumentWritten(
  "users/{uid}/workouts/{workoutId}",
  async (event) => {
    const after = event.data?.after; if (!after) return;
    const d = after.data() || {};
    const patch = {};
    if (d.distance_value != null && d.distance_unit) {
      const km = toKm(d.distance_value, d.distance_unit);
      if (km != null) patch.distance_km = km;
    }
    if (d.avg_pace_value != null && d.avg_pace_unit) {
      const mpk = paceToMinPerKm(d.avg_pace_value, d.avg_pace_unit);
      if (mpk != null) patch.avg_pace_min_per_km = mpk;
    }
    if (Object.keys(patch).length && needMerge(d, patch)) {
      patch.updated_at_utc = FieldValue.serverTimestamp();
      await after.ref.set(patch, { merge: true });
      logger.info("normWorkouts merged", { id: after.id, patch });
    }
  }
);

export const normHydration = onDocumentWritten(
  "users/{uid}/hydration_days/{dateId}",
  async (event) => {
    const after = event.data?.after; if (!after) return;
    const d = after.data() || {};
    const ml = toMl(d.total_value, d.total_unit);
    const patch = {}; if (ml != null) patch.normalized_ml = ml;
    if (Object.keys(patch).length && needMerge(d, patch)) {
      patch.updated_at_utc = FieldValue.serverTimestamp();
      await after.ref.set(patch, { merge: true });
      logger.info("normHydration merged", { id: after.id, patch });
    }
  }
);

export const normGlucose = onDocumentWritten(
  "users/{uid}/biometrics_glucose/{docId}",
  async (event) => {
    const after = event.data?.after; if (!after) return;
    const d = after.data() || {};
    const mmol = mgdLtoMmolL(d.value, d.unit);
    const patch = {}; if (mmol != null) patch.mmol_L = mmol;
    if (Object.keys(patch).length && needMerge(d, patch)) {
      patch.updated_at_utc = FieldValue.serverTimestamp();
      await after.ref.set(patch, { merge: true });
      logger.info("normGlucose merged", { id: after.id, patch });
    }
  }
);

export const normTemp = onDocumentWritten(
  "users/{uid}/biometrics_temp/{docId}",
  async (event) => {
    const after = event.data?.after; if (!after) return;
    const d = after.data() || {};
    const c = toC(d.value, d.unit);
    const patch = {}; if (c != null) patch.C = c;
    if (Object.keys(patch).length && needMerge(d, patch)) {
      patch.updated_at_utc = FieldValue.serverTimestamp();
      await after.ref.set(patch, { merge: true });
      logger.info("normTemp merged", { id: after.id, patch });
    }
  }
);

export const enrichBP = onDocumentWritten(
  "users/{uid}/biometrics_bp/{docId}",
  async (event) => {
    const after = event.data?.after; if (!after) return;
    const d = after.data() || {};
    if (d.systolic != null && d.diastolic != null) {
      const map = round(d.diastolic + (d.systolic - d.diastolic) / 3, 1);
      const patch = { mean_arterial_pressure: map };
      if (needMerge(d, patch)) {
        patch.updated_at_utc = FieldValue.serverTimestamp();
        await after.ref.set(patch, { merge: true });
        logger.info("enrichBP merged", { id: after.id, patch });
      }
    }
  }
);

/* ======================= Secure seeding endpoint ======================= */

export const seedFirestore = onRequest(
  { region: "us-central1", secrets: ["SEED_SECRET"] },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({ ok: false, error: "Use POST" });
      }
      const provided = req.headers["x-seed-secret"];
      const expected = process.env.SEED_SECRET;
      if (!expected || !provided || String(provided) !== String(expected)) {
        return res.status(401).json({ ok: false, error: "Unauthorized" });
      }

      let docs = req.body?.docs;
      if (!docs && req.body?.preset === "vitalis_full") {
        const today = todayKeyInTZ(DEFAULT_TZ);
        docs = {
          "config/app": {
            defaults: {
              tz: DEFAULT_TZ,
              locale: "en-US",
              units: { length: "cm", mass: "kg", temperature: "C", glucose: "mg_dL", distance: "km", volume: "ml" }
            },
            features: {
              computeDaily: true, badges: true, friends: true, groups: true, challenges: true,
              events: true, leaderboards: true, handles: true, paywall: true, notifications: true
            },
            ui: { welcome_version: 1 }
          },

          // Tiers, etc.
          "tiers/free": { name: "Free", price_usd: 0, limits: { groups: 2, challenges_joined: 2, export: false } },
          "tiers/plus": { name: "Plus", price_usd_month: 7.99, limits: { groups: 10, challenges_joined: 10, export: true } },
          "tiers/pro":  { name: "Pro",  price_usd_month: 19.99, limits:{ groups: 50, challenges_joined: 50, export: true } },

          // MODEL CONFIG v1 (updated with guard rails)
          "models/v1": {
            weights_base:     { recovery: 0.35, sleep: 0.30, activity: 0.20, wellbeing: 0.15 },
            weights_with_crf: { recovery: 0.30, sleep: 0.25, activity: 0.15, wellbeing: 0.15, crf: 0.15 },
            neutral_risk: 0.22,           // pivot
            scale_years: 16,              // base sensitivity
            dynamic_scale: { enabled: true, target_span_years: 8, min_days: 14 }, // p5→-4y, p95→+4y
            dynamic_pivot: { enabled: true, min_days: 21, shrink_to_neutral: 0.5 },
            limits: {
              dynamic_scale_min: 10,
              dynamic_scale_max: 20,
              pivot_min: 0.18,
              pivot_max: 0.28,
              va_offset_abs_max: 10
            },
            caps: { max_daily_va_delta: 1.0, max_daily_risk_delta: 0.12 },
            crf: { min_vo2: 20, max_vo2: 55 } // VO2 mapping clamps
          },

          "percentiles/v1": { hrv_rmssd_ms: [], rhr_bpm: [], steps_count: [], vo2max_ml_kg_min: [] },
          "vitality_reference/v1": { scale_years: 16, neutral_risk: 0.22 },

          // Demo scaffold
          "usernames/vitalis_demo": { uid: "demoUser" },
          "users/demoUser": {
            username: "vitalis_demo", username_lc: "vitalis_demo", display_name: "Vitalis Demo",
            email: "demo@example.com", tz: DEFAULT_TZ, language: "en", tier: "plus",
            units_pref: { length:"ft", mass:"lbs", temperature:"F", glucose:"mg_dL", distance:"mi", volume:"oz" },
            created_at_utc: new Date().toISOString(), last_login_utc: new Date().toISOString(),
            model_version: "vA_1.0", calibration_status: "complete",
            // optional profile anchors
            profile_age_years: 33
          },
          [`users/demoUser/days/${today}`]: {
            date_local: today, tz: DEFAULT_TZ,
            steps_count: null, sleep_total_hours: null, sleep_regularity_pct: null,
            hrv_rmssd_ms: null, rhr_bpm: null,
            wellbeing_level_1to5: null, // replaces mood+stress+energy
            vo2max_ml_kg_min: null, fitness_age_years: null,
            ema7: {}, stale_days: {},
            score: { recovery:null, sleep:null, activity:null, wellbeing:null, crf:null },
            risk_index: null, vitality_age: null, score_confidence: null, healthy_days_30: null,
            computed_at_utc: null, last_scheduler_run_utc: null
          },

          "user_events/demoUser/events/_seed": { type:"system_init", at_utc: new Date().toISOString(), notes:"seed" },
          [`users/demoUser/hydration_days/${today}`]: { date_local: today, total_value: 68, total_unit:"oz", goal_value: 80, goal_unit: "oz", normalized_ml: 2011, entries: 6 },

          // Community/leaderboards scaffold
          "groups/public_walkers": { name:"Public Walkers", owner_uid:"demoUser", visibility:"public", photo_url:"", created_at:new Date().toISOString(), stats:{ members:1, posts:0 }, rules:{ invite_only:false } },
          "groups/public_walkers/members/demoUser": { role:"owner", joined_at:new Date().toISOString() },
          "challenges/10k_steps_week": { title:"10k Steps / Day (7 days)", desc:"Hit 10,000 steps per day for a week.", visibility:"public",
            start_utc:"2025-08-11T00:00:00Z", end_utc:"2025-08-18T00:00:00Z", goal_type:"steps_per_day", goal_value:10000,
            prizes:{ badge:"steps_100k_week" }, stats:{ participants:1 } },
          "challenges/10k_steps_week/participants/demoUser": { joined_at:new Date().toISOString(), progress:{ days_ok:0, steps_total:0 } },
          "community_events/walk_sat_morning": { title:"Saturday Community Walk", desc:"Easy 3-mile walk with the community.", start_local:"2025-08-16T09:00:00", timezone:DEFAULT_TZ, location:{ name:"Lake Park", lat:null, lng:null }, visibility:"public", host_uid:"demoUser", status:"open", stats:{ rsvps:1 } },
          "community_events/walk_sat_morning/rsvps/demoUser": { status:"going", rsvped_at:new Date().toISOString() },
          "leaderboards/weekly_steps": { kind:"steps", period:"week", version:"v1", last_built_utc:null },
          "leaderboards/weekly_steps/entries/demoUser": { uid:"demoUser", display_name:"Vitalis Demo", period_id:"2025-W32", score: 12050, rank:null, updated_at_utc:new Date().toISOString() },
          "notifications/demoUser/inbox/_placeholder": { note:"{type,title,body,read,created_at}" },
          "invites/_placeholder": { note:"{type:'group|challenge|friend', from_uid, to_email, created_at, expires_at}" },
          "system_runs/daily/runs/_seed": { status:"ok", processed_ok:0, processed_fail:0, processed_missing:0, triggered_at_utc:new Date().toISOString(), finished_at_utc:new Date().toISOString(), tz:DEFAULT_TZ, notes:"seed" }
        };
      }

      if (!docs || typeof docs !== "object") {
        return res.status(400).json({ ok: false, error: "Provide { preset:'vitalis_full' } or { docs: { 'path': {...}, ... } }" });
      }

      const entries = Object.entries(docs);
      let ok = 0, fail = 0;
      for (const [docPath, data] of entries) {
        try {
          await db.doc(docPath).set(data, { merge: true });
          ok++;
        } catch (e) {
          fail++;
          logger.error("seedFirestore failed", { docPath, message: e?.message });
        }
      }
      return res.status(200).json({ ok: true, merged: ok, failed: fail });
    } catch (err) {
      logger.error("seedFirestore error", { message: err?.message, stack: err?.stack });
      return res.status(500).json({ ok: false, error: String(err?.message || err) });
    }
  }
);

/* ======================= Usernames ======================= */

// PATCH: fix the handle regex (no stray escapes; enforce 3–24 of [A–Z,a–z,0–9,_,.])
const HANDLE_RE = /^[a-zA-Z0-9_.]{3,24}$/;

export const reserveUsername = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  const handle = String(req.data?.handle || "").trim();
  if (!uid) throw new Error("unauthenticated");
  if (!HANDLE_RE.test(handle)) throw new Error("invalid_handle");

  const handleLc = handle.toLowerCase();
  const unameRef = db.doc(`usernames/${handleLc}`);
  const userRef = db.doc(`users/${uid}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(unameRef);
    if (snap.exists && snap.data()?.uid !== uid) {
      throw new Error("unavailable");
    }
    tx.set(unameRef, { uid, reserved_at_utc: new Date().toISOString() }, { merge: true });
    tx.set(userRef, { username: handle, username_lc: handleLc, updated_at_utc: new Date().toISOString() }, { merge: true });
  });

  return { ok: true, handle: handleLc };
});

/* ======================= Integrations status ======================= */

export const setIntegrationStatus = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");
  const provider = String(req.data?.provider || "").trim();
  if (!provider) throw new Error("missing_provider");

  const payload = {
    connected: !!req.data?.connected,
    scopes: Array.isArray(req.data?.scopes) ? req.data.scopes : [],
    last_status: String(req.data?.status || "ok"),
    error_msg: req.data?.error_msg ?? null,
    last_sync_utc: new Date().toISOString(),
  };

  await db.doc(`integrations/${provider}/users/${uid}`).set(payload, { merge: true });
  return { ok: true };
});

/* ======================= Friends ======================= */

async function createNotif(uid, type, title, body, action_url=null) {
  const ref = db.collection("notifications").doc(uid).collection("inbox").doc();
  await ref.set({ type, title, body, action_url, read: false, created_at: FieldValue.serverTimestamp() });
}

export const sendFriendRequest = onCall({ region: "us-central1" }, async (req) => {
  const from = req.auth?.uid;
  const to = String(req.data?.toUid || "");
  if (!from) throw new Error("unauthenticated");
  if (!to || to === from) throw new Error("invalid_target");

  const now = FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    tx.set(db.doc(`friends/${to}/incoming/${from}`), { from_uid: from, created_at: now });
    tx.set(db.doc(`friends/${from}/outgoing/${to}`), { to_uid: to, created_at: now });
  });
  await createNotif(to, "friend_request", "New Friend Request", "You have a new friend request.");
  return { ok: true };
});

export const acceptFriendRequest = onCall({ region: "us-central1" }, async (req) => {
  const to = req.auth?.uid; // recipient
  const from = String(req.data?.fromUid || "");
  if (!to) throw new Error("unauthenticated");
  if (!from || from === to) throw new Error("invalid_source");

  const now = FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    tx.delete(db.doc(`friends/${to}/incoming/${from}`));
    tx.delete(db.doc(`friends/${from}/outgoing/${to}`));
    tx.set(db.doc(`friends/${to}/accepted/${from}`), { since_utc: now });
    tx.set(db.doc(`friends/${from}/accepted/${to}`), { since_utc: now });
  });
  await createNotif(from, "friend_accept", "Friend Request Accepted", "Your request was accepted.");
  return { ok: true };
});

export const declineFriendRequest = onCall({ region: "us-central1" }, async (req) => {
  const to = req.auth?.uid;
  const from = String(req.data?.fromUid || "");
  if (!to) throw new Error("unauthenticated");
  if (!from || from === to) throw new Error("invalid_source");
  await db.runTransaction(async (tx) => {
    tx.delete(db.doc(`friends/${to}/incoming/${from}`));
    tx.delete(db.doc(`friends/${from}/outgoing/${to}`));
  });
  return { ok: true };
});

export const blockUser = onCall({ region: "us-central1" }, async (req) => {
  const me = req.auth?.uid;
  const blockUid = String(req.data?.uid || "");
  if (!me) throw new Error("unauthenticated");
  if (!blockUid || blockUid === me) throw new Error("invalid_target");

  await db.runTransaction(async (tx) => {
    tx.set(db.doc(`friends/${me}/blocked/${blockUid}`), { since_utc: FieldValue.serverTimestamp(), reason: req.data?.reason ?? null });
    // clean any existing relations
    tx.delete(db.doc(`friends/${me}/incoming/${blockUid}`));
    tx.delete(db.doc(`friends/${me}/outgoing/${blockUid}`));
    tx.delete(db.doc(`friends/${me}/accepted/${blockUid}`));
  });
  return { ok: true };
});

export const unblockUser = onCall({ region: "us-central1" }, async (req) => {
  const me = req.auth?.uid;
  const uid = String(req.data?.uid || "");
  if (!me) throw new Error("unauthenticated");
  if (!uid || uid === me) throw new Error("invalid_target");
  await db.doc(`friends/${me}/blocked/${uid}`).delete();
  return { ok: true };
});

// keep lightweight counters in friends/{uid}/meta/_counters
export const friendsCounters = onDocumentWritten(
  "friends/{uid}/{subcol}/{docId}",
  async (event) => {
    const uid = event.params.uid;
    const sub = event.params.subcol; // incoming/outgoing/accepted/blocked/meta...
    if (!["incoming", "outgoing", "accepted", "blocked"].includes(sub)) return;
    const created = !!event.data?.after && !event.data?.before;
    const deleted = !!event.data?.before && !event.data?.after;
    if (!created && !deleted) return;
    const delta = created ? 1 : -1;
    const metaRef = db.doc(`friends/${uid}/meta/_counters`);
    await metaRef.set({ counts: { [sub]: FieldValue.increment(delta) } }, { merge: true });
  }
);

/* ======================= Groups ======================= */

export const createGroup = onCall({ region: "us-central1" }, async (req) => {
  const owner = req.auth?.uid;
  if (!owner) throw new Error("unauthenticated");
  const name = String(req.data?.name || "").trim();
  if (!name) throw new Error("missing_name");

  const vis = (req.data?.visibility || "public").toString();
  const inviteOnly = !!req.data?.invite_only;

  const grpRef = db.collection("groups").doc();
  await grpRef.set({
    name, owner_uid: owner, visibility: vis, photo_url: "",
    created_at: new Date().toISOString(),
    stats: { members: 1, posts: 0 },
    rules: { invite_only: inviteOnly }
  });
  await grpRef.collection("members").doc(owner).set({ role: "owner", joined_at: new Date().toISOString() });
  return { ok: true, groupId: grpRef.id };
});

export const joinGroup = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");
  const groupId = String(req.data?.groupId || "");
  if (!groupId) throw new Error("missing_group");

  const gRef = db.doc(`groups/${groupId}`);
  const g = (await gRef.get()).data() || {};
  if (g?.rules?.invite_only) throw new Error("invite_only");
  await gRef.collection("members").doc(uid).set({ role: "member", joined_at: new Date().toISOString() }, { merge: true });
  return { ok: true };
});

export const leaveGroup = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");
  const groupId = String(req.data?.groupId || "");
  if (!groupId) throw new Error("missing_group");
  await db.doc(`groups/${groupId}/members/${uid}`).delete();
  return { ok: true };
});

// members counter
export const groupMembersCounter = onDocumentWritten(
  "groups/{groupId}/members/{uid}",
  async (event) => {
    const groupId = event.params.groupId;
    const created = !!event.data?.after && !event.data?.before;
    const deleted = !!event.data?.before && !event.data?.after;
    if (!created && !deleted) return;
    const delta = created ? 1 : -1;
    await db.doc(`groups/${groupId}`).set({ stats: { members: FieldValue.increment(delta) } }, { merge: true });
  }
);

/* ======================= Challenges ======================= */

export const createChallenge = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");

  const title = String(req.data?.title || "").trim();
  if (!title) throw new Error("missing_title");

  const cRef = db.collection("challenges").doc();
  await cRef.set({
    title, desc: req.data?.desc || "", visibility: (req.data?.visibility || "public").toString(),
    start_utc: String(req.data?.start_utc || new Date().toISOString()),
    end_utc: String(req.data?.end_utc || new Date(Date.now()+7*864e5).toISOString()),
    goal_type: String(req.data?.goal_type || "steps_per_day"),
    goal_value: Number(req.data?.goal_value ?? 10000),
    prizes: { badge: req.data?.badge || null },
    stats: { participants: 0 },
    created_by: uid
  });
  return { ok: true, challengeId: cRef.id };
});

export const joinChallenge = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");
  const id = String(req.data?.challengeId || "");
  if (!id) throw new Error("missing_challenge");

  await db.doc(`challenges/${id}/participants/${uid}`).set({
    joined_at: new Date().toISOString(),
    progress: { days_ok: 0, steps_total: 0 }
  }, { merge: true });
  return { ok: true };
});

export const updateChallengeProgress = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");
  const id = String(req.data?.challengeId || "");
  const patch = req.data?.progressPatch || {};
  if (!id) throw new Error("missing_challenge");

  await db.doc(`challenges/${id}/participants/${uid}`).set({ progress: patch, updated_at_utc: new Date().toISOString() }, { merge: true });
  return { ok: true };
});

// participants counter
export const challengeParticipantsCounter = onDocumentWritten(
  "challenges/{id}/participants/{uid}",
  async (event) => {
    const id = event.params.id;
    const created = !!event.data?.after && !event.data?.before;
    const deleted = !!event.data?.before && !event.data?.after;
    if (!created && !deleted) return;
    const delta = created ? 1 : -1;
    await db.doc(`challenges/${id}`).set({ stats: { participants: FieldValue.increment(delta) } }, { merge: true });
  }
);

/* ======================= Community Events ======================= */

export const createCommunityEvent = onCall({ region: "us-central1" }, async (req) => {
  const host = req.auth?.uid;
  if (!host) throw new Error("unauthenticated");
  const title = String(req.data?.title || "").trim();
  if (!title) throw new Error("missing_title");

  const ref = db.collection("community_events").doc();
  await ref.set({
    title, desc: req.data?.desc || "",
    start_local: String(req.data?.start_local || ""),
    timezone: String(req.data?.timezone || DEFAULT_TZ),
    location: req.data?.location || { name: "", lat: null, lng: null },
    visibility: (req.data?.visibility || "public").toString(),
    host_uid: host, status: "open",
    stats: { rsvps: 0 },
    created_at: new Date().toISOString()
  });
  return { ok: true, eventId: ref.id };
});

export const rsvpEvent = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("unauthenticated");
  const eventId = String(req.data?.eventId || "");
  const status = String(req.data?.status || "going");
  if (!eventId) throw new Error("missing_event");

  await db.doc(`community_events/${eventId}/rsvps/${uid}`).set({ status, rsvped_at: new Date().toISOString() }, { merge: true });
  return { ok: true };
});

// RSVPs counter
export const eventRsvpsCounter = onDocumentWritten(
  "community_events/{id}/rsvps/{uid}",
  async (event) => {
    const id = event.params.id;
    const created = !!event.data?.after && !event.data?.before;
    const deleted = !!event.data?.before && !event.data?.after;
    if (!created && !deleted) return;
    const delta = created ? 1 : -1;
    await db.doc(`community_events/${id}`).set({ stats: { rsvps: FieldValue.increment(delta) } }, { merge: true });
  }
);

/* ======================= Leaderboards (scheduled) ======================= */

function isoWeekId(d) {
  const date = new Date(d);
  // ISO week calc
  const dayNr = (date.getUTCDay() + 6) % 7;
  date.setUTCDate(date.getUTCDate() - dayNr + 3);
  const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
  const week = 1 + Math.round(((date - firstThursday) / 86400000 - 3) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2,"0")}`;
}

export const buildLeaderboards = onSchedule(
  { region: "us-central1", schedule: "every 24 hours", timeZone: "Etc/UTC" },
  async () => {
    const boardId = "weekly_steps";
    const periodId = isoWeekId(new Date().toISOString());

    // collect users
    const tops = await db.collection("users").listDocuments();
    const userIds = tops.map(d => d.id);

    const since = new Date(); since.setUTCDate(since.getUTCDate() - 6);
    const sinceKey = `${since.getUTCFullYear()}-${pad2(since.getUTCMonth()+1)}-${pad2(since.getUTCDate())}`;

    let writes = 0;
    for (const uid of userIds) {
      try {
        const daysCol = db.collection("users").doc(uid).collection("days");
        const id = FieldPath.documentId();
        const snap = await daysCol.orderBy(id).startAt(sinceKey).limit(14).get();
        let total = 0;
        for (const doc of snap.docs) {
          total += Number(doc.data()?.steps_count ?? 0);
        }
        const entryRef = db.doc(`leaderboards/${boardId}/entries/${uid}`);
        await entryRef.set({
          uid, display_name: null, period_id: periodId,
          score: total, rank: null, updated_at_utc: new Date().toISOString()
        }, { merge: true });
        writes++;
      } catch (e) {
        logger.error("buildLeaderboards per-user error", { uid, message: e?.message });
      }
    }

    // simple ranking metadata
    await db.doc(`leaderboards/${boardId}`).set({
      kind: "steps", period: "week", version: "v1", last_built_utc: new Date().toISOString()
    }, { merge: true });

    logger.info("buildLeaderboards finished", { boardId, periodId, users: userIds.length, writes });
  }
);

/* ======================= Notifications & Invites ======================= */

export const markNotificationRead = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  const notifId = String(req.data?.notifId || "");
  if (!uid) throw new Error("unauthenticated");
  if (!notifId) throw new Error("missing_notif");

  await db.doc(`notifications/${uid}/inbox/${notifId}`).set({ read: true }, { merge: true });
  return { ok: true };
});

function randomToken(n=32) {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let s = ""; for (let i=0;i<n;i++) s += chars[Math.floor(Math.random()*chars.length)];
  return s;
}

export const createInvite = onCall({ region: "us-central1" }, async (req) => {
  const from = req.auth?.uid;
  if (!from) throw new Error("unauthenticated");
  const type = String(req.data?.type || "group");
  const targetId = String(req.data?.targetId || "");
  const toEmail = req.data?.toEmail || null;
  const toUid = req.data?.toUid || null;
  if (!targetId) throw new Error("missing_target");

  const token = randomToken(24);
  await db.doc(`invites/${token}`).set({
    type, target_id: targetId, from_uid: from, to_email: toEmail, to_uid: toUid,
    created_at: new Date().toISOString(),
    expires_at: new Date(Date.now()+7*86400000).toISOString()
  });
  return { ok: true, token };
});

export const acceptInvite = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  const token = String(req.data?.token || "");
  if (!uid) throw new Error("unauthenticated");
  if (!token) throw new Error("missing_token");

  const invRef = db.doc(`invites/${token}`);
  const inv = (await invRef.get()).data();
  if (!inv) throw new Error("invalid_token");
  if (new Date(inv.expires_at).getTime() < Date.now()) throw new Error("expired");

  if (inv.type === "group") {
    await db.doc(`groups/${inv.target_id}/members/${uid}`).set({ role: "member", joined_at: new Date().toISOString() }, { merge: true });
  } else if (inv.type === "challenge") {
    await db.doc(`challenges/${inv.target_id}/participants/${uid}`).set({ joined_at: new Date().toISOString(), progress: { days_ok: 0, steps_total: 0 } }, { merge: true });
  } else if (inv.type === "friend" && inv.from_uid) {
    await db.runTransaction(async (tx) => {
      tx.set(db.doc(`friends/${uid}/accepted/${inv.from_uid}`), { since_utc: FieldValue.serverTimestamp() });
      tx.set(db.doc(`friends/${inv.from_uid}/accepted/${uid}`), { since_utc: FieldValue.serverTimestamp() });
    });
  }
  await invRef.delete();
  return { ok: true };
});
