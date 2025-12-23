import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/loan.dart';
import '../../../data/providers/providers.dart';
import '../../../core/constants/app_status.dart';

/// Customer detail screen - Consolidated account view with real data
class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final loansAsync = ref.watch(loansByCustomerProvider(customerId));

    return customerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Cliente')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Cliente')),
        body: AppError(
          title: 'Error',
          message: error.toString(),
          onRetry: () => ref.invalidate(customerByIdProvider(customerId)),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cliente')),
            body: const AppEmptyState(
              icon: Icons.person_off,
              title: 'Cliente no encontrado',
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
    final statusLabel = customer.isActive ? 'Activo' : 'Inactivo';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                                color: Colors.white70,
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
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Registrado: ${_formatDate(customer.createdAt)}',
                        style: context.textStyles.bodySmall.copyWith(
                          color: Colors.white70,
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
            const PopupMenuItem(
              value: 'deactivate',
              child: Text('Desactivar cliente'),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Text('Ver historial completo'),
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
      loading: () => const AppCard(
        title: 'Resumen de Cuenta',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          AppCard(title: 'Resumen de Cuenta', child: Text('Error: $e')),
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

        return AppCard(
          title: 'Resumen de Cuenta',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: 'Capital Total',
                      value: totalCapital,
                      icon: Icons.account_balance_wallet,
                      iconColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.info
                          : AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Interés Mensual',
                      value: totalInterestExpected,
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
                          'Préstamos cerrados',
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
                          'Préstamos activos',
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
            label: 'Nuevo Préstamo',
            icon: Icons.add_card,
            variant: AppButtonVariant.primary,
            onPressed: () => context.push('/customer/$customerId/loan/new'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Registrar Pago',
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
            Text('Préstamos', style: context.textStyles.titleLarge),
            TextButton(onPressed: () {}, child: const Text('Ver todos')),
          ],
        ),
        const SizedBox(height: 8),

        loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (loans) {
            if (loans.isEmpty) {
              return const AppEmptyState(
                icon: Icons.receipt_long,
                title: 'Sin préstamos',
                message: 'Este cliente no tiene préstamos registrados',
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
                              const SnackBar(
                                content: Text(
                                  'Acción denegada: No se puede eliminar un préstamo con pagos registrados.',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                          return false;
                        }

                        if (!context.mounted) return false;

                        // 2. Confirmation Dialog
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: const Text(
                              '¿Está seguro de que desea eliminar este préstamo?\nEsta acción no se puede deshacer.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                ),
                                child: const Text('Eliminar'),
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
                          ref.invalidate(loansByCustomerProvider(customerId));
                          ref.invalidate(customerByIdProvider(customerId));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Préstamo eliminado correctamente',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          // Force refresh to "undo" visual removal
                          ref.invalidate(loansByCustomerProvider(customerId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al eliminar: $e')),
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
  final String label;
  final String? subtitle;
  final double value;
  final IconData icon;
  final Color iconColor;

  const _SummaryItem({
    required this.label,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

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
        if (subtitle != null)
          Text(subtitle!, style: context.textStyles.labelSmall),
        const SizedBox(height: 4),
        MoneyDisplay(amount: value, size: MoneyDisplaySize.medium),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;

  const _LoanCard({required this.loan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isClosed = loan.status == AppStatus.loanClosed;

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
                    Row(
                      children: [
                        Text(
                          'Préstamo ${loan.loanNumber != null ? "#${loan.loanNumber}" : ""} ',
                          style: context.textStyles.labelMedium,
                        ),
                        MoneyDisplay(
                          amount: loan.principalOriginal,
                          size: MoneyDisplaySize.small,
                        ),
                      ],
                    ),
                    Text(
                      'Tasa: ${loan.monthlyInterestRate.toStringAsFixed(0)}% mensual',
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
                    label: 'Saldo Capital',
                    amount: loan.principalBalance,
                  ),
                ),
                Expanded(
                  child: MoneyLabel(
                    label: 'Int. Mensual',
                    amount: loan.calculateMonthlyInterest(),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Cerrado el ${loan.closedAt != null ? _formatDate(loan.closedAt!) : "N/A"}',
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
