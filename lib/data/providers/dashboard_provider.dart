import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/currency_context.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';
import 'package:prestamos_app/data/providers/service_providers.dart';
import 'package:prestamos_app/services/backup_service.dart';

/// Dashboard statistics state
class DashboardStats {
  /// Crea una instancia de [DashboardStats] con las estadísticas del tablero.
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
    this.currencyContext,
    this.displaySymbol = r'$',
    this.showRateWarning = false,
  });

  /// Cantidad de clientes activos.
  final int activeCustomers;

  /// Cantidad de préstamos activos.
  final int activeLoans;

  /// Saldo capital total pendiente (en moneda de visualización).
  final double totalPrincipalBalance;

  /// Capital original total prestado (en moneda de visualización).
  final double totalOriginalPrincipal;

  /// Monto total recaudado hoy.
  final double collectedToday;

  /// Capital recuperado hoy.
  final double capitalRecoveredToday;

  /// Cantidad de préstamos vencidos.
  final int overdueCount;

  /// Cantidad de pagos recibidos hoy.
  final int paymentsTodayCount;

  /// Capital total disponible para prestar (en moneda de visualización).
  final double availableCapital;

  /// Ganancias realizadas en el mes actual.
  final double earningsMonth;

  /// Ganancias proyectadas para el mes.
  final double projectedEarnings;

  /// Indica si los datos se están cargando.
  final bool isLoading;

  /// Mensaje de error, si existe.
  final String? error;

  /// Contexto de divisas (base, visualización, tasa).
  final CurrencyContext? currencyContext;

  /// Símbolo de moneda a mostrar.
  final String displaySymbol;

  /// Indica si hay una advertencia de tasa de cambio (ej: tasa antigua o manual).
  final bool showRateWarning;

  /// Crea una copia de las estadísticas con los campos proporcionados actualizados.
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
    CurrencyContext? currencyContext,
    String? displaySymbol,
    bool? showRateWarning,
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
      currencyContext: currencyContext ?? this.currencyContext,
      displaySymbol: displaySymbol ?? this.displaySymbol,
      showRateWarning: showRateWarning ?? this.showRateWarning,
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
  /// Crea un [DashboardNotifier] e inicia la carga de estadísticas.
  DashboardNotifier(this._ref) : super(const DashboardStats()) {
    loadStats();
  }
  final Ref _ref;

  /// Load all dashboard statistics using universal currency conversion
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true);
    try {
      final customerRepo = _ref.read(customerRepositoryProvider);
      final loanRepo = _ref.read(loanRepositoryProvider);
      final paymentRepo = _ref.read(paymentRepositoryProvider);
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      final currencyService = await _ref.read(currencyServiceProvider.future);

      // Get universal currency context
      final context = await currencyService.getContext();

      debugPrint(
        '[Dashboard] Base: ${context.baseCurrency.code}, Display: ${context.displayCurrency.code}',
      );
      debugPrint(
        '[Dashboard] Has Valid Rate: ${context.hasValidRate}, Rate: ${context.sellRate}',
      );

      // Check if we have a valid rate for conversion
      if (!context.hasValidRate) {
        state = state.copyWith(
          isLoading: false,
          error: 'exchange_rate_required',
          currencyContext: context,
          displaySymbol: context.displayCurrency.symbol,
        );
        return;
      }

      // Calculate time ranges
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Fetch all stats concurrently
      final results = await Future.wait<dynamic>([
        customerRepo.getCustomerCount(),
        loanRepo.getLoanCount(status: 'ACTIVE'),
        loanRepo
            .getConsolidatedActiveLoans(), // [2] CHANGED: Fetch full list for Dart-side normalization
        loanRepo.getTotalOriginalPrincipalByCurrency(),
        paymentRepo.getTotalCollectedTodayByCurrency(),
        loanRepo.getOverdueLoanCount(),
        paymentRepo.getTodayPayments(),
        paymentRepo.getCapitalRecoveredTodayByCurrency(),
      ]);

      // Fetch earnings
      var monthEarnings = <String, double>{};
      var projected = <String, double>{};
      try {
        monthEarnings = await paymentRepo.getRealizedEarningsByCurrency(
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
        projected = await loanRepo.getProjectedMonthlyEarningsByCurrency();
      } on Exception catch (_) {}

      final settings = await settingsRepo.getSettings();

      // UNIVERSAL CONVERSION: Available Capital (Base → Display)
      final availableCapitalResult = await currencyService.convertToDisplay(
        settings.availableCapital,
        context,
      );
      final availableCapitalConverted = availableCapitalResult.amount;

      debugPrint(
        '[Dashboard] Available Capital: ${settings.availableCapital} ${context.baseCurrency.code} → $availableCapitalConverted ${context.displayCurrency.code}',
      );

      // UNIVERSAL CONVERSION: Principal Balance (already in Base → Display)
      // UNIVERSAL CONVERSION: Principal Balance with STRICT VALIDATION
      // Now using [2] which is List<Map> of loans
      final activeLoans = results[2] as List<dynamic>;
      double totalPrincipalBalance = 0;
      var rateWarning = false;
      var effectiveSymbol = context.displayCurrency.symbol;

      try {
        // Calculate Total Base -> Display using division
        totalPrincipalBalance = await currencyService.calculatePortfolioTotals(
          activeLoans,
          context,
        );
      } on Exception catch (_) {
        // Portfolio Calculation Warning ignored
        rateWarning = true;
        // FALLBACK: Sum loans in Base Currency directly (no conversion)
        for (final item in activeLoans) {
          final loan = item as Map<String, dynamic>;
          final loanCurrency = loan['currency_code'] as String? ?? '';
          final balance = (loan['principal_balance'] as num).toDouble();
          final contractRate =
              (loan['applied_exchange_rate'] as num?)?.toDouble() ?? 1.0;

          if (loanCurrency == context.baseCurrency.code) {
            totalPrincipalBalance += balance;
          } else {
            totalPrincipalBalance +=
                balance * contractRate; // Normalize to base
          }
        }
        // Show values in Base Currency (fallback)
        effectiveSymbol = context.baseCurrency.symbol;
      }

      debugPrint(
        '[Dashboard] Total Principal Calculated: $totalPrincipalBalance $effectiveSymbol',
      );

      // Convert other metrics using sumToDisplay
      final collectedToday = await currencyService.sumToDisplay(
        results[4] as Map<String, double>,
        context,
      );
      final capitalRecoveredToday = await currencyService.sumToDisplay(
        results[7] as Map<String, double>,
        context,
      );
      final earningsMonthConverted = await currencyService.sumToDisplay(
        monthEarnings,
        context,
      );
      final projectedEarningsConverted = await currencyService.sumToDisplay(
        projected,
        context,
      );
      final totalOriginalPrincipal = await currencyService.sumToDisplay(
        results[3] as Map<String, double>,
        context,
      );

      state = state.copyWith(
        activeCustomers: results[0] as int,
        activeLoans: results[1] as int,
        totalPrincipalBalance: totalPrincipalBalance,
        totalOriginalPrincipal: totalOriginalPrincipal,
        collectedToday: collectedToday,
        overdueCount: results[5] as int,
        paymentsTodayCount: (results[6] as List).length,
        availableCapital: availableCapitalConverted,
        capitalRecoveredToday: capitalRecoveredToday,
        earningsMonth: earningsMonthConverted,
        projectedEarnings: projectedEarningsConverted,
        isLoading: false,
        currencyContext: context,
        displaySymbol: effectiveSymbol,
        showRateWarning: rateWarning,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      // Check scheduled backup in background
      try {
        final settingsRepo = _ref.read(settingsRepositoryProvider);
        final settings = await settingsRepo.getSettings();
        // ignore: unawaited_futures // Background check, result doesn't affect dashboard immediate load
        BackupService.instance.checkScheduledBackup(
          frequency: settings.backupFrequency,
          retentionDays: settings.backupRetentionDays,
          retries: settings.backupRetries,
          customName: settings.backupCustomName,
        );
      } on Exception catch (_) {}
    }
  }

  /// Refresh statistics
  Future<void> refresh() => loadStats();
}

/// Provider for dashboard statistics
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
      ref
        ..watch(refreshTriggerProvider)
        ..watch(appSettingsProvider);
      return DashboardNotifier(ref);
    });
