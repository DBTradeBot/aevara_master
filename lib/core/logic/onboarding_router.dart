// lib/core/logic/onboarding_router.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routing/route_paths.dart';

/// Light tolerance helpers for dates/ints
DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  if (v is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

int _ageYears(DateTime? d) {
  if (d == null) return -1;
  final now = DateTime.now();
  int years = now.year - d.year;
  final hadBirthday =
      (now.month > d.month) || (now.month == d.month && now.day >= d.day);
  if (!hadBirthday) years -= 1;
  return years;
}

/// Returns the next onboarding route if the user is not done, else null.
///
/// Required to finish onboarding:
///  - Email verified
///  - First name >= 2 chars
///  - DOB present and age >= 13
///  - Username present (non-empty)
///  - Consent accepted (onboarding.consent_done == true)
/// Connections are OPTIONAL: user may skip and still reach the dashboard.
///
/// Notes:
///  - We *don’t* rely on UserProfile.minComplete (legacy logic).
///  - We treat onboarding.completed (if present) as a cache; we can recompute.
String? computeNextOnboardingRoute({
  required User firebaseUser,
  required Map<String, dynamic>? profileData,
}) {
  // 1) Must be signed in (AuthGuard handles not-signed-in).
  // 2) Email verification
  if (!(firebaseUser.emailVerified)) {
    return RoutePaths.verify;
  }

  // Default-safe read
  final m = profileData ?? const <String, dynamic>{};

  final firstName = (m['first_name'] as String?)?.trim() ?? '';
  final dob = _asDate(m['dob']);
  final username = (m['username'] as String?)?.trim() ?? '';

  // Consent/bookkeeping
  final onboarding = (m['onboarding'] as Map<String, dynamic>?) ?? const {};
  final consentDone = onboarding['consent_done'] == true;
  // connect_done is NOT required to proceed per product decision.
  // final connectDone = onboarding['connect_done'] == true;

  // 3) Demographics required: first name (>=2) and DOB (13+)
  final firstOk = firstName.length >= 2;
  final dobOk = _ageYears(dob) >= 13;

  if (!firstOk || !dobOk) {
    return RoutePaths.demographics;
  }

  // 4) Identity (username required)
  if (username.isEmpty) {
    return RoutePaths.identity;
  }

  // 5) Consent required
  if (!consentDone) {
    return RoutePaths.consent;
  }

  // 6) Connections optional; allow skip -> proceed to home
  // If you wanted to *suggest* connect, route to RoutePaths.connect and
  // put a "Skip for now" button there that sets onboarding.connect_done=false + skipped=true.
  // But per your requirement, we do NOT block here.
  return null; // onboarding complete -> let user into the app shell/home
}
