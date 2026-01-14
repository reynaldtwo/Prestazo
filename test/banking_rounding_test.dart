import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:prestamos_app/services/billing_cycle_service.dart';
import 'package:prestamos_app/data/models/payment_plan.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/repositories/billing_cycle_repository.dart';
import 'package:prestamos_app/data/repositories/customer_repository.dart';
import 'package:prestamos_app/data/repositories/loan_repository.dart';
import 'package:prestamos_app/data/repositories/payment_plan_repository.dart';
import 'package:prestamos_app/data/repositories/settings_repository.dart'; // Make sure this exists or mock it? Service doesn't take it yet, logic is in CurrencyUtils.

class MockLoanRepository extends Mock implements LoanRepository {}

class MockCustomerRepository extends Mock implements CustomerRepository {
  @override
  Future<Customer?> getCustomerById(String id) async => Customer(
    customerId: id,
    fullName: 'Test',
    billingFrequency: 'M',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class MockBillingCycleRepository extends Mock
    implements BillingCycleRepository {
  final List<BillingCycle> cycles = [];
  @override
  Future<List<BillingCycle>> insertBillingCycles(
    List<BillingCycle> newCycles,
  ) async {
    cycles.addAll(newCycles);
    return newCycles;
  }
}

class MockPaymentPlanRepository extends Mock implements PaymentPlanRepository {
  PaymentPlan? planToReturn;
  @override
  Future<PaymentPlan?> getById(String id) async => planToReturn;
}

void main() {
  group('Banking Rounding Logic', () {
    late BillingCycleService service;
    late MockBillingCycleRepository cycleRepo;
    late MockPaymentPlanRepository planRepo;

    setUp(() {
      cycleRepo = MockBillingCycleRepository();
      planRepo = MockPaymentPlanRepository();

      service = BillingCycleService(
        cycleRepository: cycleRepo,
        customerRepository: MockCustomerRepository(),
        loanRepository: MockLoanRepository(),
        planRepository: planRepo,
      );
    });

    test(
      'Total installments sum must equal exactly 13000.00 (Regression for +0.02 error)',
      () async {
        // ARRANGE
        final now = DateTime.now();
        // Payment Plan: Iniciantes
        // 10k, 10% Monthly, 3 Months, 6 Installments (Biweekly)
        final plan = PaymentPlan(
          planId: 'p1',
          name: 'Iniciantes',
          paymentFrequencyId: 'biweekly',
          paymentFrequencyDays: 15,
          termValue: 3,
          termUnit: 'Months',
          installmentsTotal: 6,
          monthlyInterestRate: 10,
          currencyCode: 'NIO',
          distributeCapitalAndInterest: true,
          periodStartsOnDisbursement: true,
          createdAt: now,
          updatedAt: now,
        );

        planRepo.planToReturn = plan;

        final loan = Loan(
          loanId: 'l1',
          customerId: 'c1',
          principalOriginal: 10000,
          principalBalance: 10000,
          monthlyInterestRate: 10,
          billingFrequency: 'BIWEEKLY',
          planId: 'p1',
          planInstallmentsTotal: 6,
          paymentFrequencyDays: 15,
          distributeCapitalAndInterest:
              true, // Trigger Level Installment (snapshot)
          disbursementDate: now,
          currencyCode: 'NIO',
          status: 'ACTIVE',
          createdAt: now,
          updatedAt: now,
        );

        // ACT
        await service.generateInitialSchedule(loan);

        // ASSERT
        final generatedCycles = cycleRepo.cycles;
        expect(generatedCycles.length, 6);

        double totalInstallmentSum = 0;
        for (var c in generatedCycles) {
          totalInstallmentSum += c.installmentExpected!;
          print('Cycle ${c.cycleNumber}: ${c.installmentExpected}');
        }

        // Check Individual Installment (approx 2166.67)
        expect(generatedCycles[0].installmentExpected, 2166.67);
        expect(generatedCycles[4].installmentExpected, 2166.67);

        // Check Last Installment (Should be adjusted: 2166.65)
        // 13000 - (2166.67 * 5) = 13000 - 10833.35 = 2166.65
        expect(generatedCycles[5].installmentExpected, 2166.65);

        // Check Total Sum
        expect(
          double.parse(totalInstallmentSum.toStringAsFixed(2)),
          13000.00,
          reason: 'Total sum must be exactly 13,000',
        );
      },
    );
  });
}
