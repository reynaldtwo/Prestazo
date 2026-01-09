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

  PaymentService({
    required PaymentRepository paymentRepository,
    required LoanRepository loanRepository,
    required BillingCycleRepository billingCycleRepository,
    InterestCalculationService? interestService,
  }) : _paymentRepository = paymentRepository,
       _loanRepository = loanRepository,
       _billingCycleRepository = billingCycleRepository,
       _interestService =
           interestService ?? InterestCalculationService.instance;

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

    double remaining = paymentAmount;

    // First, allocate to overdue interest (oldest cycles first)
    if (calculation.overdueInterest > 0 && remaining > 0) {
      final sortedCycles = pendingCycles.toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      for (final cycle in sortedCycles) {
        if (remaining <= 0) break;
        if (cycle.interestPending <= 0) continue;

        final interestToAllocate = remaining.clamp(0.0, cycle.interestPending);
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
