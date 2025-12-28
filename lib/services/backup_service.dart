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
import 'package:share_plus/share_plus.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../data/database/database_helper.dart';

/// Backup file info
class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int sizeBytes;

  const BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.sizeBytes,
  });

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
class BackupService {
  static const String _backupFolderName = 'backups';
  static const int _maxLocalBackups = 5;

  BackupService._();
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
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Get the database file path
  /// CRITICAL: Must match exactly what DatabaseHelper uses.
  Future<File> get _databaseFile async {
    final dbPath = await DatabaseHelper().getDatabasePath();
    return File(dbPath);
  }

  /// Create a new backup - SIMPLIFIED VERSION
  /// If [customPath] is provided, saves to that location.
  /// Otherwise saves to default internal backup directory.
  /// If [allowOverwrite] is true, will overwrite existing file using writeAsBytes.
  Future<BackupInfo?> createBackup({
    String? customPath,
    bool allowOverwrite = false,
  }) async {
    debugPrint('=== BACKUP START ===');
    try {
      final dbHelper = DatabaseHelper();

      // Step 1: Get database path
      debugPrint('Step 1: Getting database path...');
      final dbPath = await dbHelper.getDatabasePath();
      debugPrint('Database path: $dbPath');

      final sourceFile = File(dbPath);
      if (!await sourceFile.exists()) {
        debugPrint('ERROR: Database file does not exist!');
        return null;
      }

      final sourceSize = await sourceFile.length();
      debugPrint('Source file size: $sourceSize bytes');

      // Step 2: Determine target path
      debugPrint('Step 2: Determining target path...');
      final DateTime timestamp = DateTime.now();
      String targetPath;

      if (customPath != null) {
        targetPath = customPath;
        debugPrint('Using custom path: $targetPath');
      } else {
        final backupDir = await _backupDir;
        final fileName = 'backup_${_formatTimestamp(timestamp)}.db';
        targetPath = path.join(backupDir.path, fileName);
        debugPrint('Using internal path: $targetPath');
      }

      // Step 3: Check existing file (for logging only - writeAsBytes will overwrite)
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        debugPrint('Step 3: File exists, will be overwritten by writeAsBytes');
        // No delete needed - writeAsBytes overwrites directly
      }

      // Step 4: Close database connections for safe copy
      debugPrint('Step 4: Closing database...');
      await dbHelper.close();

      // Small delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 5: Copy the file using readAsBytes/writeAsBytes (works with overwrite)
      debugPrint('Step 5: Copying database file...');
      final bytes = await sourceFile.readAsBytes();
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint('File copied successfully');

      // Step 6: Verify backup
      final backupFile = File(targetPath);
      if (!await backupFile.exists()) {
        debugPrint('ERROR: Backup file was not created!');
        return null;
      }

      final stat = await backupFile.stat();
      debugPrint('Backup size: ${stat.size} bytes');

      if (stat.size == 0) {
        debugPrint('ERROR: Backup file is empty!');
        return null;
      }

      // Step 7: Cleanup old backups (only for internal)
      if (customPath == null) {
        await _cleanupOldBackups();
      }

      debugPrint('=== BACKUP SUCCESS ===');
      return BackupInfo(
        fileName: path.basename(targetPath),
        filePath: targetPath,
        createdAt: timestamp,
        sizeBytes: stat.size,
      );
    } catch (e, stackTrace) {
      debugPrint('=== BACKUP ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
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
          final stat = await entity.stat();
          final fileName = path.basename(entity.path);

          // Parse timestamp from filename
          DateTime createdAt;
          try {
            final timestampStr = fileName
                .replaceAll('backup_', '')
                .replaceAll('.db', '');
            createdAt = _parseTimestamp(timestampStr);
          } catch (_) {
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
    } catch (e) {
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
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Restore from a backup file
  Future<bool> restoreFromBackup(String backupPath) async {
    debugPrint('=== RESTORE START ===');
    final dbHelper = DatabaseHelper();

    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        debugPrint('ERROR: Backup file does not exist: $backupPath');
        return false;
      }

      final backupSize = await backupFile.length();
      debugPrint('Backup file size: $backupSize bytes');

      final dbFile = await _databaseFile;
      final dbPath = dbFile.path;
      debugPrint('Target database path: $dbPath');

      _ensureFfiInitialized();

      // 1. Enable maintenance mode
      debugPrint('Step 1: Setting maintenance mode...');
      dbHelper.setMaintenanceMode(true);

      // 2. Close Database
      debugPrint('Step 2: Closing database...');
      await dbHelper.close();

      // Add delay
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Delete database
      debugPrint('Step 3: Deleting current database...');
      await databaseFactory.deleteDatabase(dbPath);

      // 4. Copy backup over
      debugPrint('Step 4: Copying backup file...');
      if (!await dbFile.parent.exists()) {
        await dbFile.parent.create(recursive: true);
      }
      await backupFile.copy(dbPath);

      // 5. Verify
      final newDbFile = File(dbPath);
      if (await newDbFile.exists()) {
        final newSize = await newDbFile.length();
        debugPrint('New database size: $newSize bytes');
      }

      // 6. Force reset database connection
      // This ensures onOpen will run and add missing columns
      debugPrint('Step 6: Force resetting database connection...');
      await dbHelper.forceReset();

      debugPrint('=== RESTORE SUCCESS ===');
      return true;
    } catch (e, stackTrace) {
      debugPrint('=== RESTORE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Force reset to clean up any partial state
      await dbHelper.forceReset();
      return false;
    }
  }

  /// Restore from external file (e.g., from file picker)
  Future<bool> restoreFromExternalFile(String externalPath) async {
    debugPrint('=== EXTERNAL RESTORE START ===');
    try {
      final externalFile = File(externalPath);
      if (!await externalFile.exists()) {
        debugPrint('ERROR: External file does not exist');
        return false;
      }

      // Copy to temp first
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'temp_restore.db');
      final tempFile = File(tempPath);

      // Copy bytes manually
      final bytes = await externalFile.readAsBytes();
      debugPrint('External file size: ${bytes.length} bytes');

      // Basic validation
      if (bytes.length < 16 ||
          String.fromCharCodes(bytes.take(6)) != 'SQLite') {
        debugPrint('ERROR: Not a valid SQLite file');
        return false;
      }

      await tempFile.writeAsBytes(bytes);
      debugPrint('Copied to temp file');

      // Now restore from temp
      final result = await restoreFromBackup(tempPath);

      // Cleanup temp
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('=== EXTERNAL RESTORE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Share a backup file using the system share dialog
  Future<bool> shareBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
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
    } catch (e) {
      debugPrint('Share error: $e');
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

  /// Clean up old backups, keeping only the latest N
  Future<void> _cleanupOldBackups() async {
    final backups = await getLocalBackups();
    if (backups.length <= _maxLocalBackups) return;

    for (var i = _maxLocalBackups; i < backups.length; i++) {
      final file = File(backups[i].filePath);
      if (await file.exists()) {
        await file.delete();
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
