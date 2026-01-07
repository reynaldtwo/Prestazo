/// App constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PrestamosApp';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'prestamos_app.db';
  static const int databaseVersion = 19; // Bump for missed columns

  // Currency - NO DEFAULTS HERE
  // Currency must always come from settings.baseCurrency at runtime
  // The database schema defines NULL-safe defaults for new installations

  // Default values from documentation
  static const int defaultMoratoriumDays = 1;
  static const String defaultPaymentApplyOrder = 'INTEREST_FIRST';
  static const String defaultBillingFrequency = 'MONTHLY';
  static const bool defaultCapitalizeUnpaidInterest = false;
  static const bool defaultDailyAccrualEnabled = true;
  static const bool defaultAllowMultipleLoans = true;
  static const int defaultDaysBeforeCycleForCapital = 10;
  static const int defaultMaxLocalBackups = 5;

  // Billing frequencies
  static const String frequencyBiweekly = 'BIWEEKLY';
  static const String frequencyMonthly = 'MONTHLY';

  // Cycle days (start day counts as day 1)
  static const int biweeklyCycleDays = 14; // 15 days total
  static const int monthlyCycleDays = 29; // 30 days total

  // Loan statuses
  static const String loanStatusActive = 'ACTIVE';
  static const String loanStatusInMora = 'IN_MORA';
  static const String loanStatusClosed = 'CLOSED';

  // Cycle statuses
  static const String cycleStatusPending = 'PENDING';
  static const String cycleStatusPaid = 'PAID';
  static const String cycleStatusOverdue = 'OVERDUE';
  static const String cycleStatusClosed = 'CLOSED';

  // Payment statuses
  static const String paymentStatusValid = 'VALID';
  static const String paymentStatusVoided = 'VOIDED';

  // Payment types
  static const String paymentTypeInterest = 'INTEREST';
  static const String paymentTypePrincipal = 'PRINCIPAL';
  static const String paymentTypeMixed = 'MIXED';
  static const String paymentTypeCancel = 'CANCEL';

  // Allocation types
  static const String allocationTypeInterest = 'INTEREST';
  static const String allocationTypePrincipal = 'PRINCIPAL';
  static const String allocationTypeMora = 'MORA';
  static const String allocationTypeFees = 'FEES';

  // Customer statuses
  static const String customerStatusActive = 'ACTIVE';
  static const String customerStatusInactive = 'INACTIVE';

  // Theme modes
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';
  static const String themeModeSystem = 'system';

  // Languages
  static const String languageSpanish = 'es';
  static const String languageEnglish = 'en';

  // Backup
  static const String backupFolderName = 'backups';
  static const String backupFileExtension = '.db';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  static const int defaultAnimationDuration = 300;
}
