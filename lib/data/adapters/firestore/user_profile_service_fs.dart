// lib/data/adapters/firestore/user_profile_service_fs.dart
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

  /// Create or update profile, using server timestamps for `updated_at`
  /// and a set-once `created_at`.
  @override
  Future<void> createOrUpdate(UserProfile p) async {
    final ref = _profiles.doc(p.uid);
    final snap = await ref.get();

    final base = p.toMap();

    // Always update updated_at from server
    final payload = <String, dynamic>{
      ...base,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Only set created_at on first creation to keep true creation time
    if (!snap.exists || !snap.data()!.containsKey('created_at')) {
      payload['created_at'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  @override
  Future<bool> isUsernameAvailable(String usernameLower) async {
    final doc = await _usernames.doc(usernameLower).get();
    return !doc.exists;
  }

  /// Reserve a username (no race conditions in simple flows). For high
  /// contention names, consider wrapping this in a transaction.
  @override
  Future<void> reserveUsername(String usernameLower, String uid) async {
    await _usernames.doc(usernameLower).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));
  }

  /// Partial update helper that also refreshes `updated_at` via server time.
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
}
