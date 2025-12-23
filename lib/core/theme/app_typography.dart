import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PrestamosApp Typography System
/// Using Inter font for modern, professional look
class AppTypography {
  AppTypography._();

  // Base text style
  static TextStyle get _baseTextStyle => GoogleFonts.inter();

  // Display - Large headers
  static TextStyle get displayLarge => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displaySmall =>
      _baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600);

  // Headlines
  static TextStyle get headlineLarge =>
      _baseTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w600);

  static TextStyle get headlineMedium =>
      _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get headlineSmall =>
      _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

  // Titles
  static TextStyle get titleLarge =>
      _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get titleMedium =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get titleSmall =>
      _baseTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w600);

  // Body text
  static TextStyle get bodyLarge =>
      _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get bodySmall =>
      _baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400);

  // Labels
  static TextStyle get labelLarge =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get labelMedium =>
      _baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500);

  static TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Money display - Special style for currency amounts
  static TextStyle get moneyLarge => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get moneyMedium =>
      _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get moneySmall =>
      _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  // Button text
  static TextStyle get buttonLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle get buttonMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle get buttonSmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
