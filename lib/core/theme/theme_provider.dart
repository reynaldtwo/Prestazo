/// Theme Provider
///
/// Riverpod provider for managing app theme mode (dark/light/system).
/// Persists theme preference to local storage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode key for storage
const String _themeModeKey = 'theme_mode';

/// Theme mode provider with persistence
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

/// Notifier for theme mode state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  /// Crea un [ThemeModeNotifier] e inicializa la carga del modo de tema persistido.
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey);
      if (modeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.name == modeString,
          orElse: () => ThemeMode.system,
        );
      }
    } on Exception catch (_) {
      state = ThemeMode.system;
    }
  }

  /// Set and persist theme mode
  /// Cambia el modo de tema actual y lo persiste en las preferencias del usuario.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } on Exception catch (_) {
      // Ignore storage errors
    }
  }

  /// Toggle between light and dark (ignores system)
  /// Alterna entre el modo claro y oscuro (ignora la configuración del sistema).
  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

/// Configuración de los datos del tema claro.
ThemeData get lightTheme => AppTheme.lightTheme;

/// Configuración de los datos del tema oscuro.
ThemeData get darkTheme => AppTheme.darkTheme;
