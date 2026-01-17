import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/billing_cycle.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/models/payment.dart';
import 'package:prestamos_app/data/models/payment_allocation.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:prestamos_app/presentation/screens/settings/currency_selection_screen.dart';
import 'package:prestamos_app/presentation/widgets/modals/currency_calculator_modal.dart';
import 'package:prestamos_app/services/idempotency_service.dart';
import 'package:prestamos_app/services/services.dart';
import 'package:sealed_currencies/sealed_currencies.dart';
import 'package:uuid/uuid.dart';

/// Pantalla de formulario para registrar pagos.
class PaymentFormScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [PaymentFormScreen].
  const PaymentFormScreen({super.key, this.customerId, this.loanId});

  /// Identificador opcional del cliente.
  final String? customerId;

  /// Identificador opcional del préstamo.
  final String? loanId;

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
  bool _enableCapitalRestriction = true;
  int _capitalRestrictionDays = 10;

  // Cross-Currency State
  String? _paymentCurrency; // The actual currency received (e.g., NIO)
  final _exchangeRateController = TextEditingController();
  double? _officialSellRate; // For profit calculation
  Timer? _debounceRate;

  // Allocation preview
  double _toOverdueInterest = 0;
  double _toCurrentInterest = 0;
  double _toPrincipal = 0;

  // Calculated debt for cancellation
  double _calculatedTotalDebt = 0;

  double _calculatedPartialInterest = 0;

  /// Detects if the selected loan uses Level Installment (cuota nivelada)
  /// meaning it has a plan with distributeCapitalAndInterest = true
  bool get _isLevelInstallmentLoan =>
      _selectedLoan?.planId != null &&
      (_selectedLoan?.distributeCapitalAndInterest ?? false);

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateAllocation);
    _exchangeRateController.addListener(_calculateAllocation);
    _loadSettings();
    _initializeFromParams();
    _loadOfficialRate();
  }

  Future<void> _loadOfficialRate() async {
    // Determine target currencies (assuming USD/NIO pair usually)
    // In a real generic app, we'd check Loan Currency vs System Currency.
    // Here we assume if Loan is USD, we might check NIO rate.
    // Safe default: Fetch USD->NIO Sell Rate from service
    // Here we assume if Loan is USD, we might check NIO rate.
    // Safe default: Fetch USD->NIO Sell Rate from service
    try {
      // Logic placeholder for future rate fetching
    } on Exception catch (_) {}
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    if (mounted) {
      setState(() {
        _dailyAccrualEnabled = settings.dailyAccrualEnabled;
        _enableCapitalRestriction = settings.enableCapitalRestriction;
        _capitalRestrictionDays = settings.capitalRestrictionDays;
      });
    }
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
        final cycleService = ref.read(billingCycleServiceProvider);

        await cycleService.generateMissingCycles(loan);
      } on Exception catch (_) {
        // Log error suppressed for production
      }
    }

    // Now load all pending cycles (including newly generated ones)
    final repo = ref.read(billingCycleRepositoryProvider);
    final cycles = await repo.getPendingCyclesByLoan(loanId);

    // FETCH ACTIVE CYCLE REGARDLESS OF STATUS (for capital restriction check)
    // Even if the current cycle is PAID (interest paid), we need it to validate
    // the capital payment date restriction.
    final activeCycle = await repo.getActiveCycle(loanId, DateTime.now());

    final finalCycles = List<BillingCycle>.from(cycles);
    if (activeCycle != null) {
      // Check if active cycle is already in the list
      final exists = finalCycles.any(
        (c) => c.billingCycleId == activeCycle.billingCycleId,
      );
      if (!exists) {
        finalCycles
          ..add(activeCycle)
          // Sort by due date again to keep order
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      }
    }

    if (mounted) {
      setState(() => _pendingCycles = finalCycles);
      _recalculateDebt();

      // AUTO-FILL AMOUNT FOR PLANS (Level Installment)
      double suggestedAmount = 0;
      final hasPlan = _selectedLoan?.planId != null;

      if (hasPlan) {
        // Smart Suggestion: Sum of Overdue + First Pending Cycle
        // Filter cycles with actual pending amount > 0
        final pendingCyclesWithAmount = finalCycles
            .where(
              (c) =>
                  c.status != 'PAID' &&
                  (c.installmentPending ?? c.installmentExpected ?? 0) > 0.01,
            )
            .toList();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        var addedFirstPending = false;

        for (final c in pendingCyclesWithAmount) {
          final amount = c.installmentPending ?? c.installmentExpected ?? 0;
          final isOverdue = c.status == 'OVERDUE' || c.dueDate.isBefore(today);

          // Always add overdue cycles
          if (isOverdue) {
            suggestedAmount += amount;
          }
          // Add the first non-overdue cycle (current/next due) and stop
          else if (!addedFirstPending) {
            suggestedAmount += amount;
            addedFirstPending = true;
            break;
          }
        }
      }

      if (suggestedAmount > 0) {
        _amountController.text = _formatMoney(suggestedAmount);
        // Optionally suggest 'MIXED' type or ensure it relies on standard distribution
      }

      _calculateAllocation();
    }
  }

  /// Recalculate total debt considering partial interest if enabled
  /// Uses centralized InterestCalculationService
  void _recalculateDebt() {
    if (_selectedLoan == null) {
      setState(() {
        _calculatedTotalDebt = 0;

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
      _calculatedPartialInterest = result.proportionalInterest;
      _calculatedTotalDebt = result.totalDebt;
    });
  }

  double _convertAmountIfNeeded(double amountInLoanCurrency) {
    if (_selectedLoan == null) return amountInLoanCurrency;
    final loanCurrency = _selectedLoan!.currencyCode;
    final paymentCurrency = _paymentCurrency ?? loanCurrency;

    if (loanCurrency == paymentCurrency) return amountInLoanCurrency;

    // Rate convention: 1 paymentCurrency = rate loanCurrency
    // Example: rate=37 means 1 USD = 37 NIO
    // To convert FROM loanCurrency TO paymentCurrency: DIVIDE
    // Example: 1000 NIO / 37 = 27.03 USD
    final rate = double.tryParse(_exchangeRateController.text);
    if (rate != null && rate > 0) {
      return amountInLoanCurrency / rate;
    }

    return amountInLoanCurrency;
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

    // Load Recovery Priority from settings
    final settings = ref.read(appSettingsProvider).value;
    final recoveryPriority = settings?.recoveryPriority ?? 'CAPITAL_FIRST';

    // Apply conversion if needed using centralized FxService
    // Fix: Handle comma as decimal separator
    final rateRaw = _exchangeRateController.text.replaceAll(',', '.');
    final rate = double.tryParse(rateRaw);
    final loanCurrency = _selectedLoan!.currencyCode;
    final paymentCurrency = _paymentCurrency ?? loanCurrency;
    final baseCurrency = settings?.baseCurrency ?? 'NIO';

    var effectiveAmount = amount;
    if (loanCurrency != paymentCurrency && rate != null && rate > 0) {
      final amountMinor = (amount * 100).round();
      final convertedMinor = FxService.convertMinor(
        amountMinor: amountMinor,
        rate: rate,
        fromCurrency: paymentCurrency,
        toCurrency: loanCurrency,
        baseCurrency: baseCurrency,
      );
      effectiveAmount = convertedMinor / 100.0;
    }

    // Call CENTRALIZED Service
    // This returns a PaymentDistribution object with exact amounts
    final distribution = InterestCalculationService.instance
        .calculatePaymentAllocation(
          loan: _selectedLoan!,
          paymentAmount: effectiveAmount,
          pendingCycles: _pendingCycles,
          paymentType: _declaredType,
          dailyAccrualEnabled: _dailyAccrualEnabled,
          paymentDate: _paymentDate,
          recoveryPriority: recoveryPriority,
        );

    setState(() {
      _toOverdueInterest = distribution.toOverdueInterest;
      _toCurrentInterest = distribution.toCurrentInterest;
      _toPrincipal = distribution.toPrincipal;
    });
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_calculateAllocation)
      ..dispose();
    _exchangeRateController.dispose();
    _debounceRate?.cancel();
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
              // Amount
              // Payment Currency (Row 1)
              _buildPaymentCurrencySelector(),
              const SizedBox(height: 16),

              // Exchange Rate (Row 2 - Moved Up)
              if (_selectedLoan != null) _buildExchangeRateSection(),
              if (_selectedLoan != null) const SizedBox(height: 16),

              // Amount (Row 3 - Moved Down)
              AppTextField(
                label: S.of(context).paymentAmountLabel,
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixText:
                    _paymentCurrency != null &&
                        _paymentCurrency != (_selectedLoan?.currencyCode ?? '')
                    ? '${FiatCurrency.maybeFromCode(_paymentCurrency)?.symbol ?? _paymentCurrency} '
                    : '$_currencySymbol ',
                suffix: IconButton(
                  icon: const Icon(Icons.calculate_outlined),
                  tooltip: 'Calculadora de Divisas',
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CurrencyCalculatorModal(
                        initialSourceCurrency:
                            _paymentCurrency ??
                            _selectedLoan?.currencyCode ??
                            'USD',
                        initialTargetCurrency:
                            _selectedLoan?.currencyCode ?? 'USD',
                        initialAmount: double.tryParse(
                          _amountController.text.replaceAll(',', ''),
                        ),
                        onTakeAmount: (result, currency, rate) {
                          setState(() {
                            _amountController.text = _formatMoney(result);
                            _paymentCurrency = currency;
                            _exchangeRateController.text = rate.toStringAsFixed(
                              4,
                            );
                            _officialSellRate = rate;
                          });
                        },
                      ),
                    );
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return S.of(context).fieldRequired;
                  }
                  final amount = double.tryParse(v.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return S.of(context).invalidAmountMsg;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

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
                      '${S.of(context).originalAmount}: C\$ ${_formatMoney(loan.principalOriginal)} - ${loan.monthlyInterestRate.toStringAsFixed(2)}% ${S.of(context).monthly}',
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
                      '${S.of(context).capital}: $_currencySymbol ${_formatMoney(_selectedLoan!.principalBalance)}',
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      '${S.of(context).pendingInterest}: $_currencySymbol ${_formatMoney(totalPendingInterest)}',
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
                          // For Level Installment: show full installment amount
                          // For Traditional: show only interest
                          '$_currencySymbol ${_formatMoney(_isLevelInstallmentLoan ? (cycle.installmentPending ?? cycle.interestPending) : cycle.interestPending)}',
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
    final l10n = S.of(context);

    // For Level Installment loans: disable MIXED, INTEREST, PRINCIPAL
    // Keep CANCEL and RECOVERY enabled
    final disableStandardTypes = _isLevelInstallmentLoan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.paymentType, style: AppTypography.labelMedium),

        // Show Plan Installment indicator for Level Installment loans
        if (_isLevelInstallmentLoan) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  l10n.planInstallmentMode,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.paymentTypeMixed),
              selected: _declaredType == 'MIXED',
              // Disable for Level Installment but auto-select MIXED internally
              onSelected: disableStandardTypes
                  ? null
                  : (_) {
                      setState(() {
                        _declaredType = 'MIXED';
                        _amountController.clear();
                      });
                      _recalculateDebt();
                      _calculateAllocation();
                    },
            ),
            ChoiceChip(
              label: Text(l10n.typeInterest),
              selected: _declaredType == 'INTEREST',
              onSelected: disableStandardTypes
                  ? null
                  : (_) {
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

                        _calculatedPartialInterest =
                            result.proportionalInterest;
                        _calculatedTotalDebt = result.totalDebt;

                        // Set text explicitly with auto-conversion
                        final converted = _convertAmountIfNeeded(
                          result.totalPendingInterest,
                        );
                        _amountController.text = _formatMoney(converted);
                      });
                      _calculateAllocation();
                    },
            ),
            ChoiceChip(
              label: Text(l10n.typePrincipal),
              selected: _declaredType == 'PRINCIPAL',
              onSelected: disableStandardTypes
                  ? null
                  : (_) {
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

                        _calculatedPartialInterest =
                            result.proportionalInterest;
                        _calculatedTotalDebt = result.totalDebt;

                        // Auto-convert principal if needed
                        final converted = _convertAmountIfNeeded(
                          result.principalBalance,
                        );
                        _amountController.text = _formatMoney(converted);
                      });
                      _calculateAllocation();
                    },
            ),
            // CANCEL - Always enabled
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  Text(l10n.typeCancel),
                ],
              ),
              selected: _declaredType == 'CANCEL',
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) {
                // DEBUG: Trace Cancel calculation
                debugPrint(
                  'CANCEL_PRESSED: _pendingCycles.length=${_pendingCycles.length}',
                );
                for (final c in _pendingCycles) {
                  debugPrint(
                    '  Cycle ${c.cycleNumber}: interestPending=${c.interestPending}, dueDate=${c.dueDate}',
                  );
                }

                final result = InterestCalculationService.instance
                    .calculateTotalDebt(
                      loan: _selectedLoan!,
                      pendingCycles: _pendingCycles,
                      paymentDate: _paymentDate,
                      paymentType: 'CANCEL', // Force type
                      dailyAccrualEnabled: _dailyAccrualEnabled,
                    );

                debugPrint(
                  'CANCEL_RESULT: totalDebt=${result.totalDebt}, overdueInterest=${result.overdueInterest}, currentCycleInterest=${result.currentCycleInterest}',
                );

                setState(() {
                  _declaredType = 'CANCEL';
                  _calculatedPartialInterest = result.proportionalInterest;
                  _calculatedTotalDebt = result.totalDebt;

                  // Auto-convert total debt
                  final converted = _convertAmountIfNeeded(result.totalDebt);
                  _amountController.text = _formatMoney(converted);
                });
                _calculateAllocation();
              },
            ),
            // RECOVERY - Always enabled
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handshake, size: 16),
                  const SizedBox(width: 4),
                  Text(l10n.paymentTypeRecovery),
                ],
              ),
              selected: _declaredType == 'RECOVERY',
              selectedColor: AppColors.info.withValues(alpha: 0.2),
              onSelected: (_) {
                if (_selectedLoan != null) {
                  setState(() {
                    _declaredType = 'RECOVERY';
                    // For Recovery, we only pay principal

                    _calculatedPartialInterest = 0;
                    _calculatedTotalDebt = _selectedLoan!.principalBalance;

                    // Auto-convert principal balance
                    final converted = _convertAmountIfNeeded(
                      _selectedLoan!.principalBalance,
                    );
                    _amountController.text = _formatMoney(converted);
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
            '$_currencySymbol ${_formatMoney(amount)}',
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

    // Ensure allocations are up to date with current rate inputs
    _calculateAllocation();

    if (_selectedLoan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).selectALoan)));
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
      var restrictCustomer = false;
      final reasonController =
          TextEditingController(); // Local controller for dialog

      if (!mounted) return;
      final secondConfirmation = await showDialog<bool>(
        context: context,
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

      // 3. EXECUTE RECOVERY (Dynamic Allocation)
      setState(() => _isLoading = true);
      try {
        final now = DateTime.now();
        final paymentId = const Uuid().v4();
        final idempotencyKey = const Uuid().v4();

        // Calculate amounts (Loan vs Base)
        final amountMinor = (amount * 100).round();
        final settingsValue = ref.read(appSettingsProvider).value;
        final baseCurrency = settingsValue?.baseCurrency ?? 'NIO';
        final loanCurrency = _selectedLoan!.currencyCode;
        final payCurrency = _paymentCurrency ?? loanCurrency;

        final appliedRate =
            (_paymentCurrency != null && _paymentCurrency != loanCurrency)
            ? double.tryParse(_exchangeRateController.text.replaceAll(',', '.'))
            : null;

        var amountLoanMinor = amountMinor;
        var amountBaseMinor =
            amountMinor; // Approx if conversion not applied yet

        if (appliedRate != null &&
            appliedRate > 0 &&
            payCurrency != loanCurrency) {
          amountLoanMinor = FxService.convertMinor(
            amountMinor: amountMinor,
            rate: appliedRate,
            fromCurrency: payCurrency,
            toCurrency: loanCurrency,
            baseCurrency: baseCurrency,
          );
          amountBaseMinor = amountLoanMinor;
        }

        final payment = Payment(
          paymentId: paymentId,
          loanId: _selectedLoan!.loanId,
          amountPaymentMinor: amountMinor,
          amountBaseMinor: amountBaseMinor,
          amountLoanMinor: amountLoanMinor,
          paymentCurrency: payCurrency,
          loanCurrency: loanCurrency,
          baseCurrency: baseCurrency,
          rateValueUsed: appliedRate,
          rateTypeUsed: appliedRate != null ? 'MANUAL' : null,
          idempotencyKey: idempotencyKey,
          payloadHash: IdempotencyService.computePayloadHash(
            loanId: _selectedLoan!.loanId,
            isoDate: now.toIso8601String().split('T')[0],
            paymentCurrency: payCurrency,
            amountPaymentMinor: amountMinor,
            rateType: null,
            rateValue: null,
          ),
          createdAt: now,
          updatedAt: now,
          customerId: _selectedCustomer!.customerId,
          receiptNumber: 'PENDING',
          declaredType: 'RECOVERY',
          notes: reasonController.text.isNotEmpty
              ? reasonController.text
              : 'Recuperación de Capital',
        );

        // CREATE ALLOCATIONS dynamically based on _calculateAllocation results
        final allocations = <PaymentAllocation>[];

        void addAllocation(String type, double val, {String? cycleId}) {
          if (val >= 0.01) {
            allocations.add(
              PaymentAllocation(
                allocationId: const Uuid().v4(),
                paymentId: paymentId,
                loanId: _selectedLoan!.loanId,
                allocationType: type,
                amountLoanMinor: (val * 100).round(),
                billingCycleId: cycleId,
                createdAt: now,
              ),
            );
          }
        }

        // 1. Overdue Interest
        var remainingForRecovery = _toOverdueInterest;
        for (final cycle in _pendingCycles.where((c) => c.isOverdue)) {
          if (remainingForRecovery <= 0) break;
          final toPay = remainingForRecovery >= cycle.interestPending
              ? cycle.interestPending
              : remainingForRecovery;
          addAllocation('INTEREST', toPay, cycleId: cycle.billingCycleId);
          remainingForRecovery -= toPay;
        }

        // 2. Current Interest
        remainingForRecovery = _toCurrentInterest;
        if (remainingForRecovery > 0) {
          final currentCycle = _pendingCycles.firstWhere(
            (c) => !c.isOverdue && c.status != 'PAID',
            orElse: () => _pendingCycles.last,
          );
          addAllocation(
            'INTEREST',
            remainingForRecovery,
            cycleId: currentCycle.billingCycleId,
          );
        }

        // 3. Principal (Generic)
        addAllocation('PRINCIPAL', _toPrincipal);

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
        await _handleSuccessAndRefresh(
          createdPayment,
          allocations: allocations,
        );
      } on Exception catch (e) {
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
      enableCapitalRestriction: _enableCapitalRestriction,
      daysBeforeCycleForCapital: _capitalRestrictionDays,
      s: S.of(context),
    );

    if (!validation.isValid) {
      await _showErrorDialog(validation.errorTitle!, validation.errorMessage!);
      return;
    }

    // For excess amount when dailyAccrual is disabled, show warning
    final totalApplicable =
        _toOverdueInterest + _toCurrentInterest + _toPrincipal;

    // Fix: For Level Installment, if Amount matches/is close to Full Installment, allow it.
    // This handles cases where _toCurrentInterest logic might erroneously be 0 due to data flags.
    var skipWarning = false;
    if (_isLevelInstallmentLoan) {
      // Find current pending installment amount
      final currentPending = _pendingCycles
          .firstWhere(
            (c) => c.status != 'PAID' && (c.installmentPending ?? 0) > 0,
            orElse: () => _pendingCycles.first,
          )
          .installmentPending;

      // If user is paying exactly the installment (or close), don't warn
      if (currentPending != null && (amount - currentPending).abs() < 1.0) {
        skipWarning = true;
      }
    }

    if (!_dailyAccrualEnabled &&
        !skipWarning &&
        amount > totalApplicable + 0.01) {
      if (!mounted) return;
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
    final paymentSymbol =
        FiatCurrency.maybeFromCode(
          _paymentCurrency ?? _selectedLoan!.currencyCode,
        )?.symbol ??
        r'C$';

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).confirmPaymentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).paymentAmount}: $paymentSymbol ${_formatMoney(amount)}',
            ),
            const SizedBox(height: 8),
            Text(
              '${S.of(context).customer}: ${_selectedCustomer!.alias ?? _selectedCustomer!.fullName}',
            ),
            const SizedBox(height: 8),
            // Show converted values for clarity is implicit in the breakdown below
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
      final idempotencyKey = const Uuid().v4();
      final amountMinor = (amount * 100).round();
      final baseCurrency =
          ref.read(appSettingsProvider).value?.baseCurrency ?? 'NIO';
      final loanCurrency = _selectedLoan!.currencyCode;
      final payCurrency = _paymentCurrency ?? loanCurrency;

      final appliedRate =
          (_paymentCurrency != null && _paymentCurrency != loanCurrency)
          // Fix: Handle comma as decimal separator
          ? double.tryParse(_exchangeRateController.text.replaceAll(',', '.'))
          : null;

      // Calculate amounts in different currencies using CONSOLIDATED LOGIC
      // This ensures Payment record and Allocations use exact same values
      var amountLoanMinor = amountMinor;
      var amountBaseMinor = amountMinor;
      var fxProfitMinor = 0;
      var remainingInLoanCurrency = amount; // Default if no conversion

      if (appliedRate != null &&
          appliedRate > 0 &&
          payCurrency != loanCurrency) {
        // Convert payment amount to loan currency using FxService
        amountLoanMinor = FxService.convertMinor(
          amountMinor: amountMinor,
          rate: appliedRate,
          fromCurrency: payCurrency,
          toCurrency: loanCurrency,
          baseCurrency: baseCurrency,
        );
        amountBaseMinor = amountLoanMinor; // Assuming base = loan for now

        // Correctly set remaining amount for allocations loop
        remainingInLoanCurrency = amountLoanMinor / 100.0;

        // Calculate FX profit
        if (_officialSellRate != null && _officialSellRate! > 0) {
          final received = amount * appliedRate;
          final cost = amount * _officialSellRate!;
          fxProfitMinor = ((received - cost) * 100).round();
        }
      }

      final payment = Payment(
        paymentId: paymentId,
        loanId: _selectedLoan!.loanId,
        amountPaymentMinor: amountMinor,
        amountBaseMinor: amountBaseMinor,
        amountLoanMinor: amountLoanMinor,
        paymentCurrency: payCurrency,
        loanCurrency: loanCurrency,
        baseCurrency: baseCurrency,
        rateTypeUsed: appliedRate != null ? 'MANUAL' : null,
        rateValueUsed: appliedRate,
        fxProfitBaseMinor: fxProfitMinor,
        fxStatus: appliedRate != null ? 'APPLIED' : 'NONE',
        idempotencyKey: idempotencyKey,
        payloadHash: IdempotencyService.computePayloadHash(
          loanId: _selectedLoan!.loanId,
          isoDate: now.toIso8601String().split('T')[0],
          paymentCurrency: payCurrency,
          amountPaymentMinor: amountMinor,
          rateType: appliedRate != null ? 'MANUAL' : null,
          rateValue: appliedRate,
        ),
        createdAt: now,
        updatedAt: now,
        customerId: _selectedCustomer!.customerId,
        receiptNumber: 'PENDING',
        declaredType: _declaredType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Create allocations using the PRE-CALCULATED remainingInLoanCurrency
      // This guarantees consistency with the Payment record
      final allocations = <PaymentAllocation>[];
      var remaining = remainingInLoanCurrency;

      // Calculate total owed based on declaredType to cap allocations
      // This prevents FX conversion excess from being applied to future debt
      final today = DateTime(now.year, now.month, now.day);

      // IMPORTANT: Filter out PAID cycles and cycles with zero pending
      // This prevents stale data from being processed on consecutive payments
      final activePendingCycles = _pendingCycles
          .where(
            (c) =>
                c.status != 'PAID' &&
                (c.installmentPending ?? c.interestPending) > 0.01,
          )
          .toList();

      final overdueCycles = activePendingCycles
          .where((c) => c.dueDate.isBefore(today))
          .toList();
      final currentCycles = activePendingCycles
          .where((c) => !c.dueDate.isBefore(today))
          .toList();

      double totalOwed = 0;
      if (_declaredType == 'INTEREST') {
        // For INTEREST-only, only pay overdue cycles
        // Do NOT include current/pending cycles - FX excess should NOT apply to them
        totalOwed = overdueCycles.fold(0, (sum, c) => sum + c.interestPending);
        // NOTE: We intentionally exclude currentCycles here
        // Any FX conversion excess will be stored in unapplied_minor
      } else if (_declaredType == 'CANCEL') {
        // For CANCEL, include all interest + principal
        totalOwed = overdueCycles.fold(0, (sum, c) => sum + c.interestPending);
        if (_dailyAccrualEnabled && _calculatedPartialInterest > 0) {
          totalOwed += _calculatedPartialInterest;
        } else {
          totalOwed += currentCycles.fold(
            0.0,
            (sum, c) => sum + c.interestPending,
          );
        }
        totalOwed += _selectedLoan!.principalBalance;
      } else {
        // MIXED: all interest + principal
        totalOwed = overdueCycles.fold(0, (sum, c) => sum + c.interestPending);
        totalOwed += currentCycles.fold(
          0.0,
          (sum, c) => sum + c.interestPending,
        );
        totalOwed += _selectedLoan!.principalBalance;
      }

      // Cap allocation to total owed - any excess is FX profit, not debt reduction
      final effectiveRemaining = remaining > totalOwed ? totalOwed : remaining;
      final fxExcess = remaining > totalOwed ? remaining - totalOwed : 0.0;
      remaining = effectiveRemaining;

      // --- LEVEL INSTALLMENT DETECTION ---
      // A loan uses Level Installment (cuota nivelada) if it has a plan
      // with distributeCapitalAndInterest = true
      final isLevelInstallment =
          _selectedLoan!.planId != null &&
          (_selectedLoan!.distributeCapitalAndInterest ?? false);

      // For Level Installment: pay each cycle COMPLETELY (Interest + Principal)
      // before moving to the next cycle.
      // For Traditional: pay all Interest first, then Principal globally.

      if (isLevelInstallment) {
        // --- LEVEL INSTALLMENT ALLOCATION ---
        // Sort all pending cycles by due date (oldest first)
        final sortedCycles = [...overdueCycles, ...currentCycles]
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        for (final cycle in sortedCycles) {
          if (remaining <= 0) break;

          // 1. Pay Interest for this cycle
          final interestPending = cycle.interestPending;
          if (interestPending > 0 && remaining > 0) {
            final toApply = remaining >= interestPending
                ? interestPending
                : remaining;
            if (toApply >= 0.01) {
              allocations.add(
                PaymentAllocation(
                  allocationId: const Uuid().v4(),
                  paymentId: paymentId,
                  loanId: _selectedLoan!.loanId,
                  allocationType: 'INTEREST',
                  amountLoanMinor: (toApply * 100).round(),
                  billingCycleId: cycle.billingCycleId,
                  createdAt: now,
                ),
              );
              remaining -= toApply;
            }
          }

          // 2. Pay Principal PORTION for this cycle
          // Principal portion = installmentPending - interestPending
          // Or use cycle.principalPortion if available
          final installmentPending =
              cycle.installmentPending ?? interestPending;
          var principalPortion = (installmentPending - interestPending).clamp(
            0.0,
            double.infinity,
          );

          // Fallback: Use stored principalPortion if calculation returns 0
          if (principalPortion <= 0 && (cycle.principalPortion ?? 0) > 0) {
            principalPortion = cycle.principalPortion!;
          }

          if (principalPortion > 0 && remaining > 0) {
            final toApply = remaining >= principalPortion
                ? principalPortion
                : remaining;
            if (toApply >= 0.01) {
              allocations.add(
                PaymentAllocation(
                  allocationId: const Uuid().v4(),
                  paymentId: paymentId,
                  loanId: _selectedLoan!.loanId,
                  allocationType: 'PRINCIPAL',
                  amountLoanMinor: (toApply * 100).round(),
                  billingCycleId: cycle.billingCycleId,
                  createdAt: now,
                ),
              );
              remaining -= toApply;
            }
          }
        }
      } else {
        // --- TRADITIONAL LOAN ALLOCATION ---
        // (Original logic: pay all interest first, then principal globally)

        // Allocate to overdue cycles first
        for (final cycle in overdueCycles) {
          if (remaining <= 0) break;
          final toApply = remaining >= cycle.interestPending
              ? cycle.interestPending
              : remaining;

          if (toApply >= 0.01) {
            allocations.add(
              PaymentAllocation(
                allocationId: const Uuid().v4(),
                paymentId: paymentId,
                loanId: _selectedLoan!.loanId,
                allocationType: 'INTEREST',
                amountLoanMinor: (toApply * 100).round(),
                billingCycleId: cycle.billingCycleId,
                createdAt: now,
              ),
            );
            remaining -= toApply;
          }
        }

        // Allocate to current cycles (only for non-CANCEL or when dailyAccrual disabled)
        if (_declaredType != 'CANCEL' || !_dailyAccrualEnabled) {
          for (final cycle in currentCycles) {
            if (remaining <= 0) break;
            final toApply = remaining >= cycle.interestPending
                ? cycle.interestPending
                : remaining;

            if (toApply >= 0.01) {
              allocations.add(
                PaymentAllocation(
                  allocationId: const Uuid().v4(),
                  paymentId: paymentId,
                  loanId: _selectedLoan!.loanId,
                  allocationType: 'INTEREST',
                  amountLoanMinor: (toApply * 100).round(),
                  billingCycleId: cycle.billingCycleId,
                  createdAt: now,
                ),
              );
              remaining -= toApply;
            }
          }
        }

        // Allocate partial interest (proportional for days) for CANCEL with daily accrual
        if (_dailyAccrualEnabled &&
            _calculatedPartialInterest > 0 &&
            remaining > 0 &&
            _declaredType == 'CANCEL') {
          final partialToApply = remaining >= _calculatedPartialInterest
              ? _calculatedPartialInterest
              : remaining;
          if (partialToApply >= 0.01) {
            allocations.add(
              PaymentAllocation(
                allocationId: const Uuid().v4(),
                paymentId: paymentId,
                loanId: _selectedLoan!.loanId,
                allocationType: 'INTEREST',
                amountLoanMinor: (partialToApply * 100).round(),
                createdAt: now,
              ),
            );
            remaining -= partialToApply;
          }
        }

        // Allocate to principal (global, not per-cycle)
        if (_declaredType != 'INTEREST' && remaining >= 0.01) {
          final toPrincipal = remaining > _selectedLoan!.principalBalance
              ? _selectedLoan!.principalBalance
              : remaining;
          if (toPrincipal >= 0.01) {
            allocations.add(
              PaymentAllocation(
                allocationId: const Uuid().v4(),
                paymentId: paymentId,
                loanId: _selectedLoan!.loanId,
                allocationType: 'PRINCIPAL',
                amountLoanMinor: (toPrincipal * 100).round(),
                createdAt: now,
              ),
            );
          }
        }
      }

      // Update payment with FX excess stored as unapplied_minor
      final paymentWithUnapplied = fxExcess > 0
          ? payment.copyWith(unappliedMinor: (fxExcess * 100).round())
          : payment;

      // Save payment with allocations
      final createdPayment = await ref
          .read(paymentsProvider.notifier)
          .registerPayment(paymentWithUnapplied, allocations);

      await _handleSuccessAndRefresh(createdPayment, allocations: allocations);
    } on Exception catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessAndRefresh(
    Payment? createdPayment, {
    required List<PaymentAllocation> allocations,
  }) async {
    if (mounted) {
      // Refresh ALL related providers to update UI everywhere
      ref
        ..invalidate(appSettingsProvider) // Force settings refresh
        ..invalidate(cobrarProvider)
        ..invalidate(loansProvider)
        ..invalidate(
          activeLoansByCustomerProvider(_selectedCustomer!.customerId),
        )
        ..invalidate(loansByCustomerProvider(_selectedCustomer!.customerId))
        ..invalidate(allPaymentsProvider)
        // Refresh loan detail and billing cycles for the specific loan
        ..invalidate(loanByIdProvider(_selectedLoan!.loanId))
        ..invalidate(billingCyclesByLoanProvider(_selectedLoan!.loanId))
        ..invalidate(paymentsByLoanProvider(_selectedLoan!.loanId));

      // Refresh dashboard stats
      await ref.read(dashboardProvider.notifier).refresh();

      // Invalidate loan calculation cache to force update on previous screen
      ref.invalidate(loanCalculationProvider);
      if (_selectedLoan != null) {
        ref
          ..invalidate(loanByIdProvider(_selectedLoan!.loanId))
          ..invalidate(pendingBillingCyclesProvider(_selectedLoan!.loanId));

        // CRITICAL: Refresh local _pendingCycles to prevent stale data
        // on consecutive payments within the same session
        await _loadPendingCycles(_selectedLoan!.loanId);
      }

      // TRIGGER AUTO BACKUP
      final backupSettings = ref.read(appSettingsProvider).value;
      if (backupSettings != null && backupSettings.backupOnPayment) {
        unawaited(
          ref
              .read(backupServiceProvider)
              .createBackup(customName: backupSettings.backupCustomName),
        );
      }

      // Check for WhatsApp Auto-Share
      if (createdPayment != null) {
        final settings = await ref
            .read(settingsRepositoryProvider)
            .getSettings();
        if (settings.shareReceiptsWhatsApp) {
          final customer = _selectedCustomer!;
          if (WhatsAppService.isValidNumber(customer.phone) && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).sendingToWhatsApp)),
            );

            // Use LOAN currency for client-facing documents, not global settings
            FiatCurrency loanCurrency;
            try {
              loanCurrency = FiatCurrency.fromCode(_selectedLoan!.currencyCode);
            } on Exception catch (_) {
              loanCurrency = FiatCurrency.fromCode('NIO');
            }

            // FETCH FRESH LOAN OBJECT to ensure PDF has updated balance
            final locale = Localizations.localeOf(context);
            Loan? updatedLoan;
            try {
              updatedLoan = await ref.read(
                loanByIdProvider(_selectedLoan!.loanId).future,
              );
            } on Exception catch (_) {
              // Ignore error fetching updated loan
            }

            if (!mounted) return;
            await WhatsAppService.sharePaymentReceipt(
              payment: createdPayment,
              loan: updatedLoan ?? _selectedLoan!, // Use fresh or fallback
              customer: customer,
              allocations: allocations,
              settings: settings,
              locale: locale,
              currencySymbol: loanCurrency.symbol ?? loanCurrency.code,
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).noValidWhatsAppNumber),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }

      if (mounted) {
        // Show success snackbar first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).paymentSuccess),
            backgroundColor: AppColors.success,
          ),
        );

        // Check if loan is paid off (balance = 0) and show rating dialog
        if (!mounted) return;
        final updatedLoan = await ref.read(
          loanByIdProvider(_selectedLoan!.loanId).future,
        );
        if (updatedLoan != null && updatedLoan.principalBalance <= 0) {
          if (!mounted) return;
          await _showRatingDialog();
        }

        if (mounted) {
          context.pop();
        }
      }
    }
  }

  void _handleError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  /// Show dialog to rate customer after loan payoff
  Future<void> _showRatingDialog() async {
    if (_selectedCustomer == null) return;

    final categories = await ref.read(customerCategoriesProvider.future);
    if (categories.isEmpty || !mounted) return;

    String? selectedCategoryId;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(S.of(context).rateThisCustomer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context).rateCustomerPrompt),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: selectedCategoryId,
                decoration: InputDecoration(
                  labelText: S.of(context).customerCategory,
                  border: const OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem<String?>(
                        value: cat.categoryId,
                        child: Text(cat.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => selectedCategoryId = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'not_now'),
              child: Text(S.of(context).notNow),
            ),
            FilledButton(
              onPressed: () {
                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(S.of(context).mustSelectCategory)),
                  );
                  return;
                }
                Navigator.pop(ctx, selectedCategoryId);
              },
              child: Text(S.of(context).rateCustomer),
            ),
          ],
        ),
      ),
    );

    // Handle result
    if (result != null && result != 'cancel' && result != 'not_now') {
      // Update customer category
      final repo = ref.read(customerRepositoryProvider);
      final updatedCustomer = _selectedCustomer!.copyWith(
        categoryId: result,
        updatedAt: DateTime.now(),
      );
      await repo.updateCustomer(updatedCustomer);
      ref.invalidate(customersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).customerRated),
            backgroundColor: AppColors.success,
          ),
        );
      }
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

  String get _currencySymbol {
    if (_selectedLoan == null) return r'C$';
    return FiatCurrency.maybeFromCode(_selectedLoan!.currencyCode)?.symbol ??
        r'C$';
  }

  Widget _buildPaymentCurrencySelector() {
    if (_selectedLoan == null) return const SizedBox.shrink();

    final currentCode = _paymentCurrency ?? _selectedLoan!.currencyCode;
    final fiat = FiatCurrency.maybeFromCode(currentCode);
    final displayText = '${fiat?.name ?? currentCode} ($currentCode)';

    return InkWell(
      onTap: () async {
        final newCode = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CurrencySelectionScreen(initialValue: currentCode),
          ),
        );

        if (newCode == null) return;

        setState(() => _paymentCurrency = newCode);

        if (newCode != _selectedLoan!.currencyCode) {
          final service = ref.read(currencyServiceProvider);
          if (service.hasValue) {
            try {
              final rate = await service.requireValue.getDisbursementRate(
                _selectedLoan!.currencyCode,
                newCode,
              );

              setState(() {
                _officialSellRate = rate;
                _exchangeRateController.text = rate.toStringAsFixed(4);
              });
            } on Exception catch (_) {}
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: S.of(context).paymentCurrency,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.monetization_on_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          displayText,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    if (_selectedLoan == null) return const SizedBox.shrink();

    final loanCurrency = _selectedLoan!.currencyCode;
    if (_paymentCurrency == null || _paymentCurrency == loanCurrency) {
      return const SizedBox.shrink();
    }

    return AppCard(
      title: S.of(context).exchangeRateLabel,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: S.of(context).appliedRate,
                  controller: _exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}), // Trigger recalc
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Tasa oficial: ${_officialSellRate?.toStringAsFixed(4) ?? "N/A"}. La diferencia se registrará como utilidad cambiaria.',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEquivalentCalculation(),
        ],
      ),
    );
  }

  Widget _buildEquivalentCalculation() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_exchangeRateController.text) ?? 0;

    if (amount <= 0 || rate <= 0) return const SizedBox.shrink();

    final equivalent = amount * rate;
    // Use LOAN currency symbol since 'equivalent' is in loan currency after conversion
    final loanCurrencyCode = _selectedLoan?.currencyCode ?? 'NIO';
    final symbol =
        FiatCurrency.maybeFromCode(loanCurrencyCode)?.symbol ??
        loanCurrencyCode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.currency_exchange,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cobrar al Cliente: $symbol ${_formatMoney(equivalent)}',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
