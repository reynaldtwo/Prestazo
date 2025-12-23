import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized definitions for Loan and Cycle statuses and their colors
class AppStatus {
  // Loan Statuses
  static const String loanActive = 'ACTIVE';
  static const String loanOverdue = 'IN_MORA';
  static const String loanClosed = 'CLOSED';
  static const String loanLegal = 'LEGAL';
  static const String loanPaid = 'PAID'; // Some legacy loans might use this?

  // Billing Cycle Statuses
  static const String cyclePending = 'PENDING';
  static const String cyclePaid = 'PAID';
  static const String cyclePartial = 'PARTIAL';
  static const String cycleOverdue = 'OVERDUE';
  static const String cycleAnulled = 'ANULLED';
  static const String cycleClosed = 'CLOSED';

  // Customer Statuses
  static const String customerActive = 'ACTIVE';
  static const String customerInactive = 'INACTIVE';

  // Payment Statuses
  static const String paymentValid = 'VALID';
  static const String paymentVoided = 'VOIDED';

  /// Get color for a given status
  static Color getColor(String status) {
    switch (status) {
      // Success / Active
      case loanActive:
      case customerActive:
      case paymentValid:
        return AppColors.success;

      // Danger / Urgent
      case loanOverdue:
      case cycleOverdue:
      case loanLegal:
        return AppColors.danger;

      // Neutral / History
      case loanClosed:
      case cyclePaid:
      case customerInactive:
      case paymentVoided:
        return const Color(0xFF757575);

      // Warning / Pending
      case cyclePending:
        return const Color(0xFFF57F17);

      // Info
      case cyclePartial:
        return AppColors.info;

      default:
        return AppColors.primary;
    }
  }

  /// Get localized label for status
  static String getLabel(String status) {
    switch (status) {
      // LOANS
      case loanActive:
        return 'Activo';
      case loanOverdue:
        return 'En Mora';
      case loanClosed:
        return 'Cerrado';
      case loanLegal:
        return 'Legal';

      // CYCLES
      case cyclePending:
        return 'Pendiente';
      case cyclePaid:
        return 'Pagado';
      case cyclePartial:
        return 'Parcial';
      case cycleOverdue:
        return 'Vencido';
      case cycleAnulled:
        return 'Anulado';

      // CUSTOMERS
      case customerActive:
        return 'Activo';
      case customerInactive:
        return 'Inactivo';

      // PAYMENTS
      case paymentValid:
        return 'Completado';
      case paymentVoided:
        return 'Anulado';

      default:
        return status;
    }
  }
}
