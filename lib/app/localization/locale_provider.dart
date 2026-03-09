import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/localization/app_localizations.dart';
import 'package:rentora/core/services/storage/shared_prefs_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const _localePreferenceKey = 'preferred_language_code';

  @override
  Locale build() {
    String? code;
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      code = prefs.getString(_localePreferenceKey);
    } catch (_) {
      // During hot-reload cycles, provider overrides can be temporarily stale.
      // Keep the app running with fallback locale instead of crashing.
      return AppLocalizations.fallbackLocale;
    }

    if (code == null || code.isEmpty) {
      return AppLocalizations.fallbackLocale;
    }

    final locale = Locale(code);
    final isSupported = AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );

    return isSupported ? locale : AppLocalizations.fallbackLocale;
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_localePreferenceKey, locale.languageCode);
    } catch (_) {
      // Ignore persistence failure and keep in-memory locale active.
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    await setLocale(Locale(languageCode));
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
