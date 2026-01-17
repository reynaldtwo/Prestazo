import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/payment.dart';
import 'package:prestamos_app/data/models/payment_allocation.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';

/// State for payments list
class PaymentsState {
  /// Crea el estado para la lista de pagos.
  const PaymentsState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.filterDate,
  });

  /// Lista de pagos realizados.
  final List<Payment> payments;

  /// Indica si los pagos se están cargando.
  final bool isLoading;

  /// Mensaje de error, si existe.
  final String? error;

  /// Fecha opcional para filtrar los pagos.
  final DateTime? filterDate;

  /// Crea una copia del estado de pagos con los campos actualizados.
  PaymentsState copyWith({
    List<Payment>? payments,
    bool? isLoading,
    String? error,
    DateTime? filterDate,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterDate: filterDate ?? this.filterDate,
    );
  }

  /// Get total amount
  double get totalAmount {
    return payments.fold(0, (sum, p) => sum + p.amount);
  }
}

/// Notifier for managing payments state
class PaymentsNotifier extends StateNotifier<PaymentsState> {
  /// Crea un [PaymentsNotifier] e inicia la carga de pagos.
  PaymentsNotifier(this._ref) : super(const PaymentsState()) {
    loadPayments();
  }
  final Ref _ref;

  /// Load all payments
  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(paymentRepositoryProvider);
      final payments = await repo.getAllPayments();
      state = state.copyWith(payments: payments, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Register payment with allocations
  Future<Payment?> registerPayment(
    Payment payment,
    List<PaymentAllocation> allocations,
  ) async {
    try {
      final repo = _ref.read(paymentRepositoryProvider);
      final createdPayment = await repo.insertPaymentWithAllocations(
        payment,
        allocations,
      );
      await loadPayments();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return createdPayment;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Register simple payment (capital only)
  Future<bool> registerSimplePayment(Payment payment) async {
    try {
      final repo = _ref.read(paymentRepositoryProvider);
      await repo.insertPayment(payment);
      await loadPayments();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Void payment
  Future<bool> voidPayment(String paymentId, String reason) async {
    try {
      final repo = _ref.read(paymentRepositoryProvider);
      await repo.voidPayment(paymentId, reason);
      await loadPayments();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Set filter date
  void setFilterDate(DateTime? date) {
    state = state.copyWith(filterDate: date);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }
}

/// Provider for payments state
final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>(
  (ref) {
    ref.watch(refreshTriggerProvider);
    return PaymentsNotifier(ref);
  },
);

/// Provider for payments by loan
final paymentsByLoanProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  loanId,
) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentsByLoanId(loanId);
});

/// Provider for payments by customer
final paymentsByCustomerProvider = FutureProvider.family<List<Payment>, String>(
  (ref, customerId) async {
    ref.watch(refreshTriggerProvider);
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.getPaymentsByCustomerId(customerId);
  },
);

/// Provider for today's payments
final todayPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getTodayPayments();
});

/// Provider for total collected today
final totalCollectedTodayProvider = FutureProvider<double>((ref) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getTotalCollectedToday();
});

/// Provider for next receipt number
final nextReceiptNumberProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getAndIncrementReceiptNumber();
});

/// Provider for all payments with customer info (for history screen)
final allPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(refreshTriggerProvider);
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getAllPaymentsWithCustomer();
});

/// Provider for allocations by payment ID
final allocationsByPaymentIdProvider =
    FutureProvider.family<List<PaymentAllocation>, String>((
      ref,
      paymentId,
    ) async {
      final repo = ref.watch(paymentRepositoryProvider);
      return repo.getPaymentAllocations(paymentId);
    });
