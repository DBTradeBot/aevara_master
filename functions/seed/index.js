// functions/seed/index.js
// Seed helpers (callable): seedFirestore
// - Seeds reference/config model v1 if missing
// - Optional demo percentiles/doc scaffolds
// Node 20 / ESM

import { onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from '../core/firebase_admin.js';


const REGION = "us-central1";

export const seedFirestore = onCall({ region: REGION }, async (req) => {
  try {
    // Auth optional; you may add admin check here
    const dryRun = !!req.data?.dryRun;

    const paths = [];

    // Model config v1
    {
      const ref = db.doc("reference/config/models_v1");
      const data = {
        version: "v1",
        scale_years: 12,
        pivot_risk: 0.35,
        groups: { recovery: 0.4, sleep: 0.3, activity: 0.3, affect: 0.0 },
        caps: { daily_va_abs: 1.0, total_va_abs: 10 },
        change_cooldown_sec: 0,
        updated_at_utc: new Date().toISOString(),
      };
      paths.push(ref.path);
      if (!dryRun) await ref.set(data, { merge: true });
    }

    // Optional: reference/config/models (single doc container)
    {
      const ref = db.doc("reference/config/models");
      const data = {
        default: {
          version: "v1",
          scale_years: 12,
          pivot_risk: 0.35,
          groups: { recovery: 0.4, sleep: 0.3, activity: 0.3, affect: 0.0 },
          caps: { daily_va_abs: 1.0, total_va_abs: 10 },
          change_cooldown_sec: 0,
        },
        v1: {
          version: "v1",
          scale_years: 12,
          pivot_risk: 0.35,
          groups: { recovery: 0.4, sleep: 0.3, activity: 0.3, affect: 0.0 },
          caps: { daily_va_abs: 1.0, total_va_abs: 10 },
          change_cooldown_sec: 0,
        },
        updated_at_utc: new Date().toISOString(),
      };
      paths.push(ref.path);
      if (!dryRun) await ref.set(data, { merge: true });
    }

    // Optional scaffolds — percentiles, bounds, etc. (kept minimal)
    {
      const ref = db.doc("reference/config/scaffolds");
      const data = {
        percentiles_scaffold: true,
        sex_bounds_scaffold: true,
        updated_at_utc: new Date().toISOString(),
      };
      paths.push(ref.path);
      if (!dryRun) await ref.set(data, { merge: true });
    }

    return { ok: true, dryRun, paths };
  } catch (e) {
    logger.error("seedFirestore error", { message: e?.message });
    return { ok: false, error: String(e?.message || e) };
  }
});

