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
  /// Note: Uses string values directly to avoid unreachable case warnings
  /// when constants share the same string value (e.g., loanActive = customerActive = 'ACTIVE')
  static Color getColor(String status) {
    switch (status) {
      // Success / Active (ACTIVE, VALID)
      case 'ACTIVE':
      case 'VALID':
        return AppColors.success;

      // Danger / Urgent
      case 'IN_MORA':
      case 'OVERDUE':
      case 'LEGAL':
        return AppColors.danger;

      // Neutral / History
      case 'CLOSED':
      case 'PAID':
      case 'INACTIVE':
      case 'VOIDED':
      case 'ANULLED':
        return const Color(0xFF757575);

      // Warning / Pending
      case 'PENDING':
        return const Color(0xFFF57F17);

      // Info
      case 'PARTIAL':
        return AppColors.info;

      default:
        return AppColors.primary;
    }
  }

  /// Get localized label for status
  /// Note: Uses string values directly to avoid unreachable case warnings
  static String getLabel(String status) {
    switch (status) {
      // ACTIVE applies to loans, customers
      case 'ACTIVE':
        return 'Activo';
      case 'IN_MORA':
        return 'En Mora';
      case 'CLOSED':
        return 'Cerrado';
      case 'LEGAL':
        return 'Legal';

      // CYCLES
      case 'PENDING':
        return 'Pendiente';
      case 'PAID':
        return 'Pagado';
      case 'PARTIAL':
        return 'Parcial';
      case 'OVERDUE':
        return 'Vencido';
      case 'ANULLED':
        return 'Anulado';

      // CUSTOMERS
      case 'INACTIVE':
        return 'Inactivo';

      // PAYMENTS
      case 'VALID':
        return 'Completado';
      case 'VOIDED':
        return 'Anulado';

      default:
        return status;
    }
  }

  /// Get localized label using S class
  static String getLocalizedLabel(BuildContext context, String status) {
    // We need to import localization, but since this is a pure logic file,
    // it's better to accept S or use S.of(context) if imported.
    // However, AppStatus is in core/constants.
    // We will dynamic lookup or just map basic statuses.
    // Ideally, we move this logic to the UI or import S.
    // For now, let's keep it simple and Map strings if S is not available,
    // but better to actually use S for real localization.
    try {
      // Dynamic import workaround or just copied logic?
      // Better: The caller (StatusBadge) has context, so it can look up S.of(context)
      // and pass the localized string.
      // But StatusBadge relies on this helper.
      // Let's implement a simple mapper here that mimics S but using a manual map if needed,
      // OR better, change this signature to use a helper that doesn't depend on S directly
      // but returns the key for S? No, that's complex.
      //
      // Simplest: We won't import S here to avoid circular deps if S depends on AppStatus (unlikely).
      // But let's check imports. S is in locale_provider.dart.
      // constants shouldn't depend on providers.
      // So we will NOT put this here. We will handle logic in StatusBadge.
      return getLabel(status); // Fallback
    } catch (e) {
      return status;
    }
  }
}
