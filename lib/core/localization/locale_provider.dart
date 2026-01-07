/// Locale Provider
///
/// Provider for managing app language (locale) with persistence.
/// Supports Spanish (default) and English.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// Extension to maintain backward compatibility during migration
/// and for legacy logic which relies on a boolean.
extension IsSpanishExtension on S {
  bool get isSpanish => localeName.startsWith('es');
}

/// Supported locales
class AppLocales {
  static const es = Locale('es', 'NI'); // Primary
  static const en = Locale('en', 'US');

  static const supportedLocales = [es, en];
}

/// Locale provider with persistence
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

/// Notifier for locale state
class LocaleNotifier extends StateNotifier<Locale?> {
  static const String _prefsKey = 'selected_locale';

  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefsKey);

    if (languageCode != null) {
      if (languageCode == 'en') {
        state = AppLocales.en;
      } else if (languageCode == 'es') {
        state = AppLocales.es;
      }
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();

    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      if (!AppLocales.supportedLocales.contains(locale)) return;
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }

  void toggleLocale() {
    if (state?.languageCode == 'es') {
      setLocale(AppLocales.en);
    } else {
      setLocale(AppLocales.es);
    }
  }
}
