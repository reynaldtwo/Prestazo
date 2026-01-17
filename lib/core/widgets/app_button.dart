import 'package:flutter/material.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';

/// Reusable button component with multiple variants
/// Variantes disponibles para el botón.
enum AppButtonVariant {
  /// Botón principal con color sólido primario.
  primary,

  /// Botón secundario con color de acento.
  secondary,

  /// Botón con borde y fondo transparente.
  outline,

  /// Botón de texto plano sin bordes ni fondo.
  text,

  /// Botón para acciones destructivas o de error.
  danger,
}

/// Tamaños predefinidos para el botón.
enum AppButtonSize {
  /// Tamaño pequeño (40px de altura).
  small,

  /// Tamaño estándar (48px de altura).
  medium,

  /// Tamaño grande (56px de altura).
  large,
}

/// Botón personalizado que sigue el sistema de diseño de la aplicación.
class AppButton extends StatelessWidget {
  /// Crea un [AppButton] con parámetros configurables.
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  /// Texto que se muestra en el botón.
  final String label;

  /// Acción a ejecutar al presionar el botón.
  final VoidCallback? onPressed;

  /// Estilo visual del botón.
  final AppButtonVariant variant;

  /// Tamaño físico del botón.
  final AppButtonSize size;

  /// Icono opcional que se muestra antes del texto.
  final IconData? icon;

  /// Indica si el botón está en estado de carga (muestra un spinner).
  final bool isLoading;

  /// Indica si el botón debe ocupar todo el ancho disponible.
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(),
    );
  }

  double _getHeight() {
    return switch (size) {
      AppButtonSize.small => 40,
      AppButtonSize.medium => 48,
      AppButtonSize.large => 56,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 16),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 32),
    };
  }

  TextStyle _getTextStyle() {
    return switch (size) {
      AppButtonSize.small => AppTypography.buttonSmall,
      AppButtonSize.medium => AppTypography.buttonMedium,
      AppButtonSize.large => AppTypography.buttonLarge,
    };
  }

  Widget _buildButton() {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _getIconSize()),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        ),
        child: child,
      ),
      AppButtonVariant.secondary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        ),
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        ),
        child: child,
      ),
      AppButtonVariant.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: AppColors.textOnPrimary,
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        ),
        child: child,
      ),
    };
  }

  double _getIconSize() {
    return switch (size) {
      AppButtonSize.small => 16,
      AppButtonSize.medium => 20,
      AppButtonSize.large => 24,
    };
  }

  Color _getLoadingColor() {
    return switch (variant) {
      AppButtonVariant.primary => AppColors.textOnPrimary,
      AppButtonVariant.secondary => AppColors.textOnAccent,
      AppButtonVariant.outline => AppColors.primary,
      AppButtonVariant.text => AppColors.primary,
      AppButtonVariant.danger => AppColors.textOnPrimary,
    };
  }
}
