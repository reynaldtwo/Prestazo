import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:prestamos_app/data/models/app_settings.dart';
import 'package:prestamos_app/data/repositories/repositories.dart';

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

/// ExchangeRate repository provider
final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ExchangeRateRepository(dbHelper: dbHelper);
});

/// BusinessPolicy repository provider (Financial Convention)
final businessPolicyRepositoryProvider = Provider<BusinessPolicyRepository>((
  ref,
) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BusinessPolicyRepository(databaseHelper: dbHelper);
});
