import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../repositories/repositories.dart';

/// Global trigger for data refresh
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Database helper provider (singleton)
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Customer repository provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return CustomerRepository(databaseHelper: dbHelper);
});

/// Loan repository provider
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LoanRepository(databaseHelper: dbHelper);
});

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return PaymentRepository(databaseHelper: dbHelper);
});

/// BillingCycle repository provider
final billingCycleRepositoryProvider = Provider<BillingCycleRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BillingCycleRepository(databaseHelper: dbHelper);
});

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SettingsRepository(databaseHelper: dbHelper);
});

/// App settings provider
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSettings();
});
