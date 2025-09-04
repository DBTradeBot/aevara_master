import { db, FieldValue, Timestamp } from "../core/firebase_admin.js";
// functions/ddc/run_for_user_day.js
// Orchestrates: anchors ? window ? merge ? policy ? compute ? write (DDC)
// - Fixed lease path (even-segment subcollection)
// - Provenance normalization (nested maps, no dotted keys)
// - EMA/staleness injection for stability
// - Stable compute signature ? true NO-OP if unchanged
// Node 20 / ESM
import { isDateKey, hashOf, parseDateKey, dateKeyInTZ } from "../core/ddc_utils.js";
import { loadModelConfig, loadAnchors } from "../core/anchors.js";
import { loadWindowUpToD, chooseDynamicParams } from "../core/dynamic_window.js";
import { resolveActivityInputs } from "../core/activity_policy.js";
import { mergeDailyFromVendors } from "../vendor/merge_daily.js";
import { computeScores } from "../core/compute.js";
import {
  acquireDayLease,
  heartbeatDayLease,
  releaseDayLease,
} from "../core/leases.js";

/**
 * runForUserDay(uid, dateKey, opts?)
 * opts: { tz?, policy?, force?, allowZerosToday? }
 *
 * Returns:
 *   { ok, no_op?, wrote?, reason?, docPath?, hashes?, dynamic_used? }
 */
export async function runForUserDay(
  uid,
  dateKey,
  {
    tz = "America/Los_Angeles",
    policy = "lag_yesterday",
    force = false,
    allowZerosToday = false,
  } = {}
) {
  if (!uid) throw new Error("runForUserDay: missing uid");
  if (!isDateKey(dateKey)) throw new Error("runForUserDay: invalid dateKey");

  const dayRef = db.doc(`users/${uid}/days/${dateKey}`);

  // ---- Lease to avoid concurrent compute for same (uid, day) ----
  const lease = await acquireDayLease(uid, dateKey, { ttlMs: 120_000 });
  if (!lease.ok) {
    return { ok: false, reason: "lease_held", until_ms: lease.until_ms, docPath: lease.refPath };
  }
  const leaseToken = lease.token;

  try {
    // Heartbeat once halfway through as a courtesy for long runs
    const heartbeatLater = setTimeout(
      () => heartbeatDayLease(uid, dateKey, leaseToken, { extendMs: 60_000 }),
      45_000
    );

    // ---- Load model + anchors ----
    const modelCfg = await loadModelConfig("v1");
    const anchors = await loadAnchors(uid);

    // ---- Window anchored to D (NOT "today") ----
    const windowDocs = await loadWindowUpToD(uid, dateKey, { limit: 30 });
    const dynamic = chooseDynamicParams(windowDocs, modelCfg);

    // ---- Merge vendor snapshots for D (source of truth snapshot) ----
    const snapshot = await mergeDailyFromVendors(uid, dateKey, { allowZerosToday });

    // ---- Pull any existing day doc (for comparison/ema) ----
    const prevSnap = await dayRef.get();
    const prevDoc = prevSnap.exists ? prevSnap.data() || {} : {};

    // ---- Resolve activity inputs per policy (may use D-1) ----
    const activity = await resolveActivityInputs(uid, dateKey, { policy, tz });

    // ---- Build inputs used for compute (values may differ from snapshot for Activity) ----
    const used = {
      // Recovery & Sleep from D (snapshot), with fallbacks to existing day doc if snapshot missing
      hrv_rmssd_ms: coalesceNum(snapshot.hrv_rmssd_ms, prevDoc.hrv_rmssd_ms),
      rhr_bpm: coalesceNum(snapshot.rhr_bpm, prevDoc.rhr_bpm),
      sleep_total_hours: coalesceNum(snapshot.sleep_total_hours, prevDoc.sleep_total_hours),
      // Activity per policy
      steps_count: coalesceNum(activity.steps_count, snapshot.steps_count, prevDoc.steps_count),
      calories_out: coalesceNum(activity.calories_out, snapshot.calories_out, prevDoc.calories_out),
      distance_km: coalesceNum(activity.distance_km, snapshot.distance_km, prevDoc.distance_km),
      // Affect direct from today doc (app writes)
      mood_level_1to5: coalesceNum(prevDoc.mood_level_1to5, snapshot.mood_level_1to5),
      stress_level_1to5: coalesceNum(prevDoc.stress_level_1to5, snapshot.stress_level_1to5),
    };

    // ---- Compute EMA7 & stale_days from window (ASC ordered) ----
    const { ema7, stale_days } = computeEmaAndStale(windowDocs, used);

    // ---- Freshness/provenance (nested, no dotted keys) ----
    const sources = nestSources(snapshot?.sources || {}, {
      activity_from_date: activity?.provenance?.from_date || null,
      activity_policy: activity?.provenance?.activity_policy || String(policy),
    });

    // ---- Load yesterday VA (for daily clamp) and calibration state ----
    const yKey = dayMinus(dateKey, 1);
    const yDocSnap = await db.doc(`users/${uid}/days/${yKey}`).get();
    const yDoc = yDocSnap.exists ? (yDocSnap.data() || {}) : {};
    const prev_vitality_age = numOrNull(yDoc?.vitality_age);

    // User doc for onboarding/calibration status (best-effort)
    const userSnap = await db.doc(`users/${uid}`).get();
    const user = userSnap.exists ? (userSnap.data() || {}) : {};

    const calibration_status = String(user?.calibration?.status || "").toLowerCase() || null;
    const calibration_day = Number(user?.calibration?.day || 0) || null;
    const days_since_onboarding = daysSinceOnboarding(user?.onboarded_at_utc, dateKey, tz);

    const last_change_utc =
      prevDoc?.computed_at_utc?.toDate?.()?.toISOString?.() ||
      prevDoc?.computed_at_utc ||
      null;

    // ---- Build compute inputs ----
    const computeIn = {
      inputs: {
        hrv_rmssd_ms: used.hrv_rmssd_ms,
        rhr_bpm: used.rhr_bpm,
        sleep_total_hours: used.sleep_total_hours,
        steps_count: used.steps_count,
        mood_level_1to5: used.mood_level_1to5,
        stress_level_1to5: used.stress_level_1to5,
        ema7,
        stale_days,
      },
      anchors,
      modelCfg,
      dynamic,
      options: {
        chrono_age_years: anchors?.age_years ?? null,
        prev_vitality_age,
        last_change_utc,
        calibration_status,
        calibration_day,
        days_since_onboarding,
      },
    };

    // ---- Compute ----
    const out = computeScores(computeIn);

    // ---- Stable compute signature for NO-OP check ----
    const snapshot_hash = hashOf({
      date_local: snapshot?.date_local,
      hrv_rmssd_ms: snapshot?.hrv_rmssd_ms,
      rhr_bpm: snapshot?.rhr_bpm,
      sleep_total_hours: snapshot?.sleep_total_hours,
      steps_count: snapshot?.steps_count,
      calories_out: snapshot?.calories_out,
      distance_km: snapshot?.distance_km,
      mood_level_1to5: prevDoc?.mood_level_1to5 ?? null,
      stress_level_1to5: prevDoc?.stress_level_1to5 ?? null,
      sources: snapshot?.sources || null,
    });

    // include clamp-relevant context so recompute is stable/intentional
    const context_hash = hashOf({
      prev_vitality_age,
      calibration_status,
      calibration_day,
      days_since_onboarding,
      last_change_utc: last_change_utc || null,
      policy: String(policy),
    });

    const compute_signature = hashOf({
      inputs_hash: out?.hashes?.inputs_hash || null,
      snapshot_hash,
      dynamic_used: out?.dynamic_used || null,
      anchors_version: anchors?.anchors_version || "a1",
      model_version: modelCfg?.version || "v1",
      context_hash,
    });

    const prev_signature = prevDoc?.hashes?.compute_signature || null;

    // ---- NO-OP ----
    if (!force && prev_signature === compute_signature) {
      clearTimeout(heartbeatLater);
      return {
        ok: true,
        no_op: true,
        reason: "signature_unchanged",
        docPath: dayRef.path,
        dynamic_used: out?.dynamic_used || null,
        hashes: out?.hashes || null,
      };
    }

    // ---- Write merged + compute result (preserve DDC transparency fields) ----
    const write = {
      date_local: dateKey,
      // snapshot (top-level inputs for the date itself)
      ...(snapshot?.hrv_rmssd_ms != null ? { hrv_rmssd_ms: snapshot.hrv_rmssd_ms } : {}),
      ...(snapshot?.rhr_bpm != null ? { rhr_bpm: snapshot.rhr_bpm } : {}),
      ...(snapshot?.sleep_total_hours != null ? { sleep_total_hours: snapshot.sleep_total_hours } : {}),
      ...(snapshot?.steps_count != null ? { steps_count: snapshot.steps_count } : {}),
      ...(snapshot?.calories_out != null ? { calories_out: snapshot.calories_out } : {}),
      ...(snapshot?.distance_km != null ? { distance_km: snapshot.distance_km } : {}),
      ...(snapshot?.sleep_score != null ? { sleep_score: snapshot.sleep_score } : {}),
      ...(snapshot?.vo2max_ml_kg_min != null ? { vo2max_ml_kg_min: snapshot.vo2max_ml_kg_min } : {}),

      // Used-for-score overlay (explicitly what was used, incl. lagged activity)
      metrics_used_for_score: {
        hrv_rmssd_ms: used.hrv_rmssd_ms ?? null,
        rhr_bpm: used.rhr_bpm ?? null,
        sleep_total_hours: used.sleep_total_hours ?? null,
        steps_count: used.steps_count ?? null,
        mood_level_1to5: used.mood_level_1to5 ?? null,
        stress_level_1to5: used.stress_level_1to5 ?? null,
      },

      // Provenance & transparency
      sources, // nested
      last_provider_sample_utc: snapshot?.last_provider_sample_utc || {},
      display: {
        status: prevDoc?.display?.status === "final" ? "final" : "computed",
        activity_policy: activity?.provenance?.activity_policy || String(policy),
        activity_from_date: activity?.provenance?.from_date || null,
        // optional UI hint for hero: "Activity reflects yesterday"
        note_activity_lag: (activity?.provenance?.activity_policy || policy) === "lag_yesterday",
      },

      // EMA & stale
      ema7,
      stale_days,

      // Compute outputs
      risk_index: out.risk_index,
      vitality_age: out.vitality_age,
      score_confidence: out.score_confidence,
      groups: out.groups,
      drivers: out.drivers,
      drivers_contrib: out.drivers_contrib,
      freshness: out.freshness,
      dynamic_used: out.dynamic_used,
      applied_caps: out.applied_caps,

      // Hashes (plus composite signature)
      hashes: {
        ...out.hashes,
        snapshot_hash,
        compute_signature,
      },

      // Model constants snapshot (for transparency)
      constants: {
        model_version: modelCfg?.version || "v1",
        scale_years: out?.dynamic_used?.scale_years ?? modelCfg?.scale_years ?? 12,
        pivot_risk: out?.dynamic_used?.pivot_risk ?? modelCfg?.pivot_risk ?? 0.35,
        caps: modelCfg?.caps || { daily_va_abs: 1.0, total_va_abs: 10 },
        groups_used: modelCfg?.groups || { recovery: 0.4, sleep: 0.3, activity: 0.3, affect: 0.0 },
      },

      // Audit
      computed_at_utc: FieldValue.serverTimestamp(),
      recompute_log: FieldValue.arrayUnion({
        at_utc: new Date().toISOString(),
        reason: force ? "force" : "normal",
        signature: compute_signature,
      }),
    };

    await dayRef.set(write, { merge: true });

    clearTimeout(heartbeatLater);
    return {
      ok: true,
      wrote: true,
      docPath: dayRef.path,
      dynamic_used: out.dynamic_used,
      hashes: { ...out.hashes, snapshot_hash, compute_signature },
    };
  } finally {
    await releaseDayLease(uid, dateKey, leaseToken).catch(() => {});
  }
}

/* --------------------------- internal helpers --------------------------- */

function coalesceNum(...vals) {
  for (const v of vals) {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return null;
}

function computeEmaAndStale(windowDocsAsc, usedToday) {
  const keys = ["hrv_rmssd_ms", "rhr_bpm", "sleep_total_hours", "steps_count"];

  // Build EMA over window (ASC), track last seen index for stale
  const emaState = { hrv_rmssd_ms: null, rhr_bpm: null, sleep_total_hours: null, steps_count: null };
  const lastSeenIdx = { hrv_rmssd_ms: null, rhr_bpm: null, sleep_total_hours: null, steps_count: null };

  windowDocsAsc.forEach((row, idx) => {
    keys.forEach((k) => {
      const v = Number(row?.[k]);
      if (Number.isFinite(v)) {
        // EMA period 7
        emaState[k] = emaState[k] == null ? v : (2 / (7 + 1)) * v + (1 - 2 / (7 + 1)) * emaState[k];
        lastSeenIdx[k] = idx;
      }
    });
  });

  // Stale days: distance from lastSeen to last index; but if usedToday has it, it's fresh
  const lastIdx = windowDocsAsc.length - 1;
  const stale_days = {};
  keys.forEach((k) => {
    if (usedToday?.[k] != null) {
      stale_days[k] = 0;
      return;
    }
    const ls = lastSeenIdx[k];
    stale_days[k] = ls == null ? 99 : Math.max(0, lastIdx - ls);
  });

  // Round EMA to 2 decimals for stability
  const ema7 = {};
  keys.forEach((k) => {
    ema7[k] = emaState[k] == null ? null : Number(emaState[k].toFixed(2));
  });

  return { ema7, stale_days };
}

function nestSources(flatSources, extra = {}) {
  return {
    ...flatSources,
    activity: {
      ...(flatSources?.steps_count || {}),
      policy: extra?.activity_policy || null,
      from_date: extra?.activity_from_date || null,
    },
  };
}

function dayMinus(dateKey, n) {
  const d = parseDateKey(dateKey);
  d.setUTCDate(d.getUTCDate() - n);
  return dateKeyInTZ(d, "UTC"); // keep YYYY-MM-DD (UTC-safe)
}

function daysSinceOnboarding(onboarded_at_utc, dateKey, tz) {
  if (!onboarded_at_utc) return null;
  const dOn = onboarded_at_utc?.toDate?.() || new Date(String(onboarded_at_utc));
  if (!(dOn instanceof Date) || isNaN(dOn)) return null;
  const dTarget = new Date(`${dateKey}T00:00:00Z`);
  const ms = dTarget.getTime() - dOn.getTime();
  return Math.floor(ms / (24 * 3600 * 1000));
}

function numOrNull(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}
