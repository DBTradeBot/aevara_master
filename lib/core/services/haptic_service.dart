// lib/core/services/haptic_service.dart
// Simple wrapper for light haptics on button taps.

import 'package:flutter/services.dart';

class HapticService {
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
}
