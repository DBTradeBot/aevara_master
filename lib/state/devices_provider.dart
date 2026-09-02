// lib/state/devices_provider.dart
//
// Devices service (Fitbit fetch) + deviceStatusProvider -> Map<String, SyncStatus>.
// - Uses FlutterFire Cloud Functions (callable): fitbitFetchNowCall
// - Falls back to HTTP endpoint when callable fails (App Check hiccup, not deployed, timeout).
// - Exposes per-provider SyncStatus for onboarding/settings UIs.
//
// Requirements: cloud_functions, cloud_firestore, firebase_auth, riverpod

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:cloud_functions/cloud_functions.dart' as cf;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import '../core/env.dart' as env;
import 'app_providers.dart'; // currentUserIdProvider
import 'package:aevara_app/core/widgets/tiles/sync_status_dot.dart' show SyncStatus;

/* ─────────────────────────── Service API ─────────────────────────── */

abstract class DevicesService {
  /// Server-triggered Fitbit fetch for [uid].
  /// - If [backfill] is true, asks the server to fetch up to [days] days (defaults to 14).
  /// - Otherwise performs a quick refresh (defaults to 4 days).
  /// - [includeCrf] toggles calling the heavier CRF endpoint (off for fast paths).
  /// - [reason] is logged server-side for diagnostics.
  Future<bool> fitbitFetchNowFor(
      String uid, {
        int days = 14,
        bool backfill = false,
        bool includeCrf = false,
        String reason = 'auto',
      });
}

/* ─────────────────────────── Service impl ─────────────────────────── */

class FirebaseDevicesService implements DevicesService {
  final cf.FirebaseFunctions _functions;

  FirebaseDevicesService({
    cf.FirebaseFunctions? functions,
  }) : _functions = functions ?? cf.FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<String?> _getAppCheckToken() async {
    try {
      final tok = await FirebaseAppCheck.instance.getToken();
      if (tok is String && tok.isNotEmpty) return tok;
    } catch (_) {}
    return null;
  }

  bool _httpUrlLooksConfigured(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty) return false;
    if (u.contains('<project-id>')) return false; // placeholder
    if (!u.startsWith('http://') && !u.startsWith('https://')) return false;
    return true;
  }

  Future<bool> _httpFallback({
    required String uid,
    required int days,
    required bool backfill,
    required bool includeCrf,
    required String reason,
  }) async {
    final httpUrl = env.FITBIT_FETCH_URL;
    if (!_httpUrlLooksConfigured(httpUrl)) {
      if (kDebugMode) {
        debugPrint('[DevicesService] HTTP fallback disabled: FITBIT_FETCH_URL not configured');
      }
      return false;
    }

    try {
      final client = HttpClient()..badCertificateCallback = (_, __, ___) => false;
      final req = await client.postUrl(Uri.parse(httpUrl!.trim()));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final secret = env.SYNC_SHARED_SECRET ?? '';
      if (secret.isNotEmpty) req.headers.set('x-sync-secret', secret);

      // Attach App Check token for HTTP path
      final appCheck = await _getAppCheckToken();
      if (appCheck != null) {
        req.headers.set('X-Firebase-AppCheck', appCheck);
      }

      final body = json.encode({
        'uid': uid,
        'days': days,
        'backfill': backfill,
        'only': 'all',
        'includeCrf': includeCrf,
        'reason': reason, // harmless extra field for server logs
      });
      req.add(utf8.encode(body));

      final resp = await req.close();
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      await resp.drain<void>();
      client.close(force: true);
      if (!ok && kDebugMode) {
        debugPrint('[DevicesService] HTTP fallback failed (${resp.statusCode})');
      }
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('[DevicesService] HTTP fallback error: $e');
      return false;
    }
  }

  @override
  Future<bool> fitbitFetchNowFor(
      String uid, {
        int days = 14,
        bool backfill = false,
        bool includeCrf = false,
        String reason = 'auto',
      }) async {
    // 1) Try callable first (fast path). App Check is automatically attached.
    try {
      final callable = _functions.httpsCallable(
        'fitbitFetchNowCall',
        // ↑ Region is us-central1 (instanceFor above). Timeout ≥ 2 minutes.
        options: cf.HttpsCallableOptions(timeout: Duration(minutes: 2)),
      );

      final res = await callable.call<Map<String, dynamic>>({
        'uid': uid,
        'days': days,
        'backfill': backfill,
        'only': 'all',
        'includeCrf': includeCrf,
        'reason': reason,
      });

      final data = res.data;
      final ok = (data['ok'] == true);
      if (ok) return true;
      if (kDebugMode) debugPrint('[DevicesService] callable returned not ok: $data');
    } catch (e) {
      if (kDebugMode) debugPrint('[DevicesService] callable error: $e');
      // fall through to HTTP
    }

    // 2) HTTP fallback (with App Check header) — only if configured
    return _httpFallback(
      uid: uid,
      days: days,
      backfill: backfill,
      includeCrf: includeCrf,
      reason: reason,
    );
  }
}

/* ─────────────────────────── DI ─────────────────────────── */

final devicesServiceProvider = Provider<DevicesService>((ref) {
  return FirebaseDevicesService();
});

/* ─────────────── Per-provider link row (internal struct) ─────────────── */

class _ProviderLinkRow {
  final bool connected;
  final DateTime? lastSyncUtc;
  final DateTime? lastBackfillAtUtc;
  final String? lastStatus;
  final String? errorMsg;

  const _ProviderLinkRow({
    required this.connected,
    this.lastSyncUtc,
    this.lastBackfillAtUtc,
    this.lastStatus,
    this.errorMsg,
  });

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate().toUtc();
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v).toUtc();
      } catch (_) {}
    }
    return null;
  }

  factory _ProviderLinkRow.from(Map<String, dynamic>? m) {
    final data = m ?? const {};
    return _ProviderLinkRow(
      connected: data['connected'] == true,
      lastSyncUtc: _toDate(data['last_sync_utc']),
      lastBackfillAtUtc: _toDate(data['last_backfill_at_utc']),
      lastStatus: (data['last_status'] as String?)?.trim(),
      errorMsg: (data['error_msg'] as String?)?.trim(),
    );
  }
}

/* ───────────────────── Map<provider, SyncStatus> ───────────────────── */

SyncStatus _toSyncStatus(_ProviderLinkRow row) {
  if (!row.connected) return SyncStatus.none;

  final now = DateTime.now().toUtc();
  final last = row.lastSyncUtc;
  if (last == null) return SyncStatus.stale; // connected but never synced

  final age = now.difference(last);
  if (age <= const Duration(hours: 24)) return SyncStatus.connected;
  if (age <= const Duration(hours: 48)) return SyncStatus.stale;
  return SyncStatus.disconnected;
}

/// Aggregated per-provider status for the current user.
/// Keys: 'fitbit', 'oura', 'garmin', 'whoop', 'apple', 'googlefit'
final deviceStatusProvider = StreamProvider<Map<String, SyncStatus>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(const <String, SyncStatus>{});
  }

  const providers = <String>['fitbit', 'oura', 'garmin', 'whoop', 'apple', 'googlefit'];

  final controller = StreamController<Map<String, SyncStatus>>.broadcast();
  final subs = <StreamSubscription>[];

  final rows = <String, _ProviderLinkRow>{
    for (final p in providers) p: const _ProviderLinkRow(connected: false),
  };

  Map<String, SyncStatus> _emitSnapshot() {
    return {
      for (final p in providers) p: _toSyncStatus(rows[p]!),
    };
  }

  void emit() => controller.add(_emitSnapshot());

  for (final p in providers) {
    final sub = FirebaseFirestore.instance
        .doc('integrations/$p/users/$uid')
        .snapshots()
        .listen((snap) {
      rows[p] = _ProviderLinkRow.from(snap.data());
      emit();
    }, onError: (_) {
      // keep previous row; no throw
    });
    subs.add(sub);
  }

  // initial
  emit();

  ref.onDispose(() async {
    for (final s in subs) {
      await s.cancel();
    }
    await controller.close();
  });

  // Deduplicate emissions
  return controller.stream.distinct((a, b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  });
});

/// 🔄 Bootstrapper: on login/app start, ensure a 14-day backfill is requested at least once.
final syncBootstrapProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return;

  // Only run once per app session
  bool triggered = false;

  final sub = FirebaseFirestore.instance
      .doc('integrations/fitbit/users/$uid')
      .snapshots()
      .listen((snap) async {
    if (triggered) return;
    final data = snap.data() ?? {};
    final connected = data['connected'] == true;
    final lastBackfillAtUtc = (data['last_backfill_at_utc'] is Timestamp)
        ? (data['last_backfill_at_utc'] as Timestamp).toDate().toUtc()
        : null;

    // Heuristic: if connected but we've never backfilled (or field missing), request 14 days once.
    if (connected && lastBackfillAtUtc == null) {
      triggered = true;
      final ok = await ref.read(devicesServiceProvider).fitbitFetchNowFor(
        uid,
        days: 14,
        backfill: true,
        reason: 'bootstrap',
      );
      if (!ok && kDebugMode) {
        debugPrint('[SyncBootstrap] backfill request failed (ignored)');
      }
    }
  });

  ref.onDispose(() => sub.cancel());
});
