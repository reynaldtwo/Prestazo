/// Backup Service
///
/// Centralized service for backup management.
/// Handles:
/// - Creating local SQLite database backups
/// - Managing backup files
/// - Restoring from backup
/// - Sharing backups to external apps
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:prestamos_app/data/database/database_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Debug logging helper - only prints in debug mode
void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Backup file info
/// Información sobre un archivo de respaldo.
class BackupInfo {
  /// Crea una instancia de [BackupInfo].
  const BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.sizeBytes,
  });

  /// Nombre del archivo del respaldo.
  final String fileName;

  /// Ruta completa al archivo en el sistema de archivos.
  final String filePath;

  /// Fecha y hora en que se creó el respaldo.
  final DateTime createdAt;

  /// Tamaño del archivo en bytes.
  final int sizeBytes;

  /// Tamaño del archivo formateado para humanos (ej: 1.2 MB).
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() => 'BackupInfo($fileName, $formattedSize, $createdAt)';
}

/// Service for backup management
/// Servicio encargado de la gestión de respaldos (Backups).
class BackupService {
  // Singleton
  BackupService._();
  static const String _backupFolderName = 'backups';

  /// Instancia única (singleton) de [BackupService].
  static final BackupService instance = BackupService._();

  // Ensure FFI is initialized for Desktop
  void _ensureFfiInitialized() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Get the backup directory path (Internal)
  Future<Directory> get _backupDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, _backupFolderName));
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    return backupDir;
  }

  /// Get the database file path
  /// CRITICAL: Must match exactly what DatabaseHelper uses.
  Future<File> get _databaseFile async {
    final dbPath = await DatabaseHelper().getDatabasePath();
    return File(dbPath);
  }

  /// Check if a scheduled backup is due
  Future<void> checkScheduledBackup({
    required String frequency, // DAILY, WEEKLY, MONTHLY
    required int retentionDays,
    required int retries,
    String? customName,
  }) async {
    if (frequency == 'NONE') return;

    try {
      final backups = await getLocalBackups();
      if (backups.isEmpty) {
        _log('No backups found, performing initial backup...');
        await createBackup(customName: customName);
        return;
      }

      final latest = backups.first;
      final now = DateTime.now();
      final diff = now.difference(latest.createdAt);

      var shouldBackup = false;
      switch (frequency) {
        case 'DAILY':
          shouldBackup = diff.inHours >= 24;
        case 'WEEKLY':
          shouldBackup = diff.inDays >= 7;
        case 'MONTHLY':
          shouldBackup = diff.inDays >= 30;
      }

      if (shouldBackup) {
        _log('Scheduled backup due ($frequency). Last: ${latest.createdAt}');
        await createBackup(customName: customName);
      }

      // Also cleanup old backups based on retention days
      await _cleanupOldBackups(retentionDays);
    } on Exception catch (e) {
      _log('Error checking scheduled backup: $e');
    }
  }

  /// Trigger a backup manually or by event
  Future<BackupInfo?> createBackup({
    String? customPath,
    String? customName,
    bool allowOverwrite = false,
  }) async {
    _log('=== BACKUP START (VACUUM INTO) ===');
    try {
      final dbHelper = DatabaseHelper();

      // Step 1: Get database instance (Ensures it is OPEN)
      _log('Step 1: Getting database instance...');
      final db = await dbHelper.database;

      // Step 2: Determine target path
      _log('Step 2: Determining target path...');
      final timestamp = DateTime.now();
      String targetPath;

      if (customPath != null) {
        targetPath = customPath;
        _log('Using custom path: $targetPath');
      } else {
        final backupDir = await _backupDir;
        String fileName;
        if (customName != null && customName.isNotEmpty) {
          fileName = '${customName}_${_formatTimestamp(timestamp)}.db';
        } else {
          fileName = 'backup_${_formatTimestamp(timestamp)}.db';
        }
        targetPath = path.join(backupDir.path, fileName);
        _log('Using internal path: $targetPath');
      }

      // Step 3: Handle existing file (VACUUM INTO fails if file exists)
      final targetFile = File(targetPath);
      if (targetFile.existsSync()) {
        if (allowOverwrite || customPath == null) {
          _log('Step 3: Target file exists, deleting for replacement...');
          targetFile.deleteSync();
        } else {
          _log('ERROR: File exists and overwrite not allowed.');
          return null;
        }
      }

      // Step 4: Execute VACUUM INTO
      // This creates a backup WITHOUT closing the database connection.
      // Crucial for "Backup on Loan Creation" to avoid "Database Closed" errors in UI.
      _log('Step 4: Executing VACUUM INTO...');

      // Escape single quotes in path just in case
      final safePath = targetPath.replaceAll("'", "''");
      await db.execute("VACUUM INTO '$safePath'");

      _log('VACUUM INTO completed successfully');

      // Step 5: Verify backup
      final backupFile = File(targetPath);
      if (!backupFile.existsSync()) {
        _log('ERROR: Backup file was not created!');
        return null;
      }

      final stat = backupFile.statSync();
      _log('Backup size: ${stat.size} bytes');

      if (stat.size == 0) {
        _log('ERROR: Backup file is empty!');
        return null;
      }

      _log('=== BACKUP SUCCESS ===');
      return BackupInfo(
        fileName: path.basename(targetPath),
        filePath: targetPath,
        createdAt: timestamp,
        sizeBytes: stat.size,
      );
    } on Exception catch (e, stackTrace) {
      _log('=== BACKUP ERROR ===');
      _log('Error: $e');
      _log('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Generate default filename for export: Prestazo_ddMMyy.db
  String getDefaultExportName() {
    final now = DateTime.now();
    final dateStr =
        '${_pad(now.day)}${_pad(now.month)}${now.year.toString().substring(2)}';
    return 'Prestazo_$dateStr.db';
  }

  /// Get list of all local backups
  Future<List<BackupInfo>> getLocalBackups() async {
    try {
      final backupDir = await _backupDir;
      final files = await backupDir.list().toList();

      final backups = <BackupInfo>[];
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.db')) {
          final stat = entity.statSync();
          final fileName = path.basename(entity.path);

          // Parse timestamp from filename
          DateTime createdAt;
          try {
            final timestampStr = fileName
                .replaceAll('backup_', '')
                .replaceAll('.db', '');
            createdAt = _parseTimestamp(timestampStr);
          } on Exception catch (_) {
            createdAt = stat.modified;
          }

          backups.add(
            BackupInfo(
              fileName: fileName,
              filePath: entity.path,
              createdAt: createdAt,
              sizeBytes: stat.size,
            ),
          );
        }
      }

      // Sort by date, newest first
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } on Exception catch (_) {
      return [];
    }
  }

  /// Delete a backup file
  /// Cannot delete the most recent backup
  Future<bool> deleteBackup(String filePath) async {
    try {
      final backups = await getLocalBackups();

      // Don't delete if it's the only or most recent backup
      if (backups.length <= 1) {
        return false;
      }

      // Check if this is the most recent
      if (backups.first.filePath == filePath) {
        return false;
      }

      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
        return true;
      }
      return false;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Restore from a backup file
  Future<bool> restoreFromBackup(String backupPath) async {
    _log('=== RESTORE START ===');
    final dbHelper = DatabaseHelper();

    try {
      final backupFile = File(backupPath);
      if (!backupFile.existsSync()) {
        _log('ERROR: Backup file does not exist: $backupPath');
        return false;
      }

      final backupSize = await backupFile.length();
      _log('Backup file size: $backupSize bytes');

      final dbFile = await _databaseFile;
      final dbPath = dbFile.path;
      _log('Target database path: $dbPath');

      _ensureFfiInitialized();

      // 1. Enable maintenance mode
      _log('Step 1: Setting maintenance mode...');
      dbHelper.maintenanceMode = true;

      // 2. Close Database
      _log('Step 2: Closing database...');
      await dbHelper.close();

      // Add delay
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 3. Delete database
      _log('Step 3: Deleting current database...');
      await databaseFactory.deleteDatabase(dbPath);

      // 4. Copy backup over
      _log('Step 4: Copying backup file...');
      if (!dbFile.parent.existsSync()) {
        dbFile.parent.createSync(recursive: true);
      }
      backupFile.copySync(dbPath);

      // 5. Verify
      final newDbFile = File(dbPath);
      if (newDbFile.existsSync()) {
        final newSize = newDbFile.lengthSync();
        _log('New database size: $newSize bytes');
      }

      // 6. Force reset database connection
      // This ensures onOpen will run and add missing columns
      _log('Step 6: Force resetting database connection...');
      await dbHelper.forceReset();

      _log('=== RESTORE SUCCESS ===');
      return true;
    } on Exception catch (e, stackTrace) {
      _log('=== RESTORE ERROR ===');
      _log('Error: $e');
      _log('Stack trace: $stackTrace');
      // Force reset to clean up any partial state
      await dbHelper.forceReset();
      return false;
    }
  }

  /// Restore from external file (e.g., from file picker)
  Future<bool> restoreFromExternalFile(String externalPath) async {
    _log('=== EXTERNAL RESTORE START ===');
    try {
      final externalFile = File(externalPath);
      if (!externalFile.existsSync()) {
        _log('ERROR: External file does not exist');
        return false;
      }

      // Copy to temp first
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'temp_restore.db');
      final tempFile = File(tempPath);

      // Copy bytes manually
      final bytes = await externalFile.readAsBytes();
      _log('External file size: ${bytes.length} bytes');

      // Basic validation
      if (bytes.length < 16 ||
          String.fromCharCodes(bytes.take(6)) != 'SQLite') {
        _log('ERROR: Not a valid SQLite file');
        return false;
      }

      await tempFile.writeAsBytes(bytes);
      _log('Copied to temp file');

      // Now restore from temp
      final result = await restoreFromBackup(tempPath);

      // Cleanup temp
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }

      return result;
    } on Exception catch (e, stackTrace) {
      _log('=== EXTERNAL RESTORE ERROR ===');
      _log('Error: $e');
      _log('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Share a backup file using the system share dialog
  Future<bool> shareBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }

      // Use the actual filename for the share subject
      final fileName = path.basename(filePath);

      final result = await Share.shareXFiles(
        [XFile(filePath, name: fileName)],
        subject: fileName,
        text: 'Respaldo de Prestazo: $fileName',
      );

      return result.status == ShareResultStatus.success;
    } on Exception catch (e) {
      _log('Share error: $e');
      return false;
    }
  }

  /// Share the most recent backup
  Future<bool> shareLatestBackup() async {
    final backups = await getLocalBackups();
    if (backups.isEmpty) {
      final newBackup = await createBackup();
      if (newBackup == null) return false;
      return shareBackup(newBackup.filePath);
    }
    return shareBackup(backups.first.filePath);
  }

  /// Clean up old backups based on retention days
  Future<void> _cleanupOldBackups(int retentionDays) async {
    final backups = await getLocalBackups();
    final now = DateTime.now();

    for (final backup in backups) {
      final diff = now.difference(backup.createdAt);
      if (diff.inDays > retentionDays) {
        _log(
          'Deleting old backup: ${backup.fileName} (${diff.inDays} days old)',
        );
        await deleteBackup(backup.filePath);
      }
    }
  }

  /// Format timestamp for filename
  String _formatTimestamp(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}_${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}';
  }

  /// Parse timestamp from filename
  DateTime _parseTimestamp(String str) {
    return DateTime(
      int.parse(str.substring(0, 4)),
      int.parse(str.substring(4, 6)),
      int.parse(str.substring(6, 8)),
      int.parse(str.substring(9, 11)),
      int.parse(str.substring(11, 13)),
      int.parse(str.substring(13, 15)),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
