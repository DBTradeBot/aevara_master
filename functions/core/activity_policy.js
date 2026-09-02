// functions/core/activity_policy.js
// Activity policy resolver for DDC
// Supports: 'lag_yesterday' (default), 'cutoff', 'sleep_bounded'
// Node 20 / ESM

import { db } from "./firebase_admin.js";
import {
  dateKeyInTZ,
  parseDateKey,
  isDateKey,
  round,
} from "./ddc_utils.js";
import { mergeDailyFromVendors } from "../vendor/merge_daily.js";

/**
 * resolveActivityInputs(uid, dateKey, { policy, tz, cutoffHourLocal, sleepWindow })
 *
 * Returns:
 * {
 *   steps_count, calories_out, distance_km,
 *   minutes_very_active, minutes_fairly_active, minutes_lightly_active, minutes_sedentary,
 *   mvpa_minutes,
 *   provenance: { activity_policy: 'lag_yesterday'|'cutoff'|'sleep_bounded', from_date: 'YYYY-MM-DD' }
 * }
 *
 * Design notes:
 * - We strongly prefer 'lag_yesterday' (D-1) using merged vendor data for morning stability.
 * - 'sleep_bounded' works best when sleep "end on D" binding is trustworthy (merge_daily enforces).
 * - 'cutoff' remains for experimentation; it uses day-doc heuristics and should be considered secondary.
 */
export async function resolveActivityInputs(
  uid,
  dateKey,
  {
    policy = "lag_yesterday",
    tz = "America/Los_Angeles",
    cutoffHourLocal = 10,
    sleepWindow = null,
  } = {}
) {
  if (!isDateKey(dateKey)) throw new Error("resolveActivityInputs: invalid dateKey");

  if (policy === "lag_yesterday") {
    const from = dayMinus(dateKey, 1);
    const merged = await mergeDailyFromVendors(uid, from, { allowZerosToday: true, tz });
    const activity = extractActivityFromMerged(merged);
    return { ...activity, provenance: { activity_policy: "lag_yesterday", from_date: from } };
  }

  if (policy === "cutoff") {
    const prev = dayMinus(dateKey, 1);
    const dDoc = await readDayDoc(uid, dateKey);
    const yDoc = await readDayDoc(uid, prev);

    const dAct = extractActivity(dDoc);
    const yAct = extractActivity(yDoc);

    const dScore = sumActivity(dAct);
    const yScore = sumActivity(yAct);

    const bothHave  = dScore > 0 && yScore > 0;
    const within30p = bothHave ? Math.abs(dScore - yScore) / Math.max(dScore, yScore) <= 0.30 : false;
    const dSmall    = (Number(dAct.steps_count) || 0) < 1500 && yScore > 0;

    const preferYesterday = (bothHave && within30p) || dSmall || yScore >= dScore;

    const picked = preferYesterday ? yAct : dAct;
    const from   = preferYesterday ? prev : dateKey;

    return {
      ...picked,
      provenance: { activity_policy: "cutoff", cutoff_hour_local: cutoffHourLocal, from_date: from },
    };
  }

  if (policy === "sleep_bounded") {
    const prev = dayMinus(dateKey, 1);
    const dDoc = await readDayDoc(uid, dateKey);
    const yDoc = await readDayDoc(uid, prev);

    const mainSleepEndedOnD = Number(dDoc?.sleep_total_hours ?? 0) > 0;
    const pickPrev = mainSleepEndedOnD || sumActivity(yDoc) >= sumActivity(dDoc);

    const act = extractActivity(pickPrev ? yDoc : dDoc);
    const from = pickPrev ? prev : dateKey;

    return { ...act, provenance: { activity_policy: "sleep_bounded", from_date: from } };
  }

  // Fallback: lag_yesterday
  const from = dayMinus(dateKey, 1);
  const merged = await mergeDailyFromVendors(uid, from, { allowZerosToday: true, tz });
  const activity = extractActivityFromMerged(merged);
  return { ...activity, provenance: { activity_policy: "lag_yesterday", from_date: from } };
}

/* ------------------------------ helpers ------------------------------ */

function dayMinus(dateKey, n) {
  const d = parseDateKey(dateKey);
  d.setUTCDate(d.getUTCDate() - n);
  return dateKeyInTZ(d, "UTC");
}

async function readDayDoc(uid, dateKey) {
  const ref = db.doc(`users/${uid}/days/${dateKey}`);
  const snap = await ref.get();
  return snap.exists ? (snap.data() || {}) : {};
}

function extractActivity(d) {
  const N = (x) => (Number.isFinite(Number(x)) ? Number(x) : null);
  const minutes_very_active   = N(d.minutes_very_active);
  const minutes_fairly_active = N(d.minutes_fairly_active);
  const mvpa_minutes = (Number(minutes_very_active) || 0) + (Number(minutes_fairly_active) || 0);
  return {
    steps_count: N(d.steps_count),
    calories_out: N(d.calories_out),
    distance_km: N(d.distance_km),
    minutes_very_active,
    minutes_fairly_active,
    minutes_lightly_active: N(d.minutes_lightly_active),
    minutes_sedentary: N(d.minutes_sedentary),
    mvpa_minutes: mvpa_minutes || null,
  };
}

function extractActivityFromMerged(merged) {
  const N = (x) => (Number.isFinite(Number(x)) ? Number(x) : null);
  const minutes_very_active   = N(merged?.minutes_very_active);
  const minutes_fairly_active = N(merged?.minutes_fairly_active);
  const zone_minutes_total    = N(merged?.zone_minutes_total); // Fitbit Zone Minutes (if mapped)
  const mvpa_from_minutes     = (Number(minutes_very_active) || 0) + (Number(minutes_fairly_active) || 0);
  const mvpa = Number.isFinite(zone_minutes_total) ? zone_minutes_total : mvpa_from_minutes;
  return {
    steps_count: N(merged?.steps_count),
    calories_out: N(merged?.calories_out),
    distance_km: N(merged?.distance_km),
    minutes_very_active,
    minutes_fairly_active,
    minutes_lightly_active: N(merged?.minutes_lightly_active),
    minutes_sedentary: N(merged?.minutes_sedentary),
    mvpa_minutes: mvpa || null,
  };
}

function sumActivity(a) {
  if (!a) return 0;
  const nums = [
    a.steps_count, a.calories_out, a.distance_km,
    a.minutes_very_active, a.minutes_fairly_active, a.minutes_lightly_active,
    a.minutes_sedentary, a.mvpa_minutes,
  ].map((v) => (Number.isFinite(Number(v)) ? Number(v) : 0));

  const score =
    nums[0] * 1.0 +  // steps
    nums[7] * 2.2 +  // MVPA
    nums[3] * 1.6 +  // very active
    nums[4] * 1.0 +  // fairly active
    nums[5] * 0.5 +  // light
    nums[1] * 0.05 + // calories
    nums[2] * 0.25 + // distance
    nums[6] * 0.01;  // sedentary (almost neutral)
  return round(score, 2);
}


