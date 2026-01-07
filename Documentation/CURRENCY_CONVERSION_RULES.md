# Currency Conversion Rules

This document defines all currency conversion operations in the PrestamosApp.

## 📌 Terminology

| Term | Definition |
|------|------------|
| **Base Currency** | The currency in which the lender's capital is denominated (e.g., NIO). Set in Settings. |
| **Report Currency** | The currency used for **viewing** aggregated data on the Dashboard. Can be changed freely. |
| **Loan Currency** | The currency in which a specific loan was disbursed (e.g., USD). Stored per-loan. |
| **Contract Rate** | The exchange rate locked at loan creation (`loan.appliedExchangeRate`). Used to normalize foreign loans to base. |
| **System Rate** | The current exchange rate fetched from the Exchange Rates table. |

---

## 🔄 Conversion Types

### 1. Loan → Base (Normalization)
**Purpose:** Aggregate all loans into a single base value for capital tracking.

**Formula:**
```
IF loan.currencyCode == baseCurrency:
    normalizedValue = loan.principalBalance
ELSE:
    normalizedValue = loan.principalBalance * loan.appliedExchangeRate
```

**Applied In:** `LoanRepository.getTotalNormalizedPrincipalBalance(baseCurrency)`

---

### 2. Base → Report (Display Conversion)
**Purpose:** Convert aggregated base-currency values into the user's preferred viewing currency.

**Formula:**
```
IF baseCurrency == reportCurrency:
    displayValue = baseValue  // NO CONVERSION
ELSE:
    rate = CurrencyService.getDisbursementRate(baseCurrency, reportCurrency)
    displayValue = baseValue * rate
```

**Applied In:** `DashboardNotifier.loadStats()` for `availableCapital`, `totalPrincipalBalance`.

> [!WARNING]
> If the value is already in baseCurrency, and reportCurrency equals baseCurrency, **do NOT apply any rate**.

---

### 3. Payment → Loan Currency (Allocation)
**Purpose:** When a payment is made in a different currency than the loan, convert to loan currency.

**Formula:**
```
IF paymentCurrency == loanCurrency:
    allocatedAmount = paymentAmount
ELSE:
    allocatedAmount = paymentAmount / appliedExchangeRate
```

**Applied In:** `PaymentFormScreen._submitPayment()`

---

## 📊 Dashboard Metrics

| Metric | Source | Conversion |
|--------|--------|------------|
| Capital Placed | `getTotalNormalizedPrincipalBalance(base)` | Base → Report |
| Available Capital (Ceiling) | `settings.availableCapital` (in Base) | Base → Report |
| Occupancy % | Placed / Ceiling | Both must be in same currency |
| Collected Today | `getCollectedTodayByCurrency()` | Map → Report |
| Earnings Month | `getRealizedEarningsByCurrency()` | Map → Report |

---

## 🛡️ Invariants

1. **Loan Display:** Always use `loan.currencyCode` for formatting amounts on loan-specific screens.
2. **No Double Conversion:** A normalized value should never be converted twice.
3. **Same-Currency Rate:** `getRate(X, X)` must always return `1.0`.

---

## 📂 Key Files

- `lib/services/currency_service.dart` — Central conversion service
- `lib/data/providers/dashboard_provider.dart` — Dashboard aggregation
- `lib/data/repositories/loan_repository.dart` — Normalization queries
- `lib/core/utils/currency_utils.dart` — Symbol/code utilities
