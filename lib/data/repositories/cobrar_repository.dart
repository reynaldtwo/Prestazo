import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Model for raw customer due data from database
class CustomerDueRow {
  final String customerId;
  final String fullName;
  final String? alias;
  final String? phone;
  final String billingFrequency;
  final String loanId;
  final double principalBalance;
  final String? billingCycleId;
  final String dueDate;
  final double interestExpected;
  final double interestPaid;
  final double interestPending;
  final String? cycleStatus;
  final String? lastPaymentDate;

  const CustomerDueRow({
    required this.customerId,
    required this.fullName,
    this.alias,
    this.phone,
    required this.billingFrequency,
    required this.loanId,
    required this.principalBalance,
    this.billingCycleId,
    required this.dueDate,
    required this.interestExpected,
    required this.interestPaid,
    required this.interestPending,
    this.cycleStatus,
    this.lastPaymentDate,
  });

  factory CustomerDueRow.fromMap(Map<String, dynamic> map) {
    return CustomerDueRow(
      customerId: map['customer_id'] as String,
      fullName: map['full_name'] as String,
      alias: map['alias'] as String?,
      phone: map['phone'] as String?,
      billingFrequency: map['billing_frequency'] as String,
      loanId: map['loan_id'] as String,
      principalBalance: (map['principal_balance'] as num?)?.toDouble() ?? 0,
      billingCycleId: map['billing_cycle_id'] as String?,
      dueDate: map['due_date'] as String,
      interestExpected: (map['interest_expected'] as num?)?.toDouble() ?? 0,
      interestPaid: (map['interest_paid'] as num?)?.toDouble() ?? 0,
      interestPending: (map['interest_pending'] as num?)?.toDouble() ?? 0,
      cycleStatus: map['cycle_status'] as String?,
      lastPaymentDate: map['last_payment_date'] as String?,
    );
  }
}

/// Repository for "A Cobrar" (Collections) queries
class CobrarRepository {
  final DatabaseHelper _databaseHelper;

  CobrarRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Get moratorium days from settings
  Future<int> getMoratoriumDays() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'app_settings',
      columns: ['moratorium_days'],
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );
    if (result.isNotEmpty) {
      return (result.first['moratorium_days'] as int?) ?? 0;
    }
    return 0;
  }

  /// Get overdue customers with their billing cycles
  Future<List<CustomerDueRow>> getOverdueCustomers({
    required DateTime today,
    required int moratoriumDays,
  }) async {
    final db = await _databaseHelper.database;
    final cutoffDate = today.subtract(Duration(days: moratoriumDays));
    final cutoffDateStr = cutoffDate.toIso8601String().split('T')[0];

    final results = await db.rawQuery(
      '''
      SELECT 
        c.customer_id,
        c.full_name,
        c.alias,
        c.phone,
        l.billing_frequency,
        l.loan_id,
        l.principal_balance,
        bc.billing_cycle_id,
        bc.due_date,
        bc.interest_expected,
        bc.interest_paid,
        bc.interest_pending,
        bc.status as cycle_status,
        (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
      FROM customers c
      INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
      INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
        AND (bc.status = 'OVERDUE' OR (bc.status IN ('PENDING', 'PARTIAL') AND bc.due_date < ?))
      WHERE c.status = 'ACTIVE'
      ORDER BY bc.due_date ASC, c.full_name ASC
    ''',
      [cutoffDateStr],
    );

    return results.map((row) => CustomerDueRow.fromMap(row)).toList();
  }

  /// Get biweekly customers with overdue cycles
  Future<List<CustomerDueRow>> getBiweeklyCustomers({
    required DateTime today,
  }) async {
    final db = await _databaseHelper.database;
    final todayStr = today.toIso8601String().split('T')[0];

    final results = await db.rawQuery(
      '''
      SELECT 
        c.customer_id,
        c.full_name,
        c.alias,
        c.phone,
        l.billing_frequency,
        l.loan_id,
        l.principal_balance,
        bc.billing_cycle_id,
        bc.due_date,
        bc.interest_expected,
        bc.interest_paid,
        bc.interest_pending,
        (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
      FROM customers c
      INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
      INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
        AND bc.status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        AND bc.due_date < ?
      WHERE c.status = 'ACTIVE' AND l.billing_frequency = 'BIWEEKLY'
      ORDER BY bc.due_date ASC, c.full_name ASC
    ''',
      [todayStr],
    );

    return results.map((row) => CustomerDueRow.fromMap(row)).toList();
  }

  /// Get monthly customers with overdue cycles
  Future<List<CustomerDueRow>> getMonthlyCustomers({
    required DateTime today,
  }) async {
    final db = await _databaseHelper.database;
    final todayStr = today.toIso8601String().split('T')[0];

    final results = await db.rawQuery(
      '''
      SELECT 
        c.customer_id,
        c.full_name,
        c.alias,
        c.phone,
        l.billing_frequency,
        l.loan_id,
        l.principal_balance,
        bc.billing_cycle_id,
        bc.due_date,
        bc.interest_expected,
        bc.interest_paid,
        bc.interest_pending,
        (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
      FROM customers c
      INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
      INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
        AND bc.status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        AND bc.due_date < ?
      WHERE c.status = 'ACTIVE' AND l.billing_frequency = 'MONTHLY'
      ORDER BY bc.due_date ASC, c.full_name ASC
    ''',
      [todayStr],
    );

    return results.map((row) => CustomerDueRow.fromMap(row)).toList();
  }

  /// Get customers with cycles due in next 7 days
  Future<List<CustomerDueRow>> getUpcomingCustomers({
    required DateTime today,
    int daysAhead = 7,
  }) async {
    final db = await _databaseHelper.database;
    final todayStr = today.toIso8601String().split('T')[0];
    final futureDate = today.add(Duration(days: daysAhead));
    final futureDateStr = futureDate.toIso8601String().split('T')[0];

    final results = await db.rawQuery(
      '''
      SELECT 
        c.customer_id,
        c.full_name,
        c.alias,
        c.phone,
        l.billing_frequency,
        l.loan_id,
        l.principal_balance,
        bc.billing_cycle_id,
        bc.due_date,
        bc.interest_expected,
        bc.interest_paid,
        bc.interest_pending,
        (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
      FROM customers c
      INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
      INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
        AND bc.status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        AND bc.due_date BETWEEN ? AND ?
      WHERE c.status = 'ACTIVE'
      ORDER BY bc.due_date ASC, c.full_name ASC
    ''',
      [todayStr, futureDateStr],
    );

    return results.map((row) => CustomerDueRow.fromMap(row)).toList();
  }

  /// Get summary statistics for dashboard
  Future<Map<String, dynamic>> getCollectionsSummary({
    required DateTime today,
  }) async {
    final db = await _databaseHelper.database;
    final todayStr = today.toIso8601String().split('T')[0];

    // Total pending interest
    final pendingResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(bc.interest_pending), 0) as total_pending
      FROM billing_cycles bc
      INNER JOIN loans l ON bc.loan_id = l.loan_id
      WHERE l.status IN ('ACTIVE', 'IN_MORA')
        AND bc.status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        AND bc.due_date < ?
    ''',
      [todayStr],
    );

    // Count of customers with overdue cycles
    final customerCountResult = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT c.customer_id) as count
      FROM customers c
      INNER JOIN loans l ON c.customer_id = l.customer_id
      INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id
      WHERE l.status IN ('ACTIVE', 'IN_MORA')
        AND bc.status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        AND bc.due_date < ?
    ''',
      [todayStr],
    );

    return {
      'total_pending_interest':
          (pendingResult.first['total_pending'] as num?)?.toDouble() ?? 0,
      'overdue_customer_count': Sqflite.firstIntValue(customerCountResult) ?? 0,
    };
  }
}
