import 'package:aevara/data/contracts/firestore_contracts_v1.dart' as Fx;
// lib/state/daily_providers.dart
//
// Daily state for dashboard widgets.
// VitalityGaugeVM + vitalityGaugeVMProvider + coachLineProvider.
//
// Reads:
// - user_profiles/{uid}.dob  (Timestamp OR ISO string "yyyy-MM-ddTHH:mm:ss.SSS")
// - users/{uid}/days/{YYYY-MM-DD}.* for vitality_age + transparency
//
// Behavior:
// - We NEVER show a faux number. Even if a vitality_age exists historically,
//   the UI only shows today's number when showTodayScore == true:
//     showTodayScore = ( (≥2 of {Sleep, Recovery, Activity} fresh today AND
//                         confidence >= threshold)
//                       OR manual input saved today )
// - Readiness gating: "waiting for sync", "waiting for manual inputs", or "computing…"
// - Delta/values rounded to 1 decimal for UI stability.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';

import '../copy/microcopy.dart';

// IMPORTANT: alias these to avoid name collisions.
import '../state/app_providers.dart' as app; // computeServiceProvider, authUserProvider, currentUserIdProvider
import '../state/user_providers.dart' as up; // currentUserProfileProvider (and also defines auth/currentUserId, but we won't use them here)

// NEW: chart point type for history provider
import '../charts/delta_bar.dart'; // VitalityPoint (date, vitalityAge, chronoAge)

enum GaugeState { younger, near, slightlyOlder, muchOlder }

class VitalityGaugeVM {
  final double vitalityAge; // e.g., 35.9
  final double chronoAge; // e.g., 33.2
  final double deltaHealthyYears; // + => younger than chrono
  final int confidence; // 0–100
  final GaugeState state;
  final bool calibrating; // show banner if true

  // Transparency (all optional; null when not present)
  final Map<String, int>? scores; // score.{recovery,sleep,activity,wellbeing[,crf]}
  final Map<String, double>? weightsUsed; // wused.*
  final Map<String, int>? staleDays; // stale_days.*
  final Map<String, num>? constants; // constants.{pivot_risk,scale_years,...}
  final int? healthyDays30; // healthy_days_30 (0..30)

  // UX robustness
  final bool hasVitality; // true when we have a real number in today's doc
  final bool showTodayScore; // gate to show number based on freshness/confidence/manual-today
  final String? statusMessage; // why we don't have a number yet / not showing

  // Readiness hints for the shell/app
  final bool hasAnyRawInputsToday; // any of {sleep, steps, hrv, rhr, wellbeing}
  final bool seenComputeToday; // computed_at_utc present today
  final String readyReason; // "synced" | "manual" | "unknown"

  const VitalityGaugeVM({
    required this.vitalityAge,
    required this.chronoAge,
    required this.deltaHealthyYears,
    required this.confidence,
    required this.state,
    required this.calibrating,
    required this.hasVitality,
    required this.showTodayScore,
    required this.statusMessage,
    this.scores,
    this.weightsUsed,
    this.staleDays,
    this.constants,
    this.healthyDays30,
    required this.hasAnyRawInputsToday,
    required this.seenComputeToday,
    required this.readyReason,
  });

  double get fraction => (chronoAge <= 0) ? 0 : (vitalityAge / chronoAge);

  List<Color> get gradient => const [
    Color(0xFFBF4A4A), // red
    Color(0xFFF6B56B), // amber
    Color(0xFF3F87A6), // azure
    Color(0xFF24A699), // teal
  ];

  Color get color {
    switch (state) {
      case GaugeState.younger:
        return const Color(0xFF24A699);
      case GaugeState.near:
        return const Color(0xFF3F87A6);
      case GaugeState.slightlyOlder:
        return const Color(0xFFF6B56B);
      case GaugeState.muchOlder:
        return const Color(0xFFBF4A4A);
    }
  }
}

// Private auth stream for this file
final _authUserProvider =
StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

String _todayKeyLocal() => DateFormat('yyyy-MM-dd').format(DateTime.now());

double _yearsBetween(DateTime from, DateTime to) =>
    to.difference(from).inDays / 365.2425;

DateTime? _parseDob(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String && raw.isNotEmpty) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd').parse(raw);
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}

Map<String, int>? _toIntMap(Map<String, dynamic>? m) {
  if (m == null) return null;
  final out = <String, int>{};
  m.forEach((k, v) {
    final n = (v as num?)?.toInt();
    if (n != null) out[k] = n;
  });
  return out.isEmpty ? null : out;
}

Map<String, double>? _toDoubleMap(Map<String, dynamic>? m) {
  if (m == null) return null;
  final out = <String, double>{};
  m.forEach((k, v) {
    final n = (v as num?)?.toDouble();
    if (n != null) out[k] = n;
  });
  return out.isEmpty ? null : out;
}

Map<String, num>? _toNumMap(Map<String, dynamic>? m) {
  if (m == null) return null;
  final out = <String, num>{};
  m.forEach((k, v) {
    if (v is num) out[k] = v;
  });
  return out.isEmpty ? null : out;
}

// Helper: any raw inputs today?
bool _hasAnyRawInputs(Map<String, dynamic> d) {
  const keys = [
    'sleep_total_hours',
    'steps_count',
    'hrv_rmssd_ms',
    'rhr_bpm',
    'wellbeing_level_1to5',
    // legacy fallbacks
    'mood_level_1to5',
    'stress_level_1to5',
    'energy_level_1to5',
  ];
  for (final k in keys) {
    if (d[k] != null) return true;
  }
  return false;
}

// Helper: did backend compute run today?
bool _hasComputeToday(Map<String, dynamic> d) {
  final s = (d['computed_at_utc'] as String? ?? '').trim();
  if (s.isEmpty) return false;
  final today = _todayKeyLocal();
  return s.startsWith(today);
}

// Group freshness helpers based on stale_days.{metric} == 0
bool _freshGroup(Map<String, int>? staleDays, List<String> metricKeys) {
  if (staleDays == null || staleDays.isEmpty) return false;
  var seenAny = false;
  var minVal = 1 << 30;
  for (final k in metricKeys) {
    final v = staleDays[k];
    if (v != null) {
      seenAny = true;
      if (v < minVal) minVal = v;
    }
  }
  if (!seenAny) return false;
  return minVal == 0;
}

int _groupsFreshCount(Map<String, int>? staleDays) {
  final sleepFresh =
  _freshGroup(staleDays, const ['sleep_total_hours', 'sleep_efficiency_pct']);
  final recoveryFresh =
  _freshGroup(staleDays, const ['hrv_rmssd_ms', 'rhr_bpm']);
  final activityFresh =
  _freshGroup(staleDays, const ['steps_count', 'mvpa_minutes']);
  return [sleepFresh, recoveryFresh, activityFresh].where((b) => b).length;
}

// Manual-today detection: any metric whose source == "manual" and has a value in today's doc.
bool _manualToday(Map<String, dynamic>? sources, Map<String, dynamic> data) {
  if (sources == null || sources.isEmpty) return false;
  for (final entry in sources.entries) {
    final key = entry.key;
    final src = (entry.value?.toString().toLowerCase() ?? '');
    if (src == 'manual' && data.containsKey(key) && data[key] != null) {
      return true;
    }
  }
  return false;
}

// Helper: status text when we don't (yet) show a value.
String _statusFor({
  required bool hasDob,
  required bool anyInputs,
  required bool computeRan,
  required bool vitalityPresent,
  required String readyReason,
  required int groupsFreshCount,
  required int confidence,
  required bool manualToday,
  required int confidenceThreshold,
}) {
  if (!hasDob) return 'Add your date of birth to compute Vitality Age';
  // If we already have a value but we're choosing not to show it (freshness or confidence),
  // explain precisely why.
  if (vitalityPresent) {
    if (manualToday && !computeRan) return 'Saved. Computing your Vitality Age…';
    if (groupsFreshCount < 2) {
      return 'Waiting for fresh data from at least 2 of 3: Sleep, Recovery, Activity';
    }
    if (confidence < confidenceThreshold) {
      return 'Confidence is low — refresh your sources or add today’s inputs';
    }
    return '';
  }

  // No present vitality_age in today doc yet.
  if (!anyInputs) {
    return readyReason == 'synced'
        ? 'Connect a wearable or add inputs to compute today’s Vitality Age'
        : 'Add inputs to compute today’s Vitality Age';
  }
  if (!computeRan) return 'Saved. Computing your Vitality Age…';
  return 'Computing your Vitality Age…';
}

/// Vitality Age gauge stream:
/// 1) Reads user_profiles/{uid}.dob (Timestamp or ISO string)
/// 2) Reads users/{uid}/days/{YYYY-MM-DD} for vitality_age, confidence, calibration + transparency maps
final vitalityGaugeVMProvider = StreamProvider<VitalityGaugeVM>((ref) async* {
  final user = await ref.watch(_authUserProvider.selectAsync((u) => u));
  if (user == null) {
    yield const VitalityGaugeVM(
      vitalityAge: 0,
      chronoAge: 0,
      deltaHealthyYears: 0,
      confidence: 0,
      state: GaugeState.near,
      calibrating: false,
      hasVitality: false,
      showTodayScore: false,
      statusMessage: 'Sign in to view Vitality Age',
      scores: null,
      weightsUsed: null,
      staleDays: null,
      constants: null,
      healthyDays30: null,
      hasAnyRawInputsToday: false,
      seenComputeToday: false,
      readyReason: 'unknown',
    );
    return;
  }

  final uid = user.uid;
  final db = FirebaseFirestore.instance;
  final todayKey = _todayKeyLocal();

  final profileStream = db.collection('user_profiles').doc(uid).snapshots();
  final dailyStream =
  db.collection(Fx.FirestorePathsV1.days(uid)).doc(todayKey).snapshots();

  const int kConfidenceThreshold = 60;

  await for (final both in StreamZip([profileStream, dailyStream])) {
    final profileSnap = both[0];
    final dailySnap = both[1];

    final profile = profileSnap.data();
    final DateTime? dob = _parseDob(profile?['dob']);
    final bool hasDob = dob != null;

    if (!hasDob) {
      yield const VitalityGaugeVM(
        vitalityAge: 0,
        chronoAge: 0,
        deltaHealthyYears: 0,
        confidence: 0,
        state: GaugeState.near,
        calibrating: false,
        hasVitality: false,
        showTodayScore: false,
        statusMessage: 'Add your date of birth to compute Vitality Age',
        scores: null,
        weightsUsed: null,
        staleDays: null,
        constants: null,
        healthyDays30: null,
        hasAnyRawInputsToday: false,
        seenComputeToday: false,
        readyReason: 'unknown',
      );
      continue;
    }

    final chronoAge = _yearsBetween(dob, DateTime.now());
    final data = dailySnap.data() ?? const <String, dynamic>{};

    // Readiness probes
    final bool anyInputs = _hasAnyRawInputs(data);
    final bool computeRanToday = _hasComputeToday(data);

    // "synced" vs "manual" transparency
    String readyReason = 'unknown';
    final src = (data['sources'] as Map?)?.cast<String, dynamic>();
    if (src != null && src.isNotEmpty) {
      readyReason =
      src.values.any((v) => (v?.toString().toLowerCase() ?? '') == 'manual') ? 'manual' : 'synced';
    } else {
      readyReason = anyInputs ? 'manual' : 'unknown';
    }

    // Read main fields
    final vitalityAgeRaw = (data['vitality_age'] as num?)?.toDouble();
    final double? vitalityAgeRounded =
    vitalityAgeRaw != null ? double.parse(vitalityAgeRaw.toStringAsFixed(1)) : null;

    final confidence = (data['score_confidence'] as num?)?.toInt() ?? 0;
    final calibrating = (data['calibration_status'] as String?) == 'running';

    // Transparency maps (optional)
    final scores = _toIntMap((data['score'] as Map?)?.cast<String, dynamic>());
    final weightsUsed = _toDoubleMap((data['wused'] as Map?)?.cast<String, dynamic>());
    final staleDays = _toIntMap((data['stale_days'] as Map?)?.cast<String, dynamic>());
    final constants = _toNumMap((data['constants'] as Map?)?.cast<String, dynamic>());
    final healthyDays30 = (data['healthy_days_30'] as num?)?.toInt();

    // Freshness gating
    final groupsFresh = _groupsFreshCount(staleDays);
    final bool enoughGroups = groupsFresh >= 2;
    final bool manualToday = _manualToday(src, data);
    final bool confidenceOK = confidence >= kConfidenceThreshold;
    final bool showTodayScore = (enoughGroups && confidenceOK) || manualToday;

    if (vitalityAgeRounded == null) {
      final status = _statusFor(
        hasDob: true,
        anyInputs: anyInputs,
        computeRan: computeRanToday,
        vitalityPresent: false,
        readyReason: readyReason,
        groupsFreshCount: groupsFresh,
        confidence: confidence,
        manualToday: manualToday,
        confidenceThreshold: kConfidenceThreshold,
      );
      yield VitalityGaugeVM(
        vitalityAge: double.parse(chronoAge.toStringAsFixed(1)), // draw neutral arc
        chronoAge: double.parse(chronoAge.toStringAsFixed(1)),
        deltaHealthyYears: 0,
        confidence: confidence,
        state: GaugeState.near,
        calibrating: calibrating,
        hasVitality: false,
        showTodayScore: showTodayScore,
        statusMessage: status,
        scores: scores,
        weightsUsed: weightsUsed,
        staleDays: staleDays,
        constants: constants,
        healthyDays30: healthyDays30,
        hasAnyRawInputsToday: anyInputs,
        seenComputeToday: computeRanToday,
        readyReason: readyReason,
      );
      continue;
    }

    final delta = chronoAge - vitalityAgeRounded;
    final GaugeState state;
    if (delta > 2.0) {
      state = GaugeState.younger;
    } else if (delta.abs() <= 2.0) {
      state = GaugeState.near;
    } else if (delta < -2.0 && delta >= -5.0) {
      state = GaugeState.slightlyOlder;
    } else {
      state = GaugeState.muchOlder;
    }

    // If we have a value but won't show it (gating false), explain why.
    String? status;
    if (!showTodayScore) {
      status = _statusFor(
        hasDob: true,
        anyInputs: anyInputs,
        computeRan: computeRanToday,
        vitalityPresent: true,
        readyReason: readyReason,
        groupsFreshCount: groupsFresh,
        confidence: confidence,
        manualToday: manualToday,
        confidenceThreshold: kConfidenceThreshold,
      );
    }

    yield VitalityGaugeVM(
      vitalityAge: vitalityAgeRounded,
      chronoAge: double.parse(chronoAge.toStringAsFixed(1)),
      deltaHealthyYears: double.parse(delta.toStringAsFixed(1)),
      confidence: confidence,
      state: state,
      calibrating: calibrating,
      hasVitality: true,
      showTodayScore: showTodayScore,
      statusMessage: status,
      scores: scores,
      weightsUsed: weightsUsed,
      staleDays: staleDays,
      constants: constants,
      healthyDays30: healthyDays30,
      hasAnyRawInputsToday: anyInputs,
      seenComputeToday: computeRanToday,
      readyReason: readyReason,
    );
  }
});

/// Coach line (greeting + summary + optional tail) for the speech bubble.
final coachLineProvider = Provider<String>((ref) {
  final vmAsync = ref.watch(vitalityGaugeVMProvider);

  // Use app.* for auth (to avoid collision) and up.* for profile.
  final auth = ref.watch(app.authUserProvider).value;
  final profile = ref.watch(up.currentUserProfileProvider).valueOrNull;

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String? _firstFromProfile(dynamic p) {
    if (p == null) return null;
    final cands = <String?>[
      p.firstName as String?,
      p.givenName as String?,
      p.name as String?,
      p.displayName as String?
    ];
    for (final c in cands) {
      final v = (c ?? '').trim();
      if (v.isNotEmpty) return _cap(v.split(RegExp(r'[ \\._-]+')).first);
    }
    return null;
  }

  String _firstFromAuth({required String? displayName, required String? email}) {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) return _cap(dn.split(RegExp(r'[ \\._-]+')).first);
    final em = (email ?? '').trim();
    if (em.contains('@')) {
      final local = em.split('@').first;
      final token = local.split(RegExp(r'[ \\._-]+')).first;
      if (token.isNotEmpty) return _cap(token);
    }
    return 'friend';
  }

  final name = _firstFromProfile(profile) ??
      _firstFromAuth(displayName: auth?.displayName, email: auth?.email);

  return vmAsync.maybeWhen(
    data: (vm) => CoachCopy.composeLine(
      name: name,
      now: DateTime.now(),
      hasVitality: vm.hasVitality && vm.showTodayScore, // reflect UI gate
      statusMessage: vm.statusMessage,
      deltaYears: vm.deltaHealthyYears,
      state: vm.state.name,
      confidence: vm.confidence,
      calibrating: vm.calibrating,
      healthyDays30: vm.healthyDays30,
      staleDays: vm.staleDays,
      uid: auth?.uid ?? 'anon',
    ),
    orElse: () => 'Hello, $name 👋',
  );
});

/// --- Auto-compute when inputs land but Vitality isn’t computed yet ---
/// This avoids forcing users to pull-to-refresh after manual entry.
final _autoComputeRunningProvider = StateProvider<bool>((_) => false);

final autoComputeKickProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<VitalityGaugeVM>>(vitalityGaugeVMProvider, (prev, next) async {
    final vm = next.valueOrNull;
    if (vm == null) return;

    // Trigger only when: inputs exist today, we haven't seen a compute, and no value yet.
    final shouldKick = vm.hasAnyRawInputsToday && !vm.seenComputeToday && !vm.hasVitality;
    final running = ref.read(_autoComputeRunningProvider);
    final uid = ref.read(app.currentUserIdProvider);

    if (shouldKick && !running && uid != null) {
      ref.read(_autoComputeRunningProvider.notifier).state = true;
      try {
        await ref.read(app.computeServiceProvider).computeTodayFor(uid);
      } finally {
        // Force streams to re-read the daily doc after compute.
        ref.invalidate(vitalityGaugeVMProvider);
        ref.read(_autoComputeRunningProvider.notifier).state = false;
      }
    }
  });
});

// -----------------------------------------------------------------------------
// NEW: Vitality history provider used by VitalityInfoSheet's chart (14/30/60/90)
// -----------------------------------------------------------------------------

/// Reads last [days] daily docs from users/{uid}/days (by doc id YYYY-MM-DD),
/// maps to VitalityPoint (vitality_age vs. derived chronological age per day),
/// and returns in ascending date order.
final vitalityHistoryProvider =
FutureProvider.family<List<VitalityPoint>, int>((ref, days) async {
  final uid = ref.watch(app.currentUserIdProvider);
  if (uid == null) return const [];

  final db = FirebaseFirestore.instance;

  // 1) Fetch DOB
  final profileSnap = await db.collection('user_profiles').doc(uid).get();
  final dob = _parseDob(profileSnap.data()?['dob']);
  if (dob == null) return const [];

  // 2) Query last N days by documentId (YYYY-MM-DD) descending
  final qs = await db
      .collection('users')
      .doc(uid)
      .collection('days')
      .orderBy(FieldPath.documentId, descending: true) // <-- FIXED: no ()
      .limit(days)
      .get();

  if (qs.docs.isEmpty) return const [];

  // 3) Map to VitalityPoint and sort ascending
  final pointsDesc = <VitalityPoint>[];
  for (final d in qs.docs) {
    final data = d.data();
    final va = (data['vitality_age'] as num?)?.toDouble();
    if (va == null) continue;

    final rawDate = (data['date_local'] as String?)?.trim();
    DateTime? date;
    try {
      date = (rawDate != null && rawDate.isNotEmpty) ? DateTime.parse(rawDate) : DateTime.parse(d.id);
    } catch (_) {
      date = null;
    }
    if (date == null) continue;

    final chrono = _yearsBetween(dob, date);
    pointsDesc.add(
      VitalityPoint(
        date: date,
        vitalityAge: double.parse(va.toStringAsFixed(1)),
        chronoAge: double.parse(chrono.toStringAsFixed(1)),
      ),
    );
  }

  if (pointsDesc.isEmpty) return const [];

  return pointsDesc.reversed.toList(growable: false);
});


