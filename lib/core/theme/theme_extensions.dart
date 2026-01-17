/// Theme Extensions
///
/// Helper extension methods for easier theme access and dark mode detection.
library;

import 'package:flutter/material.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';

/// Extension on BuildContext for easier theme access
extension ThemeX on BuildContext {
  /// Obtiene el [ColorScheme] actual del tema.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Indica si el modo oscuro está activo.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Obtiene el color de superficie adaptado al tema.
  Color get surface => colorScheme.surface;

  /// Obtiene la variante del color de superficie adaptada al tema.
  Color get surfaceVariant => colorScheme.surfaceContainerHighest;

  /// Obtiene el color primario adaptado al tema.
  Color get primary => colorScheme.primary;

  /// Obtiene el color sobre superficie adaptado al tema.
  Color get onSurface => colorScheme.onSurface;

  /// Obtiene la variante del color sobre superficie adaptada al tema.
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;

  /// Obtiene el color de borde adaptado al tema.
  Color get border =>
      isDarkMode ? colorScheme.outlineVariant : AppColors.border;

  /// Colores de texto adaptados al tema (primario, secundario y terciario).
  Color get textPrimary => colorScheme.onSurface;

  /// Color de texto secundario.
  Color get textSecondary => colorScheme.onSurfaceVariant;

  /// Color de texto terciario.
  Color get textTertiary => colorScheme.outline;

  /// Colores semánticos adaptados al tema (peligro, éxito y advertencia).
  Color get danger => AppColors.danger;

  /// Color para éxito.
  Color get success => AppColors.success;

  /// Color para advertencias.
  Color get warning => AppColors.warning;
}
