import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:prestamos_app/data/models/business_financial_policy.dart';

/// Repository for managing BusinessFinancialPolicy CRUD operations.
class BusinessPolicyRepository {
  /// Crea un [BusinessPolicyRepository] con el [DatabaseHelper] proporcionado.
  BusinessPolicyRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();
  final DatabaseHelper _databaseHelper;

  /// Get the active financial policy (only one can be active).
  Future<BusinessFinancialPolicy> getActivePolicy() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'business_financial_policies',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return BusinessFinancialPolicy.fromMap(result.first);
    }

    // If no active policy, create and return default
    final defaultPolicy = BusinessFinancialPolicy.defaultPolicy();
    await insertPolicy(defaultPolicy);
    return defaultPolicy;
  }

  /// Get policy by ID.
  Future<BusinessFinancialPolicy?> getPolicyById(String id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'business_financial_policies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return BusinessFinancialPolicy.fromMap(result.first);
  }

  /// Get all policies (for history/audit).
  Future<List<BusinessFinancialPolicy>> getAllPolicies() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'business_financial_policies',
      orderBy: 'created_at DESC',
    );
    return result.map(BusinessFinancialPolicy.fromMap).toList();
  }

  /// Insert a new policy.
  Future<void> insertPolicy(BusinessFinancialPolicy policy) async {
    final db = await _databaseHelper.database;
    await db.insert('business_financial_policies', policy.toMap());
  }

  /// Update an existing policy.
  Future<int> updatePolicy(BusinessFinancialPolicy policy) async {
    final db = await _databaseHelper.database;
    return db.update(
      'business_financial_policies',
      policy.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [policy.id],
    );
  }

  /// Set a policy as active (deactivates all others).
  Future<void> setActivePolicy(String policyId) async {
    final db = await _databaseHelper.database;

    // Deactivate all policies
    await db.update('business_financial_policies', {
      'is_active': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Activate the specified policy
    await db.update(
      'business_financial_policies',
      {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [policyId],
    );
  }

  /// Save policy (insert if new, update if exists).
  /// Automatically sets as active and deactivates others.
  Future<void> saveAsActivePolicy(BusinessFinancialPolicy policy) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    // Deactivate all current policies
    await db.update('business_financial_policies', {
      'is_active': 0,
      'updated_at': now.toIso8601String(),
    });

    // Check if policy exists
    final existing = await getPolicyById(policy.id);

    if (existing != null) {
      // Update existing
      await updatePolicy(policy.copyWith(isActive: true, updatedAt: now));
    } else {
      // Insert new
      await insertPolicy(policy.copyWith(isActive: true, updatedAt: now));
    }
  }
}
