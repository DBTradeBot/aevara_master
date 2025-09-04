import { db, FieldValue, Timestamp } from "../core/firebase_admin.js";
// provider_aliases.js
// ESM module
// - Canonicalizes vendor names
// - Provides metric alias read helpers
// - Encodes provider quality precedence per metric
// - Small numeric guards

/* --------------------------- Provider canonical --------------------------- */

const PROVIDER_CANON = {
  fitbit: "fitbit",
  oura: "oura",
  garmin: "garmin",
  whoop: "whoop",
  apple: "apple",        // Apple Health
  healthkit: "apple",    // legacy alias
  googlefit: "googlefit",
  "google_fit": "googlefit",
  "google-fit": "googlefit",
};

/** Return canonical provider id or null */
export function canonicalProvider(p) {
  if (!p) return null;
  const k = String(p).trim().toLowerCase();
  return PROVIDER_CANON[k] || null;
}

/* ------------------------------ Metric aliases --------------------------- */
/**
 * We normalize a small set of canonical metrics used across the pipeline.
 * The read helper checks multiple possible field names vendors may write.
 *
 * Canonical metrics we support:
 *  - hrv_rmssd_ms
 *  - rhr_bpm
 *  - sleep_total_hours
 *  - sleep_regularity_pct
 *  - steps_count
 *  - vo2max_ml_kg_min
 *  - fitness_age_years
 *  - calories_out
 *  - distance_km
 *  - wellbeing_level_1to5
 */
const ALIASES = {
  hrv_rmssd_ms: [
    "hrv_rmssd_ms",
    "hrv.rmssd_ms",
    "rmssd_ms",
    "rmssd",
    "hrv.dailyRmssd",
    "hrv.lastNightRmssd",
  ],
  rhr_bpm: [
    "rhr_bpm",
    "resting_hr_bpm",
    "restingHeartRate",
    "resting_heart_rate",
    "rhr",
  ],
  sleep_total_hours: [
    "sleep_total_hours",
    "sleep.total_hours",
    "sleep_hours",
    "totalSleepHours",
    "sleep.total_hours_num",
    "sleep.total_minutes_asleep", // might be minutes → handled in readMetricWithAliases
  ],
  sleep_regularity_pct: [
    "sleep_regularity_pct",
    "sleep.regularity_pct",
    "sleep_regularity",
  ],
  steps_count: [
    "steps_count",
    "steps",
    "summary.steps",
    "activity.steps",
  ],
  vo2max_ml_kg_min: [
    "vo2max_ml_kg_min",
    "vo2max",
    "cardio_fitness.vo2max",
    "cardio.vo2max",
  ],
  fitness_age_years: [
    "fitness_age_years",
    "fitness_age",
  ],
  calories_out: [
    "calories_out",
    "calories",
    "summary.caloriesOut",
    "activity.calories",
  ],
  distance_km: [
    "distance_km",
    "distance",
    "summary.distance_km",
    "activity.distance_km",
    "summary.distances.total", // Fitbit total is already km
  ],
  wellbeing_level_1to5: [
    "wellbeing_level_1to5",
    "wellbeing.level_1to5",
    "manual.wellbeing_level_1to5",
  ],
};

/** Safe getter for dotted paths */
function getPath(obj, path) {
  try {
    if (!obj || !path) return undefined;
    if (path.includes(".")) {
      return path.split(".").reduce((acc, k) => (acc == null ? undefined : acc[k]), obj);
    }
    return obj[path];
  } catch {
    return undefined;
  }
}

/**
 * Heuristics to fix units when aliases point to vendor-specific raw fields.
 * Currently:
 *  - sleep.total_minutes_asleep → convert to hours
 */
function normalizeValueForKey(key, raw) {
  if (raw == null) return raw;
  if (key === "sleep.total_minutes_asleep") {
    const n = Number(raw);
    return Number.isFinite(n) ? n / 60 : null;
  }
  return raw;
}

/**
 * Returns { value, aliasUsed } for the canonical metric.
 * If not found returns { value: null, aliasUsed: null }.
 */
export function readMetricWithAliases(doc, canonicalMetric) {
  const list = ALIASES[canonicalMetric] || [canonicalMetric];
  for (const alias of list) {
    let v = getPath(doc, alias);
    if (v == null) continue;
    v = normalizeValueForKey(alias, v);

    // Numeric normalization
    if (typeof v === "string" && v.trim() !== "") {
      const num = Number(v);
      if (!Number.isNaN(num)) v = num;
    }

    // distance: accept nested Fitbit style { summary: { distances: [{activity:'total', distance: X}] } }
    if (canonicalMetric === "distance_km" && v == null) {
      const arr = getPath(doc, "summary.distances");
      if (Array.isArray(arr)) {
        const total = arr.find(d => d?.activity === "total");
        if (total?.distance != null) {
          v = Number(total.distance);
        }
      }
    }

    // basic sanity trims
    if (typeof v === "number" && !Number.isFinite(v)) continue;

    return { value: v, aliasUsed: alias };
  }
  return { value: null, aliasUsed: null };
}

/* --------------------------- Provider quality map ------------------------ */
/**
 * Order providers by trust/quality for each metric (higher priority first).
 * The merge layer will choose first available provider in this list.
 */
export const PROVIDER_QUALITY = {
  hrv_rmssd_ms:    ["oura", "whoop", "garmin", "fitbit", "apple", "googlefit"],
  rhr_bpm:         ["oura", "whoop", "garmin", "fitbit", "apple", "googlefit"],
  sleep_total_hours:["oura", "whoop", "fitbit", "garmin", "apple", "googlefit"],
  sleep_regularity_pct: ["oura", "whoop", "fitbit", "garmin", "apple", "googlefit"],
  steps_count:     ["fitbit", "garmin", "apple", "googlefit", "whoop", "oura"],
  vo2max_ml_kg_min:["garmin", "fitbit", "apple", "googlefit", "whoop", "oura"],
  fitness_age_years:["garmin", "fitbit", "apple", "googlefit", "whoop", "oura"],
  calories_out:    ["fitbit", "garmin", "apple", "googlefit", "whoop", "oura"],
  distance_km:     ["garmin", "fitbit", "apple", "googlefit", "whoop", "oura"],
  wellbeing_level_1to5: ["fitbit", "apple", "googlefit", "garmin", "oura", "whoop"],
};

/* ------------------------------ Small guards ----------------------------- */

export function isEffectivelyZero(v, eps = 1e-9) {
  const n = Number(v);
  if (!Number.isFinite(n)) return false;
  return Math.abs(n) <= eps;
}

export default {
  canonicalProvider,
  readMetricWithAliases,
  PROVIDER_QUALITY,
  isEffectivelyZero,
};

