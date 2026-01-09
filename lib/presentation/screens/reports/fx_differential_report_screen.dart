import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/providers.dart';
import '../../../core/localization/locale_provider.dart';

/// Screen for displaying FX Differential (exchange rate profit) reports.
class FxDifferentialReportScreen extends ConsumerStatefulWidget {
  const FxDifferentialReportScreen({super.key});

  @override
  ConsumerState<FxDifferentialReportScreen> createState() =>
      _FxDifferentialReportScreenState();
}

class _FxDifferentialReportScreenState
    extends ConsumerState<FxDifferentialReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  bool _isGeneratingPdf = false;

  // Report data
  List<Map<String, dynamic>> _fxPayments = [];
  double _totalEquivalent = 0;
  double _totalApplied = 0;
  double _totalDifferential = 0;
  int _totalPayments = 0;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final db = await paymentRepo.database;

      // Query payments with FX conversion (where payment_currency != loan_currency)
      final exclusiveEndDate = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
      ).add(const Duration(days: 1));

      final results = await db.rawQuery(
        '''
        SELECT 
          p.payment_id,
          p.created_at,
          p.payment_currency,
          p.loan_currency,
          p.amount_payment_minor,
          p.amount_loan_minor,
          p.rate_value_used,
          p.unapplied_minor,
          p.fx_profit_base_minor,
          p.loan_id,
          p.receipt_number,
          c.full_name as customer_name,
          l.loan_number
        FROM payments p
        INNER JOIN customers c ON p.customer_id = c.customer_id
        INNER JOIN loans l ON p.loan_id = l.loan_id
        WHERE p.payment_currency != p.loan_currency
          AND p.status = 'VALID'
          AND p.created_at >= ?
          AND p.created_at < ?
        ORDER BY p.created_at DESC
      ''',
        [_startDate.toIso8601String(), exclusiveEndDate.toIso8601String()],
      );

      // Calculate totals
      double totalEquiv = 0;
      double totalApplied = 0;
      double totalDiff = 0;

      for (final row in results) {
        final amountLoanMinor = (row['amount_loan_minor'] as int?) ?? 0;
        final unappliedMinor = (row['unapplied_minor'] as int?) ?? 0;

        totalEquiv += amountLoanMinor / 100.0;
        totalApplied += (amountLoanMinor - unappliedMinor) / 100.0;
        totalDiff += unappliedMinor / 100.0;
      }

      if (mounted) {
        setState(() {
          _fxPayments = results;
          _totalPayments = results.length;
          _totalEquivalent = totalEquiv;
          _totalApplied = totalApplied;
          _totalDifferential = totalDiff;
        });
      }
    } catch (e) {
      debugPrint('Error loading FX data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatMoney(double amount) {
    final format = NumberFormat('#,##0.00', 'es_NI');
    return format.format(amount);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadData();
    }
  }

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGeneratingPdf = true);

    // Capture localized strings before async operations
    final l10n = S.of(context);
    final pdfTitle = l10n.fxDifferentialReportTitle;
    final periodLabel = l10n.periodFromTo(
      DateFormat('dd/MM/yyyy').format(_startDate),
      DateFormat('dd/MM/yyyy').format(_endDate),
    );
    final indicatorLabel = l10n.indicator;
    final valueLabel = l10n.value;
    final totalFxPaymentsLabel = l10n.totalFxPayments;
    final totalEquivalentLabel = l10n.totalEquivalentConverted;
    final totalAppliedLabel = l10n.totalAppliedToDebt;
    final differentialProfitLabel = l10n.differentialProfit;
    final operationsDetailLabel = l10n.operationsDetail;
    final dateLabel = l10n.date;
    final clientLabel = l10n.client;
    final loanLabel = l10n.loanLabel;
    final receiptNoLabel = l10n.receiptNo;
    final paymentCurrencyLabel = l10n.paymentCurrency;
    final paymentAmountLabel = l10n.paymentAmountLabel;
    final appliedRateLabel = l10n.appliedRate;
    final equivalentCalculatedLabel = l10n.equivalentCalculated;
    final amountAppliedLabel = l10n.amountAppliedToDebt;
    final fxDifferentialLabel = l10n.fxDifferential;
    final shareText = l10n.shareReportText;
    final baseCurrencyLabel = l10n.baseCurrency;

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                pdfTitle,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(periodLabel, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),

            // Summary Table
            pw.TableHelper.fromTextArray(
              headers: [indicatorLabel, valueLabel],
              data: [
                [totalFxPaymentsLabel, '$_totalPayments'],
                [
                  totalEquivalentLabel,
                  '${_formatMoney(_totalEquivalent)} ($baseCurrencyLabel)',
                ],
                [
                  totalAppliedLabel,
                  '${_formatMoney(_totalApplied)} ($baseCurrencyLabel)',
                ],
                [
                  differentialProfitLabel,
                  '${_formatMoney(_totalDifferential)} ($baseCurrencyLabel)',
                ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 24),

            // Detail Header
            pw.Header(
              level: 1,
              child: pw.Text(
                operationsDetailLabel,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),

            // Detail Table
            pw.TableHelper.fromTextArray(
              headers: [
                dateLabel,
                clientLabel,
                loanLabel,
                receiptNoLabel,
                paymentCurrencyLabel,
                paymentAmountLabel,
                appliedRateLabel,
                equivalentCalculatedLabel,
                amountAppliedLabel,
                fxDifferentialLabel,
              ],
              data: _fxPayments.map((p) {
                final amountPayment =
                    ((p['amount_payment_minor'] as int?) ?? 0) / 100.0;
                final amountLoan =
                    ((p['amount_loan_minor'] as int?) ?? 0) / 100.0;
                final unapplied = ((p['unapplied_minor'] as int?) ?? 0) / 100.0;
                final applied = amountLoan - unapplied;
                final rate = (p['rate_value_used'] as num?)?.toDouble() ?? 0;
                final currency = p['payment_currency']?.toString() ?? '';
                final customerName = p['customer_name']?.toString() ?? '';
                final loanNumber = p['loan_number']?.toString() ?? '';
                final receiptNumber = p['receipt_number']?.toString() ?? '';

                return [
                  _formatDate(p['created_at'] ?? ''),
                  customerName.length > 15
                      ? '${customerName.substring(0, 15)}...'
                      : customerName,
                  loanNumber,
                  receiptNumber,
                  currency,
                  _formatMoney(amountPayment),
                  rate.toStringAsFixed(2),
                  _formatMoney(amountLoan),
                  _formatMoney(applied),
                  '+${_formatMoney(unapplied)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 7,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/fx_differential_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Share
      await Share.shareXFiles([XFile(file.path)], text: shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Report Header with title and actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).fxDifferentialReport,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                tooltip: S.of(context).sharePdf,
                onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: S.of(context).refresh,
                onPressed: _loadData,
              ),
            ],
          ),
        ),

        // Date Range Selector
        _buildDateRangeSelector(),

        // Summary Cards
        _buildSummaryCards(),

        // Detail List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _fxPayments.isEmpty
              ? _buildEmptyState()
              : _buildDetailList(),
        ),
      ],
    );
  }

  Widget _buildSummaryBullets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBulletPoint(
          'Total pagos en moneda extranjera:',
          '$_totalPayments',
        ),
        _buildBulletPoint(
          'Total diferencial cambiario ganado:',
          'NIO ${_formatMoney(_totalDifferential)}',
          isHighlight: true,
        ),
        _buildBulletPoint('Moneda extranjera utilizada:', 'USD'),
      ],
    );
  }

  Widget _buildBulletPoint(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$label ', style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isHighlight ? AppColors.success : AppColors.primary,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle de operaciones',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Préstamo')),
              DataColumn(label: Text('Moneda\nPago')),
              DataColumn(label: Text('Monto Pago')),
              DataColumn(label: Text('Tasa\nAplicada')),
              DataColumn(label: Text('Equivalente\nCalculado')),
              DataColumn(label: Text('Monto\nAplicado')),
              DataColumn(label: Text('Diferencial\nCambiario')),
            ],
            rows: _fxPayments.map((p) {
              final amountPayment =
                  ((p['amount_payment_minor'] as int?) ?? 0) / 100.0;
              final amountLoan =
                  ((p['amount_loan_minor'] as int?) ?? 0) / 100.0;
              final unapplied = ((p['unapplied_minor'] as int?) ?? 0) / 100.0;
              final applied = amountLoan - unapplied;
              final rate = (p['rate_value_used'] as num?)?.toDouble() ?? 0;
              final paymentCurrency = p['payment_currency']?.toString() ?? '';
              final customerName = p['customer_name']?.toString() ?? '';
              final loanNumber = p['loan_number']?.toString() ?? '';

              return DataRow(
                cells: [
                  DataCell(Text(_formatDate(p['created_at'] ?? ''))),
                  DataCell(
                    Text(
                      customerName.length > 12
                          ? '${customerName.substring(0, 12)}...'
                          : customerName,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  DataCell(
                    Text(
                      loanNumber,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  DataCell(Text(paymentCurrency)),
                  DataCell(Text(_formatMoney(amountPayment))),
                  DataCell(Text(rate.toStringAsFixed(2))),
                  DataCell(
                    Text(
                      _formatMoney(amountLoan),
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatMoney(applied),
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '+${_formatMoney(unapplied)}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(true),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_startDate),
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('−'),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_endDate),
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main profit card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  S.of(context).differentialProfit2,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(_totalDifferential),
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Secondary stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  S.of(context).fxPayments,
                  '$_totalPayments',
                  Icons.currency_exchange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  S.of(context).applied,
                  _formatMoney(_totalApplied),
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.currency_exchange,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).noFxOperations,
            style: AppTypography.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).noFxPaymentsInPeriod,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _fxPayments.length,
      itemBuilder: (context, index) {
        final payment = _fxPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amountPayment =
        ((payment['amount_payment_minor'] as int?) ?? 0) / 100.0;
    final amountLoan = ((payment['amount_loan_minor'] as int?) ?? 0) / 100.0;
    final unapplied = ((payment['unapplied_minor'] as int?) ?? 0) / 100.0;
    final rate = (payment['rate_value_used'] as num?)?.toDouble() ?? 0;
    final paymentCurrency = payment['payment_currency']?.toString() ?? '';
    final loanCurrency = payment['loan_currency']?.toString() ?? '';
    final customerName = payment['customer_name']?.toString() ?? '';
    final loanNumber = payment['loan_number']?.toString() ?? '';

    final paySymbol =
        FiatCurrency.maybeFromCode(paymentCurrency)?.symbol ?? paymentCurrency;
    final loanSymbol =
        FiatCurrency.maybeFromCode(loanCurrency)?.symbol ?? loanCurrency;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    customerName,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$loanSymbol ${_formatMoney(unapplied)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Details row
            Row(
              children: [
                _buildDetailChip(
                  Icons.calendar_today,
                  _formatDate(payment['created_at'] ?? ''),
                ),
                const SizedBox(width: 8),
                _buildDetailChip(Icons.receipt_long, loanNumber),
              ],
            ),
            const SizedBox(height: 8),

            // Amount conversion row
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$paySymbol ${_formatMoney(amountPayment)} × $rate = $loanSymbol ${_formatMoney(amountLoan)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
