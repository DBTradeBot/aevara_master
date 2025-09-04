import { db, FieldValue, Timestamp } from "../core/firebase_admin.js";
// functions/vendor/merge_daily.js
// Merge multi-vendor sync_days into a single "day" snapshot for compute
// Node 20 / ESM
import { isDateKey } from "../core/ddc_utils.js";

/**
 * mergeDailyFromVendors(uid, dateKey, { precedence, allowZerosToday = false })
 *
 * Reads vendor sync docs: users/{uid}/sync_days/{provider}_{dateKey}
 * Default precedence (first wins per metric): apple > whoop > garmin > fitbit > googlefit > manual
 *
 * Returns:
 * {
 *   date_local,
 *   steps_count?, calories_out?, distance_km?, floors?,
 *   minutes_very_active?, minutes_fairly_active?, minutes_lightly_active?, minutes_sedentary?,
 *   sleep_total_hours?, sleep_score?,
 *   rhr_bpm?, hrv_rmssd_ms?,
 *   vo2max_ml_kg_min?,
 *   sources: { <metric>: { provider, field, sample_at_utc? } },
 *   last_provider_sample_utc: { <metric>: ISO|string },
 *   merged_from: [ 'fitbit', 'whoop', ... ],
 * }
 */
export async function mergeDailyFromVendors(
  uid,
  dateKey,
  { precedence = ["apple", "whoop", "garmin", "fitbit", "googlefit", "manual"], allowZerosToday = false } = {}
) {
  if (!isDateKey(dateKey)) throw new Error("mergeDailyFromVendors: invalid dateKey");

  // Fetch existing vendor docs (best-effort)
  const providerIds = ["fitbit", "whoop", "garmin", "apple", "googlefit", "manual"];
  const snaps = await db.getAll(...providerIds.map((p) => db.doc(`users/${uid}/sync_days/${p}_${dateKey}`)));

  // Map provider → data
  const byProvider = {};
  snaps.forEach((snap) => {
    if (snap.exists) {
      const d = snap.data() || {};
      const id = snap.id.split("_")[0]; // 'fitbit_YYYY-MM-DD' → 'fitbit'
      byProvider[id] = d;
    }
  });

  const merged = {
    date_local: dateKey,
    sources: {},
    last_provider_sample_utc: {},
    merged_from: [],
  };

  const pick = (field, alias = field) => {
    for (const prov of precedence) {
      const row = byProvider[prov];
      if (!row) continue;
      const v = row[alias];
      if (v == null) continue;

      // Optional zero guard for "today" (fetchers also guard; we double-guard safely)
      if (!allowZerosToday && isZeroLike(v)) continue;

      merged[field] = v;
      merged.sources[field] = {
        provider: prov,
        field: alias,
        sample_at_utc: row[`last_${alias}_utc`] || row.sample_at_utc || null,
      };
      if (row[`last_${alias}_utc`]) {
        merged.last_provider_sample_utc[field] = row[`last_${alias}_utc`];
      }
      if (!merged.merged_from.includes(prov)) merged.merged_from.push(prov);
      return;
    }
  };

  // Activity
  pick("steps_count");
  pick("calories_out");
  pick("distance_km");
  pick("floors");
  pick("minutes_very_active");
  pick("minutes_fairly_active");
  pick("minutes_lightly_active");
  pick("minutes_sedentary");

  // Sleep
  pick("sleep_total_hours");
  pick("sleep_score");

  // Recovery
  pick("rhr_bpm");
  pick("hrv_rmssd_ms");

  // Cardiorespiratory fitness
  pick("vo2max_ml_kg_min");

  return merged;
}

/* --------------------------------- helpers --------------------------------- */

function isZeroLike(v) {
  if (v == null) return true;
  const n = Number(v);
  if (!Number.isFinite(n)) return false;
  return n === 0;
}
