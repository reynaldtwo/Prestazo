import 'package:equatable/equatable.dart';
import '../../core/constants/app_status.dart';

/// BillingCycle model - Interest cycle per loan
class BillingCycle extends Equatable {
  final String billingCycleId;
  final String loanId;
  final int cycleNumber;
  final String frequency;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final DateTime dueDate;
  final double interestExpected;
  final double interestPaid;
  final double interestPending;
  final String status;
  final DateTime? closedAt;
  final bool isCapitalized;
  final double capitalizedAmount;
  final DateTime? capitalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // V29: Installment fields for plan distribution
  final double? installmentExpected;
  final double? installmentPaid;
  final double? installmentPending;
  final double? principalPortion;

  const BillingCycle({
    required this.billingCycleId,
    required this.loanId,
    required this.cycleNumber,
    required this.frequency,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.dueDate,
    required this.interestExpected,
    this.interestPaid = 0,
    required this.interestPending,
    this.status = AppStatus.cyclePending,
    this.closedAt,
    this.isCapitalized = false,
    this.capitalizedAmount = 0,
    this.capitalizedAt,
    required this.createdAt,
    required this.updatedAt,
    this.installmentExpected,
    this.installmentPaid,
    this.installmentPending,
    this.principalPortion,
  });

  /// Check if cycle is overdue
  bool get isOverdue =>
      status == AppStatus.cycleOverdue ||
      (status == AppStatus.cyclePending && dueDate.isBefore(DateTime.now()));

  /// Check if cycle is fully paid
  bool get isPaid => status == AppStatus.cyclePaid || interestPending <= 0;

  /// Check if cycle is closed
  bool get isClosed => status == AppStatus.cycleClosed; // Mapped to CLOSED

  /// Days until due (negative if overdue)
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  /// Days overdue (0 if not overdue)
  int get daysOverdue => daysUntilDue < 0 ? daysUntilDue.abs() : 0;

  /// Create from database map
  factory BillingCycle.fromMap(Map<String, dynamic> map) {
    return BillingCycle(
      billingCycleId: map['billing_cycle_id'] as String,
      loanId: map['loan_id'] as String,
      cycleNumber: map['cycle_number'] as int,
      frequency: map['frequency'] as String,
      periodStartDate: DateTime.parse(map['period_start_date'] as String),
      periodEndDate: DateTime.parse(map['period_end_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      interestExpected: (map['interest_expected'] as num).toDouble(),
      interestPaid: (map['interest_paid'] as num? ?? 0).toDouble(),
      interestPending: (map['interest_pending'] as num).toDouble(),
      status: map['status'] as String? ?? AppStatus.cyclePending,
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String)
          : null,
      isCapitalized: (map['is_capitalized'] as int? ?? 0) == 1,
      capitalizedAmount: (map['capitalized_amount'] as num? ?? 0).toDouble(),
      capitalizedAt: map['capitalized_at'] != null
          ? DateTime.parse(map['capitalized_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      installmentExpected: (map['installment_expected'] as num?)?.toDouble(),
      installmentPaid: (map['installment_paid'] as num?)?.toDouble(),
      installmentPending: (map['installment_pending'] as num?)?.toDouble(),
      principalPortion: (map['principal_portion'] as num?)?.toDouble(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'billing_cycle_id': billingCycleId,
      'loan_id': loanId,
      'cycle_number': cycleNumber,
      'frequency': frequency,
      'period_start_date': periodStartDate.toIso8601String().split('T')[0],
      'period_end_date': periodEndDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'interest_expected': interestExpected,
      'interest_paid': interestPaid,
      'interest_pending': interestPending,
      'status': status,
      'closed_at': closedAt?.toIso8601String(),
      'is_capitalized': isCapitalized ? 1 : 0,
      'capitalized_amount': capitalizedAmount,
      'capitalized_at': capitalizedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'installment_expected': installmentExpected,
      'installment_paid': installmentPaid,
      'installment_pending': installmentPending,
      'principal_portion': principalPortion,
    };
  }

  /// Copy with modifications
  BillingCycle copyWith({
    double? interestPaid,
    double? interestPending,
    String? status,
    DateTime? closedAt,
    bool? isCapitalized,
    double? capitalizedAmount,
    DateTime? capitalizedAt,
    DateTime? updatedAt,
    double? installmentExpected,
    double? installmentPaid,
    double? installmentPending,
    double? principalPortion,
  }) {
    return BillingCycle(
      billingCycleId: billingCycleId,
      loanId: loanId,
      cycleNumber: cycleNumber,
      frequency: frequency,
      periodStartDate: periodStartDate,
      periodEndDate: periodEndDate,
      dueDate: dueDate,
      interestExpected: interestExpected,
      interestPaid: interestPaid ?? this.interestPaid,
      interestPending: interestPending ?? this.interestPending,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      isCapitalized: isCapitalized ?? this.isCapitalized,
      capitalizedAmount: capitalizedAmount ?? this.capitalizedAmount,
      capitalizedAt: capitalizedAt ?? this.capitalizedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      installmentExpected: installmentExpected ?? this.installmentExpected,
      installmentPaid: installmentPaid ?? this.installmentPaid,
      installmentPending: installmentPending ?? this.installmentPending,
      principalPortion: principalPortion ?? this.principalPortion,
    );
  }

  @override
  List<Object?> get props => [
    billingCycleId,
    loanId,
    cycleNumber,
    frequency,
    periodStartDate,
    periodEndDate,
    dueDate,
    interestExpected,
    interestPaid,
    interestPending,
    status,
    closedAt,
    isCapitalized,
    capitalizedAmount,
    capitalizedAt,
    createdAt,
    updatedAt,
    installmentExpected,
    installmentPaid,
    installmentPending,
    principalPortion,
  ];
}
