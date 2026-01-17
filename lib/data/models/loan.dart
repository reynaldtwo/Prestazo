import 'package:equatable/equatable.dart';
import 'package:prestamos_app/core/constants/app_status.dart';

/// Loan model - Loan granted to a customer
class Loan extends Equatable {
  /// Crea un [Loan] que representa un préstamo otorgado.
  const Loan({
    required this.loanId,
    required this.customerId,
    required this.principalOriginal,
    required this.principalBalance,
    required this.monthlyInterestRate,
    required this.disbursementDate,
    required this.createdAt,
    required this.updatedAt,
    this.rateUnit = 'MONTHLY',
    this.billingFrequency = 'MONTHLY',
    this.endDate,
    this.status = AppStatus.loanActive,
    this.closedAt,
    this.notes,
    this.loanNumber,
    this.currencyCode = 'NIO',
    this.appliedExchangeRate,
    this.paymentFrequencyDays,
    this.planId,
    this.planInstallmentsTotal,
    this.distributeCapitalAndInterest,
    this.endDateCalculated,
    // V32: Financial Policy snapshot
    this.loanDayCountConvention,
    this.loanDaysPerMonth,
    this.loanDaysPerYear,
    this.loanProrationRule,
    this.loanRoundingDecimals,
    this.loanRoundingMode,
  });

  /// Create from database map
  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      loanId: map['loan_id'] as String,
      customerId: map['customer_id'] as String,
      principalOriginal: (map['principal_original'] as num).toDouble(),
      principalBalance: (map['principal_balance'] as num).toDouble(),
      monthlyInterestRate: (map['monthly_interest_rate'] as num).toDouble(),
      rateUnit: map['rate_unit'] as String? ?? 'MONTHLY',
      billingFrequency: map['billing_frequency'] as String? ?? 'MONTHLY',
      disbursementDate: DateTime.parse(map['disbursement_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      status: map['status'] as String? ?? AppStatus.loanActive,
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String)
          : null,
      notes: map['notes'] as String?,
      loanNumber: map['loan_number']?.toString(),
      currencyCode: map['currency_code'] as String? ?? 'NIO',
      appliedExchangeRate: (map['applied_exchange_rate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      paymentFrequencyDays: map['payment_frequency_days'] as int?,
      planId: map['plan_id'] as String?,
      planInstallmentsTotal: map['plan_installments_total'] as int?,
      distributeCapitalAndInterest: map['distribute_capital_and_interest'] == 1,
      endDateCalculated: map['end_date_calculated'] != null
          ? DateTime.parse(map['end_date_calculated'] as String)
          : null,
      // V32: Financial Policy snapshot
      loanDayCountConvention: map['loan_day_count_convention'] as String?,
      loanDaysPerMonth: map['loan_days_per_month'] as int?,
      loanDaysPerYear: map['loan_days_per_year'] as int?,
      loanProrationRule: map['loan_proration_rule'] as String?,
      loanRoundingDecimals: map['loan_rounding_decimals'] as int?,
      loanRoundingMode: map['loan_rounding_mode'] as String?,
    );
  }

  /// Identificador único del préstamo.
  final String loanId;

  /// Identificador del cliente asociado.
  final String customerId;

  /// Monto principal original otorgado.
  final double principalOriginal;

  /// Saldo pendiente del capital.
  final double principalBalance;

  /// Tasa de interés mensual aplicada.
  final double monthlyInterestRate;

  /// Unidad de tiempo de la tasa (normalmente 'MONTHLY').
  final String rateUnit;

  /// Frecuencia de facturación ('MONTHLY', 'BIWEEKLY', etc).
  final String billingFrequency;

  /// Fecha en la que se entregó el dinero.
  final DateTime disbursementDate;

  /// Fecha estimada de finalización.
  final DateTime? endDate;

  /// Estado actual del préstamo.
  final String status;

  /// Fecha en la que se cerró el préstamo por completo.
  final DateTime? closedAt;

  /// Notas u observaciones adicionales.
  final String? notes;

  /// Número correlativo del préstamo para visualización.
  final String? loanNumber;

  /// Código de moneda (ISO 4217, ej: 'NIO', 'USD').
  final String currencyCode;

  /// Tasa de cambio aplicada al momento del desembolso.
  final double? appliedExchangeRate;

  /// Fecha de creación en el sistema.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  /// Frecuencia de pago en días (V28).
  final int? paymentFrequencyDays;

  // V29: Payment Plan snapshot fields
  /// Identificador del plan de pagos asociado (V29).
  final String? planId;

  /// Total de cuotas del plan (V29).
  final int? planInstallmentsTotal;

  /// Indica si se distribuye capital e interés en cuotas fijas (V29).
  final bool? distributeCapitalAndInterest;

  /// Fecha de finalización calculada por el sistema (V29).
  final DateTime? endDateCalculated;

  // V32: Financial Policy snapshot fields (from BusinessFinancialPolicy)
  /// Convención de conteo de días para intereses (V32).
  final String? loanDayCountConvention;

  /// Días por mes para cálculos (V32).
  final int? loanDaysPerMonth;

  /// Días por año para cálculos (V32).
  final int? loanDaysPerYear;

  /// Regla de prorrateo aplicada (V32).
  final String? loanProrationRule;

  /// Cantidad de decimales para redondeo (V32).
  final int? loanRoundingDecimals;

  /// Modo de redondeo aplicado (V32).
  final String? loanRoundingMode;

  /// Check if loan is active (includes IN_MORA)
  bool get isActive =>
      status == AppStatus.loanActive || status == AppStatus.loanOverdue;

  /// Check if loan is in mora
  bool get isInMora => status == AppStatus.loanOverdue;

  /// Check if loan is closed
  bool get isClosed => status == AppStatus.loanClosed;

  /// Calculate biweekly rate (monthly / 2)
  double get biweeklyInterestRate => monthlyInterestRate / 2;

  /// Calculate weekly rate (monthly / 4)
  double get weeklyInterestRate => monthlyInterestRate / 4;

  /// Calculate daily rate using policy snapshot (defaults to 30 if not set)
  double get dailyInterestRate =>
      monthlyInterestRate / (loanDaysPerMonth ?? 30);

  /// Calculate interest for one month
  /// Calcula el interés generado en un mes completo sobre el saldo actual.
  double calculateMonthlyInterest() {
    return _roundMoney(principalBalance * (monthlyInterestRate / 100));
  }

  /// Calculate interest for one biweek
  /// Calcula el interés generado en una quincena sobre el saldo actual.
  double calculateBiweeklyInterest() {
    return _roundMoney(principalBalance * (biweeklyInterestRate / 100));
  }

  /// Calculate interest for one week
  /// Calcula el interés generado en una semana sobre el saldo actual.
  double calculateWeeklyInterest() {
    return _roundMoney(principalBalance * (weeklyInterestRate / 100));
  }

  /// Calculate interest for specific number of days (High Precision)
  /// Use this for dynamic frequencies to avoid intermediate rounding errors.
  /// Calcula el interés acumulado para una cantidad específica de días.
  double calculateInterestForDays(int days) {
    if (days <= 0) return 0;
    // Calculate full precision, only round at the very end
    final rawInterest = principalBalance * (dailyInterestRate / 100) * days;
    return _roundMoney(rawInterest);
  }

  /// Calculate interest for one day (Rounded)
  /// Calcula el interés generado en un solo día.
  double calculateDailyInterest() {
    return _roundMoney(principalBalance * (dailyInterestRate / 100));
  }

  /// Round to 2 decimals
  double _roundMoney(double value) {
    return (value * 100).round() / 100;
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'customer_id': customerId,
      'principal_original': principalOriginal,
      'principal_balance': principalBalance,
      'monthly_interest_rate': monthlyInterestRate,
      'rate_unit': rateUnit,
      'billing_frequency': billingFrequency,
      'disbursement_date': disbursementDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'status': status,
      'closed_at': closedAt?.toIso8601String(),
      'notes': notes,
      'loan_number': loanNumber,
      'currency_code': currencyCode,
      'applied_exchange_rate': appliedExchangeRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'payment_frequency_days': paymentFrequencyDays,
      'plan_id': planId,
      'plan_installments_total': planInstallmentsTotal,
      'distribute_capital_and_interest': distributeCapitalAndInterest ?? false
          ? 1
          : 0,
      'end_date_calculated': endDateCalculated?.toIso8601String().split('T')[0],
      // V32: Financial Policy snapshot
      'loan_day_count_convention': loanDayCountConvention,
      'loan_days_per_month': loanDaysPerMonth,
      'loan_days_per_year': loanDaysPerYear,
      'loan_proration_rule': loanProrationRule,
      'loan_rounding_decimals': loanRoundingDecimals,
      'loan_rounding_mode': loanRoundingMode,
    };
  }

  /// Copy with modifications
  Loan copyWith({
    double? principalOriginal,
    double? principalBalance,
    double? monthlyInterestRate,
    String? billingFrequency,
    DateTime? disbursementDate,
    DateTime? endDate,
    String? status,
    DateTime? closedAt,
    String? notes,
    String? loanNumber,
    String? currencyCode,
    double? appliedExchangeRate,
    DateTime? updatedAt,
    int? paymentFrequencyDays,
    String? planId,
    int? planInstallmentsTotal,
    bool? distributeCapitalAndInterest,
    DateTime? endDateCalculated,
    // V32: Financial Policy snapshot
    String? loanDayCountConvention,
    int? loanDaysPerMonth,
    int? loanDaysPerYear,
    String? loanProrationRule,
    int? loanRoundingDecimals,
    String? loanRoundingMode,
  }) {
    return Loan(
      loanId: loanId,
      customerId: customerId,
      principalOriginal: principalOriginal ?? this.principalOriginal,
      principalBalance: principalBalance ?? this.principalBalance,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
      rateUnit: rateUnit,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
      loanNumber: loanNumber ?? this.loanNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      appliedExchangeRate: appliedExchangeRate ?? this.appliedExchangeRate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      paymentFrequencyDays: paymentFrequencyDays ?? this.paymentFrequencyDays,
      planId: planId ?? this.planId,
      planInstallmentsTotal:
          planInstallmentsTotal ?? this.planInstallmentsTotal,
      distributeCapitalAndInterest:
          distributeCapitalAndInterest ?? this.distributeCapitalAndInterest,
      endDateCalculated: endDateCalculated ?? this.endDateCalculated,
      // V32: Financial Policy snapshot
      loanDayCountConvention:
          loanDayCountConvention ?? this.loanDayCountConvention,
      loanDaysPerMonth: loanDaysPerMonth ?? this.loanDaysPerMonth,
      loanDaysPerYear: loanDaysPerYear ?? this.loanDaysPerYear,
      loanProrationRule: loanProrationRule ?? this.loanProrationRule,
      loanRoundingDecimals: loanRoundingDecimals ?? this.loanRoundingDecimals,
      loanRoundingMode: loanRoundingMode ?? this.loanRoundingMode,
    );
  }

  @override
  List<Object?> get props => [
    loanId,
    customerId,
    principalOriginal,
    principalBalance,
    monthlyInterestRate,
    rateUnit,
    billingFrequency,
    disbursementDate,
    endDate,
    status,
    closedAt,
    notes,
    loanNumber,
    currencyCode,
    appliedExchangeRate,
    createdAt,
    updatedAt,
    paymentFrequencyDays,
    planId,
    planInstallmentsTotal,
    distributeCapitalAndInterest,
    endDateCalculated,
    // V32: Financial Policy snapshot
    loanDayCountConvention,
    loanDaysPerMonth,
    loanDaysPerYear,
    loanProrationRule,
    loanRoundingDecimals,
    loanRoundingMode,
  ];
}
