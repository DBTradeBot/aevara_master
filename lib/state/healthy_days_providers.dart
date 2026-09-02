// lib/state/healthy_days_providers.dart
//
// Healthy Days mini-bar sources directly from the last 30 day docs under
// users/{uid}/days, reading `risk_index` and `healthy_day` that the compute writes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/user_providers.dart' as user_state;

/// Count of healthy days over last 30 (boolean field healthy_day).
final healthyDaysCountProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(user_state.currentUserIdProvider);
  if (uid == null || uid.isEmpty) return 0;

  final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('days');

  final snap = await col.orderBy(FieldPath.documentId).limitToLast(30).get();

  int count = 0;
  for (final doc in snap.docs) {
    final d = doc.data();
    final hd = d['healthy_day'];
    if (hd == true) count++;
  }
  return count;
});

/// Last-30 series of risk_index (0..1). `null` means missing.
final healthyDaysRiskSeriesProvider = FutureProvider<List<double?>?>((ref) async {
  final uid = ref.watch(user_state.currentUserIdProvider);
  if (uid == null || uid.isEmpty) return const <double?>[];

  final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('days');

  final snap = await col.orderBy(FieldPath.documentId).limitToLast(30).get();

  final out = <double?>[];
  for (final doc in snap.docs) {
    final d = doc.data();
    if (d.containsKey('risk_index') && d['risk_index'] is num) {
      out.add((d['risk_index'] as num).toDouble());
    } else {
      out.add(null);
    }
  }
  return out;
});
