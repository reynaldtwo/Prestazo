import 'package:equatable/equatable.dart';

/// PaymentFxLeg model - FX transaction leg for multi-currency payments
class PaymentFxLeg extends Equatable {
  /// Crea un [PaymentFxLeg] para registrar una etapa de una transacción multimoneda.
  const PaymentFxLeg({
    required this.legId,
    required this.paymentId,
    required this.stepOrder,
    required this.baseCurrency,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rateTypeUsed,
    required this.rateValueUsed,
    required this.amountFromMinor,
    required this.amountToCustomerMinor,
    required this.createdAt,
    this.referenceRateType,
    this.referenceRateValue,
    this.amountToReferenceMinor,
    this.fxProfitBaseMinor,
  });

  /// Create from database map
  factory PaymentFxLeg.fromMap(Map<String, dynamic> map) {
    return PaymentFxLeg(
      legId: map['leg_id'] as String,
      paymentId: map['payment_id'] as String,
      stepOrder: map['step_order'] as int,
      baseCurrency: map['base_currency'] as String,
      fromCurrency: map['from_currency'] as String,
      toCurrency: map['to_currency'] as String,
      rateTypeUsed: map['rate_type_used'] as String,
      rateValueUsed: (map['rate_value_used'] as num).toDouble(),
      referenceRateType: map['reference_rate_type'] as String?,
      referenceRateValue: (map['reference_rate_value'] as num?)?.toDouble(),
      amountFromMinor: map['amount_from_minor'] as int,
      amountToCustomerMinor: map['amount_to_customer_minor'] as int,
      amountToReferenceMinor: map['amount_to_reference_minor'] as int?,
      fxProfitBaseMinor: map['fx_profit_base_minor'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Identificador único de la etapa.
  final String legId;

  /// Identificador del pago asociado.
  final String paymentId;

  /// Orden de la etapa en la transacción (1 o 2).
  final int stepOrder;

  /// Código de la moneda base.
  final String baseCurrency;

  /// Código de la moneda de origen.
  final String fromCurrency;

  /// Código de la moneda de destino.
  final String toCurrency;

  /// Tipo de tasa utilizada ('BUY', 'SELL', 'MID', 'MANUAL').
  final String rateTypeUsed;

  /// Valor nominal de la tasa de cambio utilizada.
  final double rateValueUsed;

  /// Tipo de tasa de referencia (opcional).
  final String? referenceRateType;

  /// Valor nominal de la tasa de referencia (opcional).
  final double? referenceRateValue;

  /// Monto de origen en unidades menores.
  final int amountFromMinor;

  /// Monto destinado al cliente en unidades menores.
  final int amountToCustomerMinor;

  /// Monto equivalente usando la tasa de referencia (opcional).
  final int? amountToReferenceMinor;

  /// Ganancia por diferencial cambiario en moneda base (opcional).
  final int? fxProfitBaseMinor;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Get amounts in major units (for display)
  /// Obtiene el monto de origen en unidades principales.
  double get amountFrom => amountFromMinor / 100.0;

  /// Obtiene el monto destinado al cliente en unidades principales.
  double get amountToCustomer => amountToCustomerMinor / 100.0;

  /// Obtiene el monto de referencia en unidades principales.
  double? get amountToReference =>
      amountToReferenceMinor != null ? amountToReferenceMinor! / 100.0 : null;

  /// Obtiene la ganancia cambiaria en unidades principales.
  double? get fxProfitBase =>
      fxProfitBaseMinor != null ? fxProfitBaseMinor! / 100.0 : null;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'leg_id': legId,
      'payment_id': paymentId,
      'step_order': stepOrder,
      'base_currency': baseCurrency,
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'rate_type_used': rateTypeUsed,
      'rate_value_used': rateValueUsed,
      'reference_rate_type': referenceRateType,
      'reference_rate_value': referenceRateValue,
      'amount_from_minor': amountFromMinor,
      'amount_to_customer_minor': amountToCustomerMinor,
      'amount_to_reference_minor': amountToReferenceMinor,
      'fx_profit_base_minor': fxProfitBaseMinor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    legId,
    paymentId,
    stepOrder,
    baseCurrency,
    fromCurrency,
    toCurrency,
    rateTypeUsed,
    rateValueUsed,
    referenceRateType,
    referenceRateValue,
    amountFromMinor,
    amountToCustomerMinor,
    amountToReferenceMinor,
    fxProfitBaseMinor,
    createdAt,
  ];
}
