import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:prestamos_app/data/models/payment_frequency.dart';
import 'package:sqflite/sqflite.dart';

/// Repositorio para gestionar las frecuencias de pago en la base de datos.
class PaymentFrequencyRepository {
  /// Crea un [PaymentFrequencyRepository] con el [DatabaseHelper] proporcionado.
  PaymentFrequencyRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  /// Obtiene todas las frecuencias de pago registradas.
  Future<List<PaymentFrequency>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_frequencies',
      orderBy: 'days_interval ASC',
    );
    return maps.map(PaymentFrequency.fromMap).toList();
  }

  /// Obtiene solo las frecuencias de pago que están marcadas como activas.
  Future<List<PaymentFrequency>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_frequencies',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'days_interval ASC',
    );
    return maps.map(PaymentFrequency.fromMap).toList();
  }

  /// Obtiene una frecuencia de pago por su ID.
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

  /// Crea una nueva frecuencia de pago.
  Future<void> create(PaymentFrequency frequency) async {
    final db = await _dbHelper.database;
    await db.insert('payment_frequencies', frequency.toMap());
  }

  /// Actualiza una frecuencia de pago existente.
  Future<void> update(PaymentFrequency frequency) async {
    final db = await _dbHelper.database;
    await db.update(
      'payment_frequencies',
      frequency.toMap(),
      where: 'id = ?',
      whereArgs: [frequency.id],
    );
  }

  /// Elimina una frecuencia de pago por su ID.
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
