import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:prestamos_app/data/models/payment_plan.dart';

/// Repository for PaymentPlan CRUD operations
class PaymentPlanRepository {

  /// Creates a PaymentPlanRepository
  PaymentPlanRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();
  final DatabaseHelper _dbHelper;

  /// Get all payment plans
  Future<List<PaymentPlan>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('payment_plans', orderBy: 'name ASC');
    return maps.map(PaymentPlan.fromMap).toList();
  }

  /// Get only active payment plans
  Future<List<PaymentPlan>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_plans',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map(PaymentPlan.fromMap).toList();
  }

  /// Get payment plan by ID
  Future<PaymentPlan?> getById(String planId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_plans',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    if (maps.isEmpty) return null;
    return PaymentPlan.fromMap(maps.first);
  }

  /// Get active plans applicable to a specific category
  Future<List<PaymentPlan>> getPlansForCategory(String? categoryId) async {
    final allActive = await getActive();
    return allActive.where((p) => p.appliesToCategory(categoryId)).toList();
  }

  /// Insert a new payment plan
  Future<void> insert(PaymentPlan plan) async {
    final db = await _dbHelper.database;
    await db.insert('payment_plans', plan.toMap());
  }

  /// Update an existing payment plan
  Future<void> update(PaymentPlan plan) async {
    final db = await _dbHelper.database;
    await db.update(
      'payment_plans',
      plan.toMap(),
      where: 'plan_id = ?',
      whereArgs: [plan.planId],
    );
  }

  /// Delete a payment plan (only if no active loans use it)
  Future<bool> delete(String planId) async {
    if (await hasActiveLoans(planId)) {
      return false;
    }
    final db = await _dbHelper.database;
    await db.delete('payment_plans', where: 'plan_id = ?', whereArgs: [planId]);
    return true;
  }

  /// Check if a plan has active loans associated
  Future<bool> hasActiveLoans(String planId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM loans 
      WHERE plan_id = ? AND status IN ('ACTIVE', 'IN_MORA')
    ''',
      [planId],
    );
    final count = result.first['cnt']! as int;
    return count > 0;
  }

  /// Toggle plan active status (only if no active loans when deactivating)
  Future<bool> toggleActive(String planId) async {
    final plan = await getById(planId);
    if (plan == null) return false;

    // If trying to deactivate, check for active loans
    if (plan.isActive && await hasActiveLoans(planId)) {
      return false;
    }

    final db = await _dbHelper.database;
    await db.update(
      'payment_plans',
      {
        'is_active': plan.isActive ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return true;
  }
}
