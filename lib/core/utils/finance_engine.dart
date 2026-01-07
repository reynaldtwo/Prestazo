/// Centralized financial calculation engine following banking standards.
/// All conversion logic must go through this class to ensure consistency.
class FinanceEngine {
  /// Universal Conversion: Base Currency → Display Currency
  ///
  /// **Rate Convention:** The rate is stored as "1 Display Unit = X Base Units".
  /// - Example: 1 MXN = 2.0468 NIO (Base=NIO, Display=MXN)
  /// - To convert 7,400 NIO to MXN: 7,400 / 2.0468 = 3,615.40 MXN
  ///
  /// **Formula:** `Display_Amount = Base_Amount / Rate`
  ///
  /// @param amountInBase The amount in the system's Base Currency.
  /// @param rate The exchange rate (1 Display = X Base).
  /// @returns The equivalent amount in the Display Currency.
  static double convertBaseToDisplay(double amountInBase, double rate) {
    if (rate <= 0) {
      // Safety fallback: if rate is invalid, return original amount
      return amountInBase;
    }
    return amountInBase / rate;
  }

  /// Universal Conversion: Foreign Currency → Base Currency (Normalization)
  ///
  /// **Rate Convention:** The contract rate is stored as "1 Foreign = X Base".
  /// - Example: Loan in USD with rate 37 means 1 USD = 37 NIO.
  /// - To normalize 100 USD to NIO: 100 * 37 = 3,700 NIO
  ///
  /// **Formula:** `Base_Amount = Foreign_Amount * Contract_Rate`
  ///
  /// @param amountInForeign The amount in a foreign currency.
  /// @param contractRate The exchange rate at contract time (1 Foreign = X Base).
  /// @returns The equivalent amount in the Base Currency.
  static double normalizeToBase(double amountInForeign, double contractRate) {
    if (contractRate <= 0) {
      throw Exception('Invalid contract rate: $contractRate');
    }
    return amountInForeign * contractRate;
  }

  /// Direction-Aware Conversion: Base → Display
  ///
  /// **CRITICAL:** The operation depends on how the rate was stored:
  /// - **Direct Rate** (Base→Display stored): MULTIPLY (1 Base = X Display)
  /// - **Reverse Rate** (Display→Base stored): DIVIDE (1 Display = X Base)
  ///
  /// @param amountInBase The amount in Base Currency.
  /// @param rate The exchange rate value.
  /// @param isDirect True if rate was stored as Base→Display, false if Display→Base.
  static double convertWithDirection(
    double amountInBase,
    double rate, {
    required bool isDirect,
  }) {
    if (rate <= 0) return amountInBase;

    if (isDirect) {
      // Rate is "1 Base = X Display" (e.g., 1 NIO = 0.4891 MXN)
      // Formula: Base × Rate = Display
      return amountInBase * rate;
    } else {
      // Rate is "1 Display = X Base" (e.g., 1 USD = 37 NIO)
      // Formula: Base ÷ Rate = Display
      return amountInBase / rate;
    }
  }
}
