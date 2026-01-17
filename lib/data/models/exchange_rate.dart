import 'package:equatable/equatable.dart';

/// ExchangeRate model - Historical exchange rates
class ExchangeRate extends Equatable {
  /// Crea un [ExchangeRate] para registrar una tasa de cambio histórica.
  const ExchangeRate({
    required this.rateId,
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.date,
    required this.buyRate,
    required this.sellRate,
    required this.createdAt,
  });

  /// Create from database map
  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      rateId: map['rate_id'] as String,
      sourceCurrency: map['source_currency'] as String,
      targetCurrency: map['target_currency'] as String,
      date: DateTime.parse(map['rate_date'] as String),
      buyRate: (map['buy_rate'] as num).toDouble(),
      sellRate: (map['sell_rate'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Identificador único de la tasa de cambio.
  final String rateId;

  /// Código de la moneda de origen.
  final String sourceCurrency;

  /// Código de la moneda de destino.
  final String targetCurrency;

  /// Fecha a la que corresponde la tasa.
  final DateTime date;

  /// Tasa de compra.
  final double buyRate;

  /// Tasa de venta.
  final double sellRate;

  /// Fecha de registro en el sistema.
  final DateTime createdAt;

  /// Get average rate (mid-market rate)
  double get averageRate => (buyRate + sellRate) / 2;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'rate_id': rateId,
      'source_currency': sourceCurrency,
      'target_currency': targetCurrency,
      'rate_date': date.toIso8601String().split('T')[0],
      'buy_rate': buyRate,
      'sell_rate': sellRate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  ExchangeRate copyWith({
    String? sourceCurrency,
    String? targetCurrency,
    DateTime? date,
    double? buyRate,
    double? sellRate,
  }) {
    return ExchangeRate(
      rateId: rateId,
      sourceCurrency: sourceCurrency ?? this.sourceCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      date: date ?? this.date,
      buyRate: buyRate ?? this.buyRate,
      sellRate: sellRate ?? this.sellRate,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    rateId,
    sourceCurrency,
    targetCurrency,
    date,
    buyRate,
    sellRate,
    createdAt,
  ];
}
