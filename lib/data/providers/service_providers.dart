/// Service Providers
///
/// Riverpod providers for business logic services.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/services.dart';
import '../repositories/cobrar_repository.dart';
import 'database_providers.dart';

/// Provider for BillingCycleService
final billingCycleServiceProvider = Provider<BillingCycleService>((ref) {
  return BillingCycleService(
    cycleRepository: ref.read(billingCycleRepositoryProvider),
    customerRepository: ref.read(customerRepositoryProvider),
    loanRepository: ref.read(loanRepositoryProvider),
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
  );
});

/// Provider for CobrarRepository
final cobrarRepositoryProvider = Provider<CobrarRepository>((ref) {
  return CobrarRepository(databaseHelper: ref.read(databaseHelperProvider));
});
