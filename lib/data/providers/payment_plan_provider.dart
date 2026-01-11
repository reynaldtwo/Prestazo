import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/payment_plan_repository.dart';
import '../models/payment_plan.dart';

/// Provider for payment plan repository
final paymentPlanRepositoryProvider = Provider<PaymentPlanRepository>((ref) {
  return PaymentPlanRepository();
});

/// Provider for list of all payment plans
final paymentPlansProvider =
    AsyncNotifierProvider<PaymentPlansNotifier, List<PaymentPlan>>(
      PaymentPlansNotifier.new,
    );

/// Provider for active payment plans only
final activePaymentPlansProvider = FutureProvider<List<PaymentPlan>>((ref) {
  final repo = ref.read(paymentPlanRepositoryProvider);
  return repo.getActive();
});

/// Notifier for managing payment plans state
class PaymentPlansNotifier extends AsyncNotifier<List<PaymentPlan>> {
  @override
  Future<List<PaymentPlan>> build() async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    return repo.getAll();
  }

  /// Refresh plans list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(paymentPlanRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Add new payment plan
  Future<void> add(PaymentPlan plan) async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    await repo.insert(plan);
    await refresh();
  }

  /// Update existing payment plan
  Future<void> updatePlan(PaymentPlan plan) async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    await repo.update(plan);
    await refresh();
  }

  /// Delete payment plan (returns false if has active loans)
  Future<bool> delete(String planId) async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    final result = await repo.delete(planId);
    if (result) {
      await refresh();
    }
    return result;
  }

  /// Toggle plan active status (returns false if cannot deactivate)
  Future<bool> toggleActive(String planId) async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    final result = await repo.toggleActive(planId);
    if (result) {
      await refresh();
    }
    return result;
  }

  /// Check if plan has active loans
  Future<bool> hasActiveLoans(String planId) async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    return repo.hasActiveLoans(planId);
  }

  /// Get plans applicable to a category
  Future<List<PaymentPlan>> getPlansForCategory(String? categoryId) async {
    final repo = ref.read(paymentPlanRepositoryProvider);
    return repo.getPlansForCategory(categoryId);
  }
}
