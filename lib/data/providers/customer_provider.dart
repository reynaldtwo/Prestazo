import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import 'database_providers.dart';

/// State for customers list
class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Get filtered customers based on search query
  List<Customer> get filteredCustomers {
    if (searchQuery.isEmpty) return customers;
    final query = searchQuery.toLowerCase();
    return customers.where((c) {
      return c.fullName.toLowerCase().contains(query) ||
          (c.alias?.toLowerCase().contains(query) ?? false) ||
          (c.phone?.contains(query) ?? false);
    }).toList();
  }

  List<Customer> get activeCustomers {
    return customers.where((c) => c.status == 'ACTIVE').toList();
  }
}

/// Notifier for managing customers state
class CustomersNotifier extends StateNotifier<CustomersState> {
  final Ref _ref;

  CustomersNotifier(this._ref) : super(const CustomersState()) {
    loadCustomers();
  }

  /// Load all customers
  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(customerRepositoryProvider);
      final customers = await repo.getAllCustomers();
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add new customer
  Future<bool> addCustomer(Customer customer) async {
    try {
      final repo = _ref.read(customerRepositoryProvider);
      await repo.insertCustomer(customer);
      await loadCustomers();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      final repo = _ref.read(customerRepositoryProvider);
      await repo.updateCustomer(customer);
      await loadCustomers();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Deactivate customer
  Future<bool> deactivateCustomer(String customerId) async {
    try {
      final repo = _ref.read(customerRepositoryProvider);

      // Check if customer has active loans
      final hasLoans = await repo.hasActiveLoans(customerId);
      if (hasLoans) {
        state = state.copyWith(
          error: 'No se puede desactivar un cliente con préstamos activos',
        );
        return false;
      }

      await repo.deactivateCustomer(customerId);
      await loadCustomers();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reactivate customer
  Future<bool> activateCustomer(String customerId) async {
    try {
      final repo = _ref.read(customerRepositoryProvider);
      await repo.activateCustomer(customerId);
      await loadCustomers();
      _ref.read(refreshTriggerProvider.notifier).state++;
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for customers state
final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
      ref.watch(refreshTriggerProvider);
      return CustomersNotifier(ref);
    });

/// Provider for getting a single customer by ID
final customerByIdProvider = FutureProvider.family<Customer?, String>((
  ref,
  customerId,
) async {
  final repo = ref.watch(customerRepositoryProvider);
  ref.watch(refreshTriggerProvider);
  return repo.getCustomerById(customerId);
});

/// Provider for customer count
final customerCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  ref.watch(refreshTriggerProvider);
  return repo.getCustomerCount();
});
