// functions/core/dynamic_window.js
// Dynamic window loader + parameter chooser for DDC
// Anchors dynamic window to the day being computed (D), not "today"
// Node 20 / ESM

import { db } from "./firebase_admin.js";
import { isDateKey } from "./ddc_utils.js";

/**
 * loadWindowUpToD(uid, dateKey, { limit = 30 })
 * Loads up to `limit` day docs with id <= dateKey (lexical order on YYYY-MM-DD).
 * Returns array of day data ordered ASC (oldestâ†'newest), capped at `limit`.
 */
export async function loadWindowUpToD(uid, dateKey, { limit = 30 } = {}) {
  if (!isDateKey(dateKey)) throw new Error("loadWindowUpToD: invalid dateKey");
  const col = db.collection(`users/${uid}/days`);
  const snap = await col.orderBy("__name__").endAt(dateKey).limitToLast(limit + 4).get();
  const docs = snap.docs.map((d) => ({ id: d.id, ...((d.data() || {})) }));
  return docs.slice(Math.max(0, docs.length - limit));
}

/**
 * chooseDynamicParams(windowDocs, modelCfg)
 * Decide scale_years (always) and optionally pivot_risk based on policy.
 *
 * For calibrated-pivot mode, we DO NOT inject a pivot_risk here; compute() will
 * derive it from dynamic.baseline_risk_median + anchors via its own formula.
 *
 * Returns:
 * {
 *   ...(pivot_risk?)  // only when calibrate_pivot === false
 *   scale_years,
 *   window: { size: N, first, last }
 * }
 */
export function chooseDynamicParams(windowDocs, modelCfg) {
  const N = Array.isArray(windowDocs) ? windowDocs.length : 0;
  const first = N ? String(windowDocs[0].id) : null;
  const last = N ? String(windowDocs[N - 1].id) : null;

  const scale_years = Number(modelCfg?.scale_years ?? 12) || 12;
  const calibrate = modelCfg?.flags?.calibrate_pivot !== false;

  const base = {
    scale_years,
    window: { size: N, first, last },
  };

  if (calibrate) {
    // Let compute() calibrate the pivot using baseline window; don't set here.
    return base;
  }

  // Non-calibrated mode: pass through model's pivot
  const pivot_risk = Number(modelCfg?.pivot_risk ?? 0.35) || 0.35;
  return { ...base, pivot_risk };
}



