import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PrestamosApp Typography System
/// Using Inter font for modern, professional look
class AppTypography {
  AppTypography._();

  // Base text style
  static TextStyle get _baseTextStyle => GoogleFonts.inter();

  // Display - Large headers
  /// Estilo para encabezados muy grandes (32px).
  static TextStyle get displayLarge => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Estilo para encabezados grandes (28px).
  static TextStyle get displayMedium => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Estilo para encabezados medianos (24px).
  static TextStyle get displaySmall =>
      _baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600);

  // Headlines
  /// Estilo para títulos de sección grandes (22px).
  static TextStyle get headlineLarge =>
      _baseTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w600);

  /// Estilo para títulos de sección medianos (20px).
  static TextStyle get headlineMedium =>
      _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600);

  /// Estilo para títulos de sección pequeños (18px).
  static TextStyle get headlineSmall =>
      _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

  // Titles
  /// Estilo para subtítulos grandes (16px).
  static TextStyle get titleLarge =>
      _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  /// Estilo para subtítulos medianos (14px).
  static TextStyle get titleMedium =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600);

  /// Estilo para subtítulos pequeños (13px).
  static TextStyle get titleSmall =>
      _baseTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w600);

  // Body text
  /// Estilo para texto de cuerpo grande (16px).
  static TextStyle get bodyLarge =>
      _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w400);

  /// Estilo para texto de cuerpo mediano (14px).
  static TextStyle get bodyMedium =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w400);

  /// Estilo para texto de cuerpo pequeño (12px).
  static TextStyle get bodySmall =>
      _baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400);

  // Labels
  /// Estilo para etiquetas grandes (14px).
  static TextStyle get labelLarge =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500);

  /// Estilo para etiquetas medianas (12px).
  static TextStyle get labelMedium =>
      _baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500);

  /// Estilo para etiquetas pequeñas (11px).
  static TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Money display - Special style for currency amounts
  /// Estilo prominente para montos de dinero (28px).
  static TextStyle get moneyLarge => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Estilo mediano para montos de dinero (20px).
  static TextStyle get moneyMedium =>
      _baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600);

  /// Estilo pequeño para montos de dinero (16px).
  static TextStyle get moneySmall =>
      _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  // Button text
  /// Estilo para texto en botones grandes (16px).
  static TextStyle get buttonLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Estilo para texto en botones medianos (14px).
  static TextStyle get buttonMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Estilo para texto en botones pequeños (12px).
  static TextStyle get buttonSmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
