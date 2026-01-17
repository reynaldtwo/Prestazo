import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:prestamos_app/data/models/payment_frequency.dart';
import 'package:prestamos_app/data/repositories/payment_frequency_repository.dart';

/// Proveedor para el repositorio [PaymentFrequencyRepository].
final paymentFrequencyRepositoryProvider = Provider<PaymentFrequencyRepository>(
  (ref) {
    return PaymentFrequencyRepository(DatabaseHelper());
  },
);

/// Proveedor de notificador asíncrono para la lista completa de frecuencias de pago.
final paymentFrequenciesProvider =
    AsyncNotifierProvider<PaymentFrequenciesNotifier, List<PaymentFrequency>>(
      () {
        return PaymentFrequenciesNotifier();
      },
    );

/// Notificador para gestionar la lista de frecuencias de pago.
class PaymentFrequenciesNotifier extends AsyncNotifier<List<PaymentFrequency>> {
  late PaymentFrequencyRepository _repository;

  @override
  Future<List<PaymentFrequency>> build() async {
    _repository = ref.read(paymentFrequencyRepositoryProvider);
    return _repository.getAll();
  }

  /// Refresca la lista de frecuencias desde el repositorio.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll());
  }

  /// Agrega una nueva frecuencia de pago.
  Future<void> add(PaymentFrequency frequency) async {
    await _repository.create(frequency);
    await refresh();
  }

  /// Actualiza una frecuencia de pago existente.
  Future<void> updateFrequency(PaymentFrequency frequency) async {
    await _repository.update(frequency);
    await refresh();
  }

  /// Elimina una frecuencia de pago por su ID.
  Future<void> delete(String id) async {
    await _repository.delete(id);
    await refresh();
  }

  /// Verifica si una frecuencia está siendo usada por algún préstamo activo.
  Future<bool> isUsed(String id) async {
    return _repository.isUsedByActiveLoan(id);
  }
}

/// Proveedor para obtener la lista de frecuencias de pago activas.
final activePaymentFrequenciesProvider = FutureProvider<List<PaymentFrequency>>(
  (ref) async {
    final repo = ref.watch(paymentFrequencyRepositoryProvider);
    return repo.getActive();
  },
);
