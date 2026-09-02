// lib/data/adapters/firestore/user_profile_service_fs.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';

/// Toggle to see verbose logs during onboarding/debug.
/// Flip to `true` locally when diagnosing writes.
const bool _debugFs = false;

void _dlog(Object msg) {
  if (_debugFs) {
    // ignore: avoid_print
    print('[UserProfileServiceFs] $msg');
  }
}

class UserProfileServiceFs implements UserProfileService {
  final FirebaseFirestore db;
  UserProfileServiceFs(this.db);

  // 🔄 PRIMARY PROFILE DOCS LIVE HERE NOW
  CollectionReference<Map<String, dynamic>> get _profiles =>
      db.collection(FirestorePathsV1.users);

  CollectionReference<Map<String, dynamic>> get _usernames =>
      db.collection('usernames');

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    _dlog('watchProfile → users/$uid');
    return _profiles.doc(uid).snapshots().map(
          (d) => d.exists ? UserProfile.fromMap(d.data()!) : null,
    );
  }

  /// Create or update full profile with server timestamps.
  /// - Sets `created_at` on first write.
  /// - Always sets `updated_at`.
  /// - Keeps merge semantics so partial writes are safe.
  @override
  Future<void> createOrUpdate(UserProfile p) async {
    final ref = _profiles.doc(p.uid);
    _dlog('createOrUpdate → users/${p.uid}');
    final snap = await ref.get();

    final payload = <String, dynamic>{
      ...p.toMap(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (!snap.exists || !snap.data()!.containsKey('created_at')) {
      payload['created_at'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  /// Merge arbitrary fields into the profile doc (with `updated_at`).
  /// HARDENED: If this is the *first* write to the document, enforce the
  /// minimum creation contract required by the security rules:
  ///   - first_name: string length ≥ 2
  ///   - dob: Firestore timestamp or 'YYYY-MM-DD' string
  ///
  /// This avoids rule trips when callers accidentally forget one of the
  /// required fields on the very first write.
  @override
  Future<void> createOrUpdatePartial({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final ref = _profiles.doc(uid);
    _dlog('createOrUpdatePartial → users/$uid payloadKeys=${data.keys.toList()}');

    final snap = await ref.get();
    final isCreate = !snap.exists;

    if (isCreate) {
      _enforceCreateMinimum(data); // throws ArgumentError on violation
    }

    final payload = <String, dynamic>{
      ...Map<String, dynamic>.from(data),
      'updated_at': FieldValue.serverTimestamp(),
      if (isCreate) 'created_at': FieldValue.serverTimestamp(),
    };

    await ref.set(payload, SetOptions(merge: true));
  }

  /// Convenience: Upsert the *minimum* profile required by rules.
  /// - Accepts DateTime for DOB and stores ISO 'YYYY-MM-DD' (human-friendly)
  ///   — rules also accept a Timestamp, but ISO is nice in the console.
  Future<void> upsertMinimal({
    required String uid,
    required String firstName,
    required DateTime dob,
    String? email,
  }) async {
    final isoDob = _isoDate(dob);
    final data = <String, dynamic>{
      'first_name': firstName.trim(),
      'dob': isoDob, // could be Timestamp.fromDate(dob) instead
      if (email != null) 'email': email,
      'uid': uid, // allowed by rules as long as it equals the doc path uid
    };
    _dlog('upsertMinimal → users/$uid first_name=${firstName.trim()} dob=$isoDob');
    await createOrUpdatePartial(uid: uid, data: data);
  }

  // -------------------- USERNAME HELPERS --------------------

  /// Simple availability (does a doc exist at /usernames/{handle}?).
  @override
  Future<bool> isUsernameAvailable(String usernameLower) async {
    final doc = await _usernames.doc(usernameLower).get();
    final available = !doc.exists;
    _dlog('isUsernameAvailable "$usernameLower" → $available');
    return available;
  }

  /// Availability that treats your own reservation as "available".
  @override
  Future<bool> isUsernameAvailableFor(String usernameLower, String uid) async {
    final owner = await usernameOwner(usernameLower);
    final ok = owner == null || owner == uid;
    _dlog('isUsernameAvailableFor "$usernameLower" (uid=$uid) → $ok (owner=$owner)');
    return ok;
  }

  /// Returns the UID that owns the handle, or null if unclaimed.
  @override
  Future<String?> usernameOwner(String usernameLower) async {
    final d = await _usernames.doc(usernameLower).get();
    if (!d.exists) return null;
    final owner = d.data()?['uid'];
    final ownerStr = owner is String ? owner : null;
    _dlog('usernameOwner "$usernameLower" → $ownerStr');
    return ownerStr;
  }

  /// One-time claim of a handle.
  /// Rules require: handle matches pattern, doc must not exist, uid == auth.uid.
  @override
  Future<void> reserveUsername(String usernameLower, String uid) async {
    _dlog('reserveUsername "$usernameLower" for uid=$uid');
    await _usernames.doc(usernameLower).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));
  }

  /// Keep a lightweight history of past handles so you can revert later.
  /// Store just strings to avoid any serverTimestamp-in-array complexity.
  @override
  Future<void> addUsernameHistory({
    required String uid,
    required String handleLower,
  }) async {
    _dlog('addUsernameHistory "$handleLower" for uid=$uid');
    await _profiles.doc(uid).set({
      'username_history': FieldValue.arrayUnion([handleLower]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // -------------------- INTERNAL --------------------

  /// Enforce the minimum *create* contract:
  /// - first_name must be a String of length ≥ 2
  /// - dob must be a Timestamp OR a 'YYYY-MM-DD' String
  void _enforceCreateMinimum(Map<String, dynamic> data) {
    final fn = data['first_name'];
    final dob = data['dob'];

    final firstOk = (fn is String) && fn.trim().length >= 2;
    final dobOk = dob is Timestamp ||
        (dob is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob));

    if (!firstOk || !dobOk) {
      _dlog('❌ Minimum create contract violated → first="$fn" dob="$dob"');
      throw ArgumentError(
        'Minimum profile fields missing or invalid for first write: '
            'first_name (≥2 chars) and dob (Timestamp or "YYYY-MM-DD") are required.',
      );
    }
  }

  String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da';
  }
}

/// FirestoreContractsV1
/// Central source of truth for Firestore collection & field names (v1 schema).
/// Avoids string literals spread across the codebase.
class FirestorePathsV1 {
  // ---- Top-level ----
  static const users = "users";
  static const userEvents = "user_events";
  static const systemRuns = "system_runs";
  static const leaderboards = "leaderboards";
  static const friends = "friends";
  static const groups = "groups";
  static const challenges = "challenges";
  static const communityEvents = "community_events";
  static const notifications = "notifications";
  static const invites = "invites";
  static const models = "models";
  static const percentiles = "percentiles";
  static const vitalityReference = "vitality_reference";
  static const tiers = "tiers";
  static const config = "config";

  // ---- User subcollections (under users/{uid}) ----
  static String days(String uid) => "users/$uid/days";
  static String dayDoc(String uid, String date) => "users/$uid/days/$date";

  static String hydrationDays(String uid) => "users/$uid/hydration_days";
  static String hydrationDayDoc(String uid, String date) =>
      "users/$uid/hydration_days/$date";

  static String measurements(String uid) => "users/$uid/measurements";
  static String workouts(String uid) => "users/$uid/workouts";
  static String glucose(String uid) => "users/$uid/biometrics_glucose";
  static String temp(String uid) => "users/$uid/biometrics_temp";
  static String bp(String uid) => "users/$uid/biometrics_bp";

  static String events(String uid) => "user_events/$uid/events";
  static String eventDoc(String uid, String id) =>
      "user_events/$uid/events/$id";

  // ---- Leaderboards ----
  static String leaderboardEntries(String boardId) =>
      "leaderboards/$boardId/entries";
}

class FirestoreFieldsV1 {
  // Identity
  static const dateLocal = "date_local";
  static const tz = "tz";

  // Inputs
  static const sleepTotalHours = "sleep_total_hours";
  static const stepsCount = "steps_count";
  static const hrvRmssdMs = "hrv_rmssd_ms";
  static const rhrBpm = "rhr_bpm";
  static const wellbeingLevel = "wellbeing_level_1to5";
  static const sleepRegularityPct = "sleep_regularity_pct";
  static const vo2max = "vo2max_ml_kg_min";
  static const fitnessAge = "fitness_age_years";

  // Computed
  static const ema7 = "ema7";
  static const staleDays = "stale_days";
  static const score = "score";
  static const riskIndex = "risk_index";
  static const vitalityAge = "vitality_age";
  static const scoreConfidence = "score_confidence";
  static const healthyDays30 = "healthy_days_30";
  static const wused = "wused";
  static const constants = "constants";

  // Metadata
  static const computedAtUtc = "computed_at_utc";
  static const lastSchedulerRunUtc = "last_scheduler_run_utc";
}
