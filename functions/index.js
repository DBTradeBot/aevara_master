// functions/index.js
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp();

const HANDLE_RE = /^[a-z0-9_.]{3,20}$/;

/**
 * Atomically reserve a username and mirror it onto the user's profile.
 * Writes:
 *   - usernames/{handleLower} = { uid, reservedAt }
 *   - user_profiles/{uid} merge: { username, username_lower, updated_at }
 */
export const reserveUsername = onCall(async (request) => {
  const authUid = request.auth?.uid;
  const usernameRaw = (request.data?.username ?? "")
      .toString()
      .trim()
      .replace(/^@/, "");

  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const lower = usernameRaw.toLowerCase();
  if (!HANDLE_RE.test(lower)) {
    throw new HttpsError("invalid-argument", "Invalid username format.");
  }

  const db = getFirestore();

  await db.runTransaction(async (tx) => {
    const handleRef = db.doc(`usernames/${lower}`);
    const profileRef = db.doc(`user_profiles/${authUid}`);

    const existing = await tx.get(handleRef);
    if (existing.exists) {
      const owner = existing.get("uid");
      if (owner !== authUid) {
        throw new HttpsError("already-exists", "Username is taken.");
      }
      // If it already belongs to this user, treat as idempotent success.
    } else {
      tx.set(handleRef, {
        uid: authUid,
        reservedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.set(
        profileRef,
        {
          uid: authUid,
          username: usernameRaw,
          username_lower: lower,
          updated_at: FieldValue.serverTimestamp(),
        },
        {merge: true},
    );
  });

  return {ok: true, username: usernameRaw, lower};
});
