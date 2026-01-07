import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sealed_currencies/sealed_currencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing selected currency code
const String _currencyKey = 'selected_currency';

/// Provider for the selected currency
final currencyProvider = StateNotifierProvider<CurrencyNotifier, FiatCurrency>((
  ref,
) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<FiatCurrency> {
  CurrencyNotifier()
    : super(
        FiatCurrency.list.firstWhere(
          (c) => c.code == 'NIO',
          orElse: () => FiatCurrency.list.first,
        ),
      ) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_currencyKey);
      if (code != null) {
        final currency = FiatCurrency.maybeFromCode(code);
        if (currency != null) {
          state = currency;
        }
      }
    } catch (_) {
      // Ignore errors, use default
    }
  }

  Future<void> setCurrency(FiatCurrency currency) async {
    state = currency;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency.code);
    } catch (_) {
      // Ignore errors
    }
  }
}
