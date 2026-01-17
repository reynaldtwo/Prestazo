import 'package:equatable/equatable.dart';

/// PaymentAllocation model - Traces how payment was applied (V25 schema)
/// Includes backward-compatible fields for smooth migration
class PaymentAllocation extends Equatable {
  /// Crea un [PaymentAllocation] que detalla cómo se aplicó parte de un pago.
  const PaymentAllocation({
    required this.allocationId,
    required this.paymentId,
    required this.allocationType,
    required this.amountLoanMinor,
    required this.createdAt,
    this.billingCycleId,
    // Deprecated
    String? loanId,
  }) : _loanId = loanId;

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

  /// Identificador único de la asignación.
  final String allocationId;

  /// Identificador del pago al que pertenece esta asignación.
  final String paymentId;

  /// Identificador del ciclo de facturación (nulo si es abono directo a capital).
  final String? billingCycleId;

  /// Tipo de asignación ('INTEREST', 'PRINCIPAL', 'FEE', 'PENALTY').
  final String allocationType;

  /// Monto asignado en unidades menores (centavos) de la moneda del préstamo.
  final int amountLoanMinor;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  // Deprecated field for backward compatibility
  final String? _loanId;

  /// Check if allocation is for interest
  bool get isInterest => allocationType == 'INTEREST';

  /// Check if allocation is for principal
  bool get isPrincipal => allocationType == 'PRINCIPAL';

  /// Get amount in major units (for display)
  /// Obtiene el monto asignado en unidades principales (ej: 10.50).
  double get amount => amountLoanMinor / 100.0;

  /// @deprecated Loan ID is now derived via payment FK
  /// @deprecated El ID del préstamo ahora se deriva mediante la clave foránea del pago.
  String? get loanId => _loanId;

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
