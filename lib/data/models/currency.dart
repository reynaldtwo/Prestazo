import 'package:equatable/equatable.dart';

/// Currency model - Master table for supported currencies
class Currency extends Equatable {
  final String currencyCode; // ISO 4217 code (e.g., USD, NIO, EUR)
  final int fractionDigits; // Decimal places (usually 2)
  final String? symbol; // Display symbol (e.g., $, C$, €)
  final String nameKey; // i18n key for currency name
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Currency({
    required this.currencyCode,
    required this.fractionDigits,
    this.symbol,
    required this.nameKey,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
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
