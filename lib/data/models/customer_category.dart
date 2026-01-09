import 'package:equatable/equatable.dart';

/// Customer category model for classifying customers
class CustomerCategory extends Equatable {
  /// Unique identifier
  final String categoryId;

  /// Display name
  final String name;

  /// Optional hex color code (e.g., "#FF5722")
  final String? colorHex;

  /// Sort order for display
  final int sortOrder;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Creates a CustomerCategory
  const CustomerCategory({
    required this.categoryId,
    required this.name,
    this.colorHex,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
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
