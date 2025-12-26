import 'package:equatable/equatable.dart';
import '../../core/constants/app_status.dart';

/// Customer model - Client master data
class Customer extends Equatable {
  final String customerId;
  final String fullName;
  final String? alias;
  final String? phone;
  final String? address;
  final String? notes;
  final String status;
  final String billingFrequency;
  final int? preferredPayDay;
  final String? dni;
  final String? coords;
  final bool isRestricted;
  final String? restrictionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.customerId,
    required this.fullName,
    this.alias,
    this.phone,
    this.address,
    this.notes,
    this.status = AppStatus.customerActive,
    required this.billingFrequency,
    this.preferredPayDay,
    this.dni,
    this.coords,
    this.isRestricted = false,
    this.restrictionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if customer is active
  bool get isActive => status == AppStatus.customerActive;

  /// Display name (alias if available, otherwise full name)
  String get displayName => alias?.isNotEmpty == true ? alias! : fullName;

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
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

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
    createdAt,
    updatedAt,
  ];
}
