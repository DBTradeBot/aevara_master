// functions/baseline/backfill_baseline_start.js
// Callable: backfillBaselineStartCall
// Sets users/{uid}.baseline_started_at_utc to the earliest FINAL day's midnight UTC,
// optionally requiring at least N final days (default 30) unless force=true.

import { onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from "../core/firebase_admin.js";

const REGION = "us-central1";

// â¬‡ï¸ App Check enforced here
export const backfillBaselineStartCall = onCall({ region: REGION, enforceAppCheck: true }, async (req) => {
  try {
    const uid = String(req.data?.uid || req.auth?.uid || "").trim();
    const minFinalDays = Number.isFinite(Number(req.data?.minFinalDays))
      ? Math.max(1, Number(req.data.minFinalDays))
      : 30;
    const force = !!req.data?.force;

    if (!uid) return { ok: false, error: "missing uid" };

    // Fetch user snapshot
    const userRef = db.doc(`users/${uid}`);
    const userSnap = await userRef.get();
    const user = userSnap.exists ? (userSnap.data() || {}) : {};

    // If already set and not forcing, no-op.
    if (!force && user.baseline_started_at_utc) {
      return { ok: true, no_op: true, reason: "already_set", baseline_started_at_utc: user.baseline_started_at_utc };
    }

    // We want the earliest FINAL day's id (YYYY-MM-DD) and also count how many finals exist
    const daysCol = db.collection(`users/${uid}/days`);

    // Count recent finals (desc) up to a cap
    let finalDaysCount = 0;
    {
      const snap = await daysCol.orderBy("__name__", "desc").limit(720).get();
      for (const doc of snap.docs) {
        const d = doc.data() || {};
        if (d?.display?.status === "final") finalDaysCount++;
      }
    }

    if (!force && finalDaysCount < minFinalDays) {
      return { ok: true, no_op: true, reason: "insufficient_days", final_days_count: finalDaysCount };
    }

    // Find earliest FINAL (asc)
    let earliestFinalKey = null;
    let pageStart = null;
    const PAGE = 300;

    while (true) {
      let q = daysCol.orderBy("__name__", "asc").limit(PAGE);
      if (pageStart) q = q.startAfter(pageStart);
      const snap = await q.get();
      if (snap.empty) break;

      for (const doc of snap.docs) {
        const d = doc.data() || {};
        if (d?.display?.status === "final") {
          earliestFinalKey = doc.id; // "YYYY-MM-DD"
          break;
        }
      }

      if (earliestFinalKey) break;
      pageStart = snap.docs[snap.docs.length - 1];
      if (snap.size < PAGE) break; // exhausted
    }

    if (!earliestFinalKey) {
      return { ok: true, no_op: true, reason: "no_final_days_found", final_days_count: finalDaysCount };
    }

    // Convert earliestFinalKey (YYYY-MM-DD) â†' midnight UTC ISO
    const iso = `${earliestFinalKey}T00:00:00.000Z`;

    // Only update if (not set) or (force)
    if (!force && user.baseline_started_at_utc) {
      return {
        ok: true,
        no_op: true,
        reason: "already_set",
        earliest_final_key: earliestFinalKey,
        baseline_started_at_utc: user.baseline_started_at_utc,
        final_days_count: finalDaysCount,
      };
    }

    await userRef.set({ baseline_started_at_utc: iso }, { merge: true });

    logger.info("[baseline] baseline_started_at_utc backfilled", { uid, iso, earliestFinalKey, finalDaysCount });

    return {
      ok: true,
      updated: true,
      earliest_final_key: earliestFinalKey,
      final_days_count: finalDaysCount,
      baseline_started_at_utc: iso,
    };
  } catch (e) {
    logger.error("backfillBaselineStartCall error", { message: e?.message });
    return { ok: false, error: String(e?.message || e) };
  }
});



