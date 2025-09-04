import { db, FieldValue, Timestamp } from "../core/firebase_admin.js";
// functions/community/leaderboards.js
// Weekly steps leaderboard builder (legacy name: buildLeaderboards).
// Node 20 / Gen 2 / ESM

import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
/**
 * Collection layout used:
 * - users/{uid}
 * - user_daily/{uid}/days/{YYYY-MM-DD} with steps_count (number)
 *
 * Leaderboard output:
 * - leaderboards/weekly_steps  { period_id, last_built_utc }
 * - leaderboards/weekly_steps/entries/{uid} { uid, score, period_id, updated_at }
 *
 * Period id is ISO week-like: YYYY-Www (UTC)
 */

function startOfIsoWeekUTC(d) {
  const dt = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const day = dt.getUTCDay() || 7; // 1..7
  if (day > 1) dt.setUTCDate(dt.getUTCDate() - (day - 1));
  dt.setUTCHours(0, 0, 0, 0);
  return dt;
}

function periodIdForUTC(d) {
  const start = startOfIsoWeekUTC(d);
  // ISO week number hack
  const yearStart = new Date(Date.UTC(start.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((start - yearStart) / 86400000) + yearStart.getUTCDay() + 1) / 7);
  const ww = String(week).padStart(2, "0");
  return `${start.getUTCFullYear()}-W${ww}`;
}

export const buildLeaderboards = onCall(async (req) => {
  // optional: allow admin-only; here we just require auth
  const uid = req.auth?.uid;
  if (!uid) throw new Error("UNAUTHENTICATED");

  const now = new Date();
  const periodId = periodIdForUTC(now);

  // Compute [today .. today-6] keys in UTC
  const keys = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(now);
    d.setUTCDate(d.getUTCDate() - i);
    const yyyy = d.getUTCFullYear();
    const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(d.getUTCDate()).padStart(2, "0");
    keys.push(`${yyyy}-${mm}-${dd}`);
  }

  // Sum steps per user via collectionGroup query (days)
  // NOTE: Requires a composite index in large datasets; for MVP scale this is fine.
  const entries = {};
  for (const dayKey of keys) {
    const cg = await db.collectionGroup("days")
      .where("date_local", "==", dayKey)
      .select("steps_count", "uid")
      .get();

    cg.forEach((doc) => {
      const data = doc.data();
      const u = data.uid || doc.ref.parent.parent?.parent?.id; // fallback: owner id from path user_daily/{uid}/days/{key}
      if (!u) return;
      const steps = Number(data.steps_count || 0);
      entries[u] = (entries[u] || 0) + (Number.isFinite(steps) ? steps : 0);
    });
  }

  // Write leaderboard doc + per-user entries
  const lbRef = db.collection("leaderboards").doc("weekly_steps");
  const batch = db.batch();
  batch.set(lbRef, { period_id: periodId, last_built_utc: FieldValue.serverTimestamp() }, { merge: true });

  Object.entries(entries).forEach(([userId, score]) => {
    const ent = lbRef.collection("entries").doc(userId);
    batch.set(ent, {
      uid: userId,
      score: Math.round(score),
      period_id: periodId,
      updated_at: FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  await batch.commit();
  logger.info(`[leaderboards] weekly_steps built for ${Object.keys(entries).length} users, period ${periodId}`);
  return { ok: true, period_id: periodId, users: Object.keys(entries).length };
});
