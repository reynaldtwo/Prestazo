import 'package:equatable/equatable.dart';
import '../../core/constants/app_status.dart';

/// Payment model - Payment record
class Payment extends Equatable {
  final String paymentId;
  final String loanId;
  final String customerId;
  final DateTime paymentDate;
  final double amount;
  final String declaredType;
  final String receiptNumber;
  final String status;
  final String? voidReason;
  final DateTime? voidedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.paymentId,
    required this.loanId,
    required this.customerId,
    required this.paymentDate,
    required this.amount,
    this.declaredType = 'MIXED',
    required this.receiptNumber,
    this.status = AppStatus.paymentValid,
    this.voidReason,
    this.voidedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if payment is valid
  bool get isValid => status == AppStatus.paymentValid;

  /// Check if payment is voided
  bool get isVoided => status == AppStatus.paymentVoided;

  /// Create from database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id'] as String,
      loanId: map['loan_id'] as String,
      customerId: map['customer_id'] as String,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      amount: (map['amount'] as num).toDouble(),
      declaredType: map['declared_type'] as String? ?? 'MIXED',
      receiptNumber: map['receipt_number']?.toString() ?? '1',
      status: map['status'] as String? ?? AppStatus.paymentValid,
      voidReason: map['void_reason'] as String?,
      voidedAt: map['voided_at'] != null
          ? DateTime.parse(map['voided_at'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'loan_id': loanId,
      'customer_id': customerId,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'declared_type': declaredType,
      'receipt_number': receiptNumber,
      'status': status,
      'void_reason': voidReason,
      'voided_at': voidedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications (primarily for voiding)
  Payment copyWith({
    String? status,
    String? voidReason,
    DateTime? voidedAt,
    DateTime? updatedAt,
    String? receiptNumber,
  }) {
    return Payment(
      paymentId: paymentId,
      loanId: loanId,
      customerId: customerId,
      paymentDate: paymentDate,
      amount: amount,
      declaredType: declaredType,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      status: status ?? this.status,
      voidReason: voidReason ?? this.voidReason,
      voidedAt: voidedAt ?? this.voidedAt,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    paymentId,
    loanId,
    customerId,
    paymentDate,
    amount,
    declaredType,
    receiptNumber,
    status,
    voidReason,
    voidedAt,
    notes,
    createdAt,
    updatedAt,
  ];
}
