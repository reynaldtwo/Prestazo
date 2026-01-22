import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/constants/app_status.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_text_styles.dart';
import 'package:prestamos_app/core/utils/currency_utils.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/providers/providers.dart';

/// Pantalla de detalle del cliente - Vista consolidada de la cuenta con datos reales.
class CustomerDetailScreen extends ConsumerWidget {
  /// Crea una instancia de [CustomerDetailScreen].
  const CustomerDetailScreen({required this.customerId, super.key});

  /// Identificador único del cliente.
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final loansAsync = ref.watch(loansByCustomerProvider(customerId));

    return customerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(S.of(context).customer)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(S.of(context).customer)),
        body: AppError(
          title: S.of(context).error,
          message: error.toString(),
          onRetry: () => ref.invalidate(customerByIdProvider(customerId)),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: Text(S.of(context).customer)),
            body: AppEmptyState(
              icon: Icons.person_off,
              title: S.of(context).customerNotFound,
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Custom app bar with customer info
              _buildSliverAppBar(context, customer, ref),

              // Account summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAccountSummary(context, loansAsync, customer),
                ),
              ),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActions(context),
                ),
              ),

              // Loans section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildLoansSection(context, ref, loansAsync),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    Customer customer,
    WidgetRef ref,
  ) {
    final initials = _getInitials(customer.displayName);
    // Use StatusBadge logic or S manually.
    // Since we used StatusBadge for UI, here we might need manual string or use StatusBadge widget?
    // But this is part of a complex header. Let's use S directly for Active/Inactive
    final statusLabel = customer.isActive
        ? S.of(context).statusActive
        : S.of(context).statusInactive;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.surface,
                    ],
                  )
                : AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.displayName,
                              style: context.textStyles.headlineMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              statusLabel,
                              style: context.textStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Registration date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color.fromARGB(179, 255, 255, 255),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${S.of(context).registeredDate} ${_formatDate(customer.createdAt)}',
                        style: context.textStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            await context.push('/customer/$customerId/edit');
            // Refresh data after editing
            ref.invalidate(customerByIdProvider(customerId));
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            // Handle menu actions
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'deactivate',
              child: Text(S.of(context).deactivateCustomer),
            ),
            PopupMenuItem(
              value: 'history',
              child: Text(S.of(context).viewFullHistory),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSummary(
    BuildContext context,
    AsyncValue<List<Loan>> loansAsync,
    Customer customer,
  ) {
    return loansAsync.when(
      loading: () => AppCard(
        title: S.of(context).accountSummary,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppCard(
        title: S.of(context).accountSummary,
        child: Text('${S.of(context).error}: $e'),
      ),
      data: (loans) {
        final activeLoans = loans
            .where((l) => l.status == AppStatus.loanActive)
            .toList();
        final totalCapital = activeLoans.fold<double>(
          0,
          (sum, l) => sum + l.principalBalance,
        );
        // Calculate expected monthly interest for active loans
        final totalInterestExpected = activeLoans.fold<double>(
          0,
          (sum, l) => sum + l.calculateMonthlyInterest(),
        );

        // Count closed loans
        final closedLoansCount = loans
            .where((l) => l.status == AppStatus.loanClosed)
            .length;

        // Determine currency symbol (Use first active loan's currency or fallback)
        final currencyCode = activeLoans.isNotEmpty
            ? activeLoans.first.currencyCode
            : (loans.isNotEmpty ? loans.first.currencyCode : 'NIO');
        final currencySymbol = CurrencyUtils.getCurrencySymbol(currencyCode);

        return AppCard(
          title: S.of(context).accountSummary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: S.of(context).totalCapital,
                      value: totalCapital,
                      currencySymbol: currencySymbol,
                      icon: Icons.account_balance_wallet,
                      iconColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.info
                          : AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: S.of(context).monthlyInterest,
                      value: totalInterestExpected,
                      currencySymbol: currencySymbol,
                      icon: Icons.schedule,
                      iconColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).closedLoansTitle,
                          style: context.textStyles.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$closedLoansCount',
                          style: context.textStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).activeLoansTitle,
                          style: context.textStyles.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeLoans.length}',
                          style: context.textStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: S.of(context).newLoan,
            icon: Icons.add_card,
            onPressed: () => context.push('/customer/$customerId/loan/new'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: S.of(context).registerPayment,
            icon: Icons.payment,
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                context.push('/payment/new', extra: {'customerId': customerId}),
          ),
        ),
      ],
    );
  }

  Widget _buildLoansSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Loan>> loansAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).loans, style: context.textStyles.titleLarge),
            TextButton(onPressed: () {}, child: Text(S.of(context).viewAll)),
          ],
        ),
        const SizedBox(height: 8),
        loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('${S.of(context).error}: $e'),
          data: (loans) {
            if (loans.isEmpty) {
              return AppEmptyState(
                icon: Icons.receipt_long,
                title: S.of(context).noLoans,
                message: S.of(context).noLoansDesc,
              );
            }

            return Column(
              children: loans
                  .map(
                    (loan) => Dismissible(
                      key: ValueKey(loan.loanId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        // 1. Validation: Check for existing payments
                        final paymentRepo = ref.read(paymentRepositoryProvider);
                        final payments = await paymentRepo.getPaymentsByLoanId(
                          loan.loanId,
                        );

                        if (payments.isNotEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  S.of(context).cannotDeleteWithPayments,
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                          return false;
                        }

                        if (!context.mounted) return false;

                        // 2. Confirmation Dialog
                        return showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(S.of(context).confirmDelete),
                            content: Text(
                              S.of(context).deleteLoanConfirmationMsg,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(S.of(context).cancel),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                ),
                                child: Text(S.of(context).delete),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          await ref
                              .read(loanRepositoryProvider)
                              .deleteLoan(loan.loanId);
                          // Refresh data
                          ref
                            ..invalidate(loansByCustomerProvider(customerId))
                            ..invalidate(customerByIdProvider(customerId));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context).loanDeleted),
                              ),
                            );
                          }
                        } on Exception catch (e) {
                          // Force refresh to "undo" visual removal
                          ref.invalidate(loansByCustomerProvider(customerId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${S.of(context).errorDeleting} $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LoanCard(
                          loan: loan,
                          onTap: () => context.push('/loan/${loan.loanId}'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.currencySymbol,
  });
  final String label;
  final double value;
  final IconData icon;
  final Color iconColor;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(label, style: context.textStyles.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        MoneyDisplay(amount: value, currencySymbol: currencySymbol),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.onTap});
  final Loan loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isClosed = loan.status == AppStatus.loanClosed;
    final currencySymbol = CurrencyUtils.getCurrencySymbol(loan.currencyCode);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '${S.of(context).loan} ${loan.loanNumber != null ? "#${loan.loanNumber}" : ""} ',
                          style: context.textStyles.labelMedium,
                        ),
                        MoneyDisplay(
                          amount: loan.principalOriginal,
                          size: MoneyDisplaySize.small,
                          currencySymbol: currencySymbol,
                        ),
                      ],
                    ),
                    Text(
                      '${S.of(context).rate}: ${loan.monthlyInterestRate.toStringAsFixed(2)}% ${S.of(context).monthly}',
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: loan.status, isCompact: true),
            ],
          ),
          if (!isClosed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MoneyLabel(
                    label: S.of(context).capitalBalance,
                    amount: loan.principalBalance,
                    currencySymbol: currencySymbol,
                  ),
                ),
                Expanded(
                  child: MoneyLabel(
                    label: S.of(context).monthlyInterest,
                    amount: loan.calculateMonthlyInterest(),
                    currencySymbol: currencySymbol,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '${S.of(context).statusClosed} ${loan.closedAt != null ? _formatDate(loan.closedAt!) : "N/A"}',
              style: context.textStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
