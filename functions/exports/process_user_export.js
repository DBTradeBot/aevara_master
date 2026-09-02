// functions/exports/process_user_export.js
// Firestore-triggered background worker to process user exports
// - Streams users/{uid}/days/* to NDJSON and optional CSV
// - Optionally dumps raw provider sync_days/*
// - Zips files, uploads to GCS, creates V4 signed URL
// - Updates users/{uid}/exports/{jobId}

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { Storage } from "@google-cloud/storage";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import archiver from "archiver";

// Import helpers (ESM JS; no TS/transpile)
import {
  writeDaysAsNdjson,
  writeDaysAsCsv,
  writeSyncDaysAsNdjson,
  writeMetadataJson,
} from "../lib/data_export.js";

if (!getApps().length) initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const storage = new Storage();

const REGION = "us-central1";
const ENV_BUCKET = process.env.EXPORTS_BUCKET; // optional override
const SIGNED_URL_EXPIRY_DAYS = Number(process.env.EXPORT_EXPIRY_DAYS || 7);

/* ------------------------------ Bucket resolution ------------------------------ */
/**
 * Prefer Firebase config's storageBucket (handles .firebasestorage.app),
 * then EXPORTS_BUCKET env, then <projectId>.appspot.com as a conservative fallback.
 */
function resolveDefaultBucket() {
  try {
    if (process.env.FIREBASE_CONFIG) {
      const cfg = JSON.parse(process.env.FIREBASE_CONFIG);
      if (cfg && cfg.storageBucket) return cfg.storageBucket; // e.g. vitalis-xxxx.firebasestorage.app
      if (cfg && cfg.projectId) return `${cfg.projectId}.appspot.com`;
    }
  } catch (e) {
    logger.warn("[exports] FIREBASE_CONFIG parse failed", { message: e?.message });
  }

  if (ENV_BUCKET && typeof ENV_BUCKET === "string" && ENV_BUCKET.length > 0) {
    return ENV_BUCKET;
  }

  const proj =
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    process.env.PROJECT_ID;
  if (!proj) throw new Error("Missing project id; set EXPORTS_BUCKET or FIREBASE_CONFIG.projectId");
  return `${proj}.appspot.com`;
}

/* ------------------------------ Trigger ------------------------------ */
export const processUserExport = onDocumentCreated(
  {
    region: REGION,
    document: "users/{uid}/exports/{jobId}",
    retry: false,
    memory: "1GiB",
    timeoutSeconds: 540,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    const uid = event.params.uid;
    const jobId = event.params.jobId;
    const jobRef = db.doc(`users/${uid}/exports/${jobId}`);

    const fail = async (msg) => {
      logger.error("[exports] job failed", { uid, jobId, msg });
      await jobRef.set(
        {
          status: "error",
          error_message: String(msg),
          updated_at_utc: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    };

    try {
      if (data.status !== "queued") return;

      await jobRef.set(
        { status: "running", updated_at_utc: FieldValue.serverTimestamp() },
        { merge: true }
      );

      // ---- bucket resolve + preflight ----
      const bucketName = resolveDefaultBucket();
      const bucket = storage.bucket(bucketName);

      const [exists] = await bucket.exists().catch((e) => {
        logger.error("[exports] bucket.exists() threw", { bucketName, msg: e?.message });
        return [false];
      });
      if (!exists) {
        return await fail(
          `Export bucket not found: "${bucketName}". ` +
          "Fix: enable Firebase Storage for the project or set EXPORTS_BUCKET to a valid bucket."
        );
      }

      // ---- temp work dir ----
      const workdir = fs.mkdtempSync(path.join(os.tmpdir(), `export-${jobId}-`));
      const files = [];

      // metadata.json
      const metadataPath = path.join(workdir, "metadata.json");
      await writeMetadataJson(metadataPath, { uid, jobId, params: data.params });
      files.push({ local: metadataPath, name: "metadata.json" });

      // days.* (NDJSON always; CSV optional)
      const daysNdjsonPath = path.join(workdir, "days.ndjson");
      await writeDaysAsNdjson(db, uid, data.params, daysNdjsonPath);
      files.push({ local: daysNdjsonPath, name: "days.ndjson" });

      if ((data.params?.formats || []).includes("csv")) {
        const daysCsvPath = path.join(workdir, "days.csv");
        await writeDaysAsCsv(db, uid, data.params, daysCsvPath);
        files.push({ local: daysCsvPath, name: "days.csv" });
      }

      // raw sync_days.* (optional)
      if (data.params?.includeRaw) {
        const rawNdjsonPath = path.join(workdir, "sync_days.ndjson");
        await writeSyncDaysAsNdjson(db, uid, data.params, rawNdjsonPath);
        files.push({ local: rawNdjsonPath, name: "sync_days.ndjson" });
      }

      // README.txt (ASCII-safe)
      const readmePath = path.join(workdir, "README.txt");
      fs.writeFileSync(
        readmePath,
        [
          "Aevara - Your Data Export",
          "",
          "What's inside:",
          " - days.ndjson: one JSON object per line (all computed day fields).",
          " - days.csv: flattened, spreadsheet-friendly (if selected).",
          " - sync_days.ndjson: raw vendor-per-day rows (if selected).",
          " - metadata.json: models, versions, units, and field dictionary.",
          "",
          "Privacy: This ZIP was generated only for your account. The link expires automatically.",
          "Reproducibility: metadata.json contains model/build ids so you can re-run formulas.",
          "",
          "Have questions? Reach us via the app -> Settings -> Help.",
          "",
        ].join("\n")
      );
      files.push({ local: readmePath, name: "README.txt" });

      // ---- zip ----
      const zipName = `${jobId}.zip`;
      const zipLocal = path.join(workdir, "export.zip"); // create then upload as jobId.zip
      await zipFiles(zipLocal, files);

      // ---- upload ----
      const destPath = `exports/${uid}/${zipName}`;
      await bucket.upload(zipLocal, {
        destination: destPath,
        contentType: "application/zip",
      });

      // ---- signed url ----
      const expires = new Date(Date.now() + SIGNED_URL_EXPIRY_DAYS * 24 * 3600 * 1000);
      let signedUrl;
      try {
        [signedUrl] = await bucket
          .file(destPath)
          .getSignedUrl({ action: "read", version: "v4", expires });
      } catch (e) {
        const m = String(e?.message || e);
        const hint = m.includes("signBlob")
          ? "Missing permission: roles/iam.serviceAccountTokenCreator on the function's service account."
          : "Ensure the function's service account can sign URLs and has Storage access.";
        return await fail(`Failed to create signed URL: ${m} ${hint}`);
      }

      // ---- size ----
      const [meta] = await bucket.file(destPath).getMetadata();
      const sizeBytes = Number(meta?.size || 0);

      // ---- update job ----
      await jobRef.set(
        {
          status: "ready",
          updated_at_utc: FieldValue.serverTimestamp(),
          download_url: signedUrl,
          expires_at_utc: Timestamp.fromDate(expires),
          bytes: sizeBytes,
          storage_path: `${bucketName}/${destPath}`,
        },
        { merge: true }
      );

      // ---- cleanup tmp ----
      try {
        for (const f of files) fs.unlinkSync(f.local);
        fs.unlinkSync(zipLocal);
        fs.rmdirSync(workdir);
      } catch (e) {
        // best effort
        logger.warn("[exports] tmp cleanup issue", { message: e?.message });
      }

      logger.info("[exports] ready", { uid, jobId, bytes: sizeBytes, destPath });
    } catch (e) {
      await fail(e?.message || e);
    }
  }
);

/* ------------------------------ helpers ------------------------------ */
async function zipFiles(zipLocal, files) {
  await new Promise((resolve, reject) => {
    const output = fs.createWriteStream(zipLocal);
    const archive = archiver("zip", { zlib: { level: 9 } });
    output.on("close", resolve);
    archive.on("error", reject);
    archive.pipe(output);
    for (const f of files) archive.file(f.local, { name: f.name });
    archive.finalize();
  });
}

// Provide a default export too, for code that does `export { default as processUserExport } ...`
export default processUserExport;
