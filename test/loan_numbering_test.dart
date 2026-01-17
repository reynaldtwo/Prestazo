import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/core/utils/string_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests for loan numbering system
///
/// These tests verify the sequential numbering logic for loans
/// using an in-memory SQLite database.
void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Use in-memory database for testing
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create minimal schema for loan numbering tests
    await db.execute('''
      CREATE TABLE app_settings (
        settings_id TEXT PRIMARY KEY,
        loan_next_number TEXT DEFAULT '1',
        receipt_next_number TEXT DEFAULT '1',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        loan_id TEXT PRIMARY KEY,
        customer_id TEXT,
        loan_number TEXT,
        principal_original REAL,
        principal_balance REAL,
        monthly_interest_rate REAL,
        status TEXT,
        billing_frequency TEXT DEFAULT 'MONTHLY',
        disbursement_date TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Insert default settings
    await db.insert('app_settings', {
      'settings_id': 'global',
      'loan_next_number': '100',
      'receipt_next_number': '1',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('Loan Numbering', () {
    test('should start with configured initial number', () async {
      final result = await db.query(
        'app_settings',
        columns: ['loan_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );

      expect(result.first['loan_next_number'], '100');
    });

    test('should increment loan number after insert', () async {
      // Simulate inserting a loan with number assignment
      const currentNumber = '100';
      final nextNumber = incrementStringCode(currentNumber);

      // Insert loan with current number
      await db.insert('loans', {
        'loan_id': 'test-loan-1',
        'customer_id': 'test-customer',
        'loan_number': currentNumber,
        'principal_original': 1000.0,
        'principal_balance': 1000.0,
        'monthly_interest_rate': 10.0,
        'status': 'ACTIVE',
        'disbursement_date': DateTime.now().toIso8601String().split('T')[0],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update settings to next number
      await db.update(
        'app_settings',
        {'loan_next_number': nextNumber},
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );

      // Verify loan has correct number
      final loanResult = await db.query(
        'loans',
        where: 'loan_id = ?',
        whereArgs: ['test-loan-1'],
      );
      expect(loanResult.first['loan_number'], '100');

      // Verify next number was incremented
      final settingsResult = await db.query(
        'app_settings',
        columns: ['loan_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );
      expect(settingsResult.first['loan_next_number'], '101');
    });

    test('should support alphanumeric loan numbers', () async {
      // Update to alphanumeric format
      await db.update(
        'app_settings',
        {'loan_next_number': 'PREST-001'},
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );

      final result = await db.query(
        'app_settings',
        columns: ['loan_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );

      final currentNumber = result.first['loan_next_number']! as String;
      final nextNumber = incrementStringCode(currentNumber);

      expect(nextNumber, 'PREST-002');
    });
  });

  group('Receipt Numbering', () {
    test('should maintain separate receipt counter', () async {
      final result = await db.query(
        'app_settings',
        columns: ['receipt_next_number'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );

      expect(result.first['receipt_next_number'], '1');
    });
  });
}
