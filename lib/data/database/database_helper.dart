import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' as io;
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import '../../core/constants/app_status.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _ffiInitialized = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        AppConstants.databaseName,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    }

    if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationSupportDirectory();
    // Create directory if it doesn't exist (AppSupport might not exist yet)
    await io.Directory(documentsDirectory.path).create(recursive: true);
    final path = join(documentsDirectory.path, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database (enable foreign keys, WAL mode, busy timeout)
  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      debugPrint('Error setting foreign_keys: $e');
    }

    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (e) {
      debugPrint('Error setting journal_mode: $e');
    }

    try {
      await db.execute('PRAGMA busy_timeout = 5000');
    } catch (e) {
      debugPrint('Error setting busy_timeout: $e');
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // AppSettings table
    await db.execute('''
      CREATE TABLE app_settings (
        settings_id TEXT PRIMARY KEY DEFAULT 'global',
        base_currency TEXT NOT NULL DEFAULT 'NIO',
        capitalize_unpaid_interest INTEGER NOT NULL DEFAULT 0,
        moratorium_days INTEGER NOT NULL DEFAULT 1,
        payment_apply_order TEXT NOT NULL DEFAULT 'INTEREST_FIRST',
        derive_biweekly_rate INTEGER NOT NULL DEFAULT 1,
        receipt_next_number INTEGER NOT NULL DEFAULT 1,
        available_capital REAL NOT NULL DEFAULT 0,
        validate_capital INTEGER NOT NULL DEFAULT 0,
        daily_accrual_enabled INTEGER NOT NULL DEFAULT 0,
        allow_multiple_loans INTEGER NOT NULL DEFAULT 0,
        loan_next_number INTEGER NOT NULL DEFAULT 1,
        company_name TEXT,
        show_company_name INTEGER NOT NULL DEFAULT 0,
        company_ruc TEXT,
        show_company_ruc INTEGER NOT NULL DEFAULT 0,
        company_phone TEXT,
        show_company_phone INTEGER NOT NULL DEFAULT 0,
        company_cell TEXT,
        show_company_cell INTEGER NOT NULL DEFAULT 0,
        company_whatsapp TEXT,
        show_company_whatsapp INTEGER NOT NULL DEFAULT 0,
        company_address TEXT,
        show_company_address INTEGER NOT NULL DEFAULT 0,
        company_logo_path TEXT,
        show_company_logo INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customer table
    await db.execute('''
      CREATE TABLE customers (
        customer_id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        alias TEXT,
        phone TEXT,
        address TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        billing_frequency TEXT NOT NULL,
        preferred_pay_day INTEGER,
        dni TEXT,
        coords TEXT,
        is_restricted INTEGER DEFAULT 0,
        restriction_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Loan table
    await db.execute('''
      CREATE TABLE loans (
        loan_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        principal_original REAL NOT NULL,
        principal_balance REAL NOT NULL,
        monthly_interest_rate REAL NOT NULL,
        rate_unit TEXT NOT NULL DEFAULT 'MONTHLY',
        billing_frequency TEXT NOT NULL DEFAULT 'MONTHLY',
        disbursement_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        closed_at TEXT,
        notes TEXT,
        loan_number INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
      )
    ''');

    // BillingCycle table
    await db.execute('''
      CREATE TABLE billing_cycles (
        billing_cycle_id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        cycle_number INTEGER NOT NULL,
        frequency TEXT NOT NULL,
        period_start_date TEXT NOT NULL,
        period_end_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        interest_expected REAL NOT NULL DEFAULT 0,
        interest_paid REAL NOT NULL DEFAULT 0,
        interest_pending REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PENDING',
        closed_at TEXT,
        is_capitalized INTEGER NOT NULL DEFAULT 0,
        capitalized_amount REAL NOT NULL DEFAULT 0,
        capitalized_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT
      )
    ''');

    // Payment table
    await db.execute('''
      CREATE TABLE payments (
        payment_id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        amount REAL NOT NULL,
        declared_type TEXT NOT NULL DEFAULT 'MIXED',
        receipt_number INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'VALID',
        void_reason TEXT,
        voided_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
      )
    ''');

    // PaymentAllocation table
    await db.execute('''
      CREATE TABLE payment_allocations (
        allocation_id TEXT PRIMARY KEY,
        payment_id TEXT NOT NULL,
        loan_id TEXT NOT NULL,
        allocation_type TEXT NOT NULL,
        amount REAL NOT NULL,
        billing_cycle_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT,
        FOREIGN KEY (billing_cycle_id) REFERENCES billing_cycles(billing_cycle_id) ON DELETE RESTRICT
      )
    ''');

    // LoanEvent table
    await db.execute('''
      CREATE TABLE loan_events (
        loan_event_id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        related_billing_cycle_id TEXT,
        related_payment_id TEXT,
        amount REAL,
        old_value TEXT,
        new_value TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT
      )
    ''');

    // AuditLog table
    await db.execute('''
      CREATE TABLE audit_logs (
        audit_log_id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await _createIndexes(db);

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    // Customer indexes
    await db.execute(
      'CREATE INDEX idx_customer_frequency_status ON customers(billing_frequency, status)',
    );
    await db.execute('CREATE INDEX idx_customer_name ON customers(full_name)');

    // Loan indexes
    await db.execute(
      'CREATE INDEX idx_loan_customer_status ON loans(customer_id, status)',
    );
    await db.execute('CREATE INDEX idx_loan_status ON loans(status)');

    // BillingCycle indexes
    await db.execute(
      'CREATE UNIQUE INDEX uq_billing_cycle_loan_due ON billing_cycles(loan_id, due_date)',
    );
    await db.execute(
      'CREATE INDEX idx_billing_cycle_loan_status ON billing_cycles(loan_id, status)',
    );
    await db.execute(
      'CREATE INDEX idx_billing_cycle_due_status ON billing_cycles(due_date, status)',
    );

    // Payment indexes
    await db.execute(
      'CREATE INDEX idx_payment_loan_date ON payments(loan_id, payment_date)',
    );
    await db.execute(
      'CREATE INDEX idx_payment_customer_date ON payments(customer_id, payment_date)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX uq_payment_receipt ON payments(receipt_number)',
    );

    // PaymentAllocation indexes
    await db.execute(
      'CREATE INDEX idx_allocation_payment ON payment_allocations(payment_id)',
    );
    await db.execute(
      'CREATE INDEX idx_allocation_cycle ON payment_allocations(billing_cycle_id)',
    );
    await db.execute(
      'CREATE INDEX idx_allocation_loan ON payment_allocations(loan_id)',
    );

    // LoanEvent indexes
    await db.execute(
      'CREATE INDEX idx_loan_event_loan_date ON loan_events(loan_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_loan_event_type ON loan_events(event_type)',
    );

    // AuditLog indexes
    await db.execute(
      'CREATE INDEX idx_audit_action_date ON audit_logs(action, created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id)',
    );
  }

  /// Insert default settings
  Future<void> _insertDefaultSettings(Database db) async {
    final settings = AppSettings.defaults();
    await db.insert('app_settings', settings.toMap());
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from v1 to v2: Add available_capital column
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN available_capital REAL NOT NULL DEFAULT 0',
      );
      // Update moratorium_days default to 1 for existing users
      await db.execute(
        'UPDATE app_settings SET moratorium_days = 1 WHERE moratorium_days = 7',
      );
    }
    // Migration from v2 to v3: Add validate_capital column
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN validate_capital INTEGER NOT NULL DEFAULT 0',
      );
    }
    // Migration from v3 to v4: Add daily_accrual_enabled column
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN daily_accrual_enabled INTEGER NOT NULL DEFAULT 0',
      );
    }
    // Migration from v5 to v6: Add allow_multiple_loans column
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN allow_multiple_loans INTEGER NOT NULL DEFAULT 0',
      );
    }
    // Migration from v6 to v7: Add billing_frequency and end_date to loans
    if (oldVersion < 7) {
      await db.execute(
        "ALTER TABLE loans ADD COLUMN billing_frequency TEXT NOT NULL DEFAULT 'MONTHLY'",
      );
      await db.execute('ALTER TABLE loans ADD COLUMN end_date TEXT');
    }
    // Migration from v7 to v8: Add loan_number and loan_next_number
    if (oldVersion < 8) {
      // Add loan_next_number to app_settings
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN loan_next_number INTEGER NOT NULL DEFAULT 1',
      );

      // Add loan_number to loans
      await db.execute('ALTER TABLE loans ADD COLUMN loan_number INTEGER');

      // Populate existing loan numbers sequentially by creation date
      final loans = await db.query('loans', orderBy: 'created_at ASC');
      int currentNumber = 1;

      for (final loan in loans) {
        await db.update(
          'loans',
          {'loan_number': currentNumber},
          where: 'loan_id = ?',
          whereArgs: [loan['loan_id']],
        );
        currentNumber++;
      }

      // Update next number setting
      await db.update('app_settings', {
        'loan_next_number': currentNumber,
      }, where: "settings_id = 'global'");
    }
    // Migration from v8 to v9: Add dni and coords to customers
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE customers ADD COLUMN dni TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN coords TEXT');
    }
    // Migration from v9 to v10: Add company settings + Repair DNI/Coords if missing
    if (oldVersion < 10) {
      // Safe add dni/coords if they were missed in a broken v9 state
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN dni TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN coords TEXT');
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_name TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_name INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_ruc TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_ruc INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_phone TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_phone INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_cell TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_cell INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_whatsapp TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_whatsapp INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_address TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_address INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_logo_path TEXT',
        );
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_company_logo INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        // Ignore if columns already exist (though unexpected for v10 columns)
      }
    }
    // Migration from v10 to v11 (Recovery features)
    if (oldVersion < 11) {
      try {
        await db.execute(
          'ALTER TABLE customers ADD COLUMN is_restricted INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE customers ADD COLUMN restriction_reason TEXT',
        );
      } catch (_) {}
    }
    // Run data fix on upgrade
    await fixInterestCalculations();
  }

  /// Fix billing cycles with incorrectly calculated interest (100x too high)
  /// Call this method to repair data from the interest calculation bug
  Future<int> fixInterestCalculations() async {
    final db = await database;
    int fixedCount = 0;

    final cycles = await db.rawQuery('''
      SELECT bc.billing_cycle_id, bc.interest_expected, bc.interest_paid, bc.interest_pending,
             l.principal_balance, l.monthly_interest_rate, c.billing_frequency
      FROM billing_cycles bc
      INNER JOIN loans l ON bc.loan_id = l.loan_id
      INNER JOIN customers c ON l.customer_id = c.customer_id
      WHERE bc.status IN ('${AppStatus.cyclePending}', '${AppStatus.cyclePartial}')
    ''');

    for (final cycle in cycles) {
      final billingCycleId = cycle['billing_cycle_id'] as String;
      final currentExpected = (cycle['interest_expected'] as num).toDouble();
      final interestPaid = (cycle['interest_paid'] as num).toDouble();
      final principalBalance = (cycle['principal_balance'] as num).toDouble();
      final monthlyRate = (cycle['monthly_interest_rate'] as num).toDouble();
      final frequency = cycle['billing_frequency'] as String;

      // Calculate correct interest (rate as decimal)
      double correctInterest;
      if (frequency == 'BIWEEKLY') {
        correctInterest = principalBalance * (monthlyRate / 2 / 100);
      } else {
        correctInterest = principalBalance * (monthlyRate / 100);
      }
      correctInterest = (correctInterest * 100).round() / 100;

      // Only update if current value seems to be 100x too high
      if (currentExpected > correctInterest * 50 && correctInterest > 0) {
        final correctPending = (correctInterest - interestPaid).clamp(
          0.0,
          correctInterest,
        );

        await db.update(
          'billing_cycles',
          {
            'interest_expected': correctInterest,
            'interest_pending': correctPending,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'billing_cycle_id = ?',
          whereArgs: [billingCycleId],
        );
        fixedCount++;
      }
    }

    return fixedCount;
  }

  /// Close database
  /// Close database
  Future<void> close() async {
    if (_database != null) {
      if (_database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    }
  }

  /// Force WAL checkpoint to merge data into the main file
  Future<void> checkpoint() async {
    try {
      final db = await database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    } catch (e) {
      debugPrint('Error checkpointing WAL: $e');
    }
  }

  /// Get database path (for backup)
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, AppConstants.databaseName);
  }

  /// Delete all data (for testing)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('audit_logs');
      await txn.delete('loan_events');
      await txn.delete('payment_allocations');
      await txn.delete('payments');
      await txn.delete('billing_cycles');
      await txn.delete('loans');
      await txn.delete('customers');
      // Delete settings to reset consecutive numbers
      await txn.delete('app_settings');
      // Re-insert defaults to prevent UI breakage
      await txn.insert('app_settings', AppSettings.defaults().toMap());
    });
  }

  /// Delete only payments and reset loans/cycles status
  Future<void> deletePaymentsOnly() async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Delete payment related data
      await txn.delete('payment_allocations');
      await txn.delete('payments');
      await txn.delete('loan_events'); // Events often relate to payments
      await txn.delete('audit_logs');

      // 2. Reset Billing Cycles
      // - interest_paid -> 0
      // - interest_pending -> interest_expected
      // - closed_at -> NULL
      // - status -> OVERDUE if older than today, else PENDING
      await txn.rawUpdate(
        '''
        UPDATE billing_cycles 
        SET interest_paid = 0,
            interest_pending = interest_expected,
            closed_at = NULL,
            status = CASE 
              WHEN due_date < date('now') THEN '${AppStatus.cycleOverdue}'
              ELSE '${AppStatus.cyclePending}'
            END,
            updated_at = ?
      ''',
        [DateTime.now().toIso8601String()],
      );

      // 3. Reset Loans
      // - principal_balance -> principal_original
      // - closed_at -> NULL
      // - status -> IN_MORA if any overdue cycle exists, else ACTIVE
      await txn.rawUpdate(
        '''
        UPDATE loans
        SET principal_balance = principal_original,
            closed_at = NULL,
            status = CASE 
              WHEN EXISTS (
                SELECT 1 FROM billing_cycles bc 
                WHERE bc.loan_id = loans.loan_id 
                AND bc.status = '${AppStatus.cycleOverdue}'
              ) THEN '${AppStatus.loanOverdue}'
              ELSE '${AppStatus.loanActive}'
            END,
            updated_at = ?
      ''',
        [DateTime.now().toIso8601String()],
      );
    });
  }

  /// Delete loans and all related data (cycles, payments)
  Future<void> deleteLoansAndRelated() async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete children first
      await txn.delete('payment_allocations');
      await txn.delete('payments');
      await txn.delete('billing_cycles');
      await txn.delete('loan_events');
      await txn.delete('audit_logs');
      await txn.delete('loans');
    });
  }

  /// Delete customers and all related data
  Future<void> deleteCustomersAndRelated() async {
    final db = await database;
    // Check for active loans effectively handled by "delete related" logic
    // but user requirement says: "if at least 1 customer has active loans, then cannot, but indicate..."
    // This check should ideally happen in UI or repository before calling this.
    // But if we force delete "Customers", we must delete loans too due to FKs.
    // So this method effectively wipes everything except settings.

    await db.transaction((txn) async {
      await txn.delete('payment_allocations');
      await txn.delete('payments');
      await txn.delete('billing_cycles');
      await txn.delete('loan_events');
      await txn.delete('audit_logs');
      await txn.delete('loans');
      await txn.delete('customers');
    });
  }

  Future<bool> hasActiveLoans() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM loans WHERE status = '${AppStatus.loanActive}' OR status = '${AppStatus.loanOverdue}'",
      ),
    );
    return (count ?? 0) > 0;
  }
}
