// functions/core/firebase_admin.js
// Pure ESM Admin SDK bootstrap (Node 20 / Firebase Admin v12+)

import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";

// Initialize Admin exactly once (credential from env / runtime)
if (!getApps().length) {
  initializeApp({ credential: applicationDefault() });
}

// Firestore (ignore undefined so partial updates don't throw)
export const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

// Re-export commonly used Admin helpers/types
export { FieldValue, Timestamp, getAuth, getStorage };
