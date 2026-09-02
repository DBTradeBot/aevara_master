// functions/exports/start_user_export.js
// Cloud Functions v2 (Node 20, ESM) "" start a user export job (callable)
// Creates users/{uid}/exports/{jobId} with status=queued and params

import { onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { randomUUID } from "node:crypto";

if (!getApps().length) initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const DEFAULT_EXPIRY_DAYS = Number(process.env.EXPORT_EXPIRY_DAYS || 7);

export const startUserExport = onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (req) => {
    try {
      const uid = req.auth?.uid || req.data?.uid;
      if (!uid) {
        return { ok: false, error: "unauthenticated" };
      }

      // Params from client
      const params = {
        dateRange: req.data?.dateRange || { kind: "all" }, // {kind:'all'|'last_30'|'custom', start:'YYYY-MM-DD', end:'YYYY-MM-DD'}
        formats: Array.isArray(req.data?.formats) && req.data.formats.length ? req.data.formats : ["ndjson", "csv"],
        includeRaw: !!req.data?.includeRaw,
        emailAlso: !!req.data?.emailAlso,
        tz: String(req.data?.tz || "America/Los_Angeles"),
      };

      const jobId = randomUUID();
      const now = new Date();
      const expiresAt = new Date(now.getTime() + DEFAULT_EXPIRY_DAYS * 24 * 3600 * 1000);

      const jobRef = db.doc(`users/${uid}/exports/${jobId}`);
      await jobRef.set({
        status: "queued",
        params,
        created_at_utc: FieldValue.serverTimestamp(),
        updated_at_utc: FieldValue.serverTimestamp(),
        expires_at_utc: expiresAt,
        download_url: null,
        bytes: null,
        job_id: jobId,
        started_by: uid,
      });

      logger.info("[exports] queued", { uid, jobId, params });

      // Firestore-triggered worker will pick this up.
      return { ok: true, jobId };
    } catch (e) {
      logger.error("[exports] start error", { message: e?.message });
      return { ok: false, error: String(e?.message || e) };
    }
  }
);



