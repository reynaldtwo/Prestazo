/// WhatsApp Service
///
/// Service for sending receipts and documents via WhatsApp
library;

import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/loan.dart';
import '../data/models/customer.dart';
import '../data/models/payment.dart';
import '../data/models/payment_allocation.dart';
import '../data/models/app_settings.dart';
import '../core/localization/locale_provider.dart';
import 'pdf_generator_service.dart';

/// WhatsApp integration service for sharing PDF receipts
class WhatsAppService {
  WhatsAppService._();

  /// Check if a phone number is valid for WhatsApp
  /// Requires at least 8 digits
  static bool isValidNumber(String? number) {
    if (number == null || number.isEmpty) return false;

    // Remove all non-digit characters
    final digits = number.replaceAll(RegExp(r'[^\d]'), '');

    // WhatsApp needs at least 8 digits
    return digits.length >= 8;
  }

  /// Generate disbursement receipt PDF and share to WhatsApp
  /// Returns true if shared successfully
  static Future<bool> shareDisbursementReceipt({
    required Loan loan,
    required Customer customer,
    required AppSettings settings,
    required Locale locale,
  }) async {
    try {
      final s = S(locale);

      // Generate PDF bytes using PdfGeneratorService (same format as print)
      final pdfGenerator = PdfGeneratorService();
      final pdfBytes = await pdfGenerator.getDisbursementReceiptBytes(
        loan: loan,
        customer: customer,
        settings: settings,
        locale: locale,
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${s.disbursementReceipt.replaceAll(" ", "_")}_${loan.loanNumber ?? loan.loanId}.pdf';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      debugPrint('WhatsApp: PDF saved to ${tempFile.path}');

      // Share via WhatsApp with PDF attached (using translations)
      final currencyFormat = 'C\$ ${loan.principalOriginal.toStringAsFixed(2)}';
      final message = s.whatsAppDisbursementMsg(
        customer.fullName,
        loan.loanNumber ?? '',
        currencyFormat,
      );

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: message,
        subject: '${s.disbursementReceipt} - ${loan.loanNumber ?? ''}',
      );

      return true;
    } catch (e) {
      debugPrint('WhatsApp: Error sharing disbursement receipt - $e');
      return false;
    }
  }

  /// Generate payment receipt PDF and share to WhatsApp
  /// Returns true if shared successfully
  static Future<bool> sharePaymentReceipt({
    required Payment payment,
    required Loan loan,
    required Customer customer,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
  }) async {
    try {
      final s = S(locale);

      // Generate PDF bytes
      final pdfGenerator = PdfGeneratorService();
      final pdfBytes = await pdfGenerator.getPaymentReceiptBytes(
        payment: payment,
        loan: loan,
        customer: customer,
        allocations: allocations,
        settings: settings,
        locale: locale,
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${s.paymentReceipt.replaceAll(" ", "_")}_${payment.receiptNumber}.pdf';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      debugPrint('WhatsApp: PDF saved to ${tempFile.path}');

      // Share via WhatsApp with PDF attached
      final currencyFormat = 'C\$ ${payment.amount.toStringAsFixed(2)}';

      // We might need a specific message for payment receipt
      // For now reusing a similar pattern or adding a new translation if needed
      // User asked not to leave anything "burned" (hardcoded)
      // I'll check locale_provider for a specific message, or use a generic one

      final message = s.whatsAppPaymentMsg(
        customer.fullName,
        payment.receiptNumber.toString(),
        currencyFormat,
      );

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: message,
        subject: '${s.paymentReceipt} - #${payment.receiptNumber}',
      );

      return true;
    } catch (e) {
      debugPrint('WhatsApp: Error sharing payment receipt - $e');
      return false;
    }
  }

  /// Generate loan statement PDF and share to WhatsApp
  /// Returns true if shared successfully
  static Future<bool> shareLoanStatement({
    required Loan loan,
    required Customer customer,
    required List<Payment> payments,
    required List<PaymentAllocation> allocations,
    required AppSettings settings,
    required Locale locale,
  }) async {
    try {
      final s = S(locale);

      // Generate PDF bytes
      final pdfGenerator = PdfGeneratorService();
      final pdfBytes = await pdfGenerator.getLoanStatementBytes(
        loan: loan,
        customer: customer,
        payments: payments,
        allocations: allocations,
        settings: settings,
        locale: locale,
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${s.loanStatement.replaceAll(" ", "_")}_${loan.loanNumber ?? loan.loanId}.pdf';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      debugPrint('WhatsApp: PDF saved to ${tempFile.path}');

      // Share via WhatsApp with PDF attached
      final message = s.whatsAppStatementMsg(
        customer.fullName,
        loan.loanNumber ?? '',
      );

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: message,
        subject: '${s.loanStatement} - ${loan.loanNumber ?? ''}',
      );

      return true;
    } catch (e) {
      debugPrint('WhatsApp: Error sharing loan statement - $e');
      return false;
    }
  }
}
