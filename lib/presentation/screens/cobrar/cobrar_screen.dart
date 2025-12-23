import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/providers/cobrar_provider.dart';
import '../../../core/constants/app_status.dart';

/// "A Cobrar" screen - Main operational screen for due payments
class CobrarScreen extends ConsumerStatefulWidget {
  const CobrarScreen({super.key});

  @override
  ConsumerState<CobrarScreen> createState() => _CobrarScreenState();
}

class _CobrarScreenState extends ConsumerState<CobrarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<_FilterTab> _tabs = [
    _FilterTab('Quincena', CobrarFilter.biweekly),
    _FilterTab('Mes', CobrarFilter.monthly),
    _FilterTab('Atrasados', CobrarFilter.overdue),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final filter = _tabs[_tabController.index].filter;
    ref.read(cobrarProvider.notifier).setFilter(filter);
    _searchController.clear();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cobrarState = ref.watch(cobrarProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('A Cobrar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cobrarProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            color: colorScheme.surface,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant, width: 1),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTypography.labelMedium,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                tabs: _tabs
                    .map((tab) => Tab(height: 36, text: tab.label))
                    .toList(),
              ),
            ),
          ),
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
                hintText: 'Buscar por nombre o monto...',
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
        title: 'Error',
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
                'No se encontraron resultados',
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'para "${state.searchQuery}"',
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
        title = 'No hay cobros pendientes esta quincena';
        message =
            'Los clientes quincenales aparecerán aquí cuando tengan pagos pendientes';
        break;
      case CobrarFilter.monthly:
        title = 'No hay cobros pendientes este mes';
        message = 'Los clientes con pagos pendientes aparecerán aquí';
        break;
      case CobrarFilter.overdue:
        title = '¡Sin clientes atrasados!';
        message = 'Todos tus clientes están al día';
        break;
      default:
        title = 'Sin datos';
        message = null;
    }

    return AppEmptyState(
      icon: filter == CobrarFilter.overdue
          ? Icons.check_circle
          : Icons.receipt_long,
      title: title,
      message: message,
      actionLabel: 'Crear Cliente',
      onAction: () => context.push('/customer/new'),
    );
  }
}

class _FilterTab {
  final String label;
  final CobrarFilter filter;

  _FilterTab(this.label, this.filter);
}

class _CustomerDueCard extends StatelessWidget {
  final CustomerDueInfo customer;
  final VoidCallback onTap;
  final VoidCallback onPayment;

  const _CustomerDueCard({
    required this.customer,
    required this.onTap,
    required this.onPayment,
  });

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
                          StatusBadge(
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

          // Info row
          Row(
            children: [
              Expanded(
                child: MoneyLabel(
                  label: 'Interés esperado',
                  amount: customer.totalInterestExpected,
                ),
              ),
              Expanded(
                child: MoneyLabel(
                  label: 'Pendiente',
                  amount: customer.totalInterestPending,
                  amountColor: customer.totalInterestPending > 0
                      ? AppColors.danger
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: MoneyLabel(
                  label: 'Capital',
                  amount: customer.totalCapitalBalance,
                ),
              ),
              if (customer.lastPaymentDate != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Último pago', style: AppTypography.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(customer.lastPaymentDate!),
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
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
                '${customer.daysOverdue} días de atraso',
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
                '${customer.loans.length} préstamos activos',
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
              label: 'Registrar Pago',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';

    return '${date.day}/${date.month}/${date.year}';
  }
}
