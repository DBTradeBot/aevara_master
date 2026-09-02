// lib/theme/color_tokens.dart
// Aevara color tokens (Light + Dark) with semantic aliases.
// Source of truth: docs/4_design_system.md

import 'package:flutter/material.dart';

/// Base palette (hex from the design system)
class AevaraBaseColors {
  // Brand
  static const primary = Color(0xFF3F87A6); // Calm Azure
  static const secondary = Color(0xFFA3BFA8); // Soft Sage
  static const tertiary = Color(0xFFEDE6D6); // Warm Beige

  // Light text/background
  static const textPrimaryLight = Color(0xFF1B1B1B);
  static const textSecondaryLight = Color(0xFF575C6C);
  static const backgroundLight = Color(0xFFFDFCF9); // Ivory Tint (main background)
  static const backgroundAltLight = Color(0xFFF5F7F9); // Cloud Gray (cards/surfaces)

  // Dark text/background
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFC8CCD4);
  static const backgroundDark = Color(0xFF1B263B); // Indigo Slate
  static const backgroundAltDark = Color(0xFF141B1F); // Near Black (kept)

  // Accents (shared)
  static const accent1 = Color(0xFF3B91A3); // Pacific Mist
  static const accent2 = Color(0xFF4AAFA9); // Sea Teal
  static const accent3 = Color(0xFFB57B65); // Terracotta Clay
  static const accent4 = Color(0xFFFFFFFF); // White

  // Semantic (Light)
  static const success = Color(0xFF24A699);
  static const error = Color(0xFFBF4A4A);
  static const warning = Color(0xFFF6B56B);
  static const info = Color(0xFF3B91A3);

  // Semantic (Dark)
  static const successDark = Color(0xFF29C1B2);
  static const errorDark = Color(0xFFE46B6B);
  static const warningDark = Color(0xFFFFC069);
  static const infoDark = Color(0xFF66C2B8);

  // Utility
  static const strokeLight = Color(0xFFE0E3E7);
  static const strokeDark = Color(0xFF2B3A40);
  static const overlayBlack12 = Color(0x1F000000);
}

/// Semantic tokens for Light theme
class AevaraLightColors {
  final Color primary = AevaraBaseColors.primary;
  final Color onPrimary = Colors.white;

  final Color secondary = AevaraBaseColors.secondary;
  final Color onSecondary = AevaraBaseColors.textPrimaryLight;

  final Color tertiary = AevaraBaseColors.tertiary;
  final Color onTertiary = AevaraBaseColors.textPrimaryLight;

  final Color background = AevaraBaseColors.backgroundLight;
  final Color surface = AevaraBaseColors.backgroundLight;
  final Color surfaceAlt = AevaraBaseColors.backgroundAltLight;

  final Color textPrimary = AevaraBaseColors.textPrimaryLight;
  final Color textSecondary = AevaraBaseColors.textSecondaryLight;

  // Precomputed alpha: 0x61 ≈ 38%
  final Color disabled = const Color(0x61575C6C);

  final Color divider = AevaraBaseColors.strokeLight;
  final Color outline = AevaraBaseColors.strokeLight;

  final Color success = AevaraBaseColors.success;
  final Color error = AevaraBaseColors.error;
  final Color warning = AevaraBaseColors.warning;
  final Color info = AevaraBaseColors.info;

  final Color accent1 = AevaraBaseColors.accent1;
  final Color accent2 = AevaraBaseColors.accent2;
  final Color accent3 = AevaraBaseColors.accent3;

  const AevaraLightColors();
}

/// Semantic tokens for Dark theme
class AevaraDarkColors {
  final Color primary = AevaraBaseColors.primary;
  final Color onPrimary = Colors.white;

  final Color secondary = AevaraBaseColors.secondary;
  final Color onSecondary = AevaraBaseColors.textPrimaryDark;

  final Color tertiary = AevaraBaseColors.tertiary;
  final Color onTertiary = AevaraBaseColors.textPrimaryDark;

  final Color background = AevaraBaseColors.backgroundDark;
  final Color surface = AevaraBaseColors.backgroundDark;
  final Color surfaceAlt = AevaraBaseColors.backgroundAltDark;

  final Color textPrimary = AevaraBaseColors.textPrimaryDark;
  final Color textSecondary = AevaraBaseColors.textSecondaryDark;

  // Precomputed alpha: 0x66 ≈ 40%
  final Color disabled = const Color(0x66C8CCD4);

  final Color divider = AevaraBaseColors.strokeDark;
  final Color outline = AevaraBaseColors.strokeDark;

  final Color success = AevaraBaseColors.successDark;
  final Color error = AevaraBaseColors.errorDark;
  final Color warning = AevaraBaseColors.warningDark;
  final Color info = AevaraBaseColors.infoDark;

  final Color accent1 = AevaraBaseColors.accent1;
  final Color accent2 = AevaraBaseColors.accent2;
  final Color accent3 = AevaraBaseColors.accent3;

  const AevaraDarkColors();
}
