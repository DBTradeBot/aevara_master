// lib/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp(String email, String password);
  Future<void> sendEmailVerification();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<UserCredential> signInWithGoogle(); // stub; platform code handled by firebase_auth_oauth or google_sign_in
}
