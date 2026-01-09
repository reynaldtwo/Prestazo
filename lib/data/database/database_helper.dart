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

  static bool _isMaintenanceMode = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Set maintenance mode (true to block DB access, false to resume)
  void setMaintenanceMode(bool enabled) {
    _isMaintenanceMode = enabled;
  }

  /// Get database instance
  Future<Database> get database async {
    if (_isMaintenanceMode) {
      throw Exception('Database is in maintenance mode');
    }
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

    final path = await getDatabasePath();
    final file = io.File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
    );
  }

  /// Called every time the database is opened - ensures all columns exist
  Future<void> _onOpen(Database db) async {
    debugPrint('Database opened, checking for missing columns...');

    // Check and add share_receipts_whatsapp column if missing
    try {
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='share_receipts_whatsapp'",
      );
      final hasColumn = (result.first['cnt'] as int) > 0;
      if (!hasColumn) {
        debugPrint('Adding missing column: share_receipts_whatsapp');
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN share_receipts_whatsapp INTEGER DEFAULT 0',
        );
      }
    } catch (e) {
      debugPrint('Error checking/adding share_receipts_whatsapp: $e');
    }

    // Check and add backup_path column if missing
    try {
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='backup_path'",
      );
      final hasColumn = (result.first['cnt'] as int) > 0;
      if (!hasColumn) {
        debugPrint('Adding missing column: backup_path');
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_path TEXT',
        );
      }
    } catch (e) {
      debugPrint('Error checking/adding backup_path: $e');
    }

    // Check and add new report settings columns (v15)
    final v15Columns = [
      {'name': 'show_disbursement_signatures', 'def': 'INTEGER DEFAULT 1'},
      {'name': 'show_payment_signatures', 'def': 'INTEGER DEFAULT 1'},
      {'name': 'disbursement_legend', 'def': 'TEXT'},
      {'name': 'show_disbursement_legend', 'def': 'INTEGER DEFAULT 0'},
      {'name': 'payment_legend', 'def': 'TEXT'},
      {'name': 'show_payment_legend', 'def': 'INTEGER DEFAULT 0'},
    ];

    for (final col in v15Columns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: ${col['name']}');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']}: $e');
      }
    }

    // Check and add capital restriction settings columns (v16)
    final v16Columns = [
      {'name': 'enable_capital_restriction', 'def': 'INTEGER DEFAULT 1'},
      {'name': 'capital_restriction_days', 'def': 'INTEGER DEFAULT 10'},
    ];

    for (final col in v16Columns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: ${col['name']}');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']}: $e');
      }
    }

    // Check and add currency_code column to loans table if missing
    try {
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('loans') WHERE name='currency_code'",
      );
      final hasColumn = (result.first['cnt'] as int) > 0;
      if (!hasColumn) {
        debugPrint('Adding missing column to loans: currency_code');
        await db.execute(
          "ALTER TABLE loans ADD COLUMN currency_code TEXT DEFAULT 'NIO'",
        );
      }
    } catch (e) {
      debugPrint('Error checking/adding currency_code to loans: $e');
    }

    // Check and add report currency settings columns if missing
    final reportCurrencyColumns = [
      {'name': 'report_currency', 'def': "TEXT DEFAULT 'NIO'"},
      {'name': 'exchange_rate', 'def': 'REAL DEFAULT 1.0'},
    ];

    for (final col in reportCurrencyColumns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: ${col['name']}');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']}: $e');
      }
    }

    // Check and add scheduled backup columns (v18)
    final backupColumns = [
      {'name': 'backup_frequency', 'def': "TEXT DEFAULT 'NONE'"},
      {'name': 'backup_retention_days', 'def': 'INTEGER DEFAULT 30'},
      {'name': 'backup_on_loan_creation', 'def': 'INTEGER DEFAULT 0'},
      {'name': 'backup_on_payment', 'def': 'INTEGER DEFAULT 0'},
      {'name': 'backup_schedule_time', 'def': 'TEXT'},
      {'name': 'backup_custom_name', 'def': 'TEXT'},
      {'name': 'backup_retries', 'def': 'INTEGER DEFAULT 3'},
    ];

    for (final col in backupColumns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: ${col['name']}');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']}: $e');
      }
    }

    // Check and add company_country_code column (v20)
    try {
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='company_country_code'",
      );
      final hasColumn = (result.first['cnt'] as int) > 0;
      if (!hasColumn) {
        debugPrint('Adding missing column: company_country_code');
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_country_code TEXT',
        );
      }
    } catch (e) {
      debugPrint('Error checking/adding company_country_code: $e');
    }

    // Check and add rate type columns (v22)
    final rateTypeColumns = [
      {'name': 'disbursement_rate_type', 'def': "TEXT DEFAULT 'SELL'"},
      {'name': 'payment_rate_type', 'def': "TEXT DEFAULT 'BUY'"},
    ];

    for (final col in rateTypeColumns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: ${col['name']}');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']}: $e');
      }
    }

    // Check and add allow_manual_exchange_rate column (v23)
    try {
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='allow_manual_exchange_rate'",
      );
      final hasColumn = (result.first['cnt'] as int) > 0;
      if (!hasColumn) {
        debugPrint('Adding missing column: allow_manual_exchange_rate');
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN allow_manual_exchange_rate INTEGER NOT NULL DEFAULT 0',
        );
      }
    } catch (e) {
      debugPrint('Error checking/adding allow_manual_exchange_rate: $e');
    }

    // Check and add payment currency columns (v24)
    final paymentColumns = [
      {'name': 'payment_currency', 'def': 'TEXT'},
      {'name': 'exchange_rate_applied', 'def': 'REAL'},
      {'name': 'exchange_profit', 'def': 'REAL'},
    ];

    for (final col in paymentColumns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('payments') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column to payments: ${col['name']}');
          await db.execute(
            'ALTER TABLE payments ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']} to payments: $e');
      }
    }

    // Auto-create exchange_rates table if missing (v21)
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='exchange_rates'",
      );
      if (result.isEmpty) {
        debugPrint('Creating missing table: exchange_rates');
        await db.execute('''
          CREATE TABLE exchange_rates (
            rate_id TEXT PRIMARY KEY,
            source_currency TEXT NOT NULL,
            target_currency TEXT NOT NULL,
            rate_date TEXT NOT NULL,
            buy_rate REAL NOT NULL,
            sell_rate REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX uq_exchange_rate_pair_date ON exchange_rates(source_currency, target_currency, rate_date)',
        );
      }
    } catch (e) {
      debugPrint('Error checking/creating exchange_rates table: $e');
    }

    // Auto-add loans columns if missing (v21)
    final loanColumns = [
      {'name': 'currency_code', 'def': "TEXT DEFAULT 'NIO'"},
      {'name': 'applied_exchange_rate', 'def': 'REAL'},
    ];

    for (final col in loanColumns) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('loans') WHERE name='${col['name']}'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column to loans: ${col['name']}');
          await db.execute(
            'ALTER TABLE loans ADD COLUMN ${col['name']} ${col['def']}',
          );
        }
      } catch (e) {
        debugPrint('Error checking/adding ${col['name']} to loans: $e');
      }
    }
    // V25 Schema Repair: Ensure payments table has _minor columns
    try {
      final paymentsInfo = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('payments') WHERE name='amount_payment_minor'",
      );
      final hasMinorColumn = (paymentsInfo.first['cnt'] as int) > 0;

      if (!hasMinorColumn) {
        debugPrint(
          'CRITICAL: V25 Schema missing in payments table. Triggering Repair.',
        );
        // We will attempt to run the migration logic manually
        await _performV25Migration(db);
      }
    } catch (e) {
      debugPrint('Error repairing V25 schema: $e');
    }
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
        validate_dni INTEGER NOT NULL DEFAULT 0,
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
        backup_path TEXT,
        share_receipts_whatsapp INTEGER NOT NULL DEFAULT 0,
        show_disbursement_signatures INTEGER NOT NULL DEFAULT 1,
        show_payment_signatures INTEGER NOT NULL DEFAULT 1,
        disbursement_legend TEXT,
        show_disbursement_legend INTEGER NOT NULL DEFAULT 0,
        payment_legend TEXT,
        show_payment_legend INTEGER NOT NULL DEFAULT 0,
        enable_capital_restriction INTEGER NOT NULL DEFAULT 1,
        capital_restriction_days INTEGER NOT NULL DEFAULT 10,
        validate_dni_format INTEGER NOT NULL DEFAULT 0,
        dni_mask TEXT,
        report_currency TEXT NOT NULL DEFAULT 'NIO',
        exchange_rate REAL NOT NULL DEFAULT 1.0,
        backup_frequency TEXT DEFAULT 'NONE',
        backup_retention_days INTEGER DEFAULT 30,
        backup_on_loan_creation INTEGER DEFAULT 0,
        backup_on_payment INTEGER DEFAULT 0,
        backup_schedule_time TEXT,
        backup_custom_name TEXT,
        backup_retries INTEGER DEFAULT 3,
        company_country_code TEXT,
        disbursement_rate_type TEXT NOT NULL DEFAULT 'SELL',
        payment_rate_type TEXT NOT NULL DEFAULT 'BUY',
        allow_manual_exchange_rate INTEGER NOT NULL DEFAULT 0,
        payment_currency TEXT,
        exchange_rate_applied REAL,
        exchange_profit REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customer Categories table
    await db.execute('''
      CREATE TABLE customer_categories (
        category_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Payment Frequencies table (V27)
    await db.execute('''
      CREATE TABLE payment_frequencies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        days_interval INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // V28: Add payment_frequency_days to loans table
    try {
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM pragma_table_info('loans') WHERE name='payment_frequency_days'",
      );
      final hasColumn = (result.first['cnt'] as int) > 0;
      if (!hasColumn) {
        await db.execute(
          'ALTER TABLE loans ADD COLUMN payment_frequency_days INTEGER',
        );
      }
    } catch (e) {
      debugPrint('Error adding payment_frequency_days to loans: $e');
    }

    // Seed default frequencies logic is effectively handled by migration logic on upgrade,
    // but for fresh installs we should insert them here too.
    final now = DateTime.now().toIso8601String();
    final defaults = [
      {'id': 'DAILY', 'name': 'Diario', 'days_interval': 1, 'is_default': 1},
      {'id': 'WEEKLY', 'name': 'Semanal', 'days_interval': 7, 'is_default': 1},
      {
        'id': 'BIWEEKLY',
        'name': 'Quincenal',
        'days_interval': 15,
        'is_default': 1,
      },
      {
        'id': 'MONTHLY',
        'name': 'Mensual',
        'days_interval': 30,
        'is_default': 1,
      },
      {'id': 'ANNUAL', 'name': 'Anual', 'days_interval': 365, 'is_default': 1},
    ];

    for (final freq in defaults) {
      await db.insert('payment_frequencies', {
        ...freq,
        'is_active': 1,
        'created_at': now,
      });
    }

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
        category_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES customer_categories(category_id) ON DELETE SET NULL
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
        currency_code TEXT DEFAULT 'NIO',
        applied_exchange_rate REAL,
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

    // Payments table (V25 Schema)
    await db.execute('''
      CREATE TABLE payments (
        payment_id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        
        amount_payment_minor INTEGER DEFAULT 0,
        amount_base_minor INTEGER DEFAULT 0,
        amount_loan_minor INTEGER DEFAULT 0,
        
        payment_currency TEXT DEFAULT 'NIO',
        loan_currency TEXT DEFAULT 'NIO',
        base_currency TEXT DEFAULT 'NIO',
        
        rate_id TEXT,
        rate_type_used TEXT,
        rate_value_used REAL,
        rate_date_used TEXT,
        reference_rate_value REAL,
        
        fx_profit_base_minor INTEGER DEFAULT 0,
        fx_status TEXT DEFAULT 'NONE',
        
        status TEXT DEFAULT 'VALID',
        void_reason_key TEXT,
        voided_at TEXT,
        
        idempotency_key TEXT DEFAULT '',
        payload_hash TEXT DEFAULT '',
        
        declared_type TEXT DEFAULT 'MIXED',
        receipt_number INTEGER NOT NULL,
        notes TEXT,
        
        legacy_migrated_at TEXT,
        legacy_ambiguous INTEGER DEFAULT 0,
        unapplied_minor INTEGER DEFAULT 0,
        
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
      )
    ''');

    // PaymentAllocation table (V25 Schema)
    await db.execute('''
      CREATE TABLE payment_allocations (
        allocation_id TEXT PRIMARY KEY,
        payment_id TEXT NOT NULL,
        amount_loan_minor INTEGER DEFAULT 0,
        allocation_type TEXT DEFAULT 'INTEREST',
        billing_cycle_id TEXT,
        created_at TEXT NOT NULL,
        
        FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,
        FOREIGN KEY (billing_cycle_id) REFERENCES billing_cycles(billing_cycle_id) ON DELETE RESTRICT
      )
    ''');

    // NEW V25 Tables

    // Currencies
    await db.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        currency_code TEXT PRIMARY KEY,
        fraction_digits INTEGER NOT NULL DEFAULT 2,
        symbol TEXT,
        name_key TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    // Insert default currencies
    // now is already defined above

    await db.execute(
      "INSERT OR IGNORE INTO currencies VALUES ('NIO', 2, 'C\$', 'currency_nio', 1, '$now', '$now')",
    );
    await db.execute(
      "INSERT OR IGNORE INTO currencies VALUES ('USD', 2, '\$', 'currency_usd', 1, '$now', '$now')",
    );

    // Client Credit Ledger
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_credits_ledger (
        entry_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        reference_payment_id TEXT,
        transaction_type TEXT,
        amount_minor INTEGER,
        created_at TEXT
      )
    ''');

    // Payment FX Legs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_fx_legs (
        leg_id TEXT PRIMARY KEY,
        payment_id TEXT NOT NULL,
        step_order INTEGER DEFAULT 1,
        base_currency TEXT DEFAULT 'NIO',
        from_currency TEXT DEFAULT 'NIO',
        to_currency TEXT DEFAULT 'NIO',
        rate_type_used TEXT DEFAULT 'MANUAL',
        rate_value_used REAL DEFAULT 1.0,
        reference_rate_type TEXT,
        reference_rate_value REAL,
        amount_from_minor INTEGER DEFAULT 0,
        amount_to_customer_minor INTEGER DEFAULT 0,
        amount_to_reference_minor INTEGER,
        fx_profit_base_minor INTEGER,
        created_at TEXT
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

    // ExchangeRate table (v21)
    await db.execute('''
      CREATE TABLE exchange_rates (
        rate_id TEXT PRIMARY KEY,
        source_currency TEXT NOT NULL,
        target_currency TEXT NOT NULL,
        rate_date TEXT NOT NULL,
        buy_rate REAL NOT NULL,
        sell_rate REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX uq_exchange_rate_pair_date ON exchange_rates(source_currency, target_currency, rate_date)',
    );

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

    // Payment indexes (V25: payment_date -> created_at)
    await db.execute(
      'CREATE INDEX idx_payment_loan_date ON payments(loan_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_payment_customer_date ON payments(customer_id, created_at)',
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
    // idx_allocation_loan removed as loan_id is no longer in allocations table

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
    // Migration from v11 to v12 (DNI validation setting)
    if (oldVersion < 12) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN validate_dni INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    // Migration from v12 to v13 (Backup path)
    if (oldVersion < 13) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_path TEXT',
        );
      } catch (_) {}
    }
    // Migration from v13 to v14 (WhatsApp receipts sharing)
    if (oldVersion < 14) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN share_receipts_whatsapp INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    // Migration from v14 to v15 (Report settings)
    if (oldVersion < 15) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_disbursement_signatures INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_payment_signatures INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN disbursement_legend TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_disbursement_legend INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN payment_legend TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN show_payment_legend INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    // Migration from v15 to v16 (Capital Payment Restriction)
    if (oldVersion < 16) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN enable_capital_restriction INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN capital_restriction_days INTEGER DEFAULT 10',
        );
      } catch (_) {}
    }
    // Migration from v16 to v17 (DNI Format Validation)
    if (oldVersion < 17) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN validate_dni_format INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE app_settings ADD COLUMN dni_mask TEXT');
      } catch (_) {}
    }
    // Migration from v17 to v18 (Scheduled Backup)
    if (oldVersion < 18) {
      try {
        await db.execute(
          "ALTER TABLE app_settings ADD COLUMN backup_frequency TEXT DEFAULT 'NONE'",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_retention_days INTEGER DEFAULT 30',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_on_loan_creation INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_on_payment INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_schedule_time TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_custom_name TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_retries INTEGER DEFAULT 3',
        );
      } catch (_) {}
    }
    // Migration from v18 to v19 (Ensure all new columns exist - Safety Check)
    if (oldVersion < 19) {
      // Report Currency Columns
      try {
        await db.execute(
          "ALTER TABLE app_settings ADD COLUMN report_currency TEXT DEFAULT 'NIO'",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN exchange_rate REAL DEFAULT 1.0',
        );
      } catch (_) {}

      // Backup Columns (if missed in v18 or just ensuring)
      try {
        await db.execute(
          "ALTER TABLE app_settings ADD COLUMN backup_frequency TEXT DEFAULT 'NONE'",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_retention_days INTEGER DEFAULT 30',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_on_loan_creation INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_on_payment INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_schedule_time TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_custom_name TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN backup_retries INTEGER DEFAULT 3',
        );
      } catch (_) {}
    }

    // Migration from v19 to v20 (Country of Operation)
    if (oldVersion < 20) {
      try {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN company_country_code TEXT',
        );
      } catch (_) {}
    }

    // Migration v25: Multi-Currency Refactor (Strict Mode)
    if (oldVersion < 25) {
      await _performV25UpgradeTables(db);
    }

    // Migration v26: Customer Categories
    if (oldVersion < 26) {
      // Create customer_categories table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer_categories (
            category_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color_hex TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}

      // Add category_id column to customers
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN category_id TEXT');
      } catch (_) {}
    }
    // Migration from v26 to v27: Add payment_frequencies table
    if (oldVersion < 27) {
      // Create payment_frequencies table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS payment_frequencies (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            days_interval INTEGER NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        debugPrint('Error creating payment_frequencies table: $e');
      }

      // Seed default frequencies
      final now = DateTime.now().toIso8601String();
      final defaults = [
        {'id': 'DAILY', 'name': 'Diario', 'days_interval': 1, 'is_default': 1},
        {
          'id': 'WEEKLY',
          'name': 'Semanal',
          'days_interval': 7,
          'is_default': 1,
        },
        {
          'id': 'BIWEEKLY',
          'name': 'Quincenal',
          'days_interval': 15,
          'is_default': 1,
        },
        {
          'id': 'MONTHLY',
          'name': 'Mensual',
          'days_interval': 30,
          'is_default': 1,
        },
        {
          'id': 'ANNUAL',
          'name': 'Anual',
          'days_interval': 365,
          'is_default': 1,
        },
      ];

      for (final freq in defaults) {
        try {
          await db.insert('payment_frequencies', {
            ...freq,
            'is_active': 1,
            'created_at': now,
          });
        } catch (e) {
          debugPrint('Error seeding default frequency ${freq['id']}: $e');
        }
      }
    }

    // Run data fix on upgrade
    await fixInterestCalculations();
  }

  /// Perform V25 Migration for Multi-Currency Refactor
  /// Follows the transaction pattern from the example database_helper.dart
  Future<void> _performV25UpgradeTables(Database db) async {
    debugPrint('Starting V25 Migration...');
    final now = DateTime.now().toIso8601String();

    // 1. Create currencies table (safe - IF NOT EXISTS)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        currency_code TEXT PRIMARY KEY,
        fraction_digits INTEGER NOT NULL DEFAULT 2,
        symbol TEXT,
        name_key TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Insert default currencies
    await db.execute(
      "INSERT OR IGNORE INTO currencies VALUES ('NIO', 2, 'C\$', 'currency_nio', 1, '$now', '$now')",
    );
    await db.execute(
      "INSERT OR IGNORE INTO currencies VALUES ('USD', 2, '\$', 'currency_usd', 1, '$now', '$now')",
    );
    await db.execute(
      "INSERT OR IGNORE INTO currencies VALUES ('EUR', 2, '€', 'currency_eur', 1, '$now', '$now')",
    );
    debugPrint('V25: Currencies table ready');

    // 2. Create client_credits_ledger (safe - IF NOT EXISTS)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_credits_ledger (
        entry_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        reference_payment_id TEXT,
        transaction_type TEXT,
        amount_minor INTEGER,
        created_at TEXT
      )
    ''');
    debugPrint('V25: Credits ledger table ready');

    // 3. Create payment_fx_legs (safe - IF NOT EXISTS)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_fx_legs (
        leg_id TEXT PRIMARY KEY,
        payment_id TEXT NOT NULL,
        step_order INTEGER DEFAULT 1,
        base_currency TEXT DEFAULT 'NIO',
        from_currency TEXT DEFAULT 'NIO',
        to_currency TEXT DEFAULT 'NIO',
        rate_type_used TEXT DEFAULT 'MANUAL',
        rate_value_used REAL DEFAULT 1.0,
        reference_rate_type TEXT,
        reference_rate_value REAL,
        amount_from_minor INTEGER DEFAULT 0,
        amount_to_customer_minor INTEGER DEFAULT 0,
        amount_to_reference_minor INTEGER,
        fx_profit_base_minor INTEGER,
        created_at TEXT
      )
    ''');
    debugPrint('V25: FX Legs table ready');

    // 4. Perform V25 Payments Migration (Extracted Method)
    await _performV25Migration(db);
  }

  /// Helper method to perform V25 migration (backfill payments/allocations)
  /// Can be called from upgrades or schema repair
  Future<void> _performV25Migration(Database db) async {
    debugPrint('Checking V25 Migration status...');

    // Check if payments table needs migration
    final paymentsColumns = await db.rawQuery('PRAGMA table_info(payments)');
    final hasAmountColumn = paymentsColumns.any((c) => c['name'] == 'amount');
    final hasMinorColumn = paymentsColumns.any(
      (c) => c['name'] == 'amount_payment_minor',
    );

    if (!hasAmountColumn && hasMinorColumn) {
      debugPrint('V25: Payments already migrated, skipping');
      return;
    }

    if (!hasAmountColumn) {
      debugPrint(
        'V25: No amount column found, skipping migration (Wait for correct state)',
      );
      // If table is empty or just created, we might not need to do anything,
      // but if it's missing amount and missing minor, it's a broken state.
      // However, if it's a fresh install, _onCreate handles it.
      // If it's a legacy DB without 'amount', something is weird.
      if (!hasMinorColumn) {
        // Force Create if neither exists? No, that's dangerous.
        // But for now, let's assume if 'amount' is missing, it's either new or very old.
        return;
      }
      return;
    }

    // Check if void_reason column exists
    final hasVoidReason = paymentsColumns.any(
      (c) => c['name'] == 'void_reason',
    );

    // CRITICAL FIX: Ensure loans table has currency_code for backfill usage
    try {
      await db.execute(
        "ALTER TABLE loans ADD COLUMN currency_code TEXT DEFAULT 'NIO'",
      );
      debugPrint('V25: Added missing currency_code to loans table');
    } catch (e) {
      // Column likely already exists, ignore
      debugPrint('V25: currency_code column check/add: $e');
    }

    // 5. Migrate payments table using transaction
    debugPrint('V25: Migrating payments table...');

    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Rename old tables
      await txn.execute('ALTER TABLE payments RENAME TO payments_old');
      await txn.execute(
        'ALTER TABLE payment_allocations RENAME TO payment_allocations_old',
      );

      // Create NEW Payments Table
      await txn.execute('''
        CREATE TABLE payments (
          payment_id TEXT PRIMARY KEY,
          loan_id TEXT NOT NULL,
          customer_id TEXT NOT NULL,
          amount_payment_minor INTEGER DEFAULT 0,
          amount_base_minor INTEGER DEFAULT 0,
          amount_loan_minor INTEGER DEFAULT 0,
          payment_currency TEXT DEFAULT 'NIO',
          loan_currency TEXT DEFAULT 'NIO',
          base_currency TEXT DEFAULT 'NIO',
          rate_id TEXT,
          rate_type_used TEXT,
          rate_value_used REAL,
          rate_date_used TEXT,
          reference_rate_value REAL,
          fx_profit_base_minor INTEGER DEFAULT 0,
          fx_status TEXT DEFAULT 'NONE',
          status TEXT DEFAULT 'VALID',
          void_reason_key TEXT,
          voided_at TEXT,
          idempotency_key TEXT DEFAULT '',
          payload_hash TEXT DEFAULT '',
          declared_type TEXT DEFAULT 'MIXED',
          receipt_number INTEGER NOT NULL,
          notes TEXT,
          legacy_migrated_at TEXT,
          legacy_ambiguous INTEGER DEFAULT 0,
          unapplied_minor INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT,
          FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
        )
      ''');

      // Create NEW Allocations Table
      await txn.execute('''
        CREATE TABLE payment_allocations (
          allocation_id TEXT PRIMARY KEY,
          payment_id TEXT NOT NULL,
          amount_loan_minor INTEGER DEFAULT 0,
          allocation_type TEXT DEFAULT 'INTEREST',
          billing_cycle_id TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,
          FOREIGN KEY (billing_cycle_id) REFERENCES billing_cycles(billing_cycle_id) ON DELETE RESTRICT
        )
      ''');

      // DATA BACKFILL - Payments
      debugPrint('V25: Backfilling Payments...');
      if (hasVoidReason) {
        await txn.execute('''
          INSERT INTO payments (
            payment_id, loan_id, customer_id,
            amount_payment_minor, amount_base_minor, amount_loan_minor,
            payment_currency, loan_currency, base_currency,
            status, void_reason_key, voided_at,
            created_at, updated_at,
            idempotency_key, payload_hash, legacy_migrated_at, legacy_ambiguous,
            receipt_number
          )
          SELECT
            p.payment_id, p.loan_id, l.customer_id,
            CAST(ROUND(COALESCE(p.amount, 0) * 100) AS INTEGER),
            CAST(ROUND(COALESCE(p.amount, 0) * 100) AS INTEGER),
            CAST(ROUND(COALESCE(p.amount, 0) * 100) AS INTEGER),
            COALESCE(l.currency_code, 'NIO'), COALESCE(l.currency_code, 'NIO'), 'NIO',
            COALESCE(p.status, 'VALID'),
            p.void_reason,
            p.voided_at,
            p.created_at, p.created_at,
            'LEGACY_' || p.payment_id, 'LEGACY|' || p.payment_id, '$now', 1,
            0
          FROM payments_old p
          LEFT JOIN loans l ON p.loan_id = l.loan_id
        ''');
      } else {
        await txn.execute('''
          INSERT INTO payments (
            payment_id, loan_id, customer_id,
            amount_payment_minor, amount_base_minor, amount_loan_minor,
            payment_currency, loan_currency, base_currency,
            status,
            created_at, updated_at,
            idempotency_key, payload_hash, legacy_migrated_at, legacy_ambiguous,
            receipt_number
          )
          SELECT
            p.payment_id, p.loan_id, l.customer_id,
            CAST(ROUND(COALESCE(p.amount, 0) * 100) AS INTEGER),
            CAST(ROUND(COALESCE(p.amount, 0) * 100) AS INTEGER),
            CAST(ROUND(COALESCE(p.amount, 0) * 100) AS INTEGER),
            COALESCE(l.currency_code, 'NIO'), COALESCE(l.currency_code, 'NIO'), 'NIO',
            COALESCE(p.status, 'VALID'),
            p.created_at, p.created_at,
            'LEGACY_' || p.payment_id, 'LEGACY|' || p.payment_id, '$now', 1,
            0
          FROM payments_old p
          LEFT JOIN loans l ON p.loan_id = l.loan_id
        ''');
      }

      // DATA BACKFILL - Allocations
      debugPrint('V25: Backfilling Allocations...');
      await txn.execute('''
        INSERT INTO payment_allocations (allocation_id, payment_id, billing_cycle_id, allocation_type, amount_loan_minor, created_at)
        SELECT
          pa.allocation_id, pa.payment_id, pa.billing_cycle_id,
          UPPER(COALESCE(pa.allocation_type, 'INTEREST')),
          CAST(ROUND(COALESCE(pa.amount, 0) * 100) AS INTEGER),
          pa.created_at
        FROM payment_allocations_old pa
      ''');

      // Drop old tables
      await txn.execute('DROP TABLE payments_old');
      await txn.execute('DROP TABLE payment_allocations_old');
    });

    debugPrint('V25 Migration Complete!');
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

  /// Upgrade a restored database to ensure it has all latest columns
  /// This is called after restoring from a backup to add any missing columns
  /// Opens the database directly without using the cached connection
  Future<void> upgradeRestoredDatabase() async {
    debugPrint('=== UPGRADING RESTORED DATABASE ===');

    // Get database path
    final dbPath = await getDatabasePath();
    debugPrint('Database path: $dbPath');

    // Ensure FFI is initialized for desktop
    if (!kIsWeb &&
        (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Open database directly (not through cached getter)
    Database? db;
    try {
      db = await databaseFactory.openDatabase(dbPath);
      debugPrint('Database opened for upgrade');

      // Check and add share_receipts_whatsapp column if missing
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='share_receipts_whatsapp'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: share_receipts_whatsapp');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN share_receipts_whatsapp INTEGER DEFAULT 0',
          );
          debugPrint('Column share_receipts_whatsapp added successfully');
        } else {
          debugPrint('Column share_receipts_whatsapp already exists');
        }
      } catch (e) {
        debugPrint('Error checking/adding share_receipts_whatsapp: $e');
      }

      // Check and add backup_path column if missing (v13)
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='backup_path'",
        );
        final hasColumn = (result.first['cnt'] as int) > 0;
        if (!hasColumn) {
          debugPrint('Adding missing column: backup_path');
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN backup_path TEXT',
          );
          debugPrint('Column backup_path added successfully');
        } else {
          debugPrint('Column backup_path already exists');
        }
      } catch (e) {
        debugPrint('Error checking/adding backup_path: $e');
      }

      // Check and add capital restriction columns (v16)
      final v16Columns = [
        {'name': 'enable_capital_restriction', 'def': 'INTEGER DEFAULT 1'},
        {'name': 'capital_restriction_days', 'def': 'INTEGER DEFAULT 10'},
      ];

      for (final col in v16Columns) {
        try {
          final result = await db.rawQuery(
            "SELECT COUNT(*) as cnt FROM pragma_table_info('app_settings') WHERE name='${col['name']}'",
          );
          final hasColumn = (result.first['cnt'] as int) > 0;
          if (!hasColumn) {
            debugPrint('Adding missing column: ${col['name']}');
            await db.execute(
              'ALTER TABLE app_settings ADD COLUMN ${col['name']} ${col['def']}',
            );
            debugPrint('Column ${col['name']} added successfully');
          } else {
            debugPrint('Column ${col['name']} already exists');
          }
        } catch (e) {
          debugPrint('Error checking/adding ${col['name']}: $e');
        }
      }

      debugPrint('=== UPGRADE COMPLETE ===');
    } finally {
      // Close the direct connection
      if (db != null && db.isOpen) {
        await db.close();
        debugPrint('Database closed after upgrade');
      }
    }
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

  /// Force reset database connection after restore
  /// This ensures the next database access will reinitialize and run onOpen
  Future<void> forceReset() async {
    debugPrint('=== FORCE RESET DATABASE CONNECTION ===');
    try {
      if (_database != null) {
        if (_database!.isOpen) {
          await _database!.close();
        }
      }
    } catch (e) {
      debugPrint('Error closing database during reset: $e');
    }
    _database = null;
    _isMaintenanceMode = false;
    debugPrint('Database connection reset, will reinitialize on next access');
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
  /// CRITICAL: Must match exactly where the database is actually stored
  Future<String> getDatabasePath() async {
    // On Android/iOS, sqflite by default stores databases in getDatabasesPath()
    // NOT in getApplicationSupportDirectory()
    // We must use the same path that openDatabase uses by default
    if (io.Platform.isAndroid || io.Platform.isIOS) {
      // Use sqflite's getDatabasesPath() which is the default location
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, AppConstants.databaseName);
    }

    // Desktop platforms (Windows, Linux, macOS) - use ApplicationSupportDirectory
    final documentsDirectory = await getApplicationSupportDirectory();
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
