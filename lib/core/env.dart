// Environment flags & endpoints for Vitality vNext.
// Pass values at runtime via --dart-define or --dart-define-from-file.
// Leave defaults empty in source to avoid accidentally calling legacy URLs.

/// Whether to use Firestore adapters (vs. mock).
const bool USE_FIRESTORE_ADAPTERS = true;

/// Public HTTPS endpoint: vendor coverage sweep (idempotent last 30d).
/// functions: ensureCoverageHttp (Cloud Run HTTPS URL)
const String? ENSURE_COVERAGE_URL = String.fromEnvironment(
  'ENSURE_COVERAGE_URL',
  defaultValue: '',
);

/// Public HTTPS endpoint: single-day vitality compute.
/// functions: vitalityComputeHttp (Cloud Run HTTPS URL)
const String? VITALITY_COMPUTE_URL = String.fromEnvironment(
  'VITALITY_COMPUTE_URL',
  defaultValue: '',
);

/// Public HTTPS endpoint: multi-day vitality compute/backfill.
/// functions: vitalityComputeRangeHttp (Cloud Run HTTPS URL)
const String? VITALITY_RANGE_URL = String.fromEnvironment(
  'VITALITY_RANGE_URL',
  defaultValue: '',
);

/// Optional HTTP fallback endpoint for on-demand Fitbit fetch (if you expose it).
const String? FITBIT_FETCH_URL = String.fromEnvironment(
  'FITBIT_FETCH_URL',
  defaultValue: '',
);

/// Optional shared secret to match server FITBIT_SYNC_SECRET.
/// App Check is also sent automatically by the client.
const String? SYNC_SHARED_SECRET = String.fromEnvironment(
  'SYNC_SHARED_SECRET',
  defaultValue: '',
);

// ───────────── Deprecated (fallback only)
@Deprecated('Use ENSURE_COVERAGE_URL instead')
const String? ENSURE_BASELINE_URL =
String.fromEnvironment('ENSURE_BASELINE_URL', defaultValue: '');
@Deprecated('Use VITALITY_COMPUTE_URL instead')
const String? COMPUTE_DAILY_URL =
String.fromEnvironment('COMPUTE_DAILY_URL', defaultValue: '');
@Deprecated('Use VITALITY_RANGE_URL instead')
const String? COMPUTE_RANGE_URL =
String.fromEnvironment('COMPUTE_RANGE_URL', defaultValue: '');
