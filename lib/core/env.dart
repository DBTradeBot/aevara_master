// lib/core/env.dart
// Single place to configure environment flags and endpoints.
// This file is referenced by state/providers/services across the app.
//
// How to set from CLI (preferred):
//   flutter run --dart-define=COMPUTE_DAILY_URL=https://<region>-<project>.cloudfunctions.net/computeDailyHttp
//
// If not provided, COMPUTE_DAILY_URL will be null and compute will be skipped safely.

/// Whether to use Firestore adapters (vs. mock). Keep true in production builds.
const bool USE_FIRESTORE_ADAPTERS = true;

/// Public HTTPS endpoint of the compute function (computeDailyHttp).
/// Use a --dart-define at build/run time to set this without committing secrets.
const String? COMPUTE_DAILY_URL = const String.fromEnvironment('COMPUTE_DAILY_URL', defaultValue: '');
