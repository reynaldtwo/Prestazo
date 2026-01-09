import 'package:equatable/equatable.dart';

/// Payment Frequency model
class PaymentFrequency extends Equatable {
  final String id;
  final String name;
  final int daysInterval;
  final bool isDefault; // System defined, cannot be deleted
  final bool isActive;
  final DateTime createdAt;

  const PaymentFrequency({
    required this.id,
    required this.name,
    required this.daysInterval,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
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
