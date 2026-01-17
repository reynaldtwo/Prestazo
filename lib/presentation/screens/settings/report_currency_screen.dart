import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

/// Pantalla para configurar la moneda de reporte y la tasa de cambio para los reportes del prestamista.
class ReportCurrencyScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [ReportCurrencyScreen].
  const ReportCurrencyScreen({super.key});

  @override
  ConsumerState<ReportCurrencyScreen> createState() =>
      _ReportCurrencyScreenState();
}

class _ReportCurrencyScreenState extends ConsumerState<ReportCurrencyScreen> {
  final _exchangeRateController = TextEditingController();
  String _reportCurrency = 'NIO';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    setState(() {
      _reportCurrency = settings.reportCurrency;
      _exchangeRateController.text = settings.exchangeRate.toStringAsFixed(4);
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final rate = double.tryParse(_exchangeRateController.text);
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).invalidExchangeRate),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.getSettings();
      await repo.updateSettings(
        settings.copyWith(reportCurrency: _reportCurrency, exchangeRate: rate),
      );

      // Invalidate provider to refresh UI everywhere
      ref.invalidate(appSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settingsSaved),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).genericError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(S.of(context).info, style: AppTypography.titleMedium),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).reportSettingsInfo,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).reportCurrencyDialogDesc,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).understood),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            s.reportCurrencyTitle,
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    FiatCurrency? displayCurrency;
    try {
      displayCurrency = FiatCurrency.fromCode(_reportCurrency);
    } on Object catch (_) {
      displayCurrency = FiatCurrency.fromCode('NIO');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.reportCurrencyTitle,
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: s.info,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    S.of(context).reportCurrencyInfoBanner,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Report Currency Selector
          Text(s.reportCurrencyTitle, style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              leading: const Icon(
                Icons.currency_exchange,
                color: AppColors.primary,
              ),
              title: Text('${displayCurrency.name} (${displayCurrency.code})'),
              subtitle: Text(S.of(context).tapToChange),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await context.push<String>(
                  '/settings/currency-selection',
                );
                if (result != null && result.isNotEmpty && mounted) {
                  setState(() => _reportCurrency = result);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Exchange Rate
          Text(
            S.of(context).exchangeRateTitle,
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            s.exchangeRateHelper,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: S.of(context).exchangeRateTitle,
            controller: _exchangeRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.sync_alt,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return S.of(context).requiredField;
              }
              final rate = double.tryParse(v);
              if (rate == null || rate <= 0) {
                return S.of(context).invalidRateError;
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            s.exchangeRateHint,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(S.of(context).saveButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
