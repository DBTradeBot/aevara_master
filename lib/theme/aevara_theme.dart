import 'package:flutter/material.dart';

@immutable
class AevaraTheme extends ThemeExtension<AevaraTheme> {
  // Brand
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color alternate;

  // Utility
  final Color textPrimary;
  final Color textSecondary;
  final Color bgPrimary;
  final Color bgSecondary;

  // Accent
  final Color accent1;
  final Color accent2;
  final Color accent3;
  final Color accent4;

  // Semantic
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  // Radii & shadows (as tokens)
  final double radiusTile;
  final double radiusCard;
  final double radiusSheet;

  const AevaraTheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.alternate,
    required this.textPrimary,
    required this.textSecondary,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.accent1,
    required this.accent2,
    required this.accent3,
    required this.accent4,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.radiusTile,
    required this.radiusCard,
    required this.radiusSheet,
  });

  factory AevaraTheme.light() => const AevaraTheme(
        primary: Color(0xFF3F87A6), // Calm Azure
        secondary: Color(0xFFA3BFA8), // Soft Sage
        tertiary: Color(0xFFEDE6D6), // Warm Beige
        alternate: Color(0xFFE0E3E7), // Soft Neutral Gray

        textPrimary: Color(0xFF1B1B1B),
        textSecondary: Color(0xFF575C6C),
        bgPrimary: Color(0xFFFFFFFF),
        bgSecondary: Color(0xFFF7F7F7),

        accent1: Color(0xFF3B91A3),  // Pacific Mist
        accent2: Color(0xFF4AAFA9),  // Sea Teal
        accent3: Color(0xFFB57B65),  // Terracotta Clay
        accent4: Color(0xFFFFFFFF),

        success: Color(0xFF24A699),
        error: Color(0xFFBF4A4A),
        warning: Color(0xFFF6B56B),
        info: Color(0xFF3B91A3),

        radiusTile: 12,
        radiusCard: 16,
        radiusSheet: 24,
      );

  factory AevaraTheme.dark() => const AevaraTheme(
        primary: Color(0xFF3F87A6),
        secondary: Color(0xFF92B6A3),
        tertiary: Color(0xFFEDE6D6),
        alternate: Color(0xFF2B3A40),

        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFC8CCD4),
        bgPrimary: Color(0xFF1A2428),
        bgSecondary: Color(0xFF141B1F),

        accent1: Color(0xFF4AAFA9),
        accent2: Color(0xFF66C2B8),
        accent3: Color(0xFFC89C85),
        accent4: Color(0xFF2B3A40),

        success: Color(0xFF29C1B2),
        error: Color(0xFFE46B6B),
        warning: Color(0xFFFFC069),
        info: Color(0xFF66C2B8),

        radiusTile: 12,
        radiusCard: 16,
        radiusSheet: 24,
      );

  @override
  AevaraTheme copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? alternate,
    Color? textPrimary,
    Color? textSecondary,
    Color? bgPrimary,
    Color? bgSecondary,
    Color? accent1,
    Color? accent2,
    Color? accent3,
    Color? accent4,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    double? radiusTile,
    double? radiusCard,
    double? radiusSheet,
  }) => AevaraTheme(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
        alternate: alternate ?? this.alternate,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        bgPrimary: bgPrimary ?? this.bgPrimary,
        bgSecondary: bgSecondary ?? this.bgSecondary,
        accent1: accent1 ?? this.accent1,
        accent2: accent2 ?? this.accent2,
        accent3: accent3 ?? this.accent3,
        accent4: accent4 ?? this.accent4,
        success: success ?? this.success,
        error: error ?? this.error,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        radiusTile: radiusTile ?? this.radiusTile,
        radiusCard: radiusCard ?? this.radiusCard,
        radiusSheet: radiusSheet ?? this.radiusSheet,
      );

  @override
  AevaraTheme lerp(ThemeExtension<AevaraTheme>? other, double t) {
    if (other is! AevaraTheme) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    double lerpD(double a, double b) => a + (b - a) * t;
    return AevaraTheme(
      primary: lerpC(primary, other.primary),
      secondary: lerpC(secondary, other.secondary),
      tertiary: lerpC(tertiary, other.tertiary),
      alternate: lerpC(alternate, other.alternate),
      textPrimary: lerpC(textPrimary, other.textPrimary),
      textSecondary: lerpC(textSecondary, other.textSecondary),
      bgPrimary: lerpC(bgPrimary, other.bgPrimary),
      bgSecondary: lerpC(bgSecondary, other.bgSecondary),
      accent1: lerpC(accent1, other.accent1),
      accent2: lerpC(accent2, other.accent2),
      accent3: lerpC(accent3, other.accent3),
      accent4: lerpC(accent4, other.accent4),
      success: lerpC(success, other.success),
      error: lerpC(error, other.error),
      warning: lerpC(warning, other.warning),
      info: lerpC(info, other.info),
      radiusTile: lerpD(radiusTile, other.radiusTile),
      radiusCard: lerpD(radiusCard, other.radiusCard),
      radiusSheet: lerpD(radiusSheet, other.radiusSheet),
    );
  }
}

ThemeData buildAevaraTheme(Brightness brightness) {
  final aev = brightness == Brightness.dark ? AevaraTheme.dark() : AevaraTheme.light();
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: aev.primary, brightness: brightness),
    scaffoldBackgroundColor: aev.bgPrimary,
  );
  return base.copyWith(
    extensions: [aev],
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: brightness == Brightness.dark ? aev.alternate.withOpacity(0.4) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      color: aev.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(0),
    ),
  );
}
