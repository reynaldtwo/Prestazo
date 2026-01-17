import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:uuid/uuid.dart';

/// Pantalla de formulario de cliente para creación y edición con integración de Riverpod.
class CustomerFormScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [CustomerFormScreen].
  const CustomerFormScreen({super.key, this.customerId});

  /// Identificador opcional del cliente para el modo edición.
  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _coordsController = TextEditingController();
  final _notesController = TextEditingController();
  final _payDayController = TextEditingController();
  final _restrictionReasonController = TextEditingController();

  String _billingFrequency = 'MONTHLY';
  int? _preferredPayDay;
  bool _isRestricted = false;
  bool _isLoading = false;
  late Customer _existingCustomer;
  String? _selectedCategoryId;

  bool get isEditing => widget.customerId != null && widget.customerId != 'new';

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerById(widget.customerId!);
      if (customer != null && mounted) {
        _existingCustomer = customer;
        _nameController.text = customer.fullName;
        _aliasController.text = customer.alias ?? '';
        _dniController.text = customer.dni ?? '';
        _phoneController.text = customer.phone ?? '';
        _addressController.text = customer.address ?? '';
        _coordsController.text = customer.coords ?? '';
        _notesController.text = customer.notes ?? '';
        _isRestricted = customer.isRestricted;
        _restrictionReasonController.text = customer.restrictionReason ?? '';
        _billingFrequency = customer.billingFrequency;
        _preferredPayDay = customer.preferredPayDay;
        if (_preferredPayDay != null) {
          _payDayController.text = _preferredPayDay.toString();
        }
        _selectedCategoryId = customer.categoryId;
        setState(() {});
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cliente: $e'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _coordsController.dispose();
    _notesController.dispose();
    _payDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? S.of(context).editCustomer : S.of(context).newCustomer,
        ),
      ),
      body: _isLoading && isEditing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Category dropdown (first field per requirement)
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Name field
                  AppTextField(
                    label: 'Nombre completo *',
                    hint: 'Ej: Juan Pérez García',
                    prefixIcon: Icons.person,
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 2) {
                        return 'El nombre es muy corto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // DNI Field
                  AppTextField(
                    label: 'DNI (Cédula) *',
                    hint: settings?.dniMask ?? 'Ej: 001-010100-0000A',
                    controller: _dniController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    inputFormatters:
                        (settings != null &&
                            settings.dniMask != null &&
                            settings.dniMask!.isNotEmpty)
                        ? [
                            MaskTextInputFormatter(
                              mask: settings.dniMask,
                              filter: {
                                '#': RegExp('[0-9]'),
                                '@': RegExp('[a-zA-Z]'),
                                '*': RegExp('.'),
                              },
                            ),
                          ]
                        : null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El DNI es requerido';
                      }

                      // Format validation
                      if (settings != null &&
                          settings.validateDniFormat &&
                          settings.dniMask != null &&
                          settings.dniMask!.isNotEmpty) {
                        final mask = settings.dniMask!;
                        final input = value.trim();

                        // Mask length check
                        if (input.length != mask.length) {
                          return 'El formato debe ser: $mask';
                        }

                        // Character check
                        for (var i = 0; i < mask.length; i++) {
                          final maskChar = mask[i];
                          final inputChar = input[i];

                          if (maskChar == '#') {
                            if (!RegExp(r'\d').hasMatch(inputChar)) {
                              return 'Posición ${i + 1} debe ser un dígito';
                            }
                          } else if (maskChar == '@') {
                            if (!RegExp('[a-zA-Z]').hasMatch(inputChar)) {
                              return 'Posición ${i + 1} debe ser una letra';
                            }
                          } else if (maskChar == '*') {
                            // Any char allowed
                          } else {
                            // Separator
                            if (inputChar != maskChar) {
                              return 'Falta el separador "$maskChar" en posición ${i + 1}';
                            }
                          }
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Alias field (Optional)
                  AppTextField(
                    label: 'Apodo / Alias',
                    hint: 'Ej: Juanito (opcional)',
                    controller: _aliasController,
                    prefixIcon: Icons.face,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Phone field
                  AppTextField(
                    label: 'Teléfono *',
                    hint: 'Ej: 8888-8888',
                    controller: _phoneController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El teléfono es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address field
                  AppTextField(
                    label: 'Dirección / Referencia *',
                    hint: 'Ej: Del mercado 2c al norte',
                    controller: _addressController,
                    prefixIcon: Icons.location_on,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La dirección es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // PIN (Coords) Field (Optional)
                  AppTextField(
                    label: 'PIN (Coordenadas)',
                    hint: 'Ej: 12.123456, -86.123456 (opcional)',
                    controller: _coordsController,
                    prefixIcon: Icons.pin_drop,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),

                  // Preferred pay day (Optional)
                  AppTextField(
                    label: 'Día preferido de pago',
                    hint: 'Ej: 15 (opcional, 1-31)',
                    controller: _payDayController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.calendar_today,
                    onChanged: (value) {
                      final day = int.tryParse(value);
                      if (day != null && day >= 1 && day <= 31) {
                        _preferredPayDay = day;
                      } else {
                        _preferredPayDay = null;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final day = int.tryParse(value);
                      if (day == null || day < 1 || day > 31) {
                        return 'Día inválido (1-31)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes field (Optional)
                  AppTextField(
                    label: 'Notas',
                    hint: 'Observaciones sobre el cliente...',
                    controller: _notesController,
                    prefixIcon: Icons.note,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Restriction fields (Only enabled in Edit mode)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEditing
                          ? AppColors.danger.withValues(alpha: 0.05)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: isEditing
                          ? Border.all(
                              color: AppColors.danger.withValues(alpha: 0.2),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _isRestricted,
                              onChanged: isEditing
                                  ? (value) {
                                      setState(() {
                                        _isRestricted = value ?? false;
                                      });
                                    }
                                  : null,
                            ),
                            const Expanded(
                              child: Text(
                                'Marcar cliente como "NO PRESTAR"',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isRestricted || isEditing)
                          AppTextField(
                            label: 'Motivo de restricción',
                            hint: 'Especifique la razón...',
                            controller: _restrictionReasonController,
                            prefixIcon: Icons.warning_amber,
                            maxLines: 2,
                            enabled: isEditing,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  AppButton(
                    label: isEditing
                        ? S.of(context).save
                        : S.of(context).createCustomer,
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categoriesAsync = ref.watch(customerCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<String?>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText:
                '${S.of(context).customerCategory} (${S.of(context).optional})',
            prefixIcon: const Icon(Icons.category),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String?>(
              child: Text(
                S.of(context).selectCategory,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...categories.map(
              (cat) => DropdownMenuItem<String?>(
                value: cat.categoryId,
                child: Text(cat.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
        );
      },
    );
  }

  void _showManualValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _submitForm() async {
    // 1. Force validation of UI fields
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      return;
    }

    // 2. EXTRA SAFETY: Manual Validation of DNI logic
    final settings = ref.read(appSettingsProvider).value;
    if ((settings?.validateDniFormat ?? false) && settings?.dniMask != null) {
      final mask = settings!.dniMask!;
      final dni = _dniController.text.trim();

      // Perform same logic as UI validator
      if (dni.isNotEmpty && dni.length != mask.length) {
        _showManualValidationError(
          'El DNI debe tener ${mask.length} caracteres',
        );
        return;
      }

      for (var i = 0; i < mask.length; i++) {
        final maskChar = mask[i];
        final inputChar = dni[i];
        var error = false;
        if (maskChar == '#') {
          if (!RegExp(r'\d').hasMatch(inputChar)) error = true;
        } else if (maskChar == '@') {
          if (!RegExp('[a-zA-Z]').hasMatch(inputChar)) error = true;
        } else if (maskChar == '*') {
          // ok
        } else {
          if (inputChar != maskChar) error = true;
        }

        if (error) {
          _showManualValidationError('El formato del DNI es inválido');
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      // Check for duplicate DNI if validation is enabled
      final settings = ref.read(appSettingsProvider).value;
      final dni = _dniController.text.trim();

      if ((settings?.validateDni ?? false) && dni.isNotEmpty) {
        final repo = ref.read(customerRepositoryProvider);
        final existingCustomer = await repo.getCustomerByDni(
          dni,
          excludeId: isEditing ? widget.customerId : null,
        );

        if (existingCustomer != null) {
          if (mounted) {
            setState(() => _isLoading = false);
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(S.of(context).dniDuplicate)),
                  ],
                ),
                content: Text(
                  'Ya existe un cliente registrado con el DNI "$dni":\n\n'
                  '• Nombre: ${existingCustomer.displayName}\n'
                  '• Teléfono: ${existingCustomer.phone ?? "No registrado"}\n\n'
                  'No se puede registrar dos clientes con el mismo DNI.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(S.of(context).understood),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      final now = DateTime.now();
      final customer = isEditing
          ? _existingCustomer.copyWith(
              fullName: _nameController.text.trim(),
              alias: _aliasController.text.trim().isEmpty
                  ? null
                  : _aliasController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              dni: _dniController.text.trim(),
              coords: _coordsController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              billingFrequency: _billingFrequency,
              preferredPayDay: _preferredPayDay,
              isRestricted: _isRestricted,
              restrictionReason:
                  _restrictionReasonController.text.trim().isEmpty
                  ? null
                  : _restrictionReasonController.text.trim(),
              categoryId: _selectedCategoryId,
              updatedAt: now,
            )
          : Customer(
              customerId: const Uuid().v4(),
              fullName: _nameController.text.trim(),
              alias: _aliasController.text.trim().isEmpty
                  ? null
                  : _aliasController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              dni: _dniController.text.trim(),
              coords: _coordsController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              billingFrequency: _billingFrequency,
              preferredPayDay: _preferredPayDay,
              isRestricted: _isRestricted,
              restrictionReason:
                  _restrictionReasonController.text.trim().isEmpty
                  ? null
                  : _restrictionReasonController.text.trim(),
              categoryId: _selectedCategoryId,
              createdAt: now,
              updatedAt: now,
            );

      final notifier = ref.read(customersProvider.notifier);
      final success = isEditing
          ? await notifier.updateCustomer(customer)
          : await notifier.addCustomer(customer);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? S.of(context).customerUpdated
                    : S.of(context).customerCreated,
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          final error = ref.read(customersProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error ?? "Desconocido"}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
