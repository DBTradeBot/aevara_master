import { db, FieldValue, Timestamp } from "../core/firebase_admin.js";
// functions/normalize/index.js
// Normalization triggers (scaffold):
// - Convert user-entered / imported entries into a low-friction manual provider snapshot
//   at users/{uid}/sync_days/manual_{YYYY-MM-DD} so mergeDailyFromVendors can consider it.
// - BP enrichment on write (pulse pressure + MAP) "" maintained under BOTH names:
//     normBloodPressure (background trigger) and enrichBP (background trigger)
// Node 20 / ESM

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { dateKeyInTZ, isDateKey, round } from "../core/ddc_utils.js";

const DEFAULT_TZ = "America/Los_Angeles";

/* ------------------------------- helpers ---------------------------------- */

function num(n) {
  const v = Number(n);
  return Number.isFinite(v) ? v : null;
}

async function upsertManualSyncDay(uid, dateKey, patch = {}) {
  if (!isDateKey(dateKey)) return;
  const ref = db.doc(`users/${uid}/sync_days/manual_${dateKey}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const cur = snap.exists ? snap.data() || {} : {};
    const next = { ...cur, ...patch, updated_at_utc: FieldValue.serverTimestamp() };
    tx.set(ref, next, { merge: true });
  });
}

/* Internal core for BP enrichment; used by both triggers below */
async function enrichBpCore(afterRef, afterData) {
  const s = num(afterData.systolic);
  const di = num(afterData.diastolic);
  if (!(Number.isFinite(s) && Number.isFinite(di))) return { wrote: false };

  const pulse_pressure = s - di;
  const map = Math.round((di + pulse_pressure / 3) * 10) / 10;

  // Only write if changed to avoid noisy loops when multiple triggers exist
  const cur_pp = num(afterData.pulse_pressure);
  const cur_map = num(afterData.mean_arterial_pressure);
  const already =
    cur_pp === pulse_pressure && cur_map === map && !!afterData.enriched_at;

  if (already) return { wrote: false };

  await afterRef.set(
    {
      pulse_pressure,
      mean_arterial_pressure: map,
      enriched_at: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { wrote: true, pulse_pressure, mean_arterial_pressure: map };
}

/* ------------------------- Measurements â†' manual --------------------------- */
/**
 * users/{uid}/measurements/{id}
 *   { at_utc, tz?, steps_count?, distance_km?, calories_out?,
 *     hrv_rmssd_ms?, rhr_bpm?, sleep_total_hours?, notes? }
 */
export const normMeasurements = onDocumentWritten(
  "users/{uid}/measurements/{id}",
  async (event) => {
    try {
      const after = event.data?.after;
      if (!after) return;
      const uid = event.params.uid;
      const d = after.data() || {};

      const tz = String(d.tz || DEFAULT_TZ);
      const at = d.at_utc?.toDate?.() || (d.at_utc ? new Date(String(d.at_utc)) : new Date());
      const dateKey = dateKeyInTZ(at, tz);

      const patch = {};
      if (num(d.steps_count) != null) patch.steps_count = num(d.steps_count);
      if (num(d.distance_km) != null) patch.distance_km = num(d.distance_km);
      if (num(d.calories_out) != null) patch.calories_out = num(d.calories_out);
      if (num(d.hrv_rmssd_ms) != null) patch.hrv_rmssd_ms = num(d.hrv_rmssd_ms);
      if (num(d.rhr_bpm) != null) patch.rhr_bpm = num(d.rhr_bpm);
      if (num(d.sleep_total_hours) != null) patch.sleep_total_hours = num(d.sleep_total_hours);

      if (Object.keys(patch).length) {
        await upsertManualSyncDay(uid, dateKey, patch);
      }
    } catch (e) {
      logger.error("normMeasurements error", { message: e?.message });
    }
  }
);

/* --------------------------- Workouts â†' manual ----------------------------- */
/**
 * users/{uid}/workouts/{id}
 * { at_utc, tz?, steps?, distance_km?, calories? , minutes_active? }
 * Additive merge into manual_{dateKey}.
 */
export const normWorkouts = onDocumentWritten("users/{uid}/workouts/{id}", async (event) => {
  try {
    const after = event.data?.after;
    if (!after) return;
    const uid = event.params.uid;
    const w = after.data() || {};

    const tz = String(w.tz || DEFAULT_TZ);
    const at = w.at_utc?.toDate?.() || (w.at_utc ? new Date(String(w.at_utc)) : new Date());
    const dateKey = dateKeyInTZ(at, tz);

    const patch = {};
    if (num(w.steps) != null) patch.steps_count = num(w.steps) || 0;
    if (num(w.distance_km) != null) patch.distance_km = num(w.distance_km) || 0;
    if (num(w.calories) != null) patch.calories_out = num(w.calories) || 0;
    if (num(w.minutes_active) != null) {
      patch.minutes_lightly_active = num(w.minutes_active) || 0; // rough
    }

    if (!Object.keys(patch).length) return;

    // Accumulate into manual sync_day
    const ref = db.doc(`users/${uid}/sync_days/manual_${dateKey}`);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const cur = snap.exists ? snap.data() || {} : {};
      const next = { ...cur };
      for (const k of Object.keys(patch)) {
        const curN = num(cur[k]) || 0;
        next[k] = round(curN + (num(patch[k]) || 0), 2);
      }
      next.updated_at_utc = FieldValue.serverTimestamp();
      tx.set(ref, next, { merge: true });
    });
  } catch (e) {
    logger.error("normWorkouts error", { message: e?.message });
  }
});

/* ------------------------ Hydration / Biometrics (scaffold) ---------------- */

export const normHydration = onDocumentWritten(
  "users/{uid}/hydration_days/{id}",
  async (event) => {
    try {
      const after = event.data?.after;
      if (!after) return;
      const uid = event.params.uid;
      const h = after.data() || {};
      const tz = String(h.tz || DEFAULT_TZ);
      const at = h.at_utc?.toDate?.() || (h.at_utc ? new Date(String(h.at_utc)) : new Date());
      const dateKey = dateKeyInTZ(at, tz);
      if (num(h.hydration_ml) != null) {
        await upsertManualSyncDay(uid, dateKey, { hydration_ml: num(h.hydration_ml) });
      }
    } catch (e) {
      logger.error("normHydration error", { message: e?.message });
    }
  }
);

export const normGlucose = onDocumentWritten(
  "users/{uid}/biometrics_glucose/{id}",
  async () => {
    // scaffold "" no-op by default
  }
);

export const normTemp = onDocumentWritten(
  "users/{uid}/biometrics_temp/{id}",
  async () => {
    // scaffold "" no-op by default
  }
);

/**
 * BP normalization + enrichment on write.
 * users/{uid}/biometrics_bp/{id}  â†' computes:
 *   - pulse_pressure = systolic - diastolic
 *   - mean_arterial_pressure = diastolic + (pulse_pressure / 3)
 */
export const normBloodPressure = onDocumentWritten(
  "users/{uid}/biometrics_bp/{id}",
  async (event) => {
    try {
      const after = event.data?.after;
      if (!after) return;
      const d = after.data() || {};
      await enrichBpCore(after.ref, d);
    } catch (e) {
      logger.error("normBloodPressure error", { message: e?.message });
    }
  }
);

/* -------------------- Legacy name kept as BACKGROUND trigger ---------------- */
/**
 * IMPORTANT:
 * Firebase says your previously deployed "enrichBP" is a background trigger.
 * We keep that exact name and type here to avoid "changing from background to callable".
 */
export const enrichBP = onDocumentWritten(
  "users/{uid}/biometrics_bp/{id}",
  async (event) => {
    try {
      const after = event.data?.after;
      if (!after) return;
      const d = after.data() || {};
      await enrichBpCore(after.ref, d);
    } catch (e) {
      logger.error("enrichBP trigger error", { message: e?.message });
    }
  }
);

/* ---------------------- Legacy export aliases (safe) ----------------------- */
/**
 * Important: avoid circular self-imports like `export {...} from "./index.js"`.
 * Just alias the names directly so old callers keep working.
 */
export const normalizeMeasurements = normMeasurements;
export const normalizeWorkouts = normWorkouts;
export const normalizeHydration = normHydration;
export const normalizeGlucose = normGlucose;
export const normalizeTemp = normTemp;
export const normalizeBloodPressure = normBloodPressure;


