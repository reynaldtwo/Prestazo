import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/constants/app_status.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/providers/cobrar_provider.dart';

/// Pantalla "A Cobrar" - Pantalla operacional principal para préstamos próximos a cobrar.
class CobrarScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [CobrarScreen].
  const CobrarScreen({super.key});

  @override
  ConsumerState<CobrarScreen> createState() => _CobrarScreenState();
}

class _CobrarScreenState extends ConsumerState<CobrarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // logic remains same mapping index to filter
    final filters = [
      CobrarFilter.biweekly,
      CobrarFilter.monthly,
      CobrarFilter.overdue,
    ];
    if (_tabController.index < filters.length) {
      ref
          .read(cobrarProvider.notifier)
          .setFilter(filters[_tabController.index]);
    }
    _searchController.clear();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cobrarState = ref.watch(cobrarProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Localized tabs
    final tabLabels = [
      S.of(context).tabBiweekly,
      S.of(context).tabMonthly,
      S.of(context).tabOverdue,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).collectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cobrarProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: S.of(context).searchCollectionHint,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: cobrarState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(cobrarProvider.notifier).setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                ref.read(cobrarProvider.notifier).setSearch(value);
              },
            ),
          ),
          // Content
          Expanded(child: _buildBody(cobrarState)),
        ],
      ),
    );
  }

  Widget _buildBody(CobrarState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return AppError(
        title: S.of(context).error,
        message: state.error,
        onRetry: () => ref.read(cobrarProvider.notifier).refresh(),
      );
    }

    if (state.filteredCustomers.isEmpty) {
      if (state.searchQuery.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).noResults,
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${S.of(context).noResultsFor} "${state.searchQuery}"',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        );
      }
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(cobrarProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = state.filteredCustomers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CustomerDueCard(
              customer: customer,
              onTap: () => context.push('/customer/${customer.customerId}'),
              onPayment: () => context.push(
                '/payment/new',
                extra: {'customerId': customer.customerId},
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final filter = ref.watch(cobrarProvider).activeFilter;
    String title;
    String? message;

    switch (filter) {
      case CobrarFilter.biweekly:
        title = S.of(context).noCollectionBiweeklyTitle;
        message = S.of(context).noCollectionBiweeklyMsg;
      case CobrarFilter.monthly:
        title = S.of(context).noCollectionMonthlyTitle;
        message = S.of(context).noCollectionMonthlyMsg;
      case CobrarFilter.overdue:
        title = S.of(context).noCollectionOverdueTitle;
        message = S.of(context).noCollectionOverdueMsg;
      case CobrarFilter.next7Days:
        title = S.of(context).noData;
        message = null;
    }

    return AppEmptyState(
      icon: filter == CobrarFilter.overdue
          ? Icons.check_circle
          : Icons.receipt_long,
      title: title,
      message: message,
      actionLabel: S.of(context).newCustomer,
      onAction: () => context.push('/customer/new'),
    );
  }
}

class _CustomerDueCard extends StatelessWidget {
  const _CustomerDueCard({
    required this.customer,
    required this.onTap,
    required this.onPayment,
  });
  final CustomerDueInfo customer;
  final VoidCallback onTap;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: customer.isInMora
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.info
                                : AppColors.primary)
                            .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    customer.displayName[0].toUpperCase(),
                    style: AppTypography.titleLarge.copyWith(
                      color: customer.isInMora
                          ? AppColors.danger
                          : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.info
                                : AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.displayName,
                            style: AppTypography.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.isInMora)
                          const StatusBadge(
                            status: AppStatus.loanOverdue,
                            isCompact: true,
                          ),
                      ],
                    ),
                    if (customer.alias != null)
                      Text(
                        customer.customerName,
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info wrap
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              MoneyLabel(
                label: S.of(context).interestExpected,
                amount: customer.totalInterestExpected,
              ),
              MoneyLabel(
                label: S.of(context).pending,
                amount: customer.totalInterestPending,
                amountColor: customer.totalInterestPending > 0
                    ? AppColors.danger
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              MoneyLabel(
                label: S.of(context).capital,
                amount: customer.totalCapitalBalance,
              ),
              if (customer.lastPaymentDate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).lastPayment,
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(context, customer.lastPaymentDate!),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
            ],
          ),

          if (customer.daysOverdue > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${customer.daysOverdue} ${S.of(context).daysOverdue}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],

          // Loans count
          if (customer.loans.length > 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.info
                            : AppColors.primary)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${customer.loans.length} ${S.of(context).activeLoansCount}',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.info
                      : AppColors.primary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: S.of(context).registerPayment,
              icon: Icons.payment,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: onPayment,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return S.of(context).dateToday;
    if (diff == 1) return S.of(context).dateYesterday;
    if (diff < 7) {
      return S.of(context).dateDaysAgo(diff.toString());
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
