import 'package:equatable/equatable.dart';

/// PaymentAllocation model - Traces how payment was applied (V25 schema)
/// Includes backward-compatible fields for smooth migration
class PaymentAllocation extends Equatable {
  final String allocationId;
  final String paymentId;
  final String? billingCycleId; // NULL for principal-only allocations
  final String allocationType; // INTEREST, PRINCIPAL, FEE, PENALTY
  final int amountLoanMinor; // Amount in loan currency minor units
  final DateTime createdAt;

  // Deprecated field for backward compatibility
  final String? _loanId;

  const PaymentAllocation({
    required this.allocationId,
    required this.paymentId,
    this.billingCycleId,
    required this.allocationType,
    required this.amountLoanMinor,
    required this.createdAt,
    // Deprecated
    String? loanId,
  }) : _loanId = loanId;

  /// Check if allocation is for interest
  bool get isInterest => allocationType == 'INTEREST';

  /// Check if allocation is for principal
  bool get isPrincipal => allocationType == 'PRINCIPAL';

  /// Get amount in major units (for display)
  double get amount => amountLoanMinor / 100.0;

  /// @deprecated Loan ID is now derived via payment FK
  String? get loanId => _loanId;

  /// Create from database map
  factory PaymentAllocation.fromMap(Map<String, dynamic> map) {
    return PaymentAllocation(
      allocationId: map['allocation_id'] as String,
      paymentId: map['payment_id'] as String,
      billingCycleId: map['billing_cycle_id'] as String?,
      allocationType: map['allocation_type'] as String,
      amountLoanMinor: map['amount_loan_minor'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      // Try to read from joined queries
      loanId: map['loan_id'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'allocation_id': allocationId,
      'payment_id': paymentId,
      'billing_cycle_id': billingCycleId,
      'allocation_type': allocationType,
      'amount_loan_minor': amountLoanMinor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    allocationId,
    paymentId,
    billingCycleId,
    allocationType,
    amountLoanMinor,
    createdAt,
  ];
}
