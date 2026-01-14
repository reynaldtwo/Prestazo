import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/logic/loan_calculator.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/models/currency_context.dart';
import '../../../data/models/payment_frequency.dart';
import '../../../data/models/payment_plan.dart';
import '../../../data/providers/providers.dart';
import '../../../data/providers/customer_category_provider.dart';
import '../../../data/providers/payment_plan_provider.dart';

class PlanFormScreen extends ConsumerStatefulWidget {
  final String? planId;

  const PlanFormScreen({super.key, this.planId});

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _termValueController = TextEditingController();
  final _rateController = TextEditingController(); // min 0, max 100
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  // State
  bool _isLoading = false;
  PaymentPlan? _existingPlan;

  // Selections
  String _termUnit =
      'Months'; // Default logical unit, but no value in text field
  PaymentFrequency? _selectedFrequency;
  String _selectedCurrencyCode = 'NIO'; // Will load default from settings

  // Categories Logic
  bool _limitByCategories = false;
  String? _selectedCategoryId; // Single category logic

  // Toggles
  bool _allowCurrencyChange = false;
  bool _distributeCapitalAndInterest = false;
  bool _periodStartsOnDisbursement = true;

  // Calculated
  int _calculatedInstallments = 0;

  final _termUnits = ['Days', 'Weeks', 'Months', 'Years'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // Load settings for default currency
    final settings = await ref.read(appSettingsProvider.future);
    if (mounted) {
      _selectedCurrencyCode = settings.baseCurrency;
    }

    // If editing, load plan
    if (widget.planId != null) {
      final plans = await ref.read(paymentPlansProvider.future);
      _existingPlan = plans.firstWhere(
        (p) => p.planId == widget.planId,
        orElse: () => throw Exception('Plan not found'),
      );

      if (_existingPlan != null) {
        _nameController.text = _existingPlan!.name;
        _termValueController.text = _existingPlan!.termValue.toString();
        _termUnit = _existingPlan!.termUnit;
        _rateController.text = _existingPlan!.monthlyInterestRate.toString();
        _minAmountController.text = _existingPlan!.minAmount?.toString() ?? '';
        _maxAmountController.text = _existingPlan!.maxAmount?.toString() ?? '';
        _selectedCurrencyCode = _existingPlan!.currencyCode;
        _allowCurrencyChange = _existingPlan!.allowCurrencyChange;
        _distributeCapitalAndInterest =
            _existingPlan!.distributeCapitalAndInterest;
        _periodStartsOnDisbursement = _existingPlan!.periodStartsOnDisbursement;

        // Category Logic
        if (_existingPlan!.applicableCategoryIds != null &&
            _existingPlan!.applicableCategoryIds!.isNotEmpty) {
          _limitByCategories = true;
          // If it's a single ID in comma separated string, take first. We only support single select in UI for now as requested.
          _selectedCategoryId = _existingPlan!.applicableCategoryIds!
              .split(',')
              .first;
        }

        // Load Frequency
        final frequencies = await ref.read(
          activePaymentFrequenciesProvider.future,
        );
        _selectedFrequency = frequencies
            .where((f) => f.id == _existingPlan!.paymentFrequencyId)
            .firstOrNull;

        _calculateInstallments();
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _calculateInstallments() {
    final termVal = int.tryParse(_termValueController.text) ?? 0;
    final freq = _selectedFrequency;

    if (termVal <= 0 || freq == null) {
      if (mounted && _calculatedInstallments != 0) {
        setState(() => _calculatedInstallments = 0);
      }
      return;
    }

    final termDays = LoanCalculator.calculateTermInDays(termVal, _termUnit);
    final count = LoanCalculator.calculateInstallmentsCount(
      termDays: termDays,
      frequencyDays: freq.daysInterval,
    );

    if (mounted && _calculatedInstallments != count) {
      setState(() => _calculatedInstallments = count);
    }
  }

  Future<void> _save() async {
    final l10n = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_limitByCategories && _selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectStartCategory)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPlan = PaymentPlan(
        planId: _existingPlan?.planId ?? const Uuid().v4(),
        name: _nameController.text,
        paymentFrequencyId: _selectedFrequency!.id,
        paymentFrequencyDays: _selectedFrequency!.daysInterval,
        termValue: int.parse(_termValueController.text),
        termUnit: _termUnit,
        installmentsTotal: _calculatedInstallments,
        monthlyInterestRate: double.parse(_rateController.text),
        minAmount: _minAmountController.text.isEmpty
            ? null
            : double.parse(_minAmountController.text),
        maxAmount: _maxAmountController.text.isEmpty
            ? null
            : double.parse(_maxAmountController.text),
        currencyCode: _selectedCurrencyCode,
        allowCurrencyChange: _allowCurrencyChange,
        distributeCapitalAndInterest: _distributeCapitalAndInterest,
        periodStartsOnDisbursement: _periodStartsOnDisbursement,
        isActive: _existingPlan?.isActive ?? true,
        applicableCategoryIds: _limitByCategories && _selectedCategoryId != null
            ? _selectedCategoryId
            : null,
        createdAt: _existingPlan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.planId == null) {
        await ref.read(paymentPlansProvider.notifier).add(newPlan);
      } else {
        await ref.read(paymentPlansProvider.notifier).updatePlan(newPlan);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).savedSuccessfully)),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.planId == null ? l10n.newPaymentPlan : l10n.editPaymentPlan,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. NAME
                  AppTextField(
                    controller: _nameController,
                    label: l10n.planName,
                    hint: l10n.planNameHint,
                    validator: (v) =>
                        v?.isEmpty == true ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. TERM & UNIT
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _termValueController,
                          decoration: InputDecoration(
                            labelText: l10n.planTerm,
                            hintText: 'Ej: 12', // Placeholder as requested
                            prefixIcon: const Icon(Icons.timelapse),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateInstallments(),
                          validator: (v) {
                            if (v?.isEmpty == true) return l10n.fieldRequired;
                            if (int.tryParse(v!) == null)
                              return l10n.invalidAmount;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<String>(
                          value: _termUnit,
                          decoration: InputDecoration(
                            labelText: l10n.planTermUnit,
                            prefixIcon: const Icon(Icons.category),
                          ),
                          items: _termUnits.map((u) {
                            String label = u;
                            if (u == 'Days') label = l10n.termDays;
                            if (u == 'Weeks') label = l10n.termWeeks;
                            if (u == 'Months') label = l10n.termMonths;
                            if (u == 'Years') label = l10n.termYears;
                            return DropdownMenuItem(
                              value: u,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() => _termUnit = v!);
                            _calculateInstallments();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. FREQUENCY
                  Consumer(
                    builder: (context, ref, child) {
                      final frequenciesAsync = ref.watch(
                        activePaymentFrequenciesProvider,
                      );
                      return frequenciesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (frequencies) {
                          return DropdownButtonFormField<PaymentFrequency>(
                            value: _selectedFrequency,
                            decoration: InputDecoration(
                              labelText: l10n.billingFrequency,
                              prefixIcon: const Icon(Icons.calendar_month),
                              hintText: l10n.selectFrequency,
                            ),
                            items: frequencies
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(
                                      '${f.name} (${f.daysInterval} días)',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() => _selectedFrequency = v);
                              _calculateInstallments();
                            },
                            validator: (v) =>
                                v == null ? l10n.fieldRequired : null,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. CALCULATED INSTALLMENTS (Readonly Display)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.installmentsTotal,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '$_calculatedInstallments',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 16),
                  Text(l10n.financialData, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 16),

                  // 5. CURRENCY SELECTION
                  _buildCurrencySelector(),
                  const SizedBox(height: 16),

                  // RATE
                  AppTextField(
                    controller: _rateController,
                    label: '${l10n.interestRate} (%)',
                    hint: 'Ej: 10', // Placeholder
                    prefixIcon: Icons.percent,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return l10n.fieldRequired;
                      final n = double.tryParse(v!);
                      if (n == null || n < 0) return l10n.invalidAmount;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // MIN/MAX AMOUNT
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _minAmountController,
                          label: l10n.minAmount,
                          hint: l10n.optional,
                          prefixIcon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null; // Optional
                            final n = double.tryParse(v);
                            if (n == null || n < 0) return l10n.invalidAmount;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _maxAmountController,
                          label: l10n.maxAmount,
                          hint: l10n.optional,
                          prefixIcon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null; // Optional
                            final n = double.tryParse(v);
                            if (n == null || n < 0) return l10n.invalidAmount;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 16),

                  // 6. TOGGLES
                  SwitchListTile(
                    title: Text(l10n.allowCurrencyChangeTitle),
                    subtitle: Text(l10n.allowCurrencyChangeSubtitle),
                    value: _allowCurrencyChange,
                    onChanged: (v) => setState(() => _allowCurrencyChange = v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.distributeCapitalInterestTitle),
                    subtitle: Text(l10n.distributeCapitalInterestSubtitle),
                    value: _distributeCapitalAndInterest,
                    onChanged: (v) =>
                        setState(() => _distributeCapitalAndInterest = v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.periodStartsOnDisbursementTitle),
                    value: _periodStartsOnDisbursement,
                    onChanged: (v) =>
                        setState(() => _periodStartsOnDisbursement = v),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 7. CATEGORY TOGGLE & SELECTOR
                  SwitchListTile(
                    title: Text(l10n.limitByCategoryTitle),
                    subtitle: Text(l10n.limitByCategorySubtitle),
                    value: _limitByCategories,
                    onChanged: (val) {
                      setState(() {
                        _limitByCategories = val;
                        if (!val) _selectedCategoryId = null;
                      });
                    },
                  ),

                  if (_limitByCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Consumer(
                        builder: (ctx, ref, _) {
                          final catsAsync = ref.watch(
                            customerCategoriesProvider,
                          );
                          return catsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) => Text('Error: $e'),
                            data: (categories) {
                              if (categories.isEmpty) {
                                return Text(
                                  l10n.noCategoriesCreated,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                );
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedCategoryId, // Single Selection
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: l10n.labelSelectCategory,
                                  border: OutlineInputBorder(),
                                ),
                                items: categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.categoryId,
                                        child: Text(c.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedCategoryId = val);
                                },
                                validator: (v) =>
                                    _limitByCategories && v == null
                                    ? l10n.fieldRequired
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 32),
                  AppButton(
                    label: l10n.save,
                    onPressed: _save,
                    variant: AppButtonVariant.primary,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrencySelector() {
    // Reusing logic from LoanFormScreen style
    final currencyInfo = CurrencyInfo.fromCode(_selectedCurrencyCode);

    return InkWell(
      onTap: () async {
        final result = await context.push<String>(
          '/settings/currency-selection',
        );
        if (result != null && result.isNotEmpty && mounted) {
          setState(() => _selectedCurrencyCode = result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: S.of(context).loanCurrencyLabel, // "Moneda del Préstamo"
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${currencyInfo.name} (${currencyInfo.code})',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
