import 'package:equatable/equatable.dart';
import 'package:prestamos_app/core/constants/app_status.dart';

/// Customer model - Client master data
class Customer extends Equatable {
  /// Crea un [Customer] que contiene los datos maestros de un cliente.
  const Customer({
    required this.customerId,
    required this.fullName,
    required this.billingFrequency,
    required this.createdAt,
    required this.updatedAt,
    this.alias,
    this.phone,
    this.address,
    this.notes,
    this.status = AppStatus.customerActive,
    this.preferredPayDay,
    this.dni,
    this.coords,
    this.isRestricted = false,
    this.restrictionReason,
    this.categoryId,
  });

  /// Create from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customer_id'] as String,
      fullName: map['full_name'] as String,
      alias: map['alias'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? AppStatus.customerActive,
      billingFrequency: map['billing_frequency'] as String,
      preferredPayDay: map['preferred_pay_day'] as int?,
      dni: map['dni'] as String?,
      coords: map['coords'] as String?,
      isRestricted: (map['is_restricted'] as int?) == 1,
      restrictionReason: map['restriction_reason'] as String?,
      categoryId: map['category_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Identificador único del cliente.
  final String customerId;

  /// Nombre completo del cliente.
  final String fullName;

  /// Alias o nombre corto del cliente (opcional).
  final String? alias;

  /// Número de teléfono de contacto.
  final String? phone;

  /// Dirección física del cliente.
  final String? address;

  /// Notas u observaciones adicionales.
  final String? notes;

  /// Estado actual del cliente (ACTIVE, INACTIVE, etc).
  final String status;

  /// Frecuencia de cobro preferida o habitual.
  final String billingFrequency;

  /// Día del mes preferido para realizar pagos (1-31).
  final int? preferredPayDay;

  /// Cédula o documento de identidad.
  final String? dni;

  /// Coordenadas de ubicación (lat,lng).
  final String? coords;

  /// Indica si el cliente tiene restricciones para nuevos créditos.
  final bool isRestricted;

  /// Motivo de la restricción (si aplica).
  final String? restrictionReason;

  /// Referencia a la categoría del cliente.
  final String? categoryId;

  /// Fecha de registro en el sistema.
  final DateTime createdAt;

  /// Fecha de última actualización de los datos.
  final DateTime updatedAt;

  /// Check if customer is active
  bool get isActive => status == AppStatus.customerActive;

  /// Display name (alias if available, otherwise full name)
  String get displayName => alias?.isNotEmpty ?? false ? alias! : fullName;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'full_name': fullName,
      'alias': alias,
      'phone': phone,
      'address': address,
      'notes': notes,
      'status': status,
      'billing_frequency': billingFrequency,
      'preferred_pay_day': preferredPayDay,
      'dni': dni,
      'coords': coords,
      'is_restricted': isRestricted ? 1 : 0,
      'restriction_reason': restrictionReason,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  Customer copyWith({
    String? fullName,
    String? alias,
    String? phone,
    String? address,
    String? notes,
    String? status,
    String? billingFrequency,
    int? preferredPayDay,
    String? dni,
    String? coords,
    bool? isRestricted,
    String? restrictionReason,
    String? categoryId,
    DateTime? updatedAt,
  }) {
    return Customer(
      customerId: customerId,
      fullName: fullName ?? this.fullName,
      alias: alias ?? this.alias,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      preferredPayDay: preferredPayDay ?? this.preferredPayDay,
      dni: dni ?? this.dni,
      coords: coords ?? this.coords,
      isRestricted: isRestricted ?? this.isRestricted,
      restrictionReason: restrictionReason ?? this.restrictionReason,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    customerId,
    fullName,
    alias,
    phone,
    address,
    notes,
    status,
    billingFrequency,
    preferredPayDay,
    dni,
    coords,
    isRestricted,
    restrictionReason,
    categoryId,
    createdAt,
    updatedAt,
  ];
}
