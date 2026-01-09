import 'package:equatable/equatable.dart';

/// ClientCreditLedger model - Tracks overpayments and void reversals
class ClientCreditLedger extends Equatable {
  final String entryId;
  final String customerId;
  final String referencePaymentId;
  final String transactionType; // OVERPAYMENT, VOID_REVERSAL, USAGE
  final int amountMinor; // Positive for credit, negative for debit
  final DateTime createdAt;

  const ClientCreditLedger({
    required this.entryId,
    required this.customerId,
    required this.referencePaymentId,
    required this.transactionType,
    required this.amountMinor,
    required this.createdAt,
  });

  /// Get amount in major units (for display)
  double get amount => amountMinor / 100.0;

  /// Check if this is a credit (positive)
  bool get isCredit => amountMinor > 0;

  /// Check if this is a debit (negative)
  bool get isDebit => amountMinor < 0;

  /// Create from database map
  factory ClientCreditLedger.fromMap(Map<String, dynamic> map) {
    return ClientCreditLedger(
      entryId: map['entry_id'] as String,
      customerId: map['customer_id'] as String,
      referencePaymentId: map['reference_payment_id'] as String,
      transactionType: map['transaction_type'] as String,
      amountMinor: map['amount_minor'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'entry_id': entryId,
      'customer_id': customerId,
      'reference_payment_id': referencePaymentId,
      'transaction_type': transactionType,
      'amount_minor': amountMinor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    entryId,
    customerId,
    referencePaymentId,
    transactionType,
    amountMinor,
    createdAt,
  ];
}
