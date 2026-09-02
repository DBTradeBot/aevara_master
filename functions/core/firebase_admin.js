// functions/core/firebase_admin.js
import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp, FieldPath } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";

if (!getApps().length) initializeApp({ credential: applicationDefault() });

export const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

// Re-exports (FieldPath is optional here)
export { FieldValue, Timestamp, FieldPath, getAuth, getStorage };
