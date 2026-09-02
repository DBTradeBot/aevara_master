// functions/vendor/fitbit_fetch.js
// Fitbit fetchers — priority-first (N=4) + bounded backfill (default 14 days)
// Node 20 / ESM / Firebase Functions v2

import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { verifyAppCheckOrScheduler } from "../core/app_check.js";

if (!getApps().length) initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const REGION = "us-central1";
const API_BASE = "https://api.fitbit.com/1/user/-";
const DEFAULT_TZ = "America/Los_Angeles";
const PRIORITY_RECENT_N = 4;           // always fetch most-recent 4 first
const BACKFILL_LOOKBACK_DEFAULT = 14;  // bounded backfill window (used when backfill=true)
const CHUNK_READ = 20;                 // Firestore batch gets
const RETRIES = 3;                     // fetch retries per endpoint
const COMPUTE_DELAY_MS = 300;          // small stagger between compute calls
const BACKFILL_DELAY_MS = 250;         // small stagger between non-priority pulls
const SYNC_SECRET = process.env.FITBIT_SYNC_SECRET || null;

const PROJECT =
  process.env.GCLOUD_PROJECT ||
  process.env.GCP_PROJECT ||
  (process.env.FIREBASE_CONFIG
    ? (() => {
        try {
          return JSON.parse(process.env.FIREBASE_CONFIG)?.projectId || "";
        } catch {
          return "";
        }
      })()
    : "") ||
  "";

const REFRESH_URL = `https://${REGION}-${PROJECT}.cloudfunctions.net/fitbitRefresh`;
// Prefer explicit env override for scorer; fall back to legacy deployed URL.
const COMPUTE_URL =
  process.env.VITALITY_COMPUTE_URL ||
  `https://${REGION}-${PROJECT}.cloudfunctions.net/vitalityComputeHttp`;

/* ─────────────────────────── Utils ─────────────────────────── */

const sleepMs = (ms) => new Promise((r) => setTimeout(r, ms));

function round(n, d = 2) {
  return typeof n === "number" && Number.isFinite(n) ? Number(n.toFixed(d)) : n;
}
function dateKeyInTZ(d, tz) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz || DEFAULT_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })
    .formatToParts(d)
    .reduce((o, p) => ((o[p.type] = p.value), o), {});
  return `${parts.year}-${parts.month}-${parts.day}`;
}
function dayMinus(key, n = 1) {
  const d = new Date(`${key}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() - Number(n || 0));
  return d.toISOString().slice(0, 10);
}
function dayKeysBackInTZ(nDays, tz) {
  const keys = [];
  const now = new Date();
  for (let i = 0; i < nDays; i++) {
    const dt = new Date(now);
    dt.setUTCDate(dt.getUTCDate() - i);
    keys.push(dateKeyInTZ(dt, tz));
  }
  return keys;
}
function isTodayKey(key, tz = DEFAULT_TZ) {
  return key === dateKeyInTZ(new Date(), tz);
}
function isExpired(expires_at_utc) {
  if (!expires_at_utc) return true;
  const skewMs = 60 * 1000; // refresh a minute early
  return new Date(expires_at_utc).getTime() - skewMs <= Date.now();
}
function uniqueSorted(keys) {
  return Array.from(new Set(keys)).sort();
}

/* ───────────────────── HTTP fetch w/ retry ───────────────────── */

function isRetriableStatus(code) {
  return code === 429 || code === 408 || (code >= 500 && code <= 599);
}
async function fetchWithRetry(
  url,
  options = {},
  { tries = RETRIES, base = 400, factor = 2, cap = 8000 } = {}
) {
  let lastErr = null;
  for (let i = 0; i < tries; i++) {
    try {
      const resp = await fetch(url, options);
      if (!resp.ok) {
        if (isRetriableStatus(resp.status) && i < tries - 1) {
          const delay =
            Math.min(cap, base * Math.pow(factor, i)) * (0.5 + Math.random());
          logger.warn("fetch backoff", {
            url,
            status: resp.status,
            try: i + 1,
            delayMs: Math.round(delay),
          });
          await sleepMs(delay);
          continue;
        }
        const text = await resp.text().catch(() => "");
        const e = new Error(`HTTP ${resp.status} ${text?.slice(0, 200) || ""}`);
        e.status = resp.status;
        throw e;
      }
      return resp;
    } catch (e) {
      lastErr = e;
      if (i < tries - 1) {
        const delay =
          Math.min(cap, base * Math.pow(factor, i)) * (0.5 + Math.random());
        logger.warn("fetch error/backoff", {
          url,
          err: String(e?.message || e),
          try: i + 1,
          delayMs: Math.round(delay),
        });
        await sleepMs(delay);
        continue;
      }
      break;
    }
  }
  throw lastErr || new Error("fetchWithRetry failed");
}
async function callFitbit(accessToken, endpoint) {
  const url = `${API_BASE}/${endpoint}`;
  const resp = await fetchWithRetry(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  return resp.json();
}

/* ─────────────────────────── Concurrency lock ───────────────────────── */

function lockRefFor(uid, provider = "fitbit") {
  return db.doc(`locks/sync_${provider}_${uid}`);
}
async function acquireLock(uid, { ttlMs = 120000 } = {}) {
  const ref = lockRefFor(uid);
  const token = Math.random().toString(36).slice(2);
  const now = Date.now();
  const expiresAt = now + ttlMs;

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : null;
    const existingExpires = data?.expires_at_ms || 0;
    const owned = data?.owner_token === token;
    const expired = existingExpires < now;
    if (!snap.exists || expired || owned) {
      tx.set(ref, {
        owner_token: token,
        acquired_at_ms: now,
        expires_at_ms: expiresAt,
        renewals: 0,
      });
      return { ok: true, token, ref };
    }
    return { ok: false, reason: "busy", until_ms: existingExpires };
  });

  return result;
}
async function releaseLock(uid, token) {
  try {
    const ref = lockRefFor(uid);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const data = snap.data() || {};
      if (token && data.owner_token === token) tx.delete(ref);
    });
  } catch {
    // best-effort
  }
}

/* ───────────────────────── Integration helpers ───────────────────────── */

async function mirrorUserIntegrationStatus(uid, patch) {
  await db.doc(`users/${uid}/integrations/fitbit`).set(
    {
      provider: "fitbit",
      updated_at_utc: FieldValue.serverTimestamp(),
      ...patch,
    },
    { merge: true }
  );
}
async function markDisconnected(uid, reason = "revoked") {
  await db.doc(`integrations/fitbit/users/${uid}`).set(
    {
      connected: false,
      last_status: "disconnected",
      error_msg: reason,
      updated_at_utc: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  await mirrorUserIntegrationStatus(uid, {
    connected: false,
    last_status: "disconnected",
    last_sync_utc: FieldValue.serverTimestamp(),
    error_msg: reason,
  });
}
async function refreshIfNeeded(uid, integ) {
  if (!isExpired(integ?.expires_at_utc)) return integ;
  const headers = { "Content-Type": "application/json" };
  if (SYNC_SECRET) headers["x-sync-secret"] = SYNC_SECRET;
  const r = await fetchWithRetry(REFRESH_URL, {
    method: "POST",
    headers,
    body: JSON.stringify({ uid }),
  });
  if (!r.ok) {
    const msg = await r.text().catch(() => "");
    throw new Error(`fitbitRefresh failed: ${r.status} ${msg}`);
  }
  const snap = await db.doc(`integrations/fitbit/users/${uid}`).get();
  return snap.exists ? snap.data() : null;
}
async function loadUserTZ(uid) {
  try {
    const u = await db.doc(`users/${uid}`).get();
    return (u.exists ? (u.data()?.tz || u.data()?.timezone) : null) || DEFAULT_TZ;
  } catch {
    return DEFAULT_TZ;
  }
}

/* ───────────────────── Episode normalization ───────────────────── */

function extractFitbitEpisodes(fitbitSleepJson, tz = DEFAULT_TZ) {
  const out = [];
  if (!fitbitSleepJson) return out;

  const rows = Array.isArray(fitbitSleepJson.sleep) ? fitbitSleepJson.sleep : [];
  for (const ep of rows) {
    let start = ep?.startTime || ep?.startTimeISO || ep?.start || null;
    let end = ep?.endTime || ep?.endTimeISO || ep?.end || null;

    const toUtcIso = (maybeLocal) => {
      if (!maybeLocal) return null;
      const s = String(maybeLocal);
      const hasZ = /[zZ]$/.test(s) || /[+\-]\d\d:?\d\d$/.test(s);
      if (hasZ) {
        const d = new Date(s);
        return Number.isFinite(d.getTime()) ? d.toISOString() : null;
      }
      try {
        const [datePart, timePartRaw] = s.split("T");
        const timePart = (timePartRaw || "00:00:00").padEnd(8, ":00").slice(0, 8);
        const [Y, M, D] = datePart.split("-").map(Number);
        const [h, m, sec] = timePart.split(":").map(Number);
        const local = new Date(Date.UTC(Y, (M || 1) - 1, D || 1, h || 0, m || 0, sec || 0));
        const parts = new Intl.DateTimeFormat("en-CA", {
          timeZone: tz,
          timeZoneName: "shortOffset",
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: false,
        })
          .formatToParts(local)
          .reduce((a, p) => ((a[p.type] = p.value), a), {});
        const tzname = parts.timeZoneName || "GMT+00:00";
        const m_ = /GMT([+\-]\d\d):?(\d\d)/.exec(tzname);
        const offMin = m_ ? Number(m_[1]) * 60 + Math.sign(Number(m_[1])) * Number(m_[2]) : 0;
        const utcMs = local.getTime() - offMin * 60 * 1000;
        const d = new Date(utcMs);
        return d.toISOString();
      } catch {
        const d = new Date(s);
        return Number.isFinite(d.getTime()) ? d.toISOString() : null;
      }
    };

    const start_utc = toUtcIso(start);
    const end_utc = toUtcIso(end);
    if (!start_utc || !end_utc) continue;

    const durH = Math.max(
      0,
      (new Date(end_utc).getTime() - new Date(start_utc).getTime()) / 3600000
    );
    if (!Number.isFinite(durH) || durH <= 0) continue;

    const is_main =
      !!(ep?.isMain || ep?.main || ep?.is_main) ||
      ep?.type === "long_sleep" ||
      ep?.logType === "main" ||
      ep?.levels?.summary?.deep != null;

    out.push({
      start_utc,
      end_utc,
      is_main: !!is_main,
      duration_h: Math.round(durH * 100) / 100,
    });
  }

  return out;
}

/* ─────────────────────────── Pull for a day ───────────────────────── */

async function pullFitbitForDayToSyncDoc(uid, accessToken, dayKey, { includeCrf = true, tz = DEFAULT_TZ } = {}) {
  // activity
  let steps = null,
    calories = null,
    distanceKm = null,
    floors = null;
  let minVery = null,
    minFair = null,
    minLight = null,
    minSed = null;
  let azmTotal = null,
    azmFatBurn = null,
    azmCardio = null,
    azmPeak = null;

  // sleep
  let sleepHours = null,
    sleepScore = null;
  let episodesD = [],
    episodesPrev = [];

  // recovery
  let rhrBpm = null,
    hrvRmssd = null;

  // CRF
  let vo2max = null;

  // body composition
  let weightKg = null,
    bodyFatPct = null,
    bmi = null,
    leanMassKg = null;

  /* -------- activity -------- */
  try {
    const a = await callFitbit(accessToken, `activities/date/${dayKey}.json`);
    steps = a?.summary?.steps ?? null;
    calories = a?.summary?.caloriesOut ?? null;
    if (Array.isArray(a?.summary?.distances)) {
      const total = a.summary.distances.find((d) => d.activity === "total");
      if (total?.distance != null) distanceKm = Number(total.distance); // km
    }
    floors = a?.summary?.floors ?? null;
    minVery = a?.summary?.veryActiveMinutes ?? a?.summary?.minutesVeryActive ?? null;
    minFair = a?.summary?.fairlyActiveMinutes ?? a?.summary?.minutesFairlyActive ?? null;
    minLight = a?.summary?.lightlyActiveMinutes ?? a?.summary?.minutesLightlyActive ?? null;
    minSed = a?.summary?.sedentaryMinutes ?? a?.summary?.minutesSedentary ?? null;

    const azm = a?.summary?.activeZoneMinutes;
    if (azm) {
      const total = azm?.totalMinutes ?? azm?.minutes ?? null;
      const zones = Array.isArray(azm?.minutesInHeartRateZones)
        ? azm.minutesInHeartRateZones
        : azm?.zones || [];
      azmTotal = total != null ? Number(total) : null;
      for (const z of zones) {
        const n = z?.minutes != null ? Number(z.minutes) : null;
        const nm = String(z?.name || z?.zone || "").toLowerCase();
        if (n == null) continue;
        if (nm.includes("fat burn")) azmFatBurn = (azmFatBurn || 0) + n;
        else if (nm.includes("cardio")) azmCardio = (azmCardio || 0) + n;
        else if (nm.includes("peak")) azmPeak = (azmPeak || 0) + n;
      }
    }
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("activities fetch issue", { uid, dayKey, msg: e?.message });
  }

  /* -------- sleep & episodes (D and D-1) -------- */
  const prevKey = dayMinus(dayKey, 1);
  try {
    const sD = await callFitbit(accessToken, `sleep/date/${dayKey}.json`);
    const sPrev = await callFitbit(accessToken, `sleep/date/${prevKey}.json`);
    const min = sD?.summary?.totalMinutesAsleep ?? null;
    if (min != null) sleepHours = round(min / 60, 2);
    const firstSleep = Array.isArray(sD?.sleep) ? sD.sleep[0] : null;
    const score = firstSleep?.score ?? sD?.summary?.score ?? null;
    if (score != null) sleepScore = Number(score);
    episodesD = extractFitbitEpisodes(sD, tz);
    episodesPrev = extractFitbitEpisodes(sPrev, tz);
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("sleep fetch issue", { uid, dayKey, msg: e?.message });
  }

  /* -------- recovery -------- */
  try {
    const h = await callFitbit(accessToken, `activities/heart/date/${dayKey}/1d.json`);
    const arr = h?.["activities-heart"];
    const v = Array.isArray(arr) ? arr?.[0]?.value?.restingHeartRate : null;
    if (v != null) rhrBpm = Number(v);
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("heart fetch issue", { uid, dayKey, msg: e?.message });
  }
  try {
    const hv = await callFitbit(accessToken, `hrv/date/${dayKey}.json`);
    const arr = hv?.hrv;
    let rmssd = Array.isArray(arr) ? arr[0]?.value?.dailyRmssd : null;
    if (rmssd == null) rmssd = Array.isArray(arr) ? arr[0]?.value?.lastNightRmssd : null;
    if (rmssd != null) hrvRmssd = Number(rmssd);
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("hrv fetch issue", { uid, dayKey, msg: e?.message });
  }

  /* -------- CRF -------- */
  try {
    if (includeCrf === true) {
      const cf = await callFitbit(accessToken, `cardioFitnessScore/date/${dayKey}.json`);
      const arr = cf?.cardioScore || cf?.["cardioFitnessScore"] || [];
      const latest = Array.isArray(arr) ? arr[0] : null;
      const v = latest?.value?.vo2Max ?? latest?.value?.vo2max ?? null;
      if (v != null) vo2max = Number(v);
    }
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("vo2max fetch issue", { uid, dayKey, msg: e?.message });
  }

  /* -------- body composition -------- */
  try {
    const weight = await callFitbit(accessToken, `body/log/weight/date/${dayKey}.json`);
    const w = Array.isArray(weight?.weight) ? weight.weight.find(Boolean) : null;
    if (w) {
      if (w.weight != null) weightKg = Number(w.weight); // kg
      if (w.bmi != null) bmi = Number(w.bmi);
    }
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("weight fetch issue", { uid, dayKey, msg: e?.message });
  }
  try {
    const fat = await callFitbit(accessToken, `body/log/fat/date/${dayKey}.json`);
    const f = Array.isArray(fat?.fat) ? fat.fat.find(Boolean) : null;
    if (f && f.fat != null) bodyFatPct = Number(f.fat);
  } catch (e) {
    if (e?.status === 401 || /invalid_token|Unauthorized/i.test(String(e?.message))) {
      await markDisconnected(uid, "revoked");
      throw e;
    }
    logger.warn("body fat fetch issue", { uid, dayKey, msg: e?.message });
  }
  if (Number.isFinite(weightKg) && Number.isFinite(bodyFatPct)) {
    const fatKg = weightKg * (bodyFatPct / 100);
    leanMassKg = round(Math.max(0, weightKg - fatKg), 2);
  }

  // Build patches (no zeros for "today")
  const docRefD = db.doc(`users/${uid}/sync_days/fitbit_${dayKey}`);
  const docRefPrev = db.doc(`users/${uid}/sync_days/fitbit_${prevKey}`);
  const sampleIso = new Date().toISOString();
  const todayLocal = isTodayKey(dayKey, DEFAULT_TZ);

  const lastStampD = {};
  const lastStampPrev = {};
  const patchD = {
    provider: "fitbit",
    date_local: dayKey,
    sample_at_utc: sampleIso,
    synced_at_utc: FieldValue.serverTimestamp(),
  };
  const patchPrev = {
    provider: "fitbit",
    date_local: prevKey,
    sample_at_utc: sampleIso,
    synced_at_utc: FieldValue.serverTimestamp(),
  };

  function setMetric(targetPatch, lastStamp, key, val) {
    if (val == null) return;
    if (todayLocal) {
      // avoid poisoning today with zeros while device is still syncing
      if (["steps_count", "sleep_total_hours", "calories_out"].includes(key) && Number(val) === 0)
        return;
    }
    targetPatch[key] = val;
    lastStamp[`last_${key}_utc`] = sampleIso;
  }

  // Activity (D)
  setMetric(patchD, lastStampD, "steps_count", steps);
  setMetric(patchD, lastStampD, "calories_out", calories);
  setMetric(patchD, lastStampD, "distance_km", distanceKm);
  setMetric(patchD, lastStampD, "floors", floors);
  setMetric(patchD, lastStampD, "minutes_very_active", minVery);
  setMetric(patchD, lastStampD, "minutes_fairly_active", minFair);
  setMetric(patchD, lastStampD, "minutes_lightly_active", minLight);
  setMetric(patchD, lastStampD, "minutes_sedentary", minSed);
  setMetric(patchD, lastStampD, "zone_minutes_total", azmTotal);
  setMetric(patchD, lastStampD, "zone_minutes_fat_burn", azmFatBurn);
  setMetric(patchD, lastStampD, "zone_minutes_cardio", azmCardio);
  setMetric(patchD, lastStampD, "zone_minutes_peak", azmPeak);

  // Sleep totals/score (D) + Episodes (D and D-1)
  setMetric(patchD, lastStampD, "sleep_total_hours", sleepHours);
  setMetric(patchD, lastStampD, "sleep_score", sleepScore);
  let wroteEpisodes = false;
  const episodesCombined = [...episodesPrev, ...episodesD];
  if (episodesCombined.length) {
    patchD.sleep_episodes = episodesCombined;
    patchPrev.sleep_episodes = episodesCombined;
    lastStampD["last_sleep_episodes_utc"] = sampleIso;
    lastStampPrev["last_sleep_episodes_utc"] = sampleIso;
    wroteEpisodes = true;
  }

  // Recovery (D)
  setMetric(patchD, lastStampD, "rhr_bpm", rhrBpm);
  setMetric(patchD, lastStampD, "hrv_rmssd_ms", hrvRmssd);

  // CRF (D)
  setMetric(patchD, lastStampD, "vo2max_ml_kg_min", vo2max);

  // Body comp (D)
  setMetric(patchD, lastStampD, "weight_kg", weightKg);
  setMetric(patchD, lastStampD, "body_fat_pct", bodyFatPct);
  setMetric(patchD, lastStampD, "bmi", bmi);
  setMetric(patchD, lastStampD, "lean_mass_kg", leanMassKg);

  // Today-empty short-circuit (no write)
  if (todayLocal && Object.keys(lastStampD).length === 0 && !wroteEpisodes) {
    logger.info("fitbit today-empty short-circuit (no sync_days write)", { uid, dayKey });
    return { wrote: false, wroteDays: [] };
  }

  Object.assign(patchD, lastStampD);
  await docRefD.set(patchD, { merge: true });

  if (wroteEpisodes) {
    Object.assign(patchPrev, lastStampPrev);
    await docRefPrev.set(patchPrev, { merge: true });
  }

  const wrote = Object.keys(lastStampD).length > 0 || wroteEpisodes;
  const wroteDays = [dayKey, ...(wroteEpisodes ? [prevKey] : [])];
  return { wrote, wroteDays };
}

/* ───────────────────── Missing & Incomplete helpers ───────────────────── */

function isPresentNumber(n) {
  return Number.isFinite(Number(n));
}
function hasCoreForScore(row) {
  if (!row) return false;
  const s = row.sleep_total_hours;
  const st = row.steps_count;
  const rhr = row.rhr_bpm;
  const hrv = row.hrv_rmssd_ms;
  return isPresentNumber(s) && isPresentNumber(st) && (isPresentNumber(rhr) || isPresentNumber(hrv));
}
async function computeMissingOrIncompleteKeys(uid, tz, lookbackDays) {
  const n = Math.max(1, Math.min(lookbackDays || BACKFILL_LOOKBACK_DEFAULT, 90));
  const keys = dayKeysBackInTZ(n, tz);
  const refs = keys.map((k) => db.doc(`users/${uid}/sync_days/fitbit_${k}`));
  const results = [];
  for (let i = 0; i < refs.length; i += CHUNK_READ) {
    const slice = refs.slice(i, i + CHUNK_READ);
    const snaps = await db.getAll(...slice);
    for (let j = 0; j < snaps.length; j++) {
      const snap = snaps[j];
      const k = keys[i + j];
      if (!snap.exists) {
        results.push({ key: k, reason: "missing" });
        continue;
      }
      const d = snap.data() || {};
      const coreOK = hasCoreForScore(d);
      if (!coreOK) results.push({ key: k, reason: "incomplete" });
    }
  }
  return results;
}

/* ───────────────────── Coverage orchestrator (exported) ─────────────────────
   Respect caller hints:
     - backfill=false → fetch PRIORITY_RECENT_N only (no sweep/repair)
     - backfill=true  → fetch PRIORITY_RECENT_N + repair window (lookbackDays, default 14)
*/

export async function ensureCoverageForUid(uid, {
  includeCrf = true,
  backfill = false,
  lookbackDays = BACKFILL_LOOKBACK_DEFAULT,
} = {}) {
  const integSnap = await db.doc(`integrations/fitbit/users/${uid}`).get();
  if (!integSnap.exists || !integSnap.data()?.connected) {
    await mirrorUserIntegrationStatus(uid, { connected: false, last_status: "disconnected" });
    return { ok: false, reason: "not_connected" };
  }

  let integ = integSnap.data() || {};
  integ = await refreshIfNeeded(uid, integ);

  const tz = await loadUserTZ(uid);

  // Acquire per-user vendor lock
  const lock = await acquireLock(uid, { ttlMs: 120000 });
  if (!lock.ok) {
    return { ok: true, no_op: true, reason: "lock_busy" };
  }

  try {
    const accessToken = integ?.access_token;
    if (!accessToken) throw new Error("missing_access_token");

    // 1) PRIORITY: last N=4 keys (strictly most-recent days)
    const priorityKeys = uniqueSorted(dayKeysBackInTZ(PRIORITY_RECENT_N, tz)).reverse(); // newest → oldest
    const priorityWritten = [];

    for (const key of priorityKeys) {
      try {
        const r = await pullFitbitForDayToSyncDoc(uid, accessToken, key, { includeCrf, tz });
        priorityWritten.push({ key, wrote: !!r?.wrote });
      } catch (e) {
        logger.warn("priority pull failed", { uid, key, msg: e?.message });
      }
    }

    // 1b) Compute each priority key immediately (so user gets a score fast)
    for (const key of priorityKeys) {
      try {
        const headers = { "Content-Type": "application/json" };
        if (SYNC_SECRET) headers["x-sync-secret"] = SYNC_SECRET;
        await fetchWithRetry(COMPUTE_URL, {
          method: "POST",
          headers,
          body: JSON.stringify({
            uid,
            tz,
            date_local: key,
            policy: "lag_yesterday",
            force: true,
            allowZerosToday: false,
          }),
        });
      } catch (e) {
        logger.warn("priority compute failed", { uid, key, msg: e?.message });
      }
      await sleepMs(COMPUTE_DELAY_MS);
    }

    let repaired = [];
    if (backfill) {
      // 2) Window repair (≤lookbackDays): find missing/incomplete and pull
      const repairs = await computeMissingOrIncompleteKeys(uid, tz, lookbackDays);
      // De-duplicate against priority keys to avoid extra pressure
      const repairKeys = uniqueSorted(
        repairs.map((r) => r.key).filter((k) => !priorityKeys.includes(k))
      ).reverse(); // newest first

      for (const key of repairKeys) {
        try {
          const r = await pullFitbitForDayToSyncDoc(uid, accessToken, key, { includeCrf, tz });
          repaired.push({ key, wrote: !!r?.wrote });
        } catch (e) {
          logger.warn("repair pull failed", { uid, key, msg: e?.message });
        }
        await sleepMs(BACKFILL_DELAY_MS);
      }

      // Optional: kick a compact backfill compute for the tail after pulls (not forced)
      for (const key of repairKeys) {
        try {
          const headers = { "Content-Type": "application/json" };
          if (SYNC_SECRET) headers["x-sync-secret"] = SYNC_SECRET;
          await fetchWithRetry(COMPUTE_URL, {
            method: "POST",
            headers,
            body: JSON.stringify({
              uid,
              tz,
              date_local: key,
              policy: "lag_yesterday",
              force: false,
              allowZerosToday: false,
            }),
          });
        } catch (e) {
          logger.warn("repair compute skip/fail", { uid, key, msg: e?.message });
        }
        await sleepMs(BACKFILL_DELAY_MS);
      }

      // Mark the fact we completed a backfill window (client uses this to avoid re-running)
      await db.doc(`integrations/fitbit/users/${uid}`).set(
        { last_backfill_at_utc: FieldValue.serverTimestamp() },
        { merge: true }
      );
      await mirrorUserIntegrationStatus(uid, {
        last_backfill_at_utc: FieldValue.serverTimestamp(),
      });
    }

    await mirrorUserIntegrationStatus(uid, {
      connected: true,
      last_status: "ok",
      last_sync_utc: FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      tz,
      priority_keys: priorityKeys,
      priority_written: priorityWritten,
      repaired_total: repaired.length,
      lookback_used: backfill ? Math.max(1, Math.min(lookbackDays || BACKFILL_LOOKBACK_DEFAULT, 90)) : 0,
      backfill: !!backfill,
    };
  } finally {
    await releaseLock(uid, lock.token);
  }
}

/* ───────────────────── Public endpoints (accept days/backfill) ───────────────────── */

// HTTP: kick coverage for a user (App Check OR sync secret)
export const fitbitEnsureCoverageHttp = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    try {
      const fromApp = await verifyAppCheckOrScheduler(req);
      const fromSecret = SYNC_SECRET && req.get("x-sync-secret") === SYNC_SECRET;
      if (!(fromApp || fromSecret)) return res.status(401).json({ ok: false, error: "unauthorized" });
      if (req.method !== "POST") return res.status(405).json({ ok: false, error: "Use POST" });

      const body = typeof req.body === "object" && req.body ? req.body : {};
      const { uid, includeCrf = true, days, backfill = false } = body;
      if (!uid) return res.status(400).json({ ok: false, error: "missing uid" });

      const lookbackDays = Number.isFinite(Number(days)) ? Number(days) : BACKFILL_LOOKBACK_DEFAULT;

      const out = await ensureCoverageForUid(uid, {
        includeCrf: !!includeCrf,
        backfill: !!backfill,
        lookbackDays,
      });
      return res.status(out.ok ? 200 : 500).json(out);
    } catch (e) {
      logger.error("fitbitEnsureCoverageHttp error", { message: e?.message });
      return res.status(500).json({ ok: false, error: String(e?.message || e) });
    }
  }
);

// Callable: pull now — respects days/backfill from client
export const fitbitFetchNowCall = onCall(
  { region: REGION, timeoutSeconds: 180 },
  async (req) => {
    try {
      const uid = String(req?.data?.uid || req?.auth?.uid || "").trim();
      if (!uid) throw new Error("missing uid");

      const includeCrf = req?.data?.includeCrf !== false;
      const days = Number.isFinite(Number(req?.data?.days))
        ? Number(req?.data?.days)
        : BACKFILL_LOOKBACK_DEFAULT;
      const backfill = req?.data?.backfill === true;

      const out = await ensureCoverageForUid(uid, {
        includeCrf,
        backfill,
        lookbackDays: days,
      });
      return out;
    } catch (e) {
      logger.error("fitbitFetchNowCall error", { message: e?.message });
      throw new Error(e?.message || "fitbitFetchNowCall failed");
    }
  }
);

// Scheduler: daily sweep (gentle) — uses default 14-day repair window
export const fitbitDailySweep = onSchedule(
  { region: REGION, schedule: "every day 06:00", timeZone: DEFAULT_TZ },
  async () => {
    const col = db.collection(`integrations/fitbit/users`);
    const snap = await col.limit(200).get(); // safety cap
    let ok = 0,
      fail = 0;
    for (const doc of snap.docs) {
      const uid = doc.id;
      if (!doc.data()?.connected) continue;
      try {
        await ensureCoverageForUid(uid, {
          includeCrf: true,
          backfill: true,
          lookbackDays: BACKFILL_LOOKBACK_DEFAULT,
        });
        ok++;
      } catch (e) {
        fail++;
        logger.warn("fitbitDailySweep user fail", { uid, msg: e?.message });
      }
      await sleepMs(200); // tiny spread
    }
    logger.info("fitbitDailySweep done", { ok, fail });
    return { ok: true, ok_count: ok, fail_count: fail };
  }
);

/* ───────────────────── Back-compat alias (prevents import errors) ─────────────────────
   Some code may still import { ensureThirtyDayCoverageForUid } from this module.
   Keep it exported, but route to the bounded policy (default 14 unless caller passes days).
*/
export async function ensureThirtyDayCoverageForUid(uid, options = {}) {
  const { includeCrf = true, backfill = true } = options || {};
  const lbRaw = options.lookbackDays ?? options.days;
  const lookbackDays = Number.isFinite(Number(lbRaw))
    ? Number(lbRaw)
    : BACKFILL_LOOKBACK_DEFAULT; // ← 14 by default now
  return ensureCoverageForUid(uid, { includeCrf, backfill, lookbackDays });
}

/* ───────────────────── CJS/ESM default export ───────────────────── */
export default {
  ensureCoverageForUid,
  ensureThirtyDayCoverageForUid, // back-compat
  fitbitEnsureCoverageHttp,
  fitbitFetchNowCall,
  fitbitDailySweep,
};
