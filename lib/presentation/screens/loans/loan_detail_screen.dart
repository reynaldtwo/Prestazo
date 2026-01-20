import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prestamos_app/core/constants/app_status.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/utils/currency_utils.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/models/payment.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:prestamos_app/services/whatsapp_service.dart';

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
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_clock, color: AppColors.warning),
              const SizedBox(width: 8),
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

    await context.pushNamed('edit-loan', pathParameters: {'id': loanId});
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).errorCheckingPayments(e.toString())),
        ),
      );
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
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.warning),
              const SizedBox(width: 8),
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
            const Icon(Icons.delete_forever, color: AppColors.danger),
            const SizedBox(width: 8),
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

    if ((confirmed ?? false) && context.mounted) {
      try {
        // Capture customerId for refresh
        final loan = ref.read(loanByIdProvider(loanId)).valueOrNull;
        final customerId = loan?.customerId;

        // Delete loan and associated cycles
        final loanNotifier = ref.read(loansProvider.notifier);
        final success = await loanNotifier.deleteLoan(loanId);

        if (success && context.mounted) {
          // Force refresh of all related lists
          ref
            ..invalidate(loansProvider)
            ..invalidate(loansWithCustomerProvider)
            ..invalidate(loanCountProvider)
            ..invalidate(totalPrincipalBalanceProvider)
            ..invalidate(dashboardProvider);

          if (customerId != null) {
            ref
              ..invalidate(loansByCustomerProvider(customerId))
              ..invalidate(activeLoansByCustomerProvider(customerId))
              ..invalidate(customerByIdProvider(customerId));
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
      } on Exception catch (e) {
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
  } on Exception catch (e) {
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
    final s = S.of(context);
    final locale = Localizations.localeOf(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.generatingStatement)));

    // Force refresh the loan to ensure we have the latest balance
    final loan = await ref.refresh(loanByIdProvider(loanId).future);
    if (loan == null) throw Exception(s.loanNotLoaded);

    final customer = await ref.read(
      customerByIdProvider(loan.customerId).future,
    );
    if (customer == null) throw Exception(s.customerNotFound);

    final payments = await ref.read(paymentsByLoanProvider(loanId).future);

    // Fetch all allocations for this loan
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final allocations = await paymentRepo.getAllAllocationsForLoan(loanId);

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) throw Exception(s.configNotLoaded);

    // Use LOAN currency for client-facing documents, not global settings
    final currencySymbol = CurrencyUtils.getCurrencySymbol(loan.currencyCode);

    await WhatsAppService.shareLoanStatement(
      loan: loan,
      customer: customer,
      payments: payments,
      allocations: allocations,
      settings: settings,
      locale: locale,
      currencySymbol: currencySymbol,
    );
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).errorGeneratingPdf(e.toString())),
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
    final s = S.of(context);
    final locale = Localizations.localeOf(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.generatingDisbursement)));

    final loan = await ref.read(loanByIdProvider(loanId).future);
    if (loan == null) throw Exception(s.loanNotFound);

    final customer = await ref.read(
      customerByIdProvider(loan.customerId).future,
    );
    if (customer == null) throw Exception(s.customerNotFound);

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) throw Exception(s.configNotLoaded);

    final pdfService = ref.read(pdfGeneratorServiceProvider);
    // Use LOAN currency for client-facing documents, not global settings
    final currencySymbol = CurrencyUtils.getCurrencySymbol(loan.currencyCode);

    // Fetch next installment date
    final nextCycle = await ref
        .read(billingCycleRepositoryProvider)
        .getCurrentCycle(loanId);
    final nextInstallmentDate = nextCycle?.dueDate;

    // Get frequency name
    final frequencies = await ref.read(paymentFrequenciesProvider.future);
    final frequency = frequencies
        .where((f) => f.id == loan.billingFrequency)
        .firstOrNull;

    if (loan.planId != null) {
      // Fetch cycles for the plan report
      final cycles = await ref.read(billingCyclesByLoanProvider(loanId).future);
      await pdfService.generateDisbursementWithPlanReceipt(
        loan: loan,
        customer: customer,
        cycles: cycles,
        settings: settings,
        locale: locale,
        currencySymbol: currencySymbol,
        frequencyName: frequency?.name,
        nextInstallmentDate: nextInstallmentDate,
      );
    } else {
      await pdfService.generateDisbursementReceipt(
        loan: loan,
        customer: customer,
        settings: settings,
        locale: locale,
        currencySymbol: currencySymbol,
        frequencyName: frequency?.name,
        nextInstallmentDate: nextInstallmentDate,
      );
    }
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).errorGeneratingReceipt(e.toString())),
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
    final s = S.of(context);
    final locale = Localizations.localeOf(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.generatingReceipt)));

    // Force refresh loan to get updated balance
    final loan = await ref.refresh(loanByIdProvider(payment.loanId).future);
    if (loan == null) throw Exception(s.loanNotFound);

    final customer = await ref.read(
      customerByIdProvider(loan.customerId).future,
    );
    if (customer == null) throw Exception(s.customerNotFound);

    final allocations = await ref.read(
      allocationsByPaymentIdProvider(payment.paymentId).future,
    );

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) throw Exception(s.configNotLoaded);

    // Use LOAN currency for client-facing documents, not global settings
    final currencySymbol = CurrencyUtils.getCurrencySymbol(loan.currencyCode);

    // Fetch next installment date
    final nextCycle = await ref
        .read(billingCycleRepositoryProvider)
        .getCurrentCycle(loan.loanId);
    final nextInstallmentDate = nextCycle?.dueDate;

    await ref
        .read(pdfGeneratorServiceProvider)
        .generatePaymentReceipt(
          payment: payment,
          loan: loan,
          customer: customer,
          allocations: allocations,
          settings: settings,
          locale: locale,
          currencySymbol: currencySymbol,
          nextInstallmentDate: nextInstallmentDate,
        );
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).errorGeneratingVoucher(e.toString())),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

/// Pantalla de detalle de préstamo.
class LoanDetailScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [LoanDetailScreen].
  const LoanDetailScreen({required this.loanId, super.key});

  /// Identificador único del préstamo a mostrar.
  final String loanId;

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
        final service = ref.read(billingCycleServiceProvider);

        final newCycles = await service.generateMissingCycles(loan);
        if (newCycles.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).generatedBillingCycles(newCycles.length),
              ),
              backgroundColor: AppColors.info,
            ),
          );
          // Invalidate ALL cycle-related providers to ensure fresh data
          ref
            ..invalidate(billingCyclesByLoanProvider(widget.loanId))
            ..invalidate(pendingBillingCyclesProvider(widget.loanId))
            // Update loan status if it changed to overdue
            ..invalidate(loanByIdProvider(widget.loanId))
            ..invalidate(loansProvider); // Refresh main list too
          // Force recalculation of interest with fresh cycle data
          ref.read(refreshTriggerProvider.notifier).state++;
        }
      }
    } on Exception catch (_) {
      // Ignore error checking cycles
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanAsync = ref.watch(loanByIdProvider(widget.loanId));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).loanDetail),
        actions: [
          // Share button moved to summary card

          // Actions removed from here
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                ..invalidate(loanByIdProvider(widget.loanId))
                ..invalidate(billingCyclesByLoanProvider(widget.loanId))
                ..invalidate(paymentsByLoanProvider(widget.loanId));
            },
          ),
        ],
      ),
      body: loanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text(S.of(context).genericError(e.toString()))),
        data: (loan) {
          if (loan == null) {
            return Center(child: Text(S.of(context).loanNotFound));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(loanByIdProvider(widget.loanId))
                ..invalidate(billingCyclesByLoanProvider(widget.loanId))
                ..invalidate(paymentsByLoanProvider(widget.loanId));
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
          // Row 1: Loan Number, Capital, Status
          // Row 1: Header (Loan Number + Status)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loan.loanNumber != null)
                Expanded(
                  child: Text(
                    '${S.of(context).loanNumber}${loan.loanNumber}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              StatusBadge(status: loan.status),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Capital Data
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).originalCapital,
                style: AppTypography.labelMedium,
              ),
              const SizedBox(height: 4),
              MoneyDisplay(
                amount: loan.principalOriginal,
                size: MoneyDisplaySize.large,
                currencySymbol: CurrencyUtils.getCurrencySymbol(
                  loan.currencyCode,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Actions (Moved down to prevent distortion)
          if (loan.status == 'ACTIVE' || loan.status == 'IN_MORA')
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Share Statement
                IconButton(
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: Colors.indigoAccent,
                  ),
                  tooltip: 'Estado de Cuenta',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.indigoAccent.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () => _shareStatement(context, ref, loan.loanId),
                ),
                // Disbursement Receipt
                IconButton(
                  icon: const Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  tooltip: S.of(context).disbursementReceiptTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () =>
                      _shareDisbursementReceipt(context, ref, loan.loanId),
                ),
                // Edit
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: S.of(context).editTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.textPrimary.withValues(
                      alpha: 0.1,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () => _handleEditLoan(context, ref, loan.loanId),
                ),
                // Delete
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  tooltip: S.of(context).deleteTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () =>
                      _showDeleteConfirmation(context, ref, loan.loanId),
                ),
              ],
            ),
          const Divider(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              MoneyLabel(
                label: S.of(context).capitalBalance,
                amount: loan.principalBalance,
                currencySymbol: CurrencyUtils.getCurrencySymbol(
                  loan.currencyCode,
                ),
              ),
              _PendingInterestLabel(
                loanId: loan.loanId,
                currencySymbol: CurrencyUtils.getCurrencySymbol(
                  loan.currencyCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${S.of(context).rate} ${loan.rateUnit == 'MONTHLY' ? S.of(context).monthly : S.of(context).otherFreq}',
                    style: AppTypography.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loan.monthlyInterestRate.toStringAsFixed(2)}%',
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
              Column(
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
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }
}

class _PendingInterestLabel extends ConsumerWidget {
  const _PendingInterestLabel({
    required this.loanId,
    required this.currencySymbol,
  });
  final String loanId;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch refresh trigger to force recalculation when data changes
    final refreshTrigger = ref.watch(refreshTriggerProvider);

    // Use CENTRALIZED calculation provider - SINGLE SOURCE OF TRUTH
    final calcParams = LoanCalculationParams(
      loanId: loanId,
      refreshTrigger: refreshTrigger,
    );
    final calcAsync = ref.watch(loanCalculationProvider(calcParams));

    return calcAsync.when(
      loading: () => Text(S.of(context).calculating),
      error: (e, _) => const Text('-'),
      data: (calc) {
        // overdueInterest is the correct value from centralized service
        return MoneyLabel(
          label: S.of(context).pendingInterest,
          amount: calc.overdueInterest,
          amountColor: calc.overdueInterest > 0
              ? AppColors.warning
              : AppColors.success,
          currencySymbol: currencySymbol,
        );
      },
    );
  }
}

class _BillingCyclesList extends ConsumerWidget {
  const _BillingCyclesList({required this.loanId});
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(billingCyclesByLoanProvider(loanId));

    return cyclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(S.of(context).errorLoadingCycles(e.toString())),
      data: (cycles) {
        if (cycles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.of(context).noBillingCycles),
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
  const _PaymentsList({required this.loanId});
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByLoanProvider(loanId));

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(S.of(context).errorLoadingPayments(e.toString())),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.of(context).noPaymentsRegistered),
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
  const _CycleCard({required this.cycle});
  final BillingCycle cycle;

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
                      '${S.of(context).dueDate} ${_formatDate(context, cycle.dueDate)}',
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
                      amount:
                          cycle.installmentExpected ?? cycle.interestExpected,
                      isCompact: true,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: MoneyLabel(
                        label: S.of(context).pending,
                        // VISUAL FIX: If paid, always show 0.00
                        amount: cycle.status == 'PAID'
                            ? 0
                            : (cycle.installmentPending ??
                                  cycle.interestPending),
                        amountColor:
                            (cycle.status != 'PAID' &&
                                (cycle.installmentPending ??
                                        cycle.interestPending) >
                                    0)
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

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }
}

class _PaymentCard extends ConsumerWidget {
  const _PaymentCard({required this.payment});
  final Payment payment;

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
                      _formatDate(context, payment.paymentDate),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              MoneyDisplay(
                amount: payment.amount,
                color: AppColors.accent,
                currencySymbol: CurrencyUtils.getCurrencySymbol(
                  payment.paymentCurrency,
                ),
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
            loading: () => Text(S.of(context).loadingDetails),
            error: (e, st) => Text(S.of(context).errorLoadingDetails),
            data: (allocations) {
              if (allocations.isEmpty) {
                return Text(S.of(context).noAllocationDetails);
              }

              // Group allocations logic to match PdfGeneratorService
              final interestTotal = allocations
                  .where(
                    (a) =>
                        a.allocationType == 'INTEREST' ||
                        a.allocationType == 'MORA',
                  )
                  .fold<double>(0, (sum, a) => sum + a.amount);

              final principalTotal = allocations
                  .where((a) => a.allocationType == 'PRINCIPAL')
                  .fold<double>(0, (sum, a) => sum + a.amount);

              // Check for other types (e.g. Fees)
              final otherAllocations = allocations
                  .where(
                    (a) =>
                        a.allocationType != 'INTEREST' &&
                        a.allocationType != 'MORA' &&
                        a.allocationType != 'PRINCIPAL',
                  )
                  .toList();

              final groupedItems = <Widget>[];

              if (interestTotal > 0.001) {
                groupedItems.add(
                  Padding(
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
                            S
                                .of(context)
                                .interest, // Use generic Interest label
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        MoneyDisplay(
                          amount: interestTotal,
                          size: MoneyDisplaySize.small,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (principalTotal > 0.001) {
                groupedItems.add(
                  Padding(
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
                            S.of(context).capital,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        MoneyDisplay(
                          amount: principalTotal,
                          size: MoneyDisplaySize.small,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Add others individually
              for (final alloc in otherAllocations) {
                groupedItems.add(
                  Padding(
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
                            _getAllocationLabel(context, alloc.allocationType),
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
                );
              }

              return Column(children: groupedItems);
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

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }
}
