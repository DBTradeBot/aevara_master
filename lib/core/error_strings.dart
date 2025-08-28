// lib/core/error_strings.dart
//
// Central error string constants so we don’t scatter copy.

class ErrorStrings {
  ErrorStrings._();

  static const String unknown = 'Something went wrong';
  static const String notSignedIn = 'You must be signed in';
  static const String network = 'Network error — check your connection';
  static const String timeout = 'Request timed out';
  static const String unauthorized = 'Unauthorized — please sign in again';

  // Sync & vitality
  static const String waitingForSync = 'Waiting for your device to sync…';
  static const String waitingForManual = 'Add all today’s inputs to compute your score';
  static const String computing = 'Computing your Vitality Age…';
}
