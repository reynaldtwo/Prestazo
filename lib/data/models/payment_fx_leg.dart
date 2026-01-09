import 'package:equatable/equatable.dart';

/// PaymentFxLeg model - FX transaction leg for multi-currency payments
class PaymentFxLeg extends Equatable {
  final String legId;
  final String paymentId;
  final int stepOrder; // 1 or 2
  final String baseCurrency;
  final String fromCurrency;
  final String toCurrency;
  final String rateTypeUsed; // BUY, SELL, MID, MANUAL
  final double rateValueUsed;
  final String? referenceRateType; // MID, PROVIDER_MID, MANUAL_REF
  final double? referenceRateValue;
  final int amountFromMinor;
  final int amountToCustomerMinor;
  final int? amountToReferenceMinor;
  final int? fxProfitBaseMinor;
  final DateTime createdAt;

  const PaymentFxLeg({
    required this.legId,
    required this.paymentId,
    required this.stepOrder,
    required this.baseCurrency,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rateTypeUsed,
    required this.rateValueUsed,
    this.referenceRateType,
    this.referenceRateValue,
    required this.amountFromMinor,
    required this.amountToCustomerMinor,
    this.amountToReferenceMinor,
    this.fxProfitBaseMinor,
    required this.createdAt,
  });

  /// Get amounts in major units (for display)
  double get amountFrom => amountFromMinor / 100.0;
  double get amountToCustomer => amountToCustomerMinor / 100.0;
  double? get amountToReference =>
      amountToReferenceMinor != null ? amountToReferenceMinor! / 100.0 : null;
  double? get fxProfitBase =>
      fxProfitBaseMinor != null ? fxProfitBaseMinor! / 100.0 : null;

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
