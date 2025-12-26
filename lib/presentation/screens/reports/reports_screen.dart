import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/loan.dart';
import '../../../data/providers/service_providers.dart';
import '../../../core/localization/locale_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const ReportsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
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
    _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _endDate = DateTime.now();
    _loadRealizedEarnings();
    _loadProjectedEarnings();
  }

  Future<void> _loadRealizedEarnings() async {
    setState(() => _isLoadingRealized = true);
    final paymentRepo = ref.read(paymentRepositoryProvider);
    try {
      // Ensure endDate covers the entire day
      final adjustedEndDate = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23,
        59,
        59,
      );

      final total = await paymentRepo.getRealizedEarnings(
        startDate: _startDate,
        endDate: adjustedEndDate,
      );
      final details = await paymentRepo.getPaymentsWithDetails(
        fromDate: _startDate,
        toDate: adjustedEndDate,
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
    try {
      final total = await repo.getProjectedMonthlyEarnings();
      final loans = await repo.getActiveLoans();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir Reporte (PDF)',
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRealizedEarnings();
              _loadProjectedEarnings();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        S.of(context).realizedEarnings,
                        style: TextStyle(
                          color: _selectedTab == 0
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: _selectedTab == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        S.of(context).projectedEarnings,
                        style: TextStyle(
                          color: _selectedTab == 1
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: _selectedTab == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildRealizedTab() : _buildProjectedTab(),
    );
  }

  Widget _buildRealizedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
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
                    color: AppColors.success,
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
              ..._paymentsDetail
                  .take(20)
                  .map((p) => _buildPaymentDetailCard(p)),
              if (_paymentsDetail.length > 20)
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
    final date = DateTime.parse(payment['payment_date'] as String);
    final amount = (payment['amount'] as num).toDouble();
    final interestPaid = (payment['interest_paid'] as num?)?.toDouble() ?? 0;

    final customerName = payment['customer_name'] ?? 'Sin nombre';

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
                  Text(
                    '${date.day}/${date.month}/${date.year} • ${S.of(context).receiptNumber}${payment['receipt_number'] ?? '---'}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyDisplay(amount: amount, size: MoneyDisplaySize.small),
                if (interestPaid > 0)
                  Text(
                    'Int: C\$${interestPaid.toStringAsFixed(0)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            backgroundColor: AppColors.info.withValues(alpha: 0.1),
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
                  color: AppColors.info,
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
              final monthlyReturn =
                  loan.principalBalance * (loan.monthlyInterestRate / 100);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '${S.of(context).loan} #${loan.loanNumber ?? '---'}',
                  ),
                  subtitle: Text(
                    'Capital: C\$${loan.principalBalance.toStringAsFixed(0)} @ ${loan.monthlyInterestRate}%',
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
                        color: AppColors.success,
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
                    color: AppColors.textSecondary,
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

    if (settings == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Configuración no cargada')),
      );
      return;
    }

    try {
      if (_selectedTab == 0) {
        // Earnings Report
        if (_paymentsDetail.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay datos de pagos para generar reporte'),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando Reporte de Ganancias...')),
        );

        // Ensure accurate breakdown is available (should be if using updated repo)
        await pdfService.generateEarningsReport(
          startDate: _startDate,
          endDate:
              _endDate, // Logic handles end-of-day in query, displayed as date only
          paymentsData: _paymentsDetail,
          settings: settings,
          locale: S.of(context).locale,
        );
      } else {
        // Consolidated Active Loans Report
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando Reporte Consolidado...')),
        );

        final loanRepo = ref.read(loanRepositoryProvider);
        final loansData = await loanRepo.getConsolidatedActiveLoans();

        if (!mounted) return;

        if (loansData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay préstamos vigentes para reportar'),
            ),
          );
          return;
        }

        await pdfService.generateConsolidatedActiveLoansReport(
          loansData: loansData,
          settings: settings,
          locale: S.of(context).locale,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: AppColors.danger,
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
