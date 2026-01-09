import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/customer_category.dart';
import '../models/customer.dart';

/// Repository for customer category operations
class CustomerCategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Get all categories ordered by sortOrder
  Future<List<CustomerCategory>> getAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customer_categories',
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map((m) => CustomerCategory.fromMap(m)).toList();
  }

  /// Get category by ID
  Future<CustomerCategory?> getById(String categoryId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customer_categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    if (maps.isEmpty) return null;
    return CustomerCategory.fromMap(maps.first);
  }

  /// Create new category
  Future<CustomerCategory> create({
    required String name,
    String? colorHex,
    int sortOrder = 0,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final category = CustomerCategory(
      categoryId: const Uuid().v4(),
      name: name,
      colorHex: colorHex,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('customer_categories', category.toMap());
    return category;
  }

  /// Update existing category
  Future<void> update(CustomerCategory category) async {
    final db = await _databaseHelper.database;
    await db.update(
      'customer_categories',
      category.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
    );
  }

  /// Delete category by ID
  /// Returns true if deleted, false if in use
  Future<bool> delete(String categoryId) async {
    // Check if any customers use this category
    final customers = await getCustomersWithCategory(categoryId);
    if (customers.isNotEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;
    await db.delete(
      'customer_categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return true;
  }

  /// Get customers that have this category assigned
  Future<List<Customer>> getCustomersWithCategory(String categoryId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customers',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  /// Get count of customers using a category
  Future<int> getCustomerCountForCategory(String categoryId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers WHERE category_id = ?',
      [categoryId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
