/// App constants
class AppConstants {
  AppConstants._();

  // App Info
  /// Nombre de la aplicación.
  static const String appName = 'PrestamosApp';

  /// Versión actual de la aplicación.
  static const String appVersion = '1.0.0';

  // Database
  /// Nombre del archivo de la base de datos local.
  static const String databaseName = 'prestamos_app.db';

  /// Versión actual del esquema de la base de datos.
  static const int databaseVersion =
      34; // V34: Remove lacero field from customers

  // Currency - NO DEFAULTS HERE
  // Currency must always come from settings.baseCurrency at runtime
  // The database schema defines NULL-safe defaults for new installations

  // Default values from documentation
  /// Días de gracia por defecto antes de aplicar mora.
  static const int defaultMoratoriumDays = 1;

  /// Orden por defecto para la aplicación de pagos.
  static const String defaultPaymentApplyOrder = 'INTEREST_FIRST';

  /// Frecuencia de facturación por defecto.
  static const String defaultBillingFrequency = 'MONTHLY';

  /// Indica si se deben capitalizar intereses no pagados por defecto.
  static const bool defaultCapitalizeUnpaidInterest = false;

  /// Indica si el devengo diario está habilitado por defecto.
  static const bool defaultDailyAccrualEnabled = true;

  /// Indica si se permiten múltiples préstamos por cliente por defecto.
  static const bool defaultAllowMultipleLoans = true;

  /// Días antes del ciclo para permitir abono a capital por defecto.
  static const int defaultDaysBeforeCycleForCapital = 10;

  /// Número máximo de respaldos locales a mantener.
  static const int defaultMaxLocalBackups = 5;

  // Billing frequencies
  /// Frecuencia quincenal.
  static const String frequencyBiweekly = 'BIWEEKLY';

  /// Frecuencia mensual.
  static const String frequencyMonthly = 'MONTHLY';

  // Cycle days (start day counts as day 1)
  /// Duración en días de un ciclo quincenal.
  static const int biweeklyCycleDays = 14; // 15 days total

  /// Duración en días de un ciclo mensual.
  static const int monthlyCycleDays = 29; // 30 days total

  // Loan statuses
  /// Estado activo para un préstamo.
  static const String loanStatusActive = 'ACTIVE';

  /// Estado en mora para un préstamo.
  static const String loanStatusInMora = 'IN_MORA';

  /// Estado cerrado para un préstamo.
  static const String loanStatusClosed = 'CLOSED';

  // Cycle statuses
  /// Estado pendiente para un ciclo.
  static const String cycleStatusPending = 'PENDING';

  /// Estado pagado para un ciclo.
  static const String cycleStatusPaid = 'PAID';

  /// Estado vencido (mora) para un ciclo.
  static const String cycleStatusOverdue = 'OVERDUE';

  /// Estado cerrado para un ciclo.
  static const String cycleStatusClosed = 'CLOSED';

  // Payment statuses
  /// Pago válido.
  static const String paymentStatusValid = 'VALID';

  /// Pago anulado.
  static const String paymentStatusVoided = 'VOIDED';

  // Payment types
  /// Pago de intereses.
  static const String paymentTypeInterest = 'INTEREST';

  /// Pago de capital.
  static const String paymentTypePrincipal = 'PRINCIPAL';

  /// Pago mixto (interés y capital).
  static const String paymentTypeMixed = 'MIXED';

  /// Pago para cancelar el préstamo totalmente.
  static const String paymentTypeCancel = 'CANCEL';

  // Allocation types
  /// Asignación a intereses.
  static const String allocationTypeInterest = 'INTEREST';

  /// Asignación a capital.
  static const String allocationTypePrincipal = 'PRINCIPAL';

  /// Asignación a mora.
  static const String allocationTypeMora = 'MORA';

  /// Asignación a cargos/comisiones.
  static const String allocationTypeFees = 'FEES';

  // Customer statuses
  /// Cliente activo.
  static const String customerStatusActive = 'ACTIVE';

  /// Cliente inactivo.
  static const String customerStatusInactive = 'INACTIVE';

  // Theme modes
  /// Modo claro.
  static const String themeModeLight = 'light';

  /// Modo oscuro.
  static const String themeModeDark = 'dark';

  /// Modo siguiendo al sistema.
  static const String themeModeSystem = 'system';

  // Languages
  /// Idioma español.
  static const String languageSpanish = 'es';

  /// Idioma inglés.
  static const String languageEnglish = 'en';

  // Backup
  /// Nombre de la carpeta de respaldos.
  static const String backupFolderName = 'backups';

  /// Extensión de los archivos de respaldo.
  static const String backupFileExtension = '.db';

  // UI Constants
  /// Padding por defecto.
  static const double defaultPadding = 16;

  /// Padding pequeño.
  static const double smallPadding = 8;

  /// Padding grande.
  static const double largePadding = 24;

  /// Radio de borde por defecto.
  static const double defaultRadius = 12;

  /// Radio de borde pequeño.
  static const double smallRadius = 8;

  /// Radio de borde grande.
  static const double largeRadius = 16;

  /// Duración por defecto de animaciones en milisegundos.
  static const int defaultAnimationDuration = 300;
}
