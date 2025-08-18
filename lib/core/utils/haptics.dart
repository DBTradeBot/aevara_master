import 'package:flutter/services.dart';

Future<void> tapLight() => HapticFeedback.lightImpact();
Future<void> tapMedium() => HapticFeedback.mediumImpact();
Future<void> tapSelect() => HapticFeedback.selectionClick();
