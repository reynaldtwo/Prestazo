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
}
