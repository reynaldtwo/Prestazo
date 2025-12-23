/// App Strings
///
/// Centralized strings for the app UI.
/// Prepared for future internationalization (i18n).
/// Currently supports Spanish (default) and English.
library;

class AppStrings {
  AppStrings._();

  // General
  static const String appName = 'PrestamosApp';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String close = 'Cerrar';
  static const String search = 'Buscar';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String success = 'Éxito';
  static const String warning = 'Advertencia';
  static const String info = 'Información';

  // Navigation
  static const String navHome = 'Inicio';
  static const String navCollect = 'A Cobrar';
  static const String navCustomers = 'Clientes';
  static const String navReports = 'Reportes';
  static const String navSettings = 'Ajustes';

  // Customer
  static const String customer = 'Cliente';
  static const String customers = 'Clientes';
  static const String newCustomer = 'Nuevo Cliente';
  static const String editCustomer = 'Editar Cliente';
  static const String customerName = 'Nombre';
  static const String customerAlias = 'Alias';
  static const String customerPhone = 'Teléfono';
  static const String customerAddress = 'Dirección';
  static const String billingFrequency = 'Frecuencia de Cobro';
  static const String biweekly = 'Quincenal';
  static const String monthly = 'Mensual';

  // Loan
  static const String loan = 'Préstamo';
  static const String loans = 'Préstamos';
  static const String newLoan = 'Nuevo Préstamo';
  static const String editLoan = 'Editar Préstamo';
  static const String capital = 'Capital';
  static const String interestRate = 'Tasa de Interés';
  static const String disbursementDate = 'Fecha de Desembolso';
  static const String monthlyRate = 'Tasa Mensual';
  static const String pendingBalance = 'Saldo Pendiente';

  // Payment
  static const String payment = 'Pago';
  static const String payments = 'Pagos';
  static const String newPayment = 'Nuevo Pago';
  static const String paymentAmount = 'Monto del Pago';
  static const String paymentDate = 'Fecha de Pago';
  static const String paymentType = 'Tipo de Pago';
  static const String typeInterest = 'Solo Interés';
  static const String typePrincipal = 'Solo Capital';
  static const String typeMixed = 'Mixto';
  static const String typeCancel = 'Cancelar';

  // Billing Cycle
  static const String cycle = 'Ciclo';
  static const String cycles = 'Ciclos';
  static const String pendingCycles = 'Ciclos Pendientes';
  static const String overdueCycles = 'Ciclos Vencidos';
  static const String currentCycle = 'Ciclo Actual';
  static const String pendingInterest = 'Interés Pendiente';

  // Reports
  static const String reports = 'Reportes';
  static const String realizedEarnings = 'Ganancias Reales';
  static const String projectedEarnings = 'Proyección';
  static const String totalEarnings = 'Ganancias Totales';
  static const String dateRange = 'Rango de Fechas';
  static const String startDate = 'Fecha Inicio';
  static const String endDate = 'Fecha Fin';

  // Settings
  static const String settings = 'Ajustes';
  static const String generalSettings = 'Configuración General';
  static const String dailyAccrual = 'Cobrar días de mora';
  static const String dailyAccrualDesc =
      'Calcular interés parcial por días fuera del ciclo';
  static const String allowMultipleLoans = 'Permitir múltiples préstamos';
  static const String allowMultipleLoansDesc =
      'Permitir más de un préstamo activo por cliente';
  static const String daysBeforeCapital =
      'Días antes del corte para abonar capital';
  static const String theme = 'Tema';
  static const String themeLight = 'Claro';
  static const String themeDark = 'Oscuro';
  static const String themeSystem = 'Sistema';
  static const String language = 'Idioma';

  // Backup
  static const String backup = 'Respaldo';
  static const String backups = 'Respaldos';
  static const String createBackup = 'Crear Respaldo';
  static const String restoreBackup = 'Restaurar Respaldo';
  static const String shareBackup = 'Compartir Respaldo';
  static const String lastBackup = 'Último Respaldo';
  static const String deleteBackup = 'Eliminar Respaldo';
  static const String backupCreated = 'Respaldo creado exitosamente';
  static const String backupRestored = 'Respaldo restaurado exitosamente';
  static const String backupDeleted = 'Respaldo eliminado';
  static const String noBackups = 'No hay respaldos disponibles';

  // Validation Messages
  static const String fieldRequired = 'Este campo es requerido';
  static const String invalidAmount = 'Monto inválido';
  static const String amountExceedsInterest =
      'El monto excede los intereses pendientes';
  static const String amountExceedsDebt = 'El monto excede la deuda total';
  static const String pendingInterestExists =
      'Hay intereses pendientes que deben pagarse primero';

  // Confirmation Messages
  static const String confirmDelete = '¿Está seguro de eliminar?';
  static const String confirmDeleteCustomer =
      '¿Está seguro de eliminar este cliente?';
  static const String confirmDeleteLoan =
      '¿Está seguro de eliminar este préstamo?';
  static const String confirmPayment = '¿Confirma realizar este pago?';
  static const String confirmRestore =
      '¿Está seguro de restaurar este respaldo? Los datos actuales se reemplazarán.';

  // Error Messages
  static const String errorLoadingData = 'Error al cargar los datos';
  static const String errorSavingData = 'Error al guardar los datos';
  static const String errorCreatingBackup = 'Error al crear el respaldo';
  static const String errorRestoringBackup = 'Error al restaurar el respaldo';
  static const String customerHasLoans =
      'No se puede eliminar: el cliente tiene préstamos activos';
  static const String loanHasPayments =
      'No se puede eliminar: el préstamo tiene pagos registrados';
}
