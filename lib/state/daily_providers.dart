// lib/state/daily_providers.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Formats the *local* YYYY-MM-DD key (not UTC) for the user's current device.
@immutable
class TodayKey {
  final String value;
  const TodayKey(this.value);
  @override
  String toString() => value;

  static TodayKey nowLocal() {
    final now = DateTime.now();
    final yyyyMmDd = DateFormat('yyyy-MM-dd').format(now);
    return TodayKey(yyyyMmDd);
  }
}

/// Today’s local date key.
final todayKeyProvider = Provider<TodayKey>((ref) {
  return TodayKey.nowLocal();
});

/// Current user id (null if signed out).
final _uidProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Reference to today's doc: user_daily/{uid}/days/{YYYY-MM-DD}
final todayDocRefProvider = Provider<DocumentReference<Map<String, dynamic>>?>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return null;
  final key = ref.watch(todayKeyProvider).value;
  return FirebaseFirestore.instance
      .collection('user_daily')
      .doc(uid)
      .collection('days')
      .doc(key);
});

/// Stream of today’s daily doc (may be null if it doesn’t exist yet).
final dailyDocStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final docRef = ref.watch(todayDocRefProvider);
  if (docRef == null) return const Stream.empty();

  return docRef.snapshots().map((snap) => snap.data());
});

/// Small typed getters with defaults so UI doesn’t crash on nulls.
double _asDouble(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v == null) return double.nan;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse('$v') ?? double.nan;
}

int _asInt(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v == null) return -1;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse('$v') ?? -1;
}

/// Convenience view for the common dashboard fields.
class DailyView {
  final double vitalityAge;       // NaN if absent
  final double healthyDays30;     // NaN if absent
  final double riskIndex;         // NaN if absent (0..1)
  final double hrvRmssdMs;        // NaN if absent
  final double sleepHours;        // NaN if absent
  final int steps;                // -1 if absent
  const DailyView({
    required this.vitalityAge,
    required this.healthyDays30,
    required this.riskIndex,
    required this.hrvRmssdMs,
    required this.sleepHours,
    required this.steps,
  });
}

final dailyViewProvider = Provider<AsyncValue<DailyView>>((ref) {
  final asyncDoc = ref.watch(dailyDocStreamProvider);
  return asyncDoc.whenData((data) {
    final m = data ?? const <String, dynamic>{};
    return DailyView(
      vitalityAge: _asDouble(m, 'vitality_age'),
      healthyDays30: _asDouble(m, 'healthy_days_30'),
      riskIndex: _asDouble(m, 'risk_index'),
      hrvRmssdMs: _asDouble(m, 'hrv_rmssd_ms'),
      sleepHours: _asDouble(m, 'sleep_total_hours'),
      steps: _asInt(m, 'steps_count'),
    );
  });
});
