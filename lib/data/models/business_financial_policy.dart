import 'package:equatable/equatable.dart';

/// Política financiera configurable para cálculos de interés.
///
/// Define la convención de conteo de días (Day Count Convention)
/// y reglas de redondeo para todos los cálculos financieros.
/// Solo puede existir una política activa a la vez.
class BusinessFinancialPolicy extends Equatable {
  /// Crea una instancia de [BusinessFinancialPolicy].
  const BusinessFinancialPolicy({
    required this.id,
    required this.dayCountConvention,
    required this.daysPerMonth,
    required this.daysPerYear,
    required this.prorationRule,
    required this.roundingDecimals,
    required this.roundingMode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Default policy: 30/360 commercial standard
  factory BusinessFinancialPolicy.defaultPolicy() {
    final now = DateTime.now();
    return BusinessFinancialPolicy(
      id: 'default',
      dayCountConvention: '30/360',
      daysPerMonth: 30,
      daysPerYear: 360,
      prorationRule: 'CYCLE_PROPORTION',
      roundingDecimals: 2,
      roundingMode: 'HALF_UP',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from database map
  factory BusinessFinancialPolicy.fromMap(Map<String, dynamic> map) {
    return BusinessFinancialPolicy(
      id: map['id'] as String,
      dayCountConvention: map['day_count_convention'] as String,
      daysPerMonth: map['days_per_month'] as int,
      daysPerYear: map['days_per_year'] as int,
      prorationRule: map['proration_rule'] as String,
      roundingDecimals: map['rounding_decimals'] as int,
      roundingMode: map['rounding_mode'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Identificador único de la política.
  final String id;

  /// Convención de conteo de días (ej: '30/360', 'ACTUAL/360').
  final String dayCountConvention;

  /// Días por mes para el cálculo de interés (ej: 30).
  final int daysPerMonth;

  /// Días por año para el cálculo de interés (ej: 360, 365).
  final int daysPerYear;

  /// Regla de prorrateo ('EXACT_DAYS' o 'CYCLE_PROPORTION').
  final String prorationRule;

  /// Cantidad de decimales para el redondeo de intereses.
  final int roundingDecimals;

  /// Modo de redondeo ('HALF_UP', 'DOWN', etc).
  final String roundingMode;

  /// Indica si esta política es la que está activa actualmente.
  final bool isActive;

  /// Fecha de creación de la política.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day_count_convention': dayCountConvention,
      'days_per_month': daysPerMonth,
      'days_per_year': daysPerYear,
      'proration_rule': prorationRule,
      'rounding_decimals': roundingDecimals,
      'rounding_mode': roundingMode,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  BusinessFinancialPolicy copyWith({
    String? id,
    String? dayCountConvention,
    int? daysPerMonth,
    int? daysPerYear,
    String? prorationRule,
    int? roundingDecimals,
    String? roundingMode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessFinancialPolicy(
      id: id ?? this.id,
      dayCountConvention: dayCountConvention ?? this.dayCountConvention,
      daysPerMonth: daysPerMonth ?? this.daysPerMonth,
      daysPerYear: daysPerYear ?? this.daysPerYear,
      prorationRule: prorationRule ?? this.prorationRule,
      roundingDecimals: roundingDecimals ?? this.roundingDecimals,
      roundingMode: roundingMode ?? this.roundingMode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate daily interest rate from monthly rate using this policy
  double dailyRateFromMonthly(double monthlyRate) {
    return monthlyRate / daysPerMonth;
  }

  /// Calculate monthly equivalent from daily rate
  double monthlyRateFromDaily(double dailyRate) {
    return dailyRate * daysPerMonth;
  }

  /// Get human-readable convention name
  String get conventionDisplayName {
    switch (dayCountConvention) {
      case '30/360':
        return '30/360 (Estándar Comercial)';
      case 'ACTUAL/360':
        return 'Actual/360';
      case 'ACTUAL/365':
        return 'Actual/365';
      case '30/365':
        return '30/365';
      default:
        return dayCountConvention;
    }
  }

  @override
  List<Object?> get props => [
    id,
    dayCountConvention,
    daysPerMonth,
    daysPerYear,
    prorationRule,
    roundingDecimals,
    roundingMode,
    isActive,
  ];
}
