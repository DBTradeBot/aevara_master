import 'package:flutter/material.dart';
import 'aevara_theme.dart';

/// Only backfill missing fields on AevaraTheme. Do NOT define context.aevara here.
extension AevaraThemeMissingGetters on AevaraTheme {
  Color get success => const Color(0xFF2E7D32);
  Color get warning => const Color(0xFFF57C00);
  Color get secondaryText => Colors.black54;
  double get radius => 12.0;
}
