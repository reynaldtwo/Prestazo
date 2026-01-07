import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/loan.dart';
import '../data/models/customer.dart';
import '../data/models/payment.dart';
import 'dart:io';
import 'package:flutter/widgets.dart' show FileImage; // For loading image
import '../data/models/app_settings.dart';
import '../data/models/payment_allocation.dart';
import '../core/localization/locale_provider.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

class PdfGeneratorService {
  // Removed static currencyFormat to allow dynamic symbols
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy h:mm a');

  Future<void> generateLoanStatement({
    required Loan loan,
    required Customer customer,
    required List<Payment> payments,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    // Load image if path provided and enabled
    pw.ImageProvider? profileImage;
    if (settings.showCompanyLogo &&
        settings.companyLogoPath != null &&
        settings.companyLogoPath!.isNotEmpty) {
      try {
        final image = await flutterImageProvider(
          FileImage(File(settings.companyLogoPath!)),
        );
        profileImage = image;
      } catch (e) {
        // Ignore image error
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => _buildLoanStatementWidgets(
          loan: loan,
          customer: customer,
          payments: payments,
          allocations: allocations,
          settings: settings,
          s: s,
          profileImage: profileImage,
          currencyFormat: currencyFormat,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.loanStatement.replaceAll(" ", "_")}_${customer.displayName}_${loan.loanNumber ?? loan.loanId.substring(0, 6)}',
    );
  }

  /// Get loan statement as PDF bytes (for sharing via WhatsApp/email)
  Future<List<int>> getLoanStatementBytes({
    required Loan loan,
    required Customer customer,
    required List<Payment> payments,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    // Load image if path provided and enabled
    pw.ImageProvider? profileImage;
    if (settings.showCompanyLogo &&
        settings.companyLogoPath != null &&
        settings.companyLogoPath!.isNotEmpty) {
      try {
        final image = await flutterImageProvider(
          FileImage(File(settings.companyLogoPath!)),
        );
        profileImage = image;
      } catch (e) {
        // Ignore image error
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => _buildLoanStatementWidgets(
          loan: loan,
          customer: customer,
          payments: payments,
          allocations: allocations,
          settings: settings,
          s: s,
          profileImage: profileImage,
          currencyFormat: currencyFormat,
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> generatePaymentReceipt({
    required Payment payment,
    required Loan loan,
    required Customer customer,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt roll format often used
        margin: const pw.EdgeInsets.all(10),
        build: (context) => _buildReceiptContent(
          payment,
          loan,
          customer,
          allocations,
          settings,
          s,
          currencyFormat,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${s.paymentReceipt.replaceAll(" ", "_")}_${payment.receiptNumber}',
    );
  }

  Future<void> generateDisbursementReceipt({
    required Loan loan,
    required Customer customer,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => _buildDisbursementReceiptContent(
          loan,
          customer,
          settings,
          s,
          currencyFormat,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.disbursementReceipt.replaceAll(" ", "_")}_${loan.loanNumber ?? loan.loanId}',
    );
  }

  /// Get disbursement receipt as PDF bytes (for sharing via WhatsApp/email)
  /// Uses the same format as generateDisbursementReceipt
  Future<List<int>> getDisbursementReceiptBytes({
    required Loan loan,
    required Customer customer,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => _buildDisbursementReceiptContent(
          loan,
          customer,
          settings,
          s,
          currencyFormat,
        ),
      ),
    );

    return pdf.save();
  }

  /// Get payment receipt as PDF bytes (for sharing via WhatsApp/email)
  /// Uses the same format as generatePaymentReceipt
  Future<List<int>> getPaymentReceiptBytes({
    required Payment payment,
    required Loan loan,
    required Customer customer,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => _buildReceiptContent(
          payment,
          loan,
          customer,
          allocations,
          settings,
          s,
          currencyFormat,
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> generateConsolidatedActiveLoansReport({
    required List<Map<String, dynamic>> loansData,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
    // Pre-calculated multi-currency aggregated totals (optional)
    double? aggregatedTotalOriginal,
    double? aggregatedTotalBalance,
    // New: totals by currency for dynamic display
    Map<String, double>? totalsByCurrencyOriginal,
    Map<String, double>? totalsByCurrencyBalance,
    String? baseCurrencyCode,
    double? totalInBaseCurrency,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = _dateFormat.format(now);
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Calculate totals by currency if not provided
    final currencyTotalsOriginal =
        totalsByCurrencyOriginal ?? <String, double>{};
    final currencyTotalsBalance = totalsByCurrencyBalance ?? <String, double>{};

    if (totalsByCurrencyOriginal == null) {
      for (var row in loansData) {
        final currency =
            row['currency_code'] as String? ?? settings.baseCurrency;
        final original = (row['principal_original'] as num).toDouble();
        final balance = (row['principal_balance'] as num).toDouble();
        currencyTotalsOriginal[currency] =
            (currencyTotalsOriginal[currency] ?? 0) + original;
        currencyTotalsBalance[currency] =
            (currencyTotalsBalance[currency] ?? 0) + balance;
      }
    }

    // Get unique currencies sorted
    final uniqueCurrencies = currencyTotalsBalance.keys.toList()..sort();
    final int clientCount = loansData
        .map((r) => r['customer_id'])
        .toSet()
        .length;

    // Use aggregated values if provided
    final displayTotalBalance =
        aggregatedTotalBalance ??
        currencyTotalsBalance.values.fold<double>(0.0, (a, b) => a + b);
    final baseTotalBalance = totalInBaseCurrency ?? displayTotalBalance;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // === HEADER SECTION ===
          pw.Text(
            s.consolidatedReport,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            (settings.companyName?.isNotEmpty ?? false)
                ? settings.companyName!
                : 'Prestazo',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),

          // === SUMMARY ROW WITH TOTALS ===
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side: Currency totals
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total de clientes registrados: $clientCount',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    // Dynamic currency totals
                    ...uniqueCurrencies.map((currency) {
                      final symbol = _getCurrencySymbol(currency);
                      final total = currencyTotalsBalance[currency] ?? 0;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          'Total en $currency: $symbol ${_formatNumber(total)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      );
                    }),
                    pw.SizedBox(height: 4),
                    // Total in Base Currency (yellow background)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.yellow100,
                      ),
                      child: pw.Text(
                        'Total en ${baseCurrencyCode ?? settings.baseCurrency}: ${_getCurrencySymbol(baseCurrencyCode ?? settings.baseCurrency)} ${_formatNumber(baseTotalBalance)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    // Total in Display Currency (green background)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.green100,
                      ),
                      child: pw.Text(
                        'Total en moneda de visualización: $currencySymbol ${_formatNumber(displayTotalBalance)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Date and Time (aligned right)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Fecha del reporte    $dateStr',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Hora    $timeStr',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // === DATA TABLE ===
          pw.TableHelper.fromTextArray(
            headers: [
              s.dateLabel.replaceAll(':', ''),
              'N° Préstamo',
              'DNI',
              s.clientLabel.replaceAll(':', ''),
              'Moneda',
              'Capital Desembolsado',
              s.currentBalance,
            ],
            data: loansData.map((row) {
              final loanNumber =
                  row['loan_number']?.toString() ??
                  (row['loan_id'] as String).substring(0, 6);
              final date = DateTime.parse(row['disbursement_date'] as String);
              final currency =
                  row['currency_code'] as String? ?? settings.baseCurrency;
              final symbol = _getCurrencySymbol(currency);
              final original = (row['principal_original'] as num).toDouble();
              final balance = (row['principal_balance'] as num).toDouble();
              final dni = row['customer_dni']?.toString() ?? 'N/A';

              return [
                _dateFormat.format(date),
                loanNumber,
                dni,
                row['customer_name']?.toString() ?? 'N/A',
                currency,
                '$symbol ${_formatNumber(original)}',
                '$symbol ${_formatNumber(balance)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.consolidatedReport.replaceAll(" ", "_")}_${dateStr.replaceAll('/', '-')}',
    );
  }

  /// Helper to get currency symbol from code (dynamic, no hardcoded values)
  String _getCurrencySymbol(String code) {
    // Use sealed_currencies package for dynamic symbol lookup
    final currency = FiatCurrency.maybeFromCode(code);
    return currency?.symbol ?? code; // Fallback to code if not found
  }

  /// Helper to format numbers with commas
  String _formatNumber(double value) {
    return NumberFormat('#,##0.00').format(value);
  }

  Future<void> generateEarningsReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> paymentsData,
    required AppSettings settings,
    required Locale locale,
    required String currencySymbol,
    // Pre-calculated multi-currency aggregated totals (optional)
    double? aggregatedTotalEarnings,
    double? aggregatedTotalPrincipal,
    double? aggregatedTotalCollected,
  }) async {
    final s = lookupS(locale);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );

    // Use pre-calculated totals if provided, otherwise calculate locally
    double totalInterest = 0;
    double totalMora = 0;
    double totalPrincipal = 0;

    for (var row in paymentsData) {
      totalInterest += (row['interest_paid'] as num?)?.toDouble() ?? 0;
      totalMora += (row['mora_paid'] as num?)?.toDouble() ?? 0;
      totalPrincipal += (row['principal_paid'] as num?)?.toDouble() ?? 0;
    }

    // Use aggregated values if provided (multi-currency normalized)
    final totalEarnings =
        aggregatedTotalEarnings ?? (totalInterest + totalMora);
    final totalCollected =
        aggregatedTotalCollected ?? (totalEarnings + totalPrincipal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildReportHeader(
            title: s.earningsReport,
            settings: settings,
            subtitle:
                '${s.dateLabel} ${_dateFormat.format(startDate)} ${s.to} ${_dateFormat.format(endDate)}',
            s: s,
          ),
          pw.SizedBox(height: 30),

          // Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${s.totalEarnings} (${s.interest} + ${s.mora}):',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      currencyFormat.format(totalEarnings),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${s.capitalRecovered}:'),
                    pw.Text(currencyFormat.format(totalPrincipal)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${s.collectedToday.replaceAll("Hoy", "")}:',
                    ), // "Total Cobrado" roughly
                    pw.Text(
                      currencyFormat.format(totalCollected),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Text(
            '${s.paymentBreakdown}:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.TableHelper.fromTextArray(
            headers: ['Concepto', 'Monto'],
            data: [
              ['${s.interest} Cobrado', currencyFormat.format(totalInterest)],
              ['${s.mora} Cobrada', currencyFormat.format(totalMora)],
              ['Otros/Fees', currencyFormat.format(0.0)],
              [
                s.totalEarnings.toUpperCase(),
                currencyFormat.format(totalEarnings),
              ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {0: pw.Alignment.centerLeft},
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.earningsReport.replaceAll(" ", "_")}_${_dateFormat.format(startDate).replaceAll('/', '-')}_${_dateFormat.format(endDate).replaceAll('/', '-')}',
    );
  }

  // --- Helper Build Methods ---

  List<pw.Widget> _buildLoanStatementWidgets({
    required Loan loan,
    required Customer customer,
    required List<Payment> payments,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required S s,
    pw.ImageProvider? profileImage,
    required NumberFormat currencyFormat,
  }) {
    return [
      _buildHeader(
        title: s.loanStatement,
        settings: settings,
        logo: profileImage,
        s: s,
      ),
      pw.SizedBox(height: 20),
      _buildCustomerInfo(customer, s),
      pw.Divider(),
      _buildLoanInfo(loan, s, currencyFormat),
      pw.SizedBox(height: 20),
      _buildPaymentsTable(payments, allocations, s, currencyFormat),
      pw.SizedBox(height: 20),
      _buildSummary(loan, payments, s, currencyFormat),
    ];
  }

  pw.Widget _buildHeader({
    required String title,
    required AppSettings settings,
    required S s,
    pw.ImageProvider? logo,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (settings.showCompanyName && settings.companyName != null)
                pw.Text(
                  settings.companyName!,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                )
              else
                pw.Text(
                  'PrestamosApp', // Fallback
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (settings.showCompanyRuc && settings.companyRuc != null)
                pw.Text(
                  '${s.labelRuc} ${settings.companyRuc}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (settings.showCompanyAddress &&
                  settings.companyAddress != null)
                pw.Text(
                  '${s.labelDir} ${settings.companyAddress}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.Row(
                children: [
                  if (settings.showCompanyPhone &&
                      settings.companyPhone != null)
                    pw.Text(
                      '${s.labelTel} ${settings.companyPhone}  ',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (settings.showCompanyCell && settings.companyCell != null)
                    pw.Text(
                      '${s.labelCel} ${settings.companyCell}  ',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (settings.showCompanyWhatsapp &&
                      settings.companyWhatsapp != null)
                    pw.Text(
                      '${s.labelWa} ${settings.companyWhatsapp}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (logo != null)
              pw.Container(height: 50, width: 50, child: pw.Image(logo)),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Fecha: ${_dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer, S s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          s.clientLabel,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(customer.displayName),
        // FIX: Display DNI if available instead of customerId (uuid)
        if (customer.dni != null) pw.Text('${s.dniLabel} ${customer.dni}'),

        if (customer.phone != null)
          pw.Text('${s.customerPhone}: ${customer.phone!}'),
        if (customer.address != null)
          pw.Text('${s.customerAddress}: ${customer.address!}'),
      ],
    );
  }

  pw.Widget _buildLoanInfo(Loan loan, S s, NumberFormat currencyFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('${s.loanLabel} ${loan.loanNumber ?? "Sin Número"}'),
            pw.Text(
              '${s.disbursementDate}: ${_dateFormat.format(loan.disbursementDate)}',
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '${s.amountGranted} ${currencyFormat.format(loan.principalOriginal)}',
            ),
            pw.Text(
              '${s.currentBalance}: ${currencyFormat.format(loan.principalBalance)}',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentsTable(
    List<Payment> payments,
    List<PaymentAllocation> allocations,
    S s,
    NumberFormat currencyFormat,
  ) {
    if (payments.isEmpty) {
      return pw.Text(s.noPayments);
    }

    final headers = [
      s.dateLabel.replaceAll(':', ''),
      s.receiptNumber,
      s.paymentAmount,
      s.interest,
      s.capital,
    ];

    // Sort payments by date
    final sortedPayments = List<Payment>.from(payments);
    sortedPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: sortedPayments.map((p) {
        final paymentAllocations = allocations
            .where((a) => a.paymentId == p.paymentId)
            .toList();

        final interest = paymentAllocations
            .where(
              (a) =>
                  a.allocationType == 'INTEREST' || a.allocationType == 'MORA',
            )
            .fold(0.0, (sum, a) => sum + a.amount);

        final capital = paymentAllocations
            .where((a) => a.allocationType == 'PRINCIPAL')
            .fold(0.0, (sum, a) => sum + a.amount);

        return [
          _dateFormat.format(p.paymentDate),
          p.receiptNumber.toString(),
          currencyFormat.format(p.amount),
          currencyFormat.format(interest),
          currencyFormat.format(capital),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
    );
  }

  pw.Widget _buildSummary(
    Loan loan,
    List<Payment> payments,
    S s,
    NumberFormat currencyFormat,
  ) {
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          '${s.totalPaidLabel} ${currencyFormat.format(totalPaid)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildDisbursementReceiptContent(
    Loan loan,
    Customer customer,
    AppSettings settings,
    S s,
    NumberFormat currencyFormat,
  ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (settings.showCompanyName && settings.companyName != null)
          pw.Text(
            settings.companyName!,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
        if (settings.showCompanyRuc && settings.companyRuc != null)
          pw.Text(
            '${s.labelRuc} ${settings.companyRuc}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        if (settings.showCompanyPhone && settings.companyPhone != null)
          pw.Text(
            '${s.labelTel} ${settings.companyPhone}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        if (settings.showCompanyAddress && settings.companyAddress != null)
          pw.Text(
            '${s.labelDir} ${settings.companyAddress}',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),

        pw.SizedBox(height: 8),
        pw.Text(
          s.disbursementReceipt.toUpperCase(),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Divider(),
        pw.Text('${s.dateLabel} ${_dateFormat.format(loan.disbursementDate)}'),
        pw.Text('${s.loanLabel} ${loan.loanNumber ?? "Sin Número"}'),
        pw.SizedBox(height: 10),

        // Client Info
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('${s.clientLabel} '),
            pw.Expanded(
              child: pw.Text(
                customer.displayName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        if (customer.dni != null)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${s.dniLabel} '),
              pw.Expanded(
                child: pw.Text(
                  customer.dni!,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),

        pw.SizedBox(height: 10),
        pw.Divider(),

        // Loan Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.amountGranted),
            pw.Text(
              currencyFormat.format(loan.principalOriginal),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.interestRateLabel),
            pw.Text(
              '${loan.monthlyInterestRate}% ${s.freqMonthly}',
            ), // Assuming monthly for now
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.frequencyLabel),
            pw.Text(_translateFrequency(loan.billingFrequency, s)),
          ],
        ),
        if (loan.endDate != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(s.maturityDateLabel),
              pw.Text(_dateFormat.format(loan.endDate!)),
            ],
          ),

        if (settings.showDisbursementSignatures) ...[
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 80, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    s.deliveredBy,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 80, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 2),
                  pw.Text(s.receivedBy, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
        ],

        if (settings.showDisbursementLegend &&
            (settings.disbursementLegend?.isNotEmpty ?? false)) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            settings.disbursementLegend!,
            style: pw.TextStyle(fontSize: 8.0, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],

        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text(s.thankYouPreference)),
      ],
    );
  }

  String _translateFrequency(String frequency, S s) {
    switch (frequency) {
      case 'DAILY':
        return s.freqDaily;
      case 'WEEKLY':
        return s.freqWeekly;
      case 'BIWEEKLY':
        return s.freqBiweekly;
      case 'MONTHLY':
        return s.freqMonthly;
      default:
        return frequency;
    }
  }

  pw.Widget _buildReceiptContent(
    Payment payment,
    Loan loan,
    Customer customer,
    List<PaymentAllocation> allocations,
    AppSettings settings,
    S s,
    NumberFormat currencyFormat,
  ) {
    final interestPaid = allocations
        .where(
          (a) => a.allocationType == 'INTEREST' || a.allocationType == 'MORA',
        )
        .fold(0.0, (sum, a) => sum + a.amount);

    final principalPaid = allocations
        .where((a) => a.allocationType == 'PRINCIPAL')
        .fold(0.0, (sum, a) => sum + a.amount);

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (settings.showCompanyName && settings.companyName != null)
          pw.Text(
            settings.companyName!,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
        if (settings.showCompanyRuc && settings.companyRuc != null)
          pw.Text(
            '${s.labelRuc} ${settings.companyRuc}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        if (settings.showCompanyPhone && settings.companyPhone != null)
          pw.Text(
            '${s.labelTel} ${settings.companyPhone}',
            style: const pw.TextStyle(fontSize: 8),
          ),

        pw.SizedBox(height: 4),
        pw.Text(
          s.paymentReceipt.toUpperCase(),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Divider(),
        pw.Text(
          '${s.dateLabel} ${_dateTimeFormat.format(payment.paymentDate)}',
        ),
        pw.Text('${s.receiptNumber}: ${payment.receiptNumber}'),
        pw.SizedBox(height: 10),
        pw.Text('${s.clientLabel} ${customer.displayName}'),
        pw.Text('${s.loanLabel} ${loan.loanNumber ?? "Sin Número"}'),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${s.paymentAmount}:'),
            pw.Text(
              currencyFormat.format(payment.amount),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Divider(),
        pw.Text('${s.distribution}:'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.interestMoraLabel),
            pw.Text(currencyFormat.format(interestPaid)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.capitalLabel),
            pw.Text(currencyFormat.format(principalPaid)),
          ],
        ),
        pw.Divider(),
        pw.Text(
          '${s.remainingBalance}: ${currencyFormat.format(loan.principalBalance)}',
        ),
        if (settings.showPaymentSignatures) ...[
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 80, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    s.deliveredBy,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 80, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 2),
                  pw.Text(s.receivedBy, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
        ],

        if (settings.showPaymentLegend &&
            (settings.paymentLegend?.isNotEmpty ?? false)) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            settings.paymentLegend!,
            style: pw.TextStyle(fontSize: 8.0, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],

        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text(s.thankYouPayment)),
      ],
    );
  }

  pw.Widget _buildReportHeader({
    required String title,
    required AppSettings settings,
    required S s,
    String? subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (settings.showCompanyName && settings.companyName != null)
          pw.Text(
            settings.companyName!,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 5),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        if (subtitle != null) ...[pw.SizedBox(height: 2), pw.Text(subtitle)],
        pw.SizedBox(height: 5),
        pw.Text(
          '${s.generated} ${_dateTimeFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }
}
