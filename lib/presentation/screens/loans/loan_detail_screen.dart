import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/billing_cycle.dart';
import '../../../data/models/payment.dart';
import '../../../data/providers/loan_provider.dart';
import '../../../data/providers/billing_cycle_provider.dart';
import '../../../data/providers/payment_provider.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/providers/customer_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../services/billing_cycle_service.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/providers/providers.dart'; // Ensure appSettingsProvider is available
import '../../../core/constants/app_status.dart';
import '../../../core/localization/locale_provider.dart';

/// Handle edit loan action with validation
Future<void> _handleEditLoan(
  BuildContext context,
  WidgetRef ref,
  String loanId,
) async {
  try {
    final payments = await ref.read(paymentsByLoanProvider(loanId).future);
    final hasValidPayments = payments.any((p) => p.voidedAt == null);

    if (!context.mounted) return;

    if (hasValidPayments) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_clock, color: AppColors.warning),
              SizedBox(width: 8),
              Text(S.of(context).restrictedEditTitle),
            ],
          ),
          content: Text(S.of(context).restrictedEditMessage),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.of(context).understood),
            ),
          ],
        ),
      );
      return;
    }

    context.pushNamed('edit-loan', pathParameters: {'id': loanId});
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al verificar pagos: $e')));
    }
  }
}

/// Show delete confirmation dialog for a loan
Future<void> _showDeleteConfirmation(
  BuildContext context,
  WidgetRef ref,
  String loanId,
) async {
  try {
    // First check if loan has payments
    final payments = await ref.read(paymentsByLoanProvider(loanId).future);
    final hasPayments = payments.isNotEmpty;

    if (!context.mounted) return;

    if (hasPayments) {
      // Cannot delete loan with payments
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning),
              SizedBox(width: 8),
              Text(S.of(context).cannotDeleteTitle),
            ],
          ),
          content: Text(S.of(context).cannotDeleteMessage),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.of(context).understood),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.danger),
            SizedBox(width: 8),
            Text(S.of(context).deleteLoanTitle),
          ],
        ),
        content: Text(S.of(context).deleteLoanConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Capture customerId for refresh
        final loan = ref.read(loanByIdProvider(loanId)).valueOrNull;
        final customerId = loan?.customerId;

        // Delete loan and associated cycles
        final loanNotifier = ref.read(loansProvider.notifier);
        final success = await loanNotifier.deleteLoan(loanId);

        if (success && context.mounted) {
          // Force refresh of all related lists
          ref.invalidate(loansProvider);
          ref.invalidate(loansWithCustomerProvider);
          ref.invalidate(loanCountProvider);
          ref.invalidate(totalPrincipalBalanceProvider);
          ref.invalidate(dashboardProvider);

          if (customerId != null) {
            ref.invalidate(loansByCustomerProvider(customerId));
            ref.invalidate(activeLoansByCustomerProvider(customerId));
            ref.invalidate(customerByIdProvider(customerId));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).loanDeletedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(); // Go back
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).errorDeletingLoan),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${S.of(context).errorProcessingRequest}: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).errorProcessingRequest}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

Future<void> _shareStatement(
  BuildContext context,
  WidgetRef ref,
  String loanId,
) async {
  try {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).generatingStatement)));

    // Force refresh the loan to ensure we have the latest balance
    final loan = await ref.refresh(loanByIdProvider(loanId).future);
    if (loan == null) throw Exception('Préstamo no cargado');

    final customer = await ref.read(
      customerByIdProvider(loan.customerId).future,
    );
    if (customer == null) throw Exception('Cliente no encontrado');

    final payments = await ref.read(paymentsByLoanProvider(loanId).future);

    // Fetch all allocations for this loan
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final allocations = await paymentRepo.getAllAllocationsForLoan(loanId);

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) throw Exception('Configuración no cargada');

    final pdfService = ref.read(pdfGeneratorServiceProvider);
    await pdfService.generateLoanStatement(
      loan: loan,
      customer: customer,
      payments: payments,
      allocations: allocations, // Added argument
      settings: settings,
      locale: S.of(context).locale,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

Future<void> _shareDisbursementReceipt(
  BuildContext context,
  WidgetRef ref,
  String loanId,
) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).generatingDisbursement)),
    );

    final loan = await ref.read(loanByIdProvider(loanId).future);
    if (loan == null) throw Exception('Préstamo no encontrado');

    final customer = await ref.read(
      customerByIdProvider(loan.customerId).future,
    );
    if (customer == null) throw Exception('Cliente no encontrado');

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) throw Exception('Configuración no cargada');

    final pdfService = ref.read(pdfGeneratorServiceProvider);
    await pdfService.generateDisbursementReceipt(
      loan: loan,
      customer: customer,
      settings: settings,
      locale: S.of(context).locale,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar comprobante: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

Future<void> _shareReceipt(
  BuildContext context,
  WidgetRef ref,
  Payment payment,
) async {
  try {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).generatingReceipt)));

    // Force refresh loan to get updated balance
    final loan = await ref.refresh(loanByIdProvider(payment.loanId).future);
    if (loan == null) throw Exception('Préstamo no visible');

    final customer = await ref.read(
      customerByIdProvider(payment.customerId).future,
    );
    if (customer == null) throw Exception('Cliente no encontrado');

    final allocations = await ref.read(
      allocationsByPaymentIdProvider(payment.paymentId).future,
    );

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) throw Exception('Configuración no cargada');

    await ref
        .read(pdfGeneratorServiceProvider)
        .generatePaymentReceipt(
          payment: payment,
          loan: loan,
          customer: customer,
          allocations: allocations,
          settings: settings,
          locale: S.of(context).locale,
        );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar recibo: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

/// Loan detail screen
class LoanDetailScreen extends ConsumerStatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Check for missing cycles after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMissingCycles();
    });
  }

  Future<void> _checkForMissingCycles() async {
    try {
      // Wait for the loan to actually load (not just use cached value)
      final loan = await ref.read(loanByIdProvider(widget.loanId).future);
      if (loan != null &&
          (loan.status == 'ACTIVE' || loan.status == 'IN_MORA')) {
        final loanRepo = ref.read(loanRepositoryProvider);
        final cycleRepo = ref.read(billingCycleRepositoryProvider);
        final customerRepo = ref.read(customerRepositoryProvider);

        final service = BillingCycleService(
          cycleRepository: cycleRepo,
          customerRepository: customerRepo,
          loanRepository: loanRepo,
        );

        final newCycles = await service.generateMissingCycles(loan);
        if (newCycles.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se han generado ${newCycles.length} nuevos ciclos de cobro',
              ),
              backgroundColor: AppColors.info,
            ),
          );
          // Invalidate ALL cycle-related providers to ensure fresh data
          ref.invalidate(billingCyclesByLoanProvider(widget.loanId));
          ref.invalidate(pendingBillingCyclesProvider(widget.loanId));
          // Update loan status if it changed to overdue
          ref.invalidate(loanByIdProvider(widget.loanId));
          ref.invalidate(loansProvider); // Refresh main list too
          // Force recalculation of interest with fresh cycle data
          ref.read(refreshTriggerProvider.notifier).state++;
        }
      }
    } catch (e) {
      debugPrint('Error checking cycles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanAsync = ref.watch(loanByIdProvider(widget.loanId));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).loanDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Estado de Cuenta',
            onPressed: () => _shareStatement(context, ref, widget.loanId),
          ),

          // Actions removed from here
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(loanByIdProvider(widget.loanId));
              ref.invalidate(billingCyclesByLoanProvider(widget.loanId));
              ref.invalidate(paymentsByLoanProvider(widget.loanId));
            },
          ),
        ],
      ),
      body: loanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (loan) {
          if (loan == null) {
            return const Center(child: Text('Préstamo no encontrado'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(loanByIdProvider(widget.loanId));
              ref.invalidate(billingCyclesByLoanProvider(widget.loanId));
              ref.invalidate(paymentsByLoanProvider(widget.loanId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Loan summary card
                _buildSummaryCard(loan),
                const SizedBox(height: 16),

                // Quick action
                AppButton(
                  label: S.of(context).registerPayment,
                  icon: Icons.payment,
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  onPressed: () {
                    // Navigate to payment form if loan is active
                    if (loan.status == 'ACTIVE' || loan.status == 'IN_MORA') {
                      context.pushNamed(
                        'new-payment',
                        extra: {
                          'loanId': loan.loanId,
                          'customerId': loan.customerId,
                        },
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Billing cycles section
                Text(
                  S.of(context).billingCycles,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 12),
                _BillingCyclesList(loanId: widget.loanId),

                const SizedBox(height: 24),

                // Payments section
                Text(
                  S.of(context).paymentHistory,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 12),
                _PaymentsList(loanId: widget.loanId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Loan loan) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loan.loanNumber != null) ...[
                      Text(
                        '${S.of(context).loanNumber}${loan.loanNumber}',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      S.of(context).originalCapital,
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    MoneyDisplay(
                      amount: loan.principalOriginal,
                      size: MoneyDisplaySize.large,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(status: loan.status),
                  if (loan.status == 'ACTIVE' || loan.status == 'IN_MORA') ...[
                    const SizedBox(width: 4),
                    // Disbursement Receipt
                    IconButton(
                      icon: const Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      tooltip: S.of(context).disbursementReceiptTooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () =>
                          _shareDisbursementReceipt(context, ref, loan.loanId),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: S.of(context).editTooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () =>
                          _handleEditLoan(context, ref, loan.loanId),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      tooltip: S.of(context).deleteTooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(context, ref, loan.loanId),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: MoneyLabel(
                  label: S.of(context).capitalBalance,
                  amount: loan.principalBalance,
                ),
              ),
              Expanded(child: _PendingInterestLabel(loanId: loan.loanId)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.of(context).rate} ${loan.rateUnit == 'MONTHLY' ? S.of(context).monthly : S.of(context).otherFreq}',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loan.monthlyInterestRate.toStringAsFixed(0)}%',
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).disbursement,
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(loan.disbursementDate),
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _PendingInterestLabel extends ConsumerWidget {
  final String loanId;

  const _PendingInterestLabel({required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch refresh trigger to force recalculation when data changes
    final refreshTrigger = ref.watch(refreshTriggerProvider);

    // Use CENTRALIZED calculation provider - SINGLE SOURCE OF TRUTH
    final calcParams = LoanCalculationParams(
      loanId: loanId,
      paymentType: 'VIEW', // Just viewing, not making a payment
      refreshTrigger: refreshTrigger,
    );
    final calcAsync = ref.watch(loanCalculationProvider(calcParams));

    return calcAsync.when(
      loading: () {
        print('DEBUG UI: _PendingInterestLabel is LOADING');
        return const Text('Calculando...');
      },
      error: (e, __) {
        print('DEBUG UI: _PendingInterestLabel ERROR: $e');
        return const Text('-');
      },
      data: (calc) {
        print(
          'DEBUG UI: _PendingInterestLabel received calc.overdueInterest=${calc.overdueInterest}, totalPendingInterest=${calc.totalPendingInterest}',
        );
        // overdueInterest is the correct value from centralized service
        return MoneyLabel(
          label: S.of(context).pendingInterest,
          amount: calc.overdueInterest,
          amountColor: calc.overdueInterest > 0
              ? AppColors.warning
              : AppColors.success,
        );
      },
    );
  }
}

class _BillingCyclesList extends ConsumerWidget {
  final String loanId;

  const _BillingCyclesList({required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(billingCyclesByLoanProvider(loanId));

    return cyclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error al cargar ciclos: $e'),
      data: (cycles) {
        if (cycles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay ciclos de cobro generados'),
            ),
          );
        }

        // Show newest cycles first
        final sortedCycles = cycles.toList()
          ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return Column(
          children: sortedCycles
              .map(
                (cycle) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CycleCard(cycle: cycle),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PaymentsList extends ConsumerWidget {
  final String loanId;

  const _PaymentsList({required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByLoanProvider(loanId));

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error al cargar pagos: $e'),
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay pagos registrados'),
            ),
          );
        }

        return Column(
          children: payments
              .map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PaymentCard(payment: payment),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CycleCard extends StatelessWidget {
  final BillingCycle cycle;

  const _CycleCard({required this.cycle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppStatus.getColor(cycle.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${cycle.cycleNumber}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppStatus.getColor(cycle.status),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${S.of(context).dueDate} ${_formatDate(cycle.dueDate)}',
                      style: AppTypography.bodyMedium,
                    ),
                    const Spacer(),
                    StatusBadge(status: cycle.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MoneyLabel(
                      label: S.of(context).expected,
                      amount: cycle.interestExpected,
                      isCompact: true,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: MoneyLabel(
                        label: S.of(context).pending,
                        // VISUAL FIX: If paid, always show 0.00 regardless of DB value
                        amount: cycle.status == 'PAID'
                            ? 0
                            : cycle.interestPending,
                        amountColor:
                            (cycle.status != 'PAID' &&
                                cycle.interestPending > 0)
                            ? AppColors.danger
                            : AppColors.success,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _PaymentCard extends ConsumerWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocationsAsync = ref.watch(
      allocationsByPaymentIdProvider(payment.paymentId),
    );

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.of(context).receiptNumber}${payment.receiptNumber}',
                      style: AppTypography.titleSmall,
                    ),
                    Text(
                      _formatDate(payment.paymentDate),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              MoneyDisplay(
                amount: payment.amount,
                size: MoneyDisplaySize.medium,
                color: AppColors.accent,
              ),
              IconButton(
                icon: Icon(
                  Icons.share,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _shareReceipt(context, ref, payment),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(S.of(context).application, style: AppTypography.labelSmall),
          const SizedBox(height: 4),

          allocationsAsync.when(
            loading: () => const Text('Cargando detalles...'),
            error: (_, __) => const Text('Error al cargar detalles'),
            data: (allocations) {
              if (allocations.isEmpty)
                return const Text('Sin asignación detallada');

              return Column(
                children: allocations
                    .map(
                      (alloc) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            Expanded(
                              child: Text(
                                _getAllocationLabel(
                                  context,
                                  alloc.allocationType,
                                ),
                                style: AppTypography.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            MoneyDisplay(
                              amount: alloc.amount,
                              size: MoneyDisplaySize.small,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getAllocationLabel(BuildContext context, String type) {
    return switch (type) {
      'PRINCIPAL' => S.of(context).capital,
      'INTEREST' => S.of(context).interest,
      'MORA' => S.of(context).mora,
      _ => type,
    };
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
