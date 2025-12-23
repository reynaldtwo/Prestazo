/// Service Providers
///
/// Riverpod providers for business logic services.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/services.dart';
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
