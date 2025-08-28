// lib/theme/aevara_theme.dart
// Wraps color tokens + text styles into a cohesive ThemeData (M3).
// Version-safe: ColorScheme.fromSeed; NavigationBarTheme uses withValues(alpha:…).

import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'text_styles.dart';

class AevaraTheme {
  static const double radiusTile = 12;
  static const double radiusCard = 16;
  static const double radiusSheet = 24;

  // ---------- LIGHT ----------
  static ThemeData light() {
    const c = AevaraLightColors();
    final text = AevaraText.textTheme(Brightness.light);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: text,
      iconTheme: IconThemeData(color: c.textPrimary),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        titleTextStyle: text.titleLarge?.copyWith(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: const EdgeInsets.all(0),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.10),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          final base = text.labelLarge!;
          return sel
              ? base.copyWith(color: colorScheme.primary)
              : base.copyWith(color: c.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
              color: sel ? colorScheme.primary : c.textSecondary);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: c.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
        labelStyle: text.labelLarge?.copyWith(color: c.textSecondary),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.outline),
        ),
        backgroundColor: c.surfaceAlt,
        selectedColor: colorScheme.primary.withValues(alpha: 0.12),
        labelStyle: text.labelLarge!,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: c.onPrimary,
          textStyle: text.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(44, 44),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.secondary,
          foregroundColor: c.onSecondary,
          textStyle: text.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(44, 44),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        iconColor: c.textSecondary,
        titleTextStyle: text.bodyLarge?.copyWith(color: c.textPrimary),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: text.bodySmall?.copyWith(color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ---------- DARK ----------
  static ThemeData dark() {
    const c = AevaraDarkColors();
    final text = AevaraText.textTheme(Brightness.dark);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: text,
      iconTheme: IconThemeData(color: c.textPrimary),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        titleTextStyle: text.titleLarge?.copyWith(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: const EdgeInsets.all(0),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          final base = text.labelLarge!;
          return sel
              ? base.copyWith(color: colorScheme.primary)
              : base.copyWith(color: c.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
              color: sel ? colorScheme.primary : c.textSecondary);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: c.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
        labelStyle: text.labelLarge?.copyWith(color: c.textSecondary),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.outline),
        ),
        backgroundColor: c.surfaceAlt,
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        labelStyle: text.labelLarge!,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: c.onPrimary,
          textStyle: text.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(44, 44),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.secondary,
          foregroundColor: c.onSecondary,
          textStyle: text.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(44, 44),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        iconColor: c.textSecondary,
        titleTextStyle: text.bodyLarge?.copyWith(color: c.textPrimary),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: text.bodySmall?.copyWith(color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
