import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:prestamos_app/data/models/exchange_rate.dart';
import 'package:uuid/uuid.dart';

/// Repository for ExchangeRate CRUD operations
class ExchangeRateRepository {
  /// Crea un [ExchangeRateRepository] con el [DatabaseHelper] proporcionado.
  ExchangeRateRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();
  final DatabaseHelper _dbHelper;

  /// Get all exchange rates
  Future<List<ExchangeRate>> getAllRates() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exchange_rates',
      orderBy: 'rate_date DESC, source_currency, target_currency',
    );
    return maps.map(ExchangeRate.fromMap).toList();
  }

  /// Get rates for a specific currency pair
  Future<List<ExchangeRate>> getRatesForPair(
    String source,
    String target,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exchange_rates',
      where: 'source_currency = ? AND target_currency = ?',
      whereArgs: [source, target],
      orderBy: 'rate_date DESC',
    );
    return maps.map(ExchangeRate.fromMap).toList();
  }

  /// Get rate for a specific date and currency pair
  Future<ExchangeRate?> getRateForDate(
    String source,
    String target,
    DateTime date,
  ) async {
    final db = await _dbHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await db.query(
      'exchange_rates',
      where: 'source_currency = ? AND target_currency = ? AND rate_date = ?',
      whereArgs: [source, target, dateStr],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExchangeRate.fromMap(maps.first);
  }

  /// Get the most recent rate for a currency pair (today or most recent before)
  Future<ExchangeRate?> getLatestRate(String source, String target) async {
    final db = await _dbHelper.database;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final maps = await db.query(
      'exchange_rates',
      where: 'source_currency = ? AND target_currency = ? AND rate_date <= ?',
      whereArgs: [source, target, todayStr],
      orderBy: 'rate_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExchangeRate.fromMap(maps.first);
  }

  /// Get today's rate for a currency pair
  Future<ExchangeRate?> getTodayRate(String source, String target) async {
    final today = DateTime.now();
    return getRateForDate(source, target, today);
  }

  /// Create new exchange rate
  Future<ExchangeRate> createRate({
    required String sourceCurrency,
    required String targetCurrency,
    required DateTime date,
    required double buyRate,
    required double sellRate,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final rate = ExchangeRate(
      rateId: const Uuid().v4(),
      sourceCurrency: sourceCurrency,
      targetCurrency: targetCurrency,
      date: date,
      buyRate: buyRate,
      sellRate: sellRate,
      createdAt: now,
    );
    await db.insert('exchange_rates', rate.toMap());
    return rate;
  }

  /// Create exchange rates for the entire month of the given date
  Future<void> createMonthlyRates({
    required String sourceCurrency,
    required String targetCurrency,
    required DateTime date,
    required double buyRate,
    required double sellRate,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // Calculate start and end of the month
    final nextMonth = DateTime(date.year, date.month + 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1)).day;

    final batch = db.batch();

    for (var day = 1; day <= lastDay; day++) {
      final currentDay = DateTime(date.year, date.month, day);
      final rateId = const Uuid().v4();

      // Check if rate exists effectively by trying to delete it first or using conflict strategy
      // Since sqflite insert with conflictAlgorithm might conflict on ID, we should handle logic.
      // However, we have a unique ID per rate, not per date/currency composite key in schema usually.
      // Assuming schema doesn't enforce composite unique on (source, target, date), we should
      // clean up old entries for this day/pair first to avoid duplicates.

      final dateStr = currentDay.toIso8601String().split('T')[0];

      // Delete existing rate for this day/pair
      batch.delete(
        'exchange_rates',
        where: 'source_currency = ? AND target_currency = ? AND rate_date = ?',
        whereArgs: [sourceCurrency, targetCurrency, dateStr],
      );

      final rate = ExchangeRate(
        rateId: rateId,
        sourceCurrency: sourceCurrency,
        targetCurrency: targetCurrency,
        date: currentDay,
        buyRate: buyRate,
        sellRate: sellRate,
        createdAt: now,
      );

      batch.insert('exchange_rates', rate.toMap());
    }

    await batch.commit(noResult: true);
  }

  /// Update existing exchange rate
  Future<void> updateRate(ExchangeRate rate) async {
    final db = await _dbHelper.database;
    await db.update(
      'exchange_rates',
      rate.toMap(),
      where: 'rate_id = ?',
      whereArgs: [rate.rateId],
    );
  }

  /// Delete exchange rate
  Future<void> deleteRate(String rateId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'exchange_rates',
      where: 'rate_id = ?',
      whereArgs: [rateId],
    );
  }

  /// Check if rate exists for date and pair
  Future<bool> rateExistsForDate(
    String source,
    String target,
    DateTime date,
  ) async {
    final rate = await getRateForDate(source, target, date);
    return rate != null;
  }
}
