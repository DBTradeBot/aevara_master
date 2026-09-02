// functions/lib/data_export.js
// Helpers to stream Firestore docs to NDJSON/CSV and write metadata.json (ESM)

import fs from "node:fs";

/* ------------------------ utilities ------------------------ */

function isDateKey(s) {
  return typeof s === "string" && /^\d{4}-\d{2}-\d{2}$/.test(s);
}

function withinRange(dateKey, params) {
  const kind = params?.dateRange?.kind || "all";
  if (kind === "all") return true;

  if (kind === "last_30") {
    // Compute cutoff (UTC) and compare as YYYY-MM-DD strings to match doc ids.
    const now = new Date();
    const cutoff = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const cutoffKey = cutoff.toISOString().slice(0, 10); // YYYY-MM-DD
    return dateKey >= cutoffKey;
  }

  if (kind === "custom") {
    const start = String(params?.dateRange?.start || "");
    const end = String(params?.dateRange?.end || "");
    if (isDateKey(start) && isDateKey(end)) return dateKey >= start && dateKey <= end;
  }

  // Default: include
  return true;
}

function flattenDayDoc(doc) {
  const d = doc || {};
  const n = (v) => (Number.isFinite(Number(v)) ? Number(v) : null);
  return {
    date_local: d.date_local || null,
    vitality_age: n(d.vitality_age),
    vitality_age_raw: n(d.vitality_age_raw),
    vitality_delta: n(d.vitality_delta),
    risk_index: n(d.risk_index),
    score_confidence: n(d.score_confidence),

    group_recovery: n(d?.groups?.recovery),
    group_sleep: n(d?.groups?.sleep),
    group_activity: n(d?.groups?.activity),

    used_hrv_rmssd_ms: n(d?.inputs?.used?.hrv_rmssd_ms),
    used_rhr_bpm: n(d?.inputs?.used?.rhr_bpm),
    used_sleep_total_hours: n(d?.inputs?.used?.sleep_total_hours),
    used_steps_count: n(d?.inputs?.used?.steps_count),

    ema_hrv_rmssd_ms: n(d?.inputs?.ema7?.hrv_rmssd_ms),
    ema_rhr_bpm: n(d?.inputs?.ema7?.rhr_bpm),
    ema_sleep_total_hours: n(d?.inputs?.ema7?.sleep_total_hours),
    ema_steps_count: n(d?.inputs?.ema7?.steps_count),

    fresh_hrv: !!d?.freshness?.hrv,
    fresh_rhr: !!d?.freshness?.rhr,
    fresh_sleep: !!d?.freshness?.sleep,
    fresh_steps: !!d?.freshness?.steps,

    activity_policy: d?.provenance?.activity_policy || null,
    activity_from_date: d?.provenance?.activity_from_date || null,

    compute_signature: d?.hashes?.compute_signature || null,

    age_years_used: n(d?.anchors_brief?.age_years_used),
    baseline_age_years: n(d?.anchors_brief?.baseline_age_years),
    baseline_vitality_age_years: n(d?.anchors_brief?.baseline_vitality_age_years),
  };
}

function toCsvLine(obj, header) {
  const esc = (v) => {
    if (v === null || v === undefined) return "";
    const s = String(v);
    if (s.includes(",") || s.includes('"') || s.includes("\n")) return `"${s.replace(/"/g, '""')}"`;
    return s;
  };
  return header.map((k) => esc(obj[k])).join(",") + "\n";
}

/* ------------------------ writers ------------------------ */

export async function writeMetadataJson(filePath, ctx) {
  const meta = {
    version: "1.0",
    generated_at_utc: new Date().toISOString(),
    user: { uid: ctx.uid },
    job_id: ctx.jobId,
    params: ctx.params,
    models: {
      compute_engine_version: "from each day record constants.compute_engine_version",
      model_version: "from each day record constants.model_version",
      pivot_risk_source: "from each day record dynamic_used.pivot_source",
      scale_years: "from each day record dynamic_used.scale_years",
    },
    units: {
      hrv_rmssd_ms: "ms",
      rhr_bpm: "bpm",
      sleep_total_hours: "hours",
      steps_count: "steps",
    },
  };
  fs.writeFileSync(filePath, JSON.stringify(meta, null, 2));
}

export async function writeDaysAsNdjson(db, uid, params, filePath) {
  const out = fs.createWriteStream(filePath, { encoding: "utf8" });
  const col = db.collection(`users/${uid}/days`);
  const snap = await col.orderBy("__name__", "asc").get();
  for (const doc of snap.docs) {
    const id = doc.id;
    if (!isDateKey(id)) continue;
    if (!withinRange(id, params)) continue;
    const data = doc.data();
    out.write(JSON.stringify({ id, ...data }) + "\n");
  }
  out.end();
  await new Promise((r) => out.on("close", r));
}

export async function writeDaysAsCsv(db, uid, params, filePath) {
  const header = [
    "date_local",
    "vitality_age",
    "vitality_age_raw",
    "vitality_delta",
    "risk_index",
    "score_confidence",
    "group_recovery",
    "group_sleep",
    "group_activity",
    "used_hrv_rmssd_ms",
    "used_rhr_bpm",
    "used_sleep_total_hours",
    "used_steps_count",
    "ema_hrv_rmssd_ms",
    "ema_rhr_bpm",
    "ema_sleep_total_hours",
    "ema_steps_count",
    "fresh_hrv",
    "fresh_rhr",
    "fresh_sleep",
    "fresh_steps",
    "activity_policy",
    "activity_from_date",
    "compute_signature",
    "age_years_used",
    "baseline_age_years",
    "baseline_vitality_age_years",
  ];

  const out = fs.createWriteStream(filePath, { encoding: "utf8" });
  out.write(header.join(",") + "\n");

  const col = db.collection(`users/${uid}/days`);
  const snap = await col.orderBy("__name__", "asc").get();
  for (const doc of snap.docs) {
    const id = doc.id;
    if (!isDateKey(id)) continue;
    if (!withinRange(id, params)) continue;
    const row = flattenDayDoc({ id, ...doc.data() });
    out.write(toCsvLine(row, header));
  }
  out.end();
  await new Promise((r) => out.on("close", r));
}

export async function writeSyncDaysAsNdjson(db, uid, _params, filePath) {
  const out = fs.createWriteStream(filePath, { encoding: "utf8" });
  const col = db.collection(`users/${uid}/sync_days`);
  const snap = await col.orderBy("__name__", "asc").get();
  for (const doc of snap.docs) {
    out.write(JSON.stringify({ id: doc.id, ...doc.data() }) + "\n");
  }
  out.end();
  await new Promise((r) => out.on("close", r));
}


