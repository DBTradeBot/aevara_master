// lib/core/telemetry.dart
//
// Production-ready telemetry helpers (client-side, user-scoped).
// - Fixes PERMISSION_DENIED by writing under users/{uid}/system_runs_client/*
// - Provides a debounced "once per window" guard for boot actions (e.g., compute).
// - Safe offline (Firestore queue).
// - Minimal deps: only firebase_auth & cloud_firestore.
//
// Usage examples (keep your existing call sites; pick whichever style you use):
//   await Telemetry.logAppShellSync(phase: 'fresh_login', extras: {'source':'app_shell'});
//   await logAppShellSync(phase: 'resume');
//   final didKick = await Telemetry.maybeKick(() async { await myCompute(); }, windowSec: 10);

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Class API (common pattern in this codebase).
class Telemetry {
  Telemetry._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static DateTime? _lastKick;

  /// Debounce/once-per-window guard for costly boot actions.
  /// Returns true if [action] executed in this call; false if skipped due to debounce.
  static Future<bool> maybeKick(
      Future<void> Function() action, {
        int windowSec = 10,
      }) async {
    final now = DateTime.now();
    if (_lastKick != null) {
      final dt = now.difference(_lastKick!).inSeconds;
      if (dt < windowSec) return false;
    }
    _lastKick = now;
    await action();
    return true;
    // NOTE: If you need per-session reset, set _lastKick = null on sign-out.
  }

  /// User-scoped telemetry write: users/{uid}/system_runs_client/{autoId}
  /// This replaces any previous global write to system_runs/app_shell_sync.
  static Future<void> logAppShellSync({
    String phase = 'fresh_login',
    Map<String, Object?> extras = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) return; // not signed in yet

    final now = DateTime.now().toUtc();

    final payload = <String, Object?>{
      'phase': phase,                   // e.g., 'fresh_login','resume','cold_start'
      'ts_utc': now,
      'sdk': {
        'platform': 'flutter',
        'firebase_auth': true,
        'firestore': true,
      },
      'app': _appSummary(),
      'device': _deviceSummary(),
      'extras': extras,
    };

    await _withBackoff(() async {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('system_runs_client')
          .add(payload);
    });
  }

  /// Generic user-scoped event logger (optional helper, same rules).
  static Future<void> logEvent({
    required String name,
    Map<String, Object?> data = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final payload = <String, Object?>{
      'name': name,
      'ts_utc': DateTime.now().toUtc(),
      'data': data,
    };

    await _withBackoff(() async {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('system_runs_client')
          .add(payload);
    });
  }

  // --- Internal helpers -----------------------------------------------------

  static Map<String, Object?> _deviceSummary() {
    // Keep minimal to avoid extra plugins; you can enrich later (device_info_plus, platform checks).
    return {
      'platform_hint': 'android_or_ios_or_web', // update if you wire platform detection
    };
  }

  static Map<String, Object?> _appSummary() {
    // Minimal; wire package_info_plus later for real version/build/channel.
    return {
      'channel': 'dev',
      'env': 'debug',
    };
  }

  static Future<T> _withBackoff<T>(Future<T> Function() fn) async {
    const maxRetries = 5;
    var attempt = 0;
    var delay = const Duration(milliseconds: 200);
    final rng = Random();

    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) rethrow;
        // Exponential backoff with jitter: 200ms → 400 → 800 → 1600 → 3200
        final jitterMs = (delay.inMilliseconds * (0.25 * rng.nextDouble())).round();
        await Future.delayed(delay + Duration(milliseconds: jitterMs));
        delay *= 2;
      }
    }
  }
}

/// Top-level function API (in case your call sites import functions instead of class methods).
Future<void> logAppShellSync({
  String phase = 'fresh_login',
  Map<String, Object?> extras = const {},
}) {
  return Telemetry.logAppShellSync(phase: phase, extras: extras);
}
