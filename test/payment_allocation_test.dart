import 'package:mockito/mockito.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/models/payment_allocation.dart';
import 'package:prestamos_app/data/repositories/billing_cycle_repository.dart';
import 'package:prestamos_app/data/repositories/loan_repository.dart';
import 'package:prestamos_app/data/repositories/payment_repository.dart';
import 'package:prestamos_app/services/interest_calculation_service.dart';
import 'package:prestamos_app/services/payment_service.dart';
import 'package:test/test.dart';

// Mocks
class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockBillingCycleRepository extends Mock
    implements BillingCycleRepository {
  List<BillingCycle> cycles = [];
  @override
  Future<List<BillingCycle>> getPendingCyclesByLoan(String loanId) async =>
      cycles;
}

class MockInterestCalculationService extends Mock
    implements InterestCalculationService {
  @override
  LoanCalculationResult calculateTotalDebt({
    required Loan loan,
    required List<BillingCycle> pendingCycles,
    required DateTime paymentDate,
    required String paymentType,
    bool dailyAccrualEnabled = false,
  }) {
    return const LoanCalculationResult(
      principalBalance: 10000,
      overdueInterest: 0,
      overdueCycles: [],
      currentCycle: null,
      currentCycleInterest: 0,
      proportionalInterest: 0,
      totalPendingInterest: 0,
      partialDays: 0,
    );
  }
}

void main() {
  group('Payment Allocation Logic', () {
    late PaymentService service;
    late MockBillingCycleRepository cycleRepo;

    setUp(() {
      cycleRepo = MockBillingCycleRepository();
      service = PaymentService(
        paymentRepository: MockPaymentRepository(),
        loanRepository: MockLoanRepository(),
        billingCycleRepository: cycleRepo,
        interestService: MockInterestCalculationService(),
      );
    });

    test(
      'Should allocated to Cycle 1 Principal BEFORE Cycle 2 Interest in Level Installment',
      () async {
        // ARRANGE
        final loan = Loan(
          loanId: 'l1',
          customerId: 'c1',
          principalOriginal: 10000,
          principalBalance: 10000,
          monthlyInterestRate: 10,
          billingFrequency: 'BIWEEKLY',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          disbursementDate: DateTime.now(),
        );

        // Cycle 1: Level Installment 2166.67 (Interest 500, Principal 1666.67) - OVERDUE
        final c1 = BillingCycle(
          billingCycleId: 'c1',
          loanId: 'l1',
          cycleNumber: 1,
          frequency: 'B',
          periodStartDate: DateTime.now().subtract(const Duration(days: 20)),
          periodEndDate: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().subtract(const Duration(days: 5)), // Past
          interestExpected: 500,
          interestPending: 500,
          installmentExpected: 2166.67,
          installmentPending: 2166.67,
          status: 'OVERDUE',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Cycle 2: Level Installment 2166.67 (Interest 500, Principal 1666.67) - PENDING
        final c2 = BillingCycle(
          billingCycleId: 'c2',
          loanId: 'l1',
          cycleNumber: 2,
          frequency: 'B',
          periodStartDate: DateTime.now().subtract(const Duration(days: 5)),
          periodEndDate: DateTime.now().add(const Duration(days: 10)),
          dueDate: DateTime.now().add(const Duration(days: 10)), // Future
          interestExpected: 500,
          interestPending: 500,
          installmentExpected: 2166.67,
          installmentPending: 2166.67,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        cycleRepo.cycles = [c1, c2];

        // ACT
        // User pays exactly one installment: 2166.67
        final allocations = await service.calculateAllocations(
          loan: loan,
          paymentAmount: 2166.67,
          paymentId: 'p1',
          paymentDate: DateTime.now(),
          paymentType: 'REGULAR',
        );

        // ASSERT
        final c1Interest = allocations.firstWhere(
          (a) => a.billingCycleId == 'c1' && a.allocationType == 'INTEREST',
        );
        final c1Principal = allocations.firstWhere(
          (a) => a.billingCycleId == 'c1' && a.allocationType == 'PRINCIPAL',
          orElse: () => PaymentAllocation(
            allocationId: '',
            paymentId: '',
            loanId: '',
            allocationType: 'NONE',
            amountLoanMinor: 0,
            createdAt: DateTime.now(),
          ),
        );

        expect(c1Interest.amount, 500.0);
        expect(c1Principal.allocationType, 'PRINCIPAL');
        expect(c1Principal.amount, closeTo(1666.67, 0.01));

        // Verify C2 is NOT touched
        final c2Allocations = allocations.where(
          (a) => a.billingCycleId == 'c2',
        );
        expect(
          c2Allocations.isEmpty,
          true,
          reason: 'Should not pay Cycle 2 if Cycle 1 needs full principal',
        );
      },
    );
  });
}
