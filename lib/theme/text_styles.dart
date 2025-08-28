// lib/theme/text_styles.dart
// Inter-based text styles with exact sizes/weights from the design system.
// Important: Tiles show values using titleMedium (weight: Medium).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AevaraText {
  // Font weights per spec: semibold (600), medium (500), regular (400)
  static const _wReg = FontWeight.w400;
  static const _wMed = FontWeight.w500;
  static const _wSmb = FontWeight.w600;

  /// Build a Material TextTheme tuned for Aevara, using Inter.
  /// - H1: 28/34 semibold
  /// - H2: 22/28 semibold
  /// - H3: 18/24 medium
  /// - Body: 15/22 regular
  /// - Label: 13/18 medium
  /// - Caption: 12/16 regular
  /// - Tile values: titleMedium (medium)
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark(useMaterial3: true).textTheme
          : ThemeData.light(useMaterial3: true).textTheme,
    );

    // We map our spec to Material 3 roles while keeping named access predictable.
    return base.copyWith(
      // Display/Headline map to our larger headings for flexibility
      displaySmall: base.displaySmall
          ?.copyWith(fontSize: 28, height: 34 / 28, fontWeight: _wSmb),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontSize: 22, height: 28 / 22, fontWeight: _wSmb),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontSize: 18, height: 24 / 18, fontWeight: _wMed),

      // Titles (used widely in cards/tiles/toolbars)
      titleLarge: base.titleLarge
          ?.copyWith(fontSize: 22, height: 28 / 22, fontWeight: _wSmb),
      titleMedium: base.titleMedium?.copyWith(
          fontSize: 15, height: 22 / 15, fontWeight: _wMed), // TILE VALUES
      titleSmall: base.titleSmall
          ?.copyWith(fontSize: 13, height: 18 / 13, fontWeight: _wMed),

      // Body
      bodyLarge: base.bodyLarge
          ?.copyWith(fontSize: 15, height: 22 / 15, fontWeight: _wReg),
      bodyMedium: base.bodyMedium
          ?.copyWith(fontSize: 15, height: 22 / 15, fontWeight: _wReg),
      bodySmall: base.bodySmall
          ?.copyWith(fontSize: 12, height: 16 / 12, fontWeight: _wReg),

      // Labels (buttons/chips)
      labelLarge: base.labelLarge
          ?.copyWith(fontSize: 13, height: 18 / 13, fontWeight: _wMed),
      labelMedium: base.labelMedium
          ?.copyWith(fontSize: 12, height: 16 / 12, fontWeight: _wMed),
      labelSmall: base.labelSmall
          ?.copyWith(fontSize: 11, height: 14 / 11, fontWeight: _wMed),
    );
  }
}

/// Optional convenience getters so widgets can call context.text.h1 etc.
extension AevaraTextX on BuildContext {
  TextTheme get _tt => Theme.of(this).textTheme;

  TextStyle get h1 => _tt.displaySmall!; // 28/34 semibold
  TextStyle get h2 => _tt.headlineMedium!; // 22/28 semibold
  TextStyle get h3 => _tt.headlineSmall!; // 18/24 medium

  TextStyle get body => _tt.bodyLarge!; // 15/22 regular
  TextStyle get label =>
      _tt.titleSmall!; // 13/18 medium (used for compact labels)
  TextStyle get caption => _tt.bodySmall!; // 12/16 regular

  // Tile numeric value style (explicitly medium per design)
  TextStyle get tileValue => _tt.titleMedium!;
}
