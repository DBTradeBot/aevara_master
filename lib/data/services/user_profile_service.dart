// lib/data/services/user_profile_service.dart
import '../models/user_profile.dart';

abstract class UserProfileService {
  Stream<UserProfile?> watchProfile(String uid);
  Future<void> createOrUpdate(UserProfile profile);
  Future<bool> isUsernameAvailable(String usernameLower);
  Future<void> reserveUsername(String usernameLower, String uid);

  /// Merge arbitrary fields into the profile doc (no model round‑trip needed).
  Future<void> createOrUpdatePartial({
    required String uid,
    required Map<String, dynamic> data,
  });
}
