// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/models/app_settings.dart';
import '../../../services/services.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/localization/locale_provider.dart';

import '../../../core/widgets/app_info_dialog.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _loanNumberController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _disbursementLegendController = TextEditingController();
  final _paymentLegendController = TextEditingController();

  // State variables
  bool _capitalizeInterest = false;
  int _moratoriumDays = 0;
  String _paymentOrder = 'INTEREST_FIRST';
  bool _validateDni = false;
  bool _shareReceiptsWhatsApp = false;
  bool _enableCapitalRestriction = true;
  int _capitalRestrictionDays = 10;
  bool _isLoaded = false;
  bool _dailyAccrualEnabled = false;
  bool _allowMultipleLoans = false;

  // Report settings state
  bool _showDisbursementSignatures = true;
  bool _showPaymentSignatures = true;
  bool _showDisbursementLegend = false;
  bool _showPaymentLegend = false;

  @override
  void dispose() {
    _loanNumberController.dispose();
    _receiptNumberController.dispose();
    _disbursementLegendController.dispose();
    _paymentLegendController.dispose();
    super.dispose();
  }

  void _loadSettings(AppSettings settings) {
    // Always update internal state to match settings
    if (_capitalizeInterest != settings.capitalizeUnpaidInterest) {
      _capitalizeInterest = settings.capitalizeUnpaidInterest;
    }
    _moratoriumDays = settings.moratoriumDays;
    _paymentOrder = settings.paymentApplyOrder;
    _dailyAccrualEnabled = settings.dailyAccrualEnabled;
    _allowMultipleLoans = settings.allowMultipleLoans;
    _validateDni = settings.validateDni;
    _shareReceiptsWhatsApp = settings.shareReceiptsWhatsApp;
    _enableCapitalRestriction = settings.enableCapitalRestriction;
    _capitalRestrictionDays = settings.capitalRestrictionDays;

    _showDisbursementSignatures = settings.showDisbursementSignatures;
    _showPaymentSignatures = settings.showPaymentSignatures;
    _showDisbursementLegend = settings.showDisbursementLegend;
    _showPaymentLegend = settings.showPaymentLegend;

    // Only update text controllers if they are empty (first load)
    // or if we want to force sync (like loan number which changes externally)
    if (!_isLoaded) {
      _disbursementLegendController.text = settings.disbursementLegend ?? '';
      _paymentLegendController.text = settings.paymentLegend ?? '';
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
    // Force global refresh to update Dashboard and other screens dependent on settings
    ref.read(refreshTriggerProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(S.of(context).genericError(e))),
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
                Text(S.of(context).catalog, style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _buildCatalogCard(),
                const SizedBox(height: 24),
                Text(
                  S.of(context).monetaryManagement,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMonetaryCard(),
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
                  S.of(context).reportSettings,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildReportSettingsCard(),
                const SizedBox(height: 24),
                Text(
                  S.of(context).validations,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildValidationsCard(),
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

  Widget _buildMonetaryCard() {
    return AppCard(
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: AppColors.primary),
        title: Text(S.of(context).monetaryManagement),
        subtitle: Text(S.of(context).monetarySubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed('monetary-settings'),
      ),
    );
  }

  Widget _buildValidationsCard() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user, color: AppColors.primary),
            title: Text(S.of(context).dniFormatTitle),
            subtitle: Text(S.of(context).dniFormatSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/dni-format'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(S.of(context).validateUniqueDni),
            subtitle: Text(
              _validateDni
                  ? S.of(context).validateUniqueDniDesc
                  : S.of(context).validateUniqueDniDescDisabled,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: _validateDni,
            onChanged: (v) {
              setState(() => _validateDni = v);
              _saveSetting('validate_dni', v ? 1 : 0);
            },
            secondary: InkWell(
              onTap: () {
                showAppInfoDialog(
                  context,
                  title: S.of(context).validateDniTitle,
                  info: S.of(context).validateDniDescription,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogCard() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.category, color: AppColors.primary),
            title: Text(S.of(context).categorizeCustomerAs),
            subtitle: Text(S.of(context).categorizeCustomerAsDesc),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).catalogInfoTitle,
                      info: S.of(context).catalogInfoDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/settings/customer-categories'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text(S.of(context).paymentFrequencies),
            subtitle: Text(S.of(context).paymentFrequenciesSubtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).paymentFrequenciesInfoTitle,
                      info: S.of(context).paymentFrequenciesInfoDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/settings/payment-frequencies'),
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
            secondary: InkWell(
              onTap: () {
                showAppInfoDialog(
                  context,
                  title: S.of(context).capitalizeInterestTitle,
                  info: S.of(context).capitalizeInterestDescription,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(S.of(context).dailyAccrual),
            subtitle: Text(S.of(context).dailyAccrualDesc),
            value: _dailyAccrualEnabled,
            onChanged: (v) {
              setState(() => _dailyAccrualEnabled = v);
              _saveSetting('daily_accrual_enabled', v ? 1 : 0);
            },
            secondary: InkWell(
              onTap: () {
                showAppInfoDialog(
                  context,
                  title: S.of(context).dailyAccrualTitle,
                  info: S.of(context).dailyAccrualDescription,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
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
            secondary: InkWell(
              onTap: () {
                showAppInfoDialog(
                  context,
                  title: S.of(context).allowMultipleLoansTitle,
                  info: S.of(context).allowMultipleLoansDescription,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(S.of(context).shareReceiptsWhatsApp),
            subtitle: Text(
              S.of(context).shareReceiptsWhatsAppDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: _shareReceiptsWhatsApp,
            onChanged: (v) {
              setState(() => _shareReceiptsWhatsApp = v);
              _saveSetting('share_receipts_whatsapp', v ? 1 : 0);
            },
            secondary: InkWell(
              onTap: () {
                showAppInfoDialog(
                  context,
                  title: S.of(context).whatsappReceiptsTitle,
                  info: S.of(context).whatsappReceiptsDescription,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(S.of(context).enableCapitalRestriction),
            subtitle: Text(S.of(context).enableCapitalRestrictionDesc),
            value: _enableCapitalRestriction,
            onChanged: (v) {
              setState(() => _enableCapitalRestriction = v);
              _saveSetting('enable_capital_restriction', v ? 1 : 0);
            },
            secondary: InkWell(
              onTap: () {
                showAppInfoDialog(
                  context,
                  title: S.of(context).capitalRestrictionTitle,
                  info: S.of(context).capitalRestrictionDescription,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          if (_enableCapitalRestriction)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).capitalRestrictionDays,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          S
                              .of(context)
                              .capitalRestrictionDaysDesc(
                                _capitalRestrictionDays,
                              ),
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        InkWell(
                          onTap: _capitalRestrictionDays > 1
                              ? () {
                                  setState(() => _capitalRestrictionDays--);
                                  _saveSetting(
                                    'capital_restriction_days',
                                    _capitalRestrictionDays,
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _capitalRestrictionDays > 1
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
                              color: _capitalRestrictionDays > 1
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.info
                                        : AppColors.primary)
                                  : Theme.of(context).colorScheme.outline,
                              size: 20,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          child: Text(
                            '$_capitalRestrictionDays',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _capitalRestrictionDays < 30
                              ? () {
                                  setState(() => _capitalRestrictionDays++);
                                  _saveSetting(
                                    'capital_restriction_days',
                                    _capitalRestrictionDays,
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _capitalRestrictionDays < 30
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
                              color: _capitalRestrictionDays < 30
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
          // Días de tolerancia con +/- buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.of(context).toleranceDays,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showAppInfoDialog(
                          context,
                          title: S.of(context).toleranceDaysTitle,
                          info: S.of(context).toleranceDaysDescription,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
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
                          _saveSetting('moratorium_days', _moratoriumDays);
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _moratoriumDays > 0
                          ? (Theme.of(context).brightness == Brightness.dark
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
                          ? (Theme.of(context).brightness == Brightness.dark
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
                          _saveSetting('moratorium_days', _moratoriumDays);
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _moratoriumDays < 30
                          ? (Theme.of(context).brightness == Brightness.dark
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
                          ? (Theme.of(context).brightness == Brightness.dark
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
          const Divider(),
          // Payment Order Header with Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).paymentOrder,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).paymentOrderTitle,
                      info: S.of(context).paymentOrderDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(
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
            // Header for Sequences Info
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).sequencesTitle,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).sequencesTitle,
                      info: S.of(context).sequencesDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

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

  Widget _buildReportSettingsCard() {
    return AppCard(
      child: Column(
        children: [
          // Header for Report Settings Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).reportSettings,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).reportSettingsTitle,
                      info: S.of(context).reportSettingsDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Report Currency with Info
          const Divider(height: 1),
          // Disbursement Signatures
          SwitchListTile(
            title: Text(S.of(context).showDisbursementSignatures),
            value: _showDisbursementSignatures,
            onChanged: (v) {
              setState(() => _showDisbursementSignatures = v);
              _saveSetting('show_disbursement_signatures', v ? 1 : 0);
            },
          ),
          // Payment Signatures
          SwitchListTile(
            title: Text(S.of(context).showPaymentSignatures),
            value: _showPaymentSignatures,
            onChanged: (v) {
              setState(() => _showPaymentSignatures = v);
              _saveSetting('show_payment_signatures', v ? 1 : 0);
            },
          ),
          const Divider(),

          // Disbursement Legend Toggle
          SwitchListTile(
            title: Text(S.of(context).showLegend),
            subtitle: Text(S.of(context).disbursementLegend),
            value: _showDisbursementLegend,
            onChanged: (v) {
              setState(() => _showDisbursementLegend = v);
              _saveSetting('show_disbursement_legend', v ? 1 : 0);
            },
          ),

          // Disbursement Legend Text Field (visible if toggle on)
          if (_showDisbursementLegend)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _disbursementLegendController,
                decoration: InputDecoration(
                  hintText: S.of(context).legendHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () => _saveSetting(
                      'disbursement_legend',
                      _disbursementLegendController.text.trim(),
                    ),
                  ),
                ),
                onSubmitted: (v) =>
                    _saveSetting('disbursement_legend', v.trim()),
              ),
            ),

          const Divider(),

          // Payment Legend Toggle
          SwitchListTile(
            title: Text(S.of(context).showLegend),
            subtitle: Text(S.of(context).paymentLegend),
            value: _showPaymentLegend,
            onChanged: (v) {
              setState(() => _showPaymentLegend = v);
              _saveSetting('show_payment_legend', v ? 1 : 0);
            },
          ),

          // Payment Legend Text Field (visible if toggle on)
          if (_showPaymentLegend)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _paymentLegendController,
                decoration: InputDecoration(
                  hintText: S.of(context).legendHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () => _saveSetting(
                      'payment_legend',
                      _paymentLegendController.text.trim(),
                    ),
                  ),
                ),
                onSubmitted: (v) => _saveSetting('payment_legend', v.trim()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    final settingsAsync = ref.watch(appSettingsProvider);
    final backupPath = settingsAsync.value?.backupPath;

    return AppCard(
      child: Column(
        children: [
          // Header for Maintenance
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).maintenanceTitle,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).maintenanceTitle,
                      info: S.of(context).maintenanceDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.backup,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.info
                  : AppColors.primary,
            ),
            title: Text(S.of(context).exportBackup),
            subtitle: Text(S.of(context).exportBackupDesc),
            onTap: _showExportDialog,
          ),
          if (!kIsWeb &&
              (Platform.isAndroid ||
                  Platform.isWindows ||
                  Platform.isLinux)) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder_open, color: AppColors.primary),
              title: const Text('Carpeta de Respaldo'),
              subtitle: Text(
                backupPath ?? 'Carpeta por defecto (Interna)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickBackupFolder,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.primary),
              title: Text(S.of(context).scheduledBackupTitle),
              subtitle: Text(S.of(context).scheduledBackupDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.goNamed('scheduled-backup'),
            ),
          ],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.of(context).creatingBackup)));

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
            // Appearance Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).appearanceTitle,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).appearanceTitle,
                      info: S.of(context).appearanceDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(S.of(context).themeMode, style: AppTypography.bodyMedium),
            const SizedBox(height: 4),
            Text(
              S.of(context).themeModeDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
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
            ),
            const Divider(height: 32),
            // Language selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).language,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).languageTitle,
                      info: S.of(context).languageDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
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

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<Locale?>(
        segments: [
          ButtonSegment<Locale?>(
            value: null,
            label: Text(S.of(context).languageSystem),
            icon: const Icon(Icons.settings_system_daydream),
          ),
          ButtonSegment<Locale?>(
            value: AppLocales.es,
            label: const Text('Español'),
            icon: const Text('🇪🇸'),
          ),
          ButtonSegment<Locale?>(
            value: AppLocales.en,
            label: const Text('English'),
            icon: const Text('🇺🇸'),
          ),
        ],
        selected: {currentLocale},
        onSelectionChanged: (Set<Locale?> selected) {
          localeNotifier.setLocale(selected.first);
        },
      ),
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).aboutTitle,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showAppInfoDialog(
                      context,
                      title: S.of(context).aboutTitle,
                      info: S.of(context).aboutDescription,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(S.of(context).appName),
            subtitle: const Text('Descubre lo que puedes hacer'),
            leading: const Icon(Icons.info_outline),
            onTap: () => context.push('/settings/about'),
          ),
        ],
      ),
    );
  }

  void _showPaymentOrderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).paymentOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(S.of(context).interestFirst),
              value: 'INTEREST_FIRST',
              groupValue: _paymentOrder,
              onChanged: (v) {
                setState(() => _paymentOrder = v!);
                _saveSetting('payment_apply_order', v);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: Text(S.of(context).principalFirst),
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
                Text(
                  S.of(context).localBackups,
                  style: AppTypography.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            if (backups.isEmpty)
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text(S.of(context).noBackupsAvailable)),
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
                                if (deleted && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  _viewBackups(); // Refresh
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () async {
                        // ignore: use_build_context_synchronously
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
                  _showExportDialog();
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
          // Show dialog informing user that app will restart
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(S.of(context).success),
                ],
              ),
              content: Text(S.of(context).restoreSuccessRestart),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Close the app to force complete restart
                    SystemNavigator.pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).errorRestoringBackup),
              backgroundColor: AppColors.danger,
            ),
          );
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
      }
    }
  }

  Future<void> _pickAndRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context); // Close the bottom sheet
          _confirmRestore(path, isExternal: true);
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showError('Error al seleccionar archivo: $e');
    }
  }

  void _restoreBackup() {
    _viewBackups();
  }

  void _recalculatePortfolio() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).recalculatingPortfolio)),
    );
  }

  // NEW METHODS FOR BACKUP FOLDER & EXPORT

  Future<void> _pickBackupFolder() async {
    final String? path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccionar carpeta para respaldos',
      lockParentWindow: true,
    );
    if (path != null) {
      // Save setting directly to DB via repository or helper, but here we use provider?
      // appSettingsProvider is read-only FutureProvider.
      // We need to write via SettingsRepository or Helper.
      // Easiest is to use Helper or Repository directly if available.
      // We have settingsRepositoryProvider.

      try {
        final repo = ref.read(settingsRepositoryProvider);
        await repo.updateSetting('backup_path', path);

        // Refresh provider
        ref.invalidate(appSettingsProvider);
      } catch (e) {
        if (mounted) _showError('Error al guardar configuración: $e');
      }
    }
  }

  void _showExportDialog() {
    final backupService = BackupService.instance;
    final defaultName = backupService.getDefaultExportName().replaceAll(
      '.db',
      '',
    );
    final nameController = TextEditingController(text: defaultName);
    final settingsAsync = ref.read(appSettingsProvider);
    final hasCustomFolder = settingsAsync.value?.backupPath != null;
    final backupPath = settingsAsync.value?.backupPath;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).createBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).backupFileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                suffixText: '.db',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            if (hasCustomFolder) ...[
              Text(
                S.of(context).backupDestFolder,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              Text(
                backupPath!,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              S.of(context).backupWhatToDo,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          if (hasCustomFolder)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(
                  nameController.text.trim(),
                  useCustomFolder: true,
                );
              },
              child: Text(S.of(context).save),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeExport(
                nameController.text.trim(),
                useCustomFolder: false,
              );
            },
            child: Text(
              Platform.isWindows || Platform.isLinux || Platform.isMacOS
                  ? S.of(context).backupSaveAs
                  : S.of(context).share,
            ),
          ),
        ],
      ),
    );
  }

  void _executeExport(String baseName, {required bool useCustomFolder}) async {
    if (baseName.isEmpty) return;

    final fileName = '$baseName.db';
    debugPrint('=== EXPORT START ===');
    debugPrint(
      'baseName: $baseName, fileName: $fileName, useCustomFolder: $useCustomFolder',
    );

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.of(context).backupProcessing)));
      }

      if (!useCustomFolder) {
        // Desktop "Save As" or Mobile "Share"
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          var outputPath = await FilePicker.platform.saveFile(
            dialogTitle: S.of(context).backupSaveDialogTitle,
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['db'],
            lockParentWindow: true,
          );

          if (outputPath == null) {
            debugPrint('User cancelled save dialog');
            return;
          }

          // Ensure .db extension
          if (!outputPath.toLowerCase().endsWith('.db')) {
            outputPath = '$outputPath.db';
          }
          debugPrint('Save As path: $outputPath');

          await _performBackup(customPath: outputPath);
          return;
        } else {
          // Mobile Share
          final tempDir = await getTemporaryDirectory();
          final tempPath = path.join(tempDir.path, fileName);
          debugPrint('Mobile share temp path: $tempPath');
          await _performBackup(customPath: tempPath, isShare: true);
          return;
        }
      }

      // Save to Custom Folder
      final settingsAsync = ref.read(appSettingsProvider);
      final backupPath = settingsAsync.value?.backupPath;
      debugPrint('Custom backup folder from settings: $backupPath');

      if (backupPath != null) {
        final targetPath = path.join(backupPath, fileName);
        debugPrint('Target path: $targetPath');

        // Check if folder exists
        final folder = Directory(backupPath);
        if (!await folder.exists()) {
          debugPrint('ERROR: Custom folder does not exist!');
          if (mounted) _showError(S.of(context).backupFolderNotExist);
          return;
        }

        // Check if file already exists - require name change
        final targetFile = File(targetPath);
        if (await targetFile.exists()) {
          debugPrint('File already exists, showing rename dialog...');
          if (mounted) {
            await _showFileExistsDialog();
            // Reopen export dialog so user can change name
            _showExportDialog();
          }
          return;
        }

        await _performBackup(customPath: targetPath);
      } else {
        debugPrint('ERROR: No custom backup path configured');
        if (mounted) _showError(S.of(context).backupNoFolderConfigured);
      }
    } catch (e, stackTrace) {
      debugPrint('=== EXPORT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        _showError('Error: $e');
      }
    }
  }

  Future<void> _performBackup({
    String? customPath,
    bool isShare = false,
    bool allowOverwrite = false,
  }) async {
    debugPrint('=== PERFORM BACKUP ===');
    debugPrint(
      'customPath: $customPath, isShare: $isShare, allowOverwrite: $allowOverwrite',
    );

    final backupService = BackupService.instance;
    final backup = await backupService.createBackup(
      customPath: customPath,
      allowOverwrite: allowOverwrite,
    );

    debugPrint('Backup result: ${backup != null ? "SUCCESS" : "FAILED"}');

    if (backup != null && mounted) {
      if (isShare) {
        await backupService.shareBackup(backup.filePath);
      } else {
        // If saved locally (Save As or Custom Folder), show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).backupSaved} ${backup.fileName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else if (mounted) {
      _showError(S.of(context).backupError);
    }
  }

  /// Show dialog when file already exists, requires user to change filename
  Future<void> _showFileExistsDialog() async {
    final s = S.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(s.fileExistsTitle),
          ],
        ),
        content: Text(s.backupFileExistsRename),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
