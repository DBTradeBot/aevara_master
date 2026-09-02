/**
 * core/ddc_shared.js
 * Shared initialization, date/TZ utilities, hashing, model cache,
 * and slow "anchors" loader (fixed + memoized).
 * Node 20 / ESM / Firebase Functions v2
 */
import { db } from "../core/firebase_admin.js";
import { createHash } from "crypto";

// --- Constants ---
export const DEFAULT_TZ = "America/Los_Angeles";
export const FINALIZE_HOUR_LOCAL = 3; // 03:00 local, D+1

// --- Small math helpers ---
export const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
export const clamp01 = (x) => clamp(x, 0, 1);
export const round = (n, d = 2) => (typeof n === "number" ? Number(n.toFixed(d)) : n);
export const pad2 = (n) => String(n).padStart(2, "0");

// --- Deterministic hash of JSON-ish object ---
export function hashOf(obj) {
  try {
    const replacer = (k, v) => (v === undefined ? null : v);
    const ordered = (o) => {
      if (o === null || typeof o !== "object" || Array.isArray(o)) return o;
      return Object.keys(o)
        .sort()
        .reduce((acc, key) => {
          acc[key] = ordered(o[key]);
          return acc;
        }, {});
    };
    const s = JSON.stringify(ordered(obj), replacer);
    return createHash("sha1").update(s).digest("hex");
  } catch (e) {
    return null;
  }
}

// --- Date/TZ helpers ---
export function todayKeyInTZ(tz = DEFAULT_TZ) {
  const now = new Date();
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })
    .formatToParts(now)
    .reduce((acc, p) => ((acc[p.type] = p.value), acc), {});
  return `${parts.year}-${parts.month}-${parts.day}`;
}

export function isTodayKey(dateKey, tz = DEFAULT_TZ) {
  return dateKey === todayKeyInTZ(tz);
}

export async function loadUserTZ(uid) {
  try {
    const u = await db.doc(`users/${uid}`).get();
    return (u.exists ? (u.data()?.tz || u.data()?.timezone) : null) || DEFAULT_TZ;
  } catch (e) {
    return DEFAULT_TZ;
  }
}

export function localHourInTZ(tz = DEFAULT_TZ) {
  try {
    const s = new Intl.DateTimeFormat("en-GB", {
      timeZone: tz,
      hour: "2-digit",
      hour12: false,
    }).format(new Date());
    return parseInt(s, 10);
  } catch (e) {
    return new Date().getHours();
  }
}

export function keyMinusDays(dateKey, n) {
  const d = new Date(`${dateKey}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - Number(n || 0));
  return d.toISOString().slice(0, 10);
}

export function keyPlusDays(dateKey, n) {
  const d = new Date(`${dateKey}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + Number(n || 0));
  return d.toISOString().slice(0, 10);
}

export function dayKeysBackInTZ(n = 30, tz = DEFAULT_TZ) {
  const keys = [];
  const now = new Date();
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const toKey = (d) => {
    const parts = fmt
      .formatToParts(d)
      .reduce((acc, p) => ((acc[p.type] = p.value), acc), {});
    return `${parts.year}-${parts.month}-${parts.day}`;
  };
  const base = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  for (let i = 0; i < n; i++) {
    const d = new Date(base);
    d.setUTCDate(d.getUTCDate() - i);
    keys.push(toKey(d));
  }
  return [...new Set(keys)].sort();
}

export function finalizeCutoffPassedFor(dateKey, tz = DEFAULT_TZ) {
  // true if now >= D+1 03:00 local
  const dPlus1 = keyPlusDays(dateKey, 1);
  const nowHour = localHourInTZ(tz);
  const todayInTz = todayKeyInTZ(tz);
  if (todayInTz > dPlus1) return true;
  if (todayInTz < dPlus1) return false;
  return nowHour >= FINALIZE_HOUR_LOCAL;
}

export function localDatePartsForKey(dateKey, tz = DEFAULT_TZ) {
  const d = new Date(`${dateKey}T00:00:00Z`);
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })
    .formatToParts(d)
    .reduce((acc, p) => ((acc[p.type] = p.value), acc), {});
  return { y: Number(parts.year), m: Number(parts.month), d: Number(parts.day) };
}

// --- Age helpers ---
function _toDateSafe(x) {
  if (!x) return null;
  if (x instanceof Date) return x;
  if (typeof x?.toDate === "function") return x.toDate();
  if (typeof x === "object" && typeof x.seconds === "number") return new Date(x.seconds * 1000);
  const d = new Date(x);
  return Number.isNaN(d.getTime()) ? null : d;
}
export function ageFromDob(dob) {
  const d = _toDateSafe(dob);
  if (!d) return null;
  const now = new Date();
  let a = now.getUTCFullYear() - d.getUTCFullYear();
  const m = now.getUTCMonth() - d.getUTCMonth();
  if (m < 0 || (m === 0 && now.getUTCDate() < d.getUTCDate())) a--;
  return a;
}

// --- Model config cache ---
let _modelCache = null;
let _modelCacheAt = 0;
export async function loadModelConfig() {
  const FRESH_MS = 60_000;
  const now = Date.now();
  if (_modelCache && now - _modelCacheAt < FRESH_MS) return _modelCache;
  const snap = await db.doc("models/v1").get();
  _modelCache = snap.exists ? (snap.data() || {}) : {};
  _modelCacheAt = now;
  return _modelCache;
}

// --- Anchors loader (FIXED + memoized) ---
// Reads slow-changing anchors from:
//   users/{uid} â†' sex, height_cm, weight_kg, waist_cm (legacy aliases supported)
//   users/{uid}/biometrics_bp           (latest) â†' systolic/diastolic
//   users/{uid}/biometrics_glucose      (latest) â†' hba1c_pct or fasting value (normalized to mmol/L)
const _anchorsMemo = new Map(); // uid -> { at: ms, value }

export async function loadAnchors(uid) {
  const now = Date.now();
  const cache = _anchorsMemo.get(uid);
  if (cache && now - cache.at < 60_000) return cache.value; // 60s memo

  const uSnap = await db.doc(`users/${uid}`).get();
  const u = uSnap.exists ? (uSnap.data() || {}) : {};

  // tolerate legacy fields
  const sexRaw = u.profile?.sex ?? u.sex ?? u.gender ?? null;
  const sex =
    (sexRaw != null ? String(sexRaw).toLowerCase() : null) || null;

  const profile = {
    sex,
    height_cm: u.profile?.height_cm ?? u.height_cm ?? null,
    weight_kg: u.profile?.weight_kg ?? u.weight_kg ?? null,
    waist_cm:  u.profile?.waist_cm  ?? u.waist_cm  ?? null,
  };

  // latest BP reading
  let bp = null;
  try {
    const bpSnap = await db
      .collection(`users/${uid}/biometrics_bp`)
      .orderBy("measured_at_utc", "desc")
      .limit(1)
      .get();
    if (!bpSnap.empty) {
      const d = bpSnap.docs[0].data() || {};
      const sys = d.systolic ?? d.sys ?? null;
      const dia = d.diastolic ?? d.dia ?? null;
      if (sys != null && dia != null) bp = { sys: Number(sys), dia: Number(dia) };
    }
  } catch (e) {
    // best-effort
  }

  // latest glucose reading (prefer A1c; else fasting normalized to mmol/L)
  let glucose = null;
  try {
    const gSnap = await db
      .collection(`users/${uid}/biometrics_glucose`)
      .orderBy("measured_at_utc", "desc")
      .limit(1)
      .get();
    if (!gSnap.empty) {
      const d = gSnap.docs[0].data() || {};
      if (d.hba1c_pct != null) {
        glucose = { hba1c_pct: Number(d.hba1c_pct) };
      } else if (d.value != null) {
        const unit = (d.unit || "").toLowerCase();
        let fasting_mmol_L = null;
        if (unit === "mmol_l" || unit === "mmol/l") fasting_mmol_L = Number(d.value);
        else if (unit === "mg_dl" || unit === "mg/dl") fasting_mmol_L = Number(d.value) * 0.0555;
        if (fasting_mmol_L != null)
          glucose = { fasting_mmol_L: Number(fasting_mmol_L.toFixed(2)) };
      }
    }
  } catch (e) {
    // best-effort
  }

  const value = { profile, bp, glucose };
  _anchorsMemo.set(uid, { at: now, value });
  return value;
}

// --- Export a small public surface for other core modules ---
export default {
  db,
  DEFAULT_TZ,
  FINALIZE_HOUR_LOCAL,
  clamp,
  clamp01,
  round,
  pad2,
  hashOf,
  todayKeyInTZ,
  isTodayKey,
  loadUserTZ,
  localHourInTZ,
  keyMinusDays,
  keyPlusDays,
  dayKeysBackInTZ,
  finalizeCutoffPassedFor,
  localDatePartsForKey,
  ageFromDob,
  loadModelConfig,
  loadAnchors,
};



