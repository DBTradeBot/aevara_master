// functions/baseline/sweep_all_users.js
// Baseline sweep for all users (scheduled) "" runs runRangeForUser per user
// Node 20 / ESM / Firebase Functions v2

import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { db } from "../core/firebase_admin.js";
import { runRangeForUser } from "../ddc/compute_range.js";

const REGION = "us-central1";

/**
 * Tunables: keep resource usage modest.
 * - DAYS_PER_USER: how many days we recompute (today..D-3 typical)
 * - CONCURRENCY: how many users to process in parallel
 * - LIMIT_USERS: cap per run (safety)
 */
const DAYS_PER_USER = 4;
const CONCURRENCY = 4;
const LIMIT_USERS = 2000;

/**
 * Query all user ids (page through collection as needed).
 * You can scope or filter if you'd like (e.g., connected Fitbit only).
 */
async function listAllUserIds(limit = LIMIT_USERS) {
  const ids = [];
  let lastDoc = null;
  const PAGE = 500;

  while (ids.length < limit) {
    let q = db.collection("users").orderBy("__name__").limit(PAGE);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      ids.push(doc.id);
      if (ids.length >= limit) break;
    }
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < PAGE) break;
  }
  return ids;
}

async function runForChunk(uids, { tz = "America/Los_Angeles", policy = "sleep_bounded", force = false } = {}) {
  const results = [];
  await Promise.all(
    uids.map(async (uid) => {
      try {
        const out = await runRangeForUser(uid, { tz, policy, force, days: DAYS_PER_USER });
        results.push({ uid, ok: true, total: out.total, computed: out.computed, skipped_final: out.skipped_final });
      } catch (e) {
        results.push({ uid, ok: false, error: String(e?.message || e) });
      }
    })
  );
  return results;
}

/**
 * â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
 * SCHEDULE: 6:10 UTC daily (adjust as desired; cron or "every 24 hours")
 * Examples:
 *   cron: "10 6 * * *"      â†' daily at 06:10 UTC
 *   schedule: "every 24 hours"
 * â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
 */
export const baselineSweepDaily = onSchedule(
  { region: REGION, schedule: "10 6 * * *" },
  async () => {
    logger.info("[baselineSweepDaily] started", { daysPerUser: DAYS_PER_USER, concurrency: CONCURRENCY });

    // 1) Pull a bounded set of user ids
    const uids = await listAllUserIds(LIMIT_USERS);
    if (!uids.length) {
      logger.info("[baselineSweepDaily] no users found");
      return;
    }

    // 2) Process in concurrent chunks
    let processed = 0;
    let errors = 0;
    for (let i = 0; i < uids.length; i += CONCURRENCY) {
      const slice = uids.slice(i, i + CONCURRENCY);
      const res = await runForChunk(slice, { tz: "America/Los_Angeles", policy: "sleep_bounded", force: false });
      for (const r of res) {
        processed++;
        if (!r.ok) errors++;
      }
      logger.info("[baselineSweepDaily] chunk done", { processed, errors });
    }

    logger.info("[baselineSweepDaily] finished", { total: uids.length, processed, errors });
  }
);



