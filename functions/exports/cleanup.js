// functions/exports/cleanup.js
// Scheduled job to delete expired export files and mark jobs as cleaned.

import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Storage } from "@google-cloud/storage";

if (!getApps().length) initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const storage = new Storage();

const REGION = "us-central1";
const EXPORTS_BUCKET = process.env.EXPORTS_BUCKET;

function pickBucket() {
  if (EXPORTS_BUCKET) return EXPORTS_BUCKET;
  const proj = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "";
  if (!proj) throw new Error("Missing project id. Set EXPORTS_BUCKET env for safety.");
  return `${proj}.appspot.com`;
}

export const cleanupExpiredExports = onSchedule(
  {
    region: REGION,
    schedule: "every 24 hours",
    timeZone: "America/Los_Angeles",
  },
  async () => {
    const bucketName = pickBucket();
    const bucket = storage.bucket(bucketName);

    let cleaned = 0;

    // Sweep user export jobs with expired links
    const usersSnap = await db.collection("users").get();
    for (const u of usersSnap.docs) {
      const uid = u.id;
      const exportsCol = db.collection(`users/${uid}/exports`);
      const jobsSnap = await exportsCol.where("expires_at_utc", "<", new Date()).get();

      for (const j of jobsSnap.docs) {
        const d = j.data() || {};
        if (d.storage_path && !d.cleaned) {
          try {
            const [, ...pathParts] = String(d.storage_path).split("/"); // bucket/path
            const storagePath = pathParts.join("/");
            await bucket.file(storagePath).delete({ ignoreNotFound: true });
            await j.ref.set(
              {
                cleaned: true,
                updated_at_utc: FieldValue.serverTimestamp(),
                download_url: null,
              },
              { merge: true }
            );
            cleaned++;
          } catch (e) {
            logger.warn("[exports] cleanup failed", { storage_path: d.storage_path, msg: e?.message });
          }
        }
      }
    }

    logger.info("[exports] cleanup complete", { cleaned });
    return { ok: true, cleaned };
  }
);


