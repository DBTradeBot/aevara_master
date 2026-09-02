// functions/core/ddc_utils.js
// Shared helpers for DDC + vendors (Node 20 / ESM / Firebase Functions v2)

export const round = (n, d = 2) =>
  typeof n === "number" && Number.isFinite(n) ? Number(n.toFixed(d)) : n;

export const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
export const clamp01 = (x) => clamp(Number(x), 0, 1);
export const pad2 = (n) => String(n).padStart(2, "0");

/* ------------------------------ Hash / stable ------------------------------ */

export function hashOf(obj) {
  try {
    const replacer = (k, v) => (v === undefined ? null : v);
    const ordered = (o) => {
      if (o === null || typeof o !== "object" || Array.isArray(o)) return o;
      return Object.keys(o)
        .sort()
        .reduce((acc, k) => {
          acc[k] = ordered(o[k]);
          return acc;
        }, {});
    };
    const json = JSON.stringify(ordered(obj), replacer);
    let h = 5381;
    for (let i = 0; i < json.length; i++) h = (h * 33) ^ json.charCodeAt(i);
    return (h >>> 0).toString(16);
  } catch (e) {
    return Math.random().toString(16).slice(2);
  }
}

/* -------------------------------- Time/TZ ---------------------------------- */

const DEFAULT_TZ = "America/Los_Angeles";

export function dateKeyInTZ(d, tz = DEFAULT_TZ) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(d).reduce((acc, p) => ((acc[p.type] = p.value), acc), {});
  return `${parts.year}-${parts.month}-${parts.day}`;
}
export function isTodayKey(key, tz = DEFAULT_TZ) {
  return key === dateKeyInTZ(new Date(), tz);
}
export function dayKeysBackInTZ(nDays, tz = DEFAULT_TZ) {
  const keys = [];
  const now = new Date();
  for (let i = 0; i < nDays; i++) {
    const dt = new Date(now);
    dt.setUTCDate(dt.getUTCDate() - i);
    keys.push(dateKeyInTZ(dt, tz));
  }
  return keys;
}
export function parseDateKey(key) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(key))) return null;
  const [y, m, d] = key.split("-").map(Number);
  if (!y || !m || !d) return null;
  const dt = new Date(Date.UTC(y, m - 1, d));
  return Number.isFinite(dt.getTime()) ? dt : null;
}

/* -------------------------------- Regexes ---------------------------------- */

export const HANDLE_RE = /^[a-zA-Z0-9*.]{3,24}$/;
export const isDateKey = (s) => /^\d{4}-\d{2}-\d{2}$/.test(String(s || ""));

/* --------------------------------- EMA ------------------------------------- */

export function ema(prev, value, alpha = 2 / (7 + 1)) {
  const v = Number(value);
  if (!Number.isFinite(v)) return prev ?? null;
  if (prev == null) return v;
  return alpha * v + (1 - alpha) * prev;
}

/**
 * Staleness weight decay.
 * daysStale: 0 â†' 1.0, 1 â†' 1.0, 2""3 â†' 0.9, â‰¥4 â†' 0.75
 */
export function stalenessWeight(daysStale) {
  const d = Number(daysStale || 0);
  if (d <= 1) return 1.0;
  if (d <= 3) return 0.9;
  return 0.75;
}

export function decayValue(value, daysStale) {
  if (value == null) return { value: null, weight: 0 };
  const w = stalenessWeight(daysStale);
  return { value, weight: w };
}

export function reNormalizeWeights(items) {
  const sum = items.reduce((acc, it) => acc + (Number(it.weight) || 0), 0);
  if (sum <= 0) return items.map((it) => ({ ...it, weight: 0 }));
  return items.map((it) => ({ ...it, weight: (Number(it.weight) || 0) / sum }));
}

/* -------------------------- Sex-aware bounds (scaffold) --------------------- */

export function sexAwareBounds(metric, { sex = "unknown", ageYears = 40 } = {}) {
  const s = String(sex || "unknown").toLowerCase();
  const defaults = {
    hrv_rmssd_ms:      { optimal: 60, low: 15,  high: 120 },
    rhr_bpm:           { optimal: 60, low: 40,  high: 90 },
    sleep_total_hours: { optimal: 7.5, low: 5.0, high: 9.5 },
    steps_count:       { optimal: 9000, low: 2000, high: 15000 },
  };
  const base = defaults[metric] || { optimal: 0, low: 0, high: 0 };
  const ageAdj = (ageYears - 40) * 0.2;

  if (metric === "hrv_rmssd_ms") {
    const sexAdj = s === "female" ? -3 : s === "male" ? 0 : -1;
    return {
      optimal: clamp(base.optimal + sexAdj - ageAdj, 10, 200),
      low:     clamp(base.low - ageAdj, 5,  180),
      high:    clamp(base.high - ageAdj,20, 240),
    };
  }
  if (metric === "rhr_bpm") {
    const sexAdj = s === "female" ? +2 : s === "male" ? 0 : +1;
    return {
      optimal: clamp(base.optimal + sexAdj + ageAdj * 0.2, 35, 100),
      low:     clamp(base.low + sexAdj,  30, 100),
      high:    clamp(base.high + sexAdj, 50, 120),
    };
  }
  return base;
}

/* ------------------------------- Units normalize --------------------------- */
/**
 * normalizeUnits(input)
 *  - height_cm: accepts meters or inches if obviously not cm (tight rules)
 *  - weight_kg: accepts lb if obviously not kg
 */
export function normalizeUnits({ height_cm, weight_kg }) {
  let h = Number(height_cm);
  let w = Number(weight_kg);

  if (Number.isFinite(h)) {
    if (h > 0.5 && h < 2.5)        h = h * 100;          // meters â†' cm
    else if (h >= 48 && h <= 84)   h = h * 2.54;         // inches â†' cm
  } else h = null;

  if (Number.isFinite(w)) {
    if (w > 130 && w < 500)        w = w * 0.45359237;   // lb â†' kg
  } else w = null;

  return {
    height_cm: Number.isFinite(h) ? round(h, 1) : null,
    weight_kg: Number.isFinite(w) ? round(w, 1) : null,
  };
}

/* ------------------------------- Percentiles ------------------------------- */
/** Minimal, monotonic mappings used for transparency/debug UIs. */
export function valueToPercentile(metric, value, ctx = {}) {
  const v = Number(value);
  if (!Number.isFinite(v)) return null;
  if (metric === "hrv_rmssd_ms")      return clamp01((v - 15) / (110 - 15));
  if (metric === "rhr_bpm")           return clamp01(1 - (v - 40) / (90 - 40));
  if (metric === "sleep_total_hours") return clamp01((v - 5) / (9.5 - 5));
  if (metric === "steps_count")       return clamp01((v - 2000) / (12000 - 2000));

  // Slow anchors (coarse, for UI only; compute logic is in anchors.js)
  if (metric === "bmi")               return clamp01(1 - Math.abs(v - 22) / 10);
  if (metric === "whtr")              return clamp01(1 - Math.abs(v - 0.45) / 0.15);
  if (metric === "bp_sys")            return clamp01(1 - Math.abs(v - 110) / 25);
  if (metric === "bp_dia")            return clamp01(1 - Math.abs(v - 70) / 15);
  if (metric === "hba1c_pct")         return clamp01(1 - Math.abs(v - 5.2) / 1.0);
  if (metric === "fasting_mmol_L")    return clamp01(1 - Math.abs(v - 4.9) / 1.3);
  if (metric === "vo2max_ml_kg_min") {
    const sex = String(ctx?.sex || "").toLowerCase();
    const tgt = sex === "female" ? 38 : 45;
    return clamp01((v - (tgt - 10)) / 15);
  }
  return 0.5;
}

/* ---------------------------------- Cache ---------------------------------- */
const _memo = new Map(); // key â†' { at, val }
export async function memoizeTtl(name, key, ttlMs, computeFn) {
  const fullKey = `${name}:${key}`;
  const now = Date.now();
  const cached = _memo.get(fullKey);
  if (cached && now - cached.at < ttlMs) return cached.val;
  const val = await computeFn();
  _memo.set(fullKey, { at: now, val });
  return val;
}



