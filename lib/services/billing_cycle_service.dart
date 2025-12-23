/// Billing Cycle Service
///
/// Centralized service for billing cycle management.
/// Handles:
/// - Automatic generation of missing cycles
/// - Cycle status updates
/// - Cycle date calculations
library;

import '../data/models/billing_cycle.dart';
import '../data/models/customer.dart';
import '../data/models/loan.dart';
import '../data/repositories/billing_cycle_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/loan_repository.dart';

/// Service for billing cycle management
class BillingCycleService {
  final BillingCycleRepository _cycleRepo;
  final CustomerRepository _customerRepo;
  final LoanRepository _loanRepo;

  BillingCycleService({
    required BillingCycleRepository cycleRepository,
    required CustomerRepository customerRepository,
    required LoanRepository loanRepository,
  }) : _cycleRepo = cycleRepository,
       _customerRepo = customerRepository,
       _loanRepo = loanRepository;

  /// Validates if a customer can have a new loan based on settings
  Future<bool> validateNewLoan(
    String customerId,
    bool allowMultipleLoans,
  ) async {
    if (allowMultipleLoans) return true;

    final loans = await _loanRepo.getLoansByCustomerId(customerId);
    final activeLoans = loans.where((l) => l.status == 'ACTIVE').toList();

    return activeLoans.isEmpty;
  }

  /// Alias for generating missing cycles, specifically used when checking for overdue status
  Future<List<BillingCycle>> generateOverdueCycles(Loan loan) async {
    return generateMissingCycles(loan);
  }

  /// Generate all missing cycles for a loan up to the current date (or specific reference date)
  Future<List<BillingCycle>> generateMissingCycles(
    Loan loan, {
    DateTime? referenceDate,
  }) async {
    if (loan.status == 'CLOSED') return [];

    // Get customer for other data (not frequency anymore)
    final customer = await _customerRepo.getCustomerById(loan.customerId);
    if (customer == null) return [];

    // Get existing cycles
    final existingCycles = await _cycleRepo.getBillingCyclesByLoan(loan.loanId);

    // Determine frequency from LOAN (not customer)
    final isBiweekly = loan.billingFrequency == 'BIWEEKLY';
    final cycleDays = isBiweekly ? 15 : 30;

    DateTime nextStart;
    int nextCycleNumber;

    if (existingCycles.isEmpty) {
      nextStart = loan.disbursementDate;
      nextCycleNumber = 1;
    } else {
      // Sort by cycle number descending
      existingCycles.sort((a, b) => b.cycleNumber.compareTo(a.cycleNumber));
      final lastCycle = existingCycles.first;

      // Next cycle starts day after last cycle ends
      nextStart = lastCycle.periodEndDate.add(const Duration(days: 1));
      nextCycleNumber = lastCycle.cycleNumber + 1;
    }

    // Use reference date if provided, otherwise now.
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final generatedCycles = <BillingCycle>[];

    while (true) {
      final nextEnd = nextStart.add(Duration(days: cycleDays - 1));

      // We should generate the cycle if its start date is BEFORE or EQUAL to today.
      // Even if today is the first day of the cycle, the cycle "exists".
      // Previous logic: if (nextStart.isAfter(today)) break;
      // This is correct: if start > today, it's in the future.
      if (nextStart.isAfter(today)) {
        break;
      }

      final cycle = _createCycle(
        loan: loan,
        customer: customer,
        cycleNumber: nextCycleNumber,
        startDate: nextStart,
        endDate: nextEnd,
        isBiweekly: isBiweekly,
      );

      await _cycleRepo.insertBillingCycle(cycle);
      generatedCycles.add(cycle);

      nextStart = nextEnd.add(const Duration(days: 1));
      nextCycleNumber++;

      if (generatedCycles.length > 200) break;
    }

    // Update overdue status for old cycles immediately
    if (generatedCycles.isNotEmpty || existingCycles.isNotEmpty) {
      await _updateOverdueStatus(loan.loanId, referenceDate: referenceDate);
    }

    return generatedCycles;
  }

  /// Regenerate future cycles for a loan.
  /// DELETES all cycles that have no payments (interestPaid == 0) and are not closed.
  /// Then regenerates cycles from the loan start date.
  /// This is used when loan terms (capital, rate, disbursement date) are edited.
  Future<void> regenerateFutureCycles(Loan loan) async {
    // 1. Get all cycles
    final allCycles = await _cycleRepo.getBillingCyclesByLoan(loan.loanId);

    // 2. Identify cycles safe to delete (no payments made)
    final cyclesToDelete = allCycles.where((c) {
      // Keep PAID, PARTIAL, CAPITALIZED
      // Delete PENDING, OVERDUE if interestPaid is 0
      final hasPayments = c.interestPaid > 0;
      final isClosed = c.status == 'PAID' || c.status == 'CAPITALIZED';
      return !hasPayments && !isClosed;
    }).toList();

    // 3. Delete them
    for (final cycle in cyclesToDelete) {
      await _cycleRepo.deleteBillingCycle(cycle.billingCycleId);
    }

    // 4. Regenerate
    // logic inside generateMissingCycles handles skipping existing cycles (PAID ones)
    // because it checks existingCycles and starts from the last one.
    // However, if we deleted ALL cycles, it starts from loan.disbursementDate.
    // This is exactly what we want.
    await generateMissingCycles(loan);
  }

  /// Update cycle statuses to OVERDUE if past due date
  Future<void> _updateOverdueStatus(
    String loanId, {
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cycles = await _cycleRepo.getPendingCyclesByLoan(loanId);

    for (final cycle in cycles) {
      final dueDate = DateTime(
        cycle.dueDate.year,
        cycle.dueDate.month,
        cycle.dueDate.day,
      );

      // If due date is strictly before today, it is overdue.
      if (dueDate.isBefore(today) &&
          cycle.status == 'PENDING' &&
          cycle.interestPending > 0) {
        final updated = cycle.copyWith(status: 'OVERDUE', updatedAt: now);
        await _cycleRepo.updateBillingCycle(updated);
      }
    }
  }

  /// Create a new billing cycle
  BillingCycle _createCycle({
    required Loan loan,
    required Customer customer,
    required int cycleNumber,
    required DateTime startDate,
    required DateTime endDate,
    required bool isBiweekly,
  }) {
    final now = DateTime.now();
    final frequency = isBiweekly ? 'BIWEEKLY' : 'MONTHLY';

    // Calculate expected interest
    final interestExpected = isBiweekly
        ? loan.calculateBiweeklyInterest()
        : loan.calculateMonthlyInterest();

    return BillingCycle(
      billingCycleId: '${loan.loanId}_cycle_$cycleNumber',
      loanId: loan.loanId,
      cycleNumber: cycleNumber,
      frequency: frequency,
      periodStartDate: startDate,
      periodEndDate: endDate,
      dueDate: endDate, // Due on last day of cycle
      interestExpected: interestExpected,
      interestPaid: 0,
      interestPending: interestExpected,
      status: 'PENDING',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Calculate the next due date based on frequency
  DateTime calculateNextDueDate(DateTime fromDate, String frequency) {
    final days = frequency == 'BIWEEKLY' ? 14 : 29;
    return fromDate.add(Duration(days: days));
  }

  /// Get all overdue cycles for a loan
  Future<List<BillingCycle>> getOverdueCycles(String loanId) async {
    final cycles = await _cycleRepo.getPendingCyclesByLoan(loanId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return cycles.where((c) {
      final dueDate = DateTime(c.dueDate.year, c.dueDate.month, c.dueDate.day);
      return dueDate.isBefore(today);
    }).toList();
  }

  /// Get current (running) cycle for a loan
  Future<BillingCycle?> getCurrentCycle(String loanId) async {
    final cycles = await _cycleRepo.getPendingCyclesByLoan(loanId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      return cycles.firstWhere((c) {
        final startDate = DateTime(
          c.periodStartDate.year,
          c.periodStartDate.month,
          c.periodStartDate.day,
        );
        final endDate = DateTime(
          c.periodEndDate.year,
          c.periodEndDate.month,
          c.periodEndDate.day,
        );
        return !today.isBefore(startDate) && !today.isAfter(endDate);
      });
    } catch (_) {
      return null;
    }
  }
}
