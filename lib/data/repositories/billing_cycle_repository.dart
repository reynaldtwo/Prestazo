import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/billing_cycle.dart';
import '../../core/constants/app_status.dart';

/// Repository for BillingCycle CRUD operations
class BillingCycleRepository {
  final DatabaseHelper _databaseHelper;

  BillingCycleRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Get all billing cycles for a loan
  Future<List<BillingCycle>> getBillingCyclesByLoan(String loanId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'billing_cycles',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'cycle_number ASC',
    );
    return maps.map((map) => BillingCycle.fromMap(map)).toList();
  }

  /// Get billing cycle by ID
  Future<BillingCycle?> getBillingCycleById(String billingCycleId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'billing_cycles',
      where: 'billing_cycle_id = ?',
      whereArgs: [billingCycleId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BillingCycle.fromMap(maps.first);
  }

  /// Get pending billing cycles for a loan (includes PENDING, PARTIAL, and OVERDUE status)
  Future<List<BillingCycle>> getPendingCyclesByLoan(String loanId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'billing_cycles',
      where: 'loan_id = ? AND status IN (?, ?, ?)',
      whereArgs: [
        loanId,
        AppStatus.cyclePending,
        AppStatus.cyclePartial,
        AppStatus.cycleOverdue,
      ],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => BillingCycle.fromMap(map)).toList();
  }

  /// Get overdue billing cycles
  Future<List<BillingCycle>> getOverdueCycles() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final maps = await db.query(
      'billing_cycles',
      where: 'due_date < ? AND status IN (?, ?)',
      whereArgs: [today, AppStatus.cyclePending, AppStatus.cyclePartial],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => BillingCycle.fromMap(map)).toList();
  }

  /// Get billing cycles due today
  Future<List<BillingCycle>> getCyclesDueToday() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final maps = await db.query(
      'billing_cycles',
      where: 'due_date = ? AND status IN (?, ?)',
      whereArgs: [today, AppStatus.cyclePending, AppStatus.cyclePartial],
    );
    return maps.map((map) => BillingCycle.fromMap(map)).toList();
  }

  /// Get billing cycles due in date range
  Future<List<BillingCycle>> getCyclesDueInRange(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  }) async {
    final db = await _databaseHelper.database;
    String where = 'due_date >= ? AND due_date <= ?';
    List<dynamic> args = [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ];

    if (status != null) {
      where += ' AND status = ?';
      args.add(status);
    }

    final maps = await db.query(
      'billing_cycles',
      where: where,
      whereArgs: args,
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => BillingCycle.fromMap(map)).toList();
  }

  /// Get billing cycles with loan and customer info
  Future<List<Map<String, dynamic>>> getCyclesWithDetails({
    DateTime? dueDate,
    bool overdueOnly = false,
    String? frequency,
  }) async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    String query =
        '''
      SELECT 
        bc.*,
        l.principal_original,
        l.principal_balance,
        l.monthly_interest_rate,
        c.customer_id,
        c.full_name as customer_name,
        c.alias as customer_alias,
        c.phone as customer_phone,
        c.address as customer_address,
        c.billing_frequency
      FROM billing_cycles bc
      INNER JOIN loans l ON bc.loan_id = l.loan_id
      INNER JOIN customers c ON l.customer_id = c.customer_id
      WHERE bc.status IN ('${AppStatus.cyclePending}', '${AppStatus.cyclePartial}')
        AND l.status = '${AppStatus.loanActive}'
    ''';

    List<dynamic> args = [];

    if (dueDate != null) {
      query += ' AND bc.due_date = ?';
      args.add(dueDate.toIso8601String().split('T')[0]);
    }

    if (overdueOnly) {
      query += ' AND bc.due_date < ?';
      args.add(today);
    }

    if (frequency != null) {
      query += ' AND c.billing_frequency = ?';
      args.add(frequency);
    }

    query += ' ORDER BY bc.due_date ASC, c.full_name ASC';

    return await db.rawQuery(query, args);
  }

  /// Insert billing cycle
  Future<BillingCycle> insertBillingCycle(BillingCycle cycle) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'billing_cycles',
      cycle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return cycle;
  }

  /// Insert multiple billing cycles
  Future<void> insertBillingCycles(List<BillingCycle> cycles) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      for (final cycle in cycles) {
        await txn.insert('billing_cycles', cycle.toMap());
      }
    });
  }

  /// Update billing cycle
  Future<int> updateBillingCycle(BillingCycle cycle) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'billing_cycles',
      cycle.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'billing_cycle_id = ?',
      whereArgs: [cycle.billingCycleId],
    );
  }

  /// Update interest paid
  Future<int> updateInterestPaid(
    String billingCycleId,
    double additionalPaid,
  ) async {
    final db = await _databaseHelper.database;
    return await db.rawUpdate(
      '''
      UPDATE billing_cycles 
      SET 
        interest_paid = interest_paid + ?,
        interest_pending = interest_pending - ?,
        status = CASE 
          WHEN interest_pending - ? <= 0 THEN '${AppStatus.cyclePaid}'
          WHEN interest_paid + ? > 0 THEN '${AppStatus.cyclePartial}'
          ELSE status
        END,
        updated_at = ?
      WHERE billing_cycle_id = ?
      ''',
      [
        additionalPaid,
        additionalPaid,
        additionalPaid,
        additionalPaid,
        DateTime.now().toIso8601String(),
        billingCycleId,
      ],
    );
  }

  /// Capitalize unpaid interest
  Future<int> capitalizeCycle(
    String billingCycleId,
    double amountToCapitalize,
  ) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'billing_cycles',
      {
        'is_capitalized': 1,
        'capitalized_amount': amountToCapitalize,
        'capitalized_at': DateTime.now().toIso8601String(),
        'status': 'CAPITALIZED',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'billing_cycle_id = ?',
      whereArgs: [billingCycleId],
    );
  }

  /// Delete billing cycle
  Future<int> deleteBillingCycle(String billingCycleId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'billing_cycles',
      where: 'billing_cycle_id = ?',
      whereArgs: [billingCycleId],
    );
  }

  /// Delete all billing cycles for a loan
  Future<int> deleteBillingCyclesByLoan(String loanId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'billing_cycles',
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
  }

  /// Get total pending interest for a loan
  Future<double> getTotalPendingInterest(String loanId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(interest_pending) as total FROM billing_cycles WHERE loan_id = ? AND status IN (?, ?)',
      [loanId, AppStatus.cyclePending, AppStatus.cyclePartial],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get count of overdue cycles
  Future<int> getOverdueCycleCount() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get moratorium days from settings
    int moratoriumDays = 0;
    final settingsResult = await db.query(
      'app_settings',
      columns: ['moratorium_days'],
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );
    if (settingsResult.isNotEmpty) {
      moratoriumDays = (settingsResult.first['moratorium_days'] as int?) ?? 0;
    }

    // Calculate cutoff date: today - moratorium days
    final cutoffDate = today.subtract(Duration(days: moratoriumDays));
    final cutoffDateStr = cutoffDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM billing_cycles WHERE due_date <= ? AND status IN (?, ?)',
      [cutoffDateStr, AppStatus.cyclePending, AppStatus.cyclePartial],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  /// Get current cycle for loan
  Future<BillingCycle?> getCurrentCycle(String loanId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'billing_cycles',
      where: 'loan_id = ? AND status IN (?, ?)',
      whereArgs: [loanId, AppStatus.cyclePending, AppStatus.cyclePartial],
      orderBy: 'due_date ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BillingCycle.fromMap(maps.first);
  }
}
