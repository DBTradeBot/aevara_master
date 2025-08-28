import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';

class UserProfileServiceFs implements UserProfileService {
  final FirebaseFirestore db;
  UserProfileServiceFs(this.db);

  CollectionReference<Map<String, dynamic>> get _profiles =>
      db.collection('user_profiles');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      db.collection('usernames');

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map(
          (d) => d.exists ? UserProfile.fromMap(d.data()!) : null,
    );
  }

  /// Create or update profile with server timestamps.
  /// Use this when you want to set created_at on first create.
  @override
  Future<void> createOrUpdate(UserProfile p) async {
    final ref = _profiles.doc(p.uid);
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

  /// Simple availability (does a doc exist at /usernames/{handle}?).
  @override
  Future<bool> isUsernameAvailable(String usernameLower) async {
    final doc = await _usernames.doc(usernameLower).get();
    return !doc.exists;
  }

  /// Availability that treats your own reservation as "available".
  @override
  Future<bool> isUsernameAvailableFor(String usernameLower, String uid) async {
    final owner = await usernameOwner(usernameLower);
    return owner == null || owner == uid;
  }

  /// Returns the UID that owns the handle, or null if unclaimed.
  @override
  Future<String?> usernameOwner(String usernameLower) async {
    final d = await _usernames.doc(usernameLower).get();
    if (!d.exists) return null;
    final owner = d.data()?['uid'];
    return owner is String ? owner : null;
  }

  /// One-time claim of a handle.
  @override
  Future<void> reserveUsername(String usernameLower, String uid) async {
    await _usernames.doc(usernameLower).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));
  }

  /// Merge arbitrary fields into the profile doc (with updated_at).
  /// Intentionally does NOT send created_at from the client (rules-safe).
  @override
  Future<void> createOrUpdatePartial({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _profiles.doc(uid).set({
      ...Map<String, dynamic>.from(data),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Keep a lightweight history of past handles so you can revert later.
  /// Store just strings to avoid any serverTimestamp-in-array complexity.
  @override
  Future<void> addUsernameHistory({
    required String uid,
    required String handleLower,
  }) async {
    await _profiles.doc(uid).set({
      'username_history': FieldValue.arrayUnion([handleLower]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
