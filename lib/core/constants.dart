// lib/core/constants.dart
//
// Global constants for Aevara app.

class AppConstants {
  AppConstants._();

  static const String appName = 'Aevara';

  // Timeouts
  static const int defaultRequestTimeoutMs = 15000;

  // Vitality Age rules
  static const int minInputsForManual = 4; // sleep, steps, hrv, rhr + wellbeing
}
