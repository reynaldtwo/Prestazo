import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/customer.dart';
import '../../../data/providers/providers.dart';
import '../../../core/constants/app_status.dart';
import '../../../core/localization/locale_provider.dart';

/// Customers list screen with Riverpod integration
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // all, active, inactive, biweekly, monthly

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).navCustomers),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchField(
              controller: _searchController,
              hint: S.of(context).searchHint,
              onChanged: (value) {
                ref.read(customersProvider.notifier).setSearchQuery(value);
              },
              onClear: () {
                ref.read(customersProvider.notifier).setSearchQuery('');
              },
            ),
          ),

          // Customer count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_getFilteredCustomers(customersState).length} ${S.of(context).customers}',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_filterType != 'all')
                  TextButton.icon(
                    onPressed: () => setState(() => _filterType = 'all'),
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(S.of(context).clearFilter),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: AppTypography.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Customers list
          Expanded(child: _buildCustomersList(customersState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customer/new'),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  List<Customer> _getFilteredCustomers(CustomersState state) {
    var customers = state.filteredCustomers;

    switch (_filterType) {
      case 'active':
        customers = customers.where((c) => c.status == 'ACTIVE').toList();
        break;
      case 'inactive':
        customers = customers.where((c) => c.status == 'INACTIVE').toList();
        break;
      case 'biweekly':
        customers = customers
            .where((c) => c.billingFrequency == 'BIWEEKLY')
            .toList();
        break;
      case 'monthly':
        customers = customers
            .where((c) => c.billingFrequency == 'MONTHLY')
            .toList();
        break;
    }

    return customers;
  }

  Widget _buildCustomersList(CustomersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return AppError(
        title: state.error!,
        onRetry: () => ref.read(customersProvider.notifier).loadCustomers(),
      );
    }

    final customers = _getFilteredCustomers(state);

    if (customers.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline,
        title: state.searchQuery.isEmpty
            ? S.of(context).noCustomers
            : S.of(context).noResults,
        message: state.searchQuery.isEmpty
            ? S.of(context).addFirstCustomer
            : S.of(context).tryAnotherTerm,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customersProvider.notifier).loadCustomers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CustomerListItem(
              customer: customer,
              onTap: () => context.push('/customer/${customer.customerId}'),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).filterCustomers,
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _buildFilterOption(S.of(context).all, 'all', setModalState),
                  _buildFilterOption(
                    S.of(context).statusActive,
                    'active',
                    setModalState,
                  ),
                  _buildFilterOption(
                    S.of(context).statusInactive,
                    'inactive',
                    setModalState,
                  ),
                  _buildFilterOption(
                    S.of(context).biweekly,
                    'biweekly',
                    setModalState,
                  ),
                  _buildFilterOption(
                    S.of(context).monthly,
                    'monthly',
                    setModalState,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    String label,
    String value,
    StateSetter setModalState,
  ) {
    final isSelected = _filterType == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(label),
      onTap: () {
        setModalState(() {});
        setState(() => _filterType = value);
        Navigator.pop(context);
      },
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerListItem({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = customer.status == 'ACTIVE';
    final displayName = customer.alias ?? customer.fullName;
    final isQuincenal = customer.billingFrequency == 'BIWEEKLY';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                        ? AppColors.info.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1))
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: AppTypography.headlineSmall.copyWith(
                  color: isActive
                      ? (isDark ? AppColors.info : AppColors.primary)
                      : Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _FrequencyBadge(isQuincenal: isQuincenal),
                  ],
                ),
                if (customer.alias != null)
                  Text(customer.fullName, style: AppTypography.bodySmall),
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Edit Action
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () =>
                context.push('/customer/${customer.customerId}/edit'),
            tooltip: 'Editar cliente',
            color: Theme.of(context).colorScheme.primary,
          ),

          // Status indicator
          if (!isActive)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: StatusBadge(
                status: AppStatus.customerInactive,
                isCompact: true,
              ),
            ),

          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  final bool isQuincenal;

  const _FrequencyBadge({required this.isQuincenal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(isQuincenal ? '15d' : '30d', style: AppTypography.labelSmall),
    );
  }
}
