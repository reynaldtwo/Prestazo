import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../core/localization/locale_provider.dart';

/// Payment history screen - Shows all registered payments
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Historial de Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allPaymentsProvider),
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppError(
          title: 'Error',
          message: error.toString(),
          onRetry: () => ref.invalidate(allPaymentsProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long,
              title: 'Sin pagos registrados',
              message: 'Los pagos registrados aparecerán aquí',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allPaymentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PaymentCard(payment: payment),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/payment/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final interestPaid = (payment['interest_paid'] as num?)?.toDouble() ?? 0.0;
    final principalPaid =
        (payment['principal_paid'] as num?)?.toDouble() ?? 0.0;
    final customerName = payment['customer_name'] as String? ?? 'Cliente';
    final paymentDate = payment['payment_date'] != null
        ? DateTime.tryParse(payment['payment_date'] as String)
        : null;
    final notes = payment['notes'] as String?;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payment,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (paymentDate != null)
                      Text(
                        '${_formatDate(paymentDate)} • ${S.of(context).receiptNumber}${payment['receipt_number'] ?? '---'}',
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
              MoneyDisplay(amount: amount, size: MoneyDisplaySize.medium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MoneyLabel(label: 'Interés', amount: interestPaid),
              ),
              Expanded(
                child: MoneyLabel(label: 'Capital', amount: principalPaid),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
