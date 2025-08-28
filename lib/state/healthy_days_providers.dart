import 'package:aevara/data/contracts/firestore_contracts_v1.dart' as Fx;
// lib/state/healthy_days_providers.dart
//
// Independent provider(s) for the Healthy Days component.
// This file intentionally does NOT import or reference the Vitality Gauge VM.
//
// Reads: users/{uid}/days/{YYYY-MM-DD}.healthy_days_30
// Added: per-day risk_index series for last 30 days (for chart rendering)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

String _todayKeyLocal() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Streams today's Healthy Days count (0–30). Returns null if missing.
final healthyDaysCountProvider = StreamProvider<int?>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield null;
    return;
  }

  final uid = user.uid;
  final todayKey = _todayKeyLocal();
  final docStream = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('days')
      .doc(todayKey)
      .snapshots();

  await for (final snap in docStream) {
    final data = snap.data();
    if (data == null) {
      yield null;
      continue;
    }
    final num? raw = data['healthy_days_30'] as num?;
    yield raw?.toInt();
  }
});

/// Fetches the last 30 days of `risk_index` values (oldest → newest).
/// Returns a list of nullable doubles (0–1). Null = missing that day.
/// This powers the dynamic Healthy Days mini bar chart.
final healthyDaysRiskSeriesProvider =
FutureProvider<List<double?>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final uid = user.uid;

  // Build the last-30 date keys (local time).
  final now = DateTime.now();
  final keys = List.generate(
    30,
        (i) => DateFormat('yyyy-MM-dd')
        .format(now.subtract(Duration(days: 29 - i))),
  );

  final col = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('days');

  // Query docs in the window.
  final snap = await col
      .orderBy(FieldPath.documentId)
      .startAt([keys.first])
      .endAt([keys.last])
      .get();

  // Map by ID for alignment.
  final byId = {
    for (final d in snap.docs) d.id: d.data(),
  };

  // Align to 30 slots (oldest → newest).
  return keys.map((k) {
    final data = byId[k];
    if (data == null) return null;
    final num? r = data['risk_index'] as num?;
    return r != null ? r.toDouble().clamp(0.0, 1.0) : null;
  }).toList();
});


