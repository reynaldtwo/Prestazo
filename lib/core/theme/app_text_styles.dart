import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extension on BuildContext to provide theme-aware text styles
/// Usage: context.textStyles.titleLarge, context.textStyles.bodyMedium, etc.
extension AppTextStyles on BuildContext {
  /// Provee acceso a estilos de texto adaptados al tema actual.
  ThemedTextStyles get textStyles => ThemedTextStyles(this);
}

/// Theme-aware text styles that automatically use colorScheme colors
class ThemedTextStyles {
  /// Crea una instancia de [ThemedTextStyles] vinculada al [context] dado.
  ThemedTextStyles(this.context);

  /// El contexto de construcción para acceder al tema actual.
  final BuildContext context;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  TextStyle get _baseTextStyle => GoogleFonts.inter();

  // Display - Large headers
  /// Estilo para encabezados muy grandes (32px).
  TextStyle get displayLarge => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: _colors.onSurface,
    letterSpacing: -0.5,
  );

  /// Estilo para encabezados grandes (28px).
  TextStyle get displayMedium => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _colors.onSurface,
    letterSpacing: -0.5,
  );

  /// Estilo para encabezados medianos (24px).
  TextStyle get displaySmall => _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Headlines
  /// Estilo para títulos de sección grandes (22px).
  TextStyle get headlineLarge => _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  /// Estilo para títulos de sección medianos (20px).
  TextStyle get headlineMedium => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  /// Estilo para títulos de sección pequeños (18px).
  TextStyle get headlineSmall => _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Titles
  /// Estilo para subtítulos grandes (16px).
  TextStyle get titleLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  /// Estilo para subtítulos medianos (14px).
  TextStyle get titleMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  /// Estilo para subtítulos pequeños (13px).
  TextStyle get titleSmall => _baseTextStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Body text
  /// Estilo para texto de cuerpo grande (16px).
  TextStyle get bodyLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _colors.onSurface,
  );

  /// Estilo para texto de cuerpo mediano (14px).
  TextStyle get bodyMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.onSurface,
  );

  /// Estilo para texto de cuerpo pequeño (12px).
  TextStyle get bodySmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.onSurfaceVariant,
  );

  // Labels
  /// Estilo para etiquetas grandes (14px).
  TextStyle get labelLarge => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _colors.onSurface,
  );

  /// Estilo para etiquetas medianas (12px).
  TextStyle get labelMedium => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _colors.onSurfaceVariant,
  );

  /// Estilo para etiquetas pequeñas (11px).
  TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: _colors.outline,
    letterSpacing: 0.5,
  );

  // Money display - Special style for currency amounts
  /// Estilo prominente para montos de dinero (28px).
  TextStyle get moneyLarge => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _colors.onSurface,
    letterSpacing: -0.5,
  );

  /// Estilo mediano para montos de dinero (20px).
  TextStyle get moneyMedium => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  /// Estilo pequeño para montos de dinero (16px).
  TextStyle get moneySmall => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _colors.onSurface,
  );

  // Button text (no color - inherits from button theme)
  /// Estilo para texto en botones grandes (16px).
  TextStyle get buttonLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Estilo para texto en botones medianos (14px).
  TextStyle get buttonMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Estilo para texto en botones pequeños (12px).
  TextStyle get buttonSmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
