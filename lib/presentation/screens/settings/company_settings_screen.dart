import 'package:country_picker/country_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/providers/providers.dart';

/// Pantalla de configuración de datos de la empresa.
class CompanySettingsScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [CompanySettingsScreen].
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _rucController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cellController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _logoPathController = TextEditingController();
  String? _selectedCountryCode;

  // Visibility Flags
  bool _showName = false;
  bool _showRuc = false;
  bool _showPhone = false;
  bool _showCell = false;
  bool _showWhatsapp = false;
  bool _showAddress = false;
  bool _showLogo = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(appSettingsProvider).value;
    if (settings != null) {
      _nameController.text = settings.companyName ?? '';
      _selectedCountryCode = settings.companyCountryCode;
      if (_selectedCountryCode != null) {
        final country = Country.tryParse(_selectedCountryCode!);
        _countryController.text = country != null
            ? '${country.flagEmoji} ${country.name}'
            : _selectedCountryCode!;
      }
      _rucController.text = settings.companyRuc ?? '';
      _phoneController.text = settings.companyPhone ?? '';
      _cellController.text = settings.companyCell ?? '';
      _whatsappController.text = settings.companyWhatsapp ?? '';
      _addressController.text = settings.companyAddress ?? '';
      _logoPathController.text = settings.companyLogoPath ?? '';

      _showName = settings.showCompanyName;
      _showRuc = settings.showCompanyRuc;
      _showPhone = settings.showCompanyPhone;
      _showCell = settings.showCompanyCell;
      _showWhatsapp = settings.showCompanyWhatsapp;
      _showAddress = settings.showCompanyAddress;
      _showLogo = settings.showCompanyLogo;

      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rucController.dispose();
    _phoneController.dispose();
    _cellController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _logoPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).companyData)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildSectionHeader(S.of(context).identity),
            _buildCountryField(), // Country first per user requirement
            _buildFieldWithToggle(
              controller: _nameController,
              label: S.of(context).companyName,
              icon: Icons.business,
              value: _showName,
              onChanged: (v) => setState(() => _showName = v),
            ),
            _buildFieldWithToggle(
              controller: _rucController,
              label: S.of(context).rucId,
              icon: Icons.confirmation_number,
              value: _showRuc,
              onChanged: (v) => setState(() => _showRuc = v),
            ),
            _buildSectionHeader(S.of(context).contact),
            _buildFieldWithToggle(
              controller: _phoneController,
              label: S.of(context).phoneFixed,
              icon: Icons.phone,
              value: _showPhone,
              onChanged: (v) => setState(() => _showPhone = v),
              keyboardType: TextInputType.phone,
            ),
            _buildFieldWithToggle(
              controller: _cellController,
              label: S.of(context).cellPhone,
              icon: Icons.smartphone,
              value: _showCell,
              onChanged: (v) => setState(() => _showCell = v),
              keyboardType: TextInputType.phone,
            ),
            _buildFieldWithToggle(
              controller: _whatsappController,
              label: S.of(context).whatsapp,
              icon: Icons.chat,
              value: _showWhatsapp,
              onChanged: (v) => setState(() => _showWhatsapp = v),
              keyboardType: TextInputType.phone,
            ),
            _buildSectionHeader(S.of(context).location),
            _buildFieldWithToggle(
              controller: _addressController,
              label: S.of(context).address,
              icon: Icons.location_on,
              value: _showAddress,
              onChanged: (v) => setState(() => _showAddress = v),
              maxLines: 2,
            ),
            _buildSectionHeader(S.of(context).branding),
            _buildLogoField(),
            const SizedBox(height: 32),
            AppButton(
              label: S.of(context).saveChanges,
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 32),
          ],
        ),
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
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).companyInfoHelp,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildFieldWithToggle({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              controller: controller,
              label: label,
              hint: hint,
              prefixIcon: icon,
              keyboardType: keyboardType ?? TextInputType.text,
              maxLines: maxLines,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              const SizedBox(height: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(
                  value ? AppColors.primary : null,
                ),
              ),
              Text(
                value ? S.of(context).visible : S.of(context).hidden,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppTextField(
        controller: _countryController,
        label: S.of(context).countryOfOperation,
        hint: S.of(context).selectCountry,
        prefixIcon: Icons.public,
        readOnly: true,
        onTap: _pickCountry,
      ),
    );
  }

  Future<void> _pickCountry() async {
    final result = await context.push<String>('/settings/country-selection');
    if (result != null && mounted) {
      setState(() {
        _selectedCountryCode = result;
        final country = Country.tryParse(result);
        _countryController.text = country != null
            ? '${country.flagEmoji} ${country.name}'
            : result;
      });
    }
  }

  Widget _buildLogoField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _logoPathController,
                    label: S.of(context).logoPath,
                    hint: S.of(context).selectFile,
                    prefixIcon: Icons.image,
                    readOnly: true, // Only allow picking via button
                    onTap: _pickLogo,
                  ),
                ),
                IconButton(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.folder_open, color: AppColors.primary),
                  tooltip: 'Seleccionar Imagen',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              const SizedBox(height: 8),
              Switch(
                value: _showLogo,
                onChanged: (v) => setState(() => _showLogo = v),
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(
                  _showLogo ? AppColors.primary : null,
                ),
              ),
              Text(
                _showLogo ? S.of(context).visible : S.of(context).hidden,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        // Simple validation check (FilePicker usually handles this but good to double check or if user manually pasted before readonly)
        if (!path.toLowerCase().endsWith('.png')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).onlyPng),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }

        setState(() {
          _logoPathController.text = path;
          _showLogo = true; // Auto-enable visibility when selected
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).errorPickingImage} $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      final currentSettings = ref.read(appSettingsProvider).value!;
      final newSettings = currentSettings.copyWith(
        companyName: _nameController.text.trim(),
        companyCountryCode: _selectedCountryCode,
        showCompanyName: _showName,
        companyRuc: _rucController.text.trim(),
        showCompanyRuc: _showRuc,
        companyPhone: _phoneController.text.trim(),
        showCompanyPhone: _showPhone,
        companyCell: _cellController.text.trim(),
        showCompanyCell: _showCell,
        companyWhatsapp: _whatsappController.text.trim(),
        showCompanyWhatsapp: _showWhatsapp,
        companyAddress: _addressController.text.trim(),
        showCompanyAddress: _showAddress,
        companyLogoPath: _logoPathController.text.trim(),
        showCompanyLogo: _showLogo,
      );

      // Using updateGlobalSettings (assuming it exists or using updateSetting iteratively)
      // Since we modified many fields, let's see if there is a bulk update or we iterate.
      // Checking SettingsRepository... usually key-value.
      // Let's implement a bulk update or just update one by one for now if no bulk.
      // BETTER: Update the repository to support saving the whole object or map.

      // For now, I'll update each field individually as typically repositories have key-value updates.
      // Actually, looking at previous knowledge, we update specific keys.
      // Let's check SettingsRepository implementation.

      // Just in case, I will try to use a bulk update method if available, or call updateSetting multiple times.
      // Ideally, we should add a saveSettings method to the repository.

      // PROVISIONAL: Calling updateSetting for each field.
      await repo.updateSetting('company_name', newSettings.companyName);
      await repo.updateSetting(
        'company_country_code',
        newSettings.companyCountryCode,
      );
      await repo.updateSetting(
        'show_company_name',
        newSettings.showCompanyName ? 1 : 0,
      );
      await repo.updateSetting('company_ruc', newSettings.companyRuc);
      await repo.updateSetting(
        'show_company_ruc',
        newSettings.showCompanyRuc ? 1 : 0,
      );
      await repo.updateSetting('company_phone', newSettings.companyPhone);
      await repo.updateSetting(
        'show_company_phone',
        newSettings.showCompanyPhone ? 1 : 0,
      );
      await repo.updateSetting('company_cell', newSettings.companyCell);
      await repo.updateSetting(
        'show_company_cell',
        newSettings.showCompanyCell ? 1 : 0,
      );
      await repo.updateSetting('company_whatsapp', newSettings.companyWhatsapp);
      await repo.updateSetting(
        'show_company_whatsapp',
        newSettings.showCompanyWhatsapp ? 1 : 0,
      );
      await repo.updateSetting('company_address', newSettings.companyAddress);
      await repo.updateSetting(
        'show_company_address',
        newSettings.showCompanyAddress ? 1 : 0,
      );
      await repo.updateSetting(
        'company_logo_path',
        newSettings.companyLogoPath,
      );
      await repo.updateSetting(
        'show_company_logo',
        newSettings.showCompanyLogo ? 1 : 0,
      );

      ref.invalidate(appSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).companyDataUpdated),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).errorSaving(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
