import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'theme_mode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    if (value == 'light') state = ThemeMode.light;
    if (value == 'dark') state = ThemeMode.dark;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeKey, state == ThemeMode.dark ? 'dark' : 'light');
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (_) => ThemeNotifier(),
);
