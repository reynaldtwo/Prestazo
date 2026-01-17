import 'package:equatable/equatable.dart';

/// Payment Frequency model
class PaymentFrequency extends Equatable {
  /// Crea una instancia de [PaymentFrequency].
  const PaymentFrequency({
    required this.id,
    required this.name,
    required this.daysInterval,
    required this.createdAt,
    this.isDefault = false,
    this.isActive = true,
  });

  /// Create from map
  factory PaymentFrequency.fromMap(Map<String, dynamic> map) {
    return PaymentFrequency(
      id: map['id'] as String,
      name: map['name'] as String,
      daysInterval: map['days_interval'] as int,
      isDefault: (map['is_default'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Identificador único de la frecuencia.
  final String id;

  /// Nombre descriptivo (ej: 'Quincenal').
  final String name;

  /// Intervalo en días entre cada cobro.
  final int daysInterval;

  /// Indica si es una frecuencia predefinida por el sistema.
  final bool isDefault;

  /// Indica si la frecuencia está disponible para ser usada.
  final bool isActive;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'days_interval': daysInterval,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea una copia de esta frecuencia con los campos proporcionados actualizados.
  PaymentFrequency copyWith({String? name, int? daysInterval, bool? isActive}) {
    return PaymentFrequency(
      id: id,
      name: name ?? this.name,
      daysInterval: daysInterval ?? this.daysInterval,
      isDefault: isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    daysInterval,
    isDefault,
    isActive,
    createdAt,
  ];
}
