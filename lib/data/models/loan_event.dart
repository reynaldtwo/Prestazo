import 'package:equatable/equatable.dart';

/// LoanEvent model - Audit trail for loan events
class LoanEvent extends Equatable {
  /// Crea un [LoanEvent] para registrar un hito en la vida de un préstamo.
  const LoanEvent({
    required this.loanEventId,
    required this.loanId,
    required this.eventType,
    required this.createdAt,
    this.relatedBillingCycleId,
    this.relatedPaymentId,
    this.amount,
    this.oldValue,
    this.newValue,
    this.notes,
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

  /// Identificador único del evento.
  final String loanEventId;

  /// Identificador del préstamo asociado.
  final String loanId;

  /// Tipo de evento ocurrido (ej: 'PAYMENT_RECORDED').
  final String eventType;

  /// Identificador del ciclo de facturación relacionado (opcional).
  final String? relatedBillingCycleId;

  /// Identificador del pago relacionado (opcional).
  final String? relatedPaymentId;

  /// Monto monetario asociado al evento (opcional).
  final double? amount;

  /// Valor anterior antes del cambio (opcional).
  final String? oldValue;

  /// Valor nuevo después del cambio (opcional).
  final String? newValue;

  /// Notas adicionales descriptivas.
  final String? notes;

  /// Fecha y hora en que ocurrió el evento.
  final DateTime createdAt;

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

  /// Interés capitalizado aplicado.
  static const String capitalizationApplied = 'CAPITALIZATION_APPLIED';

  /// Cambio de estado del préstamo.
  static const String statusChanged = 'STATUS_CHANGED';

  /// Registro de un nuevo pago.
  static const String paymentRecorded = 'PAYMENT_RECORDED';

  /// Anulación de un pago.
  static const String paymentVoided = 'PAYMENT_VOIDED';

  /// Creación del préstamo.
  static const String loanCreated = 'LOAN_CREATED';

  /// Cierre definitivo del préstamo.
  static const String loanClosed = 'LOAN_CLOSED';
}
