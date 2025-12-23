import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_providers.dart';

/// Dashboard statistics state
class DashboardStats {
  final int activeCustomers;
  final int activeLoans;
  final double totalPrincipalBalance;
  final double totalOriginalPrincipal;
  final double collectedToday;
  final double capitalRecoveredToday;
  final int overdueCount;
  final int paymentsTodayCount;
  final double availableCapital;
  final double earningsMonth;
  final double projectedEarnings;
  final bool isLoading;
  final String? error;

  const DashboardStats({
    this.activeCustomers = 0,
    this.activeLoans = 0,
    this.totalPrincipalBalance = 0,
    this.totalOriginalPrincipal = 0,
    this.collectedToday = 0,
    this.capitalRecoveredToday = 0,
    this.overdueCount = 0,
    this.paymentsTodayCount = 0,
    this.availableCapital = 0,
    this.earningsMonth = 0,
    this.projectedEarnings = 0,
    this.isLoading = false,
    this.error,
  });

  DashboardStats copyWith({
    int? activeCustomers,
    int? activeLoans,
    double? totalPrincipalBalance,
    double? totalOriginalPrincipal,
    double? collectedToday,
    double? capitalRecoveredToday,
    int? overdueCount,
    int? paymentsTodayCount,
    double? availableCapital,
    double? earningsMonth,
    double? projectedEarnings,
    bool? isLoading,
    String? error,
  }) {
    return DashboardStats(
      activeCustomers: activeCustomers ?? this.activeCustomers,
      activeLoans: activeLoans ?? this.activeLoans,
      totalPrincipalBalance:
          totalPrincipalBalance ?? this.totalPrincipalBalance,
      totalOriginalPrincipal:
          totalOriginalPrincipal ?? this.totalOriginalPrincipal,
      collectedToday: collectedToday ?? this.collectedToday,
      capitalRecoveredToday:
          capitalRecoveredToday ?? this.capitalRecoveredToday,
      overdueCount: overdueCount ?? this.overdueCount,
      paymentsTodayCount: paymentsTodayCount ?? this.paymentsTodayCount,
      availableCapital: availableCapital ?? this.availableCapital,
      earningsMonth: earningsMonth ?? this.earningsMonth,
      projectedEarnings: projectedEarnings ?? this.projectedEarnings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get percentage of capital recovered overall
  double get capitalRecoveryPercentage {
    if (totalOriginalPrincipal == 0) return 0;
    final recovered = totalOriginalPrincipal - totalPrincipalBalance;
    return (recovered / totalOriginalPrincipal) * 100;
  }

  /// Get capital recovered amount overall
  double get capitalRecovered {
    return totalOriginalPrincipal - totalPrincipalBalance;
  }

  /// Get percentage of available capital used
  double get capitalUsagePercentage {
    if (availableCapital <= 0) return 0;
    return (totalPrincipalBalance / availableCapital) * 100;
  }

  /// Get remaining capital to lend
  double get remainingCapital {
    if (availableCapital <= 0) return 0;
    return (availableCapital - totalPrincipalBalance).clamp(0, double.infinity);
  }
}

/// Notifier for dashboard statistics
class DashboardNotifier extends StateNotifier<DashboardStats> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardStats()) {
    loadStats();
  }

  /// Load all dashboard statistics
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customerRepo = _ref.read(customerRepositoryProvider);
      final loanRepo = _ref.read(loanRepositoryProvider);
      final paymentRepo = _ref.read(paymentRepositoryProvider);

      final settingsRepo = _ref.read(settingsRepositoryProvider);

      // Calculate start/end of month for earnings
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Fetch all stats concurrently
      final results = await Future.wait<dynamic>([
        customerRepo.getCustomerCount(),
        loanRepo.getLoanCount(status: 'ACTIVE'),
        loanRepo.getTotalPrincipalBalance(),
        loanRepo.getTotalOriginalPrincipal(),
        paymentRepo.getTotalCollectedToday(),
        loanRepo.getOverdueLoanCount(),
        paymentRepo.getTodayPayments(),
        settingsRepo.getSettings(),
        paymentRepo.getCapitalRecoveredToday(),
      ]);

      // Fetch earnings separately with fallback (new feature)
      double monthEarnings = 0;
      double projected = 0;
      try {
        monthEarnings = await paymentRepo.getRealizedEarnings(
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
        projected = await loanRepo.getProjectedMonthlyEarnings();
      } catch (_) {
        // Ignore if method not available yet
      }

      final settings = results[7];

      state = state.copyWith(
        activeCustomers: results[0] as int,
        activeLoans: results[1] as int,
        totalPrincipalBalance: results[2] as double,
        totalOriginalPrincipal: results[3] as double,
        collectedToday: results[4] as double,
        overdueCount: results[5] as int,
        paymentsTodayCount: (results[6] as List).length,
        availableCapital: settings.availableCapital,
        capitalRecoveredToday: results[8] as double,
        earningsMonth: monthEarnings,
        projectedEarnings: projected,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh statistics
  Future<void> refresh() => loadStats();
}

/// Provider for dashboard statistics
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
      ref.watch(refreshTriggerProvider);
      return DashboardNotifier(ref);
    });
