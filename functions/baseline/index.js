// functions/baseline/index.js
// Baseline orchestrator: ensureBaselineOnLogin + lightRefresh4
// - Idempotent guard (server-side cooldown)
// - Anchored window compute via runRangeForUser (today..D-3)
// - Guarantees last-30-day Fitbit coverage before compute (imported helper)
// Node 20 / ESM

import { onCall, onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { db } from "../core/firebase_admin.js";
import { runRangeForUser } from "../ddc/compute_range.js";
import { verifyAppCheckOrScheduler } from "../core/app_check.js";
// vendor coverage helper
import { ensureThirtyDayCoverageForUid } from "../vendor/fitbit_fetch.js";

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
  const includeCrf = source?.includeCrf === true; // pass through to coverage helper if desired
  return { tz, policy, force, days, includeCrf };
}

/**
 * ensureBaselineOnLogin (callable)
 * data: { tz?: string, policy?: string, days?: number, force?: boolean, includeCrf?: boolean }
 * App Check enforced.
 *
 * Order of ops:
 *  1) Ensure Fitbit last-30-day coverage (missing âˆª incomplete repair).
 *  2) Compute anchored window (today..D-3).
 */
export const ensureBaselineOnLogin = onCall(
  { region: REGION, enforceAppCheck: true },
  async (req) => {
    const uid = req.auth?.uid || String(req.data?.uid || "");
    const { tz, policy, force, days, includeCrf } = parseParams(req.data);

    try {
      if (!uid) return { ok: false, error: "unauthenticated" };

      const proceed = force || (await shouldRunBaseline(uid));
      if (!proceed) return { ok: true, no_op: true, reason: "cooldown" };

      // coverage pass first (guarantee inputs)
      await ensureThirtyDayCoverageForUid(uid, { includeCrf: includeCrf || true });

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
          summary: {
            total: out.total,
            computed: out.computed,
            skipped_final: out.skipped_final,
          },
        });

      return { ok: true, ...out };
    } catch (e) {
      // extra diagnostics for any future "Invalid time value" class issues
      logger.error("ensureBaselineOnLogin error", {
        message: e?.message,
        uid,
        tz,
        policy,
        force,
        days,
        includeCrf,
      });
      return { ok: false, error: String(e?.message || e) };
    }
  }
);

/**
 * ensureBaselineOnLoginHttp (HTTP)
 *
 * POST only
 * Body: { userId|uid, tz?, policy?, days?, force?, includeCrf? }
 * Guard order:
 *   1) Firebase App Check header OR Cloud Scheduler OIDC (strict audience)
 *   2) Fallback optional header token x-aevara-cron (if AEVARA_BASELINE_HTTP_TOKEN is set)
 *
 * Order of ops:
 *  1) coverage (30d)  2) compute window
 */
export const ensureBaselineOnLoginHttp = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    // CORS preflight
    if (req.method === "OPTIONS") return res.status(204).send("");

    if (req.method !== "POST") return res.status(405).json({ ok: false, error: "Use POST" });

    const uid = String(req.body?.userId || req.body?.uid || "");
    const { tz, policy, force, days, includeCrf } = parseParams(req.body);

    try {
      // 1) App Check / OIDC (Scheduler) verification
      const verified = await verifyAppCheckOrScheduler(req);
      if (!verified) {
        // 2) Fallback simple header token if configured
        const requiredToken = process.env.AEVARA_BASELINE_HTTP_TOKEN;
        if (requiredToken) {
          const provided = String(req.header("x-aevara-cron") || "");
          if (provided !== requiredToken) {
            return res.status(401).json({ ok: false, error: "unauthorized" });
          }
        } else {
          return res.status(401).json({ ok: false, error: "invalid_app_check_or_oidc" });
        }
      }

      if (!uid) return res.status(400).json({ ok: false, error: "Missing userId" });

      const proceed = force || (await shouldRunBaseline(uid));
      if (!proceed) return res.status(200).json({ ok: true, no_op: true, reason: "cooldown" });

      // Coverage first
      await ensureThirtyDayCoverageForUid(uid, { includeCrf: includeCrf || true });

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
          summary: {
            total: out.total,
            computed: out.computed,
            skipped_final: out.skipped_final,
          },
        });

      return res.status(200).json({ ok: true, ...out });
    } catch (e) {
      logger.error("ensureBaselineOnLoginHttp error", {
        message: e?.message,
        uid,
        tz,
        policy,
        force,
        days,
        includeCrf,
      });
      return res.status(500).json({ ok: false, error: String(e?.message || e) });
    }
  }
);

/**
 * lightRefresh4 (callable) "" explicit quick refresh helper
 * data: { tz?: string, policy?: string, force?: boolean, includeCrf?: boolean }
 * App Check enforced.
 *
 * We still run coverage to avoid "sleep=0" days hanging around,
 * then compute a short 4-day window for fast UI freshness.
 */
export const lightRefresh4 = onCall(
  { region: REGION, enforceAppCheck: true },
  async (req) => {
    const uid = req.auth?.uid || String(req.data?.uid || "");
    const { tz, policy, force, includeCrf } = parseParams(req.data);

    try {
      if (!uid) return { ok: false, error: "unauthenticated" };

      await ensureThirtyDayCoverageForUid(uid, { includeCrf: includeCrf || true });

      const out = await runRangeForUser(uid, { tz, policy, force, days: 4 });
      return { ok: true, ...out };
    } catch (e) {
      logger.error("lightRefresh4 error", {
        message: e?.message,
        uid,
        tz,
        policy,
        force,
        includeCrf,
      });
      return { ok: false, error: String(e?.message || e) };
    }
  }
);



