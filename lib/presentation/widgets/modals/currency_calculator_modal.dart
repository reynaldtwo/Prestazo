import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

/// Modal de calculadora de divisas para convertir montos entre diferentes monedas.
class CurrencyCalculatorModal extends ConsumerStatefulWidget {
  /// Crea una instancia de [CurrencyCalculatorModal].
  const CurrencyCalculatorModal({
    required this.initialSourceCurrency,
    required this.initialTargetCurrency,
    required this.onTakeAmount,
    super.key,
    this.initialAmount,
  });

  /// Código de la moneda de origen inicial.
  final String initialSourceCurrency;

  /// Código de la moneda de destino inicial.
  final String initialTargetCurrency;

  /// Monto inicial opcional para la calculadora.
  final double? initialAmount;

  /// Callback que se ejecuta al confirmar el monto calculado.
  /// Proporciona el resultado, la moneda y la tasa de cambio utilizada.
  final void Function(double result, String currency, double rate) onTakeAmount;

  @override
  ConsumerState<CurrencyCalculatorModal> createState() =>
      _CurrencyCalculatorModalState();
}

class _CurrencyCalculatorModalState
    extends ConsumerState<CurrencyCalculatorModal> {
  late String _sourceCurrency;
  late String _targetCurrency;
  final _amountController = TextEditingController();
  final _manualRateController = TextEditingController();
  double _calculatedResult = 0;
  bool _isLoadingRate = false;

  @override
  void initState() {
    super.initState();
    _sourceCurrency = widget.initialSourceCurrency;
    _targetCurrency = widget.initialTargetCurrency;
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    _loadRate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  Future<void> _loadRate() async {
    if (_sourceCurrency == _targetCurrency) {
      setState(() {
        _manualRateController.text = '1.0000';
      });
      _calculate();
      return;
    }

    setState(() => _isLoadingRate = true);
    try {
      final service = ref.read(currencyServiceProvider);
      // Try to get disbursement rate (Sell Rate usually)
      if (service.hasValue) {
        final rate = await service.requireValue.getDisbursementRate(
          _sourceCurrency,
          _targetCurrency,
        );
        setState(() {
          _manualRateController.text = rate.toStringAsFixed(4);
        });
      }
    } on Exception catch (_) {
      // Ignore error loading rate
    } finally {
      if (mounted) setState(() => _isLoadingRate = false);
      _calculate();
    }
  }

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_manualRateController.text) ?? 0;
    setState(() {
      _calculatedResult = amount * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetFiat = FiatCurrency.maybeFromCode(_targetCurrency);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calculadora de Divisas',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Source Currency Row
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Monto ($_sourceCurrency)',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyPicker(
                  label: 'De',
                  value: _sourceCurrency,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sourceCurrency = val);
                      _loadRate();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
          const SizedBox(height: 16),

          // Target Currency Row
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Tasa de Cambio',
                  controller: _manualRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _calculate(),
                  suffix: _isLoadingRate
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyPicker(
                  label: 'A',
                  value: _targetCurrency,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _targetCurrency = val);
                      _loadRate();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Result Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text('Resultado Estimado', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                Text(
                  _calculatedResult.toStringAsFixed(2),
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  targetFiat?.name ?? _targetCurrency,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              final rate = double.tryParse(_manualRateController.text) ?? 1;
              widget.onTakeAmount(_calculatedResult, _targetCurrency, rate);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Usar este Monto'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPicker({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    // We would ideally reuse a proper picker widget, but for now a Dropdown is valid for "All World Currencies"
    // if we limit to SealedCurrencies.list or a subset.
    // For performance, let's use a simplified approach or reusable if exists.
    // Given the prompt "include all world currencies", we'll use FiatCurrency.list

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: FiatCurrency.list.any((c) => c.code == value)
              ? value
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            // Optimization: Show common ones first + fetched rates?
            // For now, full list might be slow but fulfills requirement "all world currencies"
            ...FiatCurrency.list.map(
              (currency) => DropdownMenuItem(
                value: currency.code,
                child: Text(
                  '${currency.code} - ${currency.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
