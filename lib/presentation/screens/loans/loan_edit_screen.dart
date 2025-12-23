import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/loan.dart';
import '../../../data/providers/providers.dart';
import '../../../services/billing_cycle_service.dart';

/// Screen for editing an existing loan
/// Note: Allows editing Capital, Date, Rate, Notes.
class LoanEditScreen extends ConsumerStatefulWidget {
  final String loanId;

  const LoanEditScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanEditScreen> createState() => _LoanEditScreenState();
}

class _LoanEditScreenState extends ConsumerState<LoanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _principalController = TextEditingController();
  DateTime? _disbursementDate;
  DateTime? _endDate;
  String _billingFrequency = 'MONTHLY';

  Loan? _loan;
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLoan();
  }

  Future<void> _loadLoan() async {
    try {
      final repo = ref.read(loanRepositoryProvider);
      final loan = await repo.getLoanById(widget.loanId);

      if (!mounted) return;

      if (loan != null) {
        setState(() {
          _loan = loan;
          _rateController.text = loan.monthlyInterestRate.toStringAsFixed(1);
          _notesController.text = loan.notes ?? '';
          _principalController.text = loan.principalOriginal.toStringAsFixed(2);
          _disbursementDate = loan.disbursementDate;
          _endDate = loan.endDate;
          _billingFrequency = loan.billingFrequency;
          _isLoaded = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'El préstamo no se encontró en la base de datos.';
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos: $e';
          _isLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _notesController.dispose();
    _principalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Volver',
                  onPressed: () => context.pop(),
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Préstamo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Préstamo'),
        // REMOVED Top Save Button as requested
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Loan info (read-only)
            _buildLoanInfoCard(),
            const SizedBox(height: 24),

            // Editable fields
            Text('Campos Editables', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            _buildEditableFieldsCard(),
            const SizedBox(height: 32),

            // Save button (Bottom only)
            AppButton(
              label: 'Guardar y Recalcular',
              icon: Icons.save,
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              isLoading: _isLoading,
              onPressed: _saveLoan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanInfoCard() {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_NI',
      symbol: 'C\$ ',
      decimalDigits: 2,
    );

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado del Préstamo', style: AppTypography.titleMedium),
            const Divider(height: 24),
            _buildInfoRow(
              'Saldo Actual',
              currencyFormat.format(_loan!.principalBalance),
            ),
            _buildInfoRow('Estado', _getStatusLabel(_loan!.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableFieldsCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Principal
            AppMoneyField(
              label: 'Capital Original',
              controller: _principalController,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Disbursement Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _disbursementDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _disbursementDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Desembolso',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _disbursementDate != null
                      ? DateFormat('dd/MM/yyyy').format(_disbursementDate!)
                      : 'Seleccionar',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interest rate
            Text(
              'Tasa de Interés Mensual (%)',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                helperText: 'Recalculará intereses',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                final rate = double.tryParse(v);
                if (rate == null || rate <= 0) return 'Tasa inválida';
                if (rate > 100) return 'Máximo 100%';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Billing Frequency
            _buildFrequencySelector(),
            const SizedBox(height: 24),

            // End Date
            _buildEndDatePicker(),
            const SizedBox(height: 24),

            // Notes
            Text('Notas', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Notas adicionales sobre el préstamo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_disbursementDate == null) return;

    setState(() => _isLoading = true);

    try {
      final newPrincipal =
          double.tryParse(_principalController.text.replaceAll(',', '')) ??
          _loan!.principalOriginal;
      final newRate = double.parse(_rateController.text);
      final notes = _notesController.text.trim();

      // Check if critical fields changed
      final bool needsRecalculation =
          newPrincipal != _loan!.principalOriginal ||
          newRate != _loan!.monthlyInterestRate ||
          _disbursementDate != _loan!.disbursementDate ||
          _billingFrequency != _loan!.billingFrequency;

      double newBalance = _loan!.principalBalance;
      if (newPrincipal != _loan!.principalOriginal) {
        double paid = _loan!.principalOriginal - _loan!.principalBalance;
        newBalance = newPrincipal - paid;
        if (newBalance < 0) newBalance = 0;
      }

      final updatedLoan = _loan!.copyWith(
        principalOriginal: newPrincipal,
        principalBalance: newBalance,
        monthlyInterestRate: newRate,
        billingFrequency: _billingFrequency,
        disbursementDate: _disbursementDate,
        endDate: _endDate,
        notes: notes.isEmpty ? null : notes,
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(loansProvider.notifier)
          .updateLoan(updatedLoan);

      if (success) {
        if (needsRecalculation) {
          final service = BillingCycleService(
            cycleRepository: ref.read(billingCycleRepositoryProvider),
            customerRepository: ref.read(customerRepositoryProvider),
            loanRepository: ref.read(loanRepositoryProvider),
          );

          await service.regenerateFutureCycles(updatedLoan);

          ref.read(dashboardProvider.notifier).refresh();
          ref.invalidate(loanByIdProvider(widget.loanId));
          ref.invalidate(loansByCustomerProvider(updatedLoan.customerId));

          // Force refresh of cycles and calculations
          ref.invalidate(billingCyclesByLoanProvider(widget.loanId));
          ref.invalidate(pendingBillingCyclesProvider(widget.loanId));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préstamo actualizado y recalculado'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getStatusLabel(String status) {
    return switch (status) {
      'ACTIVE' => 'Activo',
      'IN_MORA' => 'En Mora',
      'CLOSED' => 'Cerrado',
      'CANCELLED' => 'Cancelado',
      _ => status,
    };
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frecuencia de Cobro', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FrequencyOption(
                label: 'Quincenal',
                subtitle: '15 días',
                icon: Icons.calendar_view_week,
                isSelected: _billingFrequency == 'BIWEEKLY',
                onTap: () => setState(() => _billingFrequency = 'BIWEEKLY'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FrequencyOption(
                label: 'Mensual',
                subtitle: '30 días',
                icon: Icons.calendar_month,
                isSelected: _billingFrequency == 'MONTHLY',
                onTap: () => setState(() => _billingFrequency = 'MONTHLY'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha Fin (Opcional)', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Informativa - no afecta los ciclos de cobro',
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _endDate ??
                  (_disbursementDate ?? DateTime.now()).add(
                    const Duration(days: 365),
                  ),
              firstDate: _disbursementDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (date != null) setState(() => _endDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Sin fecha fin',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _endDate = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.info : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: isSelected ? primaryColor : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
