/// Theme Extensions
///
/// Helper extension methods for easier theme access and dark mode detection.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on BuildContext for easier theme access
extension ThemeX on BuildContext {
  /// Get the current ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get theme-aware surface color
  Color get surface => colorScheme.surface;

  /// Get theme-aware surface variant color
  Color get surfaceVariant => colorScheme.surfaceContainerHighest;

  /// Get theme-aware primary color
  Color get primary => colorScheme.primary;

  /// Get theme-aware onSurface color
  Color get onSurface => colorScheme.onSurface;

  /// Get theme-aware onSurfaceVariant color
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;

  /// Get theme-aware border color
  Color get border =>
      isDarkMode ? colorScheme.outlineVariant : AppColors.border;

  /// Get theme-aware text colors
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get textTertiary => colorScheme.outline;

  /// Get theme-aware danger/warning colors
  Color get danger => AppColors.danger;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
}
