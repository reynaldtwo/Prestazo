import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/loan.dart';
import '../../../data/providers/providers.dart';
import '../../../data/providers/database_providers.dart';
import '../../../core/localization/locale_provider.dart';

/// Loan form screen for creating new loans with Riverpod
class LoanFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  const LoanFormScreen({super.key, required this.customerId});

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController(text: '20');
  final _notesController = TextEditingController();
  DateTime _disbursementDate = DateTime.now();
  DateTime? _endDate; // Optional informational end date
  String _billingFrequency = 'MONTHLY'; // 'MONTHLY' or 'BIWEEKLY'
  bool _isLoading = false;
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerById(widget.customerId);
      if (customer != null && mounted) {
        setState(() => _customer = customer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).errorLoadCustomer}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).newLoan)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            AppMoneyField(
              label: S.of(context).loanAmountLabel,
              controller: _principalController,
              validator: (v) {
                if (v == null || v.isEmpty) return S.of(context).fieldRequired;
                final amount = double.tryParse(v.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return S.of(context).invalidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: S.of(context).monthlyRateLabel,
              controller: _rateController,
              prefixIcon: Icons.percent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return S.of(context).fieldRequired;
                final rate = double.tryParse(v);
                if (rate == null || rate <= 0 || rate > 100) {
                  return S.of(context).invalidRate;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _buildRateInfo(),
            const SizedBox(height: 24),
            _buildFrequencySelector(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildEndDatePicker(),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            AppTextField(
              label: S.of(context).notes,
              hint: S.of(context).loanObservations,
              controller: _notesController,
              prefixIcon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 32),
            AppButton(
              label: S.of(context).createLoanAction,
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

  Widget _buildCustomerInfo() {
    if (_customer == null) {
      return const AppCard(child: Center(child: CircularProgressIndicator()));
    }

    final displayName = _customer!.alias ?? _customer!.fullName;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.info : AppColors.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? AppColors.info : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTypography.titleMedium),
                if (_customer!.alias != null)
                  Text(_customer!.fullName, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateInfo() {
    final principal =
        double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final monthlyInterest = principal * (rate / 100);

    if (principal <= 0 || rate <= 0) return const SizedBox.shrink();

    final isQuincenal = _billingFrequency == 'BIWEEKLY';
    final periodInterest = isQuincenal ? monthlyInterest / 2 : monthlyInterest;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Interés ${isQuincenal ? "quincenal" : "mensual"}: ',
            style: AppTypography.bodySmall,
          ),
          Text(
            'C\$ ${periodInterest.toStringAsFixed(2)}',
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.info
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frecuencia de Cobro *', style: AppTypography.labelMedium),
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
                  _endDate ?? _disbursementDate.add(const Duration(days: 365)),
              firstDate: _disbursementDate,
              lastDate: _disbursementDate.add(const Duration(days: 365 * 10)),
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
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha de Desembolso', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _disbursementDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (date != null) setState(() => _disbursementDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_disbursementDate.day}/${_disbursementDate.month}/${_disbursementDate.year}',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
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

  Widget _buildSummaryCard() {
    final principal =
        double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (principal <= 0) return const SizedBox.shrink();

    return AppCard(
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del Préstamo', style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Capital',
            value: 'C\$ ${principal.toStringAsFixed(2)}',
          ),
          _SummaryRow(label: 'Tasa mensual', value: '$rate%'),
          _SummaryRow(
            label: 'Interés mensual',
            value: 'C\$ ${(principal * rate / 100).toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando datos del cliente...'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final principal = double.parse(
      _principalController.text.replaceAll(',', ''),
    );

    // Validate capital if enabled
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final settings = await settingsRepo.getSettings();

      if (settings.validateCapital && settings.availableCapital > 0) {
        final loanRepo = ref.read(loanRepositoryProvider);
        final capitalColocado = await loanRepo.getTotalPrincipalBalance();
        final saldoDisponible = settings.availableCapital - capitalColocado;

        if (principal > saldoDisponible) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El monto C\$ ${principal.toStringAsFixed(0)} sobrepasa el saldo disponible de C\$ ${saldoDisponible.toStringAsFixed(0)}',
                ),
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // Validate disbursement date (Max 1 year old) to prevent crash
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      if (_disbursementDate.isBefore(oneYearAgo)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La fecha de desembolso no puede ser mayor a un año de antigüedad.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // Validate no existing active loans if setting is disabled
      if (!settings.allowMultipleLoans) {
        final loanRepo = ref.read(loanRepositoryProvider);
        final existingLoans = await loanRepo.getLoansByCustomerId(
          widget.customerId,
        );
        final activeLoans = existingLoans
            .where((l) => l.status == 'ACTIVE' || l.status == 'IN_MORA')
            .toList();

        if (activeLoans.isNotEmpty) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(child: Text('Préstamo Activo')),
                  ],
                ),
                content: const Text(
                  'Este cliente ya tiene un préstamo activo.\n\n'
                  'Para permitir múltiples préstamos por cliente, '
                  'habilite la opción en Configuración → Políticas del Negocio.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      // Continue if settings check fails
    }

    setState(() => _isLoading = true);

    try {
      final rate = double.parse(_rateController.text);
      final now = DateTime.now();

      final loan = Loan(
        loanId: const Uuid().v4(),
        customerId: widget.customerId,
        principalOriginal: principal,
        principalBalance: principal,
        monthlyInterestRate: rate,
        billingFrequency: _billingFrequency,
        disbursementDate: _disbursementDate,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final success = await ref
          .read(loansProvider.notifier)
          .addSimpleLoan(loan);

      if (mounted) {
        if (success) {
          // Refresh dashboard stats
          ref.read(dashboardProvider.notifier).refresh();

          // Invalidate loans by customer so detail screen refreshes
          ref.invalidate(loansByCustomerProvider(widget.customerId));

          // Invalidate settings to update loan sequence number
          ref.invalidate(appSettingsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préstamo creado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          final error = ref.read(loansProvider).error;
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.titleSmall),
        ],
      ),
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
