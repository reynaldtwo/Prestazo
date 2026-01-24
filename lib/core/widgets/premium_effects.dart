import 'dart:ui';
import 'package:flutter/material.dart';

/// Un widget que aplica un desvanecimiento suave a los bordes superior e inferior.
class PremiumFadedEdges extends StatelessWidget {
  /// Crea una instancia de [PremiumFadedEdges].
  const PremiumFadedEdges({
    required this.child,
    super.key,
    this.depth = 40.0,
    this.fadeTop = true,
    this.fadeBottom = true,
  });

  /// El widget que se desea desvanecer en sus bordes.
  final Widget child;

  /// La profundidad del desvanecimiento en píxeles.
  final double depth;

  /// Indica si se debe aplicar desvanecimiento en la parte superior.
  final bool fadeTop;

  /// Indica si se debe aplicar desvanecimiento en la parte inferior.
  final bool fadeBottom;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        // Usamos una paleta con opacidades aún más bajas al inicio para evitar franjas.
        // La progresión es no-lineal para un efecto de 'neblina' premium.
        final fadeColors = [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.4),
          Colors.black.withValues(alpha: 0.8),
          Colors.black,
        ];

        final colors = <Color>[];
        final stops = <double>[];

        // Definición de la parte superior
        if (fadeTop) {
          colors.addAll(fadeColors);
          stops.addAll([
            0,
            (depth * 0.15) / bounds.height,
            (depth * 0.35) / bounds.height,
            (depth * 0.6) / bounds.height,
            (depth * 0.85) / bounds.height,
            (depth * 1.0) / bounds.height,
          ]);
        } else {
          colors.add(Colors.black);
          stops.add(0);
        }

        // Centro (sólido)
        colors.add(Colors.black);
        stops.add(0.5);

        // Definición de la parte inferior
        if (fadeBottom) {
          colors.addAll(fadeColors.reversed);
          stops.addAll([
            1.0 - (depth * 1.0) / bounds.height,
            1.0 - (depth * 0.85) / bounds.height,
            1.0 - (depth * 0.6) / bounds.height,
            1.0 - (depth * 0.35) / bounds.height,
            1.0 - (depth * 0.15) / bounds.height,
            1,
          ]);
        } else {
          colors.add(Colors.black);
          stops.add(1);
        }

        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

/// Un contenedor con efecto de cristal (Glassmorphism) para usar en límites.
class GlassBoundary extends StatelessWidget {
  /// Crea una instancia de [GlassBoundary].
  const GlassBoundary({
    required this.child,
    super.key,
    this.height,
    this.blur = 10,
    this.opacity = 0.05,
    this.borderRadius,
    this.border,
  });

  /// El contenido que se mostrará sobre el cristal.
  final Widget child;

  /// Altura fija opcional.
  final double? height;

  /// Intensidad del desenfoque.
  final double blur;

  /// Opacidad del tinte de color.
  final double opacity;

  /// Radio de los bordes.
  final BorderRadius? borderRadius;

  /// Borde opcional para resaltar el efecto.
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: opacity,
            ),
            borderRadius: borderRadius,
            border:
                border ??
                Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                  width: 0.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
