import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/core/utils/finance_engine.dart';

/// Unit Tests for FinanceEngine - Banking Standard Validation
/// Tests the Universal Conversion Formula: Display = Base / Rate
void main() {
  group('FinanceEngine.convertBaseToDisplay', () {
    // =========================================================================
    // ESCENARIO 1: Moneda Fuerte (Dólar USD)
    // Base: NIO, Display: USD
    // Tasa: 37.0 (1 USD = 37 NIO)
    // Préstamo: 200 USD normalizado a 7,400 NIO (200 * 37)
    // Resultado esperado: 7,400 / 37 = 200.00 USD
    // =========================================================================
    test('Scenario 1: Strong Currency (USD) - 7400 NIO / 37 = 200 USD', () {
      const amountInBase = 7400; // NIO
      const rate = 37; // 1 USD = 37 NIO
      const expectedResult = 200; // USD

      final result = FinanceEngine.convertBaseToDisplay(
        amountInBase.toDouble(),
        rate.toDouble(),
      );

      expect(result, closeTo(expectedResult, 0.01));
      // VALIDACIÓN: El resultado NO debe ser inflado (273,800)
      expect(result, isNot(closeTo(273800.0, 1.0)));
    });

    // =========================================================================
    // ESCENARIO 2: Moneda Intermedia (Peso Mexicano MXN)
    // Base: NIO, Display: MXN
    // Tasa: 2.0468 (1 MXN = 2.0468 NIO)
    // Préstamo: 7,400 NIO
    // Resultado esperado: 7,400 / 2.0468 = 3,615.40 MXN
    // =========================================================================
    test(
      'Scenario 2: Intermediate Currency (MXN) - 7400 NIO / 2.0468 = 3615.40 MXN',
      () {
        const amountInBase = 7400; // NIO
        const rate = 2.0468; // 1 MXN = 2.0468 NIO
        const expectedResult = 3615.40; // MXN

        final result = FinanceEngine.convertBaseToDisplay(
          amountInBase.toDouble(),
          rate,
        );

        expect(result, closeTo(expectedResult, 0.01));
        // VALIDACIÓN: El resultado NO debe ser inflado (15,146.32)
        expect(result, isNot(closeTo(15146.32, 1.0)));
      },
    );

    // =========================================================================
    // ESCENARIO 3: Moneda Débil (Colón Costarricense CRC)
    // Base: NIO, Display: CRC
    // Tasa: 0.0710 (1 CRC = 0.0710 NIO)
    // Préstamo: 7,400 NIO
    // Resultado esperado: 7,400 / 0.0710 = 104,225.35 CRC
    // =========================================================================
    test(
      'Scenario 3: Weak Currency (CRC) - 7400 NIO / 0.0710 = 104225.35 CRC',
      () {
        const amountInBase = 7400; // NIO
        const rate = 0.0710; // 1 CRC = 0.0710 NIO
        const expectedResult = 104225.35; // CRC

        final result = FinanceEngine.convertBaseToDisplay(
          amountInBase.toDouble(),
          rate,
        );

        expect(result, closeTo(expectedResult, 0.5)); // Allow small tolerance
        // VALIDACIÓN: El resultado debe ser MAYOR que la base (correcto para moneda débil)
        expect(result, greaterThan(amountInBase));
      },
    );

    // =========================================================================
    // EDGE CASES
    // =========================================================================
    test('Edge Case: Rate of 1.0 returns same amount', () {
      const amount = 1000;
      const rate = 1;

      final result = FinanceEngine.convertBaseToDisplay(
        amount.toDouble(),
        rate.toDouble(),
      );

      expect(result, equals(amount));
    });

    test(
      'Edge Case: Rate of 0 or negative returns original amount (safety)',
      () {
        const amount = 1000;

        expect(
          FinanceEngine.convertBaseToDisplay(amount.toDouble(), 0),
          equals(amount),
        );
        expect(
          FinanceEngine.convertBaseToDisplay(amount.toDouble(), -5),
          equals(amount),
        );
      },
    );
  });

  group('FinanceEngine.normalizeToBase', () {
    test('Normalization: 200 USD * 37 = 7400 NIO', () {
      const foreignAmount = 200; // USD
      const contractRate = 37; // 1 USD = 37 NIO

      final result = FinanceEngine.normalizeToBase(
        foreignAmount.toDouble(),
        contractRate.toDouble(),
      );

      expect(result, equals(7400));
    });

    test('Normalization: 100 MXN * 2.0468 = 204.68 NIO', () {
      const foreignAmount = 100; // MXN
      const contractRate = 2.0468; // 1 MXN = 2.0468 NIO

      final result = FinanceEngine.normalizeToBase(
        foreignAmount.toDouble(),
        contractRate,
      );

      expect(result, closeTo(204.68, 0.01));
    });

    test('Edge Case: Invalid rate throws exception', () {
      expect(() => FinanceEngine.normalizeToBase(100, 0), throwsException);
      expect(() => FinanceEngine.normalizeToBase(100, -1), throwsException);
    });
  });
}
