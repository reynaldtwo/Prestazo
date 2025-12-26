import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/loan.dart';
import '../../core/constants/app_status.dart';

/// Repository for Loan CRUD operations
class LoanRepository {
  final DatabaseHelper _databaseHelper;

  LoanRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Get all loans
  Future<List<Loan>> getAllLoans() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('loans', orderBy: 'created_at DESC');
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get active loans only
  Future<List<Loan>> getActiveLoans() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'loans',
      where: 'status = ?',
      whereArgs: [AppStatus.loanActive],
      orderBy: 'disbursement_date DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get loan by ID
  Future<Loan?> getLoanById(String loanId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'loans',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  /// Get loans by customer ID
  Future<List<Loan>> getLoansByCustomerId(String customerId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'loans',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get active loans by customer ID
  Future<List<Loan>> getActiveLoansByCustomerId(String customerId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'loans',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, AppStatus.loanActive],
      orderBy: 'disbursement_date DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get loans with customer info (JOIN query)
  Future<List<Map<String, dynamic>>> getLoansWithCustomer({
    String? status,
    int? limit,
    int? offset,
  }) async {
    final db = await _databaseHelper.database;
    String query = '''
      SELECT 
        l.*,
        c.full_name as customer_name,
        c.alias as customer_alias,
        c.phone as customer_phone,
        c.billing_frequency as customer_frequency
      FROM loans l
      INNER JOIN customers c ON l.customer_id = c.customer_id
    ''';

    List<dynamic> args = [];
    if (status != null) {
      query += ' WHERE l.status = ?';
      args.add(status);
    }

    query += ' ORDER BY l.disbursement_date DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
      if (offset != null) {
        query += ' OFFSET ?';
        args.add(offset);
      }
    }

    return await db.rawQuery(query, args);
  }

  /// Get consolidated active loans with customer info
  Future<List<Map<String, dynamic>>> getConsolidatedActiveLoans() async {
    final db = await _databaseHelper.database;
    // Includes ACTIVE and IN_MORA (Overdue)
    // Assuming 'ACTIVE' covers both in typical status flow, or we explicitly include Overdue
    // Based on user request "vigentes"
    return await db.rawQuery('''
      SELECT 
        l.*,
        c.full_name as customer_name,
        c.dni as customer_dni,
        c.phone as customer_phone,
        c.address as customer_address
      FROM loans l
      INNER JOIN customers c ON l.customer_id = c.customer_id
      WHERE l.status IN ('ACTIVE', 'OVERDUE', 'IN_MORA') 
      ORDER BY l.disbursement_date ASC
    ''');
  }

  /// Insert new loan (auto-assigns loan number)
  Future<Loan> insertLoan(Loan loan) async {
    final db = await _databaseHelper.database;
    Loan? resultLoan;

    await db.transaction((txn) async {
      // 1. Get next loan number
      final settingsResult = await txn.query(
        'app_settings',
        columns: ['loan_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );
      final nextNumber =
          settingsResult.first['loan_next_number']?.toString() ?? '1';

      // 2. Assign number to loan
      final loanWithNumber = loan.copyWith(loanNumber: nextNumber);

      // 3. Insert loan
      await txn.insert(
        'loans',
        loanWithNumber.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Increment setting
      final newNextNumber = _incrementStringCode(nextNumber);
      await txn.rawUpdate(
        'UPDATE app_settings SET loan_next_number = ?, updated_at = ? WHERE settings_id = ?',
        [newNextNumber, DateTime.now().toIso8601String(), 'global'],
      );

      resultLoan = loanWithNumber;
    });

    return resultLoan!;
  }

  /// Get the current maximum loan number
  Future<String?> getMaxLoanNumber() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(loan_number) as max_number FROM loans',
    );
    return result.first['max_number']?.toString();
  }

  /// Helper to increment alphanumeric codes
  /// Examples:
  /// '10' -> '11'
  /// 'A-001' -> 'A-002'
  /// 'INV-99' -> 'INV-100'
  /// 'ABC' -> 'ABC1'
  String _incrementStringCode(String code) {
    if (code.isEmpty) return '1';

    final RegExp regex = RegExp(r'(\d+)$');
    final match = regex.firstMatch(code);

    if (match != null) {
      final numberStr = match.group(1)!;
      final prefix = code.substring(0, code.length - numberStr.length);
      final number = int.parse(numberStr);
      final newNumber = number + 1;

      // Preserve padding if number length didn't increase
      String newNumberStr = newNumber.toString();
      if (newNumberStr.length < numberStr.length) {
        newNumberStr = newNumberStr.padLeft(numberStr.length, '0');
      }

      return '$prefix$newNumberStr';
    } else {
      // No number found, append 1
      return '${code}1';
    }
  }

  /// Update existing loan
  Future<int> updateLoan(Loan loan) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'loans',
      loan.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'loan_id = ?',
      whereArgs: [loan.loanId],
    );
  }

  /// Update principal balance
  Future<int> updatePrincipalBalance(String loanId, double newBalance) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'loans',
      {
        'principal_balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
  }

  /// Close loan (mark as PAID_OFF or CANCELLED)
  Future<int> closeLoan(String loanId, String closeStatus) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'loans',
      {
        'status': closeStatus,
        'closed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
  }

  /// Delete loan (use with caution)
  Future<int> deleteLoan(String loanId) async {
    final db = await _databaseHelper.database;
    return await db.delete('loans', where: 'loan_id = ?', whereArgs: [loanId]);
  }

  /// Get loan count
  Future<int> getLoanCount({String? status}) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      status != null
          ? 'SELECT COUNT(*) as count FROM loans WHERE status = ?'
          : 'SELECT COUNT(*) as count FROM loans',
      status != null ? [status] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get count of loans with overdue cycles
  Future<int> getOverdueLoanCount() async {
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
      '''
      SELECT COUNT(DISTINCT l.loan_id) as count 
      FROM loans l
      INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id
      WHERE l.status IN ('${AppStatus.loanActive}', '${AppStatus.loanOverdue}')
        AND (
          (bc.due_date <= ? AND bc.status IN ('${AppStatus.cyclePending}', '${AppStatus.cyclePartial}'))
          OR bc.status = '${AppStatus.cycleOverdue}'
        )
    ''',
      [cutoffDateStr],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total principal balance (active loans)
  Future<double> getTotalPrincipalBalance() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(principal_balance) as total FROM loans WHERE status = ?',
      [AppStatus.loanActive],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total original principal (active loans)
  Future<double> getTotalOriginalPrincipal() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(principal_original) as total FROM loans WHERE status = ?',
      [AppStatus.loanActive],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Check if loan has payments
  Future<bool> hasPayments(String loanId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payments WHERE loan_id = ? AND status = ?',
      [loanId, AppStatus.paymentValid],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  /// Get projected monthly earnings based on active loans
  Future<double> getProjectedMonthlyEarnings() async {
    final activeLoans = await getActiveLoans();
    double total = 0;
    for (var loan in activeLoans) {
      total += loan.principalBalance * (loan.monthlyInterestRate / 100);
    }
    return total;
  }

  /// Check if customer is restricted
  Future<Map<String, dynamic>?> checkCustomerRestriction(
    String customerId,
  ) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'customers',
      columns: ['is_restricted', 'restriction_reason'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    if (results.isNotEmpty) {
      final isRestricted = (results.first['is_restricted'] as int?) == 1;
      if (isRestricted) {
        return {
          'is_restricted': true,
          'reason': results.first['restriction_reason'] as String?,
        };
      }
    }
    return null;
  }
}
