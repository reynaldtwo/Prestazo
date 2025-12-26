import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/Widgets/widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../core/localization/locale_provider.dart';

/// Dashboard screen - Main home with real KPIs from database
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Header (SliverAppBar)
            _buildHeader(context, ref),

            // Quick Actions
            SliverToBoxAdapter(child: _buildQuickActions(context)),

            // KPI Cards
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _buildKpiGrid(context, dashboardState, ref),
            ),

            // Today's Summary
            SliverToBoxAdapter(
              child: _buildTodaySummary(context, dashboardState),
            ),

            // Recent Activity Section
            SliverToBoxAdapter(child: _buildRecentSection(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;

    String title = S.of(context).appName;
    if (settings != null &&
        settings.showCompanyName &&
        settings.companyName != null &&
        settings.companyName!.isNotEmpty) {
      title = '${S.of(context).appName} - ${settings.companyName}';
    }

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 100.0,
      backgroundColor: AppColors.primary,
      // No shape allows it to be flat/rectangular like other screens
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getGreeting(context),
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final s = S.of(context);
    if (hour < 12) return s.goodMorning;
    if (hour < 18) return s.goodAfternoon;
    return s.goodEvening;
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        24,
        16,
        0,
      ), // Added top padding (24) to separate from header
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: S.of(context).registerPayment,
              icon: Icons.add_circle_outline,
              // Changed variant to secondary to distinguish from primary header
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push('/payment/new'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: S.of(context).newCustomerLabel,
              icon: Icons.person_add_outlined,
              variant: AppButtonVariant.outline,
              onPressed: () => context.push('/customer/new'),
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on capital usage percentage
  Color _getCapitalUsageColor(BuildContext context, double percentage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (percentage <= 0) {
      // In Dark Mode, use a brighter blue (info or primaryLight) instead of deep primary
      return isDark ? AppColors.info : AppColors.primary;
    }
    if (percentage < 50) return AppColors.success;
    if (percentage < 75) return AppColors.warning;
    if (percentage < 90) return const Color(0xFFFF9800); // Orange
    return AppColors.danger;
  }

  Widget _buildKpiGrid(
    BuildContext context,
    DashboardStats stats,
    WidgetRef ref,
  ) {
    if (stats.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (stats.error != null) {
      return SliverToBoxAdapter(
        child: AppError(
          title: stats.error!,
          onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
        ),
      );
    }

    final capitalColor = _getCapitalUsageColor(
      context,
      stats.capitalUsagePercentage,
    );

    final kpiCards = [
      // Capital Colocado with usage indicator
      _buildCapitalCard(
        context,
        stats: stats,
        capitalColor: capitalColor,
        onTap: () => context.go('/customers'),
      ),
      _buildKpiCard(
        context,
        icon: Icons.people,
        iconColor: AppColors.accent,
        label: S.of(context).activeCustomersLabel,
        valueText: '${stats.activeCustomers}',
        onTap: () => context.go('/customers'),
      ),
      _buildKpiCard(
        context,
        icon: Icons.receipt_long,
        iconColor: AppColors.info,
        label: S.of(context).activeLoansLabel,
        valueText: '${stats.activeLoans}',
        onTap: () => context.go('/customers'),
      ),
      _buildKpiCard(
        context,
        icon: Icons.warning_amber,
        iconColor: AppColors.danger,
        label: S.of(context).overdueLoansLabel,
        valueText: '${stats.overdueCount}',
        isWarning: stats.overdueCount > 0,
        onTap: () => context.go('/cobrar'),
      ),
      _buildKpiCard(
        context,
        icon: Icons.trending_up,
        iconColor: AppColors.success,
        label: S.of(context).earningsMonthLabel,
        value: stats.earningsMonth,
        onTap: () => context.go('/reports?tab=0'),
      ),
      _buildKpiCard(
        context,
        icon: Icons.show_chart,
        iconColor: AppColors.info,
        label: S.of(context).projectedMonthLabel,
        value: stats.projectedEarnings,
        onTap: () => context.go('/reports?tab=1'),
      ),
    ];

    return SliverToBoxAdapter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 200,
        ),
        itemCount: kpiCards.length,
        itemBuilder: (context, index) => kpiCards[index],
      ),
    );
  }

  /// Capital card with progress indicator
  Widget _buildCapitalCard(
    BuildContext context, {
    required DashboardStats stats,
    required Color capitalColor,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: capitalColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: capitalColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          MoneyDisplay(
            amount: stats.totalPrincipalBalance,
            size: MoneyDisplaySize.medium,
            color: capitalColor,
          ),
          const SizedBox(height: 2),
          Text(
            S.of(context).capitalPlacedLabel,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (stats.availableCapital > 0) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (stats.capitalUsagePercentage / 100).clamp(0.0, 1.0),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(capitalColor),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${stats.capitalUsagePercentage.toStringAsFixed(0)}% ${S.of(context).ofLabel} C\$${stats.availableCapital.toStringAsFixed(0)}',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, DashboardStats stats) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  S.of(context).today,
                  style: AppTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).capitalRecovered,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      MoneyDisplay(
                        amount: stats.capitalRecoveredToday,
                        size: MoneyDisplaySize.medium,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).payments,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${stats.paymentsTodayCount}',
                            style: AppTypography.headlineSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (stats.collectedToday > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).collectedToday,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  MoneyDisplay(
                    amount: stats.collectedToday,
                    size: MoneyDisplaySize.small,
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    String? subtitle,
    double? value,
    String? valueText,
    bool isWarning = false,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          if (value != null)
            MoneyDisplay(amount: value, size: MoneyDisplaySize.medium)
          else if (valueText != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valueText,
                style: AppTypography.moneyLarge.copyWith(
                  color: isWarning ? AppColors.danger : colorScheme.onSurface,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).quickActions,
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _buildQuickActionItem(
                  context,
                  icon: Icons.route,
                  iconColor: colorScheme.primary,
                  title: S.of(context).collectionRoute,
                  subtitle: S.of(context).viewCollectionCustomers,
                  onTap: () => context.go('/cobrar'),
                ),
                const Divider(height: 1),
                _buildQuickActionItem(
                  context,
                  icon: Icons.people,
                  iconColor: AppColors.accent,
                  title: S.of(context).viewCustomers,
                  subtitle: S.of(context).allCustomersList,
                  onTap: () => context.go('/customers'),
                ),
                const Divider(height: 1),
                _buildQuickActionItem(
                  context,
                  icon: Icons.history,
                  iconColor: AppColors.info,
                  title: S.of(context).paymentHistory,
                  subtitle: S.of(context).viewAllPayments,
                  onTap: () => context.go('/payments'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
