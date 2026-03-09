import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/services/storage/shared_prefs_service.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themePreferenceKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final stored = prefs.getString(_themePreferenceKey);
      switch (stored) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      // Keep app boot-safe even if provider override is temporarily unavailable.
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_themePreferenceKey, value);
    } catch (_) {
      // Ignore persistence error and keep in-memory theme active.
    }
  }

  // Used by ambient light automation; does not overwrite manual preference.
  void setThemeModeFromSensor(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
