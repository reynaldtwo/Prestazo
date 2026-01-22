import 'package:flutter/material.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';

/// PrestamosApp Theme Configuration
/// Combines colors, typography, and component themes
class AppTheme {
  AppTheme._();

  /// Genera la configuración del tema claro de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colors
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        outline: AppColors.border,
      ),

      // Component Themes
      appBarTheme: _appBarTheme(isDark: false),
      cardTheme: _cardTheme(isDark: false),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
      outlinedButtonTheme: _outlinedButtonTheme(isDark: false),
      textButtonTheme: _textButtonTheme(isDark: false),
      floatingActionButtonTheme: _fabTheme(isDark: false),
      inputDecorationTheme: _inputDecorationTheme(isDark: false),
      bottomNavigationBarTheme: _bottomNavTheme(isDark: false),
      dividerTheme: _dividerTheme(isDark: false),
      chipTheme: _chipTheme(isDark: false),
      dialogTheme: _dialogTheme(isDark: false),
      snackBarTheme: _snackBarTheme(isDark: false),
      listTileTheme: _listTileTheme(isDark: false),
      tabBarTheme: _tabBarTheme(isDark: false),
      switchTheme: _switchTheme(isDark: false),
    );
  }

  /// Genera la configuración del tema oscuro (Nocturne Emerald).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Colors
      primaryColor: AppColors.primaryDarkTheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDarkTheme,
        secondary: AppColors.secondaryDarkTheme,
        tertiary: AppColors.tertiaryDarkTheme,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.onSecondaryDarkTheme,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        error: AppColors.errorDark,
        outline: AppColors.textTertiaryDark,
        outlineVariant: AppColors.borderDark,
      ),

      // Component Themes
      appBarTheme: _appBarTheme(isDark: true),
      cardTheme: _cardTheme(isDark: true),
      elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
      outlinedButtonTheme: _outlinedButtonTheme(isDark: true),
      textButtonTheme: _textButtonTheme(isDark: true),
      floatingActionButtonTheme: _fabTheme(isDark: true),
      inputDecorationTheme: _inputDecorationTheme(isDark: true),
      bottomNavigationBarTheme: _bottomNavTheme(isDark: true),
      dividerTheme: _dividerTheme(isDark: true),
      chipTheme: _chipTheme(isDark: true),
      dialogTheme: _dialogTheme(isDark: true),
      snackBarTheme: _snackBarTheme(isDark: true),
      listTileTheme: _listTileTheme(isDark: true),
      tabBarTheme: _tabBarTheme(isDark: true),
      switchTheme: _switchTheme(isDark: true),
    );
  }

  // Helper methods to keep files under 300 lines limit

  static AppBarTheme _appBarTheme({required bool isDark}) => AppBarTheme(
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
    foregroundColor: isDark
        ? AppColors.textPrimaryDark
        : AppColors.textOnPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.headlineMedium.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textOnPrimary,
    ),
  );

  static CardThemeData _cardTheme({required bool isDark}) => CardThemeData(
    color: isDark ? AppColors.surfaceDark : AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required bool isDark,
  }) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: isDark ? AppColors.primaryDarkTheme : AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTypography.buttonMedium,
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required bool isDark,
  }) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: isDark ? AppColors.primaryDarkTheme : AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: isDark ? AppColors.primaryDarkTheme : AppColors.primary,
        width: 1.5,
      ),
      textStyle: AppTypography.buttonMedium,
    ),
  );

  static TextButtonThemeData _textButtonTheme({required bool isDark}) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.primaryDarkTheme
              : AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.buttonMedium,
        ),
      );

  static FloatingActionButtonThemeData _fabTheme({required bool isDark}) =>
      FloatingActionButtonThemeData(
        backgroundColor: isDark
            ? AppColors.secondaryDarkTheme
            : AppColors.accent,
        foregroundColor: isDark
            ? AppColors.onSecondaryDarkTheme
            : AppColors.textOnAccent,
        elevation: 4,
        shape: const CircleBorder(),
      );

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDarkTheme : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      );

  static BottomNavigationBarThemeData _bottomNavTheme({required bool isDark}) =>
      BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        selectedItemColor: isDark
            ? AppColors.primaryDarkTheme
            : AppColors.primary,
        unselectedItemColor: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  static DividerThemeData _dividerTheme({required bool isDark}) =>
      DividerThemeData(
        color: isDark ? AppColors.dividerDark : AppColors.divider,
        thickness: 1,
        space: 1,
      );

  static ChipThemeData _chipTheme({required bool isDark}) => ChipThemeData(
    backgroundColor: isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant,
    labelStyle: AppTypography.labelMedium.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static DialogThemeData _dialogTheme({required bool isDark}) =>
      DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      );

  static SnackBarThemeData _snackBarTheme({required bool isDark}) =>
      SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.textPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      );

  static ListTileThemeData _listTileTheme({required bool isDark}) =>
      ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        iconColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static TabBarThemeData _tabBarTheme({
    required bool isDark,
  }) => TabBarThemeData(
    labelColor: isDark ? AppColors.primaryDarkTheme : AppColors.textOnPrimary,
    unselectedLabelColor: isDark
        ? AppColors.textTertiaryDark
        : AppColors.textOnPrimary.withValues(alpha: 0.7),
    indicatorColor: isDark
        ? AppColors.primaryDarkTheme
        : AppColors.textOnPrimary,
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
    unselectedLabelStyle: AppTypography.labelMedium,
  );

  static SwitchThemeData _switchTheme({required bool isDark}) =>
      SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.primaryDarkTheme : AppColors.primary;
          }
          return isDark ? AppColors.iconInactiveDark : Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark ? AppColors.primaryDarkTheme : AppColors.primary)
                .withValues(alpha: 0.5);
          }
          return isDark
              ? AppColors.borderDark
              : Colors.grey.withValues(alpha: 0.5);
        }),
      );
}
