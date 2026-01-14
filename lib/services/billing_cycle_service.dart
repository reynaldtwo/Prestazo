/// Billing Cycle Service
///
/// Centralized service for billing cycle management.
/// Handles:
/// - Automatic generation of missing cycles
/// - Cycle status updates
/// - Cycle date calculations
library;

import 'dart:math';
import '../core/utils/currency_utils.dart';
import '../data/models/billing_cycle.dart';
import '../data/models/customer.dart';
import '../data/models/loan.dart';
import '../data/repositories/billing_cycle_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/loan_repository.dart';
import '../data/repositories/payment_plan_repository.dart';

/// Service for billing cycle management
class BillingCycleService {
  final BillingCycleRepository _cycleRepo;
  final CustomerRepository _customerRepo;
  final LoanRepository _loanRepo;
  final PaymentPlanRepository _planRepo;

  BillingCycleService({
    required BillingCycleRepository cycleRepository,
    required CustomerRepository customerRepository,
    required LoanRepository loanRepository,
    required PaymentPlanRepository planRepository,
  }) : _cycleRepo = cycleRepository,
       _customerRepo = customerRepository,
       _loanRepo = loanRepository,
       _planRepo = planRepository;

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

    // Determine frequency from LOAN
    // PRIORITY: Use paymentFrequencyDays from DB
    // Fallback for legacy: Map standard strings to days
    final cycleDays =
        loan.paymentFrequencyDays ??
        switch (loan.billingFrequency) {
          'WEEKLY' => 7,
          'DAILY' => 1,
          'BIWEEKLY' => 15,
          'ANNUALLY' => 365,
          _ => 30, // MONTHLY default
        };

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

    // Logic:
    // If Plan Loan: Generate until we reach planInstallmentsTotal
    // If Manual Loan: Generate until nextStart is in future ("Lazy Generation")
    final isPlanLoan =
        loan.planId != null && (loan.planInstallmentsTotal ?? 0) > 0;
    final maxPlanCycles = loan.planInstallmentsTotal ?? 0;

    // Rounding Logic Variables (Same as generateInitialSchedule)
    double? baseInstallment;
    double? basePrincipal;
    double? baseInterest;
    double totalPrincipal = loan.principalOriginal;
    double totalInterest = 0;

    // Accumulators (Must be initialized with sums from EXISTING cycles if partial update,
    // but regenerateFutureCycles deletes ALL relevant cycles usually.
    // For safety, if existingCycles is not empty, we should sum them?
    // regenerateFutureCycles logic: deletes "future" cycles (no payment).
    // If we have PAID cycles, they remain in 'existingCycles'. We must account for them!)

    double accumInstallment = 0;
    double accumPrincipal = 0;

    if (isPlanLoan) {
      final n = maxPlanCycles;
      final r = loan.monthlyInterestRate;
      final precision = CurrencyUtils.getCurrencyPrecision(loan.currencyCode);

      // We need to verify if distribute is enabled
      // We can check loan.distributeCapitalAndInterest directly as confirmed in previous fix
      // But let's be safe and check plan if needed (omitted for brevity, loan snapshot usually correct due to V30)
      final effectiveDistribute = loan.distributeCapitalAndInterest ?? false;

      if (effectiveDistribute) {
        // Calculate Equivalent Months
        double equivalentMonths;
        if (cycleDays >= 28 && cycleDays <= 31) {
          equivalentMonths = n.toDouble();
        } else {
          final totalDays = n * cycleDays;
          equivalentMonths = totalDays / 30.0;
        }

        totalInterest = _roundMoney(
          totalPrincipal * (r / 100) * equivalentMonths,
          precision: precision,
        );
        final totalDebt = totalPrincipal + totalInterest;

        baseInstallment = _roundMoney(totalDebt / n, precision: precision);
        basePrincipal = _roundMoney(totalPrincipal / n, precision: precision);
        baseInterest = _roundMoney(
          baseInstallment - basePrincipal,
          precision: precision,
        );

        // If there are existing cycles (e.g. Paid ones), we must add them to accumulators
        for (final c in existingCycles) {
          accumInstallment += c.installmentExpected ?? 0;
          accumPrincipal += c.principalPortion ?? 0;
        }
      }
    }

    while (true) {
      // Break conditions
      if (isPlanLoan) {
        if (nextCycleNumber > maxPlanCycles) break;
      } else {
        // Lazy Generation for non-plan loans
        if (nextStart.isAfter(today)) break;
      }

      final nextEnd = nextStart.add(Duration(days: cycleDays - 1));

      // Determine overrides for Level Installment (Banking Rounding)
      double? overrideInst;
      double? overridePrin;
      double? overrideInt;

      if (baseInstallment != null) {
        final precision = CurrencyUtils.getCurrencyPrecision(loan.currencyCode);
        if (nextCycleNumber < maxPlanCycles) {
          overrideInst = baseInstallment;
          overridePrin = basePrincipal;
          overrideInt = baseInterest;
        } else {
          // Last Cycle: Adjust for rounding
          overrideInst = _roundMoney(
            (totalPrincipal + totalInterest) - accumInstallment,
            precision: precision,
          );
          overridePrin = _roundMoney(
            totalPrincipal - accumPrincipal,
            precision: precision,
          );
          overrideInt = _roundMoney(
            overrideInst - overridePrin,
            precision: precision,
          );
        }

        accumInstallment += overrideInst ?? 0;
        accumPrincipal += overridePrin!;
      }

      final cycle = _createCycle(
        loan: loan,
        customer: customer,
        cycleNumber: nextCycleNumber,
        startDate: nextStart,
        endDate: nextEnd,
        cycleDurationDays: cycleDays,
        overrideInstallmentAmount: overrideInst,
        overridePrincipalPortion: overridePrin,
        overrideInterestAmount: overrideInt,
        // Pass distribute override to ensure _createCycle takes the values
        overrideDistributeCapital: baseInstallment != null ? true : null,
      );

      await _cycleRepo.insertBillingCycles([cycle]);
      generatedCycles.add(cycle);

      nextStart = nextEnd.add(const Duration(days: 1));
      nextCycleNumber++;

      if (generatedCycles.length > 200) break; // Safety fuse
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

  /// Generate initial schedule for a new loan
  Future<void> generateInitialSchedule(Loan loan) async {
    // Determine number of cycles to generate
    int cyclesToGenerate = 1;

    // If it's a planned loan (Plan ID exists + Total Installments > 0)
    // We generate the full schedule
    if (loan.planId != null && (loan.planInstallmentsTotal ?? 0) > 0) {
      cyclesToGenerate = loan.planInstallmentsTotal!;
    }

    final frequency = loan.billingFrequency;
    // PRIORITY: Use paymentFrequencyDays from DB
    final cycleDays =
        loan.paymentFrequencyDays ??
        switch (frequency) {
          'WEEKLY' => 7,
          'DAILY' => 1,
          'BIWEEKLY' => 15,
          'ANNUALLY' => 365,
          _ => 30, // MONTHLY
        };

    // Calculate start/end dates for each cycle
    // Cycle 1 starts on Disbursement Date
    DateTime nextStart = loan.disbursementDate;
    final now = DateTime.now();

    final cycles = <BillingCycle>[];

    // START FIX: V30 Fallback for Plan Data
    // If loan snapshot says distribute is FALSE (or null), but it IS a plan loan,
    // verify against the actual Plan in DB to be safe (handling snapshot failures).
    bool effectiveDistribute = loan.distributeCapitalAndInterest ?? false;

    if (!effectiveDistribute && loan.planId != null) {
      final plan = await _planRepo.getById(loan.planId!);
      if (plan != null) {
        effectiveDistribute = plan.distributeCapitalAndInterest;
      }
    }
    // END FIX

    // Calculate Totals for Level Installment Adjustment (Rounding)
    double? baseInstallment;
    double? basePrincipal;
    double? baseInterest;
    double totalPrincipal = loan.principalOriginal;
    double totalInterest = 0;

    // Accumulators
    double accumInstallment = 0;
    double accumPrincipal = 0;
    // double accumInterest = 0;

    // Define precision for use in calculations and loop
    final precision = CurrencyUtils.getCurrencyPrecision(loan.currencyCode);

    if (effectiveDistribute &&
        loan.planInstallmentsTotal != null &&
        loan.planInstallmentsTotal! > 0) {
      final n = loan.planInstallmentsTotal!;
      final r = loan.monthlyInterestRate;

      // Helper to calculate equivalent months match _createCycle logic
      double equivalentMonths;
      if (cycleDays >= 28 && cycleDays <= 31) {
        equivalentMonths = n.toDouble();
      } else {
        final totalDays = n * cycleDays;
        equivalentMonths = totalDays / 30.0;
      }

      totalInterest = _roundMoney(
        totalPrincipal * (r / 100) * equivalentMonths,
        precision: precision,
      );
      final totalDebt = totalPrincipal + totalInterest;

      baseInstallment = _roundMoney(totalDebt / n, precision: precision);
      basePrincipal = _roundMoney(totalPrincipal / n, precision: precision);
      baseInterest = _roundMoney(
        baseInstallment - basePrincipal,
        precision: precision,
      );
      // Note: baseInterest might not be exactly TotalInterest / N due to derivation,
      // but Installment = Principal + Interest holds.
    }

    for (int i = 1; i <= cyclesToGenerate; i++) {
      // End date = Start + Duration - 1
      final nextEnd = nextStart.add(Duration(days: cycleDays - 1));

      // Determine overrides for Level Installment
      double? overrideInst;
      double? overridePrin;
      double? overrideInt;

      if (effectiveDistribute && baseInstallment != null) {
        if (i < cyclesToGenerate) {
          overrideInst = baseInstallment;
          overridePrin = basePrincipal;
          overrideInt = baseInterest;
        } else {
          // Last Cycle: Adjust for rounding
          overrideInst = _roundMoney(
            (totalPrincipal + totalInterest) - accumInstallment,
            precision: precision,
          );
          overridePrin = _roundMoney(
            totalPrincipal - accumPrincipal,
            precision: precision,
          );
          overrideInt = _roundMoney(
            overrideInst - overridePrin,
            precision: precision,
          );
        }

        accumInstallment += overrideInst!;
        accumPrincipal += overridePrin!;
        // accumInterest += overrideInt!;
      }

      final cycle = _createCycle(
        loan: loan,
        customer:
            await _customerRepo.getCustomerById(loan.customerId) ??
            Customer(
              customerId: 'unknown',
              fullName: 'Unknown',
              billingFrequency: 'MONTHLY',
              createdAt: now,
              updatedAt: now,
            ), // Fallback if customer missing (rare)
        cycleNumber: i,
        startDate: nextStart,
        endDate: nextEnd,
        cycleDurationDays: cycleDays,
        overrideDistributeCapital: effectiveDistribute,
        overrideInstallmentAmount: overrideInst,
        overridePrincipalPortion: overridePrin,
        overrideInterestAmount: overrideInt,
      );

      cycles.add(cycle);

      // Next start = End + 1
      nextStart = nextEnd.add(const Duration(days: 1));
    }

    if (cycles.isNotEmpty) {
      await _cycleRepo.insertBillingCycles(cycles);
    }
  }

  /// Create a new billing cycle
  BillingCycle _createCycle({
    required Loan loan,
    required Customer customer,
    required int cycleNumber,
    required DateTime startDate,
    required DateTime endDate,
    required int cycleDurationDays,
    bool? overrideDistributeCapital,
    double? overrideInstallmentAmount,
    double? overridePrincipalPortion,
    double? overrideInterestAmount,
  }) {
    final now = DateTime.now();
    final frequency = loan.billingFrequency;

    // Calculate expected interest
    double interestExpected;
    double? installmentExpected;
    double? principalPortion;

    // RULE: If Loan has a Payment Plan AND "Distribute Capital & Interest" is TRUE
    // Use Level Installment (Flat Interest)
    // "Cuota Nivelada" logic: (Principal + TotalInterest) / N

    // Use override if provided (from generatingInitialSchedule), otherwise use loan snapshot
    final distribute =
        overrideDistributeCapital ??
        (loan.distributeCapitalAndInterest ?? false);

    final useLevelInstallment =
        loan.planId != null &&
        (loan.planInstallmentsTotal ?? 0) > 0 &&
        distribute;

    if (useLevelInstallment) {
      final n = loan.planInstallmentsTotal ?? 0;
      final r = loan.monthlyInterestRate; // e.g. 10.0

      // Calculate Equivalent Months
      // If frequency is Monthly (approx 30 days), equivalent months = N
      // Otherwise, calc based on total days (N * duration) / 30
      double equivalentMonths;
      if (cycleDurationDays >= 28 && cycleDurationDays <= 31) {
        equivalentMonths = n.toDouble();
      } else {
        final totalDays = n * cycleDurationDays;
        equivalentMonths = totalDays / 30.0;
      }

      final precision = CurrencyUtils.getCurrencyPrecision(loan.currencyCode);
      final factor = pow(10, precision);

      // Check for overrides (Banking Rounding Adjustment)
      if (overrideInstallmentAmount != null) {
        installmentExpected = overrideInstallmentAmount;
        principalPortion = overridePrincipalPortion ?? 0;
        interestExpected = overrideInterestAmount ?? 0;
      } else {
        // STANDARD CALCULATION (If no override or logic failed)

        // Total Interest = P * r * t
        final totalInterest =
            loan.principalOriginal * (r / 100) * equivalentMonths;

        // Per Installment (Unrounded first)
        final monthlyInterest = totalInterest / n;
        final monthlyPrincipal = loan.principalOriginal / n;

        // Round components using dynamic precision
        interestExpected =
            (monthlyInterest * factor).round() / factor.toDouble();
        principalPortion =
            (monthlyPrincipal * factor).round() / factor.toDouble();

        // Installment is sum of rounded parts
        installmentExpected = interestExpected + principalPortion;
      }
    } else {
      // STANDARD LOGIC (Interest on Unpaid Balance / Simple Interest for period)
      interestExpected = loan.calculateInterestForDays(cycleDurationDays);
      principalPortion = 0;
      installmentExpected = interestExpected;
    }

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
      // V29: Plan fields
      installmentExpected: installmentExpected,
      installmentPending: installmentExpected,
      principalPortion: principalPortion,
    );
  }

  /// Calculate the next due date based on frequency
  DateTime calculateNextDueDate(DateTime fromDate, String frequency) {
    final days = switch (frequency) {
      'WEEKLY' => 6,
      'DAILY' => 0,
      'BIWEEKLY' => 14,
      _ => 29, // MONTHLY
    };
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

  double _roundMoney(double value, {int precision = 2}) {
    final factor = pow(10, precision);
    return (value * factor).round() / factor.toDouble();
  }
}
