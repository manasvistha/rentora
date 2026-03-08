import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations._(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const Locale fallbackLocale = Locale('en');
  static const List<Locale> supportedLocales = [Locale('en'), Locale('ne')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String tr(String key) => _strings[key] ?? key;

  static Future<AppLocalizations> load(Locale locale) async {
    final languageCode =
        supportedLocales.any(
          (supported) => supported.languageCode == locale.languageCode,
        )
        ? locale.languageCode
        : fallbackLocale.languageCode;

    Intl.defaultLocale = Intl.canonicalizedLocale(languageCode);

    final jsonString = await rootBundle.loadString(
      'assets/translations/$languageCode.json',
    );
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    final strings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return AppLocalizations._(locale, strings);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key) => l10n.tr(key);
}
