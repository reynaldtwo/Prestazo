import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';
import 'package:prestamos_app/data/providers/providers.dart';

/// Pantalla de Panel de Control (Dashboard) - Pantalla principal con KPIs reales de la base de datos.
class DashboardScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [DashboardScreen].
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
    } on Exception catch (_) {
      // Ignore error checking backup
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    // Listen for rate warnings
    ref.listen<DashboardStats>(dashboardProvider, (previous, next) {
      if ((previous?.isLoading ?? false) &&
          !next.isLoading &&
          next.showRateWarning) {
        // Show dialog only when transition from loading to done with warning
        Future.microtask(() {
          if (context.mounted) _showRateWarningDialog(context);
        });
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
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
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
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;
    final theme = Theme.of(context);

    var title = S.of(context).appName;
    if (settings != null &&
        settings.showCompanyName &&
        settings.companyName != null &&
        settings.companyName!.isNotEmpty) {
      title = '${S.of(context).appName} - ${settings.companyName}';
    }

    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      backgroundColor: theme.appBarTheme.backgroundColor,
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
                color: theme.appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getGreeting(context),
              style: AppTypography.bodySmall.copyWith(
                color: theme.appBarTheme.foregroundColor?.withValues(
                  alpha: 0.8,
                ),
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
      return isDark ? AppColors.infoDark : AppColors.primary;
    }
    if (percentage < 50) {
      return isDark ? AppColors.successDark : AppColors.success;
    }
    if (percentage < 75) {
      return isDark ? AppColors.warningDark : AppColors.warning;
    }
    if (percentage < 90) {
      return const Color(0xFFFF9800); // Orange
    }
    return isDark ? AppColors.errorDark : AppColors.danger;
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final capitalColor = _getCapitalUsageColor(
      context,
      stats.capitalUsagePercentage,
    );
    final reportSymbol = stats.displaySymbol;

    return SliverList(
      delegate: SliverChildListDelegate([
        // 1. Capital Colocado (Full Width)
        _buildCapitalCard(
          context,
          stats: stats,
          capitalColor: capitalColor,
          currencySymbol: reportSymbol,
          onTap: () => context.go('/customers'),
        ),
        const SizedBox(height: 12),

        // 2. Ganancias del Mes (Full Width)
        _buildFullWidthKpiCard(
          context,
          icon: Icons.trending_up,
          iconColor: isDark ? AppColors.successDark : AppColors.success,
          label: S.of(context).earningsMonthLabel,
          value: stats.earningsMonth,
          currencySymbol: reportSymbol,
          onTap: () => context.go('/reports?tab=0'),
        ),
        const SizedBox(height: 12),

        // 3. 2x2 Grid (Proyeccion, Vencidos, Activos, Clientes)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4, // Adjusted for typical mobile screen aspects
          children: [
            _buildKpiCard(
              context,
              icon: Icons.show_chart,
              iconColor: isDark ? AppColors.infoDark : AppColors.info,
              label: S.of(context).projectedMonthLabel,
              value: stats.projectedEarnings,
              currencySymbol: reportSymbol,
              onTap: () => context.go('/reports?tab=1'),
            ),
            _buildKpiCard(
              context,
              icon: Icons.warning_amber,
              iconColor: theme.colorScheme.error,
              label: S.of(context).overdueLoansLabel,
              valueText: '${stats.overdueCount}',
              isWarning: stats.overdueCount > 0,
              onTap: () => context.go('/cobrar'),
            ),
            _buildKpiCard(
              context,
              icon: Icons.receipt_long,
              iconColor: isDark ? AppColors.infoDark : AppColors.info,
              label: S.of(context).activeLoansLabel,
              valueText: '${stats.activeLoans}',
              onTap: () => context.go('/customers'),
            ),
            _buildKpiCard(
              context,
              icon: Icons.people,
              iconColor: isDark
                  ? AppColors.secondaryDarkTheme
                  : AppColors.accent,
              label: S.of(context).activeCustomersLabel,
              valueText: '${stats.activeCustomers}',
              onTap: () => context.go('/customers'),
            ),
          ],
        ),
      ]),
    );
  }

  /// Capital card with progress indicator - Full Width
  Widget _buildCapitalCard(
    BuildContext context, {
    required DashboardStats stats,
    required Color capitalColor,
    required String currencySymbol,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).capitalPlacedLabel,
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: capitalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: capitalColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MoneyDisplay(
            amount: stats.totalPrincipalBalance,
            color: capitalColor,
            currencySymbol: currencySymbol,
            size: MoneyDisplaySize.large,
          ),
          const SizedBox(height: 4),
          Text(
            '${S.of(context).ofAmount} $currencySymbol ${_formatNumber(stats.availableCapital)}',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final percentage = (stats.capitalUsagePercentage / 100).clamp(
                0.0,
                1.0,
              );
              final maxWidth = constraints.maxWidth;
              final progressWidth = maxWidth * percentage;
              final showTextInside = percentage > 0.15;

              return SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    // Base background bar
                    Container(
                      width: maxWidth,
                      decoration: BoxDecoration(
                        color: capitalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Progress bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      width: progressWidth,
                      decoration: BoxDecoration(
                        color: capitalColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Text positioning
                    if (showTextInside)
                      Positioned(
                        right: maxWidth - progressWidth + 6,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '${stats.capitalUsagePercentage.toStringAsFixed(0)}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        left: progressWidth + 6,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '${stats.capitalUsagePercentage.toStringAsFixed(0)}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Full width KPI card for Earnings
  Widget _buildFullWidthKpiCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required double value,
    required String currencySymbol,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                MoneyDisplay(
                  amount: value,
                  currencySymbol: currencySymbol,
                  size: MoneyDisplaySize.large,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid KPI card - Icon top left
  Widget _buildKpiCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    double? value,
    String? valueText,
    bool isWarning = false,
    String? currencySymbol,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (value != null)
                MoneyDisplay(amount: value, currencySymbol: currencySymbol)
              else if (valueText != null)
                Text(
                  valueText,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isWarning
                        ? theme.colorScheme.error
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(
    BuildContext context,
    DashboardStats stats,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
                    color: isDark ? AppColors.successDark : AppColors.success,
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

  String _formatNumber(double value) {
    // Basic format for the "of X" string
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildRecentSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                  iconColor: isDark
                      ? AppColors.secondaryDarkTheme
                      : AppColors.accent,
                  title: S.of(context).viewCustomers,
                  subtitle: S.of(context).allCustomersList,
                  onTap: () => context.go('/customers'),
                ),
                const Divider(height: 1),
                _buildQuickActionItem(
                  context,
                  icon: Icons.history,
                  iconColor: isDark ? AppColors.infoDark : AppColors.info,
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
