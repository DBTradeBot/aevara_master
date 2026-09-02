import { db, FieldValue, Timestamp } from "../core/firebase_admin.js";
// functions/community/legacy_live.js
// Real, minimal implementations for critical legacy names.
// Node 20 / Gen 2 / ESM

import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Helpers â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */

function assertAuthed(req) {
  const uid = req.auth?.uid;
  if (!uid) throw new Error("UNAUTHENTICATED");
  return uid;
}

function assertString(val, name, min = 1, max = 80) {
  if (typeof val !== "string") throw new Error(`invalid ${name}`);
  const v = val.trim();
  if (v.length < min || v.length > max) throw new Error(`invalid ${name} length`);
  return v;
}

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Usernames â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
/**
 * Legacy callable: reserveUsername
 * Input: { handle: string }
 * Behavior:
 *  - Lowercase + validate handle
 *  - Atomically reserve usernames/{handle} = { uid, reservedAt }
 *  - If taken by different uid => error
 */
export const reserveUsername = onCall(async (req) => {
  const uid = assertAuthed(req);
  const handleRaw = assertString(req.data?.handle, "handle", 3, 24);
  const handle = handleRaw.toLowerCase();

  // simple policy: letters, digits, underscores, dots, hyphens; start with letter
  if (!/^[a-z][a-z0-9._-]*$/.test(handle)) throw new Error("invalid handle format");

  const ref = db.collection("usernames").doc(handle);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, { uid, reservedAt: FieldValue.serverTimestamp() });
      return;
    }
    const data = snap.data() || {};
    if (data.uid !== uid) throw new Error("handle_taken");
    // already reserved by same uid: treat as success
  });

  return { ok: true, handle };
});

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Friends counters â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
/**
 * Legacy callable: friendsCounters
 * Input: { uid?: string } (defaults to caller)
 * Recomputes counts in users/{uid}/friends_meta:
 *  - incoming_count, outgoing_count, accepted_count, blocked_count
 */
export const friendsCounters = onCall(async (req) => {
  const caller = assertAuthed(req);
  const targetUid = (req.data?.uid && typeof req.data.uid === "string")
    ? req.data.uid
    : caller;

  const base = db.collection("users").doc(targetUid);

  const [incoming, outgoing, accepted, blocked] = await Promise.all([
    base.collection("friends").doc("incoming").collection("items").count().get(),
    base.collection("friends").doc("outgoing").collection("items").count().get(),
    base.collection("friends").doc("accepted").collection("items").count().get(),
    base.collection("friends").doc("blocked").collection("items").count().get(),
  ]);

  const metaRef = base.collection("friends_meta").doc("counts");
  await metaRef.set({
    incoming_count: incoming.data().count || 0,
    outgoing_count: outgoing.data().count || 0,
    accepted_count: accepted.data().count || 0,
    blocked_count: blocked.data().count || 0,
    updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });

  return { ok: true };
});

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Groups counter â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
/**
 * Legacy callable: groupMembersCounter
 * Input: { groupId: string }
 * Recomputes groups/{groupId}.members_count from groups/{groupId}/members
 */
export const groupMembersCounter = onCall(async (req) => {
  assertAuthed(req);
  const groupId = assertString(req.data?.groupId, "groupId");

  const members = await db.collection("groups").doc(groupId).collection("members").count().get();
  await db.collection("groups").doc(groupId).set({
    members_count: members.data().count || 0,
    members_count_updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { ok: true };
});

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Challenges counter â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
/**
 * Legacy callable: challengeParticipantsCounter
 * Input: { challengeId: string }
 */
export const challengeParticipantsCounter = onCall(async (req) => {
  assertAuthed(req);
  const challengeId = assertString(req.data?.challengeId, "challengeId");

  const c = await db.collection("challenges").doc(challengeId).collection("participants").count().get();
  await db.collection("challenges").doc(challengeId).set({
    participants_count: c.data().count || 0,
    participants_count_updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { ok: true };
});

/* â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ Community events RSVPs â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€ */
/**
 * Legacy callable: eventRsvpsCounter
 * Input: { eventId: string }
 */
export const eventRsvpsCounter = onCall(async (req) => {
  assertAuthed(req);
  const eventId = assertString(req.data?.eventId, "eventId");

  const r = await db.collection("community_events").doc(eventId).collection("rsvps").count().get();
  await db.collection("community_events").doc(eventId).set({
    rsvps_count: r.data().count || 0,
    rsvps_count_updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { ok: true };
});



