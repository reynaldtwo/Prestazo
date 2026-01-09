import 'package:equatable/equatable.dart';
import '../../core/constants/app_status.dart';

/// Payment model - Matches V25 schema with minor units (Int64)
/// Includes backward-compatible fields for smooth migration
class Payment extends Equatable {
  final String paymentId;
  final String loanId;

  // Amounts in minor units (centavos)
  final int amountPaymentMinor; // What customer paid in payment currency
  final int amountBaseMinor; // Equivalent in base currency
  final int amountLoanMinor; // Equivalent in loan currency

  // Currencies (all required)
  final String paymentCurrency;
  final String loanCurrency;
  final String baseCurrency;

  // FX tracking
  final String? rateId;
  final String? rateTypeUsed; // BUY, SELL, MID, MANUAL
  final double? rateValueUsed;
  final String? rateDateUsed;
  final double? referenceRateValue;
  final int fxProfitBaseMinor;
  final String fxStatus; // NONE, APPLIED, PENDING

  // Status & VOID
  final String status; // VALID, VOIDED
  final String? voidReasonKey;
  final DateTime? voidedAt;

  // Idempotency
  final String idempotencyKey;
  final String payloadHash;

  // Legacy migration
  final DateTime? legacyMigratedAt;
  final bool legacyAmbiguous;

  // Unapplied amount (overpayment)
  final int unappliedMinor;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // === DEPRECATED FIELDS (for backward compatibility) ===
  final String? _customerId;
  final String? _receiptNumber;
  final String? _declaredType;
  final String? _notes;

  const Payment({
    required this.paymentId,
    required this.loanId,
    required this.amountPaymentMinor,
    required this.amountBaseMinor,
    required this.amountLoanMinor,
    required this.paymentCurrency,
    required this.loanCurrency,
    required this.baseCurrency,
    this.rateId,
    this.rateTypeUsed,
    this.rateValueUsed,
    this.rateDateUsed,
    this.referenceRateValue,
    this.fxProfitBaseMinor = 0,
    this.fxStatus = 'NONE',
    this.status = AppStatus.paymentValid,
    this.voidReasonKey,
    this.voidedAt,
    required this.idempotencyKey,
    required this.payloadHash,
    this.legacyMigratedAt,
    this.legacyAmbiguous = false,
    this.unappliedMinor = 0,
    required this.createdAt,
    required this.updatedAt,
    // Deprecated params
    String? customerId,
    String? receiptNumber,
    String? declaredType,
    String? notes,
  }) : _customerId = customerId,
       _receiptNumber = receiptNumber,
       _declaredType = declaredType,
       _notes = notes;

  /// Check if payment is valid
  bool get isValid => status == AppStatus.paymentValid;

  /// Check if payment is voided
  bool get isVoided => status == AppStatus.paymentVoided;

  /// Get amount in major units (for display)
  double get amountPayment => amountPaymentMinor / 100.0;
  double get amountBase => amountBaseMinor / 100.0;
  double get amountLoan => amountLoanMinor / 100.0;
  double get fxProfitBase => fxProfitBaseMinor / 100.0;
  double get unapplied => unappliedMinor / 100.0;

  // === BACKWARD COMPATIBILITY GETTERS ===

  /// @deprecated Use amountPayment instead
  double get amount => amountPayment;

  /// @deprecated Customer ID is now derived from loan
  String? get customerId => _customerId;

  /// @deprecated Use createdAt for payment date
  DateTime get paymentDate => createdAt;

  /// @deprecated Receipt number
  String? get receiptNumber => _receiptNumber;

  /// @deprecated Use voidReasonKey instead
  String? get voidReason => voidReasonKey;

  /// @deprecated Use fxProfitBase
  double? get exchangeProfit => fxProfitBaseMinor != 0 ? fxProfitBase : null;

  /// @deprecated Use rateValueUsed
  double? get exchangeRateApplied => rateValueUsed;

  /// @deprecated Declared type - no longer used
  String get declaredType => _declaredType ?? 'MIXED';

  /// @deprecated Notes field
  String? get notes => _notes;

  /// Create from database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id'] as String,
      loanId: map['loan_id'] as String,
      amountPaymentMinor: map['amount_payment_minor'] as int,
      amountBaseMinor: map['amount_base_minor'] as int,
      amountLoanMinor: map['amount_loan_minor'] as int,
      paymentCurrency: map['payment_currency'] as String,
      loanCurrency: map['loan_currency'] as String,
      baseCurrency: map['base_currency'] as String,
      rateId: map['rate_id'] as String?,
      rateTypeUsed: map['rate_type_used'] as String?,
      rateValueUsed: (map['rate_value_used'] as num?)?.toDouble(),
      rateDateUsed: map['rate_date_used'] as String?,
      referenceRateValue: (map['reference_rate_value'] as num?)?.toDouble(),
      fxProfitBaseMinor: map['fx_profit_base_minor'] as int? ?? 0,
      fxStatus: map['fx_status'] as String? ?? 'NONE',
      status: map['status'] as String? ?? AppStatus.paymentValid,
      voidReasonKey: map['void_reason_key'] as String?,
      voidedAt: map['voided_at'] != null
          ? DateTime.parse(map['voided_at'] as String)
          : null,
      idempotencyKey: map['idempotency_key'] as String,
      payloadHash: map['payload_hash'] as String,
      legacyMigratedAt: map['legacy_migrated_at'] != null
          ? DateTime.parse(map['legacy_migrated_at'] as String)
          : null,
      legacyAmbiguous: (map['legacy_ambiguous'] as int? ?? 0) == 1,
      unappliedMinor: map['unapplied_minor'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      // Try to read deprecated fields from joined queries
      customerId: map['customer_id'] as String?,
      receiptNumber: map['receipt_number']?.toString(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'loan_id': loanId,
      'customer_id': _customerId, // CRITICAL: Required NOT NULL
      'amount_payment_minor': amountPaymentMinor,
      'amount_base_minor': amountBaseMinor,
      'amount_loan_minor': amountLoanMinor,
      'payment_currency': paymentCurrency,
      'loan_currency': loanCurrency,
      'base_currency': baseCurrency,
      'rate_id': rateId,
      'rate_type_used': rateTypeUsed,
      'rate_value_used': rateValueUsed,
      'rate_date_used': rateDateUsed,
      'reference_rate_value': referenceRateValue,
      'fx_profit_base_minor': fxProfitBaseMinor,
      'fx_status': fxStatus,
      'status': status,
      'void_reason_key': voidReasonKey,
      'voided_at': voidedAt?.toIso8601String(),
      'idempotency_key': idempotencyKey,
      'payload_hash': payloadHash,
      'declared_type': _declaredType ?? 'MIXED', // Required with DEFAULT
      'receipt_number': _receiptNumber, // CRITICAL: Required NOT NULL
      'notes': _notes,
      'legacy_migrated_at': legacyMigratedAt?.toIso8601String(),
      'legacy_ambiguous': legacyAmbiguous ? 1 : 0,
      'unapplied_minor': unappliedMinor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  Payment copyWith({
    String? status,
    String? voidReasonKey,
    DateTime? voidedAt,
    DateTime? updatedAt,
    int? unappliedMinor,
    int? fxProfitBaseMinor,
    String? fxStatus,
    String? receiptNumber,
  }) {
    return Payment(
      paymentId: paymentId,
      loanId: loanId,
      amountPaymentMinor: amountPaymentMinor,
      amountBaseMinor: amountBaseMinor,
      amountLoanMinor: amountLoanMinor,
      paymentCurrency: paymentCurrency,
      loanCurrency: loanCurrency,
      baseCurrency: baseCurrency,
      rateId: rateId,
      rateTypeUsed: rateTypeUsed,
      rateValueUsed: rateValueUsed,
      rateDateUsed: rateDateUsed,
      referenceRateValue: referenceRateValue,
      fxProfitBaseMinor: fxProfitBaseMinor ?? this.fxProfitBaseMinor,
      fxStatus: fxStatus ?? this.fxStatus,
      status: status ?? this.status,
      voidReasonKey: voidReasonKey ?? this.voidReasonKey,
      voidedAt: voidedAt ?? this.voidedAt,
      idempotencyKey: idempotencyKey,
      payloadHash: payloadHash,
      legacyMigratedAt: legacyMigratedAt,
      legacyAmbiguous: legacyAmbiguous,
      unappliedMinor: unappliedMinor ?? this.unappliedMinor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      customerId: _customerId,
      receiptNumber: receiptNumber ?? _receiptNumber,
      declaredType: _declaredType,
      notes: _notes,
    );
  }

  @override
  List<Object?> get props => [
    paymentId,
    loanId,
    amountPaymentMinor,
    amountBaseMinor,
    amountLoanMinor,
    paymentCurrency,
    loanCurrency,
    baseCurrency,
    rateId,
    rateTypeUsed,
    rateValueUsed,
    rateDateUsed,
    referenceRateValue,
    fxProfitBaseMinor,
    fxStatus,
    status,
    voidReasonKey,
    voidedAt,
    idempotencyKey,
    payloadHash,
    legacyMigratedAt,
    legacyAmbiguous,
    unappliedMinor,
    createdAt,
    updatedAt,
  ];
}
