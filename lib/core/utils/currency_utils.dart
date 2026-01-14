/// Utility to map country codes to currency codes
class CurrencyUtils {
  static String getCurrencyCodeFromCountry(String? countryCode) {
    if (countryCode == null) return 'USD';

    // Common mappings (Expanded as needed)
    const map = {
      'NI': 'NIO', // Nicaragua
      'US': 'USD', // USA
      'CR': 'CRC', // Costa Rica
      'HN': 'HNL', // Honduras
      'GT': 'GTQ', // Guatemala
      'MX': 'MXN', // Mexico
      'CO': 'COP', // Colombia
      'PE': 'PEN', // Peru
      'ES': 'EUR', // Spain
      'SV': 'USD', // El Salvador (USD)
      'PA': 'USD', // Panama (USD/PAB)
      'EC': 'USD', // Ecuador (USD)
    };

    return map[countryCode.toUpperCase()] ?? 'USD';
  }

  /// Get currency symbol from currency code
  static String getCurrencySymbol(String currencyCode) {
    const symbols = {
      'NIO': 'C\$',
      'USD': '\$',
      'EUR': '€',
      'CRC': '₡',
      'HNL': 'L',
      'GTQ': 'Q',
      'MXN': '\$',
      'COP': '\$',
      'PEN': 'S/',
    };
    return symbols[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Get decimal precision for a currency (Default 2)
  static int getCurrencyPrecision(String currencyCode) {
    // In the future, this can be loaded from AppSettings or a DB table.
    // For now, most supported currencies use 2 decimals.
    // Exceptions like JPY (0) or BHD (3) can be added here.
    const precisions = {
      'CLF': 4, // Example: Fundos in Chile
      'JPY': 0, // Yen
      'BHD': 3, // Bahrain Dinar
      'KWD': 3, // Kuwait Dinar
      'OMR': 3, // Oman Rial
      'TND': 3, // Tunisian Dinar
    };
    return precisions[currencyCode.toUpperCase()] ?? 2;
  }
}
