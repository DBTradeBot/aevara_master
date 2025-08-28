import '../models/user_profile.dart';

abstract class UserProfileService {
  Stream<UserProfile?> watchProfile(String uid);
  Future<void> createOrUpdate(UserProfile profile);

  /// True if /usernames/{handle} does NOT exist.
  Future<bool> isUsernameAvailable(String usernameLower);

  /// True if the handle is free OR already reserved by this uid.
  Future<bool> isUsernameAvailableFor(String usernameLower, String uid);

  /// Returns the uid that owns this handle, or null if unclaimed.
  Future<String?> usernameOwner(String usernameLower);

  /// Reserve a handle (create /usernames/{handle} → { uid }).
  Future<void> reserveUsername(String usernameLower, String uid);

  /// Merge arbitrary fields into the profile doc (no model round-trip needed).
  Future<void> createOrUpdatePartial({
    required String uid,
    required Map<String, dynamic> data,
  });

  /// Append the previous handle to a simple history list.
  Future<void> addUsernameHistory({
    required String uid,
    required String handleLower,
  });
}
