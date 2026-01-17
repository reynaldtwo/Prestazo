import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';

/// Reusable text field component with variants
class AppTextField extends StatelessWidget {
  /// Crea un [AppTextField] altamente configurable.
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.prefixText,
  });

  /// Etiqueta que flota sobre el campo.
  final String? label;

  /// Texto de sugerencia dentro del campo.
  final String? hint;

  /// Texto de ayuda debajo del campo.
  final String? helperText;

  /// Texto de error (si hay una validación fallida).
  final String? errorText;

  /// Controlador para gestionar el texto.
  final TextEditingController? controller;

  /// Tipo de teclado que se muestra.
  final TextInputType keyboardType;

  /// Indica si el texto debe ocultarse (ej: contraseñas).
  final bool obscureText;

  /// Indica si el campo está habilitado.
  final bool enabled;

  /// Indica si el campo es de solo lectura.
  final bool readOnly;

  /// Cantidad máxima de líneas (null para multilínea ilimitado).
  final int? maxLines;

  /// Cantidad máxima de caracteres permitidos.
  final int? maxLength;

  /// Icono opcional al inicio del campo.
  final IconData? prefixIcon;

  /// Widget opcional al final del campo.
  final Widget? suffix;

  /// Función llamada cuando cambia el texto.
  final ValueChanged<String>? onChanged;

  /// Función llamada al tocar el campo.
  final VoidCallback? onTap;

  /// Función de validación del formulario.
  final FormFieldValidator<String>? validator;

  /// Lista de formateadores de entrada (ej: máscaras).
  final List<TextInputFormatter>? inputFormatters;

  /// Nodo de enfoque para gestionar el foco manualmente.
  final FocusNode? focusNode;

  /// Acción a ejecutar en el teclado (ej: done, search).
  final TextInputAction? textInputAction;

  /// Función llamada al presionar "acción" en el teclado.
  final ValueChanged<String>? onSubmitted;

  /// Prefijo textual estático (ej: "$ ").
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            helperText: helperText,
            errorText: errorText,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: colorScheme.onSurfaceVariant)
                : null,
            suffix: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Money input field with currency formatting
class AppMoneyField extends StatelessWidget {
  /// Crea un [AppMoneyField] optimizado para entradas monetarias.
  const AppMoneyField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.currencySymbol = r'C$',
  });

  /// Etiqueta del campo.
  final String? label;

  /// Sugerencia de valor (ej: "0.00").
  final String? hint;

  /// Texto de error externo.
  final String? errorText;

  /// Controlador del texto.
  final TextEditingController? controller;

  /// Estado del campo.
  final bool enabled;

  /// Callback de cambio de valor.
  final ValueChanged<String>? onChanged;

  /// Validador de formulario.
  final FormFieldValidator<String>? validator;

  /// Símbolo de moneda a mostrar como prefijo (ej: "$").
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint ?? '0.00',
      errorText: errorText,
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      validator: validator,
      prefixText: '$currencySymbol ',
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }
}

/// Search input field
class AppSearchField extends StatelessWidget {
  /// Crea un [AppSearchField] con botón de limpieza incluido.
  const AppSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  /// Texto de sugerencia (por defecto "Buscar...").
  final String? hint;

  /// Controlador del texto de búsqueda.
  final TextEditingController? controller;

  /// Callback cuando el texto de búsqueda cambia.
  final ValueChanged<String>? onChanged;

  /// Callback cuando se presiona el botón de limpiar "X".
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint ?? 'Buscar...',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
