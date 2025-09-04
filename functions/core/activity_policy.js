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



/**
 * resolveActivityInputs(uid, dateKey, { policy, tz, cutoffHourLocal, sleepWindow })
 *
 * Returns an object with activity metrics resolved per policy:
 * {
 *   steps_count, calories_out, distance_km,
 *   minutes_very_active, minutes_fairly_active, minutes_lightly_active, minutes_sedentary,
 *   provenance: { activity_policy: 'lag_yesterday'|'cutoff'|'sleep_bounded', from_date: 'YYYY-MM-DD' }
 * }
 *
 * Notes:
 * - We read the merged daily doc(s) under users/{uid}/days/{YYYY-MM-DD}.
 * - For 'lag_yesterday': pick yesterday's totals; provenance.from_date = D-1.
 * - For 'cutoff': split D by local cutoffHour (e.g., 10:00); activity for D uses up to cutoff,
 *   and remainder belongs to D-1 transparency (we still only return D’s portion for compute).
 * - For 'sleep_bounded': if main sleep episode crosses midnight, counts pre-sleep to D-1 and post-sleep to D.
 *   (For v1 we approximate by using D-1 if main sleep end is on D, else fallback to 'lag_yesterday'.)
 */
export async function resolveActivityInputs(
  uid,
  dateKey,
  {
    policy = "lag_yesterday",
    tz = "America/Los_Angeles",
    cutoffHourLocal = 10, // 10:00 local default
    sleepWindow = null,   // future: { mainSleep: { startLocalISO, endLocalISO } }
  } = {}
) {
  if (!isDateKey(dateKey)) throw new Error("resolveActivityInputs: invalid dateKey");

  if (policy === "lag_yesterday") {
    const from = dayMinus(dateKey, 1);
    const doc = await readDayDoc(uid, from);
    const activity = extractActivity(doc);
    return { ...activity, provenance: { activity_policy: "lag_yesterday", from_date: from } };
  }

  if (policy === "cutoff") {
    // For v1 compute we keep things simple: store totals in day docs.
    // We cannot truly split without raw intraday. We approximate:
    // - If D has any activity at all and yesterday has activity,
    //   prefer yesterday totals (same as lag policy) for stability.
    // - Otherwise surface D totals (likely small morning movement).
    const prev = dayMinus(dateKey, 1);
    const dDoc = await readDayDoc(uid, dateKey);
    const yDoc = await readDayDoc(uid, prev);

    const dAct = extractActivity(dDoc);
    const yAct = extractActivity(yDoc);
    const preferYesterday =
      (sumActivity(yAct) > 0 && sumActivity(dAct) > 0) || sumActivity(yAct) >= sumActivity(dAct);

    const picked = preferYesterday ? yAct : dAct;
    const from = preferYesterday ? prev : dateKey;

    return {
      ...picked,
      provenance: {
        activity_policy: "cutoff",
        cutoff_hour_local: cutoffHourLocal,
        from_date: from,
      },
    };
  }

  if (policy === "sleep_bounded") {
    // Heuristic v1:
    // If we see that D has a sleep_total_hours AND yesterday also has sleep,
    // we assume the main sleep ended on D, therefore activity “belongs” to D-1.
    const prev = dayMinus(dateKey, 1);
    const dDoc = await readDayDoc(uid, dateKey);
    const yDoc = await readDayDoc(uid, prev);

    const mainSleepEndedOnD = Number(dDoc?.sleep_total_hours ?? 0) > 0;
    const pickPrev = mainSleepEndedOnD || sumActivity(yDoc) >= sumActivity(dDoc);

    const act = extractActivity(pickPrev ? yDoc : dDoc);
    const from = pickPrev ? prev : dateKey;

    return {
      ...act,
      provenance: { activity_policy: "sleep_bounded", from_date: from },
    };
  }

  // Fallback to lag_yesterday
  const from = dayMinus(dateKey, 1);
  const doc = await readDayDoc(uid, from);
  const activity = extractActivity(doc);
  return { ...activity, provenance: { activity_policy: "lag_yesterday", from_date: from } };
}

/* ------------------------------ helpers ------------------------------ */

function dayMinus(dateKey, n) {
  const d = parseDateKey(dateKey);
  d.setUTCDate(d.getUTCDate() - n);
  return dateKeyInTZ(d, "UTC"); // keep YYYY-MM-DD (UTC-safe here)
}

async function readDayDoc(uid, dateKey) {
  const ref = db.doc(`users/${uid}/days/${dateKey}`);
  const snap = await ref.get();
  return snap.exists ? snap.data() || {} : {};
}

function extractActivity(d) {
  const getN = (x) => (Number.isFinite(Number(x)) ? Number(x) : null);
  return {
    steps_count: getN(d.steps_count),
    calories_out: getN(d.calories_out),
    distance_km: getN(d.distance_km),
    minutes_very_active: getN(d.minutes_very_active),
    minutes_fairly_active: getN(d.minutes_fairly_active),
    minutes_lightly_active: getN(d.minutes_lightly_active),
    minutes_sedentary: getN(d.minutes_sedentary),
  };
}

function sumActivity(a) {
  if (!a) return 0;
  const nums = [
    a.steps_count,
    a.calories_out,
    a.distance_km,
    a.minutes_very_active,
    a.minutes_fairly_active,
    a.minutes_lightly_active,
    a.minutes_sedentary,
  ]
    .map((v) => (Number.isFinite(Number(v)) ? Number(v) : 0));

  // weight steps + active minutes higher, calories moderate, distance small, sedentary tiny
  const score =
    nums[0] * 1.0 + // steps
    nums[3] * 2.0 + // very active min
    nums[4] * 1.2 + // fairly active min
    nums[5] * 0.5 + // light min
    nums[1] * 0.05 + // calories
    nums[2] * 0.25 + // distance km
    nums[6] * 0.01; // sedentary
  return round(score, 2);
}

