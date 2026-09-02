// lib/state/daily_providers.dart
//
// Gauges VM sourced from today's *live* day doc, with a graceful fallback.
// - Switches to a StreamProvider so updates from compute() auto-propagate.
// - Fallback order when today's vitality_age is missing:
//     1) display.last_known_vitality_age on today's doc (if present)
//     2) most recent past day (last ~30 docs) with a finite vitality_age
//   When using a fallback, vm.isStale == true.
//
// Also exposes vitalityHistoryProvider (unchanged API) for the info sheet.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'user_providers.dart' as user_state;
import 'package:aevara_app/data/contracts/firestore_contracts_v1.dart' as Fx;
import 'package:aevara_app/charts/delta_bar.dart' show VitalityPoint;

/// yyyy-MM-dd in LOCAL time
String _todayKeyLocal() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Reference to a day doc (users/{uid}/days/{yyyy-MM-dd})
DocumentReference<Map<String, dynamic>> _dayRef(String uid, String key) {
  final path = Fx.FirestorePathsV1.dayDoc(uid, key);
  return FirebaseFirestore.instance.doc(path);
}

/// Helper: read the user profile to compute chronological age on a given date.
Future<double?> _readChronoAgeForDay(String uid, String dateKey) async {
  try {
    final snap = await FirebaseFirestore.instance.doc('users/$uid').get();
    if (!snap.exists) return null;
    final d = snap.data() ?? {};

    DateTime? dob;
    final raw = d['dob_iso'] ?? d['dob'] ?? d['birthdate_iso'] ?? d['birthdate'];
    if (raw is Timestamp) {
      dob = raw.toDate();
    } else if (raw is String && raw.isNotEmpty) {
      final t = DateTime.tryParse(raw);
      if (t != null) dob = t;
    }
    if (dob == null) return null;

    final parts = dateKey.split('-').map(int.parse).toList();
    final onDay = DateTime(parts[0], parts[1], parts[2]);
    final years = (onDay.millisecondsSinceEpoch -
        DateTime(dob.year, dob.month, dob.day).millisecondsSinceEpoch) /
        (365.2425 * 24 * 3600 * 1000);
    return double.parse(years.toStringAsFixed(2));
  } catch (_) {
    return null;
  }
}

class VitalityGaugeVM {
  final bool hasVitality;         // true when we have a number to show
  final bool isStale;             // true when value comes from fallback (not today)
  final bool showTodayScore;      // kept for API parity with existing gauge
  final double vitalityAge;       // value we’ll display (today or fallback)
  final double chronoAge;         // chronological age (for delta)
  final Map<String, int>? scores;
  final Map<String, double>? weightsUsed;
  final Map<String, int>? staleDays;
  final int? confidence;
  final Map<String, num>? constants;
  final String? sourceKey;        // 'YYYY-MM-DD' of the value we’re showing

  VitalityGaugeVM({
    required this.hasVitality,
    required this.isStale,
    required this.showTodayScore,
    required this.vitalityAge,
    required this.chronoAge,
    this.scores,
    this.weightsUsed,
    this.staleDays,
    this.confidence,
    this.constants,
    this.sourceKey,
  });
}

/// Live VM for the Vitality gauge (reacts to Firestore updates).
final vitalityGaugeVMProvider = StreamProvider<VitalityGaugeVM>((ref) async* {
  final uid = ref.watch(user_state.currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    yield VitalityGaugeVM(
      hasVitality: false,
      isStale: false,
      showTodayScore: false,
      vitalityAge: double.nan,
      chronoAge: double.nan,
    );
    return;
  }

  final todayKey = _todayKeyLocal();
  final todayStream = _dayRef(uid, todayKey).snapshots();

  await for (final snap in todayStream) {
    final data = (snap.data() ?? {});
    // 1) Try today's vitality_age
    double? vAgeToday =
    (data['vitality_age'] is num) ? (data['vitality_age'] as num).toDouble() : null;

    // 2) Optional quick fallback: a value the server may stash for us
    double? lastKnownToday;
    final display = (data['display'] is Map)
        ? Map<String, dynamic>.from(data['display'] as Map)
        : const {};
    if (display['last_known_vitality_age'] is num) {
      lastKnownToday =
          (display['last_known_vitality_age'] as num).toDouble();
    }

    String? sourceKey = todayKey;
    bool isStale = false;
    double? vAge = vAgeToday;

    // 3) If still missing, scan recent past docs (newest-first) for a finite value.
    if (vAge == null || !vAge.isFinite) {
      vAge = lastKnownToday;
      if (vAge != null && vAge.isFinite) {
        isStale = true;
      } else {
        // Look back ~30 docs max; cheap and safe for dashboard.
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('days');
        final qs = await col
            .orderBy(FieldPath.documentId, descending: true)
            .limit(31)
            .get();
        for (final d in qs.docs) {
          if (d.id == todayKey) continue;
          final m = d.data();
          final val =
          (m['vitality_age'] is num) ? (m['vitality_age'] as num).toDouble() : null;
          if (val != null && val.isFinite) {
            vAge = val;
            sourceKey = d.id;
            isStale = true;
            break;
          }
        }
      }
    }

    // Confidence
    final conf =
    (data['score_confidence'] is num) ? (data['score_confidence'] as num).toInt() : null;

    // Optional legacy per-domain scores
    Map<String, int>? scores;
    if (data['score'] is Map) {
      final m = Map<String, dynamic>.from(data['score'] as Map);
      scores = {
        if (m['recovery'] is num) 'recovery': (m['recovery'] as num).toInt(),
        if (m['sleep'] is num) 'sleep': (m['sleep'] as num).toInt(),
        if (m['activity'] is num) 'activity': (m['activity'] as num).toInt(),
        if (m['affect'] is num) 'affect': (m['affect'] as num).toInt(),
      };
    }

    // Weights used
    Map<String, double>? weightsUsed;
    if (data['drivers_contrib'] is Map) {
      final dc = Map<String, dynamic>.from(data['drivers_contrib'] as Map);
      double? _w(String k) {
        final v = dc[k];
        if (v is Map && v['weight'] is num) return (v['weight'] as num).toDouble();
        return null;
      }

      weightsUsed = {
        if (_w('recovery') != null) 'recovery': _w('recovery')!,
        if (_w('sleep') != null) 'sleep': _w('sleep')!,
        if (_w('activity') != null) 'activity': _w('activity')!,
        if (_w('affect') != null) 'affect': _w('affect')!,
      };
      if (weightsUsed.isEmpty) weightsUsed = null;
    }

    // Constants
    Map<String, num>? constants;
    if (data['constants'] is Map) {
      final c = Map<String, dynamic>.from(data['constants'] as Map);
      constants = {
        if (c['pivot_risk'] is num) 'pivot_risk': c['pivot_risk'] as num,
        if (c['scale_years'] is num) 'scale_years': c['scale_years'] as num,
      };
      if (constants.isEmpty) constants = null;
    }

    // Chronological age computed for whichever day we're displaying
    final chronoAge =
        await _readChronoAgeForDay(uid, sourceKey ?? todayKey) ?? double.nan;

    if (vAge != null && vAge.isFinite) {
      yield VitalityGaugeVM(
        hasVitality: true,
        isStale: isStale,
        showTodayScore: true, // keep the gauge live when we have any value
        vitalityAge: vAge,
        chronoAge: chronoAge,
        scores: scores,
        weightsUsed: weightsUsed,
        staleDays: null,
        confidence: conf,
        constants: constants,
        sourceKey: sourceKey,
      );
    } else {
      yield VitalityGaugeVM(
        hasVitality: false,
        isStale: false,
        showTodayScore: false,
        vitalityAge: double.nan,
        chronoAge: chronoAge,
        scores: scores,
        weightsUsed: weightsUsed,
        staleDays: null,
        confidence: conf,
        constants: constants,
        sourceKey: null,
      );
    }
  }
});

/// Convenience: history points for the info sheet (vitality & chrono) over N days.
final vitalityHistoryProvider =
FutureProvider.family<List<VitalityPoint>, int>((ref, days) async {
  final uid = ref.watch(user_state.currentUserIdProvider);
  if (uid == null || uid.isEmpty) return const [];

  final col =
  FirebaseFirestore.instance.collection('users').doc(uid).collection('days');

  // order by doc ID is safe here (YYYY-MM-DD)
  final snap = await col.orderBy(FieldPath.documentId).limitToLast(days).get();

  // Approximate chrono as the value on the most recent day in range
  double? lastChrono;
  if (snap.docs.isNotEmpty) {
    lastChrono = await _readChronoAgeForDay(uid, snap.docs.last.id);
  }

  final out = <VitalityPoint>[];
  for (final d in snap.docs) {
    final data = d.data();
    final key = d.id; // yyyy-MM-dd
    final parts = key.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);

    final vAge =
    (data['vitality_age'] is num) ? (data['vitality_age'] as num).toDouble() : double.nan;

    out.add(VitalityPoint(
      date: date,
      vitalityAge: vAge.isFinite ? double.parse(vAge.toStringAsFixed(1)) : double.nan,
      chronoAge: (lastChrono ?? double.nan),
    ));
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
});
