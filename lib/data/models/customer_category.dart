import 'package:equatable/equatable.dart';

/// Customer category model for classifying customers
class CustomerCategory extends Equatable {
  /// Creates a CustomerCategory
  const CustomerCategory({
    required this.categoryId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.colorHex,
    this.sortOrder = 0,
  });

  /// Create from database map
  factory CustomerCategory.fromMap(Map<String, dynamic> map) {
    return CustomerCategory(
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Identificador único de la categoría.
  final String categoryId;

  /// Nombre mostrado de la categoría.
  final String name;

  /// Código de color hexadecimal opcional (ej: "#FF5722").
  final String? colorHex;

  /// Orden de clasificación para la visualización.
  final int sortOrder;

  /// Fecha de creación del registro.
  final DateTime createdAt;

  /// Fecha de última actualización.
  final DateTime updatedAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'color_hex': colorHex,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  CustomerCategory copyWith({
    String? name,
    String? colorHex,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return CustomerCategory(
      categoryId: categoryId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    categoryId,
    name,
    colorHex,
    sortOrder,
    createdAt,
    updatedAt,
  ];
}
