import 'package:flutter/material.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';

/// Variantes de texto disponibles basadas en el sistema de diseño.
enum TextVariant {
  /// Encabezado muy grande (32px).
  displayLarge,

  /// Encabezado grande (28px).
  displayMedium,

  /// Encabezado mediano (24px).
  displaySmall,

  /// Título de sección grande (22px).
  headlineLarge,

  /// Título de sección mediano (20px).
  headlineMedium,

  /// Título de sección pequeño (18px).
  headlineSmall,

  /// Subtítulo grande (16px).
  titleLarge,

  /// Subtítulo mediano (14px).
  titleMedium,

  /// Subtítulo pequeño (13px).
  titleSmall,

  /// Texto de cuerpo grande (16px).
  bodyLarge,

  /// Texto de cuerpo mediano (14px).
  bodyMedium,

  /// Texto de cuerpo pequeño (12px).
  bodySmall,

  /// Etiqueta grande (14px).
  labelLarge,

  /// Etiqueta mediana (12px).
  labelMedium,

  /// Etiqueta pequeña (11px).
  labelSmall,
}

/// Widget estandarizado para mostrar texto en la aplicación.
///
/// Reemplaza el uso directo de [Text] según las reglas del proyecto.
class AppText extends StatelessWidget {
  /// Crea una instancia de [AppText].
  const AppText(
    this.text, {
    super.key,
    this.variant = TextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
  });

  /// El contenido del texto a mostrar.
  final String text;

  /// La variante visual del texto.
  final TextVariant variant;

  /// El color opcional para el texto. Si es nulo, usará el color por defecto del tema.
  final Color? color;

  /// Alineación del texto.
  final TextAlign? textAlign;

  /// Número máximo de líneas permitido.
  final int? maxLines;

  /// Comportamiento del texto cuando desborda.
  final TextOverflow? overflow;

  /// Peso de la fuente (opcional).
  final FontWeight? fontWeight;

  /// Estilo de la fuente (opcional).
  final FontStyle? fontStyle;

  /// Espaciado entre letras (opcional).
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final style = _getStyle().copyWith(
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getStyle() {
    return switch (variant) {
      TextVariant.displayLarge => AppTypography.displayLarge,
      TextVariant.displayMedium => AppTypography.displayMedium,
      TextVariant.displaySmall => AppTypography.displaySmall,
      TextVariant.headlineLarge => AppTypography.headlineLarge,
      TextVariant.headlineMedium => AppTypography.headlineMedium,
      TextVariant.headlineSmall => AppTypography.headlineSmall,
      TextVariant.titleLarge => AppTypography.titleLarge,
      TextVariant.titleMedium => AppTypography.titleMedium,
      TextVariant.titleSmall => AppTypography.titleSmall,
      TextVariant.bodyLarge => AppTypography.bodyLarge,
      TextVariant.bodyMedium => AppTypography.bodyMedium,
      TextVariant.bodySmall => AppTypography.bodySmall,
      TextVariant.labelLarge => AppTypography.labelLarge,
      TextVariant.labelMedium => AppTypography.labelMedium,
      TextVariant.labelSmall => AppTypography.labelSmall,
    };
  }
}
