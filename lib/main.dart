// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app.dart'; // must export AevaraApp
// If you have generated Firebase options, import them:
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  // Try to ensure an authenticated user (anonymous in dev).
  // If Anonymous is disabled, we log and keep going so the app boots.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    // admin-restricted-operation means the Anonymous provider is disabled.
    // App can still boot, but Firestore rules requiring auth will block reads/writes.
    debugPrint('⚠️ Firebase anonymous sign-in failed: $e');
  }

  runApp(const ProviderScope(child: AevaraApp()));
}
