import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/payment_frequency.dart';

class PaymentFrequencyRepository {
  final DatabaseHelper _dbHelper;

  PaymentFrequencyRepository(this._dbHelper);

  Future<List<PaymentFrequency>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_frequencies',
      orderBy: 'days_interval ASC',
    );
    return maps.map((m) => PaymentFrequency.fromMap(m)).toList();
  }

  Future<List<PaymentFrequency>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_frequencies',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'days_interval ASC',
    );
    return maps.map((m) => PaymentFrequency.fromMap(m)).toList();
  }

  Future<PaymentFrequency?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_frequencies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PaymentFrequency.fromMap(maps.first);
  }

  Future<void> create(PaymentFrequency frequency) async {
    final db = await _dbHelper.database;
    await db.insert('payment_frequencies', frequency.toMap());
  }

  Future<void> update(PaymentFrequency frequency) async {
    final db = await _dbHelper.database;
    await db.update(
      'payment_frequencies',
      frequency.toMap(),
      where: 'id = ?',
      whereArgs: [frequency.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('payment_frequencies', where: 'id = ?', whereArgs: [id]);
  }

  /// Checks if the frequency is being used by any active loan.
  /// Note: The loans table currently stores frequency as a STRING (e.g., 'MONTHLY').
  /// This new system will likely store ID or we need to map the ID to the string.
  ///
  /// Strategy:
  /// The defaults have IDs like 'DAILY', 'WEEKLY', etc. which match current logic.
  /// Custom ones will have UUIDs.
  /// The Loan table 'billing_frequency' column will store this ID.
  Future<bool> isUsedByActiveLoan(String frequencyId) async {
    final db = await _dbHelper.database;
    // Check if any active loan uses this frequency
    // Active loans usually have status 'ACTIVE' or 'OVERDUE' (IN_MORA)
    // We check 'billing_frequency' column against the ID
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
      SELECT COUNT(*) FROM loans 
      WHERE billing_frequency = ? 
      AND status IN ('ACTIVE', 'OVERDUE', 'IN_MORA')
    ''',
        [frequencyId],
      ),
    );

    return (count ?? 0) > 0;
  }
}
