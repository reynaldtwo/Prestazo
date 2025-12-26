import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/payment_allocation.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../data/models/billing_cycle.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/providers/loan_provider.dart';
import '../../../data/providers/payment_provider.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/cobrar_provider.dart';
import '../../../data/providers/billing_cycle_provider.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../services/services.dart';

/// Payment form screen for registering payments
class PaymentFormScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? loanId;
  const PaymentFormScreen({super.key, this.customerId, this.loanId});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _declaredType = 'MIXED';

  Customer? _selectedCustomer;
  Loan? _selectedLoan;
  List<BillingCycle> _pendingCycles = [];

  bool _isLoading = false;
  bool _isLoadingLoans = false;
  bool _dailyAccrualEnabled = false;

  // Allocation preview
  double _toOverdueInterest = 0;
  double _toCurrentInterest = 0;
  double _toPrincipal = 0;

  // Calculated debt for cancellation
  double _calculatedTotalDebt = 0;
  double _calculatedAdjustedInterest = 0;
  double _calculatedPartialInterest = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateAllocation);
    _loadSettings();
    _initializeFromParams();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    if (mounted)
      setState(() => _dailyAccrualEnabled = settings.dailyAccrualEnabled);
  }

  Future<void> _initializeFromParams() async {
    if (widget.customerId != null) {
      final customer = await ref.read(
        customerByIdProvider(widget.customerId!).future,
      );
      if (customer != null && mounted) {
        setState(() => _selectedCustomer = customer);
        await _loadLoansForCustomer(customer.customerId);

        if (widget.loanId != null && _selectedLoan == null) {
          final loan = await ref.read(loanByIdProvider(widget.loanId!).future);
          if (loan != null && mounted) {
            setState(() => _selectedLoan = loan);
            await _loadPendingCycles(loan.loanId);
          }
        }
      }
    }
  }

  Future<void> _loadLoansForCustomer(String customerId) async {
    setState(() => _isLoadingLoans = true);
    try {
      final loans = await ref.read(
        activeLoansByCustomerProvider(customerId).future,
      );
      if (loans.length == 1) {
        setState(() => _selectedLoan = loans.first);
        await _loadPendingCycles(loans.first.loanId);
      }
    } finally {
      if (mounted) setState(() => _isLoadingLoans = false);
    }
  }

  Future<void> _loadPendingCycles(String loanId) async {
    // First, generate any missing cycles up to current date
    // This ensures that overdue cycles are created automatically
    final loanRepo = ref.read(loanRepositoryProvider);
    final loan = await loanRepo.getLoanById(loanId);
    if (loan != null && mounted) {
      try {
        final cycleRepo = ref.read(billingCycleRepositoryProvider);
        final customerRepo = ref.read(customerRepositoryProvider);

        final cycleService = BillingCycleService(
          cycleRepository: cycleRepo,
          customerRepository: customerRepo,
          loanRepository: loanRepo,
        );

        await cycleService.generateMissingCycles(loan);
      } catch (e) {
        // Log error but continue - we'll still try to load existing cycles
        debugPrint('Error generating cycles: $e');
      }
    }

    // Now load all pending cycles (including newly generated ones)
    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.getPendingCyclesByLoan(loanId);
    if (mounted) {
      setState(() => _pendingCycles = cycles);
      _recalculateDebt();
      _calculateAllocation();
    }
  }

  /// Recalculate total debt considering partial interest if enabled
  /// Uses centralized InterestCalculationService
  void _recalculateDebt() {
    if (_selectedLoan == null) {
      setState(() {
        _calculatedTotalDebt = 0;
        _calculatedAdjustedInterest = 0;
        _calculatedPartialInterest = 0;
      });
      return;
    }

    // Use centralized service for interest calculation
    final result = InterestCalculationService.instance.calculateTotalDebt(
      loan: _selectedLoan!,
      pendingCycles: _pendingCycles,
      paymentDate: _paymentDate,
      paymentType: _declaredType,
      dailyAccrualEnabled: _dailyAccrualEnabled,
    );

    setState(() {
      _calculatedAdjustedInterest = result.totalPendingInterest;
      _calculatedPartialInterest = result.proportionalInterest;
      _calculatedTotalDebt = result.totalDebt;
    });
  }

  /// Calculate how payment amount is distributed
  /// Uses CENTRALIZED InterestCalculationService for business logic
  void _calculateAllocation() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    // Safety clear if invalid
    if (amount <= 0 || _selectedLoan == null) {
      setState(() {
        _toOverdueInterest = 0;
        _toCurrentInterest = 0;
        _toPrincipal = 0;
      });
      return;
    }

    // For RECOVERY type, force allocation to Principal ONLY
    if (_declaredType == 'RECOVERY') {
      setState(() {
        _toOverdueInterest = 0;
        _toCurrentInterest = 0;
        _toPrincipal = amount;
      });
      return;
    }

    // Call CENTRALIZED Service
    // This returns a PaymentDistribution object with exact amounts
    final distribution = InterestCalculationService.instance
        .calculatePaymentAllocation(
          loan: _selectedLoan!,
          paymentAmount: amount,
          pendingCycles: _pendingCycles,
          paymentType: _declaredType,
          dailyAccrualEnabled: _dailyAccrualEnabled,
          paymentDate: _paymentDate,
        );

    setState(() {
      _toOverdueInterest = distribution.toOverdueInterest;
      _toCurrentInterest = distribution.toCurrentInterest;
      _toPrincipal = distribution.toPrincipal;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateAllocation);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).registerPayment)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer selection
            if (_selectedCustomer == null)
              _buildCustomerSelector(customersState.activeCustomers)
            else
              _buildSelectedCustomerCard(),

            const SizedBox(height: 16),

            // Loan selection
            if (_selectedCustomer != null && _selectedLoan == null)
              _buildLoanSelector(),

            if (_selectedLoan != null) _buildSelectedLoanCard(),

            if (_selectedLoan != null) ...[
              const SizedBox(height: 24),

              // Amount field
              AppMoneyField(
                label: S.of(context).paymentAmountLabel,
                controller: _amountController,
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return S.of(context).fieldRequired;
                  final amount = double.tryParse(v.replaceAll(',', ''));
                  if (amount == null || amount <= 0)
                    return S.of(context).invalidAmountMsg;
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment type
              _buildPaymentTypeSelector(),

              const SizedBox(height: 16),

              // Date picker
              _buildDatePicker(),

              const SizedBox(height: 16),

              // Allocation preview
              _buildAllocationPreview(),

              const SizedBox(height: 16),

              // Notes
              AppTextField(
                label: S.of(context).notes,
                controller: _notesController,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Submit button
              AppButton(
                label: S.of(context).registerPayment,
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _submitPayment,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector(List<Customer> customers) {
    if (customers.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.person_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(S.of(context).noCustomers, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            AppButton(
              label: S.of(context).createCustomer,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push('/customer/new'),
            ),
          ],
        ),
      );
    }

    return AppCard(
      title: S.of(context).selectCustomer,
      child: Column(
        children: customers
            .take(10)
            .map(
              (customer) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.info
                              : AppColors.primary)
                          .withValues(alpha: 0.1),
                  child: Text(
                    (customer.alias ?? customer.fullName)[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.info
                          : AppColors.primary,
                    ),
                  ),
                ),
                title: Text(customer.alias ?? customer.fullName),
                subtitle: customer.alias != null
                    ? Text(customer.fullName)
                    : null,
                onTap: () async {
                  setState(() {
                    _selectedCustomer = customer;
                    _selectedLoan = null;
                    _pendingCycles = [];
                  });
                  await _loadLoansForCustomer(customer.customerId);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSelectedCustomerCard() {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.info
                        : AppColors.primary)
                    .withValues(alpha: 0.1),
            child: Text(
              (_selectedCustomer!.alias ?? _selectedCustomer!.fullName)[0]
                  .toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.info
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCustomer!.alias ?? _selectedCustomer!.fullName,
                  style: AppTypography.titleMedium,
                ),
                if (_selectedCustomer!.alias != null)
                  Text(
                    _selectedCustomer!.fullName,
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _selectedCustomer = null;
              _selectedLoan = null;
              _pendingCycles = [];
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSelector() {
    if (_isLoadingLoans) {
      return const Center(child: CircularProgressIndicator());
    }

    final loansAsync = ref.watch(
      activeLoansByCustomerProvider(_selectedCustomer!.customerId),
    );

    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppCard(child: Text('Error: $e')),
      data: (loans) {
        if (loans.isEmpty) {
          return AppCard(
            child: Column(
              children: [
                Icon(
                  Icons.money_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).noActiveLoans,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: S.of(context).createLoan,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(
                    '/customer/${_selectedCustomer!.customerId}/loan/new',
                  ),
                ),
              ],
            ),
          );
        }

        return AppCard(
          title: S.of(context).selectLoan,
          child: Column(
            children: loans
                .map(
                  (loan) => ListTile(
                    title: Text('C\$ ${_formatMoney(loan.principalBalance)}'),
                    subtitle: Text(
                      '${S.of(context).originalAmount}: C\$ ${_formatMoney(loan.principalOriginal)} - ${loan.monthlyInterestRate.toStringAsFixed(0)}% ${S.of(context).monthly}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      setState(() => _selectedLoan = loan);
                      await _loadPendingCycles(loan.loanId);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSelectedLoanCard() {
    // Use centralized service for consistent calculation across all screens
    final totalPendingInterest =
        InterestCalculationService.calculateOverdueInterest(_pendingCycles);

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
                    Text(
                      S.of(context).selectedLoan,
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${S.of(context).capital}: C\$ ${_formatMoney(_selectedLoan!.principalBalance)}',
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      '${S.of(context).pendingInterest}: C\$ ${_formatMoney(totalPendingInterest)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: totalPendingInterest > 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectedLoan = null;
                  _pendingCycles = [];
                }),
              ),
            ],
          ),
          if (_pendingCycles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(S.of(context).pendingCycles, style: AppTypography.labelSmall),
            const SizedBox(height: 4),
            ..._pendingCycles
                .take(3)
                .map(
                  (cycle) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${S.of(context).dueDate} ${cycle.dueDate.day}/${cycle.dueDate.month}/${cycle.dueDate.year}',
                          style: AppTypography.bodySmall.copyWith(
                            color: cycle.isOverdue
                                ? AppColors.danger
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'C\$ ${_formatMoney(cycle.interestPending)}',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    // Use pre-calculated state values from _recalculateDebt

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).paymentType, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(S.of(context).paymentTypeMixed),
              selected: _declaredType == 'MIXED',
              onSelected: (_) {
                setState(() {
                  _declaredType = 'MIXED';
                  _amountController.clear();
                });
                _recalculateDebt();
                _calculateAllocation();
              },
            ),
            ChoiceChip(
              label: Text(S.of(context).typeInterest),
              selected: _declaredType == 'INTEREST',
              onSelected: (_) {
                // Calculate explicitly to ensure UI update
                final result = InterestCalculationService.instance
                    .calculateTotalDebt(
                      loan: _selectedLoan!,
                      pendingCycles: _pendingCycles,
                      paymentDate: _paymentDate,
                      paymentType: 'INTEREST', // Force type
                      dailyAccrualEnabled: _dailyAccrualEnabled,
                    );

                setState(() {
                  _declaredType = 'INTEREST';
                  _calculatedAdjustedInterest = result.totalPendingInterest;
                  _calculatedPartialInterest = result.proportionalInterest;
                  _calculatedTotalDebt = result.totalDebt;

                  // Set text explicitly
                  _amountController.text = result.totalPendingInterest
                      .toStringAsFixed(2);
                });
                _calculateAllocation();
              },
            ),
            ChoiceChip(
              label: Text(S.of(context).typePrincipal),
              selected: _declaredType == 'PRINCIPAL',
              onSelected: (_) {
                final result = InterestCalculationService.instance
                    .calculateTotalDebt(
                      loan: _selectedLoan!,
                      pendingCycles: _pendingCycles,
                      paymentDate: _paymentDate,
                      paymentType: 'PRINCIPAL',
                      dailyAccrualEnabled: _dailyAccrualEnabled,
                    );

                setState(() {
                  _declaredType = 'PRINCIPAL';
                  _calculatedAdjustedInterest = result.totalPendingInterest;
                  _calculatedPartialInterest = result.proportionalInterest;
                  _calculatedTotalDebt = result.totalDebt;
                  _amountController
                      .clear(); // Principal is usually manual amount
                });
                _calculateAllocation();
              },
            ),
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  Text(S.of(context).typeCancel),
                ],
              ),
              selected: _declaredType == 'CANCEL',
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) {
                final result = InterestCalculationService.instance
                    .calculateTotalDebt(
                      loan: _selectedLoan!,
                      pendingCycles: _pendingCycles,
                      paymentDate: _paymentDate,
                      paymentType: 'CANCEL',
                      dailyAccrualEnabled: _dailyAccrualEnabled,
                    );

                setState(() {
                  _declaredType = 'CANCEL';
                  _calculatedAdjustedInterest = result.totalPendingInterest;
                  _calculatedPartialInterest = result.proportionalInterest;
                  _calculatedTotalDebt = result.totalDebt;

                  // Set text explicitly (Total Debt)
                  _amountController.text = result.totalDebt.toStringAsFixed(2);
                });
                _calculateAllocation();
              },
            ),
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handshake, size: 16),
                  const SizedBox(width: 4),
                  Text(S.of(context).paymentTypeRecovery),
                ],
              ),
              selected: _declaredType == 'RECOVERY',
              selectedColor: AppColors.info.withValues(alpha: 0.2),
              onSelected: (_) {
                if (_selectedLoan != null) {
                  setState(() {
                    _declaredType = 'RECOVERY';
                    // For Recovery, we only pay principal
                    _calculatedAdjustedInterest = 0;
                    _calculatedPartialInterest = 0;
                    _calculatedTotalDebt = _selectedLoan!.principalBalance;

                    _amountController.text = _selectedLoan!.principalBalance
                        .toStringAsFixed(2);
                  });
                  _calculateAllocation();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _paymentDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _paymentDate = date);
          _recalculateDebt();
          // Update amount field if in Cancel mode
          if (_declaredType == 'CANCEL') {
            _amountController.text = _calculatedTotalDebt.toStringAsFixed(2);
          }
          _calculateAllocation();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).paymentDate,
                  style: AppTypography.labelSmall,
                ),
                Text(
                  '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationPreview() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return const SizedBox.shrink();

    return AppCard(
      title: S.of(context).paymentApplication,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          _buildAllocationRow(
            S.of(context).toOverdueInterest,
            _toOverdueInterest,
            isOverdue: true,
          ),
          _buildAllocationRow(
            S.of(context).toCurrentInterest,
            _toCurrentInterest,
          ),
          _buildAllocationRow(
            S.of(context).toPrincipal,
            _toPrincipal,
            isPrincipal: true,
          ),
          const Divider(),
          _buildAllocationRow(
            S.of(context).totalApplied,
            _toOverdueInterest + _toCurrentInterest + _toPrincipal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(
    String label,
    double amount, {
    bool isOverdue = false,
    bool isPrincipal = false,
    bool isTotal = false,
  }) {
    Color? color;
    if (isOverdue && amount > 0) color = AppColors.danger;
    if (isPrincipal && amount > 0) color = AppColors.success;
    if (isTotal) color = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTypography.titleSmall : AppTypography.bodySmall,
          ),
          Text(
            'C\$ ${_formatMoney(amount)}',
            style:
                (isTotal ? AppTypography.titleSmall : AppTypography.bodyMedium)
                    .copyWith(
                      color: color,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLoan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un préstamo')));
      return;
    }

    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    // --- RECOVERY LOGIC START ---
    if (_declaredType == 'RECOVERY') {
      // 1. First Warning: Close without interest?
      final initialConfirmation = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(S.of(context).recoverLoan),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                '${S.of(context).recoverLoanDescPart1}${_formatMoney(amount)}${S.of(context).recoverLoanDescPart2}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: Text(S.of(context).approveRecovery),
            ),
          ],
        ),
      );

      if (initialConfirmation != true) return;

      // 2. Second Dialog: Restriction & Reason
      bool restrictCustomer = false;
      final reasonController =
          TextEditingController(); // Local controller for dialog

      final secondConfirmation = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(S.of(context).finalizeRecovery),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).recoveryNotePrompt),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: S.of(context).recoveryReasonHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: restrictCustomer,
                      onChanged: (val) {
                        setStateDialog(() => restrictCustomer = val ?? false);
                      },
                    ),
                    Expanded(
                      child: Text(
                        S.of(context).markRestricted,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(S.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(S.of(context).finalizeRecovery),
              ),
            ],
          ),
        ),
      );

      if (secondConfirmation != true) return;

      // 3. EXECUTE RECOVERY
      setState(() => _isLoading = true);
      try {
        final now = DateTime.now();
        final paymentId = const Uuid().v4();

        final payment = Payment(
          paymentId: paymentId,
          loanId: _selectedLoan!.loanId,
          customerId: _selectedCustomer!.customerId,
          paymentDate: _paymentDate,
          amount: amount,
          declaredType: 'RECOVERY', // Explicit type
          receiptNumber: 'PENDING',
          status: 'VALID',
          notes: reasonController.text.isNotEmpty
              ? reasonController.text
              : 'Recuperación de Capital',
          createdAt: now,
          updatedAt: now,
        );

        // Single allocation to Principal
        final allocations = [
          PaymentAllocation(
            allocationId: const Uuid().v4(),
            paymentId: paymentId,
            loanId: _selectedLoan!.loanId,
            allocationType: 'PRINCIPAL',
            amount: amount,
            createdAt: now,
          ),
        ];

        final createdPayment = await ref
            .read(paymentRepositoryProvider)
            .registerRecoveryPayment(
              payment: payment,
              allocations: allocations,
              restrictCustomer: restrictCustomer,
              restrictionReason: restrictCustomer
                  ? reasonController.text
                  : null,
            );

        // Success & Refresh
        _handleSuccessAndRefresh(createdPayment);
      } catch (e) {
        _handleError(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }
    // --- RECOVERY LOGIC END ---

    // Use centralized validation service
    final validationService = PaymentValidationService();
    final validation = validationService.validate(
      loan: _selectedLoan!,
      pendingCycles: _pendingCycles,
      amount: amount,
      paymentType: _declaredType,
      paymentDate: _paymentDate,
      dailyAccrualEnabled: _dailyAccrualEnabled,
    );

    if (!validation.isValid) {
      _showErrorDialog(validation.errorTitle!, validation.errorMessage!);
      return;
    }

    // For excess amount when dailyAccrual is disabled, show warning
    final totalApplicable =
        _toOverdueInterest + _toCurrentInterest + _toPrincipal;
    if (!_dailyAccrualEnabled && amount > totalApplicable + 0.01) {
      final proceed = await showConfirmDialog(
        context: context,
        title: S.of(context).warning,
        message:
            '${S.of(context).amountGranted} (C\$ ${_formatMoney(amount)}) > (C\$ ${_formatMoney(totalApplicable)}). ${S.of(context).continueAnywayPrompt}',
        confirmText: S.of(context).continue_,
      );
      if (proceed != true) return;
    }

    // Confirm payment
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).confirmPaymentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${S.of(context).paymentAmount}: C\$ ${_formatMoney(amount)}'),
            const SizedBox(height: 8),
            Text(
              '${S.of(context).customer}: ${_selectedCustomer!.alias ?? _selectedCustomer!.fullName}',
            ),
            const SizedBox(height: 8),
            if (_toOverdueInterest > 0)
              Text(
                '• ${S.of(context).toOverdueInterest}: C\$ ${_formatMoney(_toOverdueInterest)}',
              ),
            if (_toCurrentInterest > 0)
              Text(
                '• ${S.of(context).toCurrentInterest}: C\$ ${_formatMoney(_toCurrentInterest)}',
              ),
            if (_toPrincipal > 0)
              Text(
                '• ${S.of(context).toPrincipal}: C\$ ${_formatMoney(_toPrincipal)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Create payment (Receipt number will be assigned by Repository)
      final now = DateTime.now();
      final paymentId = const Uuid().v4();
      final payment = Payment(
        paymentId: paymentId,
        loanId: _selectedLoan!.loanId,
        customerId: _selectedCustomer!.customerId,
        paymentDate: _paymentDate,
        amount: amount,
        declaredType: _declaredType,
        receiptNumber: 'PENDING', // Will be assigned by repository
        status: 'VALID',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: now,
        updatedAt: now,
      );

      // Create allocations
      final allocations = <PaymentAllocation>[];
      double remaining = amount;

      // Allocate to overdue cycles first
      final today = DateTime(now.year, now.month, now.day);
      final overdueCycles = _pendingCycles
          .where((c) => c.dueDate.isBefore(today))
          .toList();
      final currentCycles = _pendingCycles
          .where((c) => !c.dueDate.isBefore(today))
          .toList();

      for (final cycle in overdueCycles) {
        if (remaining <= 0) break;
        final toApply = remaining >= cycle.interestPending
            ? cycle.interestPending
            : remaining;
        if (toApply > 0) {
          allocations.add(
            PaymentAllocation(
              allocationId: const Uuid().v4(),
              paymentId: paymentId,
              loanId: _selectedLoan!.loanId,
              allocationType: 'INTEREST',
              amount: toApply,
              billingCycleId: cycle.billingCycleId,
              createdAt: now,
            ),
          );
          remaining -= toApply;
        }
      }

      // Allocate to current cycles ONLY for non-CANCEL types or when dailyAccrual is disabled
      // For CANCEL with dailyAccrual, we use proportional partial interest instead
      if (_declaredType != 'CANCEL' || !_dailyAccrualEnabled) {
        for (final cycle in currentCycles) {
          if (remaining <= 0) break;
          final toApply = remaining >= cycle.interestPending
              ? cycle.interestPending
              : remaining;
          if (toApply > 0) {
            allocations.add(
              PaymentAllocation(
                allocationId: const Uuid().v4(),
                paymentId: paymentId,
                loanId: _selectedLoan!.loanId,
                allocationType: 'INTEREST',
                amount: toApply,
                billingCycleId: cycle.billingCycleId,
                createdAt: now,
              ),
            );
            remaining -= toApply;
          }
        }
      }

      // Allocate partial interest (proportional for days in current cycle) for CANCEL with daily accrual
      if (_dailyAccrualEnabled &&
          _calculatedPartialInterest > 0 &&
          remaining > 0 &&
          _declaredType == 'CANCEL') {
        final partialToApply = remaining >= _calculatedPartialInterest
            ? _calculatedPartialInterest
            : remaining;
        if (partialToApply > 0) {
          allocations.add(
            PaymentAllocation(
              allocationId: const Uuid().v4(),
              paymentId: paymentId,
              loanId: _selectedLoan!.loanId,
              allocationType: 'INTEREST', // Counted as interest for earnings
              amount: partialToApply,
              billingCycleId: null, // No associated cycle for partial
              createdAt: now,
            ),
          );
          remaining -= partialToApply;
        }
      }

      // Allocate to principal if allowed
      if (_declaredType != 'INTEREST' && remaining > 0) {
        final toPrincipal = remaining > _selectedLoan!.principalBalance
            ? _selectedLoan!.principalBalance
            : remaining;
        if (toPrincipal > 0) {
          allocations.add(
            PaymentAllocation(
              allocationId: const Uuid().v4(),
              paymentId: paymentId,
              loanId: _selectedLoan!.loanId,
              allocationType: 'PRINCIPAL',
              amount: toPrincipal,
              createdAt: now,
            ),
          );
        }
      }

      // Save payment with allocations
      final createdPayment = await ref
          .read(paymentsProvider.notifier)
          .registerPayment(payment, allocations);

      _handleSuccessAndRefresh(createdPayment);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSuccessAndRefresh(Payment? createdPayment) {
    if (mounted) {
      // Refresh ALL related providers to update UI everywhere
      ref.invalidate(appSettingsProvider); // Force settings refresh
      ref.invalidate(cobrarProvider);
      ref.invalidate(loansProvider);
      ref.invalidate(
        activeLoansByCustomerProvider(_selectedCustomer!.customerId),
      );
      ref.invalidate(loansByCustomerProvider(_selectedCustomer!.customerId));
      ref.invalidate(allPaymentsProvider);

      // Refresh loan detail and billing cycles for the specific loan
      ref.invalidate(loanByIdProvider(_selectedLoan!.loanId));
      ref.invalidate(billingCyclesByLoanProvider(_selectedLoan!.loanId));
      ref.invalidate(paymentsByLoanProvider(_selectedLoan!.loanId));

      // Refresh dashboard stats
      ref.read(dashboardProvider.notifier).refresh();

      // Invalidate loan calculation cache to force update on previous screen
      ref.invalidate(loanCalculationProvider);
      if (_selectedLoan != null) {
        ref.invalidate(loanByIdProvider(_selectedLoan!.loanId));
        ref.invalidate(pendingBillingCyclesProvider(_selectedLoan!.loanId));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdPayment != null
                ? 'Pago registrado - Recibo #${createdPayment.receiptNumber}'
                : 'Recuperación registrada con éxito',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  void _handleError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.danger)),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
