// lib/data/adapters/firestore/auth_service_fs.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class AuthServiceFs implements AuthService {
  final FirebaseAuth _auth;
  AuthServiceFs(this._auth);

  @override
  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) await user.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<UserCredential> signInWithGoogle() async {
    // You can wire google_sign_in or firebase_auth_oauth here as per platform.
    throw UnimplementedError('Google OAuth not wired on this build yet.');
  }
}
