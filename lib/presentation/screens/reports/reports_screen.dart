import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/providers/currency_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/loan.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:prestamos_app/presentation/screens/reports/fx_differential_report_screen.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

/// Pantalla principal de reportes.
class ReportsScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [ReportsScreen].
  const ReportsScreen({super.key, this.initialTab = 0});

  /// Pestaña inicial a mostrar.
  final int initialTab;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTab = 0; // 0 = Ganancias Reales, 1 = Proyección
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Realized Earnings Data
  double _realizedTotal = 0;
  List<Map<String, dynamic>> _paymentsDetail = [];
  bool _isLoadingRealized = false;

  // Projected Data
  double _projectedTotal = 0;
  List<Loan> _activeLoans = [];
  bool _isLoadingProjected = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _startDate = DateTime(DateTime.now().year, DateTime.now().month);
    _endDate = DateTime.now();
    _loadRealizedEarnings();
    _loadProjectedEarnings();
  }

  Future<void> _loadRealizedEarnings() async {
    setState(() => _isLoadingRealized = true);
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final currencyService = ref.read(currencyServiceProvider).value;

    try {
      // Use start of next day for exclusive end date comparison
      // This properly handles all timezone scenarios
      final exclusiveEndDate = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
      ).add(const Duration(days: 1));

      final earningsByCurrency = await paymentRepo
          .getRealizedEarningsByCurrency(
            startDate: _startDate,
            endDate: exclusiveEndDate,
          );

      // Use proper multi-currency aggregation via CurrencyService
      double total = 0;
      if (currencyService != null) {
        final context = await currencyService.getContext();
        total = await currencyService.aggregateMultiCurrencyToDisplay(
          earningsByCurrency,
          context,
        );
      } else {
        // Fallback: sum literal (should not happen in production)
        earningsByCurrency.forEach((_, amount) => total += amount);
      }

      final details = await paymentRepo.getPaymentsWithDetails(
        fromDate: _startDate,
        toDate: exclusiveEndDate,
      );

      if (mounted) {
        setState(() {
          _realizedTotal = total;
          _paymentsDetail = details;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingRealized = false);
    }
  }

  Future<void> _loadProjectedEarnings() async {
    setState(() => _isLoadingProjected = true);
    final repo = ref.read(loanRepositoryProvider);
    final currencyService = ref.read(currencyServiceProvider).value;

    try {
      final projectedByCurrency = await repo
          .getProjectedMonthlyEarningsByCurrency();
      final loans = await repo.getActiveLoans();

      // Use proper multi-currency aggregation via CurrencyService
      double total = 0;
      if (currencyService != null) {
        final context = await currencyService.getContext();
        total = await currencyService.aggregateMultiCurrencyToDisplay(
          projectedByCurrency,
          context,
        );
      } else {
        // Fallback: sum literal (should not happen in production)
        projectedByCurrency.forEach((_, amount) => total += amount);
      }

      if (mounted) {
        setState(() {
          _projectedTotal = total;
          _activeLoans = loans;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingProjected = false);
    }
  }

  // GlobalKey for ArcSideBar control
  final GlobalKey<ArcSideBarState> _arcSideBarKey =
      GlobalKey<ArcSideBarState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(S.of(context).reports),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menú de reportes',
          onPressed: () => _arcSideBarKey.currentState?.toggle(),
        ),
        // Buttons moved to individual report tabs
      ),
      body: Stack(
        children: [
          // Main content
          if (_selectedTab == 0)
            _buildRealizedTab()
          else
            _selectedTab == 1
                ? _buildProjectedTab()
                : const FxDifferentialReportScreen(),
          // Arc Sidebar custom widget
          ArcSideBar(
            key: _arcSideBarKey,
            accentColor: Theme.of(context).colorScheme.primary,
            selectedIndex: _selectedTab,
            header: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text(
                S.of(context).reports,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            items: [
              ArcSideBarItem(
                icon: Icons.attach_money,
                title: S.of(context).realizedEarnings,
                onTap: () {
                  if (_selectedTab != 0) {
                    setState(() => _selectedTab = 0);
                  }
                },
              ),
              ArcSideBarItem(
                icon: Icons.trending_up,
                title: S.of(context).projectedEarnings,
                onTap: () {
                  if (_selectedTab != 1) {
                    setState(() => _selectedTab = 1);
                  }
                },
              ),
              ArcSideBarItem(
                icon: Icons.currency_exchange,
                title: 'Diferencial Cambiario',
                onTap: () {
                  if (_selectedTab != 2) {
                    setState(() => _selectedTab = 2);
                  }
                },
              ),
            ],
            onItemSelected: (index) {
              setState(() => _selectedTab = index);
            },
            footer: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                S.of(context).selectReportType,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealizedTab() {
    final settings = ref.watch(appSettingsProvider).value;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final reportCode = settings.reportCurrency;
    final symbol = FiatCurrency.maybeFromCode(reportCode)?.symbol ?? reportCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Report Header with title and actions
          Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).realizedEarnings,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Compartir PDF',
                onPressed: _shareReport,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
                onPressed: _loadRealizedEarnings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).dateRange, style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        ),
                        onPressed: () => _selectDate(true),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(S.of(context).to),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        ),
                        onPressed: () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: S.of(context).search,
                    onPressed: _loadRealizedEarnings,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result Card
          if (_isLoadingRealized)
            const Center(child: CircularProgressIndicator())
          else ...[
            AppCard(
              backgroundColor:
                  (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.successDark
                          : AppColors.success)
                      .withValues(alpha: 0.1),
              child: Column(
                children: [
                  Text(
                    S.of(context).totalEarningsInterestLateFees,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  MoneyDisplay(
                    amount: _realizedTotal,
                    size: MoneyDisplaySize.large,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.successDark
                        : AppColors.success,
                    currencySymbol: symbol,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_paymentsDetail.length} ${S.of(context).paymentsInRange}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed breakdown
            if (_paymentsDetail.isNotEmpty) ...[
              Text(
                S.of(context).paymentBreakdown,
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._paymentsDetail.take(20).map(_buildPaymentDetailCard),
              if (_paymentsDetail.length > 20)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '... ${S.of(context).and} ${_paymentsDetail.length - 20} ${S.of(context).morePayments}',
                    style: AppTypography.labelSmall,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetailCard(Map<String, dynamic> payment) {
    final settings = ref.read(appSettingsProvider).value;
    final date = DateTime.parse(payment['created_at'] as String);

    // Get raw amounts (NO conversion - show in loan's original currency)
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final interestPaid = (payment['interest_paid'] as num?)?.toDouble() ?? 0;

    // Use the LOAN'S currency, not the report currency
    final loanCurrencyCode =
        payment['currency_code'] as String? ?? settings?.baseCurrency ?? '';
    final symbol =
        FiatCurrency.maybeFromCode(loanCurrencyCode)?.symbol ??
        loanCurrencyCode;

    final customerName = (payment['customer_name'] as String?) ?? 'Sin nombre';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: AppTypography.titleSmall),
                  Row(
                    children: [
                      Text(
                        '${date.day}/${date.month}/${date.year} • ${S.of(context).receiptNumber}${payment['receipt_number']?.toString() ?? '---'}',
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          loanCurrencyCode,
                          style: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyDisplay(
                  amount: amount,
                  size: MoneyDisplaySize.small,
                  currencySymbol: symbol,
                ),
                if (interestPaid > 0)
                  Text(
                    'Int: $symbol ${interestPaid.toStringAsFixed(2)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.successDark
                          : AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectedTab() {
    if (_isLoadingProjected) {
      return const Center(child: CircularProgressIndicator());
    }

    final settings = ref.watch(appSettingsProvider).value;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final reportCode = settings.reportCurrency;
    final symbol = FiatCurrency.maybeFromCode(reportCode)?.symbol ?? reportCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Report Header with title and actions
          Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).projectedEarnings,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Compartir PDF',
                onPressed: _shareReport,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
                onPressed: _loadProjectedEarnings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            backgroundColor:
                (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.infoDark
                        : AppColors.info)
                    .withValues(alpha: 0.1),
            child: Column(
              children: [
                Text(
                  S.of(context).projectedMonthlyEarnings,
                  style: AppTypography.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                MoneyDisplay(
                  amount: _projectedTotal,
                  size: MoneyDisplaySize.large,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.infoDark
                      : AppColors.info,
                  currencySymbol: symbol,
                ),
                const SizedBox(height: 4),
                Text(
                  '${S.of(context).basedOn} ${_activeLoans.length} ${S.of(context).activeLoansLower}',
                  style: AppTypography.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_activeLoans.isNotEmpty) ...[
            Text(
              S.of(context).loanDetailByLoan,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._activeLoans.map((loan) {
              // NO conversion - show in loan's original currency
              final principal = loan.principalBalance;
              final monthlyReturn =
                  loan.principalBalance * (loan.monthlyInterestRate / 100);

              // Use the LOAN'S original currency
              final loanSymbol =
                  FiatCurrency.maybeFromCode(loan.currencyCode)?.symbol ??
                  r'C$';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        '${S.of(context).loan} #${loan.loanNumber ?? '---'}',
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          loan.currencyCode,
                          style: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${S.of(context).capital}: '),
                      MoneyDisplay(
                        amount: principal,
                        currencySymbol: loanSymbol,
                      ),
                      Text(
                        ' @ ${loan.monthlyInterestRate.toStringAsFixed(2)}%',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        S.of(context).returnPerMonth,
                        style: AppTypography.labelSmall,
                      ),
                      MoneyDisplay(
                        amount: monthlyReturn,
                        size: MoneyDisplaySize.small,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.successDark
                            : AppColors.success,
                        currencySymbol: loanSymbol,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  S.of(context).noActiveLoans,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _shareReport() async {
    final pdfService = ref.read(pdfGeneratorServiceProvider);
    final settings = ref.read(appSettingsProvider).value;
    final locale = Localizations.localeOf(context);

    if (settings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).genericError(S.of(context).configNotLoaded),
          ),
        ),
      );
      return;
    }

    try {
      final currencyService = ref.read(currencyServiceProvider).value;

      if (_selectedTab == 0) {
        // Earnings Report
        if (_paymentsDetail.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).noPaymentDataForReport)),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).generatingEarningsReport)),
        );

        // Calculate aggregated totals using multi-currency normalization
        double? aggregatedTotalEarnings;
        double? aggregatedTotalPrincipal;
        double? aggregatedTotalCollected;
        String? displayCurrencySymbol;

        if (currencyService != null) {
          final context = await currencyService.getContext();
          displayCurrencySymbol = context.displayCurrency.symbol;

          // Aggregate earnings (interest + mora) by currency
          final earningsByCurrency = <String, double>{};
          final principalByCurrency = <String, double>{};

          for (final row in _paymentsDetail) {
            final currency =
                row['currency_code'] as String? ?? settings.baseCurrency;
            final interest = (row['interest_paid'] as num?)?.toDouble() ?? 0;
            final mora = (row['mora_paid'] as num?)?.toDouble() ?? 0;
            final principal = (row['principal_paid'] as num?)?.toDouble() ?? 0;

            earningsByCurrency[currency] =
                (earningsByCurrency[currency] ?? 0) + interest + mora;
            principalByCurrency[currency] =
                (principalByCurrency[currency] ?? 0) + principal;
          }

          aggregatedTotalEarnings = await currencyService
              .aggregateMultiCurrencyToDisplay(earningsByCurrency, context);
          aggregatedTotalPrincipal = await currencyService
              .aggregateMultiCurrencyToDisplay(principalByCurrency, context);
          aggregatedTotalCollected =
              aggregatedTotalEarnings + aggregatedTotalPrincipal;
        }

        await pdfService.generateEarningsReport(
          startDate: _startDate,
          endDate: _endDate,
          paymentsData: _paymentsDetail,
          settings: settings,
          locale: locale,
          currencySymbol:
              displayCurrencySymbol ??
              ref.read(currencyProvider).symbol ??
              ref.read(currencyProvider).code,
          aggregatedTotalEarnings: aggregatedTotalEarnings,
          aggregatedTotalPrincipal: aggregatedTotalPrincipal,
          aggregatedTotalCollected: aggregatedTotalCollected,
        );
      } else {
        // Consolidated Active Loans Report
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).generatingConsolidatedReport)),
        );

        final loanRepo = ref.read(loanRepositoryProvider);
        final loansData = await loanRepo.getConsolidatedActiveLoans();

        if (!mounted) return;

        if (loansData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).noActiveLoansForReport)),
          );
          return;
        }

        // Calculate aggregated totals using multi-currency normalization
        double? aggregatedTotalOriginal;
        double? aggregatedTotalBalance;
        String? displayCurrencySymbol;
        String? baseCurrencyCode;
        double? totalInBaseCurrency;
        Map<String, double>? originalByCurrency;
        Map<String, double>? balanceByCurrency;

        if (currencyService != null) {
          final context = await currencyService.getContext();
          displayCurrencySymbol = context.displayCurrency.symbol;
          baseCurrencyCode = context.baseCurrency.code;

          // Aggregate by currency
          originalByCurrency = <String, double>{};
          balanceByCurrency = <String, double>{};

          for (final row in loansData) {
            final currency =
                row['currency_code'] as String? ?? settings.baseCurrency;
            final original = (row['principal_original'] as num).toDouble();
            final balance = (row['principal_balance'] as num).toDouble();

            originalByCurrency[currency] =
                (originalByCurrency[currency] ?? 0) + original;
            balanceByCurrency[currency] =
                (balanceByCurrency[currency] ?? 0) + balance;
          }

          // Calculate total in base currency (before display conversion)
          totalInBaseCurrency = await currencyService
              .aggregateMultiCurrencyToBase(balanceByCurrency, context);

          aggregatedTotalOriginal = await currencyService
              .aggregateMultiCurrencyToDisplay(originalByCurrency, context);
          aggregatedTotalBalance = await currencyService
              .aggregateMultiCurrencyToDisplay(balanceByCurrency, context);
        }

        await pdfService.generateConsolidatedActiveLoansReport(
          loansData: loansData,
          settings: settings,
          locale: locale,
          currencySymbol:
              displayCurrencySymbol ??
              ref.read(currencyProvider).symbol ??
              ref.read(currencyProvider).code,
          aggregatedTotalOriginal: aggregatedTotalOriginal,
          aggregatedTotalBalance: aggregatedTotalBalance,
          totalsByCurrencyOriginal: originalByCurrency,
          totalsByCurrencyBalance: balanceByCurrency,
          baseCurrencyCode: baseCurrencyCode,
          totalInBaseCurrency: totalInBaseCurrency,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).errorGeneratingReport(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          // Force end of day for the selected date to ensure inclusive coverage
          // Although DatePicker picks 00:00, our local logic will use day/month/year
          // BUT when generating report, we pass this _endDate.
          // PdfGenerator displays just the date.
          // BUT internal loading logic (_loadRealizedEarnings) does adjustment.
          // We should keep _endDate as is (midnight) or user confusion might occur if they pick same day.
          _endDate = picked;
        }
      });
    }
  }
}
