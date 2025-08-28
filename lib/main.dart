// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// If using generated options, uncomment and import:
// import 'firebase_options.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first. (No anonymous sign-in here.)
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 Important: DO NOT auto sign-in anonymously.
  // That was causing the app to think you're "signed in" and skip auth.

  runApp(const ProviderScope(child: AevaraApp()));
}
