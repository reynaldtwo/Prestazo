import 'dart:math';

/// Result of a loan calculation
class LoanCalculationResult {
  final int termDays;
  final int installmentsCount;
  final DateTime endDate;
  final double totalPrincipal;
  final double totalInterest;
  final double totalPayable;
  final double installmentAmount; // Regular installment
  final double lastInstallmentAmount; // Adjusted last installment

  const LoanCalculationResult({
    required this.termDays,
    required this.installmentsCount,
    required this.endDate,
    required this.totalPrincipal,
    required this.totalInterest,
    required this.totalPayable,
    required this.installmentAmount,
    required this.lastInstallmentAmount,
  });

  @override
  String toString() {
    return 'LoanCalculationResult(days: $termDays, installments: $installmentsCount, total: $totalPayable)';
  }
}

/// Standardized business logic for loan calculations
class LoanCalculator {
  /// 1. Convert any term to days
  /// Uses commercial year (30 day months, 365 day years) logic as specified.
  static int calculateTermInDays(int term, String unit) {
    switch (unit) {
      case 'Days':
      case 'Días':
        return term;
      case 'Weeks':
      case 'Semanas':
        return term * 7;
      case 'Months':
      case 'Meses':
        return term * 30;
      case 'Years':
      case 'Años':
        return term * 365;
      default:
        // Fallback for 'Quincenas' if it ever appears as a unit string directly
        if (unit.toLowerCase().contains('quincena')) return term * 15;
        return term;
    }
  }

  /// 2. Calculate number of installments (ceil)
  static int calculateInstallmentsCount({
    required int termDays,
    required int frequencyDays,
  }) {
    if (frequencyDays <= 0) return 0;
    // "cuotasTotales = ceil(plazoDias / frecuenciaDias)"
    return (termDays / frequencyDays).ceil();
  }

  /// 3. Calculate End Date
  /// "fechaFin = fechaDesembolso + (plazoDias - 1) días"
  static DateTime calculateEndDate(DateTime disbursementDate, int termDays) {
    if (termDays <= 0) return disbursementDate;
    // Use simple day addition to avoid DST hour shifts issues with Duration
    return DateTime(
      disbursementDate.year,
      disbursementDate.month,
      disbursementDate.day + (termDays - 1),
    );
  }

  /// 4. Calculate Loan Details (Interest, Total, Installment Amount)
  static LoanCalculationResult calculateLoan({
    required double capital,
    required double monthlyRate, // Decimal (e.g. 0.1333 for 13.33%)
    required int term,
    required String termUnit, // 'Days', 'Weeks', 'Months', 'Years'
    required int frequencyDays,
    required DateTime disbursementDate,
  }) {
    // Step 1: Term in Days
    final termDays = calculateTermInDays(term, termUnit);

    // Step 2: Installments Count
    final count = calculateInstallmentsCount(
      termDays: termDays,
      frequencyDays: frequencyDays,
    );

    if (count == 0) {
      return LoanCalculationResult(
        termDays: termDays,
        installmentsCount: 0,
        endDate: disbursementDate,
        totalPrincipal: capital,
        totalInterest: 0,
        totalPayable: capital,
        installmentAmount: 0,
        lastInstallmentAmount: 0,
      );
    }

    // Step 3: End Date
    final endDate = calculateEndDate(disbursementDate, termDays);

    // Step 4: Total Interest (Add-on)
    // "Si el plazo está en meses: mesesEquivalentes = meses"
    // "Si el plazo está en otra unidad: mesesEquivalentes = plazoDias / 30"
    double equivalentMonths;
    final isMonths = termUnit == 'Months' || termUnit == 'Meses';
    if (isMonths) {
      equivalentMonths = term.toDouble();
    } else {
      equivalentMonths = termDays / 30.0;
    }

    // "interesTotal = capital * tasaMensual * mesesEquivalentes"
    final totalInterestRaw = capital * monthlyRate * equivalentMonths;
    // Round interest to 2 decimals standard currency
    final totalInterest = (totalInterestRaw * 100).roundToDouble() / 100;

    final totalPayable = capital + totalInterest;

    // Step 5: Distribute
    // "cuotaBase = totalPagar / cuotasTotales"
    // "Redondear cuotas a 2 decimales."
    final rawBaseInstallment = totalPayable / count;
    final baseInstallment = (rawBaseInstallment * 100).roundToDouble() / 100;

    // "Ajustar solo la última cuota para que la suma total sea exactamente totalPagar"
    final totalCoveredByBase = baseInstallment * (count - 1);
    // Due to floating point math, ensure simple subtraction
    final lastInstallmentRaw = totalPayable - totalCoveredByBase;
    final lastInstallment = (lastInstallmentRaw * 100).roundToDouble() / 100;

    return LoanCalculationResult(
      termDays: termDays,
      installmentsCount: count,
      endDate: endDate,
      totalPrincipal: capital,
      totalInterest: totalInterest,
      totalPayable: totalPayable,
      installmentAmount: baseInstallment,
      lastInstallmentAmount: lastInstallment,
    );
  }
}
