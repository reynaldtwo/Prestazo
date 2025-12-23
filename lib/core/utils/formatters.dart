import 'package:intl/intl.dart';

/// Utility functions for formatting
class Formatters {
  Formatters._();

  // Currency formatter for Nicaragua (NIO)
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_NI',
    symbol: 'C\$',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormatter = NumberFormat('#,##0.00', 'es_NI');
  static final NumberFormat _percentFormatter = NumberFormat.percentPattern('es_NI');
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy', 'es_NI');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'es_NI');
  static final DateFormat _isoDateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy', 'es_NI');
  static final DateFormat _shortDateFormatter = DateFormat('dd MMM', 'es_NI');

  /// Format amount as currency (C$ 1,234.56)
  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format amount as number with decimals (1,234.56)
  static String number(double amount) {
    return _numberFormatter.format(amount);
  }

  /// Format as percentage (20%)
  static String percent(double value) {
    return _percentFormatter.format(value);
  }

  /// Format rate as readable percentage (20.00%)
  static String rate(double decimalRate) {
    return '${(decimalRate * 100).toStringAsFixed(2)}%';
  }

  /// Format date as dd/MM/yyyy
  static String date(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format datetime as dd/MM/yyyy HH:mm
  static String dateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Format date as ISO (yyyy-MM-dd) for database
  static String isoDate(DateTime date) {
    return _isoDateFormatter.format(date);
  }

  /// Parse ISO date string to DateTime
  static DateTime parseIsoDate(String isoDate) {
    return _isoDateFormatter.parse(isoDate);
  }

  /// Format as Month Year (Diciembre 2025)
  static String monthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  /// Format as short date (15 Dic)
  static String shortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  /// Format days ago/remaining
  static String relativeDays(int days) {
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    if (days == -1) return 'Ayer';
    if (days > 0) return 'En $days días';
    return 'Hace ${days.abs()} días';
  }

  /// Format phone number
  static String phone(String phone) {
    // Simple format for Nicaragua numbers
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 8) {
      return '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
    }
    return phone;
  }
}
