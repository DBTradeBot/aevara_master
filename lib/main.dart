// lib/main.dart
//
// Initialize Firebase + App Check + ensure UID, then run Aevara.
// Startup sync is handled INSIDE AppShell after the first frame.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'firebase_options.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check first so subsequent SDK calls are under protection.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    // webRecaptchaSiteKey: '...'
  );

  // Ensure a UID up-front so Firestore paths are bound immediately.
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  runApp(
    const ProviderScope(
      child: AevaraApp(),
    ),
  );
}
