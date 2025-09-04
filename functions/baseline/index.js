// functions/baseline/index.js
// Baseline orchestrator: ensureBaselineOnLogin + lightRefresh4
// - Idempotent guard (server-side cooldown)
// - Anchored window compute via runRangeForUser (today..D-3)
// Node 20 / ESM

import { onCall, onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { db } from "../core/firebase_admin.js";
import { runRangeForUser } from "../ddc/compute_range.js";

const REGION = "us-central1";
const COOLDOWN_MS = 5 * 60 * 1000; // 5 minutes

async function shouldRunBaseline(uid) {
  const ref = db.doc(`users/${uid}`);
  const snap = await ref.get();
  const u = snap.exists ? snap.data() || {} : {};
  const last = Number(u?.baseline_last_checked_ms || 0);
  const now = Date.now();
  const ok = now - last >= COOLDOWN_MS;
  if (ok) {
    await ref.set({ baseline_last_checked_ms: now }, { merge: true });
  }
  return ok;
}

function parseParams(source) {
  const tz = String(source?.tz || "America/Los_Angeles");
  const policy = (source?.policy || "lag_yesterday").toString();
  const force = !!source?.force;
  const days = Math.min(10, Math.max(1, Number(source?.days ?? 4)));
  return { tz, policy, force, days };
}

/**
 * ensureBaselineOnLogin (callable)
 * data: { tz?: string, policy?: string, days?: number, force?: boolean }
 */
export const ensureBaselineOnLogin = onCall({ region: REGION }, async (req) => {
  try {
    const uid = req.auth?.uid || String(req.data?.uid || "");
    if (!uid) return { ok: false, error: "unauthenticated" };

    const { tz, policy, force, days } = parseParams(req.data);

    const proceed = force || (await shouldRunBaseline(uid));
    if (!proceed) return { ok: true, no_op: true, reason: "cooldown" };

    const out = await runRangeForUser(uid, { tz, policy, force, days });

    await db
      .collection("users")
      .doc(uid)
      .collection("system_runs_server")
      .add({
        at_utc: new Date().toISOString(),
        source: "ensureBaselineOnLogin",
        tz,
        policy,
        days,
        summary: { total: out.total, computed: out.computed, skipped_final: out.skipped_final },
      });

    return { ok: true, ...out };
  } catch (e) {
    logger.error("ensureBaselineOnLogin error", { message: e?.message });
    return { ok: false, error: String(e?.message || e) };
  }
});

/**
 * ensureBaselineOnLoginHttp (HTTP)
 * - POST only
 * - Body: { userId|uid, tz?, policy?, days?, force? }
 * - Optional simple header guard for server-to-server: set env AEVARA_BASELINE_HTTP_TOKEN
 *   and include header: x-aevara-cron: <that-token>
 */
export const ensureBaselineOnLoginHttp = onRequest({ region: REGION, cors: true }, async (req, res) => {
  try {
    // CORS preflight
    if (req.method === "OPTIONS") return res.status(204).send("");

    if (req.method !== "POST") return res.status(405).json({ ok: false, error: "Use POST" });

    // Optional lightweight guard (in addition to Scheduler OIDC, if configured)
    const requiredToken = process.env.AEVARA_BASELINE_HTTP_TOKEN;
    if (requiredToken) {
      const provided = String(req.header("x-aevara-cron") || "");
      if (provided !== requiredToken) {
        return res.status(401).json({ ok: false, error: "unauthorized" });
      }
    }

    const uid = String(req.body?.userId || req.body?.uid || "");
    if (!uid) return res.status(400).json({ ok: false, error: "Missing userId" });

    const { tz, policy, force, days } = parseParams(req.body);

    const proceed = force || (await shouldRunBaseline(uid));
    if (!proceed) return res.status(200).json({ ok: true, no_op: true, reason: "cooldown" });

    const out = await runRangeForUser(uid, { tz, policy, force, days });

    await db
      .collection("users")
      .doc(uid)
      .collection("system_runs_server")
      .add({
        at_utc: new Date().toISOString(),
        source: "ensureBaselineOnLoginHttp",
        tz,
        policy,
        days,
        summary: { total: out.total, computed: out.computed, skipped_final: out.skipped_final },
      });

    return res.status(200).json({ ok: true, ...out });
  } catch (e) {
    logger.error("ensureBaselineOnLoginHttp error", { message: e?.message });
    return res.status(500).json({ ok: false, error: String(e?.message || e) });
  }
});

/**
 * lightRefresh4 (callable) – explicit quick refresh helper
 * data: { tz?: string, policy?: string, force?: boolean }
 */
export const lightRefresh4 = onCall({ region: REGION }, async (req) => {
  try {
    const uid = req.auth?.uid || String(req.data?.uid || "");
    if (!uid) return { ok: false, error: "unauthenticated" };

    const { tz, policy, force } = parseParams(req.data);
    const out = await runRangeForUser(uid, { tz, policy, force, days: 4 });
    return { ok: true, ...out };
  } catch (e) {
    logger.error("lightRefresh4 error", { message: e?.message });
    return { ok: false, error: String(e?.message || e) };
  }
});
