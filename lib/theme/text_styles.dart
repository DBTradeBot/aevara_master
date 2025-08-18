import 'package:flutter/material.dart';

TextTheme buildTextStyles(TextTheme base) {
  return base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
  );
}
