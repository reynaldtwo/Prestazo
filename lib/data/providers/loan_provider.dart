import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../models/billing_cycle.dart';

import 'database_providers.dart';

/// State for loans list
class LoansState {
  final List<Loan> loans;
  final bool isLoading;
  final String? error;
  final String? filterStatus;

  const LoansState({
    this.loans = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  LoansState copyWith({
    List<Loan>? loans,
    bool? isLoading,
    String? error,
    String? filterStatus,
  }) {
    return LoansState(
      loans: loans ?? this.loans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  List<Loan> get activeLoans {
    return loans.where((l) => l.status == 'ACTIVE').toList();
  }

  /// Get total principal balance
  double get totalPrincipalBalance {
    return activeLoans.fold(0, (sum, loan) => sum + loan.principalBalance);
  }
}

/// Notifier for managing loans state
class LoansNotifier extends StateNotifier<LoansState> {
  final Ref _ref;

  LoansNotifier(this._ref) : super(const LoansState()) {
    loadLoans();
  }

  /// Load all loans
  Future<void> loadLoans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(loanRepositoryProvider);
      final loans = await repo.getAllLoans();
      state = state.copyWith(loans: loans, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add new loan with billing cycles
  Future<bool> addLoan(Loan loan, List<BillingCycle> cycles) async {
    try {
      final loanRepo = _ref.read(loanRepositoryProvider);
      final cycleRepo = _ref.read(billingCycleRepositoryProvider);

      await loanRepo.insertLoan(loan);
      if (cycles.isNotEmpty) {
        await cycleRepo.insertBillingCycles(cycles);
      }

      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add loan without predefined cycles - automatically creates first billing cycle
  /// Returns the created loan with loanNumber assigned, or null on failure
  Future<Loan?> addSimpleLoan(Loan loan) async {
    try {
      final loanRepo = _ref.read(loanRepositoryProvider);
      final cycleRepo = _ref.read(billingCycleRepositoryProvider);
      final customerRepo = _ref.read(customerRepositoryProvider);

      // Insert the loan (returns loan with loanNumber assigned)
      final createdLoan = await loanRepo.insertLoan(loan);

      // Get customer for metadata (not frequency - use loan.billingFrequency instead)
      final customer = await customerRepo.getCustomerById(loan.customerId);
      if (customer != null) {
        // Calculate first due date based on disbursement date and LOAN frequency
        // Note: Subtract 1 because start date counts as day 1
        // So for 15-day cycle: start + 14 = end date (day 15)
        final isBiweekly = loan.billingFrequency == 'BIWEEKLY';
        final daysToAdd = isBiweekly ? 14 : 29;
        final dueDate = loan.disbursementDate.add(Duration(days: daysToAdd));

        // Calculate interest for first cycle
        final interestExpected = isBiweekly
            ? loan.calculateBiweeklyInterest()
            : loan.calculateMonthlyInterest();

        final now = DateTime.now();

        // Create first billing cycle
        final frequency = isBiweekly ? 'BIWEEKLY' : 'MONTHLY';
        final firstCycle = BillingCycle(
          billingCycleId: '${loan.loanId}_cycle_1',
          loanId: loan.loanId,
          cycleNumber: 1,
          frequency: frequency,
          periodStartDate: loan.disbursementDate,
          periodEndDate: dueDate,
          dueDate: dueDate,
          interestExpected: interestExpected,
          interestPaid: 0,
          interestPending: interestExpected,
          status: 'PENDING',
          createdAt: now,
          updatedAt: now,
        );

        await cycleRepo.insertBillingCycle(firstCycle);
      }

      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return createdLoan;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update loan
  Future<bool> updateLoan(Loan loan) async {
    try {
      final repo = _ref.read(loanRepositoryProvider);
      await repo.updateLoan(loan);
      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> closeLoan(String loanId, String closeStatus) async {
    try {
      final repo = _ref.read(loanRepositoryProvider);
      await repo.closeLoan(loanId, closeStatus);
      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a loan and its associated billing cycles
  /// Only allowed if loan has no payments
  Future<bool> deleteLoan(String loanId) async {
    try {
      final loanRepo = _ref.read(loanRepositoryProvider);
      final cycleRepo = _ref.read(billingCycleRepositoryProvider);

      // Delete billing cycles first
      await cycleRepo.deleteBillingCyclesByLoan(loanId);

      // Then delete the loan
      await loanRepo.deleteLoan(loanId);

      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Set filter status
  void setFilterStatus(String? status) {
    state = state.copyWith(filterStatus: status);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for loans state
final loansProvider = StateNotifierProvider<LoansNotifier, LoansState>((ref) {
  ref.watch(refreshTriggerProvider);
  return LoansNotifier(ref);
});

/// Provider for getting a single loan by ID
final loanByIdProvider = FutureProvider.family<Loan?, String>((
  ref,
  loanId,
) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getLoanById(loanId);
});

/// Provider for loans by customer
final loansByCustomerProvider = FutureProvider.family<List<Loan>, String>((
  ref,
  customerId,
) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getLoansByCustomerId(customerId);
});

/// Provider for active loans by customer
final activeLoansByCustomerProvider = FutureProvider.family<List<Loan>, String>(
  (ref, customerId) async {
    ref.watch(refreshTriggerProvider);
    final repo = ref.watch(loanRepositoryProvider);
    return repo.getActiveLoansByCustomerId(customerId);
  },
);

/// Provider for loan count
final loanCountProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getLoanCount(status: 'ACTIVE');
});

/// Provider for total principal balance
final totalPrincipalBalanceProvider = FutureProvider<double>((ref) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getTotalPrincipalBalance();
});

/// Provider for loans with customer info
final loansWithCustomerProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getLoansWithCustomer(status: 'ACTIVE');
});
