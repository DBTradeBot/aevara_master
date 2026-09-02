// lib/data/adapters/firestore/auth_service_fs.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

/// FirebaseAuth-backed AuthService.
class AuthServiceFs implements AuthService {
  AuthServiceFs({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optional: send email verification automatically
    try {
      await cred.user?.sendEmailVerification();
    } catch (_) {}

    return cred;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  User? get currentUser => _auth.currentUser;
}
