import 'package:flutter/material.dart';
import '../constants/app_status.dart';
import '../theme/app_typography.dart';
import '../../core/localization/locale_provider.dart';

/// Status badge for visual status indication
/// Uses [AppStatus] to determine colors and labels
class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppStatus.getColor(status);
    // Use localized label if available, otherwise fallback to default
    final label = customLabel ?? _getLocalizedLabel(context, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompact) ...[
            Icon(_getIconForStatus(status), size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style:
                (isCompact
                        ? AppTypography.labelSmall
                        : AppTypography.labelMedium)
                    .copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _getLocalizedLabel(BuildContext context, String status) {
    try {
      final s = S.of(context);
      switch (status) {
        // LOANS
        case AppStatus.loanActive:
          return s.statusActive;
        case AppStatus.loanOverdue:
          return s.statusInMora;
        case AppStatus.loanClosed:
          return s.statusClosed;
        case AppStatus.loanLegal:
          return 'Legal'; // Need to add if missing, or use fallback

        // CYCLES
        case AppStatus.cyclePending:
          return s.statusPending; // "Pendiente"
        case AppStatus.cyclePaid:
          return s.statusPaid; // "Pagado"
        case AppStatus.cyclePartial:
          return 'Parcial'; // Need key?
        case AppStatus.cycleOverdue:
          return s.statusOverdue; // "Vencido"
        case AppStatus.cycleAnulled:
          return 'Anulado';

        // CUSTOMERS
        case AppStatus.customerActive:
          return s.statusActive;
        case AppStatus.customerInactive:
          return s.statusInactive;

        // PAYMENTS
        case AppStatus.paymentValid:
          return 'Valid'; // Use key if available
        case AppStatus.paymentVoided:
          return 'Anulado';

        default:
          return AppStatus.getLabel(status);
      }
    } catch (_) {
      return AppStatus.getLabel(status);
    }
  }

  IconData _getIconForStatus(String status) {
    // Basic mapping for common statuses
    switch (status) {
      case AppStatus.loanActive:
      // AppStatus.customerActive is same string 'ACTIVE'
      case AppStatus.paymentValid:
        return Icons.check_circle_outline;
      case AppStatus.loanOverdue:
      case AppStatus.cycleOverdue:
        return Icons.warning_amber_outlined;
      case AppStatus.loanClosed:
        // AppStatus.cycleClosed is same string 'CLOSED'
        return Icons.check_circle;
      case AppStatus.cyclePending:
        return Icons.schedule;
      case AppStatus.cyclePaid:
        return Icons.paid;
      case AppStatus.paymentVoided:
      case AppStatus.customerInactive:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

/// Quick indicator dot for compact status display
class StatusDot extends StatelessWidget {
  final String status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppStatus.getColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}
