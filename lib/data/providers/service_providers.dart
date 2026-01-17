/// Service Providers
///
/// Riverpod providers for business logic services.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';
import 'package:prestamos_app/data/providers/payment_plan_provider.dart';
import 'package:prestamos_app/data/repositories/cobrar_repository.dart';
import 'package:prestamos_app/data/repositories/payment_plan_repository.dart';
import 'package:prestamos_app/services/services.dart';

/// Provider for BillingCycleService
final billingCycleServiceProvider = Provider<BillingCycleService>((ref) {
  return BillingCycleService(
    cycleRepository: ref.read(billingCycleRepositoryProvider),
    customerRepository: ref.read(customerRepositoryProvider),
    loanRepository: ref.read(loanRepositoryProvider),
    planRepository: PaymentPlanRepository(
      dbHelper: ref.read(databaseHelperProvider),
    ),
  );
});

/// Provider for PaymentValidationService
final paymentValidationServiceProvider = Provider<PaymentValidationService>((
  ref,
) {
  return PaymentValidationService();
});

/// Provider for BackupService (singleton)
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService.instance;
});

/// Provider para el servicio de cálculo de intereses.
final interestCalculationServiceProvider = Provider<InterestCalculationService>(
  (ref) {
    return InterestCalculationService.instance;
  },
);

/// Provider for PdfGeneratorService
final pdfGeneratorServiceProvider = Provider<PdfGeneratorService>((ref) {
  return PdfGeneratorService();
});

/// Provider for PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    paymentRepository: ref.read(paymentRepositoryProvider),
    loanRepository: ref.read(loanRepositoryProvider),
    billingCycleRepository: ref.read(billingCycleRepositoryProvider),
    interestService: ref.read(interestCalculationServiceProvider),
    paymentPlanRepository: ref.read(paymentPlanRepositoryProvider),
  );
});

/// Provider for CobrarRepository
final cobrarRepositoryProvider = Provider<CobrarRepository>((ref) {
  return CobrarRepository(databaseHelper: ref.read(databaseHelperProvider));
});

/// Provider for CurrencyService (async loading)
final currencyServiceProvider = FutureProvider<CurrencyService>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  return CurrencyService(
    exchangeRateRepo: ref.read(exchangeRateRepositoryProvider),
    settings: settings,
  );
});
