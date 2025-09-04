// functions/core/dynamic_window.js
// Dynamic window loader + parameter chooser for DDC
// Anchors dynamic window to the day being computed (D), not "today"
// Node 20 / ESM

import { db } from "../core/firebase_admin.js";
import {
  isDateKey,
} from "./ddc_utils.js";



/**
 * loadWindowUpToD(uid, dateKey, { limit = 30 })
 * Loads up to `limit` day docs with id <= dateKey (lexical order on YYYY-MM-DD).
 * Returns array of day data ordered ASC (oldest→newest), capped at `limit`.
 */
export async function loadWindowUpToD(uid, dateKey, { limit = 30 } = {}) {
  if (!isDateKey(dateKey)) throw new Error("loadWindowUpToD: invalid dateKey");
  const col = db.collection(`users/${uid}/days`);
  // Fetch a little more to buffer sparse histories
  const snap = await col.orderBy("__name__").endAt(dateKey).limitToLast(limit + 4).get();
  const docs = snap.docs.map((d) => ({ id: d.id, ...((d.data() || {})) }));
  // Keep only last `limit`
  return docs.slice(Math.max(0, docs.length - limit));
}

/**
 * chooseDynamicParams(windowDocs, modelCfg)
 * Decide pivot_risk/scale_years or other dynamics based on the window preceding/including D.
 * For v1 we mostly pass-through model config but this is the hook to adapt with user's baseline.
 *
 * Returns:
 * {
 *   pivot_risk,
 *   scale_years,
 *   window: { size: N, first: 'YYYY-MM-DD', last: 'YYYY-MM-DD' }
 * }
 */
export function chooseDynamicParams(windowDocs, modelCfg) {
  const N = Array.isArray(windowDocs) ? windowDocs.length : 0;
  const first = N ? String(windowDocs[0].id) : null;
  const last = N ? String(windowDocs[N - 1].id) : null;

  // Future: infer scale based on variability or anchors; for now adopt cfg
  const pivot_risk = Number(modelCfg?.pivot_risk ?? 0.35) || 0.35;
  const scale_years = Number(modelCfg?.scale_years ?? 12) || 12;

  return {
    pivot_risk,
    scale_years,
    window: { size: N, first, last },
  };
}

