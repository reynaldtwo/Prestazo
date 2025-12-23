import '../database/database_helper.dart';
import '../models/app_settings.dart';

/// Repository for AppSettings operations
class SettingsRepository {
  final DatabaseHelper _databaseHelper;

  SettingsRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Get global settings
  Future<AppSettings> getSettings() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'app_settings',
      where: 'settings_id = ?',
      whereArgs: ['global'],
      limit: 1,
    );
    if (maps.isEmpty) {
      // Return defaults if not found
      return AppSettings.defaults();
    }
    return AppSettings.fromMap(maps.first);
  }

  /// Update settings
  Future<int> updateSettings(AppSettings settings) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'app_settings',
      settings.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );
  }

  /// Update specific setting
  Future<int> updateSetting(String key, dynamic value) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'app_settings',
      {key: value, 'updated_at': DateTime.now().toIso8601String()},
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );
  }

  /// Get next receipt number and increment
  Future<String> getAndIncrementReceiptNumber() async {
    final db = await _databaseHelper.database;

    // Get current number
    final result = await db.query(
      'app_settings',
      columns: ['receipt_next_number'],
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );

    final currentNumber =
        result.first['receipt_next_number']?.toString() ?? '1';

    // Increment
    final newNumber = _incrementStringCode(currentNumber);
    await db.update(
      'app_settings',
      {
        'receipt_next_number': newNumber,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );

    return currentNumber;
  }

  /// Reset receipt number to 1
  Future<int> resetReceiptNumber() async {
    final db = await _databaseHelper.database;
    return await db.update(
      'app_settings',
      {
        'receipt_next_number': '1',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'settings_id = ?',
      whereArgs: ['global'],
    );
  }

  /// Helper to increment alphanumeric codes
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
}
