import 'package:equatable/equatable.dart';

/// Represents a currency with its essential properties
/// Used throughout the app for type-safe currency handling
class CurrencyInfo extends Equatable {
  /// Crea una instancia de [CurrencyInfo] con sus propiedades básicas.
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });

  /// Create from code with automatic symbol/name lookup
  factory CurrencyInfo.fromCode(String code) {
    return CurrencyInfo(
      code: code,
      symbol: _getSymbol(code),
      name: _getName(code),
    );
  }

  /// ISO 4217 currency code (e.g., "USD", "NIO", "EUR")
  final String code;

  /// Currency symbol for display (e.g., "$", "C$", "€")
  final String symbol;

  /// Human-readable currency name (e.g., "US Dollar", "Nicaraguan Córdoba")
  final String name;

  /// Symbol lookup table (no hardcoded logic elsewhere)
  static String _getSymbol(String code) {
    const symbols = {
      'NIO': r'C$',
      'USD': r'$',
      'EUR': '€',
      'CRC': '₡',
      'HNL': 'L',
      'GTQ': 'Q',
      'MXN': r'$',
      'COP': r'$',
      'PEN': 'S/',
      'GBP': '£',
      'JPY': '¥',
      'CAD': r'CA$',
      'AUD': r'A$',
      'CHF': 'CHF',
      'CNY': '¥',
      'BRL': r'R$',
    };
    return symbols[code.toUpperCase()] ?? code;
  }

  /// Name lookup table
  static String _getName(String code) {
    const names = {
      'NIO': 'Córdoba Nicaragüense',
      'USD': 'Dólar Estadounidense',
      'EUR': 'Euro',
      'CRC': 'Colón Costarricense',
      'HNL': 'Lempira Hondureño',
      'GTQ': 'Quetzal Guatemalteco',
      'MXN': 'Peso Mexicano',
      'COP': 'Peso Colombiano',
      'PEN': 'Sol Peruano',
      'GBP': 'Libra Esterlina',
      'JPY': 'Yen Japonés',
      'CAD': 'Dólar Canadiense',
      'AUD': 'Dólar Australiano',
      'CHF': 'Franco Suizo',
      'CNY': 'Yuan Chino',
      'BRL': 'Real Brasileño',
    };
    return names[code.toUpperCase()] ?? code;
  }

  @override
  List<Object?> get props => [code, symbol, name];

  @override
  String toString() => '$symbol ($code)';
}

/// Context containing all currency information for calculations
/// This is the single source of truth for currency operations
class CurrencyContext {
  /// Crea un [CurrencyContext] con la moneda base y la de visualización.
  const CurrencyContext({
    required this.baseCurrency,
    required this.displayCurrency,
    this.sellRate,
  });

  /// Create context where base = display (no conversion needed)
  factory CurrencyContext.singleCurrency(CurrencyInfo currency) {
    return CurrencyContext(
      baseCurrency: currency,
      displayCurrency: currency,
      sellRate: 1,
    );
  }

  /// The user's local/home currency where Capital resides
  final CurrencyInfo baseCurrency;

  /// The currency selected for viewing reports/dashboard
  final CurrencyInfo displayCurrency;

  /// Current sell rate: Base → Display (how many Display units per 1 Base unit)
  /// Null if no rate is defined
  final double? sellRate;

  /// Whether base and display are the same currency
  bool get isSameCurrency => baseCurrency.code == displayCurrency.code;

  /// Whether we have a valid rate for conversion
  bool get hasValidRate =>
      isSameCurrency || (sellRate != null && sellRate! > 0);

  /// Error message if rate is missing
  String? get rateError => !hasValidRate ? 'exchange_rate_required' : null;
}

/// Result of a currency conversion operation
class ConversionResult {
  /// Crea un [ConversionResult] con el monto convertido y su símbolo.
  const ConversionResult({
    required this.amount,
    required this.symbol,
    this.success = true,
    this.errorKey,
  });

  /// Create a failed result
  factory ConversionResult.error(String errorKey) {
    return ConversionResult(
      amount: 0,
      symbol: '?',
      success: false,
      errorKey: errorKey,
    );
  }

  /// The converted amount
  final double amount;

  /// The currency symbol to display
  final String symbol;

  /// Whether the conversion was successful
  final bool success;

  /// Error key for localization if conversion failed
  final String? errorKey;

  /// Format amount with thousands separator
  /// Formatea el monto con punto decimal y lo devuelve como cadena.
  String formatAmount() {
    if (!success) return '--';
    // Simple formatting, can be enhanced with intl
    return amount.toStringAsFixed(2);
  }

  @override
  String toString() => success ? '$symbol$amount' : 'Error: $errorKey';
}
