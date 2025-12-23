/// Theme Provider
///
/// Riverpod provider for managing app theme mode (dark/light/system).
/// Persists theme preference to local storage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

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
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  /// Set and persist theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {
      // Ignore storage errors
    }
  }

  /// Toggle between light and dark (ignores system)
  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

/// Light Theme Data
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.danger,
    onPrimary: AppColors.textOnPrimary,
    onSecondary: AppColors.textOnAccent,
    onSurface: AppColors.textPrimary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
    type: BottomNavigationBarType.fixed,
  ),
);

/// Dark Theme Data
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryLight,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primaryLight,
    secondary: AppColors.accent,
    surface: AppColors.surfaceDark,
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    error: AppColors.danger,
    onPrimary: AppColors.textOnPrimary,
    onSecondary: AppColors.textOnAccent,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.textTertiaryDark,
    outlineVariant: AppColors.borderDark,
  ),
  // Text theme with proper dark colors
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: AppColors.textPrimaryDark),
    displayMedium: TextStyle(color: AppColors.textPrimaryDark),
    displaySmall: TextStyle(color: AppColors.textPrimaryDark),
    headlineLarge: TextStyle(color: AppColors.textPrimaryDark),
    headlineMedium: TextStyle(color: AppColors.textPrimaryDark),
    headlineSmall: TextStyle(color: AppColors.textPrimaryDark),
    titleLarge: TextStyle(color: AppColors.textPrimaryDark),
    titleMedium: TextStyle(color: AppColors.textPrimaryDark),
    titleSmall: TextStyle(color: AppColors.textPrimaryDark),
    bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
    bodyMedium: TextStyle(color: AppColors.textPrimaryDark),
    bodySmall: TextStyle(color: AppColors.textSecondaryDark),
    labelLarge: TextStyle(color: AppColors.textPrimaryDark),
    labelMedium: TextStyle(color: AppColors.textSecondaryDark),
    labelSmall: TextStyle(color: AppColors.textTertiaryDark),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryDark,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariantDark,
    // Text styles for input fields
    hintStyle: const TextStyle(color: AppColors.textTertiaryDark),
    labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
    floatingLabelStyle: const TextStyle(color: AppColors.primaryLight),
    prefixIconColor: AppColors.textSecondaryDark,
    suffixIconColor: AppColors.textSecondaryDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
  ),
  // List tile theme
  listTileTheme: const ListTileThemeData(
    textColor: AppColors.textPrimaryDark,
    iconColor: AppColors.textSecondaryDark,
  ),
  // Icon theme
  iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
  dividerTheme: const DividerThemeData(
    color: AppColors.dividerDark,
    thickness: 1,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    selectedItemColor: AppColors.primaryLight,
    unselectedItemColor: AppColors.textTertiaryDark,
    type: BottomNavigationBarType.fixed,
  ),
  // Dialog theme
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceDark,
    titleTextStyle: const TextStyle(
      color: AppColors.textPrimaryDark,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
  ),
  // Chip theme
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surfaceVariantDark,
    labelStyle: const TextStyle(color: AppColors.textPrimaryDark),
    selectedColor: AppColors.primaryLight,
  ),
);
