import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logic/loan_calculator.dart';

import '../../../data/models/payment_plan.dart';
import '../../../data/models/payment_frequency.dart';
import '../../../data/providers/payment_plan_provider.dart';
import '../../../data/providers/payment_frequency_provider.dart';
import '../../../data/providers/database_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/providers/customer_category_provider.dart';

/// Screen for managing Payment Plans (CRUD)
class PaymentPlansScreen extends ConsumerStatefulWidget {
  const PaymentPlansScreen({super.key});

  @override
  ConsumerState<PaymentPlansScreen> createState() => _PaymentPlansScreenState();
}

class _PaymentPlansScreenState extends ConsumerState<PaymentPlansScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh plans on load
    Future.microtask(() {
      ref.read(paymentPlansProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final plansAsync = ref.watch(paymentPlansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentPlans)),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPaymentPlans,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addPaymentPlanHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildPlanCard(plan, l10n, theme);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/settings/payment-plans/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlanCard(PaymentPlan plan, S l10n, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: plan.isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          child: Icon(Icons.assignment, color: theme.colorScheme.onPrimary),
        ),
        title: Text(
          plan.name,
          style: TextStyle(
            decoration: plan.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${plan.installmentsTotal} ${l10n.installments} · ${plan.monthlyInterestRate}% ${l10n.monthly}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, plan, l10n),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(plan.isActive ? Icons.visibility_off : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(plan.isActive ? l10n.deactivate : l10n.activate),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    l10n.delete,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    String action,
    PaymentPlan plan,
    S l10n,
  ) async {
    switch (action) {
      case 'edit':
        context.push('/settings/payment-plans/edit/${plan.planId}');
        break;
      case 'toggle':
        final success = await ref
            .read(paymentPlansProvider.notifier)
            .toggleActive(plan.planId);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cannotDeactivatePlanWithLoans),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        break;
      case 'delete':
        _confirmDelete(plan, l10n);
        break;
    }
  }

  Future<void> _confirmDelete(PaymentPlan plan, S l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.deletePlanConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(paymentPlansProvider.notifier)
          .delete(plan.planId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotDeletePlanWithLoans),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deletedSuccessfully)));
      }
    }
  }
}
