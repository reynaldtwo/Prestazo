import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../../core/utils/currency_utils.dart';

import 'currency_selection_screen.dart';

class MonetarySettingsScreen extends ConsumerStatefulWidget {
  const MonetarySettingsScreen({super.key});

  @override
  ConsumerState<MonetarySettingsScreen> createState() =>
      _MonetarySettingsScreenState();
}

class _MonetarySettingsScreenState
    extends ConsumerState<MonetarySettingsScreen> {
  final _capitalController = TextEditingController();
  bool _validateCapital = true;
  bool _snapshotPolicy = false; // "Allow manual rate override"
  double _availableCapital = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(appSettingsProvider.future);
    setState(() {
      _availableCapital = settings.availableCapital;
      _validateCapital = settings.validateCapital;
      _snapshotPolicy = settings.allowManualExchangeRate;
      _capitalController.text = _availableCapital.toStringAsFixed(0);
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateSetting(key, value);
    ref.invalidate(appSettingsProvider);
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión Monetaria', // Localization TODO
              style: AppTypography.titleMedium,
            ),
            Text(
              'Monedas, Capital y Tasas', // Localization TODO
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final baseCurrency = settings.baseCurrency;
          final currencySymbol = CurrencyUtils.getCurrencySymbol(baseCurrency);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Base Configuration Section
              _buildSectionHeader(context, 'Configuración Base'), // Loc TODO
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    // Functional Currency Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(S.of(context).baseCurrency),
                        subtitle: Text(
                          '${CurrencyUtils.getCurrencySymbol(baseCurrency)} ($baseCurrency)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final newCurrency = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CurrencySelectionScreen(
                                initialValue: baseCurrency,
                                isGlobalUpdate: false,
                              ),
                            ),
                          );

                          if (newCurrency != null &&
                              newCurrency != baseCurrency) {
                            if (!context.mounted) return;
                            // Validation: Check if we can convert Report Currency from New Base
                            // Source: New Base -> Target: Report
                            final isValid = await _validateRateAndBlock(
                              context,
                              newCurrency,
                              settings.reportCurrency,
                            );
                            if (!isValid) return;

                            await _handleBaseCurrencyChange(
                              context,
                              baseCurrency,
                              newCurrency,
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${S.of(context).baseCurrencyDesc}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // Working Capital Limit
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        S.of(context).availableCapital,
                                        style: AppTypography.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoButton(
                                      title: S.of(context).availableCapital,
                                      func: S
                                          .of(context)
                                          .helpAvailableCapitalFunc,
                                      affects: S
                                          .of(context)
                                          .helpAvailableCapitalAffects,
                                      example: S
                                          .of(context)
                                          .helpAvailableCapitalEx,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _capitalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              prefixText: '$currencySymbol ',
                              hintText: '0',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.save,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  final value =
                                      double.tryParse(
                                        _capitalController.text,
                                      ) ??
                                      0;
                                  _saveSetting('available_capital', value);
                                  setState(() => _availableCapital = value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(S.of(context).capitalSaved),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            S.of(context).availableCapitalDesc,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Validate Capital Toggle
                    SwitchListTile(
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(S.of(context).validateCapital)),
                          const SizedBox(width: 8),
                          _buildInfoButton(
                            title: S.of(context).validateCapital,
                            func: S.of(context).helpValidateCapitalFunc,
                            affects: S.of(context).helpValidateCapitalAffects,
                            example: S.of(context).helpValidateCapitalEx,
                          ),
                        ],
                      ),
                      subtitle: Text(S.of(context).validateCapitalDesc),
                      value: _validateCapital,
                      onChanged: (v) {
                        setState(() => _validateCapital = v);
                        _saveSetting('validate_capital', v);
                      },
                    ),
                    const Divider(height: 1),
                    // Recovery Priority Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Prioridad en Recuperación',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoButton(
                                title: 'Prioridad en Recuperación',
                                func:
                                    'Define cómo se aplica el pago cuando se utiliza la opción "Recuperar".',
                                affects:
                                    'Afecta el orden de reducción de la deuda en pagos de recuperación.',
                                example:
                                    'Priorizar Capital: El pago reduce primero el capital prestado. Priorizar Interés: El pago reduce primero los intereses vencidos.',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: settings.recoveryPriority,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'CAPITAL_FIRST',
                                child: Text('Priorizar Capital (Recomendado)'),
                              ),
                              DropdownMenuItem(
                                value: 'INTEREST_FIRST',
                                child: Text('Priorizar Interés Vencido'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _saveSetting('recovery_priority', value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 2. Currency Center Section
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  S.of(context).currencyCenter,
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.currency_exchange,
                        color: AppColors.accent,
                      ),
                      title: Text(S.of(context).manageExchangeRates),
                      subtitle: Text(S.of(context).currencyMaster),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/exchange-rates'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.edit_note,
                        color: AppColors.info,
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(S.of(context).contractRatePolicy),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoButton(
                            title: S.of(context).contractRatePolicy,
                            func: S.of(context).helpContractRatePolicyFunc,
                            affects: S
                                .of(context)
                                .helpContractRatePolicyAffects,
                            example: S.of(context).helpContractRatePolicyEx,
                          ),
                        ],
                      ),
                      subtitle: Text(S.of(context).contractRatePolicyDesc),
                      value: _snapshotPolicy,
                      onChanged: (v) {
                        setState(() => _snapshotPolicy = v);
                        _saveSetting('allow_manual_exchange_rate', v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 3. Reporting Section
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  S.of(context).reportConsolidation,
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(S.of(context).presentationCurrency),
                  subtitle: Text(settings.reportCurrency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final newCurrency = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CurrencySelectionScreen(
                          initialValue: settings.reportCurrency,
                          isGlobalUpdate: false,
                        ),
                      ),
                    );
                    if (newCurrency != null &&
                        newCurrency != settings.reportCurrency) {
                      if (!context.mounted) return;
                      // Validation: Check if we can convert from Base to New Report
                      // Source: Base -> Target: New Report
                      final isValid = await _validateRateAndBlock(
                        context,
                        settings.baseCurrency,
                        newCurrency,
                      );
                      if (!isValid) return;

                      _updateReportCurrency(context, newCurrency);
                    }
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoButton({
    required String title,
    required String func,
    required String affects,
    required String example,
  }) {
    return InkWell(
      onTap: () => _showHelpDialog(title, func, affects, example),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showHelpDialog(
    String title,
    String func,
    String affects,
    String example,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTypography.titleMedium)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(S.of(context).helpFunc, func),
              const SizedBox(height: 12),
              _buildHelpSection(S.of(context).helpAffects, affects),
              if (example != "---") ...[
                const SizedBox(height: 12),
                _buildHelpSection(S.of(context).helpExample, example),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).close),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: AppTypography.bodyMedium),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _handleBaseCurrencyChange(
    BuildContext context,
    String oldCurrency,
    String newCurrency,
  ) async {
    // Show confirmation and existing conversion logic
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).baseCurrencyChanged),
        content: Text(S.of(context).capitalWillBeRecalculated),
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

    if (confirm == true && mounted) {
      try {
        // Calculate new capital
        final currencyService = await ref.read(currencyServiceProvider.future);
        final rate = await currencyService.getCurrentRate(
          oldCurrency,
          newCurrency,
        );

        if (rate > 0) {
          final currentCapital = _availableCapital;
          final newCapital = currentCapital * rate;

          await _saveSetting('base_currency', newCurrency);
          await _saveSetting('available_capital', newCapital);

          setState(() {
            _availableCapital = newCapital;
            _capitalController.text = newCapital.toStringAsFixed(0);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${S.of(context).capitalConverted}: ${currentCapital.toStringAsFixed(2)} $oldCurrency -> ${newCapital.toStringAsFixed(2)} $newCurrency',
                ),
              ),
            );
          }
        }
      } catch (e) {
        await _saveSetting('base_currency', newCurrency);
      }
      ref.invalidate(appSettingsProvider);
    }
  }

  Future<void> _updateReportCurrency(
    BuildContext context,
    String newCurrency,
  ) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateSetting('report_currency', newCurrency);
    ref.invalidate(appSettingsProvider);
    ref.read(refreshTriggerProvider.notifier).state++;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).currencyUpdated)));
    }
  }

  /// Validates if an exchange rate exists for today between source and target
  Future<bool> _validateRateAndBlock(
    BuildContext context,
    String source,
    String target,
  ) async {
    if (source == target) return true;

    final service = await ref.read(currencyServiceProvider.future);
    final hasRate = await service.hasRateForToday(source, target);

    if (!hasRate && context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning),
              SizedBox(width: 8),
              // Using existing general error title or validations title
              Text(S.of(context).validations),
            ],
          ),
          content: Text(S.of(context).noExchangeRateToday),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.of(context).understood),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/settings/exchange-rates');
              },
              child: Text(S.of(context).goToExchangeRates),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}
