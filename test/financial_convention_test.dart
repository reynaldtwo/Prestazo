// ignore_for_file: avoid_print // Tests use print for convention comparison output
/// Financial Convention Test Scenarios
///
/// Tests to validate that the Financial Convention configuration
/// correctly affects loan calculations, especially for CANCEL payments.
///
/// Run with: flutter test test/financial_convention_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/services/interest_calculation_service.dart';

void main() {
  late InterestCalculationService service;

  setUp(() {
    service = InterestCalculationService.instance;
  });

  group('ESCENARIO A: Sin Plan, 30/360, Cancelar', () {
    test('Interés vencido de 2 ciclos debe ser ~1,000 con 30/360', () {
      // Crear préstamo con convención 30/360
      final loan = Loan(
        loanId: 'test-loan-a',
        customerId: 'cust-1',
        principalOriginal: 10000,
        principalBalance: 10000,
        monthlyInterestRate: 10,
        billingFrequency: 'BIWEEKLY',
        disbursementDate: DateTime(2025, 12, 5),
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
        // V32: Policy snapshot - 30/360
        loanDayCountConvention: '30/360',
        loanDaysPerMonth: 30,
        loanDaysPerYear: 360,
        loanProrationRule: 'EXACT_DAYS',
        loanRoundingDecimals: 2,
        loanRoundingMode: 'HALF_UP',
      );

      // Ciclos vencidos
      final cycle1 = BillingCycle(
        billingCycleId: 'cycle-1',
        loanId: 'test-loan-a',
        cycleNumber: 1,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2025, 12, 5),
        periodEndDate: DateTime(2025, 12, 19),
        dueDate: DateTime(2025, 12, 19),
        interestExpected: 500, // 10,000 * 10% * (15/30) = 500
        interestPending: 500,
        status: 'OVERDUE',
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      final cycle2 = BillingCycle(
        billingCycleId: 'cycle-2',
        loanId: 'test-loan-a',
        cycleNumber: 2,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2025, 12, 20),
        periodEndDate: DateTime(2026, 1, 3),
        dueDate: DateTime(2026, 1, 3),
        interestExpected: 500,
        interestPending: 500,
        status: 'OVERDUE',
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      // Ciclo corriendo
      final cycle3 = BillingCycle(
        billingCycleId: 'cycle-3',
        loanId: 'test-loan-a',
        cycleNumber: 3,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2026, 1, 4),
        periodEndDate: DateTime(2026, 1, 18),
        dueDate: DateTime(2026, 1, 18),
        interestExpected: 500,
        interestPending: 500,
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      final pendingCycles = <BillingCycle>[cycle1, cycle2, cycle3];
      final paymentDate = DateTime(2026, 1, 14); // 14-01-2026

      final result = service.calculateTotalDebt(
        loan: loan,
        pendingCycles: pendingCycles,
        paymentDate: paymentDate,
        paymentType: 'CANCEL',
        dailyAccrualEnabled: true,
      );

      // Esperado con 30/360 y EXACT_DAYS:
      // Intereses vencidos: 2 × 500 = 1,000
      // Interés parcial (10 días): 10,000 × (10%/100) × (10/30) = 333.33
      // Total: 10,000 + 1,000 + 333.33 = 11,333.33

      print('--- ESCENARIO A: 30/360 ---');
      print('Overdue Interest: ${result.overdueInterest}');
      print('Current Cycle Interest: ${result.currentCycleInterest}');
      print('Proportional Interest: ${result.proportionalInterest}');
      print('Partial Days: ${result.partialDays}');
      print('Total Pending Interest: ${result.totalPendingInterest}');
      print('Principal: ${result.principalBalance}');
      print(
        'TOTAL CANCELAR: ${result.principalBalance + result.totalPendingInterest}',
      );

      expect(result.overdueInterest, equals(1000.0));
      expect(result.partialDays, equals(10)); // 04-01 a 14-01 = 10 días
    });
  });

  group('ESCENARIO B: Sin Plan, Actual/365, Cancelar', () {
    test('Interés vencido debe ser diferente a 30/360', () {
      // Mismo préstamo pero con Actual/365
      final loan = Loan(
        loanId: 'test-loan-b',
        customerId: 'cust-1',
        principalOriginal: 10000,
        principalBalance: 10000,
        monthlyInterestRate: 10,
        billingFrequency: 'BIWEEKLY',
        disbursementDate: DateTime(2025, 12, 5),
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
        // V32: Policy snapshot - Actual/365 con Días Exactos
        loanDayCountConvention: 'ACTUAL/365',
        loanDaysPerMonth: 30,
        loanDaysPerYear: 365,
        loanProrationRule: 'EXACT_DAYS',
        loanRoundingDecimals: 2,
        loanRoundingMode: 'HALF_UP',
      );

      // Ciclos con interés calculado para Actual/365
      // Interés 15 días = 10,000 × 1.20 × (15/365) = 493.15
      final cycle1 = BillingCycle(
        billingCycleId: 'cycle-1',
        loanId: 'test-loan-b',
        cycleNumber: 1,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2025, 12, 5),
        periodEndDate: DateTime(2025, 12, 19),
        dueDate: DateTime(2025, 12, 19),
        interestExpected: 493.15,
        interestPending: 493.15,
        status: 'OVERDUE',
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      final cycle2 = BillingCycle(
        billingCycleId: 'cycle-2',
        loanId: 'test-loan-b',
        cycleNumber: 2,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2025, 12, 20),
        periodEndDate: DateTime(2026, 1, 3),
        dueDate: DateTime(2026, 1, 3),
        interestExpected: 493.15,
        interestPending: 493.15,
        status: 'OVERDUE',
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      final cycle3 = BillingCycle(
        billingCycleId: 'cycle-3',
        loanId: 'test-loan-b',
        cycleNumber: 3,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2026, 1, 4),
        periodEndDate: DateTime(2026, 1, 18),
        dueDate: DateTime(2026, 1, 18),
        interestExpected: 493.15,
        interestPending: 493.15,
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      final pendingCycles = <BillingCycle>[cycle1, cycle2, cycle3];
      final paymentDate = DateTime(2026, 1, 14);

      final result = service.calculateTotalDebt(
        loan: loan,
        pendingCycles: pendingCycles,
        paymentDate: paymentDate,
        paymentType: 'CANCEL',
        dailyAccrualEnabled: true,
      );

      print('--- ESCENARIO B: Actual/365 ---');
      print('Overdue Interest: ${result.overdueInterest}');
      print('Current Cycle Interest: ${result.currentCycleInterest}');
      print('Proportional Interest: ${result.proportionalInterest}');
      print('Partial Days: ${result.partialDays}');
      print('Total Pending Interest: ${result.totalPendingInterest}');
      print('Principal: ${result.principalBalance}');
      print(
        'TOTAL CANCELAR: ${result.principalBalance + result.totalPendingInterest}',
      );

      // Verificar que es diferente a 30/360 (1000)
      expect(result.overdueInterest, closeTo(986.30, 0.01));
    });
  });

  group('ESCENARIO D: CYCLE_PROPORTION vs EXACT_DAYS', () {
    test('Diferentes reglas de prorrateo deben dar diferente resultado', () {
      // Préstamo con CYCLE_PROPORTION
      final loanCycle = Loan(
        loanId: 'test-loan-cycle',
        customerId: 'cust-1',
        principalOriginal: 10000,
        principalBalance: 10000,
        monthlyInterestRate: 10,
        billingFrequency: 'BIWEEKLY',
        disbursementDate: DateTime(2025, 12, 5),
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
        loanDayCountConvention: '30/360',
        loanDaysPerMonth: 30,
        loanDaysPerYear: 360,
        loanProrationRule: 'CYCLE_PROPORTION', // <-- Diferente
        loanRoundingDecimals: 2,
        loanRoundingMode: 'HALF_UP',
      );

      // Préstamo con EXACT_DAYS
      final loanExact = Loan(
        loanId: 'test-loan-exact',
        customerId: 'cust-1',
        principalOriginal: 10000,
        principalBalance: 10000,
        monthlyInterestRate: 10,
        billingFrequency: 'BIWEEKLY',
        disbursementDate: DateTime(2025, 12, 5),
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
        loanDayCountConvention: '30/360',
        loanDaysPerMonth: 30,
        loanDaysPerYear: 360,
        loanProrationRule: 'EXACT_DAYS', // <-- Diferente
        loanRoundingDecimals: 2,
        loanRoundingMode: 'HALF_UP',
      );

      final cycle = BillingCycle(
        billingCycleId: 'cycle-1',
        loanId: 'test-loan',
        cycleNumber: 1,
        frequency: 'BIWEEKLY',
        periodStartDate: DateTime(2026, 1, 4),
        periodEndDate: DateTime(2026, 1, 18),
        dueDate: DateTime(2026, 1, 18),
        interestExpected: 500,
        interestPending: 500,
        createdAt: DateTime(2025, 12, 5),
        updatedAt: DateTime(2025, 12, 5),
      );

      final paymentDate = DateTime(2026, 1, 14);

      final resultCycle = service.calculateTotalDebt(
        loan: loanCycle,
        pendingCycles: [cycle],
        paymentDate: paymentDate,
        paymentType: 'CANCEL',
        dailyAccrualEnabled: true,
      );

      final resultExact = service.calculateTotalDebt(
        loan: loanExact,
        pendingCycles: [cycle],
        paymentDate: paymentDate,
        paymentType: 'CANCEL',
        dailyAccrualEnabled: true,
      );

      print('--- ESCENARIO: CYCLE_PROPORTION vs EXACT_DAYS ---');
      print('CYCLE_PROPORTION: ${resultCycle.proportionalInterest}');
      print('EXACT_DAYS: ${resultExact.proportionalInterest}');
      print(
        'Total CYCLE_PROPORTION: ${resultCycle.principalBalance + resultCycle.totalPendingInterest}',
      );
      print(
        'Total EXACT_DAYS: ${resultExact.principalBalance + resultExact.totalPendingInterest}',
      );

      // Deberían ser diferentes porque usan fórmulas distintas
      expect(
        resultCycle.proportionalInterest,
        isNot(equals(resultExact.proportionalInterest)),
      );
    });
  });
}
