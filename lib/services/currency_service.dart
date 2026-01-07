import '../core/utils/finance_engine.dart';
import '../data/models/app_settings.dart';
import '../data/models/currency_context.dart';
import '../data/repositories/exchange_rate_repository.dart';

/// Centralized service for currency conversion
/// Uses STRICT rules: TODAY's Sell Rate ONLY, no fallbacks
class CurrencyService {
  final ExchangeRateRepository _exchangeRateRepo;
  final AppSettings _settings;

  CurrencyService({
    required ExchangeRateRepository exchangeRateRepo,
    required AppSettings settings,
  }) : _exchangeRateRepo = exchangeRateRepo,
       _settings = settings;

  // ============================================
  // UNIVERSAL CONTEXT & CONVERSION METHODS
  // ============================================

  /// Get the current currency context with today's sell rate
  Future<CurrencyContext> getContext() async {
    final baseCurrency = CurrencyInfo.fromCode(_settings.baseCurrency);
    final displayCurrency = CurrencyInfo.fromCode(_settings.reportCurrency);

    // If same currency, no rate needed
    if (baseCurrency.code == displayCurrency.code) {
      return CurrencyContext.singleCurrency(baseCurrency);
    }

    // Get TODAY's sell rate for display conversion
    final sellRate = await getTodaySellRate(
      baseCurrency.code,
      displayCurrency.code,
    );

    return CurrencyContext(
      baseCurrency: baseCurrency,
      displayCurrency: displayCurrency,
      sellRate: sellRate,
    );
  }

  /// Convert amount from Base currency to Display currency
  /// Uses direction-aware conversion (multiply for direct, divide for reverse)
  Future<ConversionResult> convertToDisplay(
    double amount,
    CurrencyContext context,
  ) async {
    // Same currency - no conversion needed
    if (context.isSameCurrency) {
      return ConversionResult(
        amount: amount,
        symbol: context.displayCurrency.symbol,
      );
    }

    // Get rate with direction
    final rateResult = await getTodayRateWithDirection(
      context.baseCurrency.code,
      context.displayCurrency.code,
    );

    if (rateResult == null || rateResult.rate <= 0) {
      return ConversionResult.error('exchange_rate_required');
    }

    // Direction-Aware Conversion
    final converted = FinanceEngine.convertWithDirection(
      amount,
      rateResult.rate,
      isDirect: rateResult.isDirect,
    );

    return ConversionResult(
      amount: converted,
      symbol: context.displayCurrency.symbol,
    );
  }

  /// Convert amount from foreign currency to Base using contract rate
  /// Used for portfolio valuation
  /// FORMULA: Foreign_Amount * Contract_Rate = Base_Amount
  double convertToBaseWithContractRate(
    double amount,
    String fromCurrencyCode,
    double contractRate,
  ) {
    if (fromCurrencyCode == _settings.baseCurrency) {
      return amount;
    }
    // Contract rate is stored as "1 Foreign = X Base"
    return amount * contractRate;
  }

  /// Get TODAY's sell rate ONLY - no fallbacks, no old rates
  /// Returns (rate, isDirect) where isDirect indicates if rate is Base→Display
  /// Returns null if no rate exists for today
  Future<({double rate, bool isDirect})?> getTodayRateWithDirection(
    String source,
    String target,
  ) async {
    if (source == target) return (rate: 1.0, isDirect: true);

    // STRICT: Only today's rate
    // Try direct rate (source→target) - this means "1 source = X target"
    final directRate = await _exchangeRateRepo.getTodayRate(source, target);
    if (directRate != null && directRate.sellRate > 0) {
      return (rate: directRate.sellRate, isDirect: true);
    }

    // Try reverse rate (target→source) - this means "1 target = X source"
    final reverseRate = await _exchangeRateRepo.getTodayRate(target, source);
    if (reverseRate != null && reverseRate.sellRate > 0) {
      return (rate: reverseRate.sellRate, isDirect: false);
    }

    // NO FALLBACK - if no today's rate, return null (will show error)
    return null;
  }

  /// Legacy wrapper for backward compatibility
  Future<double?> getTodaySellRate(String source, String target) async {
    final result = await getTodayRateWithDirection(source, target);
    return result?.rate;
  }

  /// Check if NO Rate exists for today (helper)
  Future<bool> hasTodayRate(String source, String target) async {
    final rate = await getTodaySellRate(source, target);
    return rate != null && rate > 0;
  }

  /// =========================================================================
  /// ISO 4217 "The Bridge Algorithm" Implementation
  /// =========================================================================

  /// 1. [Caja Única] Normalizes any amount to the System Base Currency.
  /// Uses strict Contract Rate from the loan/transaction.
  double normalizeToBase(double amount, double contractRate) {
    if (contractRate <= 0) {
      throw Exception(
        'Financial Error: Non-positive contract rate ($contractRate)',
      );
    }
    // Base = Foreign * Rate
    return amount * contractRate;
  }

  /// 2. [Bridge Algorithm] Converts Normalized Base to Display Currency.
  /// FORMULA: Display = Base / Rate (Rate is "1 Display = X Base")
  double applyBridgeConversion(double amountInBase, double sellRate) {
    return FinanceEngine.convertBaseToDisplay(amountInBase, sellRate);
  }

  /// [High-Level] Calculate Portfolio Totals using ISO Standards
  Future<double> calculatePortfolioTotals(
    List<dynamic> loans,
    CurrencyContext context,
  ) async {
    double totalNormalizedBase = 0.0;
    final baseCurrency = context.baseCurrency;

    // A. Normalization Phase (Caja Única)
    for (var loan in loans) {
      String loanCurrencyCode;
      double principalBalance;
      double? appliedExchangeRate;

      if (loan is Map) {
        loanCurrencyCode = loan['currency_code'] ?? 'NIO';
        principalBalance = (loan['principal_balance'] as num).toDouble();
        appliedExchangeRate = (loan['applied_exchange_rate'] as num?)
            ?.toDouble();
      } else {
        loanCurrencyCode = loan.currencyCode;
        principalBalance = loan.principalBalance;
        appliedExchangeRate = loan.appliedExchangeRate;
      }

      if (loanCurrencyCode == baseCurrency.code) {
        totalNormalizedBase += principalBalance;
      } else {
        final contractRate = appliedExchangeRate;
        if (contractRate == null || contractRate <= 0) {
          throw Exception(
            'ISO Validation Fail: Loan in $loanCurrencyCode missing contract rate.',
          );
        }
        totalNormalizedBase += normalizeToBase(principalBalance, contractRate);
      }
    }

    // B. Universal Output Phase (The Bridge)
    if (context.displayCurrency.code == baseCurrency.code) {
      return totalNormalizedBase;
    }

    // Identify Parity and Rate WITH DIRECTION
    final rateResult = await getTodayRateWithDirection(
      baseCurrency.code,
      context.displayCurrency.code,
    );

    // STRICT VALIDATION
    if (rateResult == null || rateResult.rate <= 0) {
      throw Exception(
        'Missing Market Rate: ${baseCurrency.code} -> ${context.displayCurrency.code}',
      );
    }

    // Direction-Aware Formula:
    // - Direct (Base→Display stored): MULTIPLY
    // - Reverse (Display→Base stored): DIVIDE
    return FinanceEngine.convertWithDirection(
      totalNormalizedBase,
      rateResult.rate,
      isDirect: rateResult.isDirect,
    );
  }

  // ============================================
  // LEGACY METHODS (for backward compatibility)
  // ============================================

  Future<double> getRate(
    String source,
    String target, {
    String type = 'MID',
  }) async {
    if (source == target) return 1.0;
    final todayRate = await _exchangeRateRepo.getTodayRate(source, target);
    if (todayRate != null) {
      switch (type) {
        case 'BUY':
          return todayRate.buyRate;
        case 'SELL':
          return todayRate.sellRate;
        case 'MID':
        default:
          return todayRate.averageRate;
      }
    }
    final reverseToday = await _exchangeRateRepo.getTodayRate(target, source);
    if (reverseToday != null) {
      switch (type) {
        case 'BUY':
          return reverseToday.sellRate > 0 ? reverseToday.sellRate : 1.0;
        case 'SELL':
          return reverseToday.buyRate > 0 ? reverseToday.buyRate : 1.0;
        case 'MID':
        default:
          return reverseToday.averageRate > 0 ? reverseToday.averageRate : 1.0;
      }
    }
    final latestRate = await _exchangeRateRepo.getLatestRate(source, target);
    if (latestRate != null) {
      switch (type) {
        case 'BUY':
          return latestRate.buyRate;
        case 'SELL':
          return latestRate.sellRate;
        case 'MID':
        default:
          return latestRate.averageRate;
      }
    }
    return 1.0;
  }

  Future<double> getDisbursementRate(String source, String target) async {
    return getRate(source, target, type: _settings.disbursementRateType);
  }

  Future<double> getCurrentRate(String source, String target) async {
    return getRate(source, target, type: 'MID');
  }

  Future<double> getPaymentRate(String source, String target) async {
    return getRate(source, target, type: _settings.paymentRateType);
  }

  /// Aggregate amounts from multiple currencies into Display Currency.
  /// Uses ISO 4217 Banking Standard:
  /// 1. Normalize each amount to Base Currency
  /// 2. Sum all normalized values
  /// 3. Convert total to Display Currency
  Future<double> aggregateMultiCurrencyToDisplay(
    Map<String, double> amountsByCurrency,
    CurrencyContext context,
  ) async {
    double totalInBase = 0.0;
    final baseCurrency = context.baseCurrency.code;

    // Phase 1: Normalize all amounts to Base Currency
    for (final entry in amountsByCurrency.entries) {
      final fromCode = entry.key;
      final amount = entry.value;

      if (fromCode == baseCurrency) {
        // Already in base currency
        totalInBase += amount;
      } else {
        // Need to convert to base using direction-aware logic
        final rateResult = await getTodayRateWithDirection(
          fromCode,
          baseCurrency,
        );
        if (rateResult != null && rateResult.rate > 0) {
          totalInBase += FinanceEngine.convertWithDirection(
            amount,
            rateResult.rate,
            isDirect: rateResult.isDirect,
          );
        }
        // If no rate, skip this amount (silent fallback)
      }
    }

    // Phase 2: Convert total to Display Currency
    if (context.isSameCurrency) {
      return totalInBase;
    }

    final displayRateResult = await getTodayRateWithDirection(
      baseCurrency,
      context.displayCurrency.code,
    );

    if (displayRateResult == null || displayRateResult.rate <= 0) {
      return totalInBase; // Fallback to base if no rate
    }

    return FinanceEngine.convertWithDirection(
      totalInBase,
      displayRateResult.rate,
      isDirect: displayRateResult.isDirect,
    );
  }

  /// Backward-compatible alias for aggregateMultiCurrencyToDisplay
  Future<double> sumToDisplay(
    Map<String, double> amountsByCurrency,
    CurrencyContext context,
  ) => aggregateMultiCurrencyToDisplay(amountsByCurrency, context);

  /// Aggregate amounts from multiple currencies into Base Currency only.
  /// This is Phase 1 of aggregateMultiCurrencyToDisplay - stops before display conversion.
  Future<double> aggregateMultiCurrencyToBase(
    Map<String, double> amountsByCurrency,
    CurrencyContext context,
  ) async {
    double totalInBase = 0.0;
    final baseCurrency = context.baseCurrency.code;

    for (final entry in amountsByCurrency.entries) {
      final fromCode = entry.key;
      final amount = entry.value;

      if (fromCode == baseCurrency) {
        totalInBase += amount;
      } else {
        final rateResult = await getTodayRateWithDirection(
          fromCode,
          baseCurrency,
        );
        if (rateResult != null && rateResult.rate > 0) {
          totalInBase += FinanceEngine.convertWithDirection(
            amount,
            rateResult.rate,
            isDirect: rateResult.isDirect,
          );
        }
      }
    }
    return totalInBase;
  }

  Future<bool> hasRateForToday(String source, String target) async {
    return hasTodayRate(source, target);
  }
}
