import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for generating and validating idempotency keys and payload hashes.
class IdempotencyService {
  /// Generate a canonical payload hash for a payment.
  ///
  /// The hash is computed from a deterministic set of fields:
  /// - loan_id
  /// - iso_date (YYYY-MM-DD)
  /// - payment_currency
  /// - amount_payment_minor (as string)
  /// - rate_type (BUY/SELL/MID/MANUAL)
  /// - rate_value (as string with fixed precision)
  ///
  /// Returns SHA256 hex string.
  static String computePayloadHash({
    required String loanId,
    required String isoDate,
    required String paymentCurrency,
    required int amountPaymentMinor,
    required String? rateType,
    required double? rateValue,
    int?
    timestamp, // Added: Unique timestamp to differentiate same-day payments
  }) {
    // Build canonical string with pipe separator
    // Include timestamp if provided, otherwise use empty string for legacy compatibility
    final parts = <String>[
      loanId,
      isoDate,
      paymentCurrency,
      amountPaymentMinor.toString(),
      rateType ?? 'NONE',
      rateValue != null ? rateValue.toStringAsFixed(6) : '0.000000',
      timestamp?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    ];

    final canonical = parts.join('|');

    // Compute SHA256
    final bytes = utf8.encode(canonical);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Generate a legacy hash for migrated payments.
  /// Format: SHA256('LEGACY|' + payment_id)
  static String computeLegacyHash(String paymentId) {
    final canonical = 'LEGACY|$paymentId';
    final bytes = utf8.encode(canonical);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate that two payload hashes match.
  /// Returns true if equal, false otherwise.
  static bool validateHash(String existingHash, String newHash) {
    return existingHash == newHash;
  }
}
