import { db, FieldValue, Timestamp } from "./firebase_admin.js";
// functions/core/leases.js
// Per-day compute lease with even-segment subcollection
// Node 20 / ESM
/**
 * acquireDayLease(uid, dateKey, { ttlMs = 90_000 })
 * Creates/updates a short-lived lease document to prevent concurrent compute of the same day.
 * Path: users/{uid}/days/{dateKey}/_leases/run
 *
 * Returns: { ok: boolean, token?: string, until_ms?: number, refPath?: string }
 */
export async function acquireDayLease(uid, dateKey, { ttlMs = 90_000 } = {}) {
  const ref = db.doc(`users/${uid}/days/${dateKey}/_leases/run`);
  const token = Math.random().toString(36).slice(2);
  const now = Date.now();
  const expiresAt = now + Math.max(30_000, ttlMs);

  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() || {} : {};
    const existingExpires = Number(data?.expires_at_ms || 0);
    const owner = String(data?.owner_token || "");
    const expired = existingExpires < now;

    if (!snap.exists || expired || owner === token) {
      tx.set(ref, {
        owner_token: token,
        acquired_at_ms: now,
        expires_at_ms: expiresAt,
        heartbeats: 0,
        updated_at_utc: FieldValue.serverTimestamp(),
      });
      return { ok: true, token, until_ms: expiresAt, refPath: ref.path };
    }
    return { ok: false, until_ms: existingExpires, refPath: ref.path };
  });

  return out;
}

/**
 * heartbeatDayLease(uid, dateKey, token, { extendMs = 60_000 })
 * Optionally extend the lease during long compute.
 */
export async function heartbeatDayLease(uid, dateKey, token, { extendMs = 60_000 } = {}) {
  const ref = db.doc(`users/${uid}/days/${dateKey}/_leases/run`);
  const now = Date.now();
  const extendTo = now + Math.max(20_000, extendMs);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const d = snap.data() || {};
    if (String(d.owner_token) !== String(token)) return; // not owner
    tx.set(
      ref,
      {
        expires_at_ms: extendTo,
        heartbeats: (Number(d.heartbeats) || 0) + 1,
        updated_at_utc: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

/**
 * releaseDayLease(uid, dateKey, token)
 * Best-effort; safe if already expired.
 */
export async function releaseDayLease(uid, dateKey, token) {
  const ref = db.doc(`users/${uid}/days/${dateKey}/_leases/run`);
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const d = snap.data() || {};
      if (String(d.owner_token) === String(token)) {
        tx.delete(ref);
      }
    });
  } catch (e) {
    // best-effort
  }
}



