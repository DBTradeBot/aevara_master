// functions/ddc/compute_range.js
// Range compute (callable + HTTP) for multiple days
// - runRangeForUser: core runner
// - computeRangeCall: callable that uses auth.uid
// - computeRangeHttp: admin/server-to-server via POST
//
// Input variants:
//   • start_key + end_key (inclusive), both YYYY-MM-DD
//   • days = N (compute today back N-1 days)
//   • explicit date_keys: string[]
//
// Behavior:
// - Skips already-final days unless force=true
// - Serializes per-day to avoid concurrent day leases; still fast for short ranges
// Node 20 / ESM

import { onCall, onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from "../core/firebase_admin.js";

import { dateKeyInTZ, isDateKey, parseDateKey } from "../core/ddc_utils.js";
import { runForUserDay } from "./run_for_user_day.js";

const REGION = "us-central1";
const HARD_MAX_DAYS = 60;

/* ------------------------------ helpers ----------------------------------- */

// Build an inclusive list of date keys from start → end (UTC-based increment)
function spanKeys(startKey, endKey) {
  if (!isDateKey(startKey) || !isDateKey(endKey)) return [];
  const a = parseDateKey(startKey);
  const b = parseDateKey(endKey);
  if (!a || !b) return [];
  const keys = [];
  for (let d = new Date(a); d.getTime() <= b.getTime(); d.setUTCDate(d.getUTCDate() + 1)) {
    keys.push(`${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`);
  }
  return keys;
}

function uniqueSortedDateKeys(arr) {
  if (!Array.isArray(arr)) return [];
  const set = new Set(arr.filter(isDateKey));
  return Array.from(set).sort();
}

// Optional shared secret check (for HTTP)
function checkSyncSecret(req) {
  const want = process.env.FITBIT_SYNC_SECRET;
  if (!want) return true;
  const got = req.headers["x-sync-secret"];
  return got && String(got) === String(want);
}

function parseCommonParams(src) {
  const tz = String(src?.tz || "America/Los_Angeles");
  const policy = (src?.policy || "lag_yesterday").toString();
  const force = !!src?.force;
  return { tz, policy, force };
}

/* ------------------------------ core runner -------------------------------- */

/**
 * runRangeForUser(uid, { tz, policy, force, start_key, end_key, days, date_keys })
 * Returns { ok, total, computed, skipped_final, errors, results: [{ date_key, ok, wrote?, no_op?, reason?, error? }] }
 */
export async function runRangeForUser(
  uid,
  {
    tz = "America/Los_Angeles",
    policy = "lag_yesterday",
    force = false,
    start_key = null,
    end_key = null,
    days = null,
    date_keys = null,
  } = {}
) {
  if (!uid) throw new Error("runRangeForUser: missing uid");

  let keys = [];

  if (Array.isArray(date_keys) && date_keys.length) {
    keys = uniqueSortedDateKeys(date_keys).slice(0, HARD_MAX_DAYS);
  } else if (isDateKey(start_key) && isDateKey(end_key)) {
    keys = spanKeys(start_key, end_key).slice(0, HARD_MAX_DAYS);
  } else if (Number.isFinite(Number(days)) && Number(days) > 0) {
    const n = Math.min(HARD_MAX_DAYS, Math.max(1, Number(days))); // guard big ranges
    const today = dateKeyInTZ(new Date(), tz);
    const end = parseDateKey(today);
    const start = new Date(end);
    start.setUTCDate(end.getUTCDate() - (n - 1));
    keys = spanKeys(
      `${start.getUTCFullYear()}-${String(start.getUTCMonth() + 1).padStart(2, "0")}-${String(start.getUTCDate()).padStart(2, "0")}`,
      today
    );
  } else {
    // default: today only
    keys = [dateKeyInTZ(new Date(), tz)];
  }

  const results = [];
  let skipped_final = 0;

  for (const k of keys) {
    if (!force) {
      const ref = db.doc(`users/${uid}/days/${k}`);
      const snap = await ref.get();
      const d = snap.exists ? (snap.data() || {}) : {};
      if (d?.display?.status === "final") {
        skipped_final++;
        results.push({ date_key: k, ok: true, no_op: true, reason: "already_final" });
        continue;
      }
    }

    try {
      const r = await runForUserDay(uid, k, { tz, policy, force });
      const ok = !!r?.ok;
      results.push({ date_key: k, ok, ...r });
    } catch (e) {
      results.push({ date_key: k, ok: false, error: String(e?.message || e) });
    }
  }

  const computed = results.filter((r) => r.ok && r.wrote).length;
  const errors = results.filter((r) => !r.ok).length;
  return { ok: errors === 0, total: keys.length, computed, skipped_final, errors, results };
}

/* --------------------------------- Callable -------------------------------- */

export const computeRangeCall = onCall({ region: REGION }, async (req) => {
  try {
    const uid = req.auth?.uid || String(req.data?.uid || "");
    if (!uid) return { ok: false, error: "unauthenticated" };

    const { tz, policy, force } = parseCommonParams(req.data);
    const start_key = req.data?.start_key;
    const end_key = req.data?.end_key;
    const days = req.data?.days;
    const date_keys = Array.isArray(req.data?.date_keys) ? req.data.date_keys : null;

    const out = await runRangeForUser(uid, { tz, policy, force, start_key, end_key, days, date_keys });
    return out;
  } catch (e) {
    logger.error("computeRangeCall error", { message: e?.message });
    return { ok: false, error: String(e?.message || e) };
  }
});

/* ----------------------------------- HTTP ---------------------------------- */

/**
 * POST /computeRangeHttp
 * Headers (optional): x-sync-secret: <FITBIT_SYNC_SECRET>
 * Body:
 *  {
 *    uid: string,
 *    tz?: string,
 *    policy?: "lag_yesterday"|"cutoff"|"sleep_bounded",
 *    force?: boolean,
 *    start_key?: "YYYY-MM-DD",
 *    end_key?: "YYYY-MM-DD",
 *    days?: number,
 *    date_keys?: string[]
 *  }
 */
export const computeRangeHttp = onRequest({ region: REGION, cors: true }, async (req, res) => {
  try {
    if (req.method === "OPTIONS") return res.status(204).send(""); // CORS preflight
    if (req.method !== "POST") return res.status(405).json({ ok: false, error: "Use POST" });
    if (!checkSyncSecret(req)) return res.status(401).json({ ok: false, error: "Unauthorized" });

    const uid = String(req.body?.uid || "");
    if (!uid) return res.status(400).json({ ok: false, error: "Missing uid" });

    const { tz, policy, force } = parseCommonParams(req.body);
    const start_key = req.body?.start_key;
    const end_key = req.body?.end_key;
    const days = req.body?.days;
    const date_keys = Array.isArray(req.body?.date_keys) ? req.body.date_keys : null;

    const out = await runRangeForUser(uid, { tz, policy, force, start_key, end_key, days, date_keys });
    return res.status(200).json(out);
  } catch (e) {
    logger.error("computeRangeHttp error", { message: e?.message });
    return res.status(500).json({ ok: false, error: String(e?.message || e) });
  }
});
