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
  String get appName => 'PrestamosApp';
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
