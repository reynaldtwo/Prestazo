import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/data/providers/providers.dart';

/// Proveedor para los datos del reporte diferencial.
final differentialReportProvider = FutureProvider<List<DifferentialReportItem>>(
  (ref) async {
    final loanRepo = ref.watch(loanRepositoryProvider);
    final currencyService = await ref.watch(currencyServiceProvider.future);
    final settings = ref.watch(appSettingsProvider).value;
    final baseCurrency = settings?.baseCurrency ?? 'NIO';

    final loans = await loanRepo.getActiveLoans();

    final items = <DifferentialReportItem>[];

    for (final loan in loans) {
      // Only consider loans with both a currency code and an applied rate
      if (loan.appliedExchangeRate != null && loan.appliedExchangeRate! > 0) {
        // Get current rate (Value of Asset = Collection Rate = Payment Rate)
        final currentRate = await currencyService.getPaymentRate(
          loan.currencyCode,
          baseCurrency,
        );

        final contractRate = loan.appliedExchangeRate!;
        final balance = loan.principalBalance;

        // Calculate values in base currency
        // Logic: specific to implementation.
        // If loan in USD, base in NIO.
        // Original Value (NIO) = Balance(USD) * ContractRate(USD->NIO)
        // Current Value (NIO)  = Balance(USD) * CurrentRate(USD->NIO)

        // Ensure we are converting used rates correctly.
        // Contract Rate is usually stored as 1 Source = X Target (Base).

        final originalValueBase = balance * contractRate;
        final currentValueBase = balance * currentRate;

        // If loan currency IS base currency, differential is 0
        if (loan.currencyCode == baseCurrency) continue;

        final differential = currentValueBase - originalValueBase;

        if (differential.abs() > 0.01) {
          items.add(
            DifferentialReportItem(
              loanId: loan.loanId,
              loanNumber: loan.loanNumber ?? loan.loanId.substring(0, 8),
              currency: loan.currencyCode,
              principalBalance: balance,
              contractRate: contractRate,
              currentRate: currentRate,
              originalValueBase: originalValueBase,
              currentValueBase: currentValueBase,
              differential: differential,
            ),
          );
        }
      }
    }

    return items;
  },
);

/// Clase de datos para un elemento del reporte diferencial.
class DifferentialReportItem {
  /// Crea un [DifferentialReportItem].
  DifferentialReportItem({
    required this.loanId,
    required this.loanNumber,
    required this.currency,
    required this.principalBalance,
    required this.contractRate,
    required this.currentRate,
    required this.originalValueBase,
    required this.currentValueBase,
    required this.differential,
  });

  /// Identificador del préstamo.
  final String loanId;

  /// Número visible del préstamo.
  final String loanNumber;

  /// Moneda del préstamo.
  final String currency;

  /// Saldo principal actual en la moneda original.
  final double principalBalance;

  /// Tasa de cambio pactada en el contrato.
  final double contractRate;

  /// Tasa de cambio actual del mercado.
  final double currentRate;

  /// Valor original en moneda base (pactado).
  final double originalValueBase;

  /// Valor actual equivalente en moneda base.
  final double currentValueBase;

  /// Diferencial cambiario (ganancia o pérdida).
  final double differential;

  /// Indica si el diferencial representa una ganancia.
  bool get isGain => differential > 0;
}

/// Pantalla para el reporte de diferencial cambiario.
class CurrencyDifferentialReportScreen extends ConsumerWidget {
  /// Crea una instancia de [CurrencyDifferentialReportScreen].
  const CurrencyDifferentialReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(differentialReportProvider);
    final numberFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte Diferencial Cambiario')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(S.of(context).genericError(e))),
        data: (items) {
          if (items.isEmpty) {
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
                    'No hay diferenciales cambiarios',
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los préstamos activos no tienen tasas de cambio aplicadas',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Calculate totals
          double totalDifferential = 0;
          for (final item in items) {
            totalDifferential += item.differential;
          }

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: totalDifferential >= 0
                        ? [
                            AppColors.success.withValues(alpha: 0.8),
                            AppColors.success,
                          ]
                        : [
                            AppColors.danger.withValues(alpha: 0.8),
                            AppColors.danger,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      totalDifferential >= 0
                          ? 'Ganancia Cambiaria'
                          : 'Pérdida Cambiaria',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'C\$ ${numberFormat.format(totalDifferential.abs())}',
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${items.length} préstamos con diferencial',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // List of items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Préstamo #${item.loanNumber}',
                                  style: AppTypography.titleMedium,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isGain
                                        ? AppColors.success.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.danger.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.isGain ? '+' : ''}C\$ ${numberFormat.format(item.differential)}',
                                    style: TextStyle(
                                      color: item.isGain
                                          ? AppColors.success
                                          : AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo',
                                        style: AppTypography.labelSmall,
                                      ),
                                      Text(
                                        '${item.currency} ${numberFormat.format(item.principalBalance)}',
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tasa Contrato',
                                        style: AppTypography.labelSmall,
                                      ),
                                      Text(
                                        item.contractRate.toStringAsFixed(4),
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tasa Actual',
                                        style: AppTypography.labelSmall,
                                      ),
                                      Text(
                                        item.currentRate.toStringAsFixed(4),
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Valor al Desembolso: C\$ ${numberFormat.format(item.originalValueBase)}',
                                  style: AppTypography.labelSmall,
                                ),
                                Text(
                                  'Valor Actual: C\$ ${numberFormat.format(item.currentValueBase)}',
                                  style: AppTypography.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
