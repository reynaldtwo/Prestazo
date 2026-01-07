// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../data/providers/providers.dart';

/// Screen for configuring scheduled backups
class ScheduledBackupScreen extends ConsumerStatefulWidget {
  const ScheduledBackupScreen({super.key});

  @override
  ConsumerState<ScheduledBackupScreen> createState() =>
      _ScheduledBackupScreenState();
}

class _ScheduledBackupScreenState extends ConsumerState<ScheduledBackupScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Form state
  String _frequency = 'NONE';
  int _retentionDays = 30;
  bool _backupOnLoan = false;
  bool _backupOnPayment = false;
  TimeOfDay? _scheduleTime;
  final TextEditingController _customNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    setState(() {
      _frequency = settings.backupFrequency;
      _retentionDays = settings.backupRetentionDays;
      _backupOnLoan = settings.backupOnLoanCreation;
      _backupOnPayment = settings.backupOnPayment;
      _customNameController.text = settings.backupCustomName ?? '';

      if (settings.backupScheduleTime != null) {
        final parts = settings.backupScheduleTime!.split(':');
        if (parts.length == 2) {
          _scheduleTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.getSettings();

      String? timeStr;
      if (_scheduleTime != null) {
        final h = _scheduleTime!.hour.toString().padLeft(2, '0');
        final m = _scheduleTime!.minute.toString().padLeft(2, '0');
        timeStr = '$h:$m';
      }

      await repo.updateSettings(
        settings.copyWith(
          backupFrequency: _frequency,
          backupRetentionDays: _retentionDays,
          backupOnLoanCreation: _backupOnLoan,
          backupOnPayment: _backupOnPayment,
          backupScheduleTime: timeStr,
          backupCustomName: _customNameController.text.trim().isEmpty
              ? null
              : _customNameController.text.trim(),
        ),
      );

      // Invalidate settings to refresh app
      ref.invalidate(appSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).backupSettingsSaved),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).genericError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).scheduledBackupTitle,
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),

          _buildSectionTitle(S.of(context).frequency),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(S.of(context).disabled),
                  value: 'NONE',
                  groupValue: _frequency,
                  onChanged: (v) => setState(() => _frequency = v!),
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(S.of(context).daily),
                  value: 'DAILY',
                  groupValue: _frequency,
                  onChanged: (v) => setState(() => _frequency = v!),
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(S.of(context).weekly),
                  value: 'WEEKLY',
                  groupValue: _frequency,
                  onChanged: (v) => setState(() => _frequency = v!),
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(S.of(context).monthly),
                  value: 'MONTHLY',
                  groupValue: _frequency,
                  onChanged: (v) => setState(() => _frequency = v!),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          if (_frequency != 'NONE') ...[
            const SizedBox(height: 16),
            ListTile(
              title: Text(S.of(context).preferredTime),
              subtitle: Text(_scheduleTime?.format(context) ?? '--:--'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _scheduleTime ?? TimeOfDay.now(),
                );
                if (t != null) setState(() => _scheduleTime = t);
              },
            ),
          ],

          const SizedBox(height: 24),
          _buildSectionTitle(S.of(context).automaticTriggers),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(S.of(context).onLoanCreation),
                  subtitle: Text(S.of(context).onLoanCreationDesc),
                  value: _backupOnLoan,
                  onChanged: (v) => setState(() => _backupOnLoan = v),
                  activeThumbColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(S.of(context).onPayment),
                  subtitle: Text(S.of(context).onPaymentDesc),
                  value: _backupOnPayment,
                  onChanged: (v) => setState(() => _backupOnPayment = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(S.of(context).advancedSettings),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppTextField(
                    controller: _customNameController,
                    label: S.of(context).fileNamePrefix,
                    hint: 'prestazo_backup',
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).keepBackupsFor(_retentionDays),
                        style: AppTypography.bodyMedium,
                      ),
                      Slider(
                        value: _retentionDays.toDouble(),
                        min: 1,
                        max: 90,
                        divisions: 89,
                        label: '$_retentionDays',
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _retentionDays = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(S.of(context).saveConfiguration),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).autoBackupInfo,
              style: AppTypography.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}
