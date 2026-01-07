import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/Widgets/widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../core/localization/locale_provider.dart';

/// Dashboard screen - Main home with real KPIs from database
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Check for scheduled backups after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduledBackups();
    });
  }

  Future<void> _checkScheduledBackups() async {
    try {
      final settings = await ref.read(appSettingsProvider.future);
      final backupService = ref.read(backupServiceProvider);

      await backupService.checkScheduledBackup(
        frequency: settings.backupFrequency,
        retentionDays: settings.backupRetentionDays,
        retries: 3,
        customName: settings.backupCustomName,
      );
    } catch (e) {
      debugPrint('Error checking scheduled backups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    // Listen for rate warnings
    ref.listen<DashboardStats>(dashboardProvider, (previous, next) {
      if ((previous?.isLoading == true) &&
          !next.isLoading &&
          next.showRateWarning) {
        // Show dialog only when transition from loading to done with warning
        _showRateWarningDialog(context);
      }
    });

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
            // Today's Summary
            SliverToBoxAdapter(
              child: _buildTodaySummary(context, dashboardState, ref),
            ),

            // Recent Activity Section
            SliverToBoxAdapter(child: _buildRecentSection(context)),
          ],
        ),
      ),
    );
  }

  void _showRateWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.of(context).defineExchangeRateMessage,
                style: AppTypography.titleMedium,
              ),
            ),
          ],
        ),
        content: Text(
          'Detailed conversion error: Missing exchange rate for today. Values may be inaccurate.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings/exchange-rates');
            },
            child: Text(S.of(context).goToExchangeRates),
          ),
        ],
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
                color: Colors.white.withValues(alpha: 0.9),
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
      // Handle missing exchange rate error with localized message
      final errorMessage = stats.error == 'exchange_rate_required'
          ? S.of(context).defineExchangeRateMessage
          : stats.error!;
      return SliverToBoxAdapter(
        child: AppError(
          title: errorMessage,
          onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
        ),
      );
    }

    final capitalColor = _getCapitalUsageColor(
      context,
      stats.capitalUsagePercentage,
    );

    // Use displaySymbol from stats (provided by CurrencyContext)
    final reportSymbol = stats.displaySymbol;

    final kpiCards = [
      // Capital Colocado with usage indicator
      _buildCapitalCard(
        context,
        stats: stats,
        capitalColor: capitalColor,
        currencySymbol: reportSymbol,
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
        currencySymbol: reportSymbol,
        onTap: () => context.go('/reports?tab=0'),
      ),
      _buildKpiCard(
        context,
        icon: Icons.show_chart,
        iconColor: AppColors.info,
        label: S.of(context).projectedMonthLabel,
        value: stats.projectedEarnings,
        currencySymbol: reportSymbol,
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
    required String currencySymbol,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyDisplay(
              amount: stats.totalPrincipalBalance,
              size: MoneyDisplaySize.medium,
              color: capitalColor,
              currencySymbol:
                  currencySymbol, // CRITICAL: Use display currency symbol
            ),
          ),
          const SizedBox(height: 2),
          Text(
            S.of(context).capitalPlacedLabel,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
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
              '${stats.capitalUsagePercentage.toStringAsFixed(0)}% ${S.of(context).ofLabel} $currencySymbol${NumberFormat('#,##0.00').format(stats.availableCapital)}',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                // Removed explicit fontSize to improve readability
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaySummary(
    BuildContext context,
    DashboardStats stats,
    WidgetRef ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use displaySymbol from stats (provided by CurrencyContext)
    final reportSymbol = stats.displaySymbol;

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
                        currencySymbol: reportSymbol,
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
                    currencySymbol: reportSymbol,
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
    String? currencySymbol,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            MoneyDisplay(
              amount: value,
              size: MoneyDisplaySize.medium,
              currencySymbol: currencySymbol,
            )
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
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
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
