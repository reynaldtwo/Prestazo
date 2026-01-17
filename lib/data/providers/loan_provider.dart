import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';
import 'package:prestamos_app/data/providers/service_providers.dart';

/// State for loans list
class LoansState {
  /// Crea el estado para la lista de préstamos.
  const LoansState({
    this.loans = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  /// Lista de todos los préstamos cargados.
  final List<Loan> loans;

  /// Indica si los datos se están cargando.
  final bool isLoading;

  /// Mensaje de error si la carga falló.
  final String? error;

  /// Estado por el cual filtrar (ej: 'ACTIVE', 'PAID').
  final String? filterStatus;

  /// Crea una copia del estado con los campos proporcionados actualizados.
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

  /// Filtra y obtiene solo los préstamos con estado 'ACTIVE'.
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
  /// Crea un [LoansNotifier] e inicia la carga de préstamos.
  LoansNotifier(this._ref) : super(const LoansState()) {
    loadLoans();
  }
  final Ref _ref;

  /// Load all loans
  Future<void> loadLoans() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(loanRepositoryProvider);
      final loans = await repo.getAllLoans();
      state = state.copyWith(loans: loans, isLoading: false);
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add loan without predefined cycles - automatically creates first billing cycle
  /// Returns the created loan with loanNumber assigned, or null on failure
  Future<Loan?> addSimpleLoan(Loan loan) async {
    try {
      final loanRepo = _ref.read(loanRepositoryProvider);
      final customerRepo = _ref.read(customerRepositoryProvider);

      // Insert the loan (returns loan with loanNumber assigned)
      final createdLoan = await loanRepo.insertLoan(loan);

      // Get customer for metadata (not frequency - use loan.billingFrequency instead)
      final customer = await customerRepo.getCustomerById(loan.customerId);
      if (customer != null) {
        // Calculate first due date based on disbursement date and LOAN frequency
        // Note: Subtract 1 because start date counts as day 1
        // So for 15-day cycle: start + 14 = end date (day 15)
        // For DAILY: start + 0 = end date (day 1)

        // Insert the loan (returns loan with loanNumber assigned)
        final createdLoan = await loanRepo.insertLoan(loan);

        final cycleService = _ref.read(billingCycleServiceProvider);
        await cycleService.generateInitialSchedule(createdLoan);
      }

      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return createdLoan;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Cierra un préstamo con el estado especificado (e.g., CANCELED, PAI_IN_FULL).
  Future<bool> closeLoan(String loanId, String closeStatus) async {
    try {
      final repo = _ref.read(loanRepositoryProvider);
      await repo.closeLoan(loanId, closeStatus);
      await loadLoans();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    state = state.copyWith();
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
