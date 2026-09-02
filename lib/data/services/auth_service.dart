// lib/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

/// App-level auth interface used by UI and guards.
abstract class AuthService {
  Stream<User?> authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  User? get currentUser;
}
