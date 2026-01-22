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

/// Proveedor para la lista de tasas de cambio.
final exchangeRatesProvider = FutureProvider<List<ExchangeRate>>((ref) async {
  final repo = ref.watch(exchangeRateRepositoryProvider);
  return repo.getAllRates();
});

/// Pantalla para visualizar y gestionar las tasas de cambio.
class ExchangeRateScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [ExchangeRateScreen].
  const ExchangeRateScreen({super.key});

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).exchangeRates),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewRate(context),
          ),
        ],
      ),
      body: ratesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(S.of(context).genericError(e.toString()))),
        data: (rates) {
          if (rates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.currency_exchange,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context).noRatesAvailable,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: S.of(context).addExchangeRate,
                    onPressed: () => _createNewRate(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rates.length,
            itemBuilder: (context, index) {
              final rate = rates[index];
              return _buildRateCard(context, rate);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewRate(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRateCard(BuildContext context, ExchangeRate rate) {
    final dateFormat = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.currency_exchange, color: AppColors.primary),
        ),
        title: Text(
          '${rate.sourceCurrency} → ${rate.targetCurrency}',
          style: AppTypography.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(rate.date)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildRateItem(
                  context,
                  S.of(context).buyRate,
                  rate.buyRate,
                  AppColors.success,
                ),
                _buildRateItem(
                  context,
                  S.of(context).sellRate,
                  rate.sellRate,
                  AppColors.danger,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editRate(context, rate);
            } else if (value == 'delete') {
              _confirmDelete(context, rate);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(S.of(context).edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).delete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _createNewRate(BuildContext context) async {
    final result = await context.pushNamed<bool>('new-exchange-rate');
    if (result ?? false) {
      ref.invalidate(exchangeRatesProvider);
    }
  }

  Future<void> _editRate(BuildContext context, ExchangeRate rate) async {
    final result = await context.pushNamed<bool>(
      'edit-exchange-rate',
      pathParameters: {'id': rate.rateId},
    );
    if (result ?? false) {
      ref.invalidate(exchangeRatesProvider);
    }
  }

  Future<void> _confirmDelete(BuildContext context, ExchangeRate rate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).delete),
        content: Text(S.of(context).deleteRateConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final repo = ref.read(exchangeRateRepositoryProvider);
        await repo.deleteRate(rate.rateId);
        ref.invalidate(exchangeRatesProvider);
        if (context.mounted) {
          final l10n = S.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.rateDeletedSuccessfully),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } on Exception catch (e) {
        if (context.mounted) {
          final l10n = S.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.genericError(e.toString())),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Widget _buildRateItem(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ),
          Text(
            value.toStringAsFixed(4),
            style: AppTypography.bodySmall.copyWith(
              fontFamily: 'RobotoMono',
              // Remove fixed color so it adapts to theme, or use specific onSurface
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
