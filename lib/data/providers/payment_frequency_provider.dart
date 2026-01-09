import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/payment_frequency.dart';
import '../repositories/payment_frequency_repository.dart';

final paymentFrequencyRepositoryProvider = Provider<PaymentFrequencyRepository>(
  (ref) {
    return PaymentFrequencyRepository(DatabaseHelper());
  },
);

final paymentFrequenciesProvider =
    AsyncNotifierProvider<PaymentFrequenciesNotifier, List<PaymentFrequency>>(
      () {
        return PaymentFrequenciesNotifier();
      },
    );

class PaymentFrequenciesNotifier extends AsyncNotifier<List<PaymentFrequency>> {
  late PaymentFrequencyRepository _repository;

  @override
  Future<List<PaymentFrequency>> build() async {
    _repository = ref.read(paymentFrequencyRepositoryProvider);
    return _repository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll());
  }

  Future<void> add(PaymentFrequency frequency) async {
    await _repository.create(frequency);
    await refresh();
  }

  Future<void> updateFrequency(PaymentFrequency frequency) async {
    await _repository.update(frequency);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await refresh();
  }

  Future<bool> isUsed(String id) async {
    return _repository.isUsedByActiveLoan(id);
  }
}

final activePaymentFrequenciesProvider = FutureProvider<List<PaymentFrequency>>(
  (ref) async {
    final repo = ref.watch(paymentFrequencyRepositoryProvider);
    return repo.getActive();
  },
);
