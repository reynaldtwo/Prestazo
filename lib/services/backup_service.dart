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
  static const String _databaseName = 'prestamos_app.db';
  static const int _maxLocalBackups = 5;

  BackupService._();
  static final BackupService instance = BackupService._();

  /// Get the backup directory path
  Future<Directory> get _backupDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, _backupFolderName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Get the database file path
  Future<File> get _databaseFile async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(path.join(appDir.path, _databaseName));
  }

  /// Create a new backup
  /// Returns the backup info if successful, null otherwise
  Future<BackupInfo?> createBackup() async {
    try {
      final dbHelper = DatabaseHelper();
      final dbFile = await _databaseFile;

      // 1. Force Checkpoint (merge WAL to DB)
      await dbHelper.checkpoint();

      // 2. Close Database to release locks
      await dbHelper.close();

      if (!await dbFile.exists()) {
        return null;
      }

      final backupDir = await _backupDir;
      final timestamp = DateTime.now();
      final fileName = 'backup_${_formatTimestamp(timestamp)}.db';
      final backupPath = path.join(backupDir.path, fileName);

      // 3. Copy database to backup location
      await dbFile.copy(backupPath);

      final backupFile = File(backupPath);
      final stat = await backupFile.stat();

      // Clean up old backups (keep only latest N)
      await _cleanupOldBackups();

      return BackupInfo(
        fileName: fileName,
        filePath: backupPath,
        createdAt: timestamp,
        sizeBytes: stat.size,
      );
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
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
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }

      final dbHelper = DatabaseHelper();
      final dbFile = await _databaseFile;
      final walFile = File('${dbFile.path}-wal');
      final shmFile = File('${dbFile.path}-shm');

      // 1. Create a safety backup of current state
      await createBackup();

      // 2. Close Database
      await dbHelper.close();

      // 3. Delete WAL and SHM files to prevent mismatch (critical!)
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      // 4. Copy backup over current database
      await backupFile.copy(dbFile.path);

      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  /// Restore from external file (e.g., from file picker)
  Future<bool> restoreFromExternalFile(String externalPath) async {
    try {
      final externalFile = File(externalPath);
      if (!await externalFile.exists()) {
        return false;
      }

      // 0. Copy to a temp file to ensure access permissions and valid path
      // This solves issues with some file pickers returning cached paths that
      // might not be readable directly by SQLite or during the copy process.
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'temp_restore.db');
      final tempFile = File(tempPath);

      // Copy bytes manually to ensure we bypass potential URI issues
      final bytes = await externalFile.readAsBytes();

      // Basic validation
      if (bytes.length < 16 ||
          String.fromCharCodes(bytes.take(6)) != 'SQLite') {
        return false;
      }

      await tempFile.writeAsBytes(bytes);

      final dbHelper = DatabaseHelper();
      final dbFile = await _databaseFile;
      final walFile = File('${dbFile.path}-wal');
      final shmFile = File('${dbFile.path}-shm');

      // 1. Create a safety backup
      await createBackup();

      // 2. Close Database
      await dbHelper.close();

      // 3. Delete WAL/SHM
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      // 4. Copy temp file over current database
      await tempFile.copy(dbFile.path);

      // 5. Cleanup temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return true;
    } catch (e) {
      debugPrint('External restore error: $e');
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

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'PrestamosApp Backup',
        text: 'Respaldo de PrestamosApp',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }

  /// Share the most recent backup
  Future<bool> shareLatestBackup() async {
    final backups = await getLocalBackups();
    if (backups.isEmpty) {
      // Create a new backup if none exists
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

    // Delete oldest backups
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
    // Format: YYYYMMDD_HHMMSS
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
