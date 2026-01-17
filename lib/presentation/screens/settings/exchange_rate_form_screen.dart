import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/exchange_rate.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';

/// Pantalla de formulario para crear o editar una tasa de cambio.
class ExchangeRateFormScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [ExchangeRateFormScreen].
  const ExchangeRateFormScreen({super.key, this.rateId});

  /// ID opcional de la tasa de cambio a editar.
  final String? rateId;

  @override
  ConsumerState<ExchangeRateFormScreen> createState() =>
      _ExchangeRateFormScreenState();
}

class _ExchangeRateFormScreenState
    extends ConsumerState<ExchangeRateFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // State variables
  late String _sourceCurrency;
  late String _targetCurrency;
  late DateTime _selectedDate;
  final _buyController = TextEditingController();
  final _sellController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  ExchangeRate? _existingRate;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final settings = ref.read(appSettingsProvider).value;
    final baseCurrency = settings?.baseCurrency ?? 'NIO';

    if (widget.rateId != null) {
      // Edit mode: fetch existing rate
      final rates = await ref
          .read(exchangeRateRepositoryProvider)
          .getAllRates();
      try {
        _existingRate = rates.firstWhere((r) => r.rateId == widget.rateId);
        _sourceCurrency = _existingRate!.sourceCurrency;
        _targetCurrency = _existingRate!.targetCurrency;
        _selectedDate = _existingRate!.date;
        _buyController.text = _existingRate!.buyRate.toString();
        _sellController.text = _existingRate!.sellRate.toString();
      } on Exception catch (e) {
        // Handle error if rate not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).genericError(e))),
          );
          context.pop();
        }
        return;
      }
    } else {
      // New mode: defaults
      _sourceCurrency = 'USD';
      _targetCurrency = baseCurrency;
      _selectedDate = DateTime.now();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _buyController.dispose();
    _sellController.dispose();
    super.dispose();
  }

  Future<void> _selectCurrency(bool isSource) async {
    // final current = isSource ? _sourceCurrency : _targetCurrency;
    final result = await context.push<String>('/settings/currency-selection');

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (isSource) {
          _sourceCurrency = result;
        } else {
          _targetCurrency = result;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sourceCurrency == _targetCurrency) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las monedas deben ser diferentes'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final buyRate = double.parse(_buyController.text);
      final sellRate = double.parse(_sellController.text);
      final repo = ref.read(exchangeRateRepositoryProvider);

      if (_existingRate != null) {
        // Update
        await repo.updateRate(
          _existingRate!.copyWith(
            sourceCurrency: _sourceCurrency,
            targetCurrency: _targetCurrency,
            date: _selectedDate,
            buyRate: buyRate,
            sellRate: sellRate,
          ),
        );
      } else {
        // Create
        // Check duplication
        final exists = await repo.rateExistsForDate(
          _sourceCurrency,
          _targetCurrency,
          _selectedDate,
        );

        if (exists) {
          if (!mounted) return;
          throw Exception(S.of(context).rateAlreadyExists);
        }

        await repo.createRate(
          sourceCurrency: _sourceCurrency,
          targetCurrency: _targetCurrency,
          date: _selectedDate,
          buyRate: buyRate,
          sellRate: sellRate,
        );
      }

      if (mounted) {
        context.pop(true); // Return success
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show spinner
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isEdit = widget.rateId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? S.of(context).editExchangeRate
              : S.of(context).addExchangeRate,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Currency Selection Card
              AppCard(
                child: Column(
                  children: [
                    _buildCurrencySelector(
                      label: S.of(context).sourceCurrency,
                      value: _sourceCurrency,
                      onTap: () => _selectCurrency(true),
                    ),
                    const Divider(height: 1),
                    _buildCurrencySelector(
                      label: S.of(context).targetCurrency,
                      value: _targetCurrency,
                      onTap: () => _selectCurrency(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date Selection
              AppCard(
                child: ListTile(
                  title: Text(S.of(context).rateDate),
                  subtitle: Text(
                    DateFormat.yMMMMd(
                      Localizations.localeOf(context).toString(),
                    ).format(_selectedDate),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // Rates Input
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: S.of(context).buyRate,
                      controller: _buyController,
                      hint: '0.0000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return S.of(context).requiredField;
                        }
                        if (double.tryParse(v) == null) {
                          return S.of(context).invalidRate;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: S.of(context).sellRate,
                      controller: _sellController,
                      hint: '0.0000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return S.of(context).requiredField;
                        }
                        if (double.tryParse(v) == null) {
                          return S.of(context).invalidRate;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              AppButton(
                label: S.of(context).save,
                isLoading: _isSaving,
                onPressed: _save,
                // type: ButtonType.primary, // Removed as it seemingly doesn't exist
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(label, style: AppTypography.bodySmall),
      subtitle: Text(
        value,
        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
