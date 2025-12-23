import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Money display widget with consistent formatting
class MoneyDisplay extends StatelessWidget {
  final double amount;
  final MoneyDisplaySize size;
  final Color? color;
  final bool showSign;
  final bool showCurrency;
  final String currencySymbol;

  const MoneyDisplay({
    super.key,
    required this.amount,
    this.size = MoneyDisplaySize.medium,
    this.color,
    this.showSign = false,
    this.showCurrency = true,
    this.currencySymbol = 'C\$',
  });

  @override
  Widget build(BuildContext context) {
    // Nicaraguan format: comma for thousands, dot for decimals
    final formattedAmount = _formatNicaraguan(amount.abs());

    String displayText = '';
    if (showSign && amount != 0) {
      displayText = amount > 0 ? '+' : '-';
    } else if (amount < 0) {
      displayText = '-';
    }

    if (showCurrency) {
      displayText += '$currencySymbol ';
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
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return '${buffer.toString().split('').reversed.join()}.$decimalPart';
  }
}

enum MoneyDisplaySize { small, medium, large }

/// Compact money display for lists
class MoneyLabel extends StatelessWidget {
  final String label;
  final double amount;
  final Color? amountColor;
  final bool isCompact;

  const MoneyLabel({
    super.key,
    required this.label,
    required this.amount,
    this.amountColor,
    this.isCompact = false,
  });

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
          size: MoneyDisplaySize.medium,
          color: amountColor,
        ),
      ],
    );
  }
}
