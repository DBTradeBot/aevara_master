// lib/features/onboarding/onboarding_next.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../routing/route_paths.dart';

/// Decide where to send the user after auth based on their profile doc.
Future<String> nextRouteAfterAuth(String uid, FirebaseFirestore db) async {
  final snap = await db.collection('user_profiles').doc(uid).get();
  final m = snap.data() ?? const <String, dynamic>{};

  final hasUsername = (m['username'] ?? '').toString().isNotEmpty;
  final hasDob = m['dob'] != null;
  final hasGender = m['gender'] != null;
  final hasMetric = m['height_cm'] != null || m['weight_kg'] != null;

  final route = (!hasDob || !hasGender || !hasMetric)
      ? RoutePaths.demographics
      : (!hasUsername ? RoutePaths.identity : RoutePaths.home);

  debugPrint('🧭 nextRouteAfterAuth '
      'uid=$uid exists=${snap.exists} '
      'username=$hasUsername dob=$hasDob gender=$hasGender metric=$hasMetric '
      '→ $route');

  return route;
}
