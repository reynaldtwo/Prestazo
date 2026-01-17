import 'package:equatable/equatable.dart';

/// Currency model - Master table for supported currencies
class Currency extends Equatable {
  /// Crea una instancia de [Currency] para representar una moneda soportada.
  const Currency({
    required this.currencyCode,
    required this.fractionDigits,
    required this.nameKey,
    required this.createdAt,
    required this.updatedAt,
    this.symbol,
    this.isActive = true,
  });

  /// Create from database map
  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      currencyCode: map['currency_code'] as String,
      fractionDigits: map['fraction_digits'] as int,
      symbol: map['symbol'] as String?,
      nameKey: map['name_key'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Código ISO 4217 de la moneda (ej: USD, NIO).
  final String currencyCode;

  /// Cantidad de decimales (ej: 2).
  final int fractionDigits;

  /// Símbolo de visualización (ej: $, C$).
  final String? symbol;

  /// Clave de traducción para el nombre de la moneda.
  final String nameKey;

  /// Indica si la moneda está habilitada.
  final bool isActive;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'currency_code': currencyCode,
      'fraction_digits': fractionDigits,
      'symbol': symbol,
      'name_key': nameKey,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    currencyCode,
    fractionDigits,
    symbol,
    nameKey,
    isActive,
    createdAt,
    updatedAt,
  ];
}
