import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/services/fx_service.dart';

void main() {
  group('FxService Currency Conversion Tests', () {
    test('Foreign (USD) to Base (NIO) should MULTIPLY', () {
      // 5 USD @ 37 NIO/USD
      // Expected: 185 NIO
      // Amount Minor: 500
      // Rate: 37.0

      final result = FxService.convertMinor(
        amountMinor: 500, // 5.00
        rate: 37.0,
        fromCurrency: 'USD',
        toCurrency: 'NIO',
        baseCurrency: 'NIO',
      );

      expect(result, 18500); // 185.00
    });

    test('Base (NIO) to Foreign (USD) should DIVIDE', () {
      // 185 NIO @ 37 NIO/USD
      // Expected: 5 USD

      final result = FxService.convertMinor(
        amountMinor: 18500, // 185.00
        rate: 37.0,
        fromCurrency: 'NIO',
        toCurrency: 'USD',
        baseCurrency: 'NIO',
      );

      expect(result, 500); // 5.00
    });

    test('Foreign (CRC) to Base (NIO) should MULTIPLY (Weak currency)', () {
      // 10000 CRC.
      // Rate: 0.07 NIO per CRC.
      // Expected: 700 NIO.

      final result = FxService.convertMinor(
        amountMinor: 1000000, // 10,000.00
        rate: 0.07,
        fromCurrency: 'CRC',
        toCurrency: 'NIO',
        baseCurrency: 'NIO',
      );

      expect(result, 70000); // 700.00
    });

    test('Input with Comma Sanitization Logic (Simulation)', () {
      // User inputs "37,00"
      String input = "37,00";
      String sanitized = input.replaceAll(',', '.');
      double? rate = double.tryParse(sanitized);

      expect(rate, 37.0);

      final result = FxService.convertMinor(
        amountMinor: 500,
        rate: rate!,
        fromCurrency: 'USD',
        toCurrency: 'NIO',
        baseCurrency: 'NIO',
      );

      expect(result, 18500);
    });
  });
}
