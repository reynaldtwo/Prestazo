import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/billing_cycle.dart';
import '../../services/interest_calculation_service.dart';
import 'database_providers.dart';
import 'loan_provider.dart';

/// State for billing cycles list
class BillingCyclesState {
  final List<BillingCycle> cycles;
  final bool isLoading;
  final String? error;

  const BillingCyclesState({
    this.cycles = const [],
    this.isLoading = false,
    this.error,
  });

  BillingCyclesState copyWith({
    List<BillingCycle>? cycles,
    bool? isLoading,
    String? error,
  }) {
    return BillingCyclesState(
      cycles: cycles ?? this.cycles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for billing cycles by loan (FutureProvider)
final billingCyclesByLoanProvider =
    FutureProvider.family<List<BillingCycle>, String>((ref, loanId) async {
      final repo = ref.watch(billingCycleRepositoryProvider);
      ref.watch(refreshTriggerProvider);
      return repo.getBillingCyclesByLoan(loanId);
    });

/// Provider for pending billing cycles by loan
final pendingBillingCyclesProvider =
    FutureProvider.family<List<BillingCycle>, String>((ref, loanId) async {
      final repo = ref.watch(billingCycleRepositoryProvider);
      ref.watch(refreshTriggerProvider);
      return repo.getPendingCyclesByLoan(loanId);
    });

/// Parameters for loan calculation
class LoanCalculationParams {
  final String loanId;
  final String paymentType;
  final DateTime? paymentDate;
  final int refreshTrigger; // Forces recalculation when data changes

  const LoanCalculationParams({
    required this.loanId,
    this.paymentType =
        'VIEW', // VIEW = just display, CANCEL, MIXED, INTEREST, PRINCIPAL
    this.paymentDate,
    this.refreshTrigger = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanCalculationParams &&
          loanId == other.loanId &&
          paymentType == other.paymentType &&
          paymentDate?.day == other.paymentDate?.day &&
          refreshTrigger == other.refreshTrigger;

  @override
  int get hashCode =>
      loanId.hashCode ^ paymentType.hashCode ^ refreshTrigger.hashCode;
}

/// CENTRALIZED Provider for loan calculations - SINGLE SOURCE OF TRUTH
/// Use this provider for ALL loan interest/debt calculations in UI
final loanCalculationProvider =
    FutureProvider.family<LoanCalculationResult, LoanCalculationParams>((
      ref,
      params,
    ) async {
      // Make reactive: Watch the loan
      final loanAsync = ref.watch(loanByIdProvider(params.loanId));

      // If loan is loading or error, we can't calculate yet.
      // Option: Return default or rethrow.
      // Unwrap async value:
      final loan = loanAsync.value;
      if (loan == null) {
        // If loading, we could throw or wait. If null (not found), throw.
        if (loanAsync.isLoading) throw const AsyncLoading(); // Wait for loan
        throw Exception('Loan not found');
      }

      // Make reactive: Watch the pending cycles
      final cyclesAsync = ref.watch(
        pendingBillingCyclesProvider(params.loanId),
      );

      // Wait for cycles to load before calculating
      if (cyclesAsync.isLoading) {
        throw const AsyncLoading(); // Wait for cycles
      }
      if (cyclesAsync.hasError) {
        throw cyclesAsync.error!;
      }
      final pendingCycles = cyclesAsync.value ?? [];

      // Get settings (reactive)
      final settingsRepo = ref.watch(settingsRepositoryProvider);
      final settings = await settingsRepo.getSettings();
      final dailyAccrualEnabled = settings.dailyAccrualEnabled ?? false;

      // Calculate using centralized service
      final service = InterestCalculationService.instance;
      return service.calculateTotalDebt(
        loan: loan,
        pendingCycles: pendingCycles,
        paymentDate: params.paymentDate ?? DateTime.now(),
        paymentType: params.paymentType,
        dailyAccrualEnabled: dailyAccrualEnabled,
      );
    });
