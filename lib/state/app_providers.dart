// lib/state/app_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth user stream (global)
final authUserProvider = StreamProvider<User?>(
      (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Current UID (nullable)
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authUserProvider).value;
  return user?.uid;
});
