import { db, FieldValue, Timestamp } from "./firebase_admin.js";
// functions/core/compute.js
// Pure compute: from inputs + anchors + model config → scores & drivers
// Node 20 / ESM

import {
  round,
  clamp01,
  clamp,
  ema,
  decayValue,
  reNormalizeWeights,
  sexAwareBounds,
  valueToPercentile,
  hashOf,
} from "./ddc_utils.js";

/**
 * computeScores({ inputs, anchors, modelCfg, dynamic, options })
 *
 * Required:
 *  - inputs: {
 *      hrv_rmssd_ms?, rhr_bpm?, sleep_total_hours?, steps_count?,
 *      mood_level_1to5?, stress_level_1to5?,
 *      stale_days?: { metric: days }, ema7?: { metric: number }
 *    }
 *  - anchors: { age_years?, sex?, ... }
 *  - modelCfg: { version, groups{recovery,sleep,activity,affect}, scale_years, pivot_risk, caps{daily_va_abs,total_va_abs}, change_cooldown_sec }
 *  - dynamic:  { pivot_risk, scale_years, window:{size,first,last} }  // usually from dynamic_window.chooseDynamicParams
 *
 * Returns:
 * {
 *   risk_index, vitality_age, score_confidence,
 *   groups: { recovery, sleep, activity, affect },
 *   metrics: { hrv_rmssd_ms, rhr_bpm, sleep_total_hours, steps_count, mood_level_1to5, stress_level_1to5 },
 *   drivers: { positives: [...], negatives: [...] },
 *   freshness: { hrv_fresh, rhr_fresh, sleep_fresh, steps_fresh },
 *   hashes: { inputs_hash, compute_hash },
 * }
 */
export function computeScores({ inputs = {}, anchors = {}, modelCfg = {}, dynamic = {}, options = {} }) {
  const sex = String(anchors?.sex || "unknown");
  const ageYears = Number(anchors?.age_years ?? 40) || 40;

  // Model + dynamic params (dynamic overrides config)
  const pivot_risk = Number(dynamic?.pivot_risk ?? modelCfg?.pivot_risk ?? 0.35) || 0.35;
  const scale_years = Number(dynamic?.scale_years ?? modelCfg?.scale_years ?? 12) || 12;

  const W = {
    recovery: Number(modelCfg?.groups?.recovery ?? 0.4),
    sleep: Number(modelCfg?.groups?.sleep ?? 0.3),
    activity: Number(modelCfg?.groups?.activity ?? 0.3),
    affect: Number(modelCfg?.groups?.affect ?? 0.0),
  };

  const caps = {
    daily_va_abs: Number(modelCfg?.caps?.daily_va_abs ?? 1.0),
    total_va_abs: Number(modelCfg?.caps?.total_va_abs ?? 10),
  };

  // Raw inputs (may be null)
  const x = {
    hrv_rmssd_ms: numOrNull(inputs.hrv_rmssd_ms),
    rhr_bpm: numOrNull(inputs.rhr_bpm),
    sleep_total_hours: numOrNull(inputs.sleep_total_hours),
    steps_count: numOrNull(inputs.steps_count),
    mood_level_1to5: numOrNull(inputs.mood_level_1to5),
    stress_level_1to5: numOrNull(inputs.stress_level_1to5),
  };

  // EMA & staleness (optional)
  const ema7 = inputs.ema7 || {};
  const stale = inputs.stale_days || {};

  // Inject EMA fallback for missing key metrics (first-run stability)
  if (x.hrv_rmssd_ms == null && numOrNull(ema7.hrv_rmssd_ms) != null) x.hrv_rmssd_ms = numOrNull(ema7.hrv_rmssd_ms);
  if (x.rhr_bpm == null && numOrNull(ema7.rhr_bpm) != null) x.rhr_bpm = numOrNull(ema7.rhr_bpm);
  if (x.sleep_total_hours == null && numOrNull(ema7.sleep_total_hours) != null) x.sleep_total_hours = numOrNull(ema7.sleep_total_hours);
  if (x.steps_count == null && numOrNull(ema7.steps_count) != null) x.steps_count = numOrNull(ema7.steps_count);

  // --- Per-metric 0–100 scores (higher is better) ---
  // Recovery: combine HRV (positive) + RHR (inverse) with 0.6 : 0.4 (scaffold)
  const bHRV = sexAwareBounds("hrv_rmssd_ms", { sex, ageYears });
  const bRHR = sexAwareBounds("rhr_bpm", { sex, ageYears });

  const score_hrv = scoreFromPercentile("hrv_rmssd_ms", x.hrv_rmssd_ms, { sex, ageYears }, bHRV);
  const score_rhr = scoreFromPercentile("rhr_bpm", x.rhr_bpm, { sex, ageYears }, bRHR);

  // Sleep: hours (U-shape approximated via percentile scaffold)
  const bS = sexAwareBounds("sleep_total_hours", { sex, ageYears });
  const score_sleep = scoreFromPercentile("sleep_total_hours", x.sleep_total_hours, { sex, ageYears }, bS);

  // Activity: steps/day (scaffold)
  const bA = sexAwareBounds("steps_count", { sex, ageYears });
  const score_steps = scoreFromPercentile("steps_count", x.steps_count, { sex, ageYears }, bA);

  // Affect: mood/stress mapped to [0–100], optional (defaults to neutral 50 if both missing)
  const score_mood = x.mood_level_1to5 != null ? clamp01((x.mood_level_1to5 - 1) / 4) * 100 : null;
  const score_stressInv = x.stress_level_1to5 != null ? clamp01((5 - x.stress_level_1to5) / 4) * 100 : null;
  const score_affect =
    score_mood == null && score_stressInv == null
      ? null
      : average([score_mood, score_stressInv].filter((v) => v != null));

  // Recovery blend
  const rec_items = weightAndDecay(
    [
      { name: "hrv_rmssd_ms", score: score_hrv, weight: 0.6, daysStale: stale.hrv_rmssd_ms ?? 0 },
      { name: "rhr_bpm", score: score_rhr, weight: 0.4, daysStale: stale.rhr_bpm ?? 0 },
    ].filter((it) => it.score != null)
  );
  const score_recovery = weightedAverage(rec_items);

  // Sleep / Activity (apply decay weights where stale)
  const scl_items = weightAndDecay(
    [{ name: "sleep_total_hours", score: score_sleep, weight: 1, daysStale: stale.sleep_total_hours ?? 0 }].filter(
      (it) => it.score != null
    )
  );
  const act_items = weightAndDecay(
    [{ name: "steps_count", score: score_steps, weight: 1, daysStale: stale.steps_count ?? 0 }].filter((it) => it.score != null)
  );
  const aff_items =
    score_affect == null ? [] : weightAndDecay([{ name: "affect", score: score_affect, weight: 1, daysStale: 0 }]);

  const groupScores = {
    recovery: nOrNull(round(weightedAverage(rec_items), 1)),
    sleep: nOrNull(round(weightedAverage(scl_items), 1)),
    activity: nOrNull(round(weightedAverage(act_items), 1)),
    affect: nOrNull(round(weightedAverage(aff_items), 1)),
  };

  // --- Risk index (0 good → 1 bad) via weighted deficit from 100 ---
  const observed = [
    ...(groupScores.recovery != null ? [{ w: W.recovery, deficit: 1 - groupScores.recovery / 100 }] : []),
    ...(groupScores.sleep != null ? [{ w: W.sleep, deficit: 1 - groupScores.sleep / 100 }] : []),
    ...(groupScores.activity != null ? [{ w: W.activity, deficit: 1 - groupScores.activity / 100 }] : []),
    ...(groupScores.affect != null ? [{ w: W.affect, deficit: 1 - groupScores.affect / 100 }] : []),
  ];
  const wsum = observed.reduce((a, b) => a + b.w, 0);
  const risk_index = wsum > 0 ? clamp01(observed.reduce((a, b) => a + b.w * b.deficit, 0) / wsum) : 0.35;

  // Vitality Age mapping
  const chrono = Number(options?.chrono_age_years ?? anchors?.age_years ?? 40) || 40;
  let raw_va = chrono + scale_years * (risk_index - pivot_risk);
  // Cap absolute offset
  const offset = clamp(raw_va - chrono, -caps.total_va_abs, caps.total_va_abs);
  const vitality_age = round(chrono + offset, 1);

  // Confidence (completeness × freshness penalty)
  const completeness = clamp01(wsum / (W.recovery + W.sleep + W.activity + W.affect || 1));
  const stalePenalty = freshnessPenalty(stale);
  const score_confidence = Math.round(100 * completeness * (1 - stalePenalty));

  // Drivers summary (light; UI can expand)
  const drivers = extractDrivers({ groupScores, score_hrv, score_rhr, score_sleep, score_steps, score_affect });

  // Freshness booleans for UI
  const freshness = {
    hrv_fresh: (stale.hrv_rmssd_ms ?? 99) <= 1,
    rhr_fresh: (stale.rhr_bpm ?? 99) <= 1,
    sleep_fresh: (stale.sleep_total_hours ?? 99) <= 1,
    steps_fresh: (stale.steps_count ?? 99) <= 1,
  };

  // Hashes
  const inputs_hash = hashOf({
    x,
    ema7,
    stale,
    sex,
    ageYears,
  });
  const compute_hash = hashOf({
    inputs_hash,
    model: { pivot_risk, scale_years, W, caps },
    window: dynamic?.window || null,
  });

  return {
    risk_index: round(risk_index, 4),
    vitality_age,
    score_confidence,
    groups: groupScores,
    metrics: x,
    drivers,
    freshness,
    hashes: { inputs_hash, compute_hash },
    dynamic_used: {
      pivot_risk,
      scale_years,
      window: dynamic?.window || null,
    },
  };
}

/* ------------------------------- helpers ----------------------------------- */

function numOrNull(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function nOrNull(n) {
  return Number.isFinite(Number(n)) ? Number(n) : null;
}

function scoreFromPercentile(metric, v, ctx, bounds) {
  if (v == null) return null;
  // If we had real curves, we'd use them. For now we use valueToPercentile scaffold.
  const p = valueToPercentile(metric, v, ctx);
  return round(100 * p, 1);
}

function average(arr) {
  if (!arr.length) return null;
  const s = arr.reduce((a, b) => a + b, 0);
  return s / arr.length;
}

function weightAndDecay(items) {
  if (!items.length) return [];
  const decayed = items.map((it) => {
    const d = decayValue(it.score, it.daysStale);
    return { ...it, weight: (it.weight || 1) * d.weight };
  });
  return reNormalizeWeights(decayed);
}

function weightedAverage(items) {
  if (!items.length) return null;
  const s = items.reduce((a, b) => a + (b.score || 0) * (b.weight || 0), 0);
  const w = items.reduce((a, b) => a + (b.weight || 0), 0);
  return w > 0 ? s / w : null;
}

function freshnessPenalty(stale = {}) {
  const ds = [
    stale.hrv_rmssd_ms,
    stale.rhr_bpm,
    stale.sleep_total_hours,
    stale.steps_count,
  ].map((d) => Number.isFinite(Number(d)) ? Number(d) : 99);

  // Map: 0–1d: 0, 2–3d: 0.10, ≥4d: 0.25; average across present metrics
  const penalties = ds
    .filter((d) => d !== 99)
    .map((d) => (d <= 1 ? 0 : d <= 3 ? 0.10 : 0.25));

  if (!penalties.length) return 0.25; // conservative when unknown
  const avg = penalties.reduce((a, b) => a + b, 0) / penalties.length;
  return clamp(avg, 0, 0.35);
}

function extractDrivers({ groupScores, score_hrv, score_rhr, score_sleep, score_steps, score_affect }) {
  const positives = [];
  const negatives = [];
  const push = (arr, label, detail) => arr.push({ label, detail });

  const add = (score, name, good, bad) => {
    if (score == null) return;
    if (score >= 70) push(positives, name, `strong (${score})`);
    else if (score < 50) push(negatives, name, `weak (${score})`);
  };

  add(groupScores.recovery, "Recovery", "strong", "weak");
  add(groupScores.sleep, "Sleep", "strong", "weak");
  add(groupScores.activity, "Activity", "strong", "weak");
  if (score_affect != null) add(groupScores.affect, "Mood/Stress", "strong", "weak");

  // Specific hints
  if (score_sleep != null && score_sleep < 50) push(negatives, "Sleep hours", `low (${score_sleep})`);
  if (score_hrv != null && score_hrv < 50) push(negatives, "HRV", `low (${score_hrv})`);
  if (score_rhr != null && score_rhr < 50) push(negatives, "Resting HR", `high (${score_rhr})`);
  if (score_steps != null && score_steps < 50) push(negatives, "Steps", `low (${score_steps})`);

  if (score_sleep != null && score_sleep >= 75) push(positives, "Sleep hours", `solid (${score_sleep})`);
  if (score_hrv != null && score_hrv >= 75) push(positives, "HRV", `solid (${score_hrv})`);
  if (score_rhr != null && score_rhr >= 75) push(positives, "Resting HR", `solid (${score_rhr})`);
  if (score_steps != null && score_steps >= 75) push(positives, "Steps", `solid (${score_steps})`);

  return { positives, negatives };
}

