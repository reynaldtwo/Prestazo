import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../models/payment_allocation.dart';
import '../models/client_credit_ledger.dart';
import '../../core/utils/string_utils.dart';
import '../../services/backup_service.dart';

/// Repository for Payment CRUD operations
class PaymentRepository {
  final DatabaseHelper _databaseHelper;

  PaymentRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Expose database for complex report queries
  Future<Database> get database => _databaseHelper.database;

  /// Get all payments
  Future<List<Payment>> getAllPayments() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'payments',
      where: 'status = ?',
      whereArgs: ['VALID'],
      orderBy: 'created_at DESC', // V25: payment_date -> created_at
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'payments',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  /// Get payments by loan ID
  Future<List<Payment>> getPaymentsByLoanId(String loanId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'payments',
      where: 'loan_id = ? AND status = ?',
      whereArgs: [loanId, 'VALID'],
      orderBy: 'created_at DESC', // V25
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  /// Get payments by customer ID
  Future<List<Payment>> getPaymentsByCustomerId(String customerId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'payments',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, 'VALID'],
      orderBy: 'created_at DESC', // V25
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  /// Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    // Use rawQuery with date() for proper date comparison
    final maps = await db.rawQuery(
      '''
      SELECT * FROM payments 
      WHERE date(created_at) >= date(?) AND date(created_at) <= date(?) AND status = ?
      ORDER BY created_at DESC
      ''',
      [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
        'VALID',
      ],
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  /// Get today's payments
  Future<List<Payment>> getTodayPayments() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getPaymentsByDateRange(startOfDay, endOfDay);
  }

  /// Get payments with customer and loan info
  Future<List<Map<String, dynamic>>> getPaymentsWithDetails({
    String? loanId,
    String? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;
    String query = '''
      SELECT 
        p.*,
        c.full_name as customer_name,
        c.alias as customer_alias,
        l.principal_original,
        l.principal_balance,
        l.currency_code,
        (SELECT COALESCE(SUM(amount_loan_minor), 0) / 100.0 FROM payment_allocations WHERE payment_id = p.payment_id AND allocation_type = 'INTEREST') as interest_paid,
        (SELECT COALESCE(SUM(amount_loan_minor), 0) / 100.0 FROM payment_allocations WHERE payment_id = p.payment_id AND allocation_type = 'MORA') as mora_paid,
        (SELECT COALESCE(SUM(amount_loan_minor), 0) / 100.0 FROM payment_allocations WHERE payment_id = p.payment_id AND allocation_type = 'PRINCIPAL') as principal_paid
      FROM payments p
      INNER JOIN customers c ON p.customer_id = c.customer_id
      INNER JOIN loans l ON p.loan_id = l.loan_id
      WHERE p.status = 'VALID'
    ''';

    List<dynamic> args = [];

    if (loanId != null) {
      query += ' AND p.loan_id = ?';
      args.add(loanId);
    }

    if (customerId != null) {
      query += ' AND p.customer_id = ?';
      args.add(customerId);
    }

    if (fromDate != null) {
      query += ' AND p.created_at >= ?';
      args.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      query += ' AND p.created_at <= ?';
      args.add(toDate.toIso8601String());
    }

    query += ' ORDER BY p.created_at DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    return await db.rawQuery(query, args);
  }

  /// Get all payments with customer info (for history screen)
  Future<List<Map<String, dynamic>>> getAllPaymentsWithCustomer() async {
    final db = await _databaseHelper.database;
    return await db.rawQuery('''
      SELECT 
        p.*,
        c.full_name as customer_name,
        c.alias as customer_alias,
        l.currency_code as loan_currency_code,
        COALESCE((SELECT SUM(pa.amount_loan_minor) FROM payment_allocations pa WHERE pa.payment_id = p.payment_id AND allocation_type = 'INTEREST'), 0) / 100.0 as interest_paid,
        COALESCE((SELECT SUM(pa.amount_loan_minor) FROM payment_allocations pa WHERE pa.payment_id = p.payment_id AND allocation_type = 'PRINCIPAL'), 0) / 100.0 as principal_paid
      FROM payments p
      INNER JOIN customers c ON p.customer_id = c.customer_id
      INNER JOIN loans l ON p.loan_id = l.loan_id
      WHERE p.status = 'VALID'
      ORDER BY p.created_at DESC
      LIMIT 100
    ''');
  }

  /// Insert payment with allocations (transaction)
  Future<Payment> insertPaymentWithAllocations(
    Payment payment,
    List<PaymentAllocation> allocations,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.transaction((txn) async {
      // 0. Idempotency Check - prevent duplicate payments
      final existingPayment = await txn.query(
        'payments',
        where: 'payload_hash = ? AND status = ?',
        whereArgs: [payment.payloadHash, 'VALID'],
        limit: 1,
      );
      if (existingPayment.isNotEmpty) {
        // Return existing payment instead of creating duplicate
        return Payment.fromMap(existingPayment.first);
      }

      // 1. Get next receipt number from settings
      final settingsResult = await txn.query(
        'app_settings',
        columns: ['receipt_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );
      final nextNumber =
          settingsResult.first['receipt_next_number']?.toString() ?? '1';

      // 2. Assign to payment
      final paymentWithNumber = payment.copyWith(receiptNumber: nextNumber);

      // 3. Insert payment
      await txn.insert('payments', paymentWithNumber.toMap());

      // 4. Update settings (Increment)
      final newNextNumber = incrementStringCode(nextNumber);
      await txn.rawUpdate(
        'UPDATE app_settings SET receipt_next_number = ?, updated_at = ? WHERE settings_id = ?',
        [newNextNumber, DateTime.now().toIso8601String(), 'global'],
      );

      // Insert allocations
      for (final allocation in allocations) {
        await txn.insert('payment_allocations', allocation.toMap());
      }

      // Update loan principal balance if there's a principal allocation
      final principalAllocation = allocations.where(
        (a) => a.allocationType == 'PRINCIPAL',
      );
      if (principalAllocation.isNotEmpty) {
        final totalPrincipal = principalAllocation.fold<double>(
          0,
          (sum, a) => sum + a.amount,
        );
        await txn.rawUpdate(
          'UPDATE loans SET principal_balance = principal_balance - ?, updated_at = ? WHERE loan_id = ?',
          [totalPrincipal, DateTime.now().toIso8601String(), payment.loanId],
        );

        // Check if loan should be closed (principal_balance < 1)
        final loanResult = await txn.query(
          'loans',
          columns: ['principal_balance'],
          where: 'loan_id = ?',
          whereArgs: [payment.loanId],
        );
        if (loanResult.isNotEmpty) {
          final balance = (loanResult.first['principal_balance'] as num)
              .toDouble();
          if (balance < 1) {
            // Close the loan
            await txn.rawUpdate(
              'UPDATE loans SET status = ?, closed_at = ?, updated_at = ? WHERE loan_id = ?',
              [
                'CLOSED',
                DateTime.now().toIso8601String(),
                DateTime.now().toIso8601String(),
                payment.loanId,
              ],
            );
            // Also close any pending billing cycles for this loan
            // Set interest_pending = 0 and status = PAID for ALL non-paid cycles
            await txn.rawUpdate(
              'UPDATE billing_cycles SET status = ?, interest_pending = 0, updated_at = ? WHERE loan_id = ? AND status IN (?, ?, ?)',
              [
                'PAID',
                DateTime.now().toIso8601String(),
                payment.loanId,
                'PENDING',
                'PARTIAL',
                'OVERDUE',
              ],
            );
          }
        }
      }

      // Update billing cycle interest if there's an interest allocation
      for (final allocation in allocations.where(
        (a) => a.allocationType == 'INTEREST' && a.billingCycleId != null,
      )) {
        // First update the interest values
        await txn.rawUpdate(
          'UPDATE billing_cycles SET interest_paid = interest_paid + ?, interest_pending = interest_pending - ?, updated_at = ? WHERE billing_cycle_id = ?',
          [
            allocation.amount,
            allocation.amount,
            DateTime.now().toIso8601String(),
            allocation.billingCycleId,
          ],
        );

        // Then update status to PAID if interest_pending is 0 or less
        await txn.rawUpdate(
          'UPDATE billing_cycles SET status = ? WHERE billing_cycle_id = ? AND interest_pending <= 0',
          ['PAID', allocation.billingCycleId],
        );
      }

      return paymentWithNumber;
    });

    // Trigger backup if enabled
    await _checkAndTriggerBackup(await _databaseHelper.database);

    return result;
  }

  /// Insert simple payment (no allocations)
  Future<Payment> insertPayment(Payment payment) async {
    final db = await _databaseHelper.database;
    final result = await db.transaction((txn) async {
      // 1. Get next receipt number
      final settingsResult = await txn.query(
        'app_settings',
        columns: ['receipt_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );
      final nextNumber =
          settingsResult.first['receipt_next_number']?.toString() ?? '1';

      // 2. Assign to payment
      final paymentWithNumber = payment.copyWith(receiptNumber: nextNumber);

      // 3. Insert
      await txn.insert(
        'payments',
        paymentWithNumber.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Increment setting
      final newNextNumber = incrementStringCode(nextNumber);
      await txn.rawUpdate(
        'UPDATE app_settings SET receipt_next_number = ?, updated_at = ? WHERE settings_id = ?',
        [newNextNumber, DateTime.now().toIso8601String(), 'global'],
      );

      return paymentWithNumber;
    });

    // Trigger backup if enabled
    await _checkAndTriggerBackup(await _databaseHelper.database);

    return result;
  }

  /// Void payment with deep reversal logic
  /// Reverses allocations and creates credit ledger entry
  Future<int> voidPayment(String paymentId, String reason) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 1. Get the payment details
      final paymentResult = await txn.query(
        'payments',
        where: 'payment_id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );
      if (paymentResult.isEmpty) return 0;

      final payment = Payment.fromMap(paymentResult.first);
      if (payment.status == 'VOIDED') return 0; // Already voided

      // 2. Get loan info to find customer
      final loanResult = await txn.query(
        'loans',
        columns: ['customer_id', 'principal_balance'],
        where: 'loan_id = ?',
        whereArgs: [payment.loanId],
        limit: 1,
      );
      final customerId = loanResult.isNotEmpty
          ? loanResult.first['customer_id'] as String
          : '';

      // 3. Get allocations to reverse
      final allocations = await txn.query(
        'payment_allocations',
        where: 'payment_id = ?',
        whereArgs: [paymentId],
      );

      // 4. Reverse principal allocations (add back to loan balance)
      int principalReversed = 0;
      for (final alloc in allocations) {
        if (alloc['allocation_type'] == 'PRINCIPAL') {
          final amount = alloc['amount_loan_minor'] as int;
          principalReversed += amount;
        }
      }

      if (principalReversed > 0) {
        await txn.rawUpdate(
          'UPDATE loans SET principal_balance = principal_balance + ?, updated_at = ? WHERE loan_id = ?',
          [
            principalReversed / 100.0,
            DateTime.now().toIso8601String(),
            payment.loanId,
          ],
        );
      }

      // 5. Reverse interest allocations (add back to billing cycles)
      for (final alloc in allocations) {
        if (alloc['allocation_type'] == 'INTEREST' &&
            alloc['billing_cycle_id'] != null) {
          final amount = alloc['amount_loan_minor'] as int;
          await txn.rawUpdate(
            'UPDATE billing_cycles SET interest_paid = interest_paid - ?, interest_pending = interest_pending + ?, status = ?, updated_at = ? WHERE billing_cycle_id = ?',
            [
              amount / 100.0,
              amount / 100.0,
              'PENDING',
              DateTime.now().toIso8601String(),
              alloc['billing_cycle_id'],
            ],
          );
        }
      }

      // 6. Create credit ledger entry for void reversal
      if (customerId.isNotEmpty) {
        final ledgerEntry = ClientCreditLedger(
          entryId: const Uuid().v4(),
          customerId: customerId,
          referencePaymentId: paymentId,
          transactionType: 'VOID_REVERSAL',
          amountMinor: -payment.amountLoanMinor, // Negative = debit
          createdAt: DateTime.now(),
        );
        await txn.insert('client_credits_ledger', ledgerEntry.toMap());
      }

      // 7. Mark payment as voided
      final updateCount = await txn.update(
        'payments',
        {
          'status': 'VOIDED',
          'void_reason_key': reason,
          'voided_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'payment_id = ?',
        whereArgs: [paymentId],
      );

      return updateCount;
    });
  }

  /// Update exchange profit
  Future<int> updateExchangeProfit(String paymentId, double profit) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'payments',
      {
        'exchange_profit': profit,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'payment_id = ?',
      whereArgs: [paymentId],
    );
  }

  /// Get next receipt number
  Future<String> getNextReceiptNumber() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT receipt_next_number FROM app_settings WHERE settings_id = ?',
      ['global'],
    );
    return result.first['receipt_next_number']?.toString() ?? '1';
  }

  /// Get payment allocations
  Future<List<PaymentAllocation>> getPaymentAllocations(
    String paymentId,
  ) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'payment_allocations',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
    );
    return maps.map((map) => PaymentAllocation.fromMap(map)).toList();
  }

  /// Get all allocations for a specific loan (for statement report)
  /// V25: payment_allocations no longer has loan_id, must JOIN through payments
  Future<List<PaymentAllocation>> getAllAllocationsForLoan(
    String loanId,
  ) async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT pa.*
      FROM payment_allocations pa
      INNER JOIN payments p ON pa.payment_id = p.payment_id
      WHERE p.loan_id = ? AND p.status = 'VALID'
      ORDER BY pa.created_at ASC
    ''',
      [loanId],
    );
    return maps.map((map) => PaymentAllocation.fromMap(map)).toList();
  }

  /// Get total collected today
  /// Returns the sum of amounts applied to loans (in loan currency)
  /// This excludes any unapplied FX differential
  Future<double> getTotalCollectedToday() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount_loan_minor - COALESCE(unapplied_minor, 0)) / 100.0 as total 
      FROM payments 
      WHERE date(created_at) = date(?) AND status = ?
      ''',
      [today, 'VALID'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total collected today grouped by currency (loan currency)
  /// Returns amounts applied to loans, excluding FX differential
  Future<Map<String, double>> getTotalCollectedTodayByCurrency() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT p.loan_currency, 
             COALESCE(SUM(p.amount_loan_minor - COALESCE(p.unapplied_minor, 0)), 0) / 100.0 as total
      FROM payments p
      WHERE date(p.created_at) = date(?) AND p.status = 'VALID'
      GROUP BY p.loan_currency
    ''',
      [today],
    );

    final Map<String, double> totals = {};
    for (final row in result) {
      final currency = row['loan_currency'] as String? ?? 'NIO';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[currency] = total;
    }
    return totals;
  }

  /// Get capital (principal) recovered today
  Future<double> getCapitalRecoveredToday() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(pa.amount_loan_minor), 0) / 100.0 as total
      FROM payment_allocations pa
      INNER JOIN payments p ON pa.payment_id = p.payment_id
      WHERE date(p.created_at) = date(?) AND p.status = 'VALID' AND pa.allocation_type = 'PRINCIPAL'
    ''',
      [today],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get capital recovered today grouped by currency
  Future<Map<String, double>> getCapitalRecoveredTodayByCurrency() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT l.currency_code, COALESCE(SUM(pa.amount_loan_minor), 0) / 100.0 as total
      FROM payment_allocations pa
      INNER JOIN payments p ON pa.payment_id = p.payment_id
      INNER JOIN loans l ON p.loan_id = l.loan_id
      WHERE date(p.created_at) = date(?) AND p.status = 'VALID' AND pa.allocation_type = 'PRINCIPAL'
      GROUP BY l.currency_code
    ''',
      [today],
    );

    final Map<String, double> totals = {};
    for (final row in result) {
      final currency = row['currency_code'] as String? ?? 'NIO';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[currency] = total;
    }
    return totals;
  }

  /// Get total collected in date range
  Future<double> getTotalCollectedInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount_payment_minor) / 100.0 as total FROM payments WHERE date(created_at) >= date(?) AND date(created_at) <= date(?) AND status = ?',
      [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
        'VALID',
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get payment count
  Future<int> getPaymentCount({String? status}) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      status != null
          ? 'SELECT COUNT(*) as count FROM payments WHERE status = ?'
          : 'SELECT COUNT(*) as count FROM payments',
      status != null ? [status] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get realized earnings (Interest + Fees) in date range
  Future<double> getRealizedEarnings({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseHelper.database;
    // Use date() function to compare only date parts, ignoring time
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(pa.amount_loan_minor), 0) / 100.0 as total
      FROM payment_allocations pa
      INNER JOIN payments p ON pa.payment_id = p.payment_id
      WHERE p.created_at >= ? AND p.created_at <= ? 
        AND p.status = 'VALID' 
        AND pa.allocation_type IN ('INTEREST', 'MORA', 'FEES')
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get realized earnings (Interest + Fees) in date range grouped by currency
  Future<Map<String, double>> getRealizedEarningsByCurrency({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT l.currency_code, COALESCE(SUM(pa.amount_loan_minor), 0) / 100.0 as total
      FROM payment_allocations pa
      INNER JOIN payments p ON pa.payment_id = p.payment_id
      INNER JOIN loans l ON p.loan_id = l.loan_id
      WHERE p.created_at >= ? AND p.created_at <= ? 
        AND p.status = 'VALID' 
        AND pa.allocation_type IN ('INTEREST', 'MORA', 'FEES')
      GROUP BY l.currency_code
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final Map<String, double> totals = {};
    for (final row in result) {
      final currency = row['currency_code'] as String? ?? 'NIO';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[currency] = total;
    }
    return totals;
  }

  /// Get max receipt number
  Future<String?> getMaxReceiptNumber() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(receipt_number) as max_number FROM payments',
    );
    return result.first['max_number']?.toString();
  }

  /// Register recovery payment (Capital only), close loan, and optionally restrict customer
  Future<Payment> registerRecoveryPayment({
    required Payment payment,
    required List<PaymentAllocation> allocations,
    required bool restrictCustomer,
    required String? restrictionReason,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.transaction((txn) async {
      // 1. Get next receipt number
      final settingsResult = await txn.query(
        'app_settings',
        columns: ['receipt_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );
      final nextNumber =
          settingsResult.first['receipt_next_number']?.toString() ?? '1';
      final paymentWithNumber = payment.copyWith(receiptNumber: nextNumber);

      // 2. Insert payment
      await txn.insert('payments', paymentWithNumber.toMap());

      // 3. Increment receipt number
      final newNextNumber = incrementStringCode(nextNumber);
      await txn.rawUpdate(
        'UPDATE app_settings SET receipt_next_number = ?, updated_at = ? WHERE settings_id = ?',
        [newNextNumber, DateTime.now().toIso8601String(), 'global'],
      );

      // 4. Insert allocations
      for (final allocation in allocations) {
        await txn.insert('payment_allocations', allocation.toMap());
      }

      // 5. Update loan - DEDUCT Principal
      final principalAllocation = allocations
          .where((a) => a.allocationType == 'PRINCIPAL')
          .fold<double>(0, (sum, a) => sum + a.amount);

      if (principalAllocation > 0) {
        await txn.rawUpdate(
          'UPDATE loans SET principal_balance = principal_balance - ?, updated_at = ? WHERE loan_id = ?',
          [
            principalAllocation,
            DateTime.now().toIso8601String(),
            payment.loanId,
          ],
        );
      }

      // 6. FORCE CLOSE LOAN (Recovered/Cancelled)
      await txn.rawUpdate(
        'UPDATE loans SET status = ?, closed_at = ?, updated_at = ? WHERE loan_id = ?',
        [
          'CLOSED', // Using CLOSED as standard for finished loans
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
          payment.loanId,
        ],
      );

      // 7. FORCE CLOSE/ANNUL CYCLES
      // "Cancelar el prestamo sin considerar los intereses"
      await txn.rawUpdate(
        'UPDATE billing_cycles SET status = ?, interest_pending = 0, closed_at = ?, updated_at = ? WHERE loan_id = ? AND status != ?',
        [
          'ANULLED',
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
          payment.loanId,
          'PAID', // Don't touch already paid cycles
        ],
      );

      // 8. RESTRICT CUSTOMER
      if (restrictCustomer) {
        await txn.rawUpdate(
          'UPDATE customers SET is_restricted = 1, restriction_reason = ?, updated_at = ? WHERE customer_id = ?',
          [
            restrictionReason ?? 'Restringido por recuperación de capital',
            DateTime.now().toIso8601String(),
            payment.customerId,
          ],
        );
      }

      return paymentWithNumber;
    });

    // Trigger backup if enabled
    await _checkAndTriggerBackup(await _databaseHelper.database);

    return result;
  }

  /// Helper to check and trigger auto-backup
  Future<void> _checkAndTriggerBackup(Database db) async {
    try {
      final settingsResult = await db.query(
        'app_settings',
        columns: ['backup_on_payment', 'backup_custom_name'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );

      if (settingsResult.isNotEmpty) {
        final shouldBackup =
            (settingsResult.first['backup_on_payment'] as int? ?? 0) == 1;
        if (shouldBackup) {
          final customName =
              settingsResult.first['backup_custom_name'] as String?;
          // Run in background
          // ignore: unawaited_futures
          BackupService.instance.createBackup(customName: customName);
        }
      }
    } catch (_) {
      // Ignore backup errors
    }
  }
}
