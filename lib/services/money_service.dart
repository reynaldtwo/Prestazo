import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

/// Service for strict monetary operations using minor units (Int64).
/// Enforces 'Zero-Check' and strict parsing rules.
class MoneyService {
  /// Parse user input string to minor units (int).
  ///
  /// Rules:
  /// - No grouping separators allowed (e.g. no '1,000').
  /// - Maximum ONE decimal separator.
  /// - Fraction digits must not exceed [fractionDigits].
  /// - If [fractionDigits] is 0, NO decimal separator allowed.
  /// - Reject negative numbers if [allowNegative] is false.
  static int parse(
    String input, {
    required int fractionDigits,
    String? locale, // defaults to 'en_US' if null/standard
    bool allowNegative = false,
  }) {
    if (input.trim().isEmpty) return 0;

    // 1. Get Decimal Separator for Locale
    locale ??= Intl.getCurrentLocale();
    final NumberSymbols symbols =
        numberFormatSymbols[locale] ??
        numberFormatSymbols['en_US'] as NumberSymbols;
    final String decimalSep = symbols.DECIMAL_SEP;

    // 2. Strict Regex Validation
    // No grouping separators allowed. ONLY digits, optional negative sign, and optional decimal.

    // Normalize input: remove spaces
    String cleaned = input.replaceAll(' ', '');

    // Check for grouping separators (forbidden)
    if (cleaned.contains(symbols.GROUP_SEP)) {
      throw FormatException(
        'Thousand separators are not allowed. Please enter digits only.',
      );
    }

    // Validate character set (digits, decimal, minus)
    final allowedChars = RegExp('^[0-9${RegExp.escape(decimalSep)}-]+\$');
    if (!allowedChars.hasMatch(cleaned)) {
      throw FormatException('Invalid characters in input.');
    }

    // Check negative
    if (cleaned.startsWith('-')) {
      if (!allowNegative) {
        throw FormatException('Negative values are not allowed.');
      }
      if (cleaned.lastIndexOf('-') > 0) {
        throw FormatException('Invalid format.');
      }
    } else if (cleaned.contains('-')) {
      throw FormatException('Invalid format.');
    }

    // Check decimals
    if (cleaned.contains(decimalSep)) {
      if (fractionDigits == 0) {
        throw FormatException('This currency does not allow decimals.');
      }

      final parts = cleaned.split(decimalSep);
      if (parts.length > 2) {
        throw FormatException('Multiple decimal separators.');
      }

      final fraction = parts[1];
      if (fraction.length > fractionDigits) {
        throw FormatException(
          'Too many decimal places (Limit: $fractionDigits).',
        );
      }
    }

    // 3. Convert to Minor Units
    // We parse as double temporarily? NO. Double loses precision for large numbers.
    // Parse parts manually.

    final isNegative = cleaned.startsWith('-');
    final absCleaned = isNegative ? cleaned.substring(1) : cleaned;

    BigInt major;
    BigInt minor;

    if (absCleaned.contains(decimalSep)) {
      final parts = absCleaned.split(decimalSep);
      major = BigInt.parse(parts[0].isEmpty ? '0' : parts[0]);

      String fracStr = parts[1];
      // Pad fraction to fractionDigits
      if (fracStr.length < fractionDigits) {
        fracStr = fracStr.padRight(fractionDigits, '0');
      }
      minor = BigInt.parse(fracStr);
    } else {
      major = BigInt.parse(absCleaned.isEmpty ? '0' : absCleaned);
      minor = BigInt.zero;
    }

    // Combine: major * 10^frac + minor
    final power = BigInt.from(10).pow(fractionDigits);
    BigInt total = (major * power) + minor;

    if (isNegative) total = -total;

    // Check Int64 bounds (Signed 63-bit safe)
    // Dart int is 64-bit on VM (native).
    if (!total.isValidInt) {
      throw FormatException('Amount too large.');
    }

    return total.toInt();
  }

  /// Format minor units to display string.
  static String format(
    int minorUnits, {
    required String currencyCode,
    String? locale,
  }) {
    // We assume default 2 digits if we just use simpleCurrency,
    // BUT we should respect the actual fraction digits of the currency.
    // For now, using NumberFormat.simpleCurrency checks internal data.

    final fmt = NumberFormat.simpleCurrency(name: currencyCode, locale: locale);
    // Convert back to major (double) for formatting
    // Note: Use simple conversion for display ONLY.
    // Ideally we divide by 10^digits.

    // How to get fraction digits from Currency object in NumberFormat?
    // It's in the formatter.decimalDigits usually.
    final digits = fmt.decimalDigits ?? 2;

    final double val = minorUnits / (BigInt.from(10).pow(digits).toInt());
    return fmt.format(val);
  }
}
