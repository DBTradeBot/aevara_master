import 'package:flutter/material.dart';

ThemeData _base(Color seed, Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 68,
    ),
  );
}

class AeTheme {
  static ThemeData light() => _base(const Color(0xFF00FFD1), Brightness.light);
  static ThemeData dark()  => _base(const Color(0xFF00FFD1), Brightness.dark);
}
