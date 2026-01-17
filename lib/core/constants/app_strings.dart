/// App Strings
///
/// Centralized strings for the app UI.
/// Prepared for future internationalization (i18n).
/// Currently supports Spanish (default) and English.
library;

/// Clase que centraliza todas las cadenas de texto de la interfaz de usuario.
class AppStrings {
  AppStrings._();

  // General
  /// Nombre principal de la aplicación.
  static const String appName = 'PrestamosApp';

  /// Etiqueta para acción de guardar.
  static const String save = 'Guardar';

  /// Etiqueta para acción de cancelar.
  static const String cancel = 'Cancelar';

  /// Etiqueta para acción de confirmar.
  static const String confirm = 'Confirmar';

  /// Etiqueta para acción de eliminar.
  static const String delete = 'Eliminar';

  /// Etiqueta para acción de editar.
  static const String edit = 'Editar';

  /// Etiqueta para acción de cerrar.
  static const String close = 'Cerrar';

  /// Etiqueta para acción de búsqueda.
  static const String search = 'Buscar';

  /// Etiqueta para estado de carga.
  static const String loading = 'Cargando...';

  /// Título para mensajes de error.
  static const String error = 'Error';

  /// Título para mensajes de éxito.
  static const String success = 'Éxito';

  /// Título para mensajes de advertencia.
  static const String warning = 'Advertencia';

  /// Título para mensajes informativos.
  static const String info = 'Información';

  // Navigation
  /// Etiqueta navegación: Inicio.
  static const String navHome = 'Inicio';

  /// Etiqueta navegación: A Cobrar.
  static const String navCollect = 'A Cobrar';

  /// Etiqueta navegación: Clientes.
  static const String navCustomers = 'Clientes';

  /// Etiqueta navegación: Reportes.
  static const String navReports = 'Reportes';

  /// Etiqueta navegación: Ajustes.
  static const String navSettings = 'Ajustes';

  // Customer
  /// Etiqueta para cliente.
  static const String customer = 'Cliente';

  /// Etiqueta para clientes (plural).
  static const String customers = 'Clientes';

  /// Título para crear nuevo cliente.
  static const String newCustomer = 'Nuevo Cliente';

  /// Título para editar cliente existente.
  static const String editCustomer = 'Editar Cliente';

  /// Etiqueta para el nombre del cliente.
  static const String customerName = 'Nombre';

  /// Etiqueta para el alias del cliente.
  static const String customerAlias = 'Alias';

  /// Etiqueta para el teléfono del cliente.
  static const String customerPhone = 'Teléfono';

  /// Etiqueta para la dirección del cliente.
  static const String customerAddress = 'Dirección';

  /// Etiqueta para frecuencia de facturación.
  static const String billingFrequency = 'Frecuencia de Cobro';

  /// Opción de frecuencia quincenal.
  static const String biweekly = 'Quincenal';

  /// Opción de frecuencia mensual.
  static const String monthly = 'Mensual';

  // Loan
  /// Etiqueta para préstamo.
  static const String loan = 'Préstamo';

  /// Etiqueta para préstamos (plural).
  static const String loans = 'Préstamos';

  /// Título para crear nuevo préstamo.
  static const String newLoan = 'Nuevo Préstamo';

  /// Título para editar préstamo existente.
  static const String editLoan = 'Editar Préstamo';

  /// Etiqueta para el monto de capital.
  static const String capital = 'Capital';

  /// Etiqueta para la tasa de interés.
  static const String interestRate = 'Tasa de Interés';

  /// Etiqueta para la fecha de desembolso.
  static const String disbursementDate = 'Fecha de Desembolso';

  /// Etiqueta para la tasa mensual equivalente.
  static const String monthlyRate = 'Tasa Mensual';

  /// Etiqueta para el saldo pendiente total.
  static const String pendingBalance = 'Saldo Pendiente';

  // Payment
  /// Etiqueta para pago.
  static const String payment = 'Pago';

  /// Etiqueta para pagos (plural).
  static const String payments = 'Pagos';

  /// Título para registrar nuevo pago.
  static const String newPayment = 'Nuevo Pago';

  /// Etiqueta para el monto del pago.
  static const String paymentAmount = 'Monto del Pago';

  /// Etiqueta para la fecha del pago.
  static const String paymentDate = 'Fecha de Pago';

  /// Etiqueta para el tipo de pago.
  static const String paymentType = 'Tipo de Pago';

  /// Opción: Pago solo de intereses.
  static const String typeInterest = 'Solo Interés';

  /// Opción: Pago solo de capital.
  static const String typePrincipal = 'Solo Capital';

  /// Opción: Pago mixto (interés y capital).
  static const String typeMixed = 'Mixto';

  /// Opción: Cancelación total del préstamo.
  static const String typeCancel = 'Cancelar';

  // Billing Cycle
  /// Etiqueta para ciclo de facturación.
  static const String cycle = 'Ciclo';

  /// Etiqueta para ciclos (plural).
  static const String cycles = 'Ciclos';

  /// Etiqueta para ciclos con saldo pendiente.
  static const String pendingCycles = 'Ciclos Pendientes';

  /// Etiqueta para ciclos que ya vencieron.
  static const String overdueCycles = 'Ciclos Vencidos';

  /// Etiqueta para el ciclo en curso.
  static const String currentCycle = 'Ciclo Actual';

  /// Etiqueta para intereses acumulados pendientes.
  static const String pendingInterest = 'Interés Pendiente';

  // Reports
  /// Título general de reportes.
  static const String reports = 'Reportes';

  /// Ganancias percibidas por intereses pagados.
  static const String realizedEarnings = 'Ganancias Reales';

  /// Ganancias estimadas por intereses devengados.
  static const String projectedEarnings = 'Proyección';

  /// Suma de ganancias reales y proyectadas.
  static const String totalEarnings = 'Ganancias Totales';

  /// Etiqueta para selección de período.
  static const String dateRange = 'Rango de Fechas';

  /// Etiqueta para fecha de inicio del reporte.
  static const String startDate = 'Fecha Inicio';

  /// Etiqueta para fecha de fin del reporte.
  static const String endDate = 'Fecha Fin';

  // Settings
  /// Título general de ajustes.
  static const String settings = 'Ajustes';

  /// Sección de configuración básica.
  static const String generalSettings = 'Configuración General';

  /// Opción: Activar cobro de días de mora.
  static const String dailyAccrual = 'Cobrar días de mora';

  /// Descripción de la opción de cobro por mora diaria.
  static const String dailyAccrualDesc =
      'Calcular interés parcial por días fuera del ciclo';

  /// Opción: Permitir más de un préstamo por cliente.
  static const String allowMultipleLoans = 'Permitir múltiples préstamos';

  /// Descripción de la opción de préstamos múltiples.
  static const String allowMultipleLoansDesc =
      'Permitir más de un préstamo activo por cliente';

  /// Opción: Configurar días de anticipación para abono a capital.
  static const String daysBeforeCapital =
      'Días antes del corte para abonar capital';

  /// Ajuste de tema visual.
  static const String theme = 'Tema';

  /// Opción de tema: Claro.
  static const String themeLight = 'Claro';

  /// Opción de tema: Oscuro.
  static const String themeDark = 'Oscuro';

  /// Opción de tema: Automático.
  static const String themeSystem = 'Sistema';

  /// Ajuste de idioma de la interfaz.
  static const String language = 'Idioma';

  // Backup
  /// Sección de respaldos de datos.
  static const String backup = 'Respaldo';

  /// Lista de respaldos realizados.
  static const String backups = 'Respaldos';

  /// Acción: Crear nuevo punto de restauración.
  static const String createBackup = 'Crear Respaldo';

  /// Acción: Restaurar datos desde un archivo.
  static const String restoreBackup = 'Restaurar Respaldo';

  /// Acción: Enviar archivo de respaldo a otro dispositivo.
  static const String shareBackup = 'Compartir Respaldo';

  /// Etiqueta para la fecha del último respaldo exitoso.
  static const String lastBackup = 'Último Respaldo';

  /// Acción: Eliminar un archivo de respaldo.
  static const String deleteBackup = 'Eliminar Respaldo';

  /// Mensaje: Respaldo completado.
  static const String backupCreated = 'Respaldo creado exitosamente';

  /// Mensaje: Restauración completada.
  static const String backupRestored = 'Respaldo restaurado exitosamente';

  /// Mensaje: Respaldo removido del almacenamiento.
  static const String backupDeleted = 'Respaldo eliminado';

  /// Mensaje: No se encontraron archivos de respaldo.
  static const String noBackups = 'No hay respaldos disponibles';

  // Validation Messages
  /// Mensaje: El campo no puede estar vacío.
  static const String fieldRequired = 'Este campo es requerido';

  /// Mensaje: El formato o valor numérico no es correcto.
  static const String invalidAmount = 'Monto inválido';

  /// Mensaje: El pago propuesto supera el interés acumulado.
  static const String amountExceedsInterest =
      'El monto excede los intereses pendientes';

  /// Mensaje: El pago propuesto supera la deuda total del préstamo.
  static const String amountExceedsDebt = 'El monto excede la deuda total';

  /// Mensaje: No se permite abono a capital si hay intereses pendientes.
  static const String pendingInterestExists =
      'Hay intereses pendientes que deben pagarse primero';

  // Confirmation Messages
  /// Mensaje genérico de confirmación de borrado.
  static const String confirmDelete = '¿Está seguro de eliminar?';

  /// Confirmación específica para eliminar un cliente.
  static const String confirmDeleteCustomer =
      '¿Está seguro de eliminar este cliente?';

  /// Confirmación específica para eliminar un préstamo.
  static const String confirmDeleteLoan =
      '¿Está seguro de eliminar este préstamo?';

  /// Confirmación antes de procesar una transacción.
  static const String confirmPayment = '¿Confirma realizar este pago?';

  /// Advertencia crítica antes de restaurar un respaldo.
  static const String confirmRestore =
      '¿Está seguro de restaurar este respaldo? Los datos actuales se reemplazarán.';

  // Error Messages
  /// Error al recuperar información de la base de datos.
  static const String errorLoadingData = 'Error al cargar los datos';

  /// Error al intentar persistir cambios.
  static const String errorSavingData = 'Error al guardar los datos';

  /// Error durante el empaquetado del respaldo.
  static const String errorCreatingBackup = 'Error al crear el respaldo';

  /// Error al leer o aplicar un archivo de respaldo.
  static const String errorRestoringBackup = 'Error al restaurar el respaldo';

  /// Restricción: Cliente tiene préstamos vinculados.
  static const String customerHasLoans =
      'No se puede eliminar: el cliente tiene préstamos activos';

  /// Restricción: Préstamo tiene transacciones vinculadas.
  static const String loanHasPayments =
      'No se puede eliminar: el préstamo tiene pagos registrados';
}
