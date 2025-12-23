import 'package:equatable/equatable.dart';

/// PaymentAllocation model - Traces how payment was applied
class PaymentAllocation extends Equatable {
  final String allocationId;
  final String paymentId;
  final String loanId;
  final String allocationType;
  final double amount;
  final String? billingCycleId;
  final DateTime createdAt;

  const PaymentAllocation({
    required this.allocationId,
    required this.paymentId,
    required this.loanId,
    required this.allocationType,
    required this.amount,
    this.billingCycleId,
    required this.createdAt,
  });

  /// Check if allocation is for interest
  bool get isInterest => allocationType == 'INTEREST';

  /// Check if allocation is for principal
  bool get isPrincipal => allocationType == 'PRINCIPAL';

  /// Create from database map
  factory PaymentAllocation.fromMap(Map<String, dynamic> map) {
    return PaymentAllocation(
      allocationId: map['allocation_id'] as String,
      paymentId: map['payment_id'] as String,
      loanId: map['loan_id'] as String,
      allocationType: map['allocation_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      billingCycleId: map['billing_cycle_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'allocation_id': allocationId,
      'payment_id': paymentId,
      'loan_id': loanId,
      'allocation_type': allocationType,
      'amount': amount,
      'billing_cycle_id': billingCycleId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        allocationId,
        paymentId,
        loanId,
        allocationType,
        amount,
        billingCycleId,
        createdAt,
      ];
}
