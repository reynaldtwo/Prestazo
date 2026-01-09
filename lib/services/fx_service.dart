// FxService for Foreign Exchange logic

enum FxDirection {
  baseToForeign, // e.g. NIO -> USD
  foreignToBase, // e.g. USD -> NIO
  foreignToForeign, // e.g. USD -> EUR (via NIO)
  sameCurrency, // e.g. USD -> USD
}

/// Service for Foreign Exchange logic and Profit calculations.
class FxService {
  /// Determine the direction of conversion relative to Base Currency.
  static FxDirection getDirection({
    required String baseCurrency,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return FxDirection.sameCurrency;
    if (fromCurrency == baseCurrency) return FxDirection.baseToForeign;
    if (toCurrency == baseCurrency) return FxDirection.foreignToBase;
    return FxDirection.foreignToForeign;
  }

  /// Calculate expected number of FX Legs for a transaction.
  static int getExpectedLegs(FxDirection direction) {
    switch (direction) {
      case FxDirection.sameCurrency:
        return 0;
      case FxDirection.baseToForeign:
      case FxDirection.foreignToBase:
        return 1;
      case FxDirection.foreignToForeign:
        return 2;
    }
  }

  /// Calculate FX Profit in Base Currency (Minor Units).
  ///
  /// Formula:
  /// Profit = (AmountSold_BaseEquivalent - AmountBought_BaseEquivalent)
  ///
  /// For Foreign to Base (Sell Foreign, Buy Base):
  /// Customer gives Foreign (AmountFrom), gets Base (AmountTo).
  /// Quote is typically Rate = Base / Foreign (e.g. 36.62 NIO per USD).
  ///
  /// Logic:
  /// Value_In_Base(AmountFrom) - Value_In_Base(AmountTo)
  /// If From is Foreign: Value = AmountFrom * ReferenceRate
  /// If To is Base: Value = AmountTo
  /// Profit = (AmountFrom * ReferenceRate) - AmountTo
  static int calculateProfitMinor({
    required int amountFromMinor,
    required int amountToMinor,
    required double referenceRate, // Base per Foreign (e.g. 36.62)
    required FxDirection direction,
  }) {
    if (direction == FxDirection.sameCurrency) return 0;

    // Case 1: Foreign to Base (Buying Foreign from Customer)
    // Bank receives AmountFrom (Foreign). Value = AmountFrom * RefRate.
    // Bank pays AmountTo (Base). Cost = AmountTo.
    if (direction == FxDirection.foreignToBase) {
      double valueInBase = amountFromMinor * referenceRate;
      double costInBase = amountToMinor.toDouble();
      return (valueInBase - costInBase).round();
    }

    // Case 2: Base to Foreign (Selling Foreign to Customer)
    // Bank receives AmountFrom (Base). Value = AmountFrom.
    // Bank pays AmountTo (Foreign). Cost = AmountTo * RefRate.
    if (direction == FxDirection.baseToForeign) {
      double valueInBase = amountFromMinor.toDouble();
      double costInBase = amountToMinor * referenceRate;
      return (valueInBase - costInBase).round();
    }

    return 0;
  }

  /// Convert an amount from one currency to another using a direct Exchange Rate.
  ///
  /// The [rate] must be defined as "Base Currency units per 1 Foreign Unit".
  /// Example: 37.00 NIO per 1 USD.
  ///
  /// Logic:
  /// - If [fromCurrency] == [toCurrency]: Return amount as is.
  /// - If [fromCurrency] is Foreign (e.g. USD) and [toCurrency] is Base (e.g. NIO):
  ///   MULTIPLY: 5 USD * 37 = 185 NIO.
  /// - If [fromCurrency] is Base (e.g. NIO) and [toCurrency] is Foreign (e.g. USD):
  ///   DIVIDE: 185 NIO / 37 = 5 USD.
  ///
  /// Note: Cross-currency (Foreign A -> Foreign B) is not supported by single rate.
  /// It requires two steps via Base. This method assumes one leg involves Base.
  static int convertMinor({
    required int amountMinor,
    required double rate,
    required String fromCurrency,
    required String toCurrency,
    required String baseCurrency,
  }) {
    if (amountMinor == 0) return 0;
    if (fromCurrency == toCurrency) return amountMinor;

    // Safety check
    if (rate <= 0) return amountMinor;

    final direction = getDirection(
      baseCurrency: baseCurrency,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );

    if (direction == FxDirection.foreignToBase) {
      // Selling Foreign (USD) -> Buying Base (NIO)
      // 1 USD = 37 NIO
      // Amount * Rate
      return (amountMinor * rate).round();
    }

    if (direction == FxDirection.baseToForeign) {
      // Selling Base (NIO) -> Buying Foreign (USD)
      // 1 USD = 37 NIO
      // Amount / Rate
      return (amountMinor / rate).round();
    }

    // Default fallback (should handle cross-currency separately)
    return amountMinor;
  }
}
