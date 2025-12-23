/// Payment Validation Service
///
/// Centralized service for payment validation.
/// Handles:
/// - Validation rules by payment type (CANCEL, INTEREST, MIXED, PRINCIPAL)
/// - Amount validation
/// - Cycle requirement validation
library;

import '../data/models/billing_cycle.dart';
import '../data/models/loan.dart';
import 'interest_calculation_service.dart';

/// Validation result with success status and error message
class ValidationResult {
  final bool isValid;
  final String? errorTitle;
  final String? errorMessage;

  const ValidationResult.success()
    : isValid = true,
      errorTitle = null,
      errorMessage = null;

  const ValidationResult.failure({
    required this.errorTitle,
    required this.errorMessage,
  }) : isValid = false;
}

/// Service for payment validation
class PaymentValidationService {
  final InterestCalculationService _interestService;

  PaymentValidationService({InterestCalculationService? interestService})
    : _interestService = interestService ?? InterestCalculationService.instance;

  /// Validate payment based on type and amount
  ///
  /// [loan] - The loan being paid
  /// [pendingCycles] - List of pending billing cycles
  /// [amount] - Payment amount
  /// [paymentType] - Type: CANCEL, INTEREST, MIXED, PRINCIPAL
  /// [paymentDate] - Date of payment
  /// [dailyAccrualEnabled] - Whether mora days are charged
  /// [daysBeforeCycleForCapital] - Days before cycle end to allow capital payment
  ValidationResult validate({
    required Loan loan,
    required List<BillingCycle> pendingCycles,
    required double amount,
    required String paymentType,
    required DateTime paymentDate,
    required bool dailyAccrualEnabled,
    int daysBeforeCycleForCapital = 10,
  }) {
    if (amount <= 0) {
      return const ValidationResult.failure(
        errorTitle: 'Monto Inválido',
        errorMessage: 'El monto debe ser mayor a cero.',
      );
    }

    // Calculate interest based on payment type using CENTRALIZED service
    final calculation = _interestService.calculateTotalDebt(
      loan: loan,
      pendingCycles: pendingCycles,
      paymentDate: paymentDate,
      paymentType: paymentType,
      dailyAccrualEnabled: dailyAccrualEnabled,
    );

    // Use CENTRALIZED overdueInterest from LoanCalculationResult
    // This is the SINGLE SOURCE OF TRUTH for overdue interest calculation
    final overdueInterestOnly = calculation.overdueInterest;

    switch (paymentType) {
      case 'CANCEL':
        return _validateCancel(amount, calculation.totalDebt);

      case 'INTEREST':
        return _validateInterestOnly(amount, overdueInterestOnly);

      case 'MIXED':
        return _validateMixed(amount, overdueInterestOnly);

      case 'PRINCIPAL':
        return _validatePrincipal(
          amount: amount,
          loan: loan,
          pendingCycles: pendingCycles,
          paymentDate: paymentDate,
          cycleInterest: overdueInterestOnly,
          daysBeforeCycle: daysBeforeCycleForCapital,
        );

      default:
        return const ValidationResult.failure(
          errorTitle: 'Tipo Inválido',
          errorMessage: 'Tipo de pago no reconocido.',
        );
    }
  }

  /// Validate CANCEL payment
  /// Amount must equal total debt (capital + all interest + partial)
  ValidationResult _validateCancel(double amount, double totalDebt) {
    // Allow small tolerance for floating point
    if ((amount - totalDebt).abs() > 0.02) {
      return ValidationResult.failure(
        errorTitle: 'Monto Incorrecto para Cancelar',
        errorMessage:
            'Para cancelar el préstamo, el monto debe ser exactamente C\$ ${_formatMoney(totalDebt)} (Capital + Intereses).',
      );
    }
    return const ValidationResult.success();
  }

  /// Validate INTEREST only payment
  /// Amount must not exceed cycle interest (partial allowed)
  ValidationResult _validateInterestOnly(double amount, double cycleInterest) {
    // Allow partial interest payments
    if (amount > cycleInterest + 0.01) {
      return ValidationResult.failure(
        errorTitle: 'Monto Excede Intereses',
        errorMessage:
            'El monto (C\$ ${_formatMoney(amount)}) excede los intereses pendientes (C\$ ${_formatMoney(cycleInterest)}).\n\nSeleccione "Mixto" para abonar al capital.',
      );
    }
    return const ValidationResult.success();
  }

  /// Validate MIXED payment
  /// Amount must be greater than interest (to include some principal)
  ValidationResult _validateMixed(double amount, double cycleInterest) {
    if (cycleInterest > 0 && amount <= cycleInterest) {
      return ValidationResult.failure(
        errorTitle: 'Monto Insuficiente para Mixto',
        errorMessage:
            'Para un pago mixto, el monto debe ser mayor a los intereses pendientes (C\$ ${_formatMoney(cycleInterest)}).\n\nSi solo desea pagar intereses, seleccione "Solo Interés".',
      );
    }
    return const ValidationResult.success();
  }

  /// Validate PRINCIPAL only payment
  /// Only allowed if no interest pending and within allowed days
  ValidationResult _validatePrincipal({
    required double amount,
    required Loan loan,
    required List<BillingCycle> pendingCycles,
    required DateTime paymentDate,
    required double cycleInterest,
    required int daysBeforeCycle,
  }) {
    // Check if there's pending interest
    if (cycleInterest > 0) {
      return ValidationResult.failure(
        errorTitle: 'Intereses Pendientes',
        errorMessage:
            'No puede abonar solo al capital porque tiene intereses pendientes (C\$ ${_formatMoney(cycleInterest)}).\n\nDebe pagar los intereses primero.',
      );
    }

    // Check if we're within allowed days of cycle start
    // Find the current (running) cycle
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
    } catch (_) {
      // No current cycle found - allow principal payment
    }

    if (currentCycle != null) {
      final endDate = DateTime(
        currentCycle.periodEndDate.year,
        currentCycle.periodEndDate.month,
        currentCycle.periodEndDate.day,
      );
      final daysUntilEnd = endDate.difference(today).inDays;

      // Requirement 3: Only allow capital payment if cycle is just starting (daysUntilEnd is high)
      // "si se puede agregar o abonar al capital siempre y cuando el ciclo esté iniciando"
      // Example logic: Cycle ends in 15 days. daysBeforeCycle = 10.
      // If daysUntilEnd (e.g. 14) > 10, then OK.
      // If daysUntilEnd (e.g. 5) < 10, then NO.
      // The parameter name daysBeforeCycleForCapital suggests "before how many days from end it is forbidden".

      if (daysUntilEnd < daysBeforeCycle) {
        return ValidationResult.failure(
          errorTitle: 'Ciclo Por Concluir',
          errorMessage:
              'No se puede abonar al capital porque el ciclo está por concluir.\n\nFaltan $daysUntilEnd días para el corte. Solo se permite abonar al capital cuando faltan más de $daysBeforeCycle días.',
        );
      }
    }

    // Check amount doesn't exceed principal
    if (amount > loan.principalBalance + 0.01) {
      return ValidationResult.failure(
        errorTitle: 'Monto Excede Capital',
        errorMessage:
            'El monto (C\$ ${_formatMoney(amount)}) excede el capital pendiente (C\$ ${_formatMoney(loan.principalBalance)}).',
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
