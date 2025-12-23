import 'package:flutter/material.dart';
import '../constants/app_status.dart';
import '../theme/app_typography.dart';

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
    final label = customLabel ?? AppStatus.getLabel(status);

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
          // We don't have icons in AppStatus yet, but we can infer or skip for now.
          // The previous version had icons.
          // For now, let's omit the icon to simplify or relying on text.
          // Or we can add getIcon to AppStatus later.
          // Given the "Visual Excellence" requirement, icons are nice.
          // I will use a local helper map for icons if needed, but for now removing icons is safer
          // than guessing. The previous implementation had icons.
          // Let's add a simple icon mapper here to maintain visual quality.
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
