import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/data/models/app_settings.dart';

void main() {
  group('AppSettings Backup Fields', () {
    test('should have default backup values', () {
      final settings = AppSettings.defaults();
      expect(settings.backupFrequency, 'NONE');
      expect(settings.backupRetentionDays, 30);
      expect(settings.backupOnLoanCreation, false);
      expect(settings.backupOnPayment, false);
      expect(settings.backupRetries, 3);
    });

    test('should copyWith backup values', () {
      final settings = AppSettings.defaults();
      final newSettings = settings.copyWith(
        backupFrequency: 'DAILY',
        backupRetentionDays: 14,
        backupOnLoanCreation: true,
        backupOnPayment: true,
        backupScheduleTime: '12:00',
        backupCustomName: 'test_backup',
        backupRetries: 5,
      );

      expect(newSettings.backupFrequency, 'DAILY');
      expect(newSettings.backupRetentionDays, 14);
      expect(newSettings.backupOnLoanCreation, true);
      expect(newSettings.backupOnPayment, true);
      expect(newSettings.backupScheduleTime, '12:00');
      expect(newSettings.backupCustomName, 'test_backup');
      expect(newSettings.backupRetries, 5);
    });

    test('should serialize to map', () {
      final settings = AppSettings.defaults().copyWith(
        backupFrequency: 'WEEKLY',
      );
      final map = settings.toMap();
      expect(map['backup_frequency'], 'WEEKLY');
      expect(map['backup_retention_days'], 30);
    });
  });
}
