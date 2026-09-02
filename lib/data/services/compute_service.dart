// lib/services/compute_service.dart
//
// Vitality Compute HTTP client with boot-bypass + explicit cooldown override.
// - Adds a 5-minute boot window where cooldowns are ignored once per key.
// - Accepts bypassCooldown=true on any call to force-send.
// - Attaches Firebase App Check and optional shared secret header.
// - Uses range endpoint when available, falls back to per-day loop.
//
// Env keys used (via ../../core/env.dart):
//   VITALITY_COMPUTE_URL, VITALITY_RANGE_URL, SYNC_SHARED_SECRET
//
// Safe defaults:
//   - Cooldowns remain for normal use to prevent spam.
//   - Boot-bypass only relaxes cooldown for the first few minutes after app start.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_app_check/firebase_app_check.dart';
import '../../core/env.dart' as env;

abstract class ComputeService {
  Future<bool> computeTodayFor(
      String uid, {
        String? tz,
        String? source,
        bool bypassCooldown = false,
      });

  Future<bool> computeYesterdayFor(
      String uid, {
        String? tz,
        String? source,
        bool bypassCooldown = false,
      });

  Future<bool> computeRangeFor(
      String uid, {
        required int days,
        String? tz,
        bool allowBackfill = false,
        String? source,
        bool bypassCooldown = false,
      });
}

class HttpComputeService implements ComputeService {
  final String? computeEndpoint;
  final String? rangeEndpoint;

  const HttpComputeService({
    this.computeEndpoint = env.VITALITY_COMPUTE_URL,
    this.rangeEndpoint = env.VITALITY_RANGE_URL,
  });

  // ---- Cooldown & boot-bypass state ----------------------------------------

  static final Set<String> _inFlight = <String>{};
  static final Map<String, DateTime> _cooldownUntil = <String, DateTime>{};

  static const Duration _cooldownToday = Duration(seconds: 20);
  static const Duration _cooldownYesterday = Duration(seconds: 10);

  // Boot bypass: first few minutes after app start; ignore cooldown once per key.
  static final DateTime _bootStartedAt = DateTime.now();
  static const Duration _bootBypassWindow = Duration(minutes: 5);
  static final Set<String> _bootBypassConsumed = <String>{};

  bool _isBootBypassActive() {
    final now = DateTime.now();
    return now.isBefore(_bootStartedAt.add(_bootBypassWindow));
  }

  // ---- URL helpers ----------------------------------------------------------

  Uri? _computeUri() {
    final url = (computeEndpoint ?? '').trim();
    return url.isEmpty ? null : Uri.parse(url);
  }

  Uri? _rangeUri() {
    final url = (rangeEndpoint ?? '').trim();
    return url.isEmpty ? null : Uri.parse(url);
  }

  // ---- Utils ----------------------------------------------------------------

  String _fmtDate(DateTime d) {
    String p2(int x) => x < 10 ? '0$x' : '$x';
    return '${d.year}-${p2(d.month)}-${p2(d.day)}';
  }

  bool _ok(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) return false;
    try {
      final body = (jsonDecode(resp.body) as Map?) ?? const {};
      final ok = body['ok'] == true;
      final skipped = body['skipped'] == true;
      return ok || skipped;
    } catch (_) {
      return false;
    }
  }

  bool _shouldSkipByCooldown(
      String key,
      Duration cooldown, {
        required bool bypassCooldown,
      }) {
    // Explicit bypass from caller
    if (bypassCooldown) return false;

    // Boot-time implicit bypass (once per key inside boot window)
    if (_isBootBypassActive() && !_bootBypassConsumed.contains(key)) {
      _bootBypassConsumed.add(key);
      if (kDebugMode) {
        debugPrint('[ComputeService] boot-bypass granted for $key');
      }
      return false;
    }

    final now = DateTime.now();
    final until = _cooldownUntil[key];
    if (until != null && now.isBefore(until)) {
      if (kDebugMode) {
        debugPrint('[ComputeService] skipped by cooldown ($key) until $until');
      }
      return true;
    }
    _cooldownUntil[key] = now.add(cooldown);
    return false;
  }

  Future<String?> _getAppCheckToken() async {
    try {
      final tok = await FirebaseAppCheck.instance.getToken();
      if (tok is String && tok.isNotEmpty) return tok;
    } catch (_) {}
    return null;
  }

  Map<String, String> _baseHeaders({bool withJson = true}) {
    final h = <String, String>{};
    if (withJson) h['Content-Type'] = 'application/json';
    return h;
  }

  Future<Map<String, String>> _headers({bool bypassCooldown = false}) async {
    final headers = _baseHeaders();
    final appCheck = await _getAppCheckToken();
    if (appCheck != null) headers['X-Firebase-AppCheck'] = appCheck;

    final secret = (env.SYNC_SHARED_SECRET ?? '').trim();
    if (secret.isNotEmpty) headers['x-sync-secret'] = secret;

    if (bypassCooldown) {
      headers['X-Bypass-Cooldown'] = 'true';
    }
    return headers;
  }

  Future<bool> _postSingleDay({
    required String uid,
    required String? dateKey,
    String? tz,
    String? source,
    required Duration cooldown,
    required bool bypassCooldown,
  }) async {
    final uri = _computeUri();
    if (uri == null) {
      if (kDebugMode) {
        debugPrint('[ComputeService] VITALITY_COMPUTE_URL empty — skipping HTTP compute.');
      }
      return false;
    }

    final key = '$uid:${dateKey ?? "today"}';

    if (_shouldSkipByCooldown(key, cooldown, bypassCooldown: bypassCooldown)) {
      return true; // treat as not-an-error; UI will still refresh via streams
    }

    if (_inFlight.contains(key)) {
      if (kDebugMode) debugPrint('[ComputeService] in-flight lock ($key), drop duplicate');
      return true;
    }
    _inFlight.add(key);

    try {
      final body = <String, dynamic>{
        'userId': uid,
        if (tz != null && tz.isNotEmpty) 'tz': tz,
        if (dateKey != null) 'date_local': dateKey,
        if (source != null && source.isNotEmpty) 'source': source,
      };

      final resp = await http.post(
        uri,
        headers: await _headers(bypassCooldown: bypassCooldown),
        body: jsonEncode(body),
      );

      final ok = _ok(resp);
      if (kDebugMode) {
        debugPrint(
          '[ComputeService] compute ${dateKey ?? "today"} '
              '-> ${ok ? "ok" : "fail"} (HTTP ${resp.statusCode})'
              '${source != null ? " source=$source" : ""}'
              '${bypassCooldown ? " [bypass]" : ""}',
        );
      }
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('[ComputeService] compute error: $e');
      return false;
    } finally {
      _inFlight.remove(key);
    }
  }

  @override
  Future<bool> computeTodayFor(
      String uid, {
        String? tz,
        String? source,
        bool bypassCooldown = false,
      }) {
    return _postSingleDay(
      uid: uid,
      dateKey: null,
      tz: tz,
      source: source,
      cooldown: _cooldownToday,
      bypassCooldown: bypassCooldown,
    );
  }

  @override
  Future<bool> computeYesterdayFor(
      String uid, {
        String? tz,
        String? source,
        bool bypassCooldown = false,
      }) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    final dateKey = _fmtDate(y);
    return _postSingleDay(
      uid: uid,
      dateKey: dateKey,
      tz: tz,
      source: source,
      cooldown: _cooldownYesterday,
      bypassCooldown: bypassCooldown,
    );
  }

  @override
  Future<bool> computeRangeFor(
      String uid, {
        required int days,
        String? tz,
        bool allowBackfill = false,
        String? source,
        bool bypassCooldown = false,
      }) async {
    if (!allowBackfill) {
      if (kDebugMode) {
        debugPrint('[ComputeService] range compute blocked (allowBackfill=false).'
            '${source != null ? " source=$source" : ""}');
      }
      return false;
    }

    final n = days.clamp(1, 90);

    // Try range endpoint first.
    final rUri = _rangeUri();
    if (rUri != null) {
      try {
        final body = <String, dynamic>{
          'userId': uid,
          'days': n,
          if (tz != null && tz.isNotEmpty) 'tz': tz,
          if (source != null && source.isNotEmpty) 'source': source,
          'force': true,
        };
        final resp = await http.post(
          rUri,
          headers: await _headers(bypassCooldown: bypassCooldown),
          body: jsonEncode(body),
        );
        final ok = _ok(resp);
        if (kDebugMode) {
          debugPrint(
            '[ComputeService] computeRange $n -> ${ok ? "ok" : "fail"} '
                '(HTTP ${resp.statusCode})'
                '${source != null ? " source=$source" : ""}'
                '${bypassCooldown ? " [bypass]" : ""}',
          );
        }
        if (ok) return true;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ComputeService] range endpoint error: $e (falling back)');
        }
      }
    }

    // Fallback: per-day loop, with cooldown disabled unless caller wants it.
    var allOk = true;
    for (int i = 0; i < n; i++) {
      final when = DateTime.now().subtract(Duration(days: i));
      final key = _fmtDate(when);
      final ok = await _postSingleDay(
        uid: uid,
        dateKey: key,
        tz: tz,
        source: source ?? 'backfill',
        cooldown: const Duration(seconds: 0),
        bypassCooldown: true, // force-send in fallback
      );
      if (!ok) allOk = false;
    }
    return allOk;
  }
}
