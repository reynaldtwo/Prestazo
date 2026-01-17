import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/providers/currency_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';

/// Money display widget with consistent formatting
class MoneyDisplay extends ConsumerWidget {
  /// Crea un [MoneyDisplay] para mostrar montos monetarios formateados.
  const MoneyDisplay({
    required this.amount,
    super.key,
    this.size = MoneyDisplaySize.medium,
    this.color,
    this.showSign = false,
    this.showCurrency = true,
    this.currencySymbol, // default will be pulled from provider
  });

  /// Cantidad numérica del monto a mostrar.
  final double amount;

  /// Tamaño visual del texto del dinero.
  final MoneyDisplaySize size;

  /// Color personalizado para el texto (si es nulo, usa colores semánticos por defecto).
  final Color? color;

  /// Indica si se debe mostrar siempre el signo (+ o -).
  final bool showSign;

  /// Indica si se debe mostrar el símbolo de la moneda.
  final bool showCurrency;

  /// Símbolo de moneda personalizado (si es nulo, usa el del proveedor global).
  final String? currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get symbol from provider if not explicit
    final effectiveSymbol =
        currencySymbol ?? ref.watch(currencyProvider).symbol;

    // Nicaraguan format: comma for thousands, dot for decimals
    final formattedAmount = _formatNicaraguan(amount.abs());

    var displayText = '';
    if (showSign && amount != 0) {
      displayText = amount > 0 ? '+' : '-';
    } else if (amount < 0) {
      displayText = '-';
    }

    if (showCurrency) {
      displayText += '$effectiveSymbol '; // Use variable, not hardcoded
    }
    displayText += formattedAmount;

    final textColor = color ?? _getDefaultColor(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        displayText,
        style: _getTextStyle().copyWith(color: textColor),
      ),
    );
  }

  Color _getDefaultColor(BuildContext context) {
    if (amount > 0 && showSign) return AppColors.success;
    if (amount < 0) return AppColors.danger;
    return Theme.of(context).colorScheme.onSurface;
  }

  TextStyle _getTextStyle() {
    return switch (size) {
      MoneyDisplaySize.small => AppTypography.moneySmall,
      MoneyDisplaySize.medium => AppTypography.moneyMedium,
      MoneyDisplaySize.large => AppTypography.moneyLarge,
    };
  }

  /// Format number with Nicaraguan style: comma for thousands, dot for decimals
  String _formatNicaraguan(double value) {
    // Format with 2 decimal places
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add comma separators for thousands
    final buffer = StringBuffer();
    final digits = integerPart.split('').reversed.toList();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return '${buffer.toString().split('').reversed.join()}.$decimalPart';
  }
}

/// Tamaños disponibles para el visualizador de dinero.
enum MoneyDisplaySize {
  /// Tamaño pequeño.
  small,

  /// Tamaño mediano (predeterminado).
  medium,

  /// Tamaño grande.
  large,
}

/// Compact money display for lists
class MoneyLabel extends StatelessWidget {
  /// Crea un [MoneyLabel] que combina una etiqueta descriptiva con un monto.
  const MoneyLabel({
    required this.label,
    required this.amount,
    super.key,
    this.amountColor,
    this.isCompact = false,
    this.currencySymbol,
  });

  /// Etiqueta descriptiva (ej: "Capital").
  final String label;

  /// Monto monetario.
  final double amount;

  /// Color personalizado para el monto.
  final Color? amountColor;

  /// Indica si se debe mostrar en formato compacto (en una línea).
  final bool isCompact;

  /// Símbolo de moneda opcional.
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppTypography.labelSmall),
          Flexible(
            child: MoneyDisplay(
              amount: amount,
              size: MoneyDisplaySize.small,
              color: amountColor,
              currencySymbol: currencySymbol,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        MoneyDisplay(
          amount: amount,
          color: amountColor,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }
}
