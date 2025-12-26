import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/providers/loan_provider.dart';
import '../../../services/services.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/localization/locale_provider.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _capitalController = TextEditingController();
  final _loanNumberController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  bool _capitalizeInterest = false;
  int _moratoriumDays = 1;
  String _paymentOrder = 'INTEREST_FIRST';
  double _availableCapital = 0;
  bool _validateCapital = false;
  bool _dailyAccrualEnabled = false;
  bool _allowMultipleLoans = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _capitalController.dispose();
    _loanNumberController.dispose();
    _receiptNumberController.dispose();
    super.dispose();
  }

  void _loadSettings(AppSettings settings) {
    // Always update internal state to match settings
    if (_capitalizeInterest != settings.capitalizeUnpaidInterest) {
      _capitalizeInterest = settings.capitalizeUnpaidInterest;
    }
    _moratoriumDays = settings.moratoriumDays;
    _paymentOrder = settings.paymentApplyOrder;
    _availableCapital = settings.availableCapital;
    _validateCapital = settings.validateCapital;
    _dailyAccrualEnabled = settings.dailyAccrualEnabled;
    _allowMultipleLoans = settings.allowMultipleLoans;

    // Only update text controllers if they are empty (first load)
    // or if we want to force sync (like loan number which changes externally)
    if (!_isLoaded) {
      _capitalController.text = _availableCapital > 0
          ? _availableCapital.toStringAsFixed(0)
          : '';
      _isLoaded = true;
    }

    // Always sync loan number (Display Last Used = Next - 1)
    final correctLoanNum = _decrementStringCode(settings.loanNextNumber);
    if (_loanNumberController.text != correctLoanNum) {
      _loanNumberController.text = correctLoanNum;
    }

    // Always sync receipt number
    final correctReceiptNum = _decrementStringCode(settings.receiptNextNumber);
    if (_receiptNumberController.text != correctReceiptNum) {
      _receiptNumberController.text = correctReceiptNum;
    }
  }

  /// Helper to decrement alphanumeric codes (Display Logic)
  /// Reverses the increment logic to show the "Last Used" code
  String _decrementStringCode(String code) {
    if (code == '1') return '0';
    if (code.isEmpty) return '';

    final RegExp regex = RegExp(r'(\d+)$');
    final match = regex.firstMatch(code);

    if (match != null) {
      final numberStr = match.group(1)!;
      final prefix = code.substring(0, code.length - numberStr.length);
      final number = int.parse(numberStr);

      if (number > 0) {
        final newNumber = number - 1;
        // Preserve padding
        String newNumberStr = newNumber.toString();
        if (newNumberStr.length < numberStr.length) {
          newNumberStr = newNumberStr.padLeft(numberStr.length, '0');
        }
        return '$prefix$newNumberStr';
      }
    }
    return code; // Fallback if cannot decrement
  }

  /// Helper to increment alphanumeric codes (Save Logic)
  String _incrementStringCode(String code) {
    if (code.isEmpty) return '1';

    final RegExp regex = RegExp(r'(\d+)$');
    final match = regex.firstMatch(code);

    if (match != null) {
      final numberStr = match.group(1)!;
      final prefix = code.substring(0, code.length - numberStr.length);
      final number = int.parse(numberStr);
      final newNumber = number + 1;

      String newNumberStr = newNumber.toString();
      if (newNumberStr.length < numberStr.length) {
        newNumberStr = newNumberStr.padLeft(numberStr.length, '0');
      }
      return '$prefix$newNumberStr';
    } else {
      return '${code}1';
    }
  }

  // ... (Keeping _saveSetting unchanged) ...
  Future<void> _saveSetting(String key, dynamic value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateSetting(key, value);
    ref.invalidate(appSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          _loadSettings(settings);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(appSettingsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(S.of(context).business, style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _buildCompanyCard(),
                const SizedBox(height: 24),
                Text(
                  S.of(context).businessCapital,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildCapitalCard(),
                const SizedBox(height: 24),
                Text(
                  S.of(context).businessPolicies,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildPoliciesCard(),
                const SizedBox(height: 24),
                Text(S.of(context).sequences, style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _buildSequencesCard(),
                const SizedBox(height: 24),
                Text(
                  S.of(context).maintenance,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMaintenanceCard(),
                const SizedBox(height: 24),
                Text(S.of(context).appearance, style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _buildAppearanceCard(),
                const SizedBox(height: 24),
                Text(S.of(context).about, style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _buildAboutCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyCard() {
    return AppCard(
      child: ListTile(
        leading: const Icon(Icons.business, color: AppColors.primary),
        title: Text(S.of(context).companyData),
        subtitle: Text(S.of(context).companySubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/settings/company'),
      ),
    );
  }

  Widget _buildCapitalCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).availableCapital,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  S.of(context).availableCapitalDesc,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _capitalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixText: 'C\$ ',
                    hintText: '0',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, color: AppColors.success),
                      onPressed: () {
                        final value =
                            double.tryParse(_capitalController.text) ?? 0;
                        setState(() => _availableCapital = value);
                        _saveSetting('available_capital', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(S.of(context).capitalSaved)),
                        );
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    final val = double.tryParse(value) ?? 0;
                    setState(() => _availableCapital = val);
                    _saveSetting('available_capital', val);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(S.of(context).validateCapital),
            subtitle: Text(
              _validateCapital
                  ? S.of(context).validateCapitalDesc
                  : S.of(context).validateCapitalDescDisabled,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: _validateCapital,
            onChanged: (v) {
              setState(() => _validateCapital = v);
              _saveSetting('validate_capital', v ? 1 : 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesCard() {
    return AppCard(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(S.of(context).capitalizeInterest),
            subtitle: Text(S.of(context).capitalizeInterestDesc),
            value: _capitalizeInterest,
            onChanged: (v) {
              setState(() => _capitalizeInterest = v);
              _saveSetting('capitalize_unpaid_interest', v ? 1 : 0);
            },
          ),
          SwitchListTile(
            title: Text(S.of(context).dailyAccrual),
            subtitle: Text(S.of(context).dailyAccrualDesc),
            value: _dailyAccrualEnabled,
            onChanged: (v) {
              setState(() => _dailyAccrualEnabled = v);
              _saveSetting('daily_accrual_enabled', v ? 1 : 0);
            },
          ),
          SwitchListTile(
            title: Text(S.of(context).allowMultipleLoans),
            subtitle: Text(
              _allowMultipleLoans
                  ? S.of(context).allowMultipleLoansDesc
                  : S.of(context).allowMultipleLoansDescDisabled,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: _allowMultipleLoans,
            onChanged: (v) {
              setState(() => _allowMultipleLoans = v);
              _saveSetting('allow_multiple_loans', v ? 1 : 0);
            },
          ),
          const Divider(),
          // Días de tolerancia con +/- buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).toleranceDays,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context).toleranceDaysDesc,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Counter with +/- buttons
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      InkWell(
                        onTap: _moratoriumDays > 0
                            ? () {
                                setState(() => _moratoriumDays--);
                                _saveSetting(
                                  'moratorium_days',
                                  _moratoriumDays,
                                );
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _moratoriumDays > 0
                                ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.info
                                          : AppColors.primary)
                                      .withValues(alpha: 0.1)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(7),
                              bottomLeft: Radius.circular(7),
                            ),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: _moratoriumDays > 0
                                ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.info
                                      : AppColors.primary)
                                : Theme.of(context).colorScheme.outline,
                            size: 20,
                          ),
                        ),
                      ),
                      // Value display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Text(
                          '$_moratoriumDays',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Plus button
                      InkWell(
                        onTap: _moratoriumDays < 30
                            ? () {
                                setState(() => _moratoriumDays++);
                                _saveSetting(
                                  'moratorium_days',
                                  _moratoriumDays,
                                );
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _moratoriumDays < 30
                                ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.info
                                          : AppColors.primary)
                                      .withValues(alpha: 0.1)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: _moratoriumDays < 30
                                ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.info
                                      : AppColors.primary)
                                : Theme.of(context).colorScheme.outline,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(S.of(context).paymentOrder),
            subtitle: Text(
              _paymentOrder == 'INTEREST_FIRST'
                  ? S.of(context).paymentOrderInterestFirst
                  : S.of(context).paymentOrderCapitalFirst,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPaymentOrderDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSequencesCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Sequence
            Text(
              S.of(context).lastLoanGenerated,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).nextLoanSequenceDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loanNumberController,
              keyboardType: TextInputType.text, // Allow alphanumeric
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                prefixText: '# ',
                hintText: 'A-000',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: () => _saveLoanNumber(),
                ),
              ),
              onSubmitted: (_) => _saveLoanNumber(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),

            // Receipt Sequence
            Text(
              S.of(context).lastReceiptGenerated,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).nextReceiptSequenceDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _receiptNumberController,
              keyboardType: TextInputType.text, // Allow alphanumeric
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                prefixText: '# ',
                hintText: 'R-000',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: () => _saveReceiptNumber(),
                ),
              ),
              onSubmitted: (_) => _saveReceiptNumber(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLoanNumber() async {
    final value = _loanNumberController.text.trim();
    if (value.isEmpty) return;

    // Strict validation removed for alphanumeric flexibility.
    // User is trusted to set the correct "Last Used" value.

    // Input is "Last Used", so Next = Input + 1 (using alphanumeric logic)
    final nextNumber = _incrementStringCode(value);
    await _saveSetting('loan_next_number', nextNumber);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).sequenceUpdated)));
    }
  }

  Future<void> _saveReceiptNumber() async {
    final value = _receiptNumberController.text.trim();
    if (value.isEmpty) return;

    final nextNumber = _incrementStringCode(value);
    await _saveSetting('receipt_next_number', nextNumber);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).receiptSequenceUpdated)),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  Widget _buildMaintenanceCard() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.backup,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.info
                  : AppColors.primary,
            ),
            title: Text(S.of(context).exportBackup),
            subtitle: Text(S.of(context).exportBackupDesc),
            onTap: _exportBackup,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore, color: AppColors.warning),
            title: Text(S.of(context).restoreBackup),
            subtitle: Text(S.of(context).restoreBackupDesc),
            onTap: _restoreBackup,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync, color: AppColors.info),
            title: Text(S.of(context).recalculatePortfolio),
            subtitle: Text(S.of(context).recalculatePortfolioDesc),
            onTap: _recalculatePortfolio,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: Text(S.of(context).deleteData),
            subtitle: Text(S.of(context).deleteDataDesc),
            onTap: _showDeletionOptions,
          ),
        ],
      ),
    );
  }

  Future<void> _showDeletionOptions() async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(context).deleteDialogTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'PAYMENTS'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).deletePayments,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    S.of(context).deletePaymentsDesc,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'LOANS'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).deleteLoans,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    S.of(context).deleteLoansDesc,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'CUSTOMERS'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).deleteCustomers,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    S.of(context).deleteCustomersDesc,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ALL'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                S.of(context).deleteAll,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (option != null && mounted) {
      // Validate customer deletion constraint
      if (option == 'CUSTOMERS') {
        final dbHelper = ref.read(databaseHelperProvider);
        final hasActive = await dbHelper.hasActiveLoans();

        if (hasActive) {
          if (mounted) {
            _showErrorDialog(
              S.of(context).restrictedAction,
              S.of(context).deleteRestrictedMsg,
            );
          }
          return;
        }
      }

      _confirmAndExecuteDeletion(option);
    }
  }

  Future<void> _confirmAndExecuteDeletion(String option) async {
    final String title;
    final String message;

    switch (option) {
      case 'PAYMENTS':
        title = '¿Borrar solo PAGOS?';
        message =
            'Se eliminarán todos los registros de pagos. Los préstamos volverán a estado pendiente si corresponde.';
        break;
      case 'LOANS':
        title = '¿Borrar PRÉSTAMOS?';
        message =
            'Se eliminarán todos los préstamos y sus pagos asociados. Los clientes se mantendrán.';
        break;
      case 'CUSTOMERS':
        title = '¿Borrar CLIENTES?';
        message =
            'Se eliminarán los clientes seleccionados. (Esta opción borrará todo si no hay préstamos activos)';
        break;
      case 'ALL':
        title =
            '${S.of(context).confirmDeleteTitle} ${S.of(context).deleteAll}';
        message = S.of(context).deleteAllDesc;
        break;
      default:
        return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Se creará una copia de seguridad automática antes de borrar.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar y Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 1. Create Backup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creando respaldo de seguridad...')),
        );

        final backupService = BackupService.instance;
        final backup = await backupService.createBackup();

        if (backup == null) {
          throw Exception(
            'No se pudo crear el respaldo de seguridad. Abortando.',
          );
        }

        // 2. Execute Deletion
        final dbHelper = ref.read(databaseHelperProvider);

        switch (option) {
          case 'PAYMENTS':
            await dbHelper.deletePaymentsOnly();
            break;
          case 'LOANS':
            await dbHelper.deleteLoansAndRelated();
            break;
          case 'CUSTOMERS':
            // Logic handled by check above + generic call or specific
            // If we reached here, it's safe to delete customers (no active loans)
            // or simply delete everything related to customers (which implies loans)
            // But the requirement said "cannot... but indicate".
            // If we passed the check, we use deleteCustomersAndRelated which cleans up.
            await dbHelper.deleteCustomersAndRelated();
            break;
          case 'ALL':
            await dbHelper.deleteAllData();
            break;
        }

        // 3. Global Refresh
        ref.invalidate(appSettingsProvider);
        ref.read(refreshTriggerProvider.notifier).state++;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos eliminados correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Error', e.toString());
        }
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard() {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).themeMode, style: AppTypography.bodyMedium),
            const SizedBox(height: 4),
            Text(
              S.of(context).themeModeDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(S.of(context).light),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(S.of(context).dark),
                  icon: const Icon(Icons.dark_mode),
                ),
              ],
              selected: {
                themeMode == ThemeMode.system ? ThemeMode.light : themeMode,
              },
              onSelectionChanged: (Set<ThemeMode> selected) {
                themeNotifier.setThemeMode(selected.first);
              },
            ),
            const Divider(height: 32),
            // Language selector
            Text(S.of(context).language, style: AppTypography.bodyMedium),
            const SizedBox(height: 4),
            Text(
              S.of(context).languageDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return SegmentedButton<Locale>(
      segments: [
        ButtonSegment(
          value: AppLocales.spanish,
          label: const Text('Español'),
          icon: const Text('🇪🇸'),
        ),
        ButtonSegment(
          value: AppLocales.english,
          label: const Text('English'),
          icon: const Text('🇺🇸'),
        ),
      ],
      selected: {currentLocale},
      onSelectionChanged: (Set<Locale> selected) {
        localeNotifier.setLocale(selected.first);
      },
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            title: Text(S.of(context).appName),
            subtitle: const Text('Descubre lo que puedes hacer'),
            leading: const Icon(Icons.info_outline),
            onTap: () => context.push('/settings/about'),
          ),
          const Divider(),
          const ListTile(
            title: Text('Moneda'),
            trailing: Text('NIO (Córdobas)'),
          ),
        ],
      ),
    );
  }

  void _showPaymentOrderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Orden de aplicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Interés primero'),
              value: 'INTEREST_FIRST',
              groupValue: _paymentOrder,
              onChanged: (v) {
                setState(() => _paymentOrder = v!);
                _saveSetting('payment_apply_order', v);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('Capital primero'),
              value: 'PRINCIPAL_FIRST',
              groupValue: _paymentOrder,
              onChanged: (v) {
                setState(() => _paymentOrder = v!);
                _saveSetting('payment_apply_order', v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportBackup() async {
    try {
      // Show loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Creando respaldo...')));

      // Create backup
      final backupService = BackupService.instance;
      final backup = await backupService.createBackup();

      if (backup != null && mounted) {
        // Share the backup
        final shared = await backupService.shareBackup(backup.filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shared
                  ? 'Respaldo creado y compartido: ${backup.fileName}'
                  : 'Respaldo creado: ${backup.fileName}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear respaldo'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _viewBackups() async {
    final backupService = BackupService.instance;
    final backups = await backupService.getLocalBackups();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Respaldos Locales', style: AppTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            if (backups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No hay respaldos disponibles')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: backups.length,
                  itemBuilder: (_, i) {
                    final backup = backups[i];
                    return ListTile(
                      leading: const Icon(Icons.backup),
                      title: Text(backup.fileName),
                      subtitle: Text(
                        '${_formatBackupDate(backup.createdAt)} - ${backup.formattedSize}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () async {
                              await backupService.shareBackup(backup.filePath);
                            },
                          ),
                          if (i > 0) // Can't delete most recent
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                              onPressed: () async {
                                final deleted = await backupService
                                    .deleteBackup(backup.filePath);
                                if (deleted) {
                                  Navigator.pop(ctx);
                                  _viewBackups(); // Refresh
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        _confirmRestore(backup.filePath);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _exportBackup();
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Nuevo Respaldo'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickAndRestoreBackup,
                icon: const Icon(Icons.folder_open),
                label: const Text('Buscar Archivo de Respaldo...'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBackupDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmRestore(String backupPath, {bool isExternal = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Restaurar Respaldo'),
          ],
        ),
        content: const Text(
          '¿Está seguro de restaurar este respaldo?\n\n'
          'Se creará un respaldo de los datos actuales antes de restaurar.\n\n'
          'Deberá reiniciar la aplicación después de restaurar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final backupService = BackupService.instance;
        final success = isExternal
            ? await backupService.restoreFromExternalFile(backupPath)
            : await backupService.restoreFromBackup(backupPath);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Respaldo restaurado. Actualizando datos...'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          // Force UI to reload text controllers
          setState(() {
            _isLoaded = false;
          });

          // Invalidate ALL data providers to reflect restored state
          ref.invalidate(appSettingsProvider);
          ref.invalidate(loansProvider);
          ref.invalidate(customerRepositoryProvider);
          ref.invalidate(dashboardProvider);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al restaurar respaldo'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAndRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          Navigator.pop(context); // Close the bottom sheet
          _confirmRestore(path, isExternal: true);
        }
      }
    } catch (e) {
      if (mounted) _showError('Error al seleccionar archivo: $e');
    }
  }

  void _restoreBackup() {
    _viewBackups();
  }

  void _recalculatePortfolio() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recalculando cartera...')));
  }
}
