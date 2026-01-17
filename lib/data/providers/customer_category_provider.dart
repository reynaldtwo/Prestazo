import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/customer_category.dart';
import 'package:prestamos_app/data/repositories/customer_category_repository.dart';

/// Provider for customer category repository
final customerCategoryRepositoryProvider = Provider<CustomerCategoryRepository>(
  (ref) {
    return CustomerCategoryRepository();
  },
);

/// Provider for list of all customer categories
final customerCategoriesProvider =
    AsyncNotifierProvider<CustomerCategoriesNotifier, List<CustomerCategory>>(
      CustomerCategoriesNotifier.new,
    );

/// Notifier for managing customer categories state
class CustomerCategoriesNotifier extends AsyncNotifier<List<CustomerCategory>> {
  @override
  Future<List<CustomerCategory>> build() async {
    final repo = ref.read(customerCategoryRepositoryProvider);
    return repo.getAll();
  }

  /// Refresh categories list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(customerCategoryRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Add new category
  Future<CustomerCategory> add({
    required String name,
    String? colorHex,
    int sortOrder = 0,
  }) async {
    final repo = ref.read(customerCategoryRepositoryProvider);
    final category = await repo.create(
      name: name,
      colorHex: colorHex,
      sortOrder: sortOrder,
    );
    await refresh();
    return category;
  }

  /// Update existing category
  Future<void> updateCategory(CustomerCategory category) async {
    final repo = ref.read(customerCategoryRepositoryProvider);
    await repo.update(category);
    await refresh();
  }

  /// Delete category (returns false if in use)
  Future<bool> delete(String categoryId) async {
    final repo = ref.read(customerCategoryRepositoryProvider);
    final result = await repo.delete(categoryId);
    if (result) {
      await refresh();
    }
    return result;
  }

  /// Get customers using a category
  Future<List<dynamic>> getCustomersWithCategory(String categoryId) async {
    final repo = ref.read(customerCategoryRepositoryProvider);
    return repo.getCustomersWithCategory(categoryId);
  }
}
