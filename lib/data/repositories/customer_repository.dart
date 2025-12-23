import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

/// Repository for Customer CRUD operations
class CustomerRepository {
  final DatabaseHelper _databaseHelper;

  CustomerRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customers',
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get active customers only
  Future<List<Customer>> getActiveCustomers() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customers',
      where: 'status = ?',
      whereArgs: ['ACTIVE'],
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customers',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Get customers by billing frequency
  Future<List<Customer>> getCustomersByFrequency(String frequency) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'customers',
      where: 'billing_frequency = ? AND status = ?',
      whereArgs: [frequency, 'ACTIVE'],
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Search customers by name or alias
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _databaseHelper.database;
    final searchPattern = '%$query%';
    final maps = await db.query(
      'customers',
      where: 'full_name LIKE ? OR alias LIKE ?',
      whereArgs: [searchPattern, searchPattern],
      orderBy: 'full_name ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Insert new customer
  Future<Customer> insertCustomer(Customer customer) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customer;
  }

  /// Update existing customer
  Future<int> updateCustomer(Customer customer) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'customers',
      customer.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'customer_id = ?',
      whereArgs: [customer.customerId],
    );
  }

  /// Soft delete customer (change status to INACTIVE)
  Future<int> deactivateCustomer(String customerId) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'customers',
      {
        'status': 'INACTIVE',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  /// Reactivate customer
  Future<int> activateCustomer(String customerId) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'customers',
      {
        'status': 'ACTIVE',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  /// Hard delete customer (use with caution)
  Future<int> deleteCustomer(String customerId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'customers',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  /// Get customer count
  Future<int> getCustomerCount({bool activeOnly = true}) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      activeOnly
          ? 'SELECT COUNT(*) as count FROM customers WHERE status = ?'
          : 'SELECT COUNT(*) as count FROM customers',
      activeOnly ? ['ACTIVE'] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if customer has active loans
  Future<bool> hasActiveLoans(String customerId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM loans WHERE customer_id = ? AND status = ?',
      [customerId, 'ACTIVE'],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }
}
