// functions/ddc/compute_http.js
// HTTP endpoint for single-day compute (ESM / Firebase v2)
// - Accepts POST { userId, date_local?, tz?, force? }
// - Defaults date_local to "today" in tz
// - Skips already-final days unless force=true
// - Calls runForUserDay and returns its structured result
//
// Note: call_computeDaily.js continues to proxy to this.

import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from '../core/firebase_admin.js';

import { dateKeyInTZ, isDateKey } from "../core/ddc_utils.js";
import { runForUserDay } from "./run_for_user_day.js";


const REGION = "us-central1";

// Optional shared secret check (compatible with your proxy)
function checkSyncSecret(req) {
  const want = process.env.FITBIT_SYNC_SECRET;
  if (!want) return true;
  const got = req.headers["x-sync-secret"];
  return got && String(got) === String(want);
}

/**
 * POST /computeDailyHttp
 * Body:
 *   {
 *     userId: string,
 *     date_local?: "YYYY-MM-DD",  // defaults to today in tz
 *     tz?: string,                 // default "America/Los_Angeles"
 *     force?: boolean,             // recompute even if signature unchanged or final
 *     policy?: "lag_yesterday"|"cutoff"|"sleep_bounded" // default lag_yesterday
 *   }
 */
export const computeDailyHttp = onRequest({ region: REGION, cors: true }, async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).json({ ok: false, error: "Use POST" });
    if (!checkSyncSecret(req)) return res.status(401).json({ ok: false, error: "Unauthorized" });

    const userId = String(req.body?.userId || req.body?.uid || "");
    if (!userId) return res.status(400).json({ ok: false, error: "Missing userId" });

    const tz = String(req.body?.tz || "America/Los_Angeles");
    const policy = (req.body?.policy || "lag_yesterday").toString();
    const force = !!req.body?.force;

    let date_local = req.body?.date_local;
    if (!isDateKey(date_local)) {
      date_local = dateKeyInTZ(new Date(), tz);
    }

    // Skip finalized days unless force
    if (!force) {
      const dayRef = db.doc(`users/${userId}/days/${date_local}`);
      const snap = await dayRef.get();
      const d = snap.exists ? (snap.data() || {}) : {};
      if (d?.display?.status === "final") {
        return res.status(200).json({
          ok: true,
          no_op: true,
          reason: "already_final",
          docPath: dayRef.path,
        });
      }
    }

    const out = await runForUserDay(userId, date_local, { tz, policy, force });
    return res.status(200).json({ ok: true, ...out });
  } catch (e) {
    logger.error("computeDailyHttp error", { message: e?.message });
    return res.status(500).json({ ok: false, error: String(e?.message || e) });
  }
});

