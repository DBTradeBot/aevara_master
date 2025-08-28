import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final s = _prefs!.getString('theme_mode');
    final loaded = _fromString(s) ?? ThemeMode.system;
    if (mounted) state = loaded;
  }

  Future<void> setThemeMode(ThemeMode m) async {
    state = m;
    final p = _prefs ??= await SharedPreferences.getInstance();
    await p.setString('theme_mode', _toString(m));
  }

  static String _toString(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : (m == ThemeMode.light ? 'light' : 'system');

  static ThemeMode? _fromString(String? s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
    }
    return null;
  }
}
