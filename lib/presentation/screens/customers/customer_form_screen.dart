import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/models/customer.dart';
import '../../../data/providers/providers.dart';

/// Customer form screen for create/edit with Riverpod integration
class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

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
  Customer? _existingCustomer;

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
        setState(() {});
      }
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
      ),
      body: _isLoading && isEditing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Name field
                  AppTextField(
                    label: 'Nombre completo *',
                    hint: 'Ej: Juan Pérez García',
                    controller: _nameController,
                    prefixIcon: Icons.person,
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
                    hint: 'Ej: 001-010100-0000A',
                    controller: _dniController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El DNI es requerido';
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
                    label: isEditing ? 'Guardar Cambios' : 'Crear Cliente',
                    variant: AppButtonVariant.primary,
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final customer = isEditing
          ? _existingCustomer!.copyWith(
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
                    ? 'Cliente actualizado'
                    : 'Cliente creado exitosamente',
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
    } catch (e) {
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
