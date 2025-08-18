import 'package:flutter/material.dart';
import 'text_styles.dart';

ThemeData buildAevaraTheme({required Brightness brightness}) {
  // Primary brand color (Calm Azure #3F87A6 from your ADA palette)
  const primary = Color(0xFF3F87A6);

  final base = ThemeData(
    brightness: brightness,
    colorSchemeSeed: primary,
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: buildTextStyles(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
