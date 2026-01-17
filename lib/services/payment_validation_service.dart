/// Payment Validation Service
///
/// Centralized service for payment validation.
/// Handles:
/// - Validation rules by payment type (CANCEL, INTEREST, MIXED, PRINCIPAL)
/// - Amount validation
/// - Cycle requirement validation
library;

import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/l10n/app_localizations.dart';
import 'package:prestamos_app/services/interest_calculation_service.dart';

/// Validation result with success status and error message
/// Resultado de una validación con estado de éxito y mensaje de error opcional.
class ValidationResult {
  /// Crea un resultado de validación exitoso.
  const ValidationResult.success()
    : isValid = true,
      errorTitle = null,
      errorMessage = null;

  /// Crea un resultado de validación fallido con título y mensaje de error.
  const ValidationResult.failure({
    required this.errorTitle,
    required this.errorMessage,
  }) : isValid = false;

  /// Indica si la validación fue exitosa.
  final bool isValid;

  /// Título descriptivo del error, si aplica.
  final String? errorTitle;

  /// Mensaje detallado del error, si aplica.
  final String? errorMessage;
}

/// Servicio encargado de la validación de pagos según las reglas de negocio.
class PaymentValidationService {
  /// Crea un [PaymentValidationService] con el servicio de cálculo de interés proporcionado.
  PaymentValidationService({InterestCalculationService? interestService})
    : _interestService = interestService ?? InterestCalculationService.instance;
  final InterestCalculationService _interestService;

  /// Valida una intención de pago contra el estado del préstamo y ciclos pendientes.
  ValidationResult validate({
    required Loan loan,
    required List<BillingCycle> pendingCycles,
    required double amount,
    required String paymentType,
    required DateTime paymentDate,
    required bool dailyAccrualEnabled,
    required S s,
    int daysBeforeCycleForCapital = 10,
    bool enableCapitalRestriction = true,
    String currencySymbol = r'C$',
  }) {
    if (amount <= 0) {
      return ValidationResult.failure(
        errorTitle: s.invalidAmountTitle,
        errorMessage: s.invalidAmountMessage,
      );
    }

    final calculation = _interestService.calculateTotalDebt(
      loan: loan,
      pendingCycles: pendingCycles,
      paymentDate: paymentDate,
      paymentType: paymentType,
      dailyAccrualEnabled: dailyAccrualEnabled,
    );

    final overdueInterestOnly = calculation.overdueInterest;

    switch (paymentType) {
      case 'CANCEL':
        return _validateCancel(
          amount,
          calculation.totalDebt,
          currencySymbol,
          s,
        );

      case 'INTEREST':
        return _validateInterestOnly(
          amount,
          overdueInterestOnly,
          currencySymbol,
          s,
        );

      case 'MIXED':
        return _validateMixed(amount, overdueInterestOnly, currencySymbol, s);

      case 'PRINCIPAL':
        return _validatePrincipal(
          amount: amount,
          loan: loan,
          pendingCycles: pendingCycles,
          paymentDate: paymentDate,
          cycleInterest: overdueInterestOnly,
          daysBeforeCycle: daysBeforeCycleForCapital,
          enableRestriction: enableCapitalRestriction,
          s: s,
          currencySymbol: currencySymbol,
        );

      default:
        return ValidationResult.failure(
          errorTitle: s.invalidPaymentTypeTitle,
          errorMessage: s.invalidPaymentTypeMessage,
        );
    }
  }

  ValidationResult _validateCancel(
    double amount,
    double totalDebt,
    String currencySymbol,
    S s,
  ) {
    if ((amount - totalDebt).abs() > 0.02) {
      return ValidationResult.failure(
        errorTitle: s.incorrectCancelAmountTitle,
        errorMessage: s.incorrectCancelAmountMessage(
          currencySymbol,
          _formatMoney(totalDebt),
        ),
      );
    }
    return const ValidationResult.success();
  }

  ValidationResult _validateInterestOnly(
    double amount,
    double cycleInterest,
    String currencySymbol,
    S s,
  ) {
    if (amount > cycleInterest + 0.01) {
      return ValidationResult.failure(
        errorTitle: s.amountExceedsInterestTitle,
        errorMessage: s.amountExceedsInterestMessage(
          currencySymbol,
          _formatMoney(amount),
          _formatMoney(cycleInterest),
        ),
      );
    }
    return const ValidationResult.success();
  }

  ValidationResult _validateMixed(
    double amount,
    double cycleInterest,
    String currencySymbol,
    S s,
  ) {
    if (cycleInterest > 0 && amount <= cycleInterest) {
      return ValidationResult.failure(
        errorTitle: s.insufficientMixedAmountTitle,
        errorMessage: s.insufficientMixedAmountMessage(
          currencySymbol,
          _formatMoney(cycleInterest),
        ),
      );
    }
    return const ValidationResult.success();
  }

  ValidationResult _validatePrincipal({
    required double amount,
    required Loan loan,
    required List<BillingCycle> pendingCycles,
    required DateTime paymentDate,
    required double cycleInterest,
    required int daysBeforeCycle,
    required bool enableRestriction,
    required S s,
    required String currencySymbol,
  }) {
    if (cycleInterest > 0) {
      return ValidationResult.failure(
        errorTitle: s.pendingInterestTitle,
        errorMessage: s.pendingInterestMessage(
          currencySymbol,
          _formatMoney(cycleInterest),
        ),
      );
    }

    if (enableRestriction) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      BillingCycle? currentCycle;
      try {
        currentCycle = pendingCycles.firstWhere((c) {
          final startDate = DateTime(
            c.periodStartDate.year,
            c.periodStartDate.month,
            c.periodStartDate.day,
          );
          final endDate = DateTime(
            c.periodEndDate.year,
            c.periodEndDate.month,
            c.periodEndDate.day,
          );
          return !today.isBefore(startDate) && !today.isAfter(endDate);
        });
      } on Exception catch (_) {}

      if (currentCycle != null) {
        final endDate = DateTime(
          currentCycle.periodEndDate.year,
          currentCycle.periodEndDate.month,
          currentCycle.periodEndDate.day,
        );
        final daysUntilEnd = endDate.difference(today).inDays;

        if (daysUntilEnd < daysBeforeCycle) {
          return ValidationResult.failure(
            errorTitle: s.cycleConcluding,
            errorMessage: s.errorCycleConcluding(daysUntilEnd, daysBeforeCycle),
          );
        }
      }
    }

    if (amount > loan.principalBalance + 0.01) {
      return ValidationResult.failure(
        errorTitle: s.amountExceedsPrincipalTitle,
        errorMessage: s.amountExceedsPrincipalMessage(
          currencySymbol,
          _formatMoney(amount),
          _formatMoney(loan.principalBalance),
        ),
      );
    }

    return const ValidationResult.success();
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
