import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extension on BuildContext to provide theme-aware text styles
/// Usage: context.textStyles.titleLarge, context.textStyles.bodyMedium, etc.
extension AppTextStyles on BuildContext {
  ThemedTextStyles get textStyles => ThemedTextStyles(this);
}

/// Theme-aware text styles that automatically use colorScheme colors
class ThemedTextStyles {
  final BuildContext context;

  ThemedTextStyles(this.context);

  ColorScheme get _colors => Theme.of(context).colorScheme;
  TextStyle get _baseTextStyle => GoogleFonts.inter();

  // Display - Large headers
  TextStyle get displayLarge => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: _colors.onSurface,
    letterSpacing: -0.5,
  );

  TextStyle get displayMedium => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _colors.onSurface,
    letterSpacing: -0.5,
  );

  TextStyle get displaySmall => _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Headlines
  TextStyle get headlineLarge => _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  TextStyle get headlineMedium => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  TextStyle get headlineSmall => _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Titles
  TextStyle get titleLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  TextStyle get titleMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  TextStyle get titleSmall => _baseTextStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Body text
  TextStyle get bodyLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _colors.onSurface,
  );

  TextStyle get bodyMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.onSurface,
  );

  TextStyle get bodySmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.onSurfaceVariant,
  );

  // Labels
  TextStyle get labelLarge => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _colors.onSurface,
  );

  TextStyle get labelMedium => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _colors.onSurfaceVariant,
  );

  TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: _colors.outline,
    letterSpacing: 0.5,
  );

  // Money display - Special style for currency amounts
  TextStyle get moneyLarge => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _colors.onSurface,
    letterSpacing: -0.5,
  );

  TextStyle get moneyMedium => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  TextStyle get moneySmall => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Button text (no color - inherits from button theme)
  TextStyle get buttonLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  TextStyle get buttonMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  TextStyle get buttonSmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
