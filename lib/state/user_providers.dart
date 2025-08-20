// lib/state/user_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../data/services/user_profile_service.dart';
import '../data/adapters/firestore/user_profile_service_fs.dart';
import '../data/models/user_profile.dart';

/// Auth user (nullable)
final authUserProvider = StreamProvider<User?>(
      (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Current UID (null when signed out)
final currentUserIdProvider = Provider<String?>(
      (ref) => ref.watch(authUserProvider).value?.uid,
);

/// Firestore
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

/// User profile service
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final db = ref.watch(firestoreProvider);
  return UserProfileServiceFs(db);
});

/// ✅ Write alias to satisfy pages expecting `userProfileWriteProvider`
final userProfileWriteProvider = Provider<UserProfileService>((ref) {
  return ref.watch(userProfileServiceProvider);
});

/// Current user profile
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final svc = ref.watch(userProfileServiceProvider);
  if (uid == null) return const Stream<UserProfile?>.empty();
  return svc.watchProfile(uid);
});

/// Cloud Functions
final functionsProvider = Provider<FirebaseFunctions>((_) => FirebaseFunctions.instance);

/// Callable: reserveUsername
final reserveUsernameCallableProvider = Provider<HttpsCallable>((ref) {
  final fns = ref.watch(functionsProvider);
  return fns.httpsCallable('reserveUsername');
});
