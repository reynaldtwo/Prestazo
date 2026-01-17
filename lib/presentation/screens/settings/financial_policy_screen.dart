import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/business_financial_policy.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';

/// Screen for configuring Business Financial Policy (Day Count Convention)
/// Location: Ajustes → Políticas del Negocio → Convención Financiera
/// Pantalla para configurar la política financiera del negocio (convención de conteo de días).
class FinancialPolicyScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [FinancialPolicyScreen].
  const FinancialPolicyScreen({super.key});

  @override
  ConsumerState<FinancialPolicyScreen> createState() =>
      _FinancialPolicyScreenState();
}

class _FinancialPolicyScreenState extends ConsumerState<FinancialPolicyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _dayCountConvention = '30/360';
  int _daysPerMonth = 30;
  int _daysPerYear = 360;
  String _prorationRule = 'CYCLE_PROPORTION';
  int _roundingDecimals = 2;
  String _roundingMode = 'HALF_UP';

  bool _isLoading = true;
  bool _isSaving = false;

  // Preview calculation values
  final double _previewPrincipal = 10000;
  final double _previewRate = 10; // 10% monthly
  final int _previewDays = 15;

  @override
  void initState() {
    super.initState();
    _loadCurrentPolicy();
  }

  Future<void> _loadCurrentPolicy() async {
    try {
      final repo = ref.read(businessPolicyRepositoryProvider);
      final policy = await repo.getActivePolicy();
      setState(() {
        _dayCountConvention = policy.dayCountConvention;
        _daysPerMonth = policy.daysPerMonth;
        _daysPerYear = policy.daysPerYear;
        _prorationRule = policy.prorationRule;
        _roundingDecimals = policy.roundingDecimals;
        _roundingMode = policy.roundingMode;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando política: $e')));
      }
    }
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(businessPolicyRepositoryProvider);
      final now = DateTime.now();

      final newPolicy = BusinessFinancialPolicy(
        id: 'policy_${now.millisecondsSinceEpoch}',
        dayCountConvention: _dayCountConvention,
        daysPerMonth: _daysPerMonth,
        daysPerYear: _daysPerYear,
        prorationRule: _prorationRule,
        roundingDecimals: _roundingDecimals,
        roundingMode: _roundingMode,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveAsActivePolicy(newPolicy);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Política financiera guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando política: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Calculate preview interest based on current settings
  double get _previewInterest {
    final dailyRate = _previewRate / _daysPerMonth;
    return _previewPrincipal * (dailyRate / 100) * _previewDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convención Financiera'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _savePolicy,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Esta configuración define cómo se calculan los intereses. '
                                'Los préstamos existentes mantienen su política original.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Day Count Convention
                    Text(
                      'Convención de Conteo de Días',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _dayCountConvention,
                      decoration: const InputDecoration(
                        hintText: 'Seleccione convención',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '30/360',
                          child: Text('30/360 (Estándar Comercial)'),
                        ),
                        DropdownMenuItem(
                          value: 'ACTUAL/360',
                          child: Text('Actual/360'),
                        ),
                        DropdownMenuItem(
                          value: 'ACTUAL/365',
                          child: Text('Actual/365'),
                        ),
                        DropdownMenuItem(
                          value: '30/365',
                          child: Text('30/365'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _dayCountConvention = value;
                            // Auto-fill based on convention
                            if (value == '30/360') {
                              _daysPerMonth = 30;
                              _daysPerYear = 360;
                            } else if (value == 'ACTUAL/360') {
                              _daysPerYear = 360;
                            } else if (value == 'ACTUAL/365') {
                              _daysPerYear = 365;
                            } else if (value == '30/365') {
                              _daysPerMonth = 30;
                              _daysPerYear = 365;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Days Per Month
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Días por Mes'),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _daysPerMonth.toString(),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '30',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final v = int.tryParse(value ?? '');
                                  if (v == null || v <= 0 || v > 31) {
                                    return 'Entre 1 y 31';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final v = int.tryParse(value);
                                  if (v != null) {
                                    setState(() => _daysPerMonth = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Días por Año'),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _daysPerYear.toString(),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '360',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final v = int.tryParse(value ?? '');
                                  if (v == null || v < 360 || v > 366) {
                                    return 'Entre 360 y 366';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final v = int.tryParse(value);
                                  if (v != null) {
                                    setState(() => _daysPerYear = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Proration Rule
                    Text(
                      'Regla de Prorrateo',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _prorationRule,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'EXACT_DAYS',
                          child: Text('Días Exactos'),
                        ),
                        DropdownMenuItem(
                          value: 'CYCLE_PROPORTION',
                          child: Text('Proporción del Ciclo'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _prorationRule = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Rounding Settings
                    Text(
                      'Política de Redondeo',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Decimales'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: _roundingDecimals,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 2, child: Text('2')),
                                  DropdownMenuItem(value: 3, child: Text('3')),
                                  DropdownMenuItem(value: 4, child: Text('4')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _roundingDecimals = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Modo'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _roundingMode,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'HALF_UP',
                                    child: Text('Medio Arriba'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'HALF_EVEN',
                                    child: Text('Bancario'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'DOWN',
                                    child: Text('Truncar'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UP',
                                    child: Text('Hacia Arriba'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _roundingMode = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Live Preview
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calculate,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vista Previa del Cálculo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              'Capital: C\$ ${_previewPrincipal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              'Tasa Mensual: $_previewRate%',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              'Días: $_previewDays',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tasa Diaria: ${(_previewRate / _daysPerMonth).toStringAsFixed(4)}%',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Interés Calculado: C\$ ${_previewInterest.toStringAsFixed(_roundingDecimals)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SAVE BUTTON - Prominent at bottom
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePolicy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Configuración',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
