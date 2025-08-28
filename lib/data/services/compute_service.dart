// lib/data/services/compute_service.dart
//
// Triggers the daily compute HTTP function (computeDailyHttp) for the current user.
// Safe no-op if COMPUTE_DAILY_URL is empty.
// Uses POST { userId, tz } and expects { ok:true } in response.
//
// Add dependency: `http`.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/env.dart';

/// Abstraction used by state/UI layers.
abstract class ComputeService {
  /// Ask backend to recompute today's aggregates for [uid].
  /// If [tz] is null, backend defaults (America/Los_Angeles) will apply.
  Future<bool> computeTodayFor(String uid, {String? tz});
}

class HttpComputeService implements ComputeService {
  final String? endpoint;

  const HttpComputeService({this.endpoint = COMPUTE_DAILY_URL});

  @override
  Future<bool> computeTodayFor(String uid, {String? tz}) async {
    final url = (endpoint ?? '').trim();
    if (url.isEmpty) {
      if (kDebugMode) {
        debugPrint('[ComputeService] COMPUTE_DAILY_URL empty — skipping HTTP compute.');
      }
      return false;
    }
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          if (tz != null && tz.isNotEmpty) 'tz': tz,
          // date_local optional; backend will pick "today in tz" if omitted
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>? ?? const {};
        final ok = body['ok'] == true;
        if (!ok && kDebugMode) {
          debugPrint('[ComputeService] computeDailyHttp responded not ok: ${resp.body}');
        }
        return ok;
      } else {
        if (kDebugMode) {
          debugPrint('[ComputeService] HTTP ${resp.statusCode}: ${resp.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ComputeService] error: $e');
      }
      return false;
    }
  }
}
