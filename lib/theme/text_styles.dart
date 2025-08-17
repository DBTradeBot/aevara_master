import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AevTextStyles {
  static TextTheme buildTextTheme(TextTheme base, Color colorPrimary, Color colorSecondary) {
    // Inter font across the board
    final t = GoogleFonts.interTextTheme(base).apply(
      bodyColor: colorPrimary,
      displayColor: colorPrimary,
    );

    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w600, height: 36/28),
      headlineMedium: t.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 30/22),
      headlineSmall: t.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 26/18),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 24/16),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 22/14),
      labelLarge: t.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: t.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}
