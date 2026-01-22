import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/constants/app_status.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';

import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/providers/providers.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

/// Pantalla de lista de clientes con integración de Riverpod.
class CustomersScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [CustomersScreen].
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
      case 'inactive':
        customers = customers.where((c) => c.status == 'INACTIVE').toList();
      case 'biweekly':
        customers = customers
            .where((c) => c.billingFrequency == 'BIWEEKLY')
            .toList();
      case 'monthly':
        customers = customers
            .where((c) => c.billingFrequency == 'MONTHLY')
            .toList();
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
    showModalBottomSheet<void>(
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
            ? Theme.of(context).colorScheme.primary
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

class _CustomerListItem extends ConsumerWidget {
  const _CustomerListItem({required this.customer, required this.onTap});
  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = customer.status == 'ACTIVE';
    final displayName = customer.alias ?? customer.fullName;
    final isQuincenal = customer.billingFrequency == 'BIWEEKLY';

    // Get customer's most recent active loan currency
    final loansAsync = ref.watch(loansByCustomerProvider(customer.customerId));

    // Determine avatar text: currency symbol or first initial
    var avatarText = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    loansAsync.whenData((loans) {
      // Filter active loans and sort by disbursement date (most recent first)
      final activeLoans = loans
          .where(
            (loan) =>
                loan.status == 'ACTIVE' ||
                loan.status == 'OVERDUE' ||
                loan.status == 'IN_MORA',
          )
          .toList();

      if (activeLoans.isNotEmpty) {
        // Sort by disbursement date descending (most recent first)
        activeLoans.sort(
          (a, b) => b.disbursementDate.compareTo(a.disbursementDate),
        );
        final mostRecentLoan = activeLoans.first;

        // Get currency symbol dynamically
        final currency = FiatCurrency.maybeFromCode(
          mostRecentLoan.currencyCode,
        );
        avatarText = currency?.symbol ?? mostRecentLoan.currencyCode;
      }
    });

    // Get category color and calculate contrast
    Color? categoryColor;
    Color? contrastTextColor;
    if (customer.categoryId != null) {
      ref.watch(customerCategoriesProvider).whenData((categories) {
        final category = categories
            .where((c) => c.categoryId == customer.categoryId)
            .firstOrNull;
        if (category?.colorHex != null) {
          try {
            final hex = category!.colorHex!.replaceFirst('#', '');
            categoryColor = Color(int.parse('FF$hex', radix: 16));
            // Calculate luminance to determine text color
            // Dark colors (low luminance) need light text
            // Light colors (high luminance) need dark text
            final luminance = categoryColor!.computeLuminance();
            contrastTextColor = luminance < 0.5
                ? const Color(
                    0xFFF5F5F5,
                  ) // Light smoke white for dark backgrounds
                : const Color(0xFF212121); // Dark gray for light backgrounds
          } on Object catch (_) {}
        }
      });
    }

    // Text styles with contrasting color if category is set
    final nameStyle = contrastTextColor != null
        ? AppTypography.titleMedium.copyWith(color: contrastTextColor)
        : AppTypography.titleMedium;

    final subtitleStyle = contrastTextColor != null
        ? AppTypography.bodySmall.copyWith(
            color: contrastTextColor!.withValues(alpha: 0.85),
          )
        : AppTypography.bodySmall;

    final iconColor =
        contrastTextColor ?? Theme.of(context).colorScheme.outline;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: categoryColor != null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    categoryColor!.withValues(alpha: 0.85),
                    categoryColor!.withValues(alpha: 0.4),
                  ],
                ),
              )
            : null,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: contrastTextColor != null
                    ? contrastTextColor!.withValues(alpha: 0.15)
                    : isActive
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15)
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  avatarText,
                  style: AppTypography.headlineSmall.copyWith(
                    color:
                        contrastTextColor ??
                        (isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline),
                    fontWeight: FontWeight.bold,
                    fontSize: avatarText.length > 2
                        ? 14
                        : 18, // Smaller font for longer symbols
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
                          style: nameStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _FrequencyBadge(
                        isQuincenal: isQuincenal,
                        textColor: contrastTextColor,
                      ),
                    ],
                  ),
                  if (customer.alias != null)
                    Text(customer.fullName, style: subtitleStyle),
                  if (customer.phone != null)
                    Text(
                      customer.phone!,
                      style: contrastTextColor != null
                          ? subtitleStyle
                          : AppTypography.bodySmall.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                    ),
                ],
              ),
            ),

            // Edit Action
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: iconColor),
              onPressed: () =>
                  context.push('/customer/${customer.customerId}/edit'),
              tooltip: S.of(context).editCustomer,
            ),

            // Status indicator
            if (!isActive)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: StatusBadge(
                  status: AppStatus.customerInactive,
                  isCompact: true,
                ),
              ),

            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.isQuincenal, this.textColor});
  final bool isQuincenal;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: textColor != null
            ? textColor!.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isQuincenal ? '15d' : '30d',
        style: textColor != null
            ? AppTypography.labelSmall.copyWith(color: textColor)
            : AppTypography.labelSmall,
      ),
    );
  }
}
