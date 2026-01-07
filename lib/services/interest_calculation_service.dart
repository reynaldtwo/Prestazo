/// Interest Calculation Service.
///
/// Centralized service for all interest calculations in the app.
/// This service handles:
/// - Monthly and biweekly interest calculation
/// - Partial interest (days mora) calculation
/// - Total debt calculation based on payment type
/// - Cycle interest calculations
library;

import '../data/models/billing_cycle.dart';
import '../data/models/loan.dart';

/// CENTRALIZED Loan Calculation Result
///
/// This class is the SINGLE SOURCE OF TRUTH for all loan calculations.
/// All UI components, validation, and reports MUST use this.
class LoanCalculationResult {
  /// List of overdue cycles (due date < today)
  final List<BillingCycle> overdueCycles;

  /// Current running cycle (due date >= today), if any
  final BillingCycle? currentCycle;

  /// Interest from overdue cycles (ALWAYS charged in full)
  final double overdueInterest;

  /// Interest from current cycle (varies by payment type)
  final double currentCycleInterest;

  /// Proportional interest for days elapsed in current cycle (CANCEL only)
  final double proportionalInterest;

  /// Number of overdue cycles
  int get overdueCyclesCount => overdueCycles.length;

  /// Days elapsed in current cycle (for proportional)
  final int partialDays;

  /// Total pending interest (overdue + current as applicable)
  final double totalPendingInterest;

  /// Principal balance
  final double principalBalance;

  /// Total debt (principal + totalPendingInterest)
  double get totalDebt => principalBalance + totalPendingInterest;

  const LoanCalculationResult({
    required this.overdueCycles,
    required this.currentCycle,
    required this.overdueInterest,
    required this.currentCycleInterest,
    required this.proportionalInterest,
    required this.partialDays,
    required this.totalPendingInterest,
    required this.principalBalance,
  });

  @override
  String toString() =>
      'LoanCalculationResult('
      'overdueInterest: $overdueInterest, '
      'currentCycleInterest: $currentCycleInterest, '
      'proportionalInterest: $proportionalInterest, '
      'totalPendingInterest: $totalPendingInterest, '
      'totalDebt: $totalDebt, '
      'partialDays: $partialDays, '
      'overdueCyclesCount: $overdueCyclesCount)';
}

/// Alias for backward compatibility
typedef InterestCalculationResult = LoanCalculationResult;

/// Result of payment allocation calculation
class PaymentDistribution {
  final double toOverdueInterest;
  final double toCurrentInterest;
  final double toPrincipal;
  final double remainingAmount;

  const PaymentDistribution({
    required this.toOverdueInterest,
    required this.toCurrentInterest,
    required this.toPrincipal,
    required this.remainingAmount,
  });
}

/// Service for centralized interest calculations
class InterestCalculationService {
  InterestCalculationService._();

  static final InterestCalculationService instance =
      InterestCalculationService._();

  // ============================================================
  // STATIC HELPER METHODS - Can be called without instance
  // ============================================================

  /// Calculate total overdue interest from a list of billing cycles.
  /// ONLY includes cycles where due_date < today.
  /// This is the SINGLE SOURCE OF TRUTH for pending interest calculations.
  static double calculateOverdueInterest(List<BillingCycle> cycles) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final result = cycles
        .where((c) => c.dueDate.isBefore(todayOnly))
        .fold<double>(0, (sum, c) => sum + c.interestPending);
    return (result * 100).round() / 100; // Round to 2 decimals
  }

  /// Get only overdue cycles from a list (due_date < today).
  static List<BillingCycle> getOverdueCycles(List<BillingCycle> cycles) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return cycles.where((c) => c.dueDate.isBefore(todayOnly)).toList();
  }

  /// Get count of overdue cycles
  static int getOverdueCyclesCount(List<BillingCycle> cycles) {
    return getOverdueCycles(cycles).length;
  }

  /// Check if any cycle is overdue
  static bool hasOverdueCycles(List<BillingCycle> cycles) {
    return getOverdueCyclesCount(cycles) > 0;
  }

  /// Calculate days since oldest overdue cycle
  static int getDaysOverdue(List<BillingCycle> cycles) {
    final overdue = getOverdueCycles(cycles);
    if (overdue.isEmpty) return 0;

    // Sort by due date ascending to get oldest
    overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final oldestDueDate = overdue.first.dueDate;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return todayOnly.difference(oldestDueDate).inDays;
  }

  // ============================================================
  // INSTANCE METHODS
  // ============================================================

  /// Calculate how a payment amount should be allocated
  /// Centralizes the business rules: Overdue > Current > Principal
  PaymentDistribution calculatePaymentAllocation({
    required Loan loan,
    required double paymentAmount,
    required List<BillingCycle> pendingCycles,
    required String paymentType, // CANCEL, INTEREST, MIXED, PRINCIPAL
    required bool dailyAccrualEnabled,
    DateTime? paymentDate,
  }) {
    // 1. Calculate debt state first
    final debtCalc = calculateTotalDebt(
      loan: loan,
      pendingCycles: pendingCycles,
      paymentDate: paymentDate ?? DateTime.now(),
      paymentType: paymentType,
      dailyAccrualEnabled: dailyAccrualEnabled,
    );

    double remaining = paymentAmount;
    double toOverdue = 0;
    double toCurrent = 0;
    double toPrincipal = 0;

    // 2. Allocating to Overdue Interest (Priority 1)
    if (remaining > 0 && debtCalc.overdueInterest > 0) {
      toOverdue = remaining >= debtCalc.overdueInterest
          ? debtCalc.overdueInterest
          : remaining;
      remaining -= toOverdue;
    }

    // 3. Allocating to Current Interest (Priority 2)
    // Only if payment type allows it (Logic handled by calculateTotalDebt returning correct currentCycleInterest/proportionalInterest)
    // We use the 'currentCycleInterest' or 'proportionalInterest' from result depending on type
    double targetCurrentInterest = 0;

    if (paymentType == 'CANCEL' && dailyAccrualEnabled) {
      targetCurrentInterest = debtCalc.proportionalInterest;
    } else {
      targetCurrentInterest = debtCalc.currentCycleInterest;
    }

    if (remaining > 0 && targetCurrentInterest > 0) {
      toCurrent = remaining >= targetCurrentInterest
          ? targetCurrentInterest
          : remaining;
      remaining -= toCurrent;
    }

    // 4. Allocating to Principal (Priority 3)
    if (paymentType != 'INTEREST' && remaining > 0) {
      final maxPrincipal = loan.principalBalance;
      toPrincipal = remaining > maxPrincipal ? maxPrincipal : remaining;
      // remaining -= toPrincipal; // Not strictly needed for result but good for tracking
    }

    return PaymentDistribution(
      toOverdueInterest: _roundMoney(toOverdue),
      toCurrentInterest: _roundMoney(toCurrent),
      toPrincipal: _roundMoney(toPrincipal),
      remainingAmount: _roundMoney(remaining > 0 ? remaining - toPrincipal : 0),
    );
  }

  /// Calculate total debt for a loan based on payment type and settings
  ///
  /// [loan] - The loan being paid
  /// [pendingCycles] - List of pending billing cycles (includes OVERDUE + PENDING)
  /// [paymentDate] - Date of payment
  /// [paymentType] - Type of payment: CANCEL, INTEREST, MIXED, PRINCIPAL
  /// [dailyAccrualEnabled] - Whether to charge partial interest for current cycle days
  InterestCalculationResult calculateTotalDebt({
    required Loan loan,
    required List<BillingCycle> pendingCycles,
    required DateTime paymentDate,
    required String paymentType,
    required bool dailyAccrualEnabled,
  }) {
    final paymentDateOnly = DateTime(
      paymentDate.year,
      paymentDate.month,
      paymentDate.day,
    );

    // SAFETY CHECK: If loan is fully paid (principal < 1), no pending interest
    // SAFETY CHECK: If loan is fully paid (principal < 1) OR status is CLOSED/PAID
    if (loan.principalBalance < 1 || !loan.isActive) {
      return LoanCalculationResult(
        overdueCycles: [],
        currentCycle: null,
        overdueInterest: 0,
        currentCycleInterest: 0,
        proportionalInterest: 0,
        partialDays: 0,
        totalPendingInterest: 0,
        principalBalance: loan.principalBalance,
      );
    }

    // Separate OVERDUE cycles from CURRENT (running) cycle
    final overdueCycles = <BillingCycle>[];
    BillingCycle? currentCycle;

    for (final cycle in pendingCycles) {
      final dueDate = DateTime(
        cycle.dueDate.year,
        cycle.dueDate.month,
        cycle.dueDate.day,
      );

      if (dueDate.isBefore(paymentDateOnly)) {
        // Cycle is overdue (due date passed)
        overdueCycles.add(cycle);
      } else {
        // Cycle is current (due date not yet passed)
        // Take the earliest one as current
        if (currentCycle == null ||
            cycle.periodStartDate.isBefore(currentCycle.periodStartDate)) {
          currentCycle = cycle;
        }
      }
    }

    // Sum all OVERDUE cycle interest (full interest for completed cycles)
    final overdueInterest = overdueCycles.fold<double>(
      0,
      (sum, c) => sum + c.interestPending,
    );
    double currentCycleInterest = 0;
    double partialInterest = 0;
    int partialDays = 0;

    if (currentCycle != null) {
      final cycleStart = DateTime(
        currentCycle.periodStartDate.year,
        currentCycle.periodStartDate.month,
        currentCycle.periodStartDate.day,
      );

      // For CANCEL with dailyAccrualEnabled: calculate proportional interest
      if (paymentType == 'CANCEL' && dailyAccrualEnabled) {
        // Days elapsed in current cycle (from cycle start to payment date)
        partialDays = paymentDateOnly.difference(cycleStart).inDays + 1;
        if (partialDays < 1) partialDays = 1;

        // Calculate daily interest and multiply by days
        final monthlyInterest =
            loan.principalBalance * (loan.monthlyInterestRate / 100);
        final dailyInterest = monthlyInterest / 30;

        partialInterest = dailyInterest * partialDays;
        currentCycleInterest = partialInterest;
      } else if (paymentType == 'CANCEL') {
        // CANCEL without dailyAccrualEnabled: charge full current cycle
        currentCycleInterest = currentCycle.interestPending;
      } else if (paymentType == 'INTEREST') {
        // INTEREST (Solo Interés): DO NOT include current cycle per fix.md #3A
        // "excepto intereses de los días del ciclo corriente"
        currentCycleInterest = 0;
      } else if (paymentType == 'MIXED') {
        // MIXED: DO NOT include current cycle per fix.md #3
        // "los intereses de los días del ciclo corriente no se consideran"
        currentCycleInterest = 0;
      } else {
        // PRINCIPAL or other: no current cycle interest
        currentCycleInterest = 0;
      }
    }

    final totalPendingInterest = overdueInterest + currentCycleInterest;

    return LoanCalculationResult(
      overdueCycles: overdueCycles,
      currentCycle: currentCycle,
      overdueInterest: _roundMoney(overdueInterest),
      currentCycleInterest: _roundMoney(currentCycleInterest),
      proportionalInterest: _roundMoney(partialInterest),
      partialDays: partialDays,
      totalPendingInterest: _roundMoney(totalPendingInterest),
      principalBalance: loan.principalBalance,
    );
  }

  /// Calculate monthly interest for a loan
  double calculateMonthlyInterest(Loan loan) {
    return _roundMoney(
      loan.principalBalance * (loan.monthlyInterestRate / 100),
    );
  }

  /// Calculate biweekly interest for a loan (half of monthly)
  double calculateBiweeklyInterest(Loan loan) {
    return _roundMoney(calculateMonthlyInterest(loan) / 2);
  }

  /// Calculate daily interest rate based on monthly rate
  double calculateDailyInterest(Loan loan) {
    return _roundMoney(calculateMonthlyInterest(loan) / 30);
  }

  /// Round to 2 decimal places for money
  double _roundMoney(double value) => (value * 100).round() / 100;
}
