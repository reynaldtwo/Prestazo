import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';
import 'package:prestamos_app/data/providers/loan_provider.dart';
import 'package:prestamos_app/services/interest_calculation_service.dart';

/// State for billing cycles list
/// Estado que representa la lista de ciclos de facturación, incluyendo su carga y errores.
class BillingCyclesState {
  /// Crea una instancia de [BillingCyclesState].
  const BillingCyclesState({
    this.cycles = const [],
    this.isLoading = false,
    this.error,
  });

  /// Lista de ciclos de facturación obtenidos.
  final List<BillingCycle> cycles;

  /// Indica si los ciclos se están cargando actualmente.
  final bool isLoading;

  /// Mensaje de error si la carga falló.
  final String? error;

  /// Crea una copia de este estado con los campos proporcionados actualizados.
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
      final _ = ref.watch(refreshTriggerProvider);
      return repo.getBillingCyclesByLoan(loanId);
    });

/// Provider for pending billing cycles by loan
final pendingBillingCyclesProvider =
    FutureProvider.family<List<BillingCycle>, String>((ref, loanId) async {
      final repo = ref.watch(billingCycleRepositoryProvider);
      final _ = ref.watch(refreshTriggerProvider);
      return repo.getPendingCyclesByLoan(loanId);
    });

/// Parámetros necesarios para realizar cálculos de intereses y deudas de un préstamo.
@immutable
class LoanCalculationParams {
  // Forces recalculation when data changes

  /// Crea los parámetros para el cálculo del préstamo.
  const LoanCalculationParams({
    required this.loanId,
    this.paymentType =
        'VIEW', // VIEW = just display, CANCEL, MIXED, INTEREST, PRINCIPAL
    this.paymentDate,
    this.refreshTrigger = 0,
  });

  /// ID del préstamo a calcular.
  final String loanId;

  /// Tipo de operación (VIEW, CANCEL, MIXED, etc).
  final String paymentType;

  /// Fecha en la que se simula el pago o consulta.
  final DateTime? paymentDate;

  /// Disparador para forzar la actualización del cálculo.
  final int refreshTrigger;

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
        if (loanAsync.isLoading) {
          // ignore: only_throw_errors // AsyncLoading is thrown to signal suspension in this specific architecture
          throw const AsyncLoading<LoanCalculationResult>(); // Wait for loan
        }
        throw Exception('Loan not found');
      }

      // Make reactive: Watch the pending cycles
      final cyclesAsync = ref.watch(
        pendingBillingCyclesProvider(params.loanId),
      );

      // Wait for cycles to load before calculating
      if (cyclesAsync.isLoading) {
        // ignore: only_throw_errors // AsyncLoading is thrown to signal suspension in this specific architecture
        throw const AsyncLoading<LoanCalculationResult>(); // Wait for cycles
      }
      if (cyclesAsync.hasError) {
        final error = cyclesAsync.error!;
        if (error is Exception) throw error;
        if (error is Error) throw error;
        throw Exception(error.toString());
      }
      final pendingCycles = cyclesAsync.value ?? [];

      // Get settings (reactive)
      final settingsRepo = ref.watch(settingsRepositoryProvider);
      final settings = await settingsRepo.getSettings();
      final dailyAccrualEnabled = settings.dailyAccrualEnabled;

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
