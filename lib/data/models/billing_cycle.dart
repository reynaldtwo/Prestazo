import 'package:equatable/equatable.dart';
import 'package:prestamos_app/core/constants/app_status.dart';

/// BillingCycle model - Interest cycle per loan
class BillingCycle extends Equatable {
  /// Crea un [BillingCycle] que representa un periodo de cobro de intereses.
  const BillingCycle({
    required this.billingCycleId,
    required this.loanId,
    required this.cycleNumber,
    required this.frequency,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.dueDate,
    required this.interestExpected,
    required this.interestPending,
    required this.createdAt,
    required this.updatedAt,
    this.interestPaid = 0,
    this.status = AppStatus.cyclePending,
    this.closedAt,
    this.isCapitalized = false,
    this.capitalizedAmount = 0,
    this.capitalizedAt,
    this.installmentExpected,
    this.installmentPaid,
    this.installmentPending,
    this.principalPortion,
  });

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

  /// Identificador único del ciclo de facturación.
  final String billingCycleId;

  /// Identificador del préstamo asociado.
  final String loanId;

  /// Número correlativo del ciclo dentro del préstamo.
  final int cycleNumber;

  /// Frecuencia del ciclo (ej: 'MONTHLY').
  final String frequency;

  /// Fecha de inicio del periodo que cubre este ciclo.
  final DateTime periodStartDate;

  /// Fecha de fin del periodo que cubre este ciclo.
  final DateTime periodEndDate;

  /// Fecha de vencimiento para el pago de este ciclo.
  final DateTime dueDate;

  /// Monto de interés esperado para este ciclo.
  final double interestExpected;

  /// Monto de interés pagado hasta ahora.
  final double interestPaid;

  /// Monto de interés pendiente de pago.
  final double interestPending;

  /// Estado actual del ciclo (PENDING, PAID, OVERDUE, etc).
  final String status;

  /// Fecha en la que el ciclo fue cerrado.
  final DateTime? closedAt;

  /// Indica si el interés de este ciclo fue capitalizado.
  final bool isCapitalized;

  /// Monto total capitalizado en este ciclo.
  final double capitalizedAmount;

  /// Fecha en la que ocurrió la capitalización.
  final DateTime? capitalizedAt;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  // V29: Installment fields for plan distribution
  /// Cuota total esperada (Capital + Interés) (V29).
  final double? installmentExpected;

  /// Cuota total pagada (V29).
  final double? installmentPaid;

  /// Cuota total pendiente (V29).
  final double? installmentPending;

  /// Porción del capital incluida en la cuota (V29).
  final double? principalPortion;

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
