import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/logic/loan_calculator.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/currency_context.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/models/payment_frequency.dart';
import 'package:prestamos_app/data/models/payment_plan.dart';
import 'package:prestamos_app/data/providers/business_policy_provider.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:prestamos_app/presentation/screens/frequencies/payment_frequency_selection_screen.dart';
import 'package:prestamos_app/services/backup_service.dart';
import 'package:prestamos_app/services/whatsapp_service.dart';
import 'package:sealed_currencies/sealed_currencies.dart';
import 'package:uuid/uuid.dart';

/// Pantalla de formulario de préstamo para crear nuevos préstamos con Riverpod.
class LoanFormScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [LoanFormScreen].
  const LoanFormScreen({required this.customerId, super.key});

  /// The ID of the customer for whom the loan is being created.
  final String customerId;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController(text: '20');
  final _notesController = TextEditingController();
  DateTime _disbursementDate = DateTime.now();
  DateTime? _endDate; // Optional informational end date
  PaymentFrequency? _selectedFrequency;
  String _selectedCurrencyCode = 'NIO'; // Default currency
  double? _appliedExchangeRate; // Exchange Rate State
  bool _isLoadingRate = false;
  PaymentPlan? _selectedPlan; // Selected Plan
  final TextEditingController _exchangeRateController = TextEditingController();

  bool _isLoading = false;
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _initializeCurrency();
    _loadCustomer();
    _loadDefaultFrequency();
  }

  Future<void> _loadDefaultFrequency() async {
    // Optional: Load default frequency (e.g. Monthly)
    try {
      final frequencies = await ref.read(
        activePaymentFrequenciesProvider.future,
      );
      if (frequencies.isNotEmpty && mounted) {
        final monthly = frequencies.where((f) => f.id == 'MONTHLY').firstOrNull;
        setState(() {
          _selectedFrequency = monthly ?? frequencies.first;
        });
      }
    } on Exception catch (_) {
      // Ignore error, user will select manually
    }
  }

  void _initializeCurrency() {
    final settings = ref.read(appSettingsProvider).value;
    // EMERGENCY FIX: Default to Base Currency (not USD)
    _selectedCurrencyCode = settings?.baseCurrency ?? 'NIO';
    // No need to load exchange rate if defaulting to base
  }

  /// Load exchange rate from CurrencyService when currency is not base currency
  /// EMERGENCY FIX: Use TODAY's rate ONLY, block if not found
  Future<void> _loadExchangeRate() async {
    final settings = ref.read(appSettingsProvider).value;
    final baseCurrency = settings?.baseCurrency ?? 'NIO';

    // Only load rate if loan currency differs from base currency
    if (_selectedCurrencyCode == baseCurrency) {
      setState(() {
        _appliedExchangeRate = null;
        _exchangeRateController.clear();
        _isLoadingRate = false;
      });
      return;
    }

    setState(() => _isLoadingRate = true);

    try {
      final currencyService = await ref.read(currencyServiceProvider.future);
      // STRICT: Check for TODAY's rate only
      final hasTodayRate = await currencyService.hasTodayRate(
        _selectedCurrencyCode,
        baseCurrency,
      );

      if (!hasTodayRate) {
        // No TODAY rate - show blocking dialog
        if (mounted) {
          setState(() {
            _appliedExchangeRate = null;
            _exchangeRateController.clear();
            _isLoadingRate = false;
          });
          _showNoRateDialog();
        }
        return;
      }

      // Get the rate
      final rate = await currencyService.getRate(
        _selectedCurrencyCode,
        baseCurrency,
        type: settings?.disbursementRateType ?? 'SELL',
      );

      if (mounted) {
        setState(() {
          _appliedExchangeRate = rate;
          _exchangeRateController.text = rate.toStringAsFixed(4);
          _isLoadingRate = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() {
          _appliedExchangeRate = null;
          _exchangeRateController.clear();
          _isLoadingRate = false;
        });
        _showNoRateDialog();
      }
    }
  }

  /// Show dialog when no TODAY's rate exists
  void _showNoRateDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).warning),
        content: Text(S.of(context).noExchangeRateToday),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Reset to base currency
              final settings = ref.read(appSettingsProvider).value;
              setState(() {
                _selectedCurrencyCode = settings?.baseCurrency ?? 'NIO';
              });
            },
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate to exchange rates screen
              context.push('/settings/exchange-rates');
            },
            child: Text(S.of(context).goToExchangeRates),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCustomer() async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerById(widget.customerId);
      if (customer != null && mounted) {
        setState(() => _customer = customer);

        // CHECK RESTRICTION
        if (customer.isRestricted) {
          // Show dialog after build
          // ignore: unawaited_futures
          Future.microtask(() async {
            if (mounted) await _showRestrictionDialog(customer);
          });
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).errorLoadCustomer}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showRestrictionDialog(Customer customer) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.of(context).restrictedCustomerTitle,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).restrictedCustomerWarning,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(S.of(context).reasonLabel),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                customer.restrictionReason ?? S.of(context).noReasonSpecified,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            Text(S.of(context).continueAnywayPrompt),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text(S.of(context).cancelReturn),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(S.of(context).ignoreAndContinue),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayCurrency = FiatCurrency.maybeFromCode(_selectedCurrencyCode);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).newLoan)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildPlanSelector(),
            const SizedBox(height: 24),
            _buildCurrencySelector(),
            const SizedBox(height: 16),
            // Exchange rate field (always visible, right after currency)
            _buildExchangeRateField(),
            const SizedBox(height: 16),
            AppMoneyField(
              label: S.of(context).loanAmountLabel,
              controller: _principalController,
              currencySymbol: displayCurrency?.symbol ?? r'$',
              validator: (v) {
                if (v == null || v.isEmpty) return S.of(context).fieldRequired;
                final amount = double.tryParse(v.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return S.of(context).invalidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: S.of(context).monthlyRateLabel,
              controller: _rateController,
              prefixIcon: Icons.percent,
              enabled:
                  _selectedPlan == null ||
                  (_selectedPlan?.allowCurrencyChange ?? true),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return S.of(context).fieldRequired;
                final rate = double.tryParse(v);
                if (rate == null || rate <= 0 || rate > 100) {
                  return S.of(context).invalidRate;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _buildRateInfo(),
            const SizedBox(height: 24),
            _buildFrequencySelector(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildEndDatePicker(),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            AppTextField(
              label: S.of(context).notes,
              hint: S.of(context).loanObservations,
              controller: _notesController,
              prefixIcon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 32),
            AppButton(
              label: S.of(context).createLoanAction,
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateField() {
    final settings = ref.watch(appSettingsProvider).value;
    final baseCurrency = settings?.baseCurrency ?? 'NIO';
    final allowManual = settings?.allowManualExchangeRate ?? false;

    // If currencies match, strictly show 1.0 (or hide logic, but here we show field disabled)
    final isSameCurrency = _selectedCurrencyCode == baseCurrency;
    final canEdit = allowManual && !isSameCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).appliedExchangeRate,
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: _isLoadingRate
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '1 $_selectedCurrencyCode = ',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextFormField(
                                controller: _exchangeRateController,
                                enabled: canEdit,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: canEdit
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  suffixText: baseCurrency,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: canEdit
                                      ? const OutlineInputBorder()
                                      : InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final newRate = double.tryParse(value);
                                  if (newRate != null) {
                                    setState(() {
                                      _appliedExchangeRate = newRate;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_isLoadingRate)
                        Text(
                          'Cargando tasa...',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (canEdit)
                        Text(
                          'Puede editar la tasa manualmente',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.infoDark
                                : AppColors.info,
                          ),
                        )
                      else
                        Text(
                          'Tasa del día aplicada al préstamo',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoadingRate) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).billingFrequency, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push<PaymentFrequency>(
              MaterialPageRoute(
                builder: (context) => const PaymentFrequencySelectionScreen(),
              ),
            );

            if (result != null && mounted) {
              setState(() {
                _selectedFrequency = result;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFrequency?.name ??
                            S.of(context).selectFrequency,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _selectedFrequency == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (_selectedFrequency != null)
                        Text(
                          '${_selectedFrequency!.daysInterval} ${S.of(context).daysInterval.toLowerCase()}',
                          style: AppTypography.bodySmall,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _applyPlan(PaymentPlan plan) async {
    setState(() => _selectedPlan = plan);

    // 1. Currency
    if (plan.currencyCode != _selectedCurrencyCode) {
      if (!plan.allowCurrencyChange) {
        setState(() => _selectedCurrencyCode = plan.currencyCode);
        await _loadExchangeRate();
      } else {
        // Optional: Ask user or just switch? For now switch but allow edit.
        setState(() => _selectedCurrencyCode = plan.currencyCode);
        await _loadExchangeRate();
      }
    }

    // 2. Frequency
    // We need to match the Plan's frequency ID with the available frequencies
    // The Plan stores frequencyId and daysInterval.
    try {
      final frequencies = await ref.read(
        activePaymentFrequenciesProvider.future,
      );
      // Try to find by ID first
      var match = frequencies
          .where((f) => f.id == plan.paymentFrequencyId)
          .firstOrNull;

      // Fallback: match by daysInterval if ID not found (e.g. legacy/custom)
      match ??= frequencies
          .where((f) => f.daysInterval == plan.paymentFrequencyDays)
          .firstOrNull;

      if (match != null && mounted) {
        setState(() => _selectedFrequency = match);
      }
    } on Exception catch (_) {
      // Ignore error loading frequencies
    }

    // 3. Rate
    // Plan has monthlyInterestRate.
    if (mounted) {
      setState(() {
        _rateController.text = plan.monthlyInterestRate.toStringAsFixed(2);
      });
    }

    // 4. Calculate End Date (if Term is provided in plan)
    // We assume the user inputs the Principal, then we calculate details?
    // Wait, the plan has a Term (Value + Unit).
    // So if I select a plan validation, does it enforce the term?
    // YES. We should probably calculate the date immediately if we can.
    _calculatePlanEndDate(plan);
  }

  void _calculatePlanEndDate(PaymentPlan plan) {
    if (plan.termValue > 0) {
      final days = LoanCalculator.calculateTermInDays(
        plan.termValue,
        plan.termUnit,
      );
      final endDate = LoanCalculator.calculateEndDate(_disbursementDate, days);
      setState(() {
        _endDate = endDate;
      });
    }
  }

  Widget _buildCustomerInfo() {
    if (_customer == null) {
      return const AppCard(child: Center(child: CircularProgressIndicator()));
    }

    final displayName = _customer!.alias ?? _customer!.fullName;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.infoDark
                          : Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: AppTypography.headlineSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.infoDark
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTypography.titleMedium),
                if (_customer!.alias != null)
                  Text(_customer!.fullName, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateInfo() {
    final principal =
        double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (principal <= 0 || rate <= 0 || _selectedFrequency == null) {
      return const SizedBox.shrink();
    }

    // Calculate interest for the selected frequency interval
    // Monthly Rate (20%) -> Daily Rate (20% / daysPerMonth) -> Frequency Rate (Daily * Interval)
    // Formula: Principal * (MonthlyRate / 100 / daysPerMonth * Interval)
    final policy = ref.watch(activePolicyProvider).value;
    final daysPerMonth =
        policy?.daysPerMonth ?? 30; // Prioriza política, cae a 30
    final dailyInterest = principal * (rate / 100) / daysPerMonth;
    final periodInterest = dailyInterest * _selectedFrequency!.daysInterval;

    final frequencyLabel = _selectedFrequency!.name;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${S.of(context).interest} $frequencyLabel: ',
                  style: AppTypography.bodySmall,
                ),
                DefaultTextStyle(
                  style: AppTypography.titleSmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.infoDark
                        : Theme.of(context).colorScheme.primary,
                  ),
                  child: MoneyDisplay(amount: periodInterest),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    // Get the currency info dynamically
    final settings = ref.watch(appSettingsProvider).value;
    final baseCurrencyCode = settings?.baseCurrency ?? 'NIO';

    // Use CurrencyInfo for dynamic symbol
    final currencyInfo = CurrencyInfo.fromCode(_selectedCurrencyCode);
    final baseCurrencyInfo = CurrencyInfo.fromCode(baseCurrencyCode);

    // Lock if Plan forbids currency change
    final isLocked =
        _selectedPlan != null && !_selectedPlan!.allowCurrencyChange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context).loanCurrencyLabel,
              style: AppTypography.labelMedium,
            ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Restringido por Plan',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: AppCard(
            child: ListTile(
              leading: Text(
                currencyInfo.symbol,
                style: AppTypography.headlineMedium.copyWith(
                  color: isLocked ? AppColors.textSecondary : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              title: Text('${currencyInfo.name} (${currencyInfo.code})'),
              subtitle: _selectedCurrencyCode != baseCurrencyCode
                  ? Text(
                      'Moneda Base: ${baseCurrencyInfo.symbol} ${baseCurrencyInfo.code}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
              trailing: isLocked
                  ? const Icon(Icons.lock_outline, size: 20)
                  : const Icon(Icons.chevron_right),
              onTap: isLocked
                  ? null
                  : () async {
                      final result = await context.push<String>(
                        '/settings/currency-selection',
                      );
                      if (result != null && result.isNotEmpty && mounted) {
                        setState(() => _selectedCurrencyCode = result);
                        await _loadExchangeRate();
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelector() {
    final plansAsync = ref.watch(paymentPlansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).paymentPlans, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        plansAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading plans: $e'),
          data: (plans) {
            // Filter active plans + valid for customer category if check enabled
            final activePlans = plans.where((p) => p.isActive).toList();

            // Filter by Customer Category
            final visiblePlans = activePlans.where((p) {
              return p.appliesToCategory(_customer?.categoryId);
            }).toList();

            return AppCard(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedPlan?.planId,
                decoration: InputDecoration(
                  labelText: S.of(context).selectPlan,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  prefixIcon: const Icon(Icons.assignment_outlined),
                ),
                items: [
                  DropdownMenuItem<String>(child: Text(S.of(context).optional)),
                  ...visiblePlans.map((plan) {
                    return DropdownMenuItem<String>(
                      value: plan.planId,
                      child: Text(plan.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value == null) {
                    setState(() {
                      _selectedPlan = null;
                      _endDate = null; // Clear calculated end date
                    });
                  } else {
                    final plan = visiblePlans.firstWhere(
                      (p) => p.planId == value,
                      orElse: () => visiblePlans.first, // Fallback safety
                    );
                    _applyPlan(plan);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ... (keeping _applyPlan same, but updating validators below) ...

  Widget _buildEndDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha Fin (Opcional)', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Informativa - no afecta los ciclos de cobro',
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _endDate ?? _disbursementDate.add(const Duration(days: 365)),
              firstDate: _disbursementDate,
              lastDate: _disbursementDate.add(const Duration(days: 365 * 10)),
            );
            if (date != null) setState(() => _endDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Sin fecha fin',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _endDate = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha de Desembolso', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _disbursementDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (date != null) {
              setState(() {
                _disbursementDate = date;
                // Clear end date if it becomes invalid
                if (_endDate != null && _endDate!.isBefore(date)) {
                  _endDate = null;
                }
                // Recalculate if plan is selected
                if (_selectedPlan != null) {
                  _calculatePlanEndDate(_selectedPlan!);
                }
              });
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
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_disbursementDate.day}/${_disbursementDate.month}/${_disbursementDate.year}',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final principal =
        double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (principal <= 0) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del Préstamo', style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Capital',
            value: 'C\$ ${principal.toStringAsFixed(2)}',
          ),
          _SummaryRow(label: 'Tasa mensual', value: '$rate%'),
          _SummaryRow(
            label: 'Interés mensual',
            value: 'C\$ ${(principal * rate / 100).toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Esperando datos del cliente...'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.warningDark
              : AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor seleccione una frecuencia de pago'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.warningDark
              : AppColors.warning,
        ),
      );
      return;
    }

    final principal = double.parse(
      _principalController.text.replaceAll(',', ''),
    );

    // Validate capital if enabled
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final settings = await settingsRepo.getSettings();

      if (settings.validateCapital && settings.availableCapital > 0) {
        final loanRepo = ref.read(loanRepositoryProvider);
        final capitalColocado = await loanRepo.getTotalPrincipalBalance();
        final saldoDisponible = settings.availableCapital - capitalColocado;

        if (principal > saldoDisponible) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El monto C\$ ${principal.toStringAsFixed(2)} sobrepasa el saldo disponible de C\$ ${saldoDisponible.toStringAsFixed(2)}',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }

      // Validate disbursement date (Max 1 year old) to prevent crash
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      if (_disbursementDate.isBefore(oneYearAgo)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'La fecha de desembolso no puede ser mayor a un año de antigüedad.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Validate end date is not before disbursement date
      if (_endDate != null && _endDate!.isBefore(_disbursementDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'La fecha fin no puede ser anterior a la fecha de desembolso.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Validate no existing active loans if setting is disabled
      if (!settings.allowMultipleLoans) {
        final loanRepo = ref.read(loanRepositoryProvider);
        final existingLoans = await loanRepo.getLoansByCustomerId(
          widget.customerId,
        );
        final activeLoans = existingLoans
            .where((l) => l.status == 'ACTIVE' || l.status == 'IN_MORA')
            .toList();

        if (activeLoans.isNotEmpty) {
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.warningDark
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Préstamo Activo')),
                  ],
                ),
                content: const Text(
                  'Este cliente ya tiene un préstamo activo.\n\n'
                  'Para permitir múltiples préstamos por cliente, '
                  'habilite la opción en Configuración → Políticas del Negocio.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
      // Validate Plan Limits
      // Validate Plan Limits
      if (_selectedPlan != null) {
        var hasError = false;
        var errorMessage = '';

        if (_selectedPlan!.minAmount != null &&
            principal < _selectedPlan!.minAmount!) {
          hasError = true;
          errorMessage =
              'El monto es inferior al mínimo permitido por el plan (${_selectedPlan!.minAmount}).';
        }
        if (_selectedPlan!.maxAmount != null &&
            principal > _selectedPlan!.maxAmount!) {
          hasError = true;
          errorMessage =
              'El monto excede el máximo permitido por el plan (${_selectedPlan!.maxAmount}).';
        }

        if (hasError) {
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    const Text('Monto Inválido'),
                  ],
                ),
                content: Text(errorMessage),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    } on Exception catch (_) {
      // Continue if settings check fails
    }

    setState(() => _isLoading = true);

    try {
      final rate = double.parse(_rateController.text);
      final now = DateTime.now();

      final loan = Loan(
        loanId: const Uuid().v4(),
        customerId: widget.customerId,
        principalOriginal: principal,
        principalBalance: principal,
        monthlyInterestRate: rate,
        billingFrequency: _selectedFrequency?.id ?? 'MONTHLY',
        paymentFrequencyDays: _selectedFrequency?.daysInterval,
        disbursementDate: _disbursementDate,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        currencyCode: _selectedCurrencyCode,
        appliedExchangeRate: _appliedExchangeRate, // Exchange rate snapshot
        createdAt: now,
        updatedAt: now,
        // Payment Plan Snapshot
        planId: _selectedPlan?.planId,
        planInstallmentsTotal: _selectedPlan?.installmentsTotal,
        distributeCapitalAndInterest:
            _selectedPlan?.distributeCapitalAndInterest,
        endDateCalculated: _endDate, // Snapshot calculated end date
      );

      final createdLoan = await ref
          .read(loansProvider.notifier)
          .addSimpleLoan(loan);

      if (mounted) {
        if (createdLoan != null) {
          // Refresh dashboard stats
          await ref.read(dashboardProvider.notifier).refresh();

          // Invalidate settings to update loan sequence number
          ref
            ..invalidate(loansByCustomerProvider(widget.customerId))
            ..invalidate(appSettingsProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Préstamo creado exitosamente'),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.successDark
                    : AppColors.success,
              ),
            );
          }

          // TRIGGER AUTO BACKUP
          final settings = ref.read(appSettingsProvider).value;
          if (settings != null && settings.backupOnLoanCreation) {
            // ignore: unawaited_futures // Background backup
            BackupService.instance.checkScheduledBackup(
              frequency: settings.backupFrequency,
              retentionDays: settings.backupRetentionDays,
              retries: settings.backupRetries,
              customName: settings.backupCustomName,
            );
          }

          // Send WhatsApp notification with PDF if enabled (use createdLoan with loanNumber)
          // valid settings is already in scope
          if (settings != null &&
              settings.shareReceiptsWhatsApp &&
              _customer != null) {
            final phone = _customer!.phone ?? '';
            if (WhatsAppService.isValidNumber(phone)) {
              // Generate PDF receipt and share via WhatsApp - use LOAN currency
              FiatCurrency loanCurrency;
              try {
                loanCurrency = FiatCurrency.fromCode(createdLoan.currencyCode);
              } on Exception catch (_) {
                loanCurrency = FiatCurrency.fromCode('NIO');
              }

              if (mounted) {
                // Fetch next installment date
                final nextCycle = await ref
                    .read(billingCycleRepositoryProvider)
                    .getCurrentCycle(createdLoan.loanId);
                final nextInstallmentDate = nextCycle?.dueDate;

                if (createdLoan.planId != null) {
                  // Fetch the newly created cycles for the plan report
                  final cycles = await ref
                      .read(billingCycleRepositoryProvider)
                      .getBillingCyclesByLoan(createdLoan.loanId);

                  if (mounted) {
                    await WhatsAppService.shareDisbursementWithPlanReceipt(
                      loan: createdLoan,
                      customer: _customer!,
                      cycles: cycles,
                      settings: settings,
                      locale: Localizations.localeOf(context),
                      currencySymbol: loanCurrency.symbol ?? loanCurrency.code,
                      nextInstallmentDate: nextInstallmentDate,
                    );
                  }
                } else if (mounted) {
                  await WhatsAppService.shareDisbursementReceipt(
                    loan: createdLoan,
                    customer: _customer!,
                    settings: settings,
                    locale: Localizations.localeOf(context),
                    currencySymbol: loanCurrency.symbol ?? loanCurrency.code,
                    nextInstallmentDate: nextInstallmentDate,
                  );
                }
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).noValidWhatsAppNumber),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? AppColors.warningDark
                      : AppColors.warning,
                ),
              );
            }
          }

          // ignore: use_build_context_synchronously // Pop after async operation if mounted
          if (context.mounted) context.pop();
        } else {
          final error = ref.read(loansProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error ?? "Desconocido"}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.titleSmall,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
