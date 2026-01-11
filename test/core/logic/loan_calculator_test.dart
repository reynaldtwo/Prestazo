import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/core/logic/loan_calculator.dart';

void main() {
  group('LoanCalculator Commercial Rules', () {
    test('Example 1: 3 Months, Weekly, 13.33%', () {
      final result = LoanCalculator.calculateLoan(
        capital: 2000.00,
        monthlyRate: 0.1333,
        term: 3,
        termUnit: 'Months', // or Meses
        frequencyDays: 7, // Weekly
        disbursementDate: DateTime.utc(2026, 1, 10),
      );

      // Verify Step 1: Plazo en días
      expect(result.termDays, 90, reason: '3 months * 30 days = 90');

      // Verify Step 2: Cuotas Totales (ceil(90/7) = 13)
      expect(result.installmentsCount, 13, reason: 'ceil(90/7) should be 13');

      // Verify Step 3: Fecha Fin (10 Jan + 89 days = 09 Apr 2026?)
      // Jan 10 + 21 = Jan 31 (21 days)
      // Feb 28 days (49 days)
      // Mar 31 days (80 days)
      // Apr 9 (89 days passed?)
      // Let's rely on standard DateTime math which the user implicitly accepted
      // The user calculated: 10-ene + (90-1) = 09-abr-2026.
      expect(
        result.endDate,
        DateTime.utc(2026, 4, 9),
        reason: 'Should matches user calculation for end date',
      );

      // Verify Step 4: Interest
      // 2000 * 0.1333 * 3 = 799.80
      expect(result.totalInterest, 799.80);
      expect(result.totalPayable, 2799.80);

      // Verify Step 5: Installments
      // Cuota Base: 2799.80 / 13 = 215.369... -> 215.37
      expect(result.installmentAmount, 215.37);

      // Last Installment Adjustment
      // 12 * 215.37 = 2584.44
      // Total 2799.80 - 2584.44 = 215.36
      expect(result.lastInstallmentAmount, 215.36);
    });

    test('Example 2: 60 Days, Fortnightly, 8%', () {
      final result = LoanCalculator.calculateLoan(
        capital: 5000.00,
        monthlyRate: 0.08,
        term: 60,
        termUnit: 'Days',
        frequencyDays: 15, // Quincenal
        disbursementDate: DateTime.utc(2026, 1, 10),
      );

      // Step 1: Days
      expect(result.termDays, 60);

      // Step 2: Installments ceil(60/15) = 4
      expect(result.installmentsCount, 4);

      // Step 3: End Date
      // 10 Jan + 59 days.
      // 10 Jan + 21 = 31 Jan.
      // Feb 28. (Total 49).
      // Mar 10. (Total 59).
      expect(result.endDate, DateTime.utc(2026, 3, 10));

      // Step 4: Interest
      // Equiv Months = 60 / 30 = 2.
      // 5000 * 0.08 * 2 = 800.00
      expect(result.totalInterest, 800.00);
      expect(result.totalPayable, 5800.00);

      // Step 5: Installments
      // 5800 / 4 = 1450.00
      expect(result.installmentAmount, 1450.00);
      expect(result.lastInstallmentAmount, 1450.00);
    });
  });
}
