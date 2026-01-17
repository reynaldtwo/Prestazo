import 'package:equatable/equatable.dart';

/// Payment Plan model - Preconfigured loan plan
class PaymentPlan extends Equatable {
  /// Crea un [PaymentPlan] que define las condiciones de un tipo de préstamo.
  const PaymentPlan({
    required this.planId,
    required this.name,
    required this.paymentFrequencyId,
    required this.paymentFrequencyDays,
    required this.termValue,
    required this.termUnit,
    required this.installmentsTotal,
    required this.monthlyInterestRate,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.allowCurrencyChange = false,
    this.minAmount,
    this.maxAmount,
    this.distributeCapitalAndInterest = false,
    this.periodStartsOnDisbursement = true,
    this.applicableCategoryIds,
    this.isActive = true,
  });

  /// Create from database map
  factory PaymentPlan.fromMap(Map<String, dynamic> map) {
    return PaymentPlan(
      planId: map['plan_id'] as String,
      name: map['name'] as String,
      paymentFrequencyId: map['payment_frequency_id'] as String,
      paymentFrequencyDays: map['payment_frequency_days'] as int,
      termValue: map['term_value'] as int? ?? 0,
      termUnit: map['term_unit'] as String? ?? 'Months',
      installmentsTotal: map['installments_total'] as int,
      monthlyInterestRate: (map['monthly_interest_rate'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      allowCurrencyChange: (map['allow_currency_change'] as int) == 1,
      minAmount: (map['min_amount'] as num?)?.toDouble(),
      maxAmount: (map['max_amount'] as num?)?.toDouble(),
      distributeCapitalAndInterest:
          (map['distribute_capital_and_interest'] as int) == 1,
      periodStartsOnDisbursement:
          (map['period_starts_on_disbursement'] as int) == 1,
      applicableCategoryIds: map['applicable_category_ids'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Unique identifier
  /// Identificador único del plan.
  final String planId;

  /// Nombre del plan (ej: 'Plan Comercial').
  final String name;

  /// Referencia a la frecuencia de pago.
  final String paymentFrequencyId;

  /// Cantidad de días del intervalo de pago extraído de la frecuencia.
  final int paymentFrequencyDays;

  /// Valor del plazo (ej: 12).
  final int termValue;

  /// Unidad del plazo (ej: 'Months').
  final String termUnit;

  /// Número total de cuotas del plan.
  final int installmentsTotal;

  /// Tasa de interés mensual (%).
  final double monthlyInterestRate;

  /// Moneda base para este plan.
  final String currencyCode;

  /// Permite cambiar la moneda al crear un préstamo basado en este plan.
  final bool allowCurrencyChange;

  /// Monto mínimo del préstamo para este plan.
  final double? minAmount;

  /// Monto máximo del préstamo para este plan.
  final double? maxAmount;

  /// Indica si se debe distribuir capital e interés en las cuotas.
  final bool distributeCapitalAndInterest;

  /// Indica si el periodo inicia en la fecha de desembolso.
  final bool periodStartsOnDisbursement;

  /// IDs de categorías de clientes aplicables separated por comas (nulo = todas).
  final String? applicableCategoryIds;

  /// Indica si el plan está activo.
  final bool isActive;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'plan_id': planId,
      'name': name,
      'payment_frequency_id': paymentFrequencyId,
      'payment_frequency_days': paymentFrequencyDays,
      'term_value': termValue,
      'term_unit': termUnit,
      'installments_total': installmentsTotal,
      'monthly_interest_rate': monthlyInterestRate,
      'currency_code': currencyCode,
      'allow_currency_change': allowCurrencyChange ? 1 : 0,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'distribute_capital_and_interest': distributeCapitalAndInterest ? 1 : 0,
      'period_starts_on_disbursement': periodStartsOnDisbursement ? 1 : 0,
      'applicable_category_ids': applicableCategoryIds,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  PaymentPlan copyWith({
    String? name,
    String? paymentFrequencyId,
    int? paymentFrequencyDays,
    int? termValue,
    String? termUnit,
    int? installmentsTotal,
    double? monthlyInterestRate,
    String? currencyCode,
    bool? allowCurrencyChange,
    double? minAmount,
    double? maxAmount,
    bool? distributeCapitalAndInterest,
    bool? periodStartsOnDisbursement,
    String? applicableCategoryIds,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return PaymentPlan(
      planId: planId,
      name: name ?? this.name,
      paymentFrequencyId: paymentFrequencyId ?? this.paymentFrequencyId,
      paymentFrequencyDays: paymentFrequencyDays ?? this.paymentFrequencyDays,
      termValue: termValue ?? this.termValue,
      termUnit: termUnit ?? this.termUnit,
      installmentsTotal: installmentsTotal ?? this.installmentsTotal,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
      currencyCode: currencyCode ?? this.currencyCode,
      allowCurrencyChange: allowCurrencyChange ?? this.allowCurrencyChange,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      distributeCapitalAndInterest:
          distributeCapitalAndInterest ?? this.distributeCapitalAndInterest,
      periodStartsOnDisbursement:
          periodStartsOnDisbursement ?? this.periodStartsOnDisbursement,
      applicableCategoryIds:
          applicableCategoryIds ?? this.applicableCategoryIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if plan applies to a specific category
  bool appliesToCategory(String? categoryId) {
    if (applicableCategoryIds == null || applicableCategoryIds!.isEmpty) {
      return true; // No restriction, applies to all
    }
    if (categoryId == null) {
      return false; // Plan has restrictions but customer has no category
    }
    final ids = applicableCategoryIds!.split(',').map((e) => e.trim()).toList();
    return ids.contains(categoryId);
  }

  @override
  List<Object?> get props => [
    planId,
    name,
    paymentFrequencyId,
    paymentFrequencyDays,
    termValue,
    termUnit,
    installmentsTotal,
    monthlyInterestRate,
    currencyCode,
    allowCurrencyChange,
    minAmount,
    maxAmount,
    distributeCapitalAndInterest,
    periodStartsOnDisbursement,
    applicableCategoryIds,
    isActive,
    createdAt,
    updatedAt,
  ];
}
