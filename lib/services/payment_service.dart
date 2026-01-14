/// Payment Service
///
/// Handles business logic for payment processing, including:
/// - Payment validation
/// - Loan balance updates
/// - Billing cycle updates
/// - Loan closure logic
library;

import '../data/models/payment.dart';
import '../data/models/payment_allocation.dart';
import '../data/models/loan.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/loan_repository.dart';
import '../data/repositories/billing_cycle_repository.dart';
import '../data/repositories/payment_plan_repository.dart';
import 'interest_calculation_service.dart';

/// Result of a payment operation
class PaymentResult {
  final Payment payment;
  final bool loanClosed;
  final double remainingBalance;
  final String? message;

  const PaymentResult({
    required this.payment,
    this.loanClosed = false,
    required this.remainingBalance,
    this.message,
  });
}

/// Service for processing payments with business logic
class PaymentService {
  final PaymentRepository _paymentRepository;
  final LoanRepository _loanRepository;
  final BillingCycleRepository _billingCycleRepository;
  final InterestCalculationService _interestService;
  final PaymentPlanRepository? _paymentPlanRepository;

  PaymentService({
    required PaymentRepository paymentRepository,
    required LoanRepository loanRepository,
    required BillingCycleRepository billingCycleRepository,
    InterestCalculationService? interestService,
    PaymentPlanRepository? paymentPlanRepository,
  }) : _paymentRepository = paymentRepository,
       _loanRepository = loanRepository,
       _billingCycleRepository = billingCycleRepository,
       _interestService =
           interestService ?? InterestCalculationService.instance,
       _paymentPlanRepository = paymentPlanRepository;

  /// Process a payment with full business logic
  ///
  /// This method:
  /// 1. Validates the payment
  /// 2. Creates allocations for interest and principal
  /// 3. Updates the loan balance
  /// 4. Updates billing cycles
  /// 5. Closes the loan if fully paid
  Future<PaymentResult> processPayment({
    required Payment payment,
    required List<PaymentAllocation> allocations,
    required Loan loan,
  }) async {
    // Validate payment amount
    if (payment.amountPaymentMinor <= 0) {
      throw PaymentValidationException('El monto del pago debe ser mayor a 0');
    }

    // Validate loan is active
    if (!loan.isActive) {
      throw PaymentValidationException(
        'No se puede registrar pago en un préstamo cerrado',
      );
    }

    // Process the payment through repository
    final processedPayment = await _paymentRepository
        .insertPaymentWithAllocations(payment, allocations);

    // Get updated loan to check if it was closed
    final updatedLoan = await _loanRepository.getLoanById(loan.loanId);
    final loanClosed = updatedLoan?.isClosed ?? false;
    final remainingBalance = updatedLoan?.principalBalance ?? 0;

    return PaymentResult(
      payment: processedPayment,
      loanClosed: loanClosed,
      remainingBalance: remainingBalance,
      message: loanClosed ? 'Préstamo cerrado automáticamente' : null,
    );
  }

  /// Calculate suggested allocations for a payment amount
  ///
  /// Uses the interest calculation service to determine how to
  /// distribute the payment between interest and principal
  Future<List<PaymentAllocation>> calculateAllocations({
    required Loan loan,
    required double paymentAmount,
    required String paymentId,
    required DateTime paymentDate,
    required String paymentType,
    bool dailyAccrualEnabled = false,
  }) async {
    final allocations = <PaymentAllocation>[];

    // Get pending billing cycles
    final pendingCycles = await _billingCycleRepository.getPendingCyclesByLoan(
      loan.loanId,
    );

    // Calculate debt using centralized service
    final calculation = _interestService.calculateTotalDebt(
      loan: loan,
      pendingCycles: pendingCycles,
      paymentDate: paymentDate,
      paymentType: paymentType,
      dailyAccrualEnabled: dailyAccrualEnabled,
    );

    // --- ROBUSTNESS: Corrective Context for Legacy/Migrated Loans ---
    // If the Loan has a Plan ID, but the 'distributeCapitalAndInterest' snapshot is missing or false
    // (typical for loans created before V30 fix or migrated incorrectly),
    // we MUST fetch the original Plan to know the intended behavior.
    bool robustDistribute = loan.distributeCapitalAndInterest ?? false;

    if (!robustDistribute &&
        loan.planId != null &&
        _paymentPlanRepository != null) {
      try {
        final plan = await _paymentPlanRepository!.getById(loan.planId!);
        if (plan != null && plan.distributeCapitalAndInterest) {
          robustDistribute = true;
        }
      } catch (_) {
        // Fail silently if repo fails, fall back to snapshot
      }
    }
    // ----------------------------------------------------------------

    double remaining = paymentAmount;

    // Allocate to billing cycles (oldest first)
    if (remaining > 0) {
      final sortedCycles = pendingCycles.toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      for (final cycle in sortedCycles) {
        if (remaining <= 0) break;

        // --- LEVEL INSTALLMENT DETECTION ---
        // A cycle is Level Installment if:
        //   1) It has installmentExpected > 0 (new data), OR
        //   2) The Loan Plan dictates distributeCapitalAndInterest = true (robustDistribute)
        final isLevelInstallment =
            (cycle.installmentExpected ?? 0) > 0 ||
            (loan.planId != null && robustDistribute);

        final interestPending = cycle.interestPending;

        // --- CASE 1: LEVEL INSTALLMENT (CUOTA NIVELADA) ---
        // Pay the FULL installment for this cycle (Interest + Principal) BEFORE moving to the next.
        if (isLevelInstallment) {
          // Calculate amounts needed for this cycle
          // installmentPending includes both Interest and Principal for the cycle
          final installmentPending =
              cycle.installmentPending ?? interestPending;

          // Principal portion = Installment - Interest
          double principalNeeded = (installmentPending - interestPending).clamp(
            0.0,
            double.infinity,
          );

          // Fallback: If principalNeeded is 0 but we know it's Level Installment, use cycle.principalPortion
          if (principalNeeded <= 0 && (cycle.principalPortion ?? 0) > 0) {
            principalNeeded = cycle.principalPortion!;
          }

          // Step 1: Pay Interest for this cycle
          if (interestPending > 0 && remaining > 0) {
            final interestToAllocate = remaining.clamp(0.0, interestPending);
            if (interestToAllocate > 0) {
              allocations.add(
                PaymentAllocation(
                  allocationId: '${paymentId}_INT_${cycle.billingCycleId}',
                  paymentId: paymentId,
                  loanId: loan.loanId,
                  allocationType: 'INTEREST',
                  amountLoanMinor: (interestToAllocate * 100).round(),
                  billingCycleId: cycle.billingCycleId,
                  createdAt: DateTime.now(),
                ),
              );
              remaining -= interestToAllocate;
            }
          }

          // Step 2: Pay Principal for this cycle (Level Installment portion)
          if (principalNeeded > 0 && remaining > 0) {
            final principalToAllocate = remaining.clamp(0.0, principalNeeded);
            if (principalToAllocate > 0) {
              allocations.add(
                PaymentAllocation(
                  allocationId: '${paymentId}_PRIN_${cycle.billingCycleId}',
                  paymentId: paymentId,
                  loanId: loan.loanId,
                  allocationType: 'PRINCIPAL',
                  amountLoanMinor: (principalToAllocate * 100).round(),
                  billingCycleId: cycle.billingCycleId,
                  createdAt: DateTime.now(),
                ),
              );
              remaining -= principalToAllocate;
            }
          }

          // NOTE: For Level Installment, we do NOT move to the next cycle
          // until this cycle's installment is fully paid.
          // However, if there's remaining money after paying this cycle's full installment,
          // the loop will naturally continue to the next cycle.
        } else {
          // --- CASE 2: TRADITIONAL LOAN (Solo Intereses) ---
          // Only pay Interest for this cycle. Principal is paid separately later.
          if (interestPending > 0) {
            final interestToAllocate = remaining.clamp(0.0, interestPending);
            if (interestToAllocate > 0) {
              allocations.add(
                PaymentAllocation(
                  allocationId: '${paymentId}_INT_${cycle.billingCycleId}',
                  paymentId: paymentId,
                  loanId: loan.loanId,
                  allocationType: 'INTEREST',
                  amountLoanMinor: (interestToAllocate * 100).round(),
                  billingCycleId: cycle.billingCycleId,
                  createdAt: DateTime.now(),
                ),
              );
              remaining -= interestToAllocate;
            }
          }
        }
      }
    }

    // Then, allocate to proportional/current interest if any
    if (calculation.proportionalInterest > 0 && remaining > 0) {
      final currentCycle = pendingCycles
          .where((c) => c.dueDate.isAfter(paymentDate))
          .toList();

      if (currentCycle.isNotEmpty) {
        final interestToAllocate = remaining.clamp(
          0.0,
          calculation.proportionalInterest,
        );
        if (interestToAllocate > 0) {
          allocations.add(
            PaymentAllocation(
              allocationId: '${paymentId}_INT_PROP',
              paymentId: paymentId,
              loanId: loan.loanId,
              allocationType: 'INTEREST',
              amountLoanMinor: (interestToAllocate * 100).round(),
              billingCycleId: currentCycle.first.billingCycleId,
              createdAt: DateTime.now(),
            ),
          );
          remaining -= interestToAllocate;
        }
      }
    }

    // Finally, allocate remaining to principal
    if (remaining > 0) {
      final principalToAllocate = remaining.clamp(0.0, loan.principalBalance);
      if (principalToAllocate > 0) {
        allocations.add(
          PaymentAllocation(
            allocationId: '${paymentId}_PRINCIPAL',
            paymentId: paymentId,
            loanId: loan.loanId,
            allocationType: 'PRINCIPAL',
            amountLoanMinor: (principalToAllocate * 100).round(),
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return allocations;
  }

  /// Process a capital recovery payment
  ///
  /// This is used when the loan is being cancelled/recovered
  /// without considering pending interest
  Future<PaymentResult> processRecoveryPayment({
    required Payment payment,
    required List<PaymentAllocation> allocations,
    required bool restrictCustomer,
    required String? restrictionReason,
  }) async {
    final processedPayment = await _paymentRepository.registerRecoveryPayment(
      payment: payment,
      allocations: allocations,
      restrictCustomer: restrictCustomer,
      restrictionReason: restrictionReason,
    );

    return PaymentResult(
      payment: processedPayment,
      loanClosed: true,
      remainingBalance: 0,
      message: 'Préstamo cerrado por recuperación de capital',
    );
  }

  /// Void a payment and reverse its effects
  Future<void> voidPayment({
    required String paymentId,
    required String reason,
  }) async {
    // Get the payment first
    final payment = await _paymentRepository.getPaymentById(paymentId);
    if (payment == null) {
      throw PaymentValidationException('Pago no encontrado');
    }

    if (payment.isVoided) {
      throw PaymentValidationException('El pago ya está anulado');
    }

    // Void the payment (the repository handles the reversal logic)
    await _paymentRepository.voidPayment(paymentId, reason);
  }
}

/// Exception thrown when payment validation fails
class PaymentValidationException implements Exception {
  final String message;

  PaymentValidationException(this.message);

  @override
  String toString() => 'PaymentValidationException: $message';
}
