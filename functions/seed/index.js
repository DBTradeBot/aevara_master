// functions/seed/index.js
// Unified Firestore seeder (idempotent)
// - Seeds reference/config/models_v1 (primary)
// - Seeds reference/config/models (legacy container with default + v1)
// - Seeds reference/config/scaffolds (placeholders)
// - Supports dryRun and logs touched paths
// Node 20 / ESM

import { onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db, FieldValue } from "../core/firebase_admin.js";

const REGION = "us-central1";

/**
 * Callable: seedFirestore
 *
 * Example (no changes, just write):
 *   seedFirestore({})
 *
 * Example (dry run):
 *   seedFirestore({ dryRun: true })
 *
 * Optional overrides (all optional; omit to keep defaults):
 *   {
 *     dryRun?: boolean,
 *     model?: {
 *       version?: string,               // default "v1"
 *       scale_years?: number,           // default 12
 *       pivot_risk?: number,            // default 0.35
 *       groups?: {                      // default { recovery:0.4, sleep:0.3, activity:0.3, affect:0.0 }
 *         recovery?: number,
 *         sleep?: number,
 *         activity?: number,
 *         affect?: number
 *       },
 *       caps?: {                        // default { daily_va_abs:1.0, total_va_abs:10 }
 *         daily_va_abs?: number,        // per-day clamp (|Î"| â‰¤ daily_va_abs)
 *         total_va_abs?: number,        // absolute cap vs chosen anchor (baseline or chrono)
 *         anchor_mode?: "baseline"|"chronological", // total cap is measured vs which anchor (default "baseline")
 *       },
 *       early_period?: {                // early-period tightening (optional)
 *         days?: number,                // default 14
 *         daily_va_abs?: number,        // default 1.0 (kept)
 *         drift_toward_baseline?: number // 0..1 dampening toward baseline (default 0)
 *       },
 *       flags?: {
 *         sex_norms_enabled?: boolean,  // default true (HRV/RHR sex-aware bounds)
 *         slow_anchors_enabled?: boolean, // default true (body_comp/bp/glucose scoring hooks)
 *         softer_sleep_tail?: boolean   // default false (gives 5.5""6h a small positive)
 *       },
 *       change_cooldown_sec?: number    // default 0
 *     }
 *   }
 */
export const seedFirestore = onCall({ region: REGION }, async (req) => {
  try {
    const dryRun = !!req.data?.dryRun;
    const m = req.data?.model || {};

    // Defaults aligned with loader and new runtime knobs
    const modelPayload = {
      version: String(m.version ?? "v1"),
      scale_years: isNum(m.scale_years) ? Number(m.scale_years) : 12,
      pivot_risk: isNum(m.pivot_risk) ? Number(m.pivot_risk) : 0.35,

      groups: {
        recovery: isNum(m.groups?.recovery) ? Number(m.groups.recovery) : 0.4,
        sleep:    isNum(m.groups?.sleep)    ? Number(m.groups.sleep)    : 0.3,
        activity: isNum(m.groups?.activity) ? Number(m.groups.activity) : 0.3,
        affect:   isNum(m.groups?.affect)   ? Number(m.groups.affect)   : 0.0, // wellbeing present but weight 0 by default
      },

      caps: {
        daily_va_abs:  isNum(m.caps?.daily_va_abs)  ? Number(m.caps.daily_va_abs)  : 1.0,
        total_va_abs:  isNum(m.caps?.total_va_abs)  ? Number(m.caps.total_va_abs)  : 10,
        anchor_mode:   oneOf(m.caps?.anchor_mode, ["baseline","chronological"]) ?? "baseline",
      },

      // Early period gate (optional softeners)
      early_period: {
        days:                  isNum(m.early_period?.days) ? Number(m.early_period.days) : 14,
        daily_va_abs:          isNum(m.early_period?.daily_va_abs) ? Number(m.early_period.daily_va_abs) : 1.0,
        drift_toward_baseline: clamp01(m.early_period?.drift_toward_baseline ?? 0),
      },

      flags: {
        sex_norms_enabled:     bool(m.flags?.sex_norms_enabled, true),
        slow_anchors_enabled:  bool(m.flags?.slow_anchors_enabled, true),
        softer_sleep_tail:     bool(m.flags?.softer_sleep_tail, false),
      },

      change_cooldown_sec: isNum(m.change_cooldown_sec) ? Number(m.change_cooldown_sec) : 0,
      updated_at_utc: FieldValue.serverTimestamp(),
    };

    const paths = [];

    // 1) Primary model doc: reference/config/models_v1
    {
      const ref = db.doc("reference/config/models_v1");
      paths.push(ref.path);
      if (!dryRun) await ref.set(modelPayload, { merge: true });
    }

    // 2) Legacy container: reference/config/models (default + v1)
    {
      const ref = db.doc("reference/config/models");
      const container = {
        default: shrinkForContainer(modelPayload),
        [modelPayload.version]: shrinkForContainer(modelPayload),
        updated_at_utc: FieldValue.serverTimestamp(),
      };
      paths.push(ref.path);
      if (!dryRun) await ref.set(container, { merge: true });
    }

    // 3) Scaffolds (placeholders for future percentile/bounds tables)
    {
      const ref = db.doc("reference/config/scaffolds");
      const data = {
        percentiles_scaffold: true,
        sex_bounds_scaffold: true,
        updated_at_utc: FieldValue.serverTimestamp(),
      };
      paths.push(ref.path);
      if (!dryRun) await ref.set(data, { merge: true });
    }

    logger.info("[seed] models/config seeded", { dryRun, paths });
    return { ok: true, dryRun, version: modelPayload.version, paths };
  } catch (e) {
    logger.error("seedFirestore error", { message: e?.message });
    return { ok: false, error: String(e?.message || e) };
  }
});

/* ------------------------------ helpers ------------------------------ */

function isNum(n) {
  return Number.isFinite(Number(n));
}
function clamp01(x) {
  const n = Number(x);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(1, n));
}
function bool(v, def) {
  return typeof v === "boolean" ? v : !!def;
}
function oneOf(v, allowed) {
  const s = String(v || "");
  return allowed.includes(s) ? s : null;
}

// Keep the legacy container slim (no timestamps)
function shrinkForContainer(mp) {
  const { updated_at_utc, ...rest } = mp || {};
  return rest;
}


