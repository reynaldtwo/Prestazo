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

class PdfGeneratorService {
  final _currencyFormat = NumberFormat.currency(
    symbol: 'C\$ ',
    decimalDigits: 2,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy h:mm a');

  Future<void> generateLoanStatement({
    required Loan loan,
    required Customer customer,
    required List<Payment> payments,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
  }) async {
    final s = S(locale);
    final pdf = pw.Document();

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
        build: (context) => [
          _buildHeader(
            title: s.loanStatement,
            settings: settings,
            logo: profileImage,
            s: s,
          ),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(customer, s),
          pw.Divider(),
          _buildLoanInfo(loan, s),
          pw.SizedBox(height: 20),
          _buildPaymentsTable(payments, allocations, s),
          pw.SizedBox(height: 20),
          _buildSummary(loan, payments, s),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.loanStatement.replaceAll(" ", "_")}_${customer.displayName}_${loan.loanNumber ?? loan.loanId.substring(0, 6)}',
    );
  }

  Future<void> generatePaymentReceipt({
    required Payment payment,
    required Loan loan,
    required Customer customer,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
  }) async {
    final s = S(locale);
    final pdf = pw.Document();

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
  }) async {
    final s = S(locale);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (context) =>
            _buildDisbursementReceiptContent(loan, customer, settings, s),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.disbursementReceipt.replaceAll(" ", "_")}_${loan.loanNumber ?? loan.loanId}',
    );
  }

  Future<void> generateConsolidatedActiveLoansReport({
    required List<Map<String, dynamic>> loansData,
    required AppSettings settings,
    required Locale locale,
  }) async {
    final s = S(locale);
    final pdf = pw.Document();

    // Calculate totals
    double totalPrincipalOriginal = 0;
    double totalPrincipalBalance = 0;
    for (var row in loansData) {
      totalPrincipalOriginal += (row['principal_original'] as num).toDouble();
      totalPrincipalBalance += (row['principal_balance'] as num).toDouble();
    }
    final int count = loansData.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildReportHeader(
            title: s.consolidatedReport,
            settings: settings,
            s: s,
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              s.clientLabel.replaceAll(':', ''),
              s.dateLabel.replaceAll(':', ''),
              s.loanLabel.replaceAll(':', ''),
              s.originalCapital,
              s.currentBalance,
              s.statusActive, // Using generic status label
            ],
            data: loansData.map((row) {
              final loanId =
                  row['loan_number']?.toString() ??
                  (row['loan_id'] as String).substring(0, 6);
              final date = DateTime.parse(row['disbursement_date']);
              final balance = (row['principal_balance'] as num).toDouble();
              final original = (row['principal_original'] as num).toDouble();

              return [
                (loansData.indexOf(row) + 1).toString(),
                row['customer_name']?.toString() ?? 'N/A',
                _dateFormat.format(date),
                loanId,
                _currencyFormat.format(original),
                _currencyFormat.format(balance),
                row['status'].toString(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total ${s.originalCapital}: ${_currencyFormat.format(totalPrincipalOriginal)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Total ${s.pendingBalance}: ${_currencyFormat.format(totalPrincipalBalance)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Total ${s.customers}/${s.loans}: $count',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${s.consolidatedReport.replaceAll(" ", "_")}_${_dateFormat.format(DateTime.now()).replaceAll('/', '-')}',
    );
  }

  Future<void> generateEarningsReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> paymentsData,
    required AppSettings settings,
    required Locale locale,
  }) async {
    final s = S(locale);
    final pdf = pw.Document();

    // Calculate totals
    double totalInterest = 0;
    double totalMora = 0;
    double totalPrincipal = 0;

    for (var row in paymentsData) {
      totalInterest += (row['interest_paid'] as num?)?.toDouble() ?? 0;
      totalMora += (row['mora_paid'] as num?)?.toDouble() ?? 0;
      totalPrincipal += (row['principal_paid'] as num?)?.toDouble() ?? 0;
    }
    final totalEarnings = totalInterest + totalMora;
    final totalCollected = totalEarnings + totalPrincipal;

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
                      _currencyFormat.format(totalEarnings),
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
                    pw.Text(_currencyFormat.format(totalPrincipal)),
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
                      _currencyFormat.format(totalCollected),
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
              ['${s.interest} Cobrado', _currencyFormat.format(totalInterest)],
              ['${s.mora} Cobrada', _currencyFormat.format(totalMora)],
              ['Otros/Fees', _currencyFormat.format(0.0)],
              [
                s.totalEarnings.toUpperCase(),
                _currencyFormat.format(totalEarnings),
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
                  'RUC: ${settings.companyRuc}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (settings.showCompanyAddress &&
                  settings.companyAddress != null)
                pw.Text(
                  'Dir: ${settings.companyAddress}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.Row(
                children: [
                  if (settings.showCompanyPhone &&
                      settings.companyPhone != null)
                    pw.Text(
                      'Tel: ${settings.companyPhone}  ',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (settings.showCompanyCell && settings.companyCell != null)
                    pw.Text(
                      'Cel: ${settings.companyCell}  ',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (settings.showCompanyWhatsapp &&
                      settings.companyWhatsapp != null)
                    pw.Text(
                      'WA: ${settings.companyWhatsapp}',
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
        pw.Text('${s.dniLabel} ${customer.customerId}'),
        if (customer.phone != null)
          pw.Text('${s.customerPhone}: ${customer.phone!}'),
        if (customer.address != null)
          pw.Text('${s.customerAddress}: ${customer.address!}'),
      ],
    );
  }

  pw.Widget _buildLoanInfo(Loan loan, S s) {
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
              '${s.amountGranted} ${_currencyFormat.format(loan.principalOriginal)}',
            ),
            pw.Text(
              '${s.currentBalance}: ${_currencyFormat.format(loan.principalBalance)}',
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
          _currencyFormat.format(p.amount),
          _currencyFormat.format(interest),
          _currencyFormat.format(capital),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
    );
  }

  pw.Widget _buildSummary(Loan loan, List<Payment> payments, S s) {
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          '${s.totalPaidLabel} ${_currencyFormat.format(totalPaid)}',
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
            'RUC: ${settings.companyRuc}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        if (settings.showCompanyPhone && settings.companyPhone != null)
          pw.Text(
            'Tel: ${settings.companyPhone}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        if (settings.showCompanyAddress && settings.companyAddress != null)
          pw.Text(
            'Dir: ${settings.companyAddress}',
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
        if (customer.dni != null) pw.Text('${s.dniLabel} ${customer.dni}'),

        pw.SizedBox(height: 10),
        pw.Divider(),

        // Loan Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.amountGranted),
            pw.Text(
              _currencyFormat.format(loan.principalOriginal),
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

        pw.SizedBox(height: 30),

        // Signatures
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              children: [
                pw.Container(width: 80, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Text(s.deliveredBy, style: const pw.TextStyle(fontSize: 8)),
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
            'RUC: ${settings.companyRuc}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        if (settings.showCompanyPhone && settings.companyPhone != null)
          pw.Text(
            'Tel: ${settings.companyPhone}',
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
              _currencyFormat.format(payment.amount),
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
            pw.Text(_currencyFormat.format(interestPaid)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.capitalLabel),
            pw.Text(_currencyFormat.format(principalPaid)),
          ],
        ),
        pw.Divider(),
        pw.Text(
          '${s.remainingBalance}: ${_currencyFormat.format(loan.principalBalance)}',
        ),
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
