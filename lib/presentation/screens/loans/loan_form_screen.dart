import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/loan.dart';
import '../../../data/providers/providers.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../data/models/payment_frequency.dart';
import '../../../data/providers/payment_frequency_provider.dart';
import '../../../services/whatsapp_service.dart';

import '../../../data/models/currency_context.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

/// Loan form screen for creating new loans with Riverpod
class LoanFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  const LoanFormScreen({super.key, required this.customerId});

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
  final TextEditingController _exchangeRateController = TextEditingController();

  bool _isLoading = false;
  bool _hasValidRate = true;
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _initializeCurrency();
    _loadCustomer();
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
        _hasValidRate = true;
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
            _hasValidRate = false;
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
          _hasValidRate = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appliedExchangeRate = null;
          _exchangeRateController.clear();
          _isLoadingRate = false;
          _hasValidRate = false;
        });
        _showNoRateDialog();
      }
    }
  }

  /// Show dialog when no TODAY's rate exists
  void _showNoRateDialog() {
    showDialog(
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
                _hasValidRate = true;
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
          Future.microtask(() => _showRestrictionDialog(customer));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).errorLoadCustomer}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showRestrictionDialog(Customer customer) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.block, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.of(context).restrictedCustomerTitle,
                style: const TextStyle(color: AppColors.danger),
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
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
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
            const SizedBox(height: 24),
            _buildCurrencySelector(),
            const SizedBox(height: 16),
            // Exchange rate field (always visible, right after currency)
            _buildExchangeRateField(),
            const SizedBox(height: 16),
            AppMoneyField(
              label: S.of(context).loanAmountLabel,
              controller: _principalController,
              currencySymbol: displayCurrency?.symbol ?? '\$',
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
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    if (_customer == null) {
      return const AppCard(child: Center(child: CircularProgressIndicator()));
    }

    final displayName = _customer!.alias ?? _customer!.fullName;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.info : AppColors.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? AppColors.info : AppColors.primary,
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

    if (principal <= 0 || rate <= 0 || _selectedFrequency == null)
      return const SizedBox.shrink();

    // Calculate interest for the selected frequency interval
    // Monthly Rate (20%) -> Daily Rate (20% / 30) -> Frequency Rate (Daily * Interval)
    // Formula: Principal * (MonthlyRate / 100 / 30 * Interval)
    final dailyInterest = principal * (rate / 100) / 30;
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
                        ? AppColors.info
                        : AppColors.primary,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).loanCurrencyLabel, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        AppCard(
          child: ListTile(
            leading: Text(
              currencyInfo.symbol,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primary,
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await context.push<String>(
                '/settings/currency-selection',
              );
              if (result != null && result.isNotEmpty && mounted) {
                setState(() => _selectedCurrencyCode = result);
                _loadExchangeRate();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeRateField() {
    final settings = ref.read(appSettingsProvider).value;
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
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
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
                            color: AppColors.textSecondary,
                          ),
                        )
                      else if (canEdit)
                        Text(
                          'Puede editar la tasa manualmente',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        )
                      else
                        Text(
                          'Tasa del día aplicada al préstamo',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
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
    final frequenciesAsync = ref.watch(activePaymentFrequenciesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).billingFrequency, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        frequenciesAsync.when(
          loading: () => const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Text(
            'Error: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
          data: (frequencies) {
            if (frequencies.isEmpty) return const Text('No active frequencies');

            // Auto-select MONTHLY if nothing selected
            if (_selectedFrequency == null && frequencies.isNotEmpty) {
              // Try to find Monthly or default to first
              final monthly = frequencies
                  .where((f) => f.id == 'MONTHLY')
                  .firstOrNull;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(
                    () => _selectedFrequency = monthly ?? frequencies.first,
                  );
                }
              });
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: frequencies.map((freq) {
                    return SizedBox(
                      width: itemWidth,
                      child: _FrequencyOption(
                        label: freq.name,
                        subtitle:
                            '${freq.daysInterval} ${S.of(context).daysInterval.toLowerCase()}',
                        icon: Icons
                            .calendar_today, // Generic icon or custom mapping
                        isSelected: _selectedFrequency?.id == freq.id,
                        onTap: () => setState(() => _selectedFrequency = freq),
                        isCompact: true,
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

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
      showBorder: true,
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando datos del cliente...'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una frecuencia de pago'),
          backgroundColor: AppColors.warning,
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
                  'El monto C\$ ${principal.toStringAsFixed(0)} sobrepasa el saldo disponible de C\$ ${saldoDisponible.toStringAsFixed(0)}',
                ),
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 4),
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
            const SnackBar(
              content: Text(
                'La fecha de desembolso no puede ser mayor a un año de antigüedad.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // Validate end date is not before disbursement date
      if (_endDate != null && _endDate!.isBefore(_disbursementDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La fecha fin no puede ser anterior a la fecha de desembolso.',
              ),
              backgroundColor: AppColors.danger,
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
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(child: Text('Préstamo Activo')),
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
    } catch (e) {
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
      );

      final createdLoan = await ref
          .read(loansProvider.notifier)
          .addSimpleLoan(loan);

      if (mounted) {
        if (createdLoan != null) {
          // Refresh dashboard stats
          ref.read(dashboardProvider.notifier).refresh();

          // Invalidate loans by customer so detail screen refreshes
          ref.invalidate(loansByCustomerProvider(widget.customerId));

          // Invalidate settings to update loan sequence number
          ref.invalidate(appSettingsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préstamo creado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );

          // TRIGGER AUTO BACKUP
          final settings = ref.read(appSettingsProvider).value;
          if (settings != null && settings.backupOnLoanCreation) {
            // Run in background
            ref
                .read(backupServiceProvider)
                .createBackup(customName: settings.backupCustomName)
                .then((_) => debugPrint('Auto backup triggered'));
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
              } catch (_) {
                loanCurrency = FiatCurrency.fromCode('NIO');
              }
              await WhatsAppService.shareDisbursementReceipt(
                loan: createdLoan,
                customer: _customer!,
                settings: settings,
                locale: Localizations.localeOf(context),
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

          // ignore: use_build_context_synchronously
          context.pop();
        } else {
          final error = ref.read(loansProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error ?? "Desconocido"}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
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
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

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

class _FrequencyOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  const _FrequencyOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.info : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: isCompact ? 24 : 28,
            ),
            SizedBox(height: isCompact ? 4 : 8),
            Text(
              label,
              style:
                  (isCompact
                          ? AppTypography.bodySmall
                          : AppTypography.titleSmall)
                      .copyWith(
                        color: isSelected ? primaryColor : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                        fontSize: isCompact ? 10 : null,
                      ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isCompact)
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
