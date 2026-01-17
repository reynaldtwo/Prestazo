import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Prestazo'**
  String get appName;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In es, this message translates to:
  /// **'Advertencia'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get info;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @continue_.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continue_;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get tomorrow;

  /// No description provided for @viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver Todo'**
  String get viewAll;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navCollect.
  ///
  /// In es, this message translates to:
  /// **'A Cobrar'**
  String get navCollect;

  /// No description provided for @navCustomers.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get navCustomers;

  /// No description provided for @navReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @customer.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get customer;

  /// No description provided for @customers.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get customers;

  /// No description provided for @newCustomer.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Cliente'**
  String get newCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In es, this message translates to:
  /// **'Editar Cliente'**
  String get editCustomer;

  /// No description provided for @dniDuplicate.
  ///
  /// In es, this message translates to:
  /// **'DNI Duplicado'**
  String get dniDuplicate;

  /// No description provided for @customerUpdated.
  ///
  /// In es, this message translates to:
  /// **'Cliente actualizado'**
  String get customerUpdated;

  /// No description provided for @customerCreated.
  ///
  /// In es, this message translates to:
  /// **'Cliente creado exitosamente'**
  String get customerCreated;

  /// No description provided for @customerName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get customerName;

  /// No description provided for @customerAlias.
  ///
  /// In es, this message translates to:
  /// **'Alias'**
  String get customerAlias;

  /// No description provided for @customerPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get customerPhone;

  /// No description provided for @customerAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get customerAddress;

  /// No description provided for @billingFrequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia de Cobro'**
  String get billingFrequency;

  /// No description provided for @biweekly.
  ///
  /// In es, this message translates to:
  /// **'Quincenal'**
  String get biweekly;

  /// No description provided for @monthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get weekly;

  /// No description provided for @daily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get daily;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, alias o teléfono...'**
  String get searchHint;

  /// No description provided for @clearFilter.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtro'**
  String get clearFilter;

  /// No description provided for @filterCustomers.
  ///
  /// In es, this message translates to:
  /// **'Filtrar clientes'**
  String get filterCustomers;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @statusInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get statusInactive;

  /// No description provided for @noCustomers.
  ///
  /// In es, this message translates to:
  /// **'No hay clientes'**
  String get noCustomers;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get noResults;

  /// No description provided for @addFirstCustomer.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primer cliente presionando el botón +'**
  String get addFirstCustomer;

  /// No description provided for @tryAnotherTerm.
  ///
  /// In es, this message translates to:
  /// **'Intenta con otro término de búsqueda'**
  String get tryAnotherTerm;

  /// No description provided for @loan.
  ///
  /// In es, this message translates to:
  /// **'Préstamo'**
  String get loan;

  /// No description provided for @loans.
  ///
  /// In es, this message translates to:
  /// **'Préstamos'**
  String get loans;

  /// No description provided for @newLoan.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Préstamo'**
  String get newLoan;

  /// No description provided for @editLoan.
  ///
  /// In es, this message translates to:
  /// **'Editar Préstamo'**
  String get editLoan;

  /// No description provided for @loanDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle del Préstamo'**
  String get loanDetail;

  /// No description provided for @capital.
  ///
  /// In es, this message translates to:
  /// **'Capital'**
  String get capital;

  /// No description provided for @originalCapital.
  ///
  /// In es, this message translates to:
  /// **'Capital Original'**
  String get originalCapital;

  /// No description provided for @capitalRecovered.
  ///
  /// In es, this message translates to:
  /// **'Capital Recuperado'**
  String get capitalRecovered;

  /// No description provided for @currentBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo Actual'**
  String get currentBalance;

  /// No description provided for @capitalBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo Capital'**
  String get capitalBalance;

  /// No description provided for @interestRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Interés'**
  String get interestRate;

  /// No description provided for @monthlyRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Mensual'**
  String get monthlyRate;

  /// No description provided for @otherRate.
  ///
  /// In es, this message translates to:
  /// **'Otra Tasa'**
  String get otherRate;

  /// No description provided for @rate.
  ///
  /// In es, this message translates to:
  /// **'Tasa'**
  String get rate;

  /// No description provided for @disbursement.
  ///
  /// In es, this message translates to:
  /// **'Desembolso'**
  String get disbursement;

  /// No description provided for @disbursementDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Desembolso'**
  String get disbursementDate;

  /// No description provided for @loanNumber.
  ///
  /// In es, this message translates to:
  /// **'Préstamo #'**
  String get loanNumber;

  /// No description provided for @pendingBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo Pendiente'**
  String get pendingBalance;

  /// No description provided for @closeLoan.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Préstamo'**
  String get closeLoan;

  /// No description provided for @deleteLoan.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Préstamo'**
  String get deleteLoan;

  /// No description provided for @selectLoan.
  ///
  /// In es, this message translates to:
  /// **'Seleccione un préstamo'**
  String get selectLoan;

  /// No description provided for @to.
  ///
  /// In es, this message translates to:
  /// **'a'**
  String get to;

  /// No description provided for @totalEarningsInterestLateFees.
  ///
  /// In es, this message translates to:
  /// **'Total Ganancias (Interés + Mora)'**
  String get totalEarningsInterestLateFees;

  /// No description provided for @payment.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get payment;

  /// No description provided for @payments.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get payments;

  /// No description provided for @newPayment.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Pago'**
  String get newPayment;

  /// No description provided for @registerPayment.
  ///
  /// In es, this message translates to:
  /// **'Registrar Pago'**
  String get registerPayment;

  /// No description provided for @paymentAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto del Pago'**
  String get paymentAmount;

  /// No description provided for @paymentDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Pago'**
  String get paymentDate;

  /// No description provided for @paymentType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Pago'**
  String get paymentType;

  /// No description provided for @typeInterest.
  ///
  /// In es, this message translates to:
  /// **'Solo Interés'**
  String get typeInterest;

  /// No description provided for @typePrincipal.
  ///
  /// In es, this message translates to:
  /// **'Solo Capital'**
  String get typePrincipal;

  /// No description provided for @typeCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get typeCancel;

  /// No description provided for @planInstallmentMode.
  ///
  /// In es, this message translates to:
  /// **'Cuota del Plan'**
  String get planInstallmentMode;

  /// No description provided for @collectedToday.
  ///
  /// In es, this message translates to:
  /// **'Total Cobrado Hoy'**
  String get collectedToday;

  /// No description provided for @paymentsToday.
  ///
  /// In es, this message translates to:
  /// **'Pagos de Hoy'**
  String get paymentsToday;

  /// No description provided for @paymentHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de Pagos'**
  String get paymentHistory;

  /// No description provided for @viewAllPayments.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los pagos'**
  String get viewAllPayments;

  /// No description provided for @receiptNumber.
  ///
  /// In es, this message translates to:
  /// **'Comprobante #'**
  String get receiptNumber;

  /// No description provided for @application.
  ///
  /// In es, this message translates to:
  /// **'Aplicación:'**
  String get application;

  /// No description provided for @noDetailedAllocation.
  ///
  /// In es, this message translates to:
  /// **'Sin asignación detallada'**
  String get noDetailedAllocation;

  /// No description provided for @interest.
  ///
  /// In es, this message translates to:
  /// **'Interés'**
  String get interest;

  /// No description provided for @mora.
  ///
  /// In es, this message translates to:
  /// **'Mora'**
  String get mora;

  /// No description provided for @cycle.
  ///
  /// In es, this message translates to:
  /// **'Ciclo'**
  String get cycle;

  /// No description provided for @cycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos'**
  String get cycles;

  /// No description provided for @billingCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos de Cobro'**
  String get billingCycles;

  /// No description provided for @pendingCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos Pendientes'**
  String get pendingCycles;

  /// No description provided for @overdueCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos Vencidos'**
  String get overdueCycles;

  /// No description provided for @currentCycle.
  ///
  /// In es, this message translates to:
  /// **'Ciclo Actual'**
  String get currentCycle;

  /// No description provided for @pendingInterest.
  ///
  /// In es, this message translates to:
  /// **'Interés Pendiente'**
  String get pendingInterest;

  /// No description provided for @expected.
  ///
  /// In es, this message translates to:
  /// **'Esperado'**
  String get expected;

  /// No description provided for @pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pending;

  /// No description provided for @dueDate.
  ///
  /// In es, this message translates to:
  /// **'Vence:'**
  String get dueDate;

  /// No description provided for @noBillingCycles.
  ///
  /// In es, this message translates to:
  /// **'No hay ciclos de cobro'**
  String get noBillingCycles;

  /// No description provided for @noPayments.
  ///
  /// In es, this message translates to:
  /// **'No hay pagos'**
  String get noPayments;

  /// No description provided for @reports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get reports;

  /// No description provided for @realizedEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ganancias Reales'**
  String get realizedEarnings;

  /// No description provided for @projectedEarnings.
  ///
  /// In es, this message translates to:
  /// **'Proyección'**
  String get projectedEarnings;

  /// No description provided for @totalEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ganancias Totales'**
  String get totalEarnings;

  /// No description provided for @dateRange.
  ///
  /// In es, this message translates to:
  /// **'Rango de Fechas'**
  String get dateRange;

  /// No description provided for @startDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha Inicio'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha Fin'**
  String get endDate;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuraciones'**
  String get settings;

  /// No description provided for @monetaryManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión Monetaria'**
  String get monetaryManagement;

  /// No description provided for @monetarySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Monedas, Capital y Tasas de Cambio'**
  String get monetarySubtitle;

  /// No description provided for @baseConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Configuración Base'**
  String get baseConfiguration;

  /// No description provided for @currencyCenter.
  ///
  /// In es, this message translates to:
  /// **'Centro de Divisas'**
  String get currencyCenter;

  /// No description provided for @currencyMaster.
  ///
  /// In es, this message translates to:
  /// **'Maestro de tasas de compra y venta'**
  String get currencyMaster;

  /// No description provided for @snapshotPolicy.
  ///
  /// In es, this message translates to:
  /// **'Registro de Tasa en Contrato'**
  String get snapshotPolicy;

  /// No description provided for @allowManualRate.
  ///
  /// In es, this message translates to:
  /// **'Permitir editar tasa al crear préstamo'**
  String get allowManualRate;

  /// No description provided for @reportConsolidation.
  ///
  /// In es, this message translates to:
  /// **'Consolidación de Reportes'**
  String get reportConsolidation;

  /// No description provided for @presentationCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda de Visualización'**
  String get presentationCurrency;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In es, this message translates to:
  /// **'Modo de Tema'**
  String get themeMode;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @businessCapital.
  ///
  /// In es, this message translates to:
  /// **'Capital del Negocio'**
  String get businessCapital;

  /// No description provided for @businessPolicies.
  ///
  /// In es, this message translates to:
  /// **'Políticas del Negocio'**
  String get businessPolicies;

  /// No description provided for @maintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get maintenance;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;

  /// No description provided for @backup.
  ///
  /// In es, this message translates to:
  /// **'Respaldo'**
  String get backup;

  /// No description provided for @backups.
  ///
  /// In es, this message translates to:
  /// **'Respaldos'**
  String get backups;

  /// No description provided for @localBackups.
  ///
  /// In es, this message translates to:
  /// **'Respaldos Locales'**
  String get localBackups;

  /// No description provided for @createBackup.
  ///
  /// In es, this message translates to:
  /// **'Crear Respaldo'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In es, this message translates to:
  /// **'Restaurar Respaldo'**
  String get restoreBackup;

  /// No description provided for @shareBackup.
  ///
  /// In es, this message translates to:
  /// **'Compartir Respaldo'**
  String get shareBackup;

  /// No description provided for @exportBackup.
  ///
  /// In es, this message translates to:
  /// **'Exportar Backup'**
  String get exportBackup;

  /// No description provided for @creatingBackup.
  ///
  /// In es, this message translates to:
  /// **'Creando respaldo...'**
  String get creatingBackup;

  /// No description provided for @backupCreated.
  ///
  /// In es, this message translates to:
  /// **'Respaldo creado exitosamente'**
  String get backupCreated;

  /// No description provided for @backupRestored.
  ///
  /// In es, this message translates to:
  /// **'Respaldo restaurado. Por favor reinicie la app.'**
  String get backupRestored;

  /// No description provided for @noBackups.
  ///
  /// In es, this message translates to:
  /// **'No hay respaldos disponibles'**
  String get noBackups;

  /// No description provided for @countryOfOperation.
  ///
  /// In es, this message translates to:
  /// **'País de Operación'**
  String get countryOfOperation;

  /// No description provided for @selectCountry.
  ///
  /// In es, this message translates to:
  /// **'Seleccione un país'**
  String get selectCountry;

  /// No description provided for @whatsAppDisbursementMsg.
  ///
  /// In es, this message translates to:
  /// **'¡Hola {name}! 👋\n\nAquí tienes el comprobante de tu préstamo #{loanNumber} por {amount}.\n\n¡Gracias por tu preferencia! 🙏'**
  String whatsAppDisbursementMsg(Object name, Object loanNumber, Object amount);

  /// No description provided for @whatsAppPaymentMsg.
  ///
  /// In es, this message translates to:
  /// **'¡Hola {name}! 👋\n\nAdjunto el recibo de tu pago #{receiptNumber} de {amount}.\n\n¡Gracias por tu pago! 🙏'**
  String whatsAppPaymentMsg(Object name, Object receiptNumber, Object amount);

  /// No description provided for @whatsAppStatementMsg.
  ///
  /// In es, this message translates to:
  /// **'¡Hola {name}! 👋\n\nAdjunto su estado de cuenta del préstamo #{loanNumber}.\n\nPara cualquier consulta, estamos a la orden. 🤝'**
  String whatsAppStatementMsg(Object name, Object loanNumber);

  /// No description provided for @whatsAppBalancePending.
  ///
  /// In es, this message translates to:
  /// **'Tu saldo pendiente es: {amount}'**
  String whatsAppBalancePending(Object amount);

  /// No description provided for @whatsAppLoanCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Felicidades! Has completado tu préstamo. 🎉'**
  String get whatsAppLoanCompleted;

  /// No description provided for @backupFileName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del archivo:'**
  String get backupFileName;

  /// No description provided for @backupDestFolder.
  ///
  /// In es, this message translates to:
  /// **'Carpeta destino:'**
  String get backupDestFolder;

  /// No description provided for @backupWhatToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué desea hacer?'**
  String get backupWhatToDo;

  /// No description provided for @backupSaveAs.
  ///
  /// In es, this message translates to:
  /// **'Guardar Como...'**
  String get backupSaveAs;

  /// No description provided for @backupProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando respaldo...'**
  String get backupProcessing;

  /// No description provided for @backupSaveDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar respaldo como...'**
  String get backupSaveDialogTitle;

  /// No description provided for @backupSaved.
  ///
  /// In es, this message translates to:
  /// **'Respaldo guardado:'**
  String get backupSaved;

  /// No description provided for @backupError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear respaldo'**
  String get backupError;

  /// No description provided for @backupFolderNotExist.
  ///
  /// In es, this message translates to:
  /// **'La carpeta seleccionada no existe'**
  String get backupFolderNotExist;

  /// No description provided for @backupNoFolderConfigured.
  ///
  /// In es, this message translates to:
  /// **'No hay carpeta configurada'**
  String get backupNoFolderConfigured;

  /// No description provided for @fileExistsTitle.
  ///
  /// In es, this message translates to:
  /// **'Archivo Existente'**
  String get fileExistsTitle;

  /// No description provided for @fileExistsMsg.
  ///
  /// In es, this message translates to:
  /// **'Ya existe un archivo llamado \"{fileName}\" en esta ubicación.\n\n¿Desea reemplazarlo con el nuevo respaldo?'**
  String fileExistsMsg(Object fileName);

  /// No description provided for @replace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar'**
  String get replace;

  /// No description provided for @backupFolder.
  ///
  /// In es, this message translates to:
  /// **'Carpeta de Respaldo'**
  String get backupFolder;

  /// No description provided for @viewBackups.
  ///
  /// In es, this message translates to:
  /// **'Ver Respaldos'**
  String get viewBackups;

  /// No description provided for @createNewBackup.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Respaldo'**
  String get createNewBackup;

  /// No description provided for @backupFileExistsRename.
  ///
  /// In es, this message translates to:
  /// **'Ya existe un archivo con este nombre. Por favor, cambie el nombre.'**
  String get backupFileExistsRename;

  /// No description provided for @restoreSuccessRestart.
  ///
  /// In es, this message translates to:
  /// **'Respaldo restaurado exitosamente.\n\nLa aplicación se cerrará para aplicar los cambios. Por favor, vuelva a abrirla.'**
  String get restoreSuccessRestart;

  /// No description provided for @shareReceiptsWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'Enviar comprobantes por WhatsApp'**
  String get shareReceiptsWhatsApp;

  /// No description provided for @shareReceiptsWhatsAppDesc.
  ///
  /// In es, this message translates to:
  /// **'Enviar comprobante de desembolso y recibos de pago al cliente después de cada transacción'**
  String get shareReceiptsWhatsAppDesc;

  /// No description provided for @noValidWhatsAppNumber.
  ///
  /// In es, this message translates to:
  /// **'El cliente no tiene número de WhatsApp válido'**
  String get noValidWhatsAppNumber;

  /// No description provided for @sendingToWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'Abriendo WhatsApp...'**
  String get sendingToWhatsApp;

  /// No description provided for @statusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get statusActive;

  /// No description provided for @statusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get statusClosed;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @statusOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get statusOverdue;

  /// No description provided for @statusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get statusPaid;

  /// No description provided for @statusInMora.
  ///
  /// In es, this message translates to:
  /// **'En Mora'**
  String get statusInMora;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es requerido'**
  String get fieldRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto inválido'**
  String get invalidAmount;

  /// No description provided for @invalidRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa inválida'**
  String get invalidRate;

  /// No description provided for @maxRate100.
  ///
  /// In es, this message translates to:
  /// **'Máximo 100%'**
  String get maxRate100;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar Respaldo'**
  String get confirmRestoreTitle;

  /// No description provided for @confirmPaymentTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Pago'**
  String get confirmPaymentTitle;

  /// No description provided for @cannotDelete.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar'**
  String get cannotDelete;

  /// No description provided for @loanHasPayments.
  ///
  /// In es, this message translates to:
  /// **'Este préstamo tiene pagos registrados y no puede ser eliminado.\n\nSi desea eliminarlo, primero debe anular todos los pagos asociados.'**
  String get loanHasPayments;

  /// No description provided for @savedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Guardado exitosamente'**
  String get savedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Eliminado exitosamente'**
  String get deletedSuccessfully;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Actualizado exitosamente'**
  String get updatedSuccessfully;

  /// No description provided for @errorOccurred.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error'**
  String get errorOccurred;

  /// No description provided for @quickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones Rápidas'**
  String get quickActions;

  /// No description provided for @collectionRoute.
  ///
  /// In es, this message translates to:
  /// **'Ruta de Cobro'**
  String get collectionRoute;

  /// No description provided for @viewCollectionCustomers.
  ///
  /// In es, this message translates to:
  /// **'Ver clientes a cobrar hoy'**
  String get viewCollectionCustomers;

  /// No description provided for @viewCustomers.
  ///
  /// In es, this message translates to:
  /// **'Ver Clientes'**
  String get viewCustomers;

  /// No description provided for @allCustomersList.
  ///
  /// In es, this message translates to:
  /// **'Lista de todos los clientes'**
  String get allCustomersList;

  /// No description provided for @generate.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get generate;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share;

  /// No description provided for @consolidatedReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte Consolidado'**
  String get consolidatedReport;

  /// No description provided for @earningsReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte de Ganancias'**
  String get earningsReport;

  /// No description provided for @paymentBreakdown.
  ///
  /// In es, this message translates to:
  /// **'Desglose de Pagos'**
  String get paymentBreakdown;

  /// No description provided for @basedOn.
  ///
  /// In es, this message translates to:
  /// **'Basado en'**
  String get basedOn;

  /// No description provided for @activeLoansLower.
  ///
  /// In es, this message translates to:
  /// **'préstamos activos'**
  String get activeLoansLower;

  /// No description provided for @loanDetailByLoan.
  ///
  /// In es, this message translates to:
  /// **'Detalle por Préstamo'**
  String get loanDetailByLoan;

  /// No description provided for @returnPerMonth.
  ///
  /// In es, this message translates to:
  /// **'Retorno/Mes'**
  String get returnPerMonth;

  /// No description provided for @and.
  ///
  /// In es, this message translates to:
  /// **'y'**
  String get and;

  /// No description provided for @morePayments.
  ///
  /// In es, this message translates to:
  /// **'pagos más'**
  String get morePayments;

  /// No description provided for @companyData.
  ///
  /// In es, this message translates to:
  /// **'Datos de la Empresa'**
  String get companyData;

  /// No description provided for @companySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre, RUC, logo, dirección y contacto'**
  String get companySubtitle;

  /// No description provided for @availableCapital.
  ///
  /// In es, this message translates to:
  /// **'Capital disponible para prestar'**
  String get availableCapital;

  /// No description provided for @availableCapitalDesc.
  ///
  /// In es, this message translates to:
  /// **'Monto máximo que tienes disponible para préstamos'**
  String get availableCapitalDesc;

  /// No description provided for @validateCapital.
  ///
  /// In es, this message translates to:
  /// **'Validar capital de trabajo'**
  String get validateCapital;

  /// No description provided for @validateCapitalDesc.
  ///
  /// In es, this message translates to:
  /// **'Se validará que el monto del préstamo no exceda el saldo disponible'**
  String get validateCapitalDesc;

  /// No description provided for @validateCapitalDescDisabled.
  ///
  /// In es, this message translates to:
  /// **'No se validará el saldo disponible al crear préstamos'**
  String get validateCapitalDescDisabled;

  /// No description provided for @capitalSaved.
  ///
  /// In es, this message translates to:
  /// **'Capital guardado'**
  String get capitalSaved;

  /// No description provided for @capitalizeInterest.
  ///
  /// In es, this message translates to:
  /// **'Capitalizar interés no pagado'**
  String get capitalizeInterest;

  /// No description provided for @capitalizeInterestDesc.
  ///
  /// In es, this message translates to:
  /// **'Suma interés vencido al capital'**
  String get capitalizeInterestDesc;

  /// No description provided for @dailyAccrual.
  ///
  /// In es, this message translates to:
  /// **'Calcular interés diario (Pago Final)'**
  String get dailyAccrual;

  /// No description provided for @dailyAccrualDesc.
  ///
  /// In es, this message translates to:
  /// **'Cobra intereses por días en cancelación'**
  String get dailyAccrualDesc;

  /// No description provided for @allowMultipleLoans.
  ///
  /// In es, this message translates to:
  /// **'Permitir múltiples préstamos'**
  String get allowMultipleLoans;

  /// No description provided for @allowMultipleLoansDesc.
  ///
  /// In es, this message translates to:
  /// **'Un cliente puede tener varios préstamos activos'**
  String get allowMultipleLoansDesc;

  /// No description provided for @allowMultipleLoansDescDisabled.
  ///
  /// In es, this message translates to:
  /// **'Solo un préstamo activo por cliente'**
  String get allowMultipleLoansDescDisabled;

  /// No description provided for @validateUniqueDni.
  ///
  /// In es, this message translates to:
  /// **'Validar DNI Único'**
  String get validateUniqueDni;

  /// No description provided for @validateUniqueDniDesc.
  ///
  /// In es, this message translates to:
  /// **'Se verificará que no existan clientes con el mismo DNI'**
  String get validateUniqueDniDesc;

  /// No description provided for @validateUniqueDniDescDisabled.
  ///
  /// In es, this message translates to:
  /// **'Se permite registrar clientes con DNI duplicado'**
  String get validateUniqueDniDescDisabled;

  /// No description provided for @toleranceDays.
  ///
  /// In es, this message translates to:
  /// **'Días de tolerancia'**
  String get toleranceDays;

  /// No description provided for @toleranceDaysDesc.
  ///
  /// In es, this message translates to:
  /// **'Días antes de marcar como atrasado'**
  String get toleranceDaysDesc;

  /// No description provided for @paymentOrder.
  ///
  /// In es, this message translates to:
  /// **'Orden de aplicación de pagos'**
  String get paymentOrder;

  /// No description provided for @paymentOrderInterestFirst.
  ///
  /// In es, this message translates to:
  /// **'Interés primero'**
  String get paymentOrderInterestFirst;

  /// No description provided for @paymentOrderCapitalFirst.
  ///
  /// In es, this message translates to:
  /// **'Capital primero'**
  String get paymentOrderCapitalFirst;

  /// No description provided for @lastLoanGenerated.
  ///
  /// In es, this message translates to:
  /// **'Último Préstamo Generado'**
  String get lastLoanGenerated;

  /// No description provided for @nextLoanSequenceDesc.
  ///
  /// In es, this message translates to:
  /// **'El próximo préstamo será el siguiente en la secuencia'**
  String get nextLoanSequenceDesc;

  /// No description provided for @lastReceiptGenerated.
  ///
  /// In es, this message translates to:
  /// **'Último Recibo Generado'**
  String get lastReceiptGenerated;

  /// No description provided for @nextReceiptSequenceDesc.
  ///
  /// In es, this message translates to:
  /// **'El próximo recibo será el siguiente en la secuencia'**
  String get nextReceiptSequenceDesc;

  /// No description provided for @sequenceUpdated.
  ///
  /// In es, this message translates to:
  /// **'Consecutivo actualizado'**
  String get sequenceUpdated;

  /// No description provided for @receiptSequenceUpdated.
  ///
  /// In es, this message translates to:
  /// **'Consecutivo de recibos actualizado'**
  String get receiptSequenceUpdated;

  /// No description provided for @recalculatePortfolio.
  ///
  /// In es, this message translates to:
  /// **'Recalcular cartera'**
  String get recalculatePortfolio;

  /// No description provided for @recalculatePortfolioDesc.
  ///
  /// In es, this message translates to:
  /// **'Verificar consistencia de saldos'**
  String get recalculatePortfolioDesc;

  /// No description provided for @deleteData.
  ///
  /// In es, this message translates to:
  /// **'Borrar datos'**
  String get deleteData;

  /// No description provided for @deleteDataDesc.
  ///
  /// In es, this message translates to:
  /// **'Eliminar registros (Pagos, Préstamos, etc.)'**
  String get deleteDataDesc;

  /// No description provided for @business.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get business;

  /// No description provided for @sequences.
  ///
  /// In es, this message translates to:
  /// **'Consecutivos'**
  String get sequences;

  /// No description provided for @exportBackupDesc.
  ///
  /// In es, this message translates to:
  /// **'Guardar copia de la base de datos'**
  String get exportBackupDesc;

  /// No description provided for @restoreBackupDesc.
  ///
  /// In es, this message translates to:
  /// **'Cargar base de datos desde archivo'**
  String get restoreBackupDesc;

  /// No description provided for @themeModeDesc.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo se ve la aplicación'**
  String get themeModeDesc;

  /// No description provided for @light.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get system;

  /// No description provided for @languageDesc.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar idioma de la aplicación'**
  String get languageDesc;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrado de Datos'**
  String get deleteDialogTitle;

  /// No description provided for @deletePayments.
  ///
  /// In es, this message translates to:
  /// **'Borrar Pagos'**
  String get deletePayments;

  /// No description provided for @deletePaymentsDesc.
  ///
  /// In es, this message translates to:
  /// **'Elimina solo el historial de pagos. Mantiene préstamos y clientes.'**
  String get deletePaymentsDesc;

  /// No description provided for @deleteLoans.
  ///
  /// In es, this message translates to:
  /// **'Borrar Préstamos'**
  String get deleteLoans;

  /// No description provided for @deleteLoansDesc.
  ///
  /// In es, this message translates to:
  /// **'Elimina préstamos y pagos. Mantiene clientes.'**
  String get deleteLoansDesc;

  /// No description provided for @deleteCustomers.
  ///
  /// In es, this message translates to:
  /// **'Borrar Clientes'**
  String get deleteCustomers;

  /// No description provided for @deleteCustomersDesc.
  ///
  /// In es, this message translates to:
  /// **'Elimina clientes y toda su información asociada.'**
  String get deleteCustomersDesc;

  /// No description provided for @deleteAll.
  ///
  /// In es, this message translates to:
  /// **'Borrar TODO'**
  String get deleteAll;

  /// No description provided for @deleteAllDesc.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará TODA la información, incluyendo configuración, consecutivos y preferencias. Esta acción es irreversible.'**
  String get deleteAllDesc;

  /// No description provided for @restrictedAction.
  ///
  /// In es, this message translates to:
  /// **'Acción Restringida'**
  String get restrictedAction;

  /// No description provided for @deleteRestrictedMsg.
  ///
  /// In es, this message translates to:
  /// **'No se pueden eliminar clientes mientras existan préstamos activos.\n\nDebe borrar los préstamos primero o seleccionar \"Borrar Todo\" si desea limpiar la base de datos completamente.'**
  String get deleteRestrictedMsg;

  /// No description provided for @loanAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto del Préstamo (Capital) *'**
  String get loanAmountLabel;

  /// No description provided for @monthlyRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Interés Mensual (%) *'**
  String get monthlyRateLabel;

  /// No description provided for @notes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notes;

  /// No description provided for @loanObservations.
  ///
  /// In es, this message translates to:
  /// **'Observaciones del préstamo...'**
  String get loanObservations;

  /// No description provided for @createLoanAction.
  ///
  /// In es, this message translates to:
  /// **'Crear Préstamo'**
  String get createLoanAction;

  /// No description provided for @errorLoadCustomer.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar cliente'**
  String get errorLoadCustomer;

  /// No description provided for @recoverLoan.
  ///
  /// In es, this message translates to:
  /// **'Recuperar Préstamo'**
  String get recoverLoan;

  /// No description provided for @recoverLoanDescPart1.
  ///
  /// In es, this message translates to:
  /// **'Esta opción cerrará el préstamo pagando solo el capital pendiente (C\$ '**
  String get recoverLoanDescPart1;

  /// No description provided for @recoverLoanDescPart2.
  ///
  /// In es, this message translates to:
  /// **').\n\nLos intereses y moras pendientes serán ANULADOS.\n\n¿Está seguro de continuar?'**
  String get recoverLoanDescPart2;

  /// No description provided for @approveRecovery.
  ///
  /// In es, this message translates to:
  /// **'Aprobar Recuperación'**
  String get approveRecovery;

  /// No description provided for @finalizeRecovery.
  ///
  /// In es, this message translates to:
  /// **'Finalizar Recuperación'**
  String get finalizeRecovery;

  /// No description provided for @recoveryNotePrompt.
  ///
  /// In es, this message translates to:
  /// **'Ingrese una nota sobre esta recuperación:'**
  String get recoveryNotePrompt;

  /// No description provided for @recoveryReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Motivo de la recuperación/cierre...'**
  String get recoveryReasonHint;

  /// No description provided for @markRestricted.
  ///
  /// In es, this message translates to:
  /// **'Marcar cliente como \"NO VOLVER A PRESTAR\"'**
  String get markRestricted;

  /// No description provided for @recoverySuccess.
  ///
  /// In es, this message translates to:
  /// **'Recuperación registrada con éxito'**
  String get recoverySuccess;

  /// No description provided for @restrictedCustomerTitle.
  ///
  /// In es, this message translates to:
  /// **'Cliente Restringido'**
  String get restrictedCustomerTitle;

  /// No description provided for @restrictedCustomerWarning.
  ///
  /// In es, this message translates to:
  /// **'Advertencia: Este cliente está marcado como \"NO PRESTAR\".'**
  String get restrictedCustomerWarning;

  /// No description provided for @reasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo:'**
  String get reasonLabel;

  /// No description provided for @noReasonSpecified.
  ///
  /// In es, this message translates to:
  /// **'Sin motivo especificado'**
  String get noReasonSpecified;

  /// No description provided for @continueAnywayPrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Desea continuar con el préstamo de todas formas?'**
  String get continueAnywayPrompt;

  /// No description provided for @cancelReturn.
  ///
  /// In es, this message translates to:
  /// **'Cancelar (Volver)'**
  String get cancelReturn;

  /// No description provided for @goodMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get goodEvening;

  /// No description provided for @loanStatement.
  ///
  /// In es, this message translates to:
  /// **'Estado de Cuenta'**
  String get loanStatement;

  /// No description provided for @disbursementReceipt.
  ///
  /// In es, this message translates to:
  /// **'Comprobante de Desembolso'**
  String get disbursementReceipt;

  /// No description provided for @paymentReceipt.
  ///
  /// In es, this message translates to:
  /// **'Recibo de Pago'**
  String get paymentReceipt;

  /// No description provided for @thankYouPreference.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por su preferencia!'**
  String get thankYouPreference;

  /// No description provided for @thankYouPayment.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por su pago!'**
  String get thankYouPayment;

  /// No description provided for @receivedBy.
  ///
  /// In es, this message translates to:
  /// **'Recibido por'**
  String get receivedBy;

  /// No description provided for @deliveredBy.
  ///
  /// In es, this message translates to:
  /// **'Entregado por'**
  String get deliveredBy;

  /// No description provided for @distribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución'**
  String get distribution;

  /// No description provided for @remainingBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo Restante'**
  String get remainingBalance;

  /// No description provided for @dateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha:'**
  String get dateLabel;

  /// No description provided for @amountGranted.
  ///
  /// In es, this message translates to:
  /// **'Monto Otorgado:'**
  String get amountGranted;

  /// No description provided for @reportSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de Reportes'**
  String get reportSettings;

  /// No description provided for @showDisbursementSignatures.
  ///
  /// In es, this message translates to:
  /// **'Firmas en entrega'**
  String get showDisbursementSignatures;

  /// No description provided for @showPaymentSignatures.
  ///
  /// In es, this message translates to:
  /// **'Firmas en recibo'**
  String get showPaymentSignatures;

  /// No description provided for @disbursementLegend.
  ///
  /// In es, this message translates to:
  /// **'Leyenda en entrega'**
  String get disbursementLegend;

  /// No description provided for @paymentLegend.
  ///
  /// In es, this message translates to:
  /// **'Leyenda en recibo'**
  String get paymentLegend;

  /// No description provided for @legendHint.
  ///
  /// In es, this message translates to:
  /// **'Ingrese un texto opcional...'**
  String get legendHint;

  /// No description provided for @showLegend.
  ///
  /// In es, this message translates to:
  /// **'Mostrar leyenda'**
  String get showLegend;

  /// No description provided for @labelRuc.
  ///
  /// In es, this message translates to:
  /// **'RUC:'**
  String get labelRuc;

  /// No description provided for @labelDir.
  ///
  /// In es, this message translates to:
  /// **'Dir:'**
  String get labelDir;

  /// No description provided for @labelTel.
  ///
  /// In es, this message translates to:
  /// **'Tel:'**
  String get labelTel;

  /// No description provided for @labelCel.
  ///
  /// In es, this message translates to:
  /// **'Cel:'**
  String get labelCel;

  /// No description provided for @labelWa.
  ///
  /// In es, this message translates to:
  /// **'WA:'**
  String get labelWa;

  /// No description provided for @interestRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Tasa Interés:'**
  String get interestRateLabel;

  /// No description provided for @frequencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia:'**
  String get frequencyLabel;

  /// No description provided for @maturityDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Vencimiento:'**
  String get maturityDateLabel;

  /// No description provided for @totalPaidLabel.
  ///
  /// In es, this message translates to:
  /// **'Total Pagado:'**
  String get totalPaidLabel;

  /// No description provided for @interestMoraLabel.
  ///
  /// In es, this message translates to:
  /// **'Interés/Mora:'**
  String get interestMoraLabel;

  /// No description provided for @capitalLabel.
  ///
  /// In es, this message translates to:
  /// **'Capital:'**
  String get capitalLabel;

  /// No description provided for @loanLabelPrefix.
  ///
  /// In es, this message translates to:
  /// **'Préstamo #:'**
  String get loanLabelPrefix;

  /// No description provided for @clientLabel.
  ///
  /// In es, this message translates to:
  /// **'Cliente:'**
  String get clientLabel;

  /// No description provided for @dniLabel.
  ///
  /// In es, this message translates to:
  /// **'Cédula:'**
  String get dniLabel;

  /// No description provided for @restrictedEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Edición Restringida'**
  String get restrictedEditTitle;

  /// No description provided for @restrictedEditMessage.
  ///
  /// In es, this message translates to:
  /// **'No se puede editar este préstamo porque ya tiene pagos o abonos registrados.\n\nSolo se permite editar préstamos que no han iniciado su amortización (sin pagos).'**
  String get restrictedEditMessage;

  /// No description provided for @errorVerifyingPayments.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar pagos'**
  String get errorVerifyingPayments;

  /// No description provided for @cannotDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar'**
  String get cannotDeleteTitle;

  /// No description provided for @cannotDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Este préstamo tiene pagos registrados y no puede ser eliminado.\n\nSi desea eliminarlo, primero debe anular todos los pagos asociados.'**
  String get cannotDeleteMessage;

  /// No description provided for @deleteLoanTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Préstamo'**
  String get deleteLoanTitle;

  /// No description provided for @deleteLoanConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de eliminar este préstamo?\n\nEsta acción eliminará también todos los ciclos de facturación asociados.\n\nEsta acción no se puede deshacer.'**
  String get deleteLoanConfirmation;

  /// No description provided for @loanDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Préstamo eliminado exitosamente'**
  String get loanDeletedSuccess;

  /// No description provided for @errorDeletingLoan.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el préstamo'**
  String get errorDeletingLoan;

  /// No description provided for @errorProcessingRequest.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar solicitud'**
  String get errorProcessingRequest;

  /// No description provided for @generatingStatement.
  ///
  /// In es, this message translates to:
  /// **'Generando estado de cuenta...'**
  String get generatingStatement;

  /// No description provided for @loanNotLoaded.
  ///
  /// In es, this message translates to:
  /// **'Préstamo no cargado'**
  String get loanNotLoaded;

  /// No description provided for @customerNotFound.
  ///
  /// In es, this message translates to:
  /// **'Cliente no encontrado'**
  String get customerNotFound;

  /// No description provided for @generatingReceipt.
  ///
  /// In es, this message translates to:
  /// **'Generando recibo...'**
  String get generatingReceipt;

  /// No description provided for @errorGeneratingReceiptTitle.
  ///
  /// In es, this message translates to:
  /// **'Error al generar recibo'**
  String get errorGeneratingReceiptTitle;

  /// No description provided for @generatingDisbursement.
  ///
  /// In es, this message translates to:
  /// **'Generando comprobante de desembolso...'**
  String get generatingDisbursement;

  /// No description provided for @errorGeneratingDisbursement.
  ///
  /// In es, this message translates to:
  /// **'Error al generar comprobante'**
  String get errorGeneratingDisbursement;

  /// No description provided for @disbursementReceiptTooltip.
  ///
  /// In es, this message translates to:
  /// **'Comprobante Desembolso'**
  String get disbursementReceiptTooltip;

  /// No description provided for @editTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteTooltip;

  /// No description provided for @otherFreq.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get otherFreq;

  /// No description provided for @freqDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get freqWeekly;

  /// No description provided for @freqBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Quincenal'**
  String get freqBiweekly;

  /// No description provided for @collectionTitle.
  ///
  /// In es, this message translates to:
  /// **'A Cobrar'**
  String get collectionTitle;

  /// No description provided for @tabBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Quincena'**
  String get tabBiweekly;

  /// No description provided for @tabMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get tabMonthly;

  /// No description provided for @tabOverdue.
  ///
  /// In es, this message translates to:
  /// **'Atrasados'**
  String get tabOverdue;

  /// No description provided for @accountSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Cuenta'**
  String get accountSummary;

  /// No description provided for @totalCapital.
  ///
  /// In es, this message translates to:
  /// **'Capital Total'**
  String get totalCapital;

  /// No description provided for @monthlyInterest.
  ///
  /// In es, this message translates to:
  /// **'Interés Mensual'**
  String get monthlyInterest;

  /// No description provided for @closedLoansTitle.
  ///
  /// In es, this message translates to:
  /// **'Préstamos cerrados'**
  String get closedLoansTitle;

  /// No description provided for @activeLoansTitle.
  ///
  /// In es, this message translates to:
  /// **'Préstamos activos'**
  String get activeLoansTitle;

  /// No description provided for @noLoans.
  ///
  /// In es, this message translates to:
  /// **'Sin préstamos'**
  String get noLoans;

  /// No description provided for @noLoansDesc.
  ///
  /// In es, this message translates to:
  /// **'Este cliente no tiene préstamos registrados'**
  String get noLoansDesc;

  /// No description provided for @actionDenied.
  ///
  /// In es, this message translates to:
  /// **'Acción denegada'**
  String get actionDenied;

  /// No description provided for @cannotDeleteWithPayments.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar un préstamo con pagos registrados.'**
  String get cannotDeleteWithPayments;

  /// No description provided for @registeredDate.
  ///
  /// In es, this message translates to:
  /// **'Registrado:'**
  String get registeredDate;

  /// No description provided for @deactivateCustomer.
  ///
  /// In es, this message translates to:
  /// **'Desactivar cliente'**
  String get deactivateCustomer;

  /// No description provided for @viewFullHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial completo'**
  String get viewFullHistory;

  /// No description provided for @confirmDelete.
  ///
  /// In es, this message translates to:
  /// **'Confirmar eliminación'**
  String get confirmDelete;

  /// No description provided for @deleteLoanConfirmationMsg.
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de que desea eliminar este préstamo?\nEsta acción no se puede deshacer.'**
  String get deleteLoanConfirmationMsg;

  /// No description provided for @loanDeleted.
  ///
  /// In es, this message translates to:
  /// **'Préstamo eliminado correctamente'**
  String get loanDeleted;

  /// No description provided for @errorDeleting.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar:'**
  String get errorDeleting;

  /// No description provided for @selectCustomer.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Cliente'**
  String get selectCustomer;

  /// No description provided for @createCustomer.
  ///
  /// In es, this message translates to:
  /// **'Crear Cliente'**
  String get createCustomer;

  /// No description provided for @paymentAmountLabelRequired.
  ///
  /// In es, this message translates to:
  /// **'Monto del Pago *'**
  String get paymentAmountLabelRequired;

  /// No description provided for @invalidAmountMsg.
  ///
  /// In es, this message translates to:
  /// **'Ingrese un monto válido'**
  String get invalidAmountMsg;

  /// No description provided for @identity.
  ///
  /// In es, this message translates to:
  /// **'Identidad'**
  String get identity;

  /// No description provided for @contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get contact;

  /// No description provided for @location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get location;

  /// No description provided for @branding.
  ///
  /// In es, this message translates to:
  /// **'Branding'**
  String get branding;

  /// No description provided for @companyName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Empresa'**
  String get companyName;

  /// No description provided for @rucId.
  ///
  /// In es, this message translates to:
  /// **'RUC / Identificación'**
  String get rucId;

  /// No description provided for @phoneFixed.
  ///
  /// In es, this message translates to:
  /// **'Teléfono Fijo'**
  String get phoneFixed;

  /// No description provided for @cellPhone.
  ///
  /// In es, this message translates to:
  /// **'Celular'**
  String get cellPhone;

  /// No description provided for @whatsapp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @address.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get address;

  /// No description provided for @logoPath.
  ///
  /// In es, this message translates to:
  /// **'Ruta del Logo (PNG)'**
  String get logoPath;

  /// No description provided for @selectFile.
  ///
  /// In es, this message translates to:
  /// **'Seleccione archivo...'**
  String get selectFile;

  /// No description provided for @visible.
  ///
  /// In es, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @hidden.
  ///
  /// In es, this message translates to:
  /// **'Oculto'**
  String get hidden;

  /// No description provided for @companyInfoHelp.
  ///
  /// In es, this message translates to:
  /// **'Activa el interruptor para mostrar el dato en los recibos y reportes.'**
  String get companyInfoHelp;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get saveChanges;

  /// No description provided for @onlyPng.
  ///
  /// In es, this message translates to:
  /// **'Solo se permiten imágenes PNG'**
  String get onlyPng;

  /// No description provided for @errorPickingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen:'**
  String get errorPickingImage;

  /// No description provided for @searchCollectionHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o monto...'**
  String get searchCollectionHint;

  /// No description provided for @noActiveLoans.
  ///
  /// In es, this message translates to:
  /// **'Este cliente no tiene préstamos activos'**
  String get noActiveLoans;

  /// No description provided for @createLoan.
  ///
  /// In es, this message translates to:
  /// **'Crear Préstamo'**
  String get createLoan;

  /// No description provided for @originalAmount.
  ///
  /// In es, this message translates to:
  /// **'Original'**
  String get originalAmount;

  /// No description provided for @selectedLoan.
  ///
  /// In es, this message translates to:
  /// **'Préstamo Seleccionado'**
  String get selectedLoan;

  /// No description provided for @paymentTypeMixed.
  ///
  /// In es, this message translates to:
  /// **'Mixto'**
  String get paymentTypeMixed;

  /// No description provided for @paymentTypeRecovery.
  ///
  /// In es, this message translates to:
  /// **'Recuperar'**
  String get paymentTypeRecovery;

  /// No description provided for @paymentApplication.
  ///
  /// In es, this message translates to:
  /// **'Aplicación del Pago'**
  String get paymentApplication;

  /// No description provided for @toOverdueInterest.
  ///
  /// In es, this message translates to:
  /// **'A interés vencido'**
  String get toOverdueInterest;

  /// No description provided for @toCurrentInterest.
  ///
  /// In es, this message translates to:
  /// **'A interés actual'**
  String get toCurrentInterest;

  /// No description provided for @toPrincipal.
  ///
  /// In es, this message translates to:
  /// **'A capital'**
  String get toPrincipal;

  /// No description provided for @totalApplied.
  ///
  /// In es, this message translates to:
  /// **'Total aplicado'**
  String get totalApplied;

  /// No description provided for @projectedMonthlyEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ganancias Mensuales Proyectadas'**
  String get projectedMonthlyEarnings;

  /// No description provided for @paymentsInRange.
  ///
  /// In es, this message translates to:
  /// **'pagos en el rango'**
  String get paymentsInRange;

  /// No description provided for @noResultsFor.
  ///
  /// In es, this message translates to:
  /// **'para'**
  String get noResultsFor;

  /// No description provided for @noCollectionBiweeklyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay cobros pendientes esta quincena'**
  String get noCollectionBiweeklyTitle;

  /// No description provided for @noCollectionBiweeklyMsg.
  ///
  /// In es, this message translates to:
  /// **'Los clientes quincenales aparecerán aquí cuando tengan pagos pendientes'**
  String get noCollectionBiweeklyMsg;

  /// No description provided for @noCollectionMonthlyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay cobros pendientes este mes'**
  String get noCollectionMonthlyTitle;

  /// No description provided for @noCollectionMonthlyMsg.
  ///
  /// In es, this message translates to:
  /// **'Los clientes con pagos pendientes aparecerán aquí'**
  String get noCollectionMonthlyMsg;

  /// No description provided for @noCollectionOverdueTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Sin clientes atrasados!'**
  String get noCollectionOverdueTitle;

  /// No description provided for @noCollectionOverdueMsg.
  ///
  /// In es, this message translates to:
  /// **'Todos tus clientes están al día'**
  String get noCollectionOverdueMsg;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get noData;

  /// No description provided for @interestExpected.
  ///
  /// In es, this message translates to:
  /// **'Interés esperado'**
  String get interestExpected;

  /// No description provided for @capitalPending.
  ///
  /// In es, this message translates to:
  /// **'Capital Pendiente'**
  String get capitalPending;

  /// No description provided for @daysOverdue.
  ///
  /// In es, this message translates to:
  /// **'días de atraso'**
  String get daysOverdue;

  /// No description provided for @activeLoansCount.
  ///
  /// In es, this message translates to:
  /// **'préstamos activos'**
  String get activeLoansCount;

  /// No description provided for @lastPayment.
  ///
  /// In es, this message translates to:
  /// **'Último pago'**
  String get lastPayment;

  /// No description provided for @historyTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de Pagos'**
  String get historyTitle;

  /// No description provided for @noPaymentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin pagos registrados'**
  String get noPaymentsTitle;

  /// No description provided for @noPaymentsMsg.
  ///
  /// In es, this message translates to:
  /// **'Los pagos registrados aparecerán aquí'**
  String get noPaymentsMsg;

  /// No description provided for @dateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {days} días'**
  String dateDaysAgo(Object days);

  /// No description provided for @activeCustomersLabel.
  ///
  /// In es, this message translates to:
  /// **'Clientes Activos'**
  String get activeCustomersLabel;

  /// No description provided for @activeLoansLabel.
  ///
  /// In es, this message translates to:
  /// **'Préstamos Activos'**
  String get activeLoansLabel;

  /// No description provided for @overdueLoansLabel.
  ///
  /// In es, this message translates to:
  /// **'Préstamos Vencidos'**
  String get overdueLoansLabel;

  /// No description provided for @earningsMonthLabel.
  ///
  /// In es, this message translates to:
  /// **'Ganancias (Mes)'**
  String get earningsMonthLabel;

  /// No description provided for @projectedMonthLabel.
  ///
  /// In es, this message translates to:
  /// **'Proyección Mes'**
  String get projectedMonthLabel;

  /// No description provided for @capitalPlacedLabel.
  ///
  /// In es, this message translates to:
  /// **'Capital Colocado'**
  String get capitalPlacedLabel;

  /// No description provided for @ofLabel.
  ///
  /// In es, this message translates to:
  /// **'de'**
  String get ofLabel;

  /// No description provided for @newCustomerLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Cliente'**
  String get newCustomerLabel;

  /// No description provided for @freqMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get freqMonthly;

  /// No description provided for @generated.
  ///
  /// In es, this message translates to:
  /// **'Generado:'**
  String get generated;

  /// No description provided for @ignoreAndContinue.
  ///
  /// In es, this message translates to:
  /// **'Ignorar y Continuar'**
  String get ignoreAndContinue;

  /// No description provided for @enableCapitalRestriction.
  ///
  /// In es, this message translates to:
  /// **'Restringir abono al capital por fecha'**
  String get enableCapitalRestriction;

  /// No description provided for @enableCapitalRestrictionDesc.
  ///
  /// In es, this message translates to:
  /// **'Impide abonar al capital cuando el ciclo está por concluir'**
  String get enableCapitalRestrictionDesc;

  /// No description provided for @capitalRestrictionDays.
  ///
  /// In es, this message translates to:
  /// **'Días mínimos antes del corte'**
  String get capitalRestrictionDays;

  /// No description provided for @capitalRestrictionDaysDesc.
  ///
  /// In es, this message translates to:
  /// **'Restringir abonos si faltan menos de {days} días para completar el ciclo'**
  String capitalRestrictionDaysDesc(int days);

  /// No description provided for @errorCycleConcluding.
  ///
  /// In es, this message translates to:
  /// **'No se puede abonar al capital porque el ciclo está por concluir.\n\nFaltan {remaining} días para el corte. Solo se permite abonar al capital cuando faltan más de {required} días.'**
  String errorCycleConcluding(int remaining, int required);

  /// No description provided for @cycleConcluding.
  ///
  /// In es, this message translates to:
  /// **'Ciclo Por Concluir'**
  String get cycleConcluding;

  /// No description provided for @aboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de Prestazo'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get aboutVersion;

  /// No description provided for @aboutTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu aliado financiero'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In es, this message translates to:
  /// **'Prestazo es una aplicación diseñada para simplificar la gestión de tus préstamos personales. Con Prestazo, puedes mantener un control total sobre tus clientes, créditos y cobros, todo desde la palma de tu mano.'**
  String get aboutDescription;

  /// No description provided for @featureCustomers.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu cartera de clientes fácilmente.'**
  String get featureCustomers;

  /// No description provided for @featureCalculations.
  ///
  /// In es, this message translates to:
  /// **'Calcula intereses y amortizaciones automáticamente.'**
  String get featureCalculations;

  /// No description provided for @featureCollections.
  ///
  /// In es, this message translates to:
  /// **'Visualiza cobros pendientes por día, semana o mes.'**
  String get featureCollections;

  /// No description provided for @featureReports.
  ///
  /// In es, this message translates to:
  /// **'Genera reportes de ganancias y proyección de ingresos.'**
  String get featureReports;

  /// No description provided for @selectCurrency.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Moneda'**
  String get selectCurrency;

  /// No description provided for @searchCurrencyHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar moneda...'**
  String get searchCurrencyHint;

  /// No description provided for @currencyUpdated.
  ///
  /// In es, this message translates to:
  /// **'Moneda actualizada'**
  String get currencyUpdated;

  /// No description provided for @exchangeRateMissingContract.
  ///
  /// In es, this message translates to:
  /// **'Error: Un préstamo en moneda extranjera no tiene registrada su tasa de cambio base. Contacte soporte.'**
  String get exchangeRateMissingContract;

  /// No description provided for @defineExchangeRateMessage.
  ///
  /// In es, this message translates to:
  /// **'Defina una tasa de cambio para la moneda de visualización seleccionada.'**
  String get defineExchangeRateMessage;

  /// No description provided for @noExchangeRateToday.
  ///
  /// In es, this message translates to:
  /// **'No hay tasa de cambio para hoy. Por favor agregue una tasa antes de crear un préstamo en esta moneda.'**
  String get noExchangeRateToday;

  /// No description provided for @goToExchangeRates.
  ///
  /// In es, this message translates to:
  /// **'Ir a Divisas'**
  String get goToExchangeRates;

  /// No description provided for @validations.
  ///
  /// In es, this message translates to:
  /// **'Validaciones'**
  String get validations;

  /// No description provided for @dniFormatTitle.
  ///
  /// In es, this message translates to:
  /// **'Formato de DNI'**
  String get dniFormatTitle;

  /// No description provided for @dniFormatSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar máscara y validación de DNI'**
  String get dniFormatSubtitle;

  /// No description provided for @validateDniFormat.
  ///
  /// In es, this message translates to:
  /// **'Validar formato de DNI'**
  String get validateDniFormat;

  /// No description provided for @validateDniFormatDesc.
  ///
  /// In es, this message translates to:
  /// **'Exigir que el DNI cumpla con la máscara definida'**
  String get validateDniFormatDesc;

  /// No description provided for @defineMaskTitle.
  ///
  /// In es, this message translates to:
  /// **'Definir Máscara / Formato'**
  String get defineMaskTitle;

  /// No description provided for @maskHelpText.
  ///
  /// In es, this message translates to:
  /// **'Use los siguientes caracteres para definir el formato:\n# : Dígito (0-9)\n@ : Letra (A-Z)\n* : Cualquiera\nOtros : Separadores (-, ., /)'**
  String get maskHelpText;

  /// No description provided for @maskLabel.
  ///
  /// In es, this message translates to:
  /// **'Máscara'**
  String get maskLabel;

  /// No description provided for @maskHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: ###-######-####@'**
  String get maskHint;

  /// No description provided for @testValidation.
  ///
  /// In es, this message translates to:
  /// **'Probar Validación'**
  String get testValidation;

  /// No description provided for @testDniLabel.
  ///
  /// In es, this message translates to:
  /// **'Prueba de DNI'**
  String get testDniLabel;

  /// No description provided for @testDniHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe para probar...'**
  String get testDniHint;

  /// No description provided for @formatMismatch.
  ///
  /// In es, this message translates to:
  /// **'El formato no coincide con la máscara'**
  String get formatMismatch;

  /// No description provided for @saveConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Guardar Configuración'**
  String get saveConfiguration;

  /// No description provided for @configurationSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada'**
  String get configurationSaved;

  /// No description provided for @reportCurrencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Moneda de Reportes'**
  String get reportCurrencyTitle;

  /// No description provided for @reportCurrencySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar moneda y tasa de cambio'**
  String get reportCurrencySubtitle;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Cambio'**
  String get exchangeRateLabel;

  /// No description provided for @exchangeRateHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 36.50'**
  String get exchangeRateHint;

  /// No description provided for @exchangeRateHelper.
  ///
  /// In es, this message translates to:
  /// **'1 Moneda Reporte = X Moneda Base'**
  String get exchangeRateHelper;

  /// No description provided for @saveSettings.
  ///
  /// In es, this message translates to:
  /// **'Guardar configuración'**
  String get saveSettings;

  /// No description provided for @reportSettingsInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Moneda de Reportes'**
  String get reportSettingsInfoTitle;

  /// No description provided for @reportSettingsInfo.
  ///
  /// In es, this message translates to:
  /// **'Define la moneda en la que deseas ver tus ganancias y reportes. Si prestas en otra moneda, usa la Tasa de Cambio para convertir los montos.'**
  String get reportSettingsInfo;

  /// No description provided for @loanCurrencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda del Préstamo'**
  String get loanCurrencyLabel;

  /// No description provided for @selectCountryTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar País'**
  String get selectCountryTitle;

  /// No description provided for @searchCountryHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar país...'**
  String get searchCountryHint;

  /// No description provided for @availableCapitalTitle.
  ///
  /// In es, this message translates to:
  /// **'Proyección de Capital y Límites'**
  String get availableCapitalTitle;

  /// No description provided for @availableCapitalDescription.
  ///
  /// In es, this message translates to:
  /// **'El \"Capital disponible para prestar\" funciona como un límite de seguridad y una herramienta de planificación financiera para tu negocio de préstamos.\n\n**¿Para qué sirve?**\nEste valor establece un techo máximo para el capital total que puedes tener prestado (en la calle) en un momento dado. No es una cuenta bancaria real, sino un límite administrativo que defines tú mismo.\n\n**¿Qué pasa si lo activo?**\nCuando la opción \"Validar capital de trabajo\" está activada, antes de crear un nuevo préstamo, el sistema verificará si tienes saldo disponible suficiente.\n\n1. **Cálculo:** Se resta la suma de todos los capitales prestados activos de este límite global.\n2. **Validación:** Si el nuevo préstamo excede el remanente, el sistema te avisará e impedirá la creación del préstamo para evitar sobregiros no planificados.\n\n**Recomendación:**\nMantén este valor actualizado según tu capacidad real de inversión o el presupuesto que has asignado para tu cartera de créditos. Si tu negocio crece, recuerda aumentar este límite.'**
  String get availableCapitalDescription;

  /// No description provided for @capitalizeInterestTitle.
  ///
  /// In es, this message translates to:
  /// **'Capitalización de Intereses'**
  String get capitalizeInterestTitle;

  /// No description provided for @capitalizeInterestDescription.
  ///
  /// In es, this message translates to:
  /// **'Esta opción permite convertir los intereses no pagados en nuevo capital.\n\n**¿Qué significa?**\nSi un cliente no paga sus intereses a tiempo, estos se suman al saldo capital del préstamo, generando nuevos intereses sobre el monto acumulado (interés compuesto).\n\n**Uso:** Habilita esta opción si tu modelo de negocio cobra interés sobre interés en caso de mora prolongada.'**
  String get capitalizeInterestDescription;

  /// No description provided for @dailyAccrualTitle.
  ///
  /// In es, this message translates to:
  /// **'Acumulación Diaria (Prorrateo)'**
  String get dailyAccrualTitle;

  /// No description provided for @dailyAccrualDescription.
  ///
  /// In es, this message translates to:
  /// **'Controla cómo se cobran los intereses si el cliente cancela el préstamo antes de tiempo.\n\n**Activado:**\nSe cobra interés solo por los días exactos transcurridos en el ciclo actual.\n*Ejemplo:* Si paga a la mitad del mes, paga solo medio mes de interés.\n\n**Desactivado:**\nSe cobra el ciclo completo de interés sin importar el día de pago.\n*Ejemplo:* Un día dentro del mes cuenta como el mes entero de interés.'**
  String get dailyAccrualDescription;

  /// No description provided for @allowMultipleLoansTitle.
  ///
  /// In es, this message translates to:
  /// **'Múltiples Préstamos'**
  String get allowMultipleLoansTitle;

  /// No description provided for @allowMultipleLoansDescription.
  ///
  /// In es, this message translates to:
  /// **'**Activado:**\nPermite que un mismo cliente tenga varios préstamos activos simultáneamente.\n\n**Desactivado:**\nUn cliente debe liquidar su préstamo actual antes de poder solicitar uno nuevo.'**
  String get allowMultipleLoansDescription;

  /// No description provided for @validateDniTitle.
  ///
  /// In es, this message translates to:
  /// **'Validación de DNI Único'**
  String get validateDniTitle;

  /// No description provided for @validateDniDescription.
  ///
  /// In es, this message translates to:
  /// **'Evita la duplicidad de clientes en tu base de datos.\nAl registrar un nuevo cliente, el sistema verificará si el número de identidad (DNI/Cédula) ya existe.'**
  String get validateDniDescription;

  /// No description provided for @whatsappReceiptsTitle.
  ///
  /// In es, this message translates to:
  /// **'Recibos por WhatsApp'**
  String get whatsappReceiptsTitle;

  /// No description provided for @whatsappReceiptsDescription.
  ///
  /// In es, this message translates to:
  /// **'Habilita el envío rápido de comprobantes de pago y desembolso a través de WhatsApp.\nEl sistema generará el PDF y abrirá WhatsApp automáticamente con el archivo listo para enviar.'**
  String get whatsappReceiptsDescription;

  /// No description provided for @capitalRestrictionTitle.
  ///
  /// In es, this message translates to:
  /// **'Restricción de Abono a Capital'**
  String get capitalRestrictionTitle;

  /// No description provided for @capitalRestrictionDescription.
  ///
  /// In es, this message translates to:
  /// **'Evita que los clientes abonen al capital si faltan pocos días para su fecha de corte.\n\n**Objetivo:**\nAsegurar el cobro completo de los intereses del ciclo. Si abonan capital muy cerca de la fecha de pago, el interés calculado bajaría drásticamente, afectando tu ganancia esperada.\n\n**Configuración:**\nTú defines cuántos días antes del corte se activa este bloqueo (ej. 10 días).'**
  String get capitalRestrictionDescription;

  /// No description provided for @toleranceDaysTitle.
  ///
  /// In es, this message translates to:
  /// **'Días de Tolerancia (Mora)'**
  String get toleranceDaysTitle;

  /// No description provided for @toleranceDaysDescription.
  ///
  /// In es, this message translates to:
  /// **'Días adicionales que otorgas después de la fecha de pago antes de considerar el préstamo en \"Mora\".\n\n**Ejemplo (2 días de tolerancia):**\nSi paga el día 1 o 2 después de la fecha límite, se considera puntual. Al día 3, pasa a estado de Mora.'**
  String get toleranceDaysDescription;

  /// No description provided for @paymentOrderTitle.
  ///
  /// In es, this message translates to:
  /// **'Orden de Aplicación de Pagos'**
  String get paymentOrderTitle;

  /// No description provided for @paymentOrderDescription.
  ///
  /// In es, this message translates to:
  /// **'Define la prioridad con la que se distribuye el dinero recibido.\n\n**Interés Primero (Recomendado):**\n1. Mora pendiente\n2. Interés corriente\n3. Abono a capital\n\n**Capital Primero:**\n1. Descuenta capital directamente\n2. Luego cubre intereses\n*Nota: Esta opción reduce el saldo más rápido pero puede afectar la recuperación de intereses.*'**
  String get paymentOrderDescription;

  /// No description provided for @reportSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Reportes'**
  String get reportSettingsTitle;

  /// No description provided for @reportSettingsDescription.
  ///
  /// In es, this message translates to:
  /// **'Personaliza la apariencia de los recibos PDF que entregas a tus clientes.\n\n* **Firmas:** Añade líneas para firma de \"Entregado por\" y \"Recibido por\".\n* **Leyendas:** Añade textos legales o notas al pie (ej. \"Gracias por su pago\", \"Sujeto a mora por atraso\").'**
  String get reportSettingsDescription;

  /// No description provided for @sequencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Consecutivos'**
  String get sequencesTitle;

  /// No description provided for @sequencesDescription.
  ///
  /// In es, this message translates to:
  /// **'Permite ajustar manualmente los números de control para Préstamos y Recibos.\n\n**Préstamos:**\nDefine el número del *último* préstamo creado (ej. 100). El siguiente préstamo será 101.\nÚtil si migras datos de otro sistema y quieres continuar tu numeración.\n\n**Recibos:**\nIgual que los préstamos, define el último número generado para los comprobantes de pago.'**
  String get sequencesDescription;

  /// No description provided for @maintenanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento y Respaldos'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDescription.
  ///
  /// In es, this message translates to:
  /// **'Herramientas críticas para proteger y gestionar tus datos.\n\n**Exportar Respaldo:** Crea una copia completa de tu base de datos. ¡Haz esto regularmente!\n**Carpeta de Respaldo:** Elige dónde se guardan los respaldos (útil para sincronizar con la nube).\n**Restaurar:** Recupera tus datos desde un archivo de respaldo anterior.\n**Recalcular Cartera:** Corrige inconsistencias en saldos si notas errores en los cálculos.\n**Borrar Datos:** *Zona de Peligro*. Elimina datos permanentemente para reiniciar o limpiar.'**
  String get maintenanceDescription;

  /// No description provided for @appearanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearanceTitle;

  /// No description provided for @appearanceDescription.
  ///
  /// In es, this message translates to:
  /// **'Personaliza cómo se ve la aplicación.\n\n**Modo Claro:** Ideal para entornos muy iluminados.\n**Modo Oscuro:** Reduce la fatiga visual y ahorra batería.\n**Sistema:** Se adapta automáticamente a la configuración de tu teléfono.'**
  String get appearanceDescription;

  /// No description provided for @languageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In es, this message translates to:
  /// **'Cambia el idioma de toda la interfaz de la aplicación.\nActualmente soportamos Español e Inglés.'**
  String get languageDescription;

  /// No description provided for @onLoanCreation.
  ///
  /// In es, this message translates to:
  /// **'Al crear préstamo'**
  String get onLoanCreation;

  /// No description provided for @onLoanCreationDesc.
  ///
  /// In es, this message translates to:
  /// **'Respaldar cada vez que se crea un préstamo'**
  String get onLoanCreationDesc;

  /// No description provided for @onPayment.
  ///
  /// In es, this message translates to:
  /// **'Al registrar pago'**
  String get onPayment;

  /// No description provided for @onPaymentDesc.
  ///
  /// In es, this message translates to:
  /// **'Respaldar cada vez que se registra un pago'**
  String get onPaymentDesc;

  /// No description provided for @advancedSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración Avanzada'**
  String get advancedSettings;

  /// No description provided for @fileNamePrefix.
  ///
  /// In es, this message translates to:
  /// **'Prefijo del archivo'**
  String get fileNamePrefix;

  /// No description provided for @keepBackupsFor.
  ///
  /// In es, this message translates to:
  /// **'Retener respaldos por: {days} días'**
  String keepBackupsFor(int days);

  /// No description provided for @autoBackupInfo.
  ///
  /// In es, this message translates to:
  /// **'Los respaldos automáticos se verificarán cuando abras la aplicación. Asegúrate de abrir la app regularmente.'**
  String get autoBackupInfo;

  /// No description provided for @errorCheckingPayments.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar pagos: {error}'**
  String errorCheckingPayments(Object error);

  /// No description provided for @configNotLoaded.
  ///
  /// In es, this message translates to:
  /// **'Configuración no cargada'**
  String get configNotLoaded;

  /// No description provided for @errorGeneratingPdf.
  ///
  /// In es, this message translates to:
  /// **'Error al generar PDF: {error}'**
  String errorGeneratingPdf(Object error);

  /// No description provided for @errorGeneratingReceipt.
  ///
  /// In es, this message translates to:
  /// **'Error al generar comprobante: {error}'**
  String errorGeneratingReceipt(Object error);

  /// No description provided for @errorGeneratingVoucher.
  ///
  /// In es, this message translates to:
  /// **'Error al generar recibo: {error}'**
  String errorGeneratingVoucher(Object error);

  /// No description provided for @generatedBillingCycles.
  ///
  /// In es, this message translates to:
  /// **'Se han generado {count} nuevos ciclos de cobro'**
  String generatedBillingCycles(int count);

  /// No description provided for @genericError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String genericError(Object error);

  /// No description provided for @loanNotFound.
  ///
  /// In es, this message translates to:
  /// **'Préstamo no encontrado'**
  String get loanNotFound;

  /// No description provided for @generatingEarningsReport.
  ///
  /// In es, this message translates to:
  /// **'Generando Reporte de Ganancias...'**
  String get generatingEarningsReport;

  /// No description provided for @noPaymentDataForReport.
  ///
  /// In es, this message translates to:
  /// **'No hay datos de pagos para generar reporte'**
  String get noPaymentDataForReport;

  /// No description provided for @generatingConsolidatedReport.
  ///
  /// In es, this message translates to:
  /// **'Generando Reporte Consolidado...'**
  String get generatingConsolidatedReport;

  /// No description provided for @noActiveLoansForReport.
  ///
  /// In es, this message translates to:
  /// **'No hay préstamos vigentes para reportar'**
  String get noActiveLoansForReport;

  /// No description provided for @errorGeneratingReport.
  ///
  /// In es, this message translates to:
  /// **'Error al generar reporte: {error}'**
  String errorGeneratingReport(Object error);

  /// No description provided for @recalculatingPortfolio.
  ///
  /// In es, this message translates to:
  /// **'Recalculando cartera...'**
  String get recalculatingPortfolio;

  /// No description provided for @errorRestoringBackup.
  ///
  /// In es, this message translates to:
  /// **'Error al restaurar respaldo'**
  String get errorRestoringBackup;

  /// No description provided for @errorSelectingFile.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar archivo: {error}'**
  String errorSelectingFile(Object error);

  /// No description provided for @invalidAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto Inválido'**
  String get invalidAmountTitle;

  /// No description provided for @invalidAmountMessage.
  ///
  /// In es, this message translates to:
  /// **'El monto debe ser mayor a cero.'**
  String get invalidAmountMessage;

  /// No description provided for @invalidPaymentTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo Inválido'**
  String get invalidPaymentTypeTitle;

  /// No description provided for @invalidPaymentTypeMessage.
  ///
  /// In es, this message translates to:
  /// **'Tipo de pago no reconocido.'**
  String get invalidPaymentTypeMessage;

  /// No description provided for @incorrectCancelAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto Incorrecto para Cancelar'**
  String get incorrectCancelAmountTitle;

  /// No description provided for @incorrectCancelAmountMessage.
  ///
  /// In es, this message translates to:
  /// **'Para cancelar el préstamo, el monto debe ser exactamente {symbol} {amount} (Capital + Intereses).'**
  String incorrectCancelAmountMessage(String symbol, String amount);

  /// No description provided for @amountExceedsInterestTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto Excede Intereses'**
  String get amountExceedsInterestTitle;

  /// No description provided for @amountExceedsInterestMessage.
  ///
  /// In es, this message translates to:
  /// **'El monto ({symbol} {paid}) excede los intereses pendientes ({symbol} {pending}).\n\nSeleccione \"Mixto\" para abonar al capital.'**
  String amountExceedsInterestMessage(
    String symbol,
    String paid,
    String pending,
  );

  /// No description provided for @insufficientMixedAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto Insuficiente para Mixto'**
  String get insufficientMixedAmountTitle;

  /// No description provided for @insufficientMixedAmountMessage.
  ///
  /// In es, this message translates to:
  /// **'Para un pago mixto, el monto debe ser mayor a los intereses pendientes ({symbol} {pending}).\n\nSi solo desea pagar intereses, seleccione \"Solo Interés\".'**
  String insufficientMixedAmountMessage(String symbol, String pending);

  /// No description provided for @pendingInterestTitle.
  ///
  /// In es, this message translates to:
  /// **'Intereses Pendientes'**
  String get pendingInterestTitle;

  /// No description provided for @pendingInterestMessage.
  ///
  /// In es, this message translates to:
  /// **'No puede abonar solo al capital porque tiene intereses pendientes ({symbol} {pending}).\n\nDebe pagar los intereses primero.'**
  String pendingInterestMessage(String symbol, String pending);

  /// No description provided for @amountExceedsPrincipalTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto Excede Capital'**
  String get amountExceedsPrincipalTitle;

  /// No description provided for @amountExceedsPrincipalMessage.
  ///
  /// In es, this message translates to:
  /// **'El monto ({symbol} {paid}) excede el capital pendiente ({symbol} {pending}).'**
  String amountExceedsPrincipalMessage(
    String symbol,
    String paid,
    String pending,
  );

  /// No description provided for @calculating.
  ///
  /// In es, this message translates to:
  /// **'Calculando...'**
  String get calculating;

  /// No description provided for @errorLoadingCycles.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar ciclos: {error}'**
  String errorLoadingCycles(Object error);

  /// No description provided for @errorLoadingPayments.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar pagos: {error}'**
  String errorLoadingPayments(Object error);

  /// No description provided for @noPaymentsRegistered.
  ///
  /// In es, this message translates to:
  /// **'No hay pagos registrados'**
  String get noPaymentsRegistered;

  /// No description provided for @loadingDetails.
  ///
  /// In es, this message translates to:
  /// **'Cargando detalles...'**
  String get loadingDetails;

  /// No description provided for @errorLoadingDetails.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar detalles'**
  String get errorLoadingDetails;

  /// No description provided for @noAllocationDetails.
  ///
  /// In es, this message translates to:
  /// **'Sin asignación detallada'**
  String get noAllocationDetails;

  /// No description provided for @companyDataUpdated.
  ///
  /// In es, this message translates to:
  /// **'Datos de la empresa actualizados'**
  String get companyDataUpdated;

  /// No description provided for @errorSaving.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String errorSaving(Object error);

  /// No description provided for @selectALoan.
  ///
  /// In es, this message translates to:
  /// **'Seleccione un préstamo'**
  String get selectALoan;

  /// No description provided for @loanUpdatedRecalculated.
  ///
  /// In es, this message translates to:
  /// **'Préstamo actualizado y recalculado'**
  String get loanUpdatedRecalculated;

  /// No description provided for @exchangeRates.
  ///
  /// In es, this message translates to:
  /// **'Tasas de Cambio'**
  String get exchangeRates;

  /// No description provided for @addExchangeRate.
  ///
  /// In es, this message translates to:
  /// **'Agregar Tasa'**
  String get addExchangeRate;

  /// No description provided for @editExchangeRate.
  ///
  /// In es, this message translates to:
  /// **'Editar Tasa'**
  String get editExchangeRate;

  /// No description provided for @sourceCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda Origen'**
  String get sourceCurrency;

  /// No description provided for @targetCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda Destino'**
  String get targetCurrency;

  /// No description provided for @buyRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Compra'**
  String get buyRate;

  /// No description provided for @sellRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Venta'**
  String get sellRate;

  /// No description provided for @rateDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get rateDate;

  /// No description provided for @noRatesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay tasas registradas'**
  String get noRatesAvailable;

  /// No description provided for @rateAddedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Tasa agregada exitosamente'**
  String get rateAddedSuccessfully;

  /// No description provided for @rateUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Tasa actualizada exitosamente'**
  String get rateUpdatedSuccessfully;

  /// No description provided for @rateDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Tasa eliminada'**
  String get rateDeletedSuccessfully;

  /// No description provided for @averageRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Promedio'**
  String get averageRate;

  /// No description provided for @deleteRateConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de eliminar esta tasa?'**
  String get deleteRateConfirmation;

  /// No description provided for @rateAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una tasa para esta fecha y par de monedas'**
  String get rateAlreadyExists;

  /// No description provided for @workingCapitalIn.
  ///
  /// In es, this message translates to:
  /// **'Capital de Trabajo en {currency}'**
  String workingCapitalIn(String currency);

  /// No description provided for @recalculateCapitalQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Desea recalcular el capital de trabajo a la nueva moneda base?'**
  String get recalculateCapitalQuestion;

  /// No description provided for @baseCurrencyChanged.
  ///
  /// In es, this message translates to:
  /// **'Moneda base cambiada'**
  String get baseCurrencyChanged;

  /// No description provided for @capitalWillBeRecalculated.
  ///
  /// In es, this message translates to:
  /// **'El capital será recalculado según la tasa vigente'**
  String get capitalWillBeRecalculated;

  /// No description provided for @allowManualExchangeRate.
  ///
  /// In es, this message translates to:
  /// **'Permitir modificación manual de tasa'**
  String get allowManualExchangeRate;

  /// No description provided for @allowManualExchangeRateDesc.
  ///
  /// In es, this message translates to:
  /// **'El prestamista puede editar la tasa al crear un préstamo'**
  String get allowManualExchangeRateDesc;

  /// No description provided for @appliedExchangeRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Aplicada'**
  String get appliedExchangeRate;

  /// No description provided for @noRateForToday.
  ///
  /// In es, this message translates to:
  /// **'No hay tasa registrada para hoy'**
  String get noRateForToday;

  /// No description provided for @usingFallbackRate.
  ///
  /// In es, this message translates to:
  /// **'Usando tasa de respaldo'**
  String get usingFallbackRate;

  /// No description provided for @totalInBaseCurrency.
  ///
  /// In es, this message translates to:
  /// **'Total en {currency}'**
  String totalInBaseCurrency(String currency);

  /// No description provided for @currencyDifferentialReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte Diferencial Cambiario'**
  String get currencyDifferentialReport;

  /// No description provided for @exchangeGain.
  ///
  /// In es, this message translates to:
  /// **'Ganancia Cambiaria'**
  String get exchangeGain;

  /// No description provided for @exchangeLoss.
  ///
  /// In es, this message translates to:
  /// **'Pérdida Cambiaria'**
  String get exchangeLoss;

  /// No description provided for @portfolioDifferential.
  ///
  /// In es, this message translates to:
  /// **'Diferencial de Cartera'**
  String get portfolioDifferential;

  /// No description provided for @atDisbursement.
  ///
  /// In es, this message translates to:
  /// **'Al Desembolso'**
  String get atDisbursement;

  /// No description provided for @atCurrentRate.
  ///
  /// In es, this message translates to:
  /// **'A Tasa Actual'**
  String get atCurrentRate;

  /// No description provided for @contractRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Contrato'**
  String get contractRate;

  /// No description provided for @currentRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Actual'**
  String get currentRate;

  /// No description provided for @noDifferentials.
  ///
  /// In es, this message translates to:
  /// **'No hay diferenciales cambiarios'**
  String get noDifferentials;

  /// No description provided for @loansWithDifferential.
  ///
  /// In es, this message translates to:
  /// **'{count} préstamos con diferencial'**
  String loansWithDifferential(int count);

  /// No description provided for @manageExchangeRates.
  ///
  /// In es, this message translates to:
  /// **'Gestionar tasas de cambio'**
  String get manageExchangeRates;

  /// No description provided for @baseCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda Base'**
  String get baseCurrency;

  /// No description provided for @planNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Préstamo Personal Rápido'**
  String get planNameHint;

  /// No description provided for @financialData.
  ///
  /// In es, this message translates to:
  /// **'Datos Financieros'**
  String get financialData;

  /// No description provided for @allowCurrencyChangeTitle.
  ///
  /// In es, this message translates to:
  /// **'Permitir cambio de moneda'**
  String get allowCurrencyChangeTitle;

  /// No description provided for @allowCurrencyChangeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Al crear el préstamo'**
  String get allowCurrencyChangeSubtitle;

  /// No description provided for @distributeCapitalInterestTitle.
  ///
  /// In es, this message translates to:
  /// **'Distribuir capital e interés'**
  String get distributeCapitalInterestTitle;

  /// No description provided for @distributeCapitalInterestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'En cuotas niveladas'**
  String get distributeCapitalInterestSubtitle;

  /// No description provided for @periodStartsOnDisbursementTitle.
  ///
  /// In es, this message translates to:
  /// **'El periodo inicia en desembolso'**
  String get periodStartsOnDisbursementTitle;

  /// No description provided for @limitByCategoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplica a clientes con categoría (opcional)'**
  String get limitByCategoryTitle;

  /// No description provided for @limitByCategorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Limitar este plan a un tipo específico de cliente'**
  String get limitByCategorySubtitle;

  /// No description provided for @noCategoriesCreated.
  ///
  /// In es, this message translates to:
  /// **'No hay categorías creadas. Cree una categoría primero.'**
  String get noCategoriesCreated;

  /// No description provided for @labelSelectCategory.
  ///
  /// In es, this message translates to:
  /// **'Seleccione Categoría'**
  String get labelSelectCategory;

  /// No description provided for @planNotFound.
  ///
  /// In es, this message translates to:
  /// **'Plan no encontrado'**
  String get planNotFound;

  /// No description provided for @selectStartCategory.
  ///
  /// In es, this message translates to:
  /// **'Seleccione una categoría'**
  String get selectStartCategory;

  /// No description provided for @baseCurrencyDesc.
  ///
  /// In es, this message translates to:
  /// **'Moneda principal para cálculos y reportes'**
  String get baseCurrencyDesc;

  /// No description provided for @baseCurrencyInfo.
  ///
  /// In es, this message translates to:
  /// **'La Moneda Base es la moneda local en la que opera su negocio de préstamos.\n\n¿Qué afecta?\n• El campo de Capital de Trabajo se muestra en esta moneda\n• Las tasas de cambio se registran contra esta moneda\n• Los préstamos en otra moneda usan la tasa del día para conversión\n\nEjemplo: Si opera en Nicaragua, su moneda base sería Córdoba (NIO).'**
  String get baseCurrencyInfo;

  /// No description provided for @capitalConverted.
  ///
  /// In es, this message translates to:
  /// **'Capital convertido'**
  String get capitalConverted;

  /// No description provided for @contractRatePolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Tasa en Contrato'**
  String get contractRatePolicy;

  /// No description provided for @contractRatePolicyDesc.
  ///
  /// In es, this message translates to:
  /// **'Permitir modificar la tasa de cambio al crear un préstamo'**
  String get contractRatePolicyDesc;

  /// No description provided for @helpFunc.
  ///
  /// In es, this message translates to:
  /// **'Función'**
  String get helpFunc;

  /// No description provided for @helpAffects.
  ///
  /// In es, this message translates to:
  /// **'Qué afecta'**
  String get helpAffects;

  /// No description provided for @helpExample.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo'**
  String get helpExample;

  /// No description provided for @helpBaseCurrencyFunc.
  ///
  /// In es, this message translates to:
  /// **'Divisa principal para la contabilidad de tu negocio.'**
  String get helpBaseCurrencyFunc;

  /// No description provided for @helpBaseCurrencyAffects.
  ///
  /// In es, this message translates to:
  /// **'Define la moneda del Capital de Trabajo y es la base de todos los reportes de rentabilidad.'**
  String get helpBaseCurrencyAffects;

  /// No description provided for @helpBaseCurrencyEx.
  ///
  /// In es, this message translates to:
  /// **'Si tu base es Córdobas, el sistema convertirá cualquier préstamo en otra moneda a Córdobas para darte un total global.'**
  String get helpBaseCurrencyEx;

  /// No description provided for @helpAvailableCapitalFunc.
  ///
  /// In es, this message translates to:
  /// **'Es el límite máximo de dinero propio asignado para préstamos.'**
  String get helpAvailableCapitalFunc;

  /// No description provided for @helpAvailableCapitalAffects.
  ///
  /// In es, this message translates to:
  /// **'Define el saldo disponible en tu \'techo\' de inversión.'**
  String get helpAvailableCapitalAffects;

  /// No description provided for @helpAvailableCapitalEx.
  ///
  /// In es, this message translates to:
  /// **'Si tienes 20,000 y prestas 10,000, el sistema indicará que solo te quedan 10,000 disponible.'**
  String get helpAvailableCapitalEx;

  /// No description provided for @helpValidateCapitalFunc.
  ///
  /// In es, this message translates to:
  /// **'Control de seguridad para no prestar más dinero del que tienes en caja.'**
  String get helpValidateCapitalFunc;

  /// No description provided for @helpValidateCapitalAffects.
  ///
  /// In es, this message translates to:
  /// **'Bloquea la creación de nuevos préstamos si el monto (convertido a moneda base) supera el capital disponible.'**
  String get helpValidateCapitalAffects;

  /// No description provided for @helpValidateCapitalEx.
  ///
  /// In es, this message translates to:
  /// **'Si solo te quedan C\$ 5,000 e intentas prestar \$200 USD (C\$ 7,400 aprox.), la app impedirá el registro.'**
  String get helpValidateCapitalEx;

  /// No description provided for @helpContractRatePolicyFunc.
  ///
  /// In es, this message translates to:
  /// **'Define si la tasa de cambio puede editarse manualmente al momento del desembolso.'**
  String get helpContractRatePolicyFunc;

  /// No description provided for @helpContractRatePolicyAffects.
  ///
  /// In es, this message translates to:
  /// **'Permite usar una tasa personalizada para un contrato específico en lugar de la tasa oficial del día.'**
  String get helpContractRatePolicyAffects;

  /// No description provided for @helpContractRatePolicyEx.
  ///
  /// In es, this message translates to:
  /// **'Si la tasa oficial es 36.60, pero acuerdas con el cliente usar 37.00, podrás ajustarlo manualmente si esta opción está activa.'**
  String get helpContractRatePolicyEx;

  /// No description provided for @helpPresentationCurrencyFunc.
  ///
  /// In es, this message translates to:
  /// **'Cambia la moneda en la que ves tus totales en el Dashboard.'**
  String get helpPresentationCurrencyFunc;

  /// No description provided for @helpPresentationCurrencyAffects.
  ///
  /// In es, this message translates to:
  /// **'Solo afecta la vista estética de los reportes; no altera los saldos reales de los clientes.'**
  String get helpPresentationCurrencyAffects;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Predeterminado del sistema'**
  String get languageSystem;

  /// No description provided for @selectReportType.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un tipo de reporte'**
  String get selectReportType;

  /// No description provided for @viewRealizedEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ver ganancias cobradas en el período'**
  String get viewRealizedEarnings;

  /// No description provided for @viewProjectedEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ver ingresos esperados por intereses'**
  String get viewProjectedEarnings;

  /// No description provided for @fxDifferentialReport.
  ///
  /// In es, this message translates to:
  /// **'Ganancias por Diferencial Cambiario'**
  String get fxDifferentialReport;

  /// No description provided for @fxDifferentialReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Reporte de Diferencial Cambiario'**
  String get fxDifferentialReportTitle;

  /// No description provided for @periodLabel.
  ///
  /// In es, this message translates to:
  /// **'Período'**
  String get periodLabel;

  /// No description provided for @periodFromTo.
  ///
  /// In es, this message translates to:
  /// **'Período: {startDate} al {endDate}'**
  String periodFromTo(String startDate, String endDate);

  /// No description provided for @periodSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen del período'**
  String get periodSummary;

  /// No description provided for @totalFxPayments.
  ///
  /// In es, this message translates to:
  /// **'Total pagos en moneda extranjera'**
  String get totalFxPayments;

  /// No description provided for @totalFxDifferential.
  ///
  /// In es, this message translates to:
  /// **'Total diferencial cambiario ganado'**
  String get totalFxDifferential;

  /// No description provided for @foreignCurrencyUsed.
  ///
  /// In es, this message translates to:
  /// **'Moneda extranjera utilizada'**
  String get foreignCurrencyUsed;

  /// No description provided for @operationsDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de operaciones'**
  String get operationsDetail;

  /// No description provided for @indicator.
  ///
  /// In es, this message translates to:
  /// **'Indicador'**
  String get indicator;

  /// No description provided for @value.
  ///
  /// In es, this message translates to:
  /// **'Valor'**
  String get value;

  /// No description provided for @totalEquivalentConverted.
  ///
  /// In es, this message translates to:
  /// **'Total equivalente convertido'**
  String get totalEquivalentConverted;

  /// No description provided for @totalAppliedToDebt.
  ///
  /// In es, this message translates to:
  /// **'Total aplicado a deuda'**
  String get totalAppliedToDebt;

  /// No description provided for @differentialProfit.
  ///
  /// In es, this message translates to:
  /// **'Ganancia por diferencial'**
  String get differentialProfit;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @client.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get client;

  /// No description provided for @loanLabel.
  ///
  /// In es, this message translates to:
  /// **'Préstamo'**
  String get loanLabel;

  /// No description provided for @receiptNo.
  ///
  /// In es, this message translates to:
  /// **'No. Recibo'**
  String get receiptNo;

  /// No description provided for @paymentCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda Pago'**
  String get paymentCurrency;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto Pago'**
  String get paymentAmountLabel;

  /// No description provided for @appliedRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa Aplicada'**
  String get appliedRate;

  /// No description provided for @equivalentCalculated.
  ///
  /// In es, this message translates to:
  /// **'Equivalente Calculado'**
  String get equivalentCalculated;

  /// No description provided for @amountAppliedToDebt.
  ///
  /// In es, this message translates to:
  /// **'Monto Aplicado a Deuda'**
  String get amountAppliedToDebt;

  /// No description provided for @fxDifferential.
  ///
  /// In es, this message translates to:
  /// **'Diferencial Cambiario'**
  String get fxDifferential;

  /// No description provided for @sharePdf.
  ///
  /// In es, this message translates to:
  /// **'Compartir PDF'**
  String get sharePdf;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Refrescar'**
  String get refresh;

  /// No description provided for @noFxOperations.
  ///
  /// In es, this message translates to:
  /// **'Sin operaciones cambiarias'**
  String get noFxOperations;

  /// No description provided for @noFxPaymentsInPeriod.
  ///
  /// In es, this message translates to:
  /// **'No hay pagos en moneda extranjera\nen el período seleccionado'**
  String get noFxPaymentsInPeriod;

  /// No description provided for @fxPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos en Divisas'**
  String get fxPayments;

  /// No description provided for @applied.
  ///
  /// In es, this message translates to:
  /// **'Aplicado'**
  String get applied;

  /// No description provided for @differentialProfit2.
  ///
  /// In es, this message translates to:
  /// **'Ganancia por Diferencial'**
  String get differentialProfit2;

  /// No description provided for @pdfGenerationError.
  ///
  /// In es, this message translates to:
  /// **'Error al generar PDF: {error}'**
  String pdfGenerationError(String error);

  /// No description provided for @shareReportText.
  ///
  /// In es, this message translates to:
  /// **'Reporte Diferencial Cambiario'**
  String get shareReportText;

  /// No description provided for @catalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get catalog;

  /// No description provided for @catalogDescription.
  ///
  /// In es, this message translates to:
  /// **'Gestionar listas y categorías'**
  String get catalogDescription;

  /// No description provided for @categorizeCustomerAs.
  ///
  /// In es, this message translates to:
  /// **'Categorías de Cliente'**
  String get categorizeCustomerAs;

  /// No description provided for @categorizeCustomerAsDesc.
  ///
  /// In es, this message translates to:
  /// **'Define categorías para clasificar a tus clientes'**
  String get categorizeCustomerAsDesc;

  /// No description provided for @customerCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías de Cliente'**
  String get customerCategories;

  /// No description provided for @addCategory.
  ///
  /// In es, this message translates to:
  /// **'Agregar Categoría'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In es, this message translates to:
  /// **'Editar Categoría'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Categoría'**
  String get deleteCategory;

  /// No description provided for @categoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Categoría'**
  String get categoryName;

  /// No description provided for @categoryColor.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get categoryColor;

  /// No description provided for @recoveryPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad en Recuperación'**
  String get recoveryPriority;

  /// No description provided for @recoveryPriorityDesc.
  ///
  /// In es, this message translates to:
  /// **'Define cómo se aplica el pago cuando se utiliza la opción \"Recuperar\".'**
  String get recoveryPriorityDesc;

  /// No description provided for @recoveryPriorityAffects.
  ///
  /// In es, this message translates to:
  /// **'Afecta el orden de reducción de la deuda en pagos de recuperación.'**
  String get recoveryPriorityAffects;

  /// No description provided for @recoveryPriorityEx.
  ///
  /// In es, this message translates to:
  /// **'Priorizar Capital: El pago reduce primero el capital prestado. Priorizar Interés: El pago reduce primero los intereses vencidos.'**
  String get recoveryPriorityEx;

  /// No description provided for @prioritizeCapital.
  ///
  /// In es, this message translates to:
  /// **'Priorizar Capital (Recomendado)'**
  String get prioritizeCapital;

  /// No description provided for @prioritizeInterest.
  ///
  /// In es, this message translates to:
  /// **'Priorizar Interés Vencido'**
  String get prioritizeInterest;

  /// No description provided for @categoryRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre de categoría es requerido'**
  String get categoryRequired;

  /// No description provided for @categoryCreated.
  ///
  /// In es, this message translates to:
  /// **'Categoría creada'**
  String get categoryCreated;

  /// No description provided for @categoryUpdated.
  ///
  /// In es, this message translates to:
  /// **'Categoría actualizada'**
  String get categoryUpdated;

  /// No description provided for @categoryDeleted.
  ///
  /// In es, this message translates to:
  /// **'Categoría eliminada'**
  String get categoryDeleted;

  /// No description provided for @categoryInUse.
  ///
  /// In es, this message translates to:
  /// **'Categoría en uso'**
  String get categoryInUse;

  /// No description provided for @categoryInUseByOne.
  ///
  /// In es, this message translates to:
  /// **'Esta categoría está asignada a {customerName}. Quítala del cliente antes de eliminarla.'**
  String categoryInUseByOne(String customerName);

  /// No description provided for @categoryInUseByMany.
  ///
  /// In es, this message translates to:
  /// **'Esta categoría está asignada a {count} clientes. Quítala de todos los clientes antes de eliminarla.'**
  String categoryInUseByMany(int count);

  /// No description provided for @noCategories.
  ///
  /// In es, this message translates to:
  /// **'Sin categorías'**
  String get noCategories;

  /// No description provided for @noCategoriesHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega categorías para clasificar a tus clientes'**
  String get noCategoriesHint;

  /// No description provided for @customerCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get customerCategory;

  /// No description provided for @selectCategory.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría'**
  String get selectCategory;

  /// No description provided for @optional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get optional;

  /// No description provided for @rateThisCustomer.
  ///
  /// In es, this message translates to:
  /// **'Calificar a este cliente'**
  String get rateThisCustomer;

  /// No description provided for @rateCustomerPrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Desea calificar a este cliente como?'**
  String get rateCustomerPrompt;

  /// No description provided for @notNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notNow;

  /// No description provided for @rateCustomer.
  ///
  /// In es, this message translates to:
  /// **'Calificar'**
  String get rateCustomer;

  /// No description provided for @mustSelectCategory.
  ///
  /// In es, this message translates to:
  /// **'Debe seleccionar una categoría'**
  String get mustSelectCategory;

  /// No description provided for @customerRated.
  ///
  /// In es, this message translates to:
  /// **'Cliente calificado exitosamente'**
  String get customerRated;

  /// No description provided for @good.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get good;

  /// No description provided for @veryGood.
  ///
  /// In es, this message translates to:
  /// **'Muy bueno'**
  String get veryGood;

  /// No description provided for @regular.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @doNotLend.
  ///
  /// In es, this message translates to:
  /// **'No prestar'**
  String get doNotLend;

  /// No description provided for @bad.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get bad;

  /// No description provided for @paymentSuccess.
  ///
  /// In es, this message translates to:
  /// **'Pago registrado exitosamente'**
  String get paymentSuccess;

  /// No description provided for @catalogInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es el Catálogo?'**
  String get catalogInfoTitle;

  /// No description provided for @catalogInfoDescription.
  ///
  /// In es, this message translates to:
  /// **'El catálogo permite crear categorías personalizadas para clasificar a tus clientes (ej. Bueno, Regular, No Prestar).\n\nCon las categorías asignadas a los clientes, podrás:\n• Identificar rápidamente el tipo de cada cliente\n• Generar reportes filtrados por categoría\n• Tomar mejores decisiones de crédito basadas en el historial'**
  String get catalogInfoDescription;

  /// No description provided for @colorSelector.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get colorSelector;

  /// No description provided for @selectColor.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar color'**
  String get selectColor;

  /// No description provided for @customColor.
  ///
  /// In es, this message translates to:
  /// **'Color personalizado'**
  String get customColor;

  /// No description provided for @paymentFrequencies.
  ///
  /// In es, this message translates to:
  /// **'Frecuencias de Pago'**
  String get paymentFrequencies;

  /// No description provided for @paymentFrequenciesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar frecuencias de cobro (Diario, Semanal, etc)'**
  String get paymentFrequenciesSubtitle;

  /// No description provided for @newFrequency.
  ///
  /// In es, this message translates to:
  /// **'Nueva Frecuencia'**
  String get newFrequency;

  /// No description provided for @editFrequency.
  ///
  /// In es, this message translates to:
  /// **'Editar Frecuencia'**
  String get editFrequency;

  /// No description provided for @frequencyName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get frequencyName;

  /// No description provided for @frequencyNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Mensual, Quincenal'**
  String get frequencyNameHint;

  /// No description provided for @daysInterval.
  ///
  /// In es, this message translates to:
  /// **'Intervalo (Días)'**
  String get daysInterval;

  /// No description provided for @daysIntervalHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 30'**
  String get daysIntervalHint;

  /// No description provided for @cantEditDefaultInterval.
  ///
  /// In es, this message translates to:
  /// **'No se puede editar el intervalo de frecuencias predeterminadas'**
  String get cantEditDefaultInterval;

  /// No description provided for @deactivateFrequencyConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Desactivar esta frecuencia?'**
  String get deactivateFrequencyConfirm;

  /// No description provided for @activeFrequency.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get activeFrequency;

  /// No description provided for @inactiveFrequency.
  ///
  /// In es, this message translates to:
  /// **'Inactiva'**
  String get inactiveFrequency;

  /// No description provided for @validationFrequencyInUse.
  ///
  /// In es, this message translates to:
  /// **'Esta frecuencia está en uso por préstamos activos y no puede ser modificada/eliminada'**
  String get validationFrequencyInUse;

  /// No description provided for @deleteFrequencyConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta frecuencia?'**
  String get deleteFrequencyConfirm;

  /// No description provided for @paymentFrequenciesInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué son las Frecuencias?'**
  String get paymentFrequenciesInfoTitle;

  /// No description provided for @paymentFrequenciesInfoDescription.
  ///
  /// In es, this message translates to:
  /// **'Define los periodos de tiempo para los cobros (ej. diario, quincenal, 20 días).\nPuedes crear frecuencias personalizadas con intervalos de días específicos para adaptarse a tus préstamos.'**
  String get paymentFrequenciesInfoDescription;

  /// No description provided for @freqAnnually.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get freqAnnually;

  /// No description provided for @selectFrequency.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Frecuencia'**
  String get selectFrequency;

  /// No description provided for @searchFrequency.
  ///
  /// In es, this message translates to:
  /// **'Buscar frecuencia...'**
  String get searchFrequency;

  /// No description provided for @sortBy.
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get sortBy;

  /// No description provided for @sortByName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get sortByName;

  /// No description provided for @sortByDays.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get sortByDays;

  /// No description provided for @noFrequenciesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron frecuencias'**
  String get noFrequenciesFound;

  /// No description provided for @planTerm.
  ///
  /// In es, this message translates to:
  /// **'Plazo'**
  String get planTerm;

  /// No description provided for @planTermUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad de Plazo'**
  String get planTermUnit;

  /// No description provided for @termDays.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get termDays;

  /// No description provided for @termWeeks.
  ///
  /// In es, this message translates to:
  /// **'Semanas'**
  String get termWeeks;

  /// No description provided for @termMonths.
  ///
  /// In es, this message translates to:
  /// **'Meses'**
  String get termMonths;

  /// No description provided for @termYears.
  ///
  /// In es, this message translates to:
  /// **'Años'**
  String get termYears;

  /// No description provided for @calculatedInstallments.
  ///
  /// In es, this message translates to:
  /// **'Cuotas Calculadas: {count}'**
  String calculatedInstallments(int count);

  /// No description provided for @calculatedInstallmentsWarning.
  ///
  /// In es, this message translates to:
  /// **'Advertencia: El plazo no es múltiplo exacto de la frecuencia. Se ajustará a {count} cuotas.'**
  String calculatedInstallmentsWarning(int count);

  /// No description provided for @applicableCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías Aplicables'**
  String get applicableCategories;

  /// No description provided for @allCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas las Categorías'**
  String get allCategories;

  /// No description provided for @selectCategories.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Categorías'**
  String get selectCategories;

  /// No description provided for @distributeCapitalInterestTooltip.
  ///
  /// In es, this message translates to:
  /// **'Si se activa, la cuota calculada incluirá capital e interés amortizado. Si se desactiva, el cobro por ciclo será solo interés.'**
  String get distributeCapitalInterestTooltip;

  /// No description provided for @periodStartsOnDisbursementTooltip.
  ///
  /// In es, this message translates to:
  /// **'Activo: La fecha de inicio es la fecha de desembolso. Inactivo: Debe seleccionar fecha de inicio manual.'**
  String get periodStartsOnDisbursementTooltip;

  /// No description provided for @paymentPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes de Pago'**
  String get paymentPlans;

  /// No description provided for @paymentPlansSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar planes preconfigurados para préstamos'**
  String get paymentPlansSubtitle;

  /// No description provided for @noPaymentPlans.
  ///
  /// In es, this message translates to:
  /// **'No hay planes de pago'**
  String get noPaymentPlans;

  /// No description provided for @addPaymentPlanHint.
  ///
  /// In es, this message translates to:
  /// **'Presiona el botón + para agregar un plan'**
  String get addPaymentPlanHint;

  /// No description provided for @newPaymentPlan.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Plan de Pago'**
  String get newPaymentPlan;

  /// No description provided for @editPaymentPlan.
  ///
  /// In es, this message translates to:
  /// **'Editar Plan de Pago'**
  String get editPaymentPlan;

  /// No description provided for @planName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Plan'**
  String get planName;

  /// No description provided for @installments.
  ///
  /// In es, this message translates to:
  /// **'cuotas'**
  String get installments;

  /// No description provided for @installmentsTotal.
  ///
  /// In es, this message translates to:
  /// **'Total de Cuotas'**
  String get installmentsTotal;

  /// No description provided for @minAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto Mínimo'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto Máximo'**
  String get maxAmount;

  /// No description provided for @days.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get days;

  /// No description provided for @distributeCapitalInterest.
  ///
  /// In es, this message translates to:
  /// **'Distribuir Capital e Interés'**
  String get distributeCapitalInterest;

  /// No description provided for @distributeCapitalInterestDesc.
  ///
  /// In es, this message translates to:
  /// **'Calcular cuotas fijas con capital + interés distribuido'**
  String get distributeCapitalInterestDesc;

  /// No description provided for @periodStartsOnDisbursement.
  ///
  /// In es, this message translates to:
  /// **'Período inicia al desembolsar'**
  String get periodStartsOnDisbursement;

  /// No description provided for @periodStartsOnDisbursementDesc.
  ///
  /// In es, this message translates to:
  /// **'La fecha de desembolso se autocompleta con la fecha actual'**
  String get periodStartsOnDisbursementDesc;

  /// No description provided for @allowCurrencyChange.
  ///
  /// In es, this message translates to:
  /// **'Permitir cambiar moneda en préstamo'**
  String get allowCurrencyChange;

  /// No description provided for @activate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get deactivate;

  /// No description provided for @cannotDeactivatePlanWithLoans.
  ///
  /// In es, this message translates to:
  /// **'No se puede desactivar un plan con préstamos activos'**
  String get cannotDeactivatePlanWithLoans;

  /// No description provided for @cannotDeletePlanWithLoans.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar un plan con préstamos activos'**
  String get cannotDeletePlanWithLoans;

  /// No description provided for @deletePlanConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de eliminar este plan de pago?'**
  String get deletePlanConfirmation;

  /// No description provided for @scheduledBackupTitle.
  ///
  /// In es, this message translates to:
  /// **'Respaldo Programado'**
  String get scheduledBackupTitle;

  /// No description provided for @frequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get frequency;

  /// No description provided for @disabled.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get disabled;

  /// No description provided for @preferredTime.
  ///
  /// In es, this message translates to:
  /// **'Hora Preferida'**
  String get preferredTime;

  /// No description provided for @automaticTriggers.
  ///
  /// In es, this message translates to:
  /// **'Disparadores Automáticos'**
  String get automaticTriggers;

  /// No description provided for @backupSettingsSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración de respaldo guardada'**
  String get backupSettingsSaved;

  /// No description provided for @reportCurrencyDialogDesc.
  ///
  /// In es, this message translates to:
  /// **'Moneda utilizada para reportes financieros'**
  String get reportCurrencyDialogDesc;

  /// No description provided for @reportCurrencyInfoBanner.
  ///
  /// In es, this message translates to:
  /// **'Los reportes se mostrarán en esta moneda'**
  String get reportCurrencyInfoBanner;

  /// No description provided for @tapToChange.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar'**
  String get tapToChange;

  /// No description provided for @exchangeRateTitle.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Cambio'**
  String get exchangeRateTitle;

  /// No description provided for @invalidRateError.
  ///
  /// In es, this message translates to:
  /// **'Tasa inválida'**
  String get invalidRateError;

  /// No description provided for @saveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get saveButton;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get requiredField;

  /// No description provided for @scheduledBackupDesc.
  ///
  /// In es, this message translates to:
  /// **'Configura copias de seguridad automáticas'**
  String get scheduledBackupDesc;

  /// No description provided for @interestFirst.
  ///
  /// In es, this message translates to:
  /// **'Interés Primero'**
  String get interestFirst;

  /// No description provided for @principalFirst.
  ///
  /// In es, this message translates to:
  /// **'Capital Primero'**
  String get principalFirst;

  /// No description provided for @noBackupsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay respaldos disponibles'**
  String get noBackupsAvailable;

  /// No description provided for @settingsSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada'**
  String get settingsSaved;

  /// No description provided for @invalidExchangeRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de cambio inválida'**
  String get invalidExchangeRate;

  /// No description provided for @selectPlan.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Plan'**
  String get selectPlan;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
