import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/database_providers.dart';
import '../../../core/localization/locale_provider.dart';

class DniFormatScreen extends ConsumerStatefulWidget {
  const DniFormatScreen({super.key});

  @override
  ConsumerState<DniFormatScreen> createState() => _DniFormatScreenState();
}

class _DniFormatScreenState extends ConsumerState<DniFormatScreen> {
  final _maskController = TextEditingController();
  final _testController = TextEditingController();
  bool _validateFormat = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = ref.read(appSettingsProvider).value;
    if (settings != null) {
      _maskController.text = settings.dniMask ?? '';
      _validateFormat = settings.validateDniFormat;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _maskController.dispose();
    _testController.dispose();
    super.dispose();
  }

  bool _validateInput(String input, String mask) {
    if (mask.isEmpty) return true;
    if (input.length != mask.length) return false;

    for (int i = 0; i < mask.length; i++) {
      final maskChar = mask[i];
      final inputChar = input[i];

      if (maskChar == '#') {
        if (!RegExp(r'\d').hasMatch(inputChar)) return false;
      } else if (maskChar == '@') {
        if (!RegExp(r'[a-zA-Z]').hasMatch(inputChar)) return false;
      } else if (maskChar == '*') {
        // Any char is fine
      } else {
        // Separator must match exactly
        if (inputChar != maskChar) return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);

      // Update individual settings
      await repo.updateSetting('dni_mask', _maskController.text.trim());
      await repo.updateSetting('validate_dni_format', _validateFormat ? 1 : 0);

      // Refresh provider
      ref.invalidate(appSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).configurationSaved),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validationResult = _validateFormat
        ? _validateInput(_testController.text, _maskController.text)
        : true;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).dniFormatTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(S.of(context).validateDniFormat),
            subtitle: Text(S.of(context).validateDniFormatDesc),
            value: _validateFormat,
            onChanged: (v) => setState(() => _validateFormat = v),
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(S.of(context).defineMaskTitle, style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(S.of(context).maskHelpText, style: AppTypography.bodySmall),
          const SizedBox(height: 16),
          AppTextField(
            label: S.of(context).maskLabel,
            hint: S.of(context).maskHint,
            controller: _maskController,
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 32),
          Text(S.of(context).testValidation, style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          AppTextField(
            label: S.of(context).testDniLabel,
            hint: S.of(context).testDniHint,
            controller: _testController,
            onChanged: (v) => setState(() {}),
            suffix: _testController.text.isEmpty
                ? null
                : Icon(
                    validationResult ? Icons.check_circle : Icons.error,
                    color: validationResult
                        ? AppColors.success
                        : AppColors.danger,
                  ),
          ),
          if (_testController.text.isNotEmpty && !validationResult)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                S.of(context).formatMismatch,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),

          const SizedBox(height: 32),
          AppButton(
            label: S.of(context).saveConfiguration,
            onPressed: _save,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
