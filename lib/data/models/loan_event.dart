import 'package:equatable/equatable.dart';

/// LoanEvent model - Audit trail for loan events
class LoanEvent extends Equatable {
  final String loanEventId;
  final String loanId;
  final String eventType;
  final String? relatedBillingCycleId;
  final String? relatedPaymentId;
  final double? amount;
  final String? oldValue;
  final String? newValue;
  final String? notes;
  final DateTime createdAt;

  const LoanEvent({
    required this.loanEventId,
    required this.loanId,
    required this.eventType,
    this.relatedBillingCycleId,
    this.relatedPaymentId,
    this.amount,
    this.oldValue,
    this.newValue,
    this.notes,
    required this.createdAt,
  });

  /// Create from database map
  factory LoanEvent.fromMap(Map<String, dynamic> map) {
    return LoanEvent(
      loanEventId: map['loan_event_id'] as String,
      loanId: map['loan_id'] as String,
      eventType: map['event_type'] as String,
      relatedBillingCycleId: map['related_billing_cycle_id'] as String?,
      relatedPaymentId: map['related_payment_id'] as String?,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      oldValue: map['old_value'] as String?,
      newValue: map['new_value'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'loan_event_id': loanEventId,
      'loan_id': loanId,
      'event_type': eventType,
      'related_billing_cycle_id': relatedBillingCycleId,
      'related_payment_id': relatedPaymentId,
      'amount': amount,
      'old_value': oldValue,
      'new_value': newValue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        loanEventId,
        loanId,
        eventType,
        relatedBillingCycleId,
        relatedPaymentId,
        amount,
        oldValue,
        newValue,
        notes,
        createdAt,
      ];
}

/// Event type constants
class LoanEventType {
  LoanEventType._();
  
  static const String capitalizationApplied = 'CAPITALIZATION_APPLIED';
  static const String statusChanged = 'STATUS_CHANGED';
  static const String paymentRecorded = 'PAYMENT_RECORDED';
  static const String paymentVoided = 'PAYMENT_VOIDED';
  static const String loanCreated = 'LOAN_CREATED';
  static const String loanClosed = 'LOAN_CLOSED';
}
