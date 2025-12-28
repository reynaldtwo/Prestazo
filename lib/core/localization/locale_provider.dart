/// Locale Provider
///
/// Provider for managing app language (locale) with persistence.
/// Supports Spanish (default) and English.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale key for storage
const String _localeKey = 'app_locale';

/// Supported locales
class AppLocales {
  static const Locale spanish = Locale('es', 'NI');
  static const Locale english = Locale('en', 'US');

  static List<Locale> get supportedLocales => [spanish, english];

  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}

/// Locale provider with persistence
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Notifier for locale state
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(AppLocales.spanish) {
    _loadLocale();
  }

  /// Load locale from storage
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        final parts = localeCode.split('_');
        if (parts.length == 2) {
          state = Locale(parts[0], parts[1]);
        } else {
          state = Locale(parts[0]);
        }
      }
    } catch (_) {
      state = AppLocales.spanish;
    }
  }

  /// Set and persist locale
  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await prefs.setString(_localeKey, code);
    } catch (_) {
      // Ignore storage errors
    }
  }
}

/// Localized strings accessor
/// Usage: S.of(context).appName
class S {
  final Locale locale;

  S(this.locale);

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(AppLocales.spanish);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  bool get isSpanish => locale.languageCode == 'es';

  // ===== GENERAL =====
  String get appName => 'Prestazo';
  String get save => isSpanish ? 'Guardar' : 'Save';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get confirm => isSpanish ? 'Confirmar' : 'Confirm';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';
  String get edit => isSpanish ? 'Editar' : 'Edit';
  String get close => isSpanish ? 'Cerrar' : 'Close';
  String get search => isSpanish ? 'Buscar' : 'Search';
  String get loading => isSpanish ? 'Cargando...' : 'Loading...';
  String get error => isSpanish ? 'Error' : 'Error';
  String get success => isSpanish ? 'Éxito' : 'Success';
  String get warning => isSpanish ? 'Advertencia' : 'Warning';
  String get info => isSpanish ? 'Información' : 'Information';
  String get understood => isSpanish ? 'Entendido' : 'Understood';
  String get continue_ => isSpanish ? 'Continuar' : 'Continue';
  String get today => isSpanish ? 'Hoy' : 'Today';
  String get yesterday => isSpanish ? 'Ayer' : 'Yesterday';
  String get tomorrow => isSpanish ? 'Mañana' : 'Tomorrow';
  String get viewAll => isSpanish ? 'Ver Todo' : 'View All';

  // ===== NAVIGATION =====
  String get navHome => isSpanish ? 'Inicio' : 'Home';
  String get navCollect => isSpanish ? 'A Cobrar' : 'To Collect';
  String get navCustomers => isSpanish ? 'Clientes' : 'Customers';
  String get navReports => isSpanish ? 'Reportes' : 'Reports';
  String get navSettings => isSpanish ? 'Ajustes' : 'Settings';

  // ===== CUSTOMER =====
  String get customer => isSpanish ? 'Cliente' : 'Customer';
  String get customers => isSpanish ? 'Clientes' : 'Customers';
  String get newCustomer => isSpanish ? 'Nuevo Cliente' : 'New Customer';
  String get editCustomer => isSpanish ? 'Editar Cliente' : 'Edit Customer';
  String get customerName => isSpanish ? 'Nombre' : 'Name';
  String get customerAlias => isSpanish ? 'Alias' : 'Nickname';
  String get customerPhone => isSpanish ? 'Teléfono' : 'Phone';
  String get customerAddress => isSpanish ? 'Dirección' : 'Address';
  String get billingFrequency =>
      isSpanish ? 'Frecuencia de Cobro' : 'Billing Frequency';
  String get biweekly => isSpanish ? 'Quincenal' : 'Biweekly';
  String get monthly => isSpanish ? 'Mensual' : 'Monthly';
  String get searchHint => isSpanish
      ? 'Buscar por nombre, alias o teléfono...'
      : 'Search by name, alias or phone...';
  String get clearFilter => isSpanish ? 'Limpiar filtro' : 'Clear filter';
  String get filterCustomers =>
      isSpanish ? 'Filtrar clientes' : 'Filter customers';
  String get all => isSpanish ? 'Todos' : 'All';
  String get statusInactive => isSpanish ? 'Inactivo' : 'Inactive';
  String get noCustomers => isSpanish ? 'No hay clientes' : 'No customers';
  String get noResults =>
      isSpanish ? 'No se encontraron resultados' : 'No results found';
  String get addFirstCustomer => isSpanish
      ? 'Agrega tu primer cliente presionando el botón +'
      : 'Add your first customer by pressing +';
  String get tryAnotherTerm => isSpanish
      ? 'Intenta con otro término de búsqueda'
      : 'Try another search term';

  // ===== LOAN =====
  String get loan => isSpanish ? 'Préstamo' : 'Loan';
  String get loans => isSpanish ? 'Préstamos' : 'Loans';
  String get newLoan => isSpanish ? 'Nuevo Préstamo' : 'New Loan';
  String get editLoan => isSpanish ? 'Editar Préstamo' : 'Edit Loan';
  String get loanDetail => isSpanish ? 'Detalle del Préstamo' : 'Loan Details';
  String get capital => isSpanish ? 'Capital' : 'Principal';
  String get originalCapital =>
      isSpanish ? 'Capital Original' : 'Original Principal';
  String get capitalRecovered =>
      isSpanish ? 'Capital Recuperado' : 'Principal Recovered';
  String get currentBalance => isSpanish ? 'Saldo Actual' : 'Current Balance';
  String get capitalBalance =>
      isSpanish ? 'Saldo Capital' : 'Principal Balance';
  String get interestRate => isSpanish ? 'Tasa de Interés' : 'Interest Rate';
  String get monthlyRate => isSpanish ? 'Tasa Mensual' : 'Monthly Rate';
  String get otherRate => isSpanish ? 'Otra Tasa' : 'Other Rate';
  String get rate => isSpanish ? 'Tasa' : 'Rate';
  String get disbursement => isSpanish ? 'Desembolso' : 'Disbursement';
  String get disbursementDate =>
      isSpanish ? 'Fecha de Desembolso' : 'Disbursement Date';
  String get loanNumber => isSpanish ? 'Préstamo #' : 'Loan #';
  String get pendingBalance =>
      isSpanish ? 'Saldo Pendiente' : 'Outstanding Balance';
  String get closeLoan => isSpanish ? 'Cerrar Préstamo' : 'Close Loan';
  String get deleteLoan => isSpanish ? 'Eliminar Préstamo' : 'Delete Loan';
  String get selectLoan =>
      isSpanish ? 'Seleccione un préstamo' : 'Select a loan';
  String get to => isSpanish ? 'a' : 'to';
  String get totalEarningsInterestLateFees => isSpanish
      ? 'Total Ganancias (Interés + Mora)'
      : 'Total Earnings (Interest + Late Fees)';

  // ===== PAYMENT =====
  String get payment => isSpanish ? 'Pago' : 'Payment';
  String get payments => isSpanish ? 'Pagos' : 'Payments';
  String get newPayment => isSpanish ? 'Nuevo Pago' : 'New Payment';
  String get registerPayment =>
      isSpanish ? 'Registrar Pago' : 'Register Payment';
  String get paymentAmount => isSpanish ? 'Monto del Pago' : 'Payment Amount';
  String get paymentDate => isSpanish ? 'Fecha de Pago' : 'Payment Date';
  String get paymentType => isSpanish ? 'Tipo de Pago' : 'Payment Type';
  String get typeInterest => isSpanish ? 'Solo Interés' : 'Interest Only';
  String get typePrincipal => isSpanish ? 'Solo Capital' : 'Principal Only';

  String get typeCancel => isSpanish ? 'Cancelar' : 'Payoff';
  String get collectedToday =>
      isSpanish ? 'Total Cobrado Hoy' : 'Total Collected Today';
  String get paymentsToday => isSpanish ? 'Pagos de Hoy' : 'Today\'s Payments';
  String get paymentHistory =>
      isSpanish ? 'Historial de Pagos' : 'Payment History';
  String get viewAllPayments =>
      isSpanish ? 'Ver todos los pagos' : 'View all payments';
  String get receiptNumber => isSpanish ? 'Comprobante #' : 'Receipt #';
  String get application => isSpanish ? 'Aplicación:' : 'Application:';
  String get noDetailedAllocation =>
      isSpanish ? 'Sin asignación detallada' : 'No detailed allocation';
  String get interest => isSpanish ? 'Interés' : 'Interest';
  String get mora => isSpanish ? 'Mora' : 'Late Fee';

  // ===== BILLING CYCLE =====
  String get cycle => isSpanish ? 'Ciclo' : 'Cycle';
  String get cycles => isSpanish ? 'Ciclos' : 'Cycles';
  String get billingCycles => isSpanish ? 'Ciclos de Cobro' : 'Billing Cycles';
  String get pendingCycles =>
      isSpanish ? 'Ciclos Pendientes' : 'Pending Cycles';
  String get overdueCycles => isSpanish ? 'Ciclos Vencidos' : 'Overdue Cycles';
  String get currentCycle => isSpanish ? 'Ciclo Actual' : 'Current Cycle';
  String get pendingInterest =>
      isSpanish ? 'Interés Pendiente' : 'Pending Interest';
  String get expected => isSpanish ? 'Esperado' : 'Expected';
  String get pending => isSpanish ? 'Pendiente' : 'Pending';
  String get dueDate => isSpanish ? 'Vence:' : 'Due:';
  String get noBillingCycles =>
      isSpanish ? 'No hay ciclos de cobro' : 'No billing cycles';
  String get noPayments => isSpanish ? 'No hay pagos' : 'No payments';

  // ===== REPORTS =====
  String get reports => isSpanish ? 'Reportes' : 'Reports';
  String get realizedEarnings =>
      isSpanish ? 'Ganancias Reales' : 'Realized Earnings';
  String get projectedEarnings => isSpanish ? 'Proyección' : 'Projected';
  String get totalEarnings =>
      isSpanish ? 'Ganancias Totales' : 'Total Earnings';
  String get dateRange => isSpanish ? 'Rango de Fechas' : 'Date Range';
  String get startDate => isSpanish ? 'Fecha Inicio' : 'Start Date';
  String get endDate => isSpanish ? 'Fecha Fin' : 'End Date';

  // ===== SETTINGS =====
  String get settings => isSpanish ? 'Configuración' : 'Settings';
  String get appearance => isSpanish ? 'Apariencia' : 'Appearance';
  String get themeMode => isSpanish ? 'Modo de Tema' : 'Theme Mode';
  String get themeLight => isSpanish ? 'Claro' : 'Light';
  String get themeDark => isSpanish ? 'Oscuro' : 'Dark';
  String get themeSystem => isSpanish ? 'Sistema' : 'System';
  String get language => isSpanish ? 'Idioma' : 'Language';
  String get businessCapital =>
      isSpanish ? 'Capital del Negocio' : 'Business Capital';
  String get businessPolicies =>
      isSpanish ? 'Políticas del Negocio' : 'Business Policies';
  String get maintenance => isSpanish ? 'Mantenimiento' : 'Maintenance';
  String get about => isSpanish ? 'Acerca de' : 'About';

  // ===== BACKUP =====
  String get backup => isSpanish ? 'Respaldo' : 'Backup';
  String get backups => isSpanish ? 'Respaldos' : 'Backups';
  String get localBackups => isSpanish ? 'Respaldos Locales' : 'Local Backups';
  String get createBackup => isSpanish ? 'Crear Respaldo' : 'Create Backup';
  String get restoreBackup =>
      isSpanish ? 'Restaurar Respaldo' : 'Restore Backup';
  String get shareBackup => isSpanish ? 'Compartir Respaldo' : 'Share Backup';
  String get exportBackup => isSpanish ? 'Exportar Backup' : 'Export Backup';
  String get creatingBackup =>
      isSpanish ? 'Creando respaldo...' : 'Creating backup...';
  String get backupCreated => isSpanish
      ? 'Respaldo creado exitosamente'
      : 'Backup created successfully';
  String get backupRestored => isSpanish
      ? 'Respaldo restaurado. Por favor reinicie la app.'
      : 'Backup restored. Please restart the app.';
  String get noBackups =>
      isSpanish ? 'No hay respaldos disponibles' : 'No backups available';

  // Backup Export Dialog
  String get backupFileName => isSpanish ? 'Nombre del archivo:' : 'Filename:';
  String get backupDestFolder =>
      isSpanish ? 'Carpeta destino:' : 'Destination folder:';
  String get backupWhatToDo =>
      isSpanish ? '¿Qué desea hacer?' : 'What would you like to do?';
  String get backupSaveAs => isSpanish ? 'Guardar Como...' : 'Save As...';
  String get backupProcessing =>
      isSpanish ? 'Procesando respaldo...' : 'Processing backup...';
  String get backupSaveDialogTitle =>
      isSpanish ? 'Guardar respaldo como...' : 'Save backup as...';
  String get backupSaved => isSpanish ? 'Respaldo guardado:' : 'Backup saved:';
  String get backupError =>
      isSpanish ? 'Error al crear respaldo' : 'Error creating backup';
  String get backupFolderNotExist => isSpanish
      ? 'La carpeta seleccionada no existe'
      : 'Selected folder does not exist';
  String get backupNoFolderConfigured =>
      isSpanish ? 'No hay carpeta configurada' : 'No folder configured';

  // File Replace Dialog
  String get fileExistsTitle => isSpanish ? 'Archivo Existente' : 'File Exists';
  String fileExistsMsg(String fileName) => isSpanish
      ? 'Ya existe un archivo llamado "$fileName" en esta ubicación.\n\n¿Desea reemplazarlo con el nuevo respaldo?'
      : 'A file named "$fileName" already exists in this location.\n\nDo you want to replace it with the new backup?';
  String get replace => isSpanish ? 'Reemplazar' : 'Replace';
  String get backupFolder =>
      isSpanish ? 'Carpeta de Respaldo' : 'Backup Folder';
  String get viewBackups => isSpanish ? 'Ver Respaldos' : 'View Backups';
  String get createNewBackup =>
      isSpanish ? 'Crear Nuevo Respaldo' : 'Create New Backup';
  String get backupFileExistsRename => isSpanish
      ? 'Ya existe un archivo con este nombre. Por favor, cambie el nombre.'
      : 'A file with this name already exists. Please change the name.';
  String get restoreSuccessRestart => isSpanish
      ? 'Respaldo restaurado exitosamente.\n\nLa aplicación se cerrará para aplicar los cambios. Por favor, vuelva a abrirla.'
      : 'Backup restored successfully.\n\nThe app will close to apply changes. Please reopen it.';

  // ===== STATUS =====
  String get statusActive => isSpanish ? 'Activo' : 'Active';
  String get statusClosed => isSpanish ? 'Cerrado' : 'Closed';
  String get statusPending => isSpanish ? 'Pendiente' : 'Pending';
  String get statusOverdue => isSpanish ? 'Vencido' : 'Overdue';
  String get statusPaid => isSpanish ? 'Pagado' : 'Paid';
  String get statusInMora => isSpanish ? 'En Mora' : 'In Default';

  // ===== VALIDATION =====
  String get fieldRequired =>
      isSpanish ? 'Este campo es requerido' : 'This field is required';
  String get invalidAmount => isSpanish ? 'Monto inválido' : 'Invalid amount';
  String get invalidRate => isSpanish ? 'Tasa inválida' : 'Invalid rate';
  String get maxRate100 => isSpanish ? 'Máximo 100%' : 'Maximum 100%';

  // ===== CONFIRMATION =====
  String get confirmDeleteTitle => isSpanish ? '¿Eliminar?' : 'Delete?';
  String get confirmRestoreTitle =>
      isSpanish ? 'Restaurar Respaldo' : 'Restore Backup';
  String get confirmPaymentTitle =>
      isSpanish ? 'Confirmar Pago' : 'Confirm Payment';
  String get cannotDelete =>
      isSpanish ? 'No se puede eliminar' : 'Cannot delete';
  String get loanHasPayments => isSpanish
      ? 'Este préstamo tiene pagos registrados y no puede ser eliminado.\n\nSi desea eliminarlo, primero debe anular todos los pagos asociados.'
      : 'This loan has registered payments and cannot be deleted.\n\nTo delete it, you must first void all associated payments.';

  // ===== MESSAGES =====
  String get savedSuccessfully =>
      isSpanish ? 'Guardado exitosamente' : 'Saved successfully';
  String get deletedSuccessfully =>
      isSpanish ? 'Eliminado exitosamente' : 'Deleted successfully';
  String get updatedSuccessfully =>
      isSpanish ? 'Actualizado exitosamente' : 'Updated successfully';
  String get errorOccurred =>
      isSpanish ? 'Ocurrió un error' : 'An error occurred';

  // ===== DASHBOARD =====
  String get quickActions => isSpanish ? 'Acciones Rápidas' : 'Quick Actions';
  String get collectionRoute =>
      isSpanish ? 'Ruta de Cobro' : 'Collection Route';
  String get viewCollectionCustomers => isSpanish
      ? 'Ver clientes a cobrar hoy'
      : 'View customers to collect today';
  String get viewCustomers => isSpanish ? 'Ver Clientes' : 'View Customers';
  String get allCustomersList =>
      isSpanish ? 'Lista de todos los clientes' : 'List of all customers';

  // ===== REPORTS UI =====
  String get generate => isSpanish ? 'Generar' : 'Generate';
  String get share => isSpanish ? 'Compartir' : 'Share';
  String get consolidatedReport =>
      isSpanish ? 'Reporte Consolidado' : 'Consolidated Report';
  String get earningsReport =>
      isSpanish ? 'Reporte de Ganancias' : 'Earnings Report';
  String get paymentBreakdown =>
      isSpanish ? 'Desglose de Pagos' : 'Payment Breakdown';
  String get basedOn => isSpanish ? 'Basado en' : 'Based on';
  String get activeLoansLower =>
      isSpanish ? 'préstamos activos' : 'active loans';
  String get loanDetailByLoan =>
      isSpanish ? 'Detalle por Préstamo' : 'Loan Detail';
  String get returnPerMonth => isSpanish ? 'Retorno/Mes' : 'Return/Month';
  String get and => isSpanish ? 'y' : 'and';
  String get morePayments => isSpanish ? 'pagos más' : 'more payments';

  // ===== SETTINGS =====
  String get companyData => isSpanish ? 'Datos de la Empresa' : 'Company Data';
  String get companySubtitle => isSpanish
      ? 'Nombre, RUC, logo, dirección y contacto'
      : 'Name, TAX ID, logo, address and contact';
  String get availableCapital => isSpanish
      ? 'Capital disponible para prestar'
      : 'Capital available for lending';
  String get availableCapitalDesc => isSpanish
      ? 'Monto máximo que tienes disponible para préstamos'
      : 'Maximum amount available for lending';
  String get validateCapital =>
      isSpanish ? 'Validar capital de trabajo' : 'Validate working capital';
  String get validateCapitalDesc => isSpanish
      ? 'Se validará que el monto del préstamo no exceda el saldo disponible'
      : 'Loan amount will be validated against available limits';
  String get validateCapitalDescDisabled => isSpanish
      ? 'No se validará el saldo disponible al crear préstamos'
      : 'Balance limits will not be validated';
  String get capitalSaved => isSpanish ? 'Capital guardado' : 'Capital saved';
  String get capitalizeInterest => isSpanish
      ? 'Capitalizar interés no pagado'
      : 'Capitalize unpaid interest';
  String get capitalizeInterestDesc => isSpanish
      ? 'Suma interés vencido al capital'
      : 'Add overdue interest to principal';
  String get dailyAccrual => isSpanish
      ? 'Calcular interés diario (Pago Final)'
      : 'Calculate daily interest (Final Payment)';
  String get dailyAccrualDesc => isSpanish
      ? 'Cobra intereses por días en cancelación'
      : 'Charge interest for days until payoff';
  String get allowMultipleLoans =>
      isSpanish ? 'Permitir múltiples préstamos' : 'Allow multiple loans';
  String get allowMultipleLoansDesc => isSpanish
      ? 'Un cliente puede tener varios préstamos activos'
      : 'A customer can have multiple active loans';
  String get allowMultipleLoansDescDisabled => isSpanish
      ? 'Solo un préstamo activo por cliente'
      : 'Only one active loan per customer';
  String get toleranceDays =>
      isSpanish ? 'Días de tolerancia' : 'Grace period days';
  String get toleranceDaysDesc => isSpanish
      ? 'Días antes de marcar como atrasado'
      : 'Days before marking as overdue';
  String get paymentOrder =>
      isSpanish ? 'Orden de aplicación de pagos' : 'Payment application order';
  String get paymentOrderInterestFirst =>
      isSpanish ? 'Interés primero' : 'Interest first';
  String get paymentOrderCapitalFirst =>
      isSpanish ? 'Capital primero' : 'Principal first';
  String get lastLoanGenerated =>
      isSpanish ? 'Último Préstamo Generado' : 'Last Loan Generated';
  String get nextLoanSequenceDesc => isSpanish
      ? 'El próximo préstamo será el siguiente en la secuencia'
      : 'The next loan will follow this sequence';
  String get lastReceiptGenerated =>
      isSpanish ? 'Último Recibo Generado' : 'Last Receipt Generated';
  String get nextReceiptSequenceDesc => isSpanish
      ? 'El próximo recibo será el siguiente en la secuencia'
      : 'The next receipt will follow this sequence';
  String get sequenceUpdated =>
      isSpanish ? 'Consecutivo actualizado' : 'Sequence updated';
  String get receiptSequenceUpdated => isSpanish
      ? 'Consecutivo de recibos actualizado'
      : 'Receipt sequence updated';

  String get recalculatePortfolio =>
      isSpanish ? 'Recalcular cartera' : 'Recalculate portfolio';
  String get recalculatePortfolioDesc => isSpanish
      ? 'Verificar consistencia de saldos'
      : 'Verify balance consistency';
  String get deleteData => isSpanish ? 'Borrar datos' : 'Delete data';
  String get deleteDataDesc => isSpanish
      ? 'Eliminar registros (Pagos, Préstamos, etc.)'
      : 'Delete records (Payments, Loans, etc.)';

  String get business => isSpanish ? 'Empresa' : 'Business';
  String get sequences => isSpanish ? 'Consecutivos' : 'Sequences';

  String get exportBackupDesc => isSpanish
      ? 'Guardar copia de la base de datos'
      : 'Save a copy of the database';
  String get restoreBackupDesc => isSpanish
      ? 'Cargar base de datos desde archivo'
      : 'Load database from file';

  String get themeModeDesc =>
      isSpanish ? 'Elige cómo se ve la aplicación' : 'Choose how the app looks';
  String get light => isSpanish ? 'Claro' : 'Light';
  String get dark => isSpanish ? 'Oscuro' : 'Dark';
  String get system => isSpanish ? 'Sistema' : 'System';
  String get languageDesc => isSpanish
      ? 'Seleccionar idioma de la aplicación'
      : 'Select application language';

  String get deleteDialogTitle =>
      isSpanish ? 'Borrado de Datos' : 'Delete Data';
  String get deletePayments => isSpanish ? 'Borrar Pagos' : 'Delete Payments';
  String get deletePaymentsDesc => isSpanish
      ? 'Elimina solo el historial de pagos. Mantiene préstamos y clientes.'
      : 'Deletes only payment history. Keeps loans and customers.';
  String get deleteLoans => isSpanish ? 'Borrar Préstamos' : 'Delete Loans';
  String get deleteLoansDesc => isSpanish
      ? 'Elimina préstamos y pagos. Mantiene clientes.'
      : 'Deletes loans and payments. Keeps customers.';
  String get deleteCustomers =>
      isSpanish ? 'Borrar Clientes' : 'Delete Customers';
  String get deleteCustomersDesc => isSpanish
      ? 'Elimina clientes y toda su información asociada.'
      : 'Deletes customers and all associated info.';
  String get deleteAll => isSpanish ? 'Borrar TODO' : 'Delete ALL';
  String get deleteAllDesc => isSpanish
      ? 'Se eliminará TODA la información, incluyendo configuración, consecutivos y preferencias. Esta acción es irreversible.'
      : 'ALL information will be deleted, including settings, sequences and preferences. This action is irreversible.';
  String get restrictedAction =>
      isSpanish ? 'Acción Restringida' : 'Restricted Action';
  String get deleteRestrictedMsg => isSpanish
      ? 'No se pueden eliminar clientes mientras existan préstamos activos.\n\nDebe borrar los préstamos primero o seleccionar "Borrar Todo" si desea limpiar la base de datos completamente.'
      : 'Cannot delete customers while active loans exist.\n\nYou must delete loans first or select "Delete ALL" to clear database completely.';
  String get loanAmountLabel => isSpanish
      ? 'Monto del Préstamo (Capital) *'
      : 'Loan Amount (Principal) *';
  String get monthlyRateLabel => isSpanish
      ? 'Tasa de Interés Mensual (%) *'
      : 'Monthly Interest Rate (%) *';
  String get notes => isSpanish ? 'Notas' : 'Notes';
  String get loanObservations =>
      isSpanish ? 'Observaciones del préstamo...' : 'Loan observations...';
  String get createLoanAction => isSpanish ? 'Crear Préstamo' : 'Create Loan';
  String get errorLoadCustomer =>
      isSpanish ? 'Error al cargar cliente' : 'Error loading customer';

  // Recovery Feature
  String get recoverLoan => isSpanish ? 'Recuperar Préstamo' : 'Recover Loan';
  String get recoverLoanDescPart1 => isSpanish
      ? 'Esta opción cerrará el préstamo pagando solo el capital pendiente (C\$ '
      : 'This option will close the loan by paying only the outstanding principal (C\$ ';
  String get recoverLoanDescPart2 => isSpanish
      ? ').\n\nLos intereses y moras pendientes serán ANULADOS.\n\n¿Está seguro de continuar?'
      : ').\n\nOutstanding interest and late fees will be VOIDED.\n\nAre you sure you want to continue?';
  String get approveRecovery =>
      isSpanish ? 'Aprobar Recuperación' : 'Approve Recovery';
  String get finalizeRecovery =>
      isSpanish ? 'Finalizar Recuperación' : 'Finalize Recovery';
  String get recoveryNotePrompt => isSpanish
      ? 'Ingrese una nota sobre esta recuperación:'
      : 'Enter a note about this recovery:';
  String get recoveryReasonHint => isSpanish
      ? 'Motivo de la recuperación/cierre...'
      : 'Reason for recovery/closure...';
  String get markRestricted => isSpanish
      ? 'Marcar cliente como "NO VOLVER A PRESTAR"'
      : 'Mark customer as "DO NOT LEND AGAIN"';
  String get recoverySuccess => isSpanish
      ? 'Recuperación registrada con éxito'
      : 'Recovery successfully registered';

  // Restricted Customer
  String get restrictedCustomerTitle =>
      isSpanish ? 'Cliente Restringido' : 'Restricted Customer';
  String get restrictedCustomerWarning => isSpanish
      ? 'Advertencia: Este cliente está marcado como "NO PRESTAR".'
      : 'Warning: This customer is marked as "DO NOT LEND".';
  String get reasonLabel => isSpanish ? 'Motivo:' : 'Reason:';
  String get noReasonSpecified =>
      isSpanish ? 'Sin motivo especificado' : 'No reason specified';
  String get continueAnywayPrompt => isSpanish
      ? '¿Desea continuar con el préstamo de todas formas?'
      : 'Do you wish to proceed with the loan anyway?';
  String get cancelReturn =>
      isSpanish ? 'Cancelar (Volver)' : 'Cancel (Return)';
  // ===== DASHBOARD GREETINGS =====
  String get goodMorning => isSpanish ? 'Buenos días' : 'Good morning';
  String get goodAfternoon => isSpanish ? 'Buenas tardes' : 'Good afternoon';
  String get goodEvening => isSpanish ? 'Buenas noches' : 'Good evening';

  // ===== PDF REPORTS & RECEIPTS =====
  String get loanStatement => isSpanish ? 'Estado de Cuenta' : 'Loan Statement';
  String get disbursementReceipt =>
      isSpanish ? 'Comprobante de Desembolso' : 'Disbursement Receipt';
  String get paymentReceipt => isSpanish ? 'Recibo de Pago' : 'Payment Receipt';
  String get thankYouPreference => isSpanish
      ? '¡Gracias por su preferencia!'
      : 'Thank you for your business!';
  String get thankYouPayment =>
      isSpanish ? '¡Gracias por su pago!' : 'Thank you for your payment!';
  String get receivedBy => isSpanish ? 'Recibido por' : 'Received by';
  String get deliveredBy => isSpanish ? 'Entregado por' : 'Delivered by';
  String get distribution => isSpanish ? 'Distribución' : 'Distribution';
  String get remainingBalance =>
      isSpanish ? 'Saldo Restante' : 'Remaining Balance';
  String get dateLabel => isSpanish ? 'Fecha:' : 'Date:'; // explicit with colon
  String get amountGranted => isSpanish ? 'Monto Otorgado:' : 'Amount Granted:';
  String get interestRateLabel =>
      isSpanish ? 'Tasa Interés:' : 'Interest Rate:';
  String get frequencyLabel => isSpanish ? 'Frecuencia:' : 'Frequency:';
  String get maturityDateLabel => isSpanish ? 'Vencimiento:' : 'Maturity Date:';
  String get totalPaidLabel => isSpanish ? 'Total Pagado:' : 'Total Paid:';
  String get interestMoraLabel =>
      isSpanish ? 'Interés/Mora:' : 'Interest/Late Fee:';
  String get capitalLabel => isSpanish ? 'Capital:' : 'Principal:';
  String get loanLabel => isSpanish ? 'Préstamo #:' : 'Loan #:';
  String get clientLabel => isSpanish ? 'Cliente:' : 'Customer:';
  String get dniLabel => isSpanish ? 'Cédula:' : 'ID Card:';

  // Common Frequencies (if not already present elsewhere with different names)
  // ===== LOAN DETAIL / DIALOGS =====
  String get restrictedEditTitle =>
      isSpanish ? 'Edición Restringida' : 'Restricted Edit';
  String get restrictedEditMessage => isSpanish
      ? 'No se puede editar este préstamo porque ya tiene pagos o abonos registrados.\n\nSolo se permite editar préstamos que no han iniciado su amortización (sin pagos).'
      : 'This loan cannot be edited because it already has registered payments.\n\nOnly loans that have not started amortization (no payments) can be edited.';

  String get errorVerifyingPayments =>
      isSpanish ? 'Error al verificar pagos' : 'Error verifying payments';
  String get cannotDeleteTitle =>
      isSpanish ? 'No se puede eliminar' : 'Cannot Delete';
  String get cannotDeleteMessage => isSpanish
      ? 'Este préstamo tiene pagos registrados y no puede ser eliminado.\n\nSi desea eliminarlo, primero debe anular todos los pagos asociados.'
      : 'This loan has registered payments and cannot be deleted.\n\nIf you wish to delete it, you must first void all associated payments.';
  String get deleteLoanTitle => isSpanish ? 'Eliminar Préstamo' : 'Delete Loan';
  String get deleteLoanConfirmation => isSpanish
      ? '¿Está seguro de eliminar este préstamo?\n\nEsta acción eliminará también todos los ciclos de facturación asociados.\n\nEsta acción no se puede deshacer.'
      : 'Are you sure you want to delete this loan?\n\nThis action will also delete all associated billing cycles.\n\nThis action cannot be undone.';

  String get loanDeletedSuccess => isSpanish
      ? 'Préstamo eliminado exitosamente'
      : 'Loan deleted successfully';
  String get errorDeletingLoan =>
      isSpanish ? 'Error al eliminar el préstamo' : 'Error deleting loan';
  String get errorProcessingRequest =>
      isSpanish ? 'Error al procesar solicitud' : 'Error processing request';
  String get generatingStatement =>
      isSpanish ? 'Generando estado de cuenta...' : 'Generating statement...';
  String get loanNotLoaded =>
      isSpanish ? 'Préstamo no cargado' : 'Loan not loaded';
  String get customerNotFound =>
      isSpanish ? 'Cliente no encontrado' : 'Customer not found';
  String get generatingReceipt =>
      isSpanish ? 'Generando recibo...' : 'Generating receipt...';
  String get errorGeneratingReceipt =>
      isSpanish ? 'Error al generar recibo' : 'Error generating receipt';
  String get generatingDisbursement => isSpanish
      ? 'Generando comprobante de desembolso...'
      : 'Generating disbursement receipt...';
  String get errorGeneratingDisbursement =>
      isSpanish ? 'Error al generar comprobante' : 'Error generating receipt';
  String get disbursementReceiptTooltip =>
      isSpanish ? 'Comprobante Desembolso' : 'Disbursement Receipt';
  String get editTooltip => isSpanish ? 'Editar' : 'Edit';
  String get deleteTooltip => isSpanish ? 'Eliminar' : 'Delete';
  String get otherFreq => isSpanish ? 'Otro' : 'Other';

  String get freqDaily => isSpanish ? 'Diario' : 'Daily';
  String get freqWeekly => isSpanish ? 'Semanal' : 'Weekly';
  String get freqBiweekly => isSpanish ? 'Quincenal' : 'Biweekly';
  // ===== COBRAR (COLLECTION) =====
  String get collectionTitle => isSpanish ? 'A Cobrar' : 'To Collect';
  String get tabBiweekly => isSpanish ? 'Quincena' : 'Biweekly';
  String get tabMonthly => isSpanish ? 'Mes' : 'Month';
  String get tabOverdue => isSpanish ? 'Atrasados' : 'Overdue';

  // ===== CUSTOMER DETAIL =====
  String get accountSummary =>
      isSpanish ? 'Resumen de Cuenta' : 'Account Summary';
  String get totalCapital => isSpanish ? 'Capital Total' : 'Total Principal';
  String get monthlyInterest =>
      isSpanish ? 'Interés Mensual' : 'Monthly Interest';
  String get closedLoansTitle =>
      isSpanish ? 'Préstamos cerrados' : 'Closed loans';
  String get activeLoansTitle =>
      isSpanish ? 'Préstamos activos' : 'Active loans';
  String get noLoans => isSpanish ? 'Sin préstamos' : 'No loans';
  String get noLoansDesc => isSpanish
      ? 'Este cliente no tiene préstamos registrados'
      : 'This customer has no registered loans';
  String get actionDenied => isSpanish ? 'Acción denegada' : 'Action denied';
  String get cannotDeleteWithPayments => isSpanish
      ? 'No se puede eliminar un préstamo con pagos registrados.'
      : 'Cannot delete a loan with registered payments.';
  String get registeredDate => isSpanish ? 'Registrado:' : 'Registered:';
  String get deactivateCustomer =>
      isSpanish ? 'Desactivar cliente' : 'Deactivate customer';
  String get viewFullHistory =>
      isSpanish ? 'Ver historial completo' : 'View full history';
  String get confirmDelete =>
      isSpanish ? 'Confirmar eliminación' : 'Confirm deletion';
  String get deleteLoanConfirmationMsg => isSpanish
      ? '¿Está seguro de que desea eliminar este préstamo?\nEsta acción no se puede deshacer.'
      : 'Are you sure you want to delete this loan?\nThis action cannot be undone.';
  String get loanDeleted => isSpanish
      ? 'Préstamo eliminado correctamente'
      : 'Loan deleted successfully';
  String get errorDeleting =>
      isSpanish ? 'Error al eliminar:' : 'Error deleting:';

  // ===== PAYMENT FORM =====
  String get selectCustomer =>
      isSpanish ? 'Seleccionar Cliente' : 'Select Customer';
  String get createCustomer => isSpanish ? 'Crear Cliente' : 'Create Customer';
  String get paymentAmountLabel =>
      isSpanish ? 'Monto del Pago *' : 'Payment Amount *';
  String get invalidAmountMsg =>
      isSpanish ? 'Ingrese un monto válido' : 'Enter a valid amount';

  // ===== COMPANY SETTINGS =====
  String get identity => isSpanish ? 'Identidad' : 'Identity';
  String get contact => isSpanish ? 'Contacto' : 'Contact';
  String get location => isSpanish ? 'Ubicación' : 'Location';
  String get branding => isSpanish ? 'Branding' : 'Branding';
  String get companyName => isSpanish ? 'Nombre de la Empresa' : 'Company Name';
  String get rucId =>
      isSpanish ? 'RUC / Identificación' : 'TAX ID / Identification';
  String get phoneFixed => isSpanish ? 'Teléfono Fijo' : 'Landline';
  String get cellPhone => isSpanish ? 'Celular' : 'Mobile';
  String get whatsapp => isSpanish ? 'WhatsApp' : 'WhatsApp';
  String get address => isSpanish ? 'Dirección' : 'Address';
  String get logoPath => isSpanish ? 'Ruta del Logo (PNG)' : 'Logo Path (PNG)';
  String get selectFile =>
      isSpanish ? 'Seleccione archivo...' : 'Select file...';
  String get visible => isSpanish ? 'Visible' : 'Visible';
  String get hidden => isSpanish ? 'Oculto' : 'Hidden';
  String get companyInfoHelp => isSpanish
      ? 'Activa el interruptor para mostrar el dato en los recibos y reportes.'
      : 'Toggle the switch to show this data on receipts and reports.';
  String get saveChanges => isSpanish ? 'Guardar Cambios' : 'Save Changes';
  String get onlyPng => isSpanish
      ? 'Solo se permiten imágenes PNG'
      : 'Only PNG images are allowed';
  String get errorPickingImage =>
      isSpanish ? 'Error al seleccionar imagen:' : 'Error picking image:';

  String get searchCollectionHint => isSpanish
      ? 'Buscar por nombre o monto...'
      : 'Search by name or amount...';

  // ===== PAYMENT FORM EXTENDED =====
  String get noActiveLoans => isSpanish
      ? 'Este cliente no tiene préstamos activos'
      : 'This customer has no active loans';
  String get createLoan => isSpanish ? 'Crear Préstamo' : 'Create Loan';
  String get originalAmount => isSpanish ? 'Original' : 'Original';
  // monthly already exists
  // selectLoan already exists
  String get selectedLoan =>
      isSpanish ? 'Préstamo Seleccionado' : 'Selected Loan';
  // capital already exists
  // pendingInterest already exists
  // pendingCycles already exists
  // expires - use dueDate (Vence:) or define if strictly needed without colon.
  // Let's use dueDate in UI and remove colon there.

  // paymentType already exists
  String get paymentTypeMixed => isSpanish ? 'Mixto' : 'Mixed';
  // paymentTypeInterestOnly -> use typeInterest
  // paymentTypeCapitalOnly -> use typePrincipal
  // paymentTypeCancel -> use typeCancel
  String get paymentTypeRecovery => isSpanish ? 'Recuperar' : 'Recovery';
  // paymentDate already exists
  String get paymentApplication =>
      isSpanish ? 'Aplicación del Pago' : 'Payment Application';
  String get toOverdueInterest =>
      isSpanish ? 'A interés vencido' : 'To Overdue Interest';
  String get toCurrentInterest =>
      isSpanish ? 'A interés actual' : 'To Current Interest';
  String get toPrincipal => isSpanish ? 'A capital' : 'To Principal';
  String get totalApplied => isSpanish ? 'Total aplicado' : 'Total Applied';

  String get projectedMonthlyEarnings => isSpanish
      ? 'Ganancias Mensuales Proyectadas'
      : 'Projected Monthly Earnings';

  String get paymentsInRange =>
      isSpanish ? 'pagos en el rango' : 'payments in range';
  String get noResultsFor => isSpanish ? 'para' : 'for';
  String get noCollectionBiweeklyTitle => isSpanish
      ? 'No hay cobros pendientes esta quincena'
      : 'No pending collections this fortnight';
  String get noCollectionBiweeklyMsg => isSpanish
      ? 'Los clientes quincenales aparecerán aquí cuando tengan pagos pendientes'
      : 'Biweekly customers will appear here when they have pending payments';
  String get noCollectionMonthlyTitle => isSpanish
      ? 'No hay cobros pendientes este mes'
      : 'No pending collections this month';
  String get noCollectionMonthlyMsg => isSpanish
      ? 'Los clientes con pagos pendientes aparecerán aquí'
      : 'Customers with pending payments will appear here';
  String get noCollectionOverdueTitle =>
      isSpanish ? '¡Sin clientes atrasados!' : 'No overdue customers!';
  String get noCollectionOverdueMsg => isSpanish
      ? 'Todos tus clientes están al día'
      : 'All your customers are up to date';
  String get noData => isSpanish ? 'Sin datos' : 'No data';
  String get interestExpected =>
      isSpanish ? 'Interés esperado' : 'Expected Interest';
  String get capitalPending =>
      isSpanish ? 'Capital Pendiente' : 'Pending Principal';
  String get daysOverdue => isSpanish ? 'días de atraso' : 'days overdue';
  String get activeLoansCount =>
      isSpanish ? 'préstamos activos' : 'active loans';
  String get lastPayment => isSpanish ? 'Último pago' : 'Last payment';

  // ===== PAYMENT HISTORY =====
  String get historyTitle =>
      isSpanish ? 'Historial de Pagos' : 'Payment History';
  String get noPaymentsTitle =>
      isSpanish ? 'Sin pagos registrados' : 'No payments registered';
  String get noPaymentsMsg => isSpanish
      ? 'Los pagos registrados aparecerán aquí'
      : 'Registered payments will appear here';

  // ===== DATE FORMATTING =====
  String get dateToday => isSpanish ? 'Hoy' : 'Today';
  String get dateYesterday => isSpanish ? 'Ayer' : 'Yesterday';
  String get dateDaysAgo => isSpanish ? 'Hace {days} días' : '{days} days ago';

  // ===== DASHBOARD KPI =====
  String get activeCustomersLabel =>
      isSpanish ? 'Clientes Activos' : 'Active Customers';
  String get activeLoansLabel =>
      isSpanish ? 'Préstamos Activos' : 'Active Loans';
  String get overdueLoansLabel =>
      isSpanish ? 'Préstamos Vencidos' : 'Overdue Loans';
  String get earningsMonthLabel =>
      isSpanish ? 'Ganancias (Mes)' : 'Earnings (Mes)';
  String get projectedMonthLabel =>
      isSpanish ? 'Proyección Mes' : 'Projected Month';
  String get capitalPlacedLabel =>
      isSpanish ? 'Capital Colocado' : 'Capital Placed';
  String get ofLabel => isSpanish ? 'de' : 'of'; // for "50% de 1000"
  String get newCustomerLabel => isSpanish ? 'Nuevo Cliente' : 'New Customer';

  String get freqMonthly => isSpanish ? 'Mensual' : 'Monthly';

  String get generated => isSpanish ? 'Generado:' : 'Generated:';

  String get ignoreAndContinue =>
      isSpanish ? 'Ignorar y Continuar' : 'Ignore and Continue';
}

/// Localizations delegate
class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<S> load(Locale locale) async {
    return S(locale);
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}
