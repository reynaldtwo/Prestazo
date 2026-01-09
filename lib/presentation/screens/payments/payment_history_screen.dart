import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/utils/currency_utils.dart';

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
        title: Text(S.of(context).historyTitle),
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
          title: S.of(context).error,
          message: error.toString(),
          onRetry: () => ref.invalidate(allPaymentsProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long,
              title: S.of(context).noPaymentsTitle,
              message: S.of(context).noPaymentsMsg,
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
    var amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final interestPaid = (payment['interest_paid'] as num?)?.toDouble() ?? 0.0;
    final principalPaid =
        (payment['principal_paid'] as num?)?.toDouble() ?? 0.0;
    final customerName =
        payment['customer_name'] as String? ?? S.of(context).customer;
    final paymentDate = payment['created_at'] != null
        ? DateTime.tryParse(payment['created_at'] as String)
        : null;
    final notes = payment['notes'] as String?;
    final paymentCurrency = payment['payment_currency'] as String?;
    final currencySymbol = paymentCurrency != null
        ? CurrencyUtils.getCurrencySymbol(paymentCurrency)
        : null;

    final loanCurrencyCode = payment['loan_currency_code'] as String?;
    final loanCurrencySymbol = loanCurrencyCode != null
        ? CurrencyUtils.getCurrencySymbol(loanCurrencyCode)
        : currencySymbol; // Fallback to payment symbol if loan currency missing

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
                        '${_formatDate(context, paymentDate)} • ${S.of(context).receiptNumber}${payment['receipt_number'] ?? '---'}',
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
              MoneyDisplay(
                amount: amount,
                size: MoneyDisplaySize.medium,
                currencySymbol: currencySymbol,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MoneyLabel(
                  label: S.of(context).interest,
                  amount: interestPaid,
                  currencySymbol: loanCurrencySymbol,
                ),
              ),
              Expanded(
                child: MoneyLabel(
                  label: S.of(context).capital,
                  amount: principalPaid,
                  currencySymbol: loanCurrencySymbol,
                ),
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

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return S.of(context).dateToday;
    if (diff == 1) return S.of(context).dateYesterday;
    if (diff < 7) {
      return S.of(context).dateDaysAgo(diff.toString());
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
