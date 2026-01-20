import 'package:equatable/equatable.dart';

/// AppSettings model - Global configuration (1 row)
class AppSettings extends Equatable {
  /// Crea una instancia de [AppSettings] con la configuración global.
  const AppSettings({
    required this.createdAt,
    required this.updatedAt,
    this.settingsId = 'global',
    this.baseCurrency = 'NIO',
    this.capitalizeUnpaidInterest = false,
    this.moratoriumDays = 1,
    this.paymentApplyOrder = 'INTEREST_FIRST',
    this.deriveBiweeklyRate = true,
    this.receiptNextNumber = '1',
    this.loanNextNumber = '1',
    this.availableCapital = 0,
    this.validateCapital = false,
    this.dailyAccrualEnabled = false,
    this.allowMultipleLoans = false,
    this.validateDni = false,
    this.validateDniFormat = false,
    this.dniMask,
    this.companyName,
    this.showCompanyName = false,
    this.companyRuc,
    this.showCompanyRuc = false,
    this.companyPhone,
    this.showCompanyPhone = false,
    this.companyCell,
    this.showCompanyCell = false,
    this.companyWhatsapp,
    this.showCompanyWhatsapp = false,
    this.companyAddress,
    this.showCompanyAddress = false,
    this.companyLogoPath,
    this.showCompanyLogo = false,
    this.backupPath,
    this.shareReceiptsWhatsApp = false,
    this.companyCountryCode,
    this.showDisbursementSignatures = true,
    this.showPaymentSignatures = true,
    this.disbursementLegend,
    this.showDisbursementLegend = false,
    this.paymentLegend,
    this.showPaymentLegend = false,
    this.enableCapitalRestriction = true,
    this.capitalRestrictionDays = 10,
    this.reportCurrency = 'NIO',
    this.exchangeRate = 1.0,
    this.backupFrequency = 'NONE',
    this.backupRetentionDays = 30,
    this.backupOnLoanCreation = false,
    this.backupOnPayment = false,
    this.backupScheduleTime,
    this.backupCustomName,
    this.backupRetries = 3,
    this.allowManualExchangeRate = false,
    this.disbursementRateType = 'SELL',
    this.paymentRateType = 'BUY',
    this.recoveryPriority = 'CAPITAL_FIRST',
    this.collectionPlanDays = 3,
  });

  /// Create default settings
  factory AppSettings.defaults() {
    final now = DateTime.now();
    return AppSettings(createdAt: now, updatedAt: now);
  }

  /// Create from database map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      settingsId: map['settings_id'] as String? ?? 'global',
      baseCurrency: map['base_currency'] as String? ?? 'NIO',
      capitalizeUnpaidInterest:
          (map['capitalize_unpaid_interest'] as int? ?? 0) == 1,
      moratoriumDays: map['moratorium_days'] as int? ?? 1,
      paymentApplyOrder:
          map['payment_apply_order'] as String? ?? 'INTEREST_FIRST',
      deriveBiweeklyRate: (map['derive_biweekly_rate'] as int? ?? 1) == 1,
      receiptNextNumber: map['receipt_next_number']?.toString() ?? '1',
      loanNextNumber: map['loan_next_number']?.toString() ?? '1',
      availableCapital: (map['available_capital'] as num?)?.toDouble() ?? 0,
      validateCapital: (map['validate_capital'] as int? ?? 0) == 1,
      dailyAccrualEnabled: (map['daily_accrual_enabled'] as int? ?? 0) == 1,
      allowMultipleLoans: (map['allow_multiple_loans'] as int? ?? 0) == 1,
      validateDni: (map['validate_dni'] as int? ?? 0) == 1,
      validateDniFormat: (map['validate_dni_format'] as int? ?? 0) == 1,
      dniMask: map['dni_mask'] as String?,
      companyName: map['company_name'] as String?,
      showCompanyName: (map['show_company_name'] as int? ?? 0) == 1,
      companyRuc: map['company_ruc'] as String?,
      showCompanyRuc: (map['show_company_ruc'] as int? ?? 0) == 1,
      companyPhone: map['company_phone'] as String?,
      showCompanyPhone: (map['show_company_phone'] as int? ?? 0) == 1,
      companyCell: map['company_cell'] as String?,
      showCompanyCell: (map['show_company_cell'] as int? ?? 0) == 1,
      companyWhatsapp: map['company_whatsapp'] as String?,
      showCompanyWhatsapp: (map['show_company_whatsapp'] as int? ?? 0) == 1,
      companyAddress: map['company_address'] as String?,
      showCompanyAddress: (map['show_company_address'] as int? ?? 0) == 1,
      companyLogoPath: map['company_logo_path'] as String?,
      showCompanyLogo: (map['show_company_logo'] as int? ?? 0) == 1,
      backupPath: map['backup_path'] as String?,
      shareReceiptsWhatsApp: (map['share_receipts_whatsapp'] as int? ?? 0) == 1,
      companyCountryCode: map['company_country_code'] as String?,
      showDisbursementSignatures:
          (map['show_disbursement_signatures'] as int? ?? 1) == 1,
      showPaymentSignatures: (map['show_payment_signatures'] as int? ?? 1) == 1,
      disbursementLegend: map['disbursement_legend'] as String?,
      showDisbursementLegend:
          (map['show_disbursement_legend'] as int? ?? 0) == 1,
      paymentLegend: map['payment_legend'] as String?,
      showPaymentLegend: (map['show_payment_legend'] as int? ?? 0) == 1,
      enableCapitalRestriction:
          (map['enable_capital_restriction'] as int? ?? 1) == 1,
      capitalRestrictionDays: map['capital_restriction_days'] as int? ?? 10,
      reportCurrency: map['report_currency'] as String? ?? 'NIO',
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      backupFrequency: map['backup_frequency'] as String? ?? 'NONE',
      backupRetentionDays: map['backup_retention_days'] as int? ?? 30,
      backupOnLoanCreation: (map['backup_on_loan_creation'] as int? ?? 0) == 1,
      backupOnPayment: (map['backup_on_payment'] as int? ?? 0) == 1,
      backupScheduleTime: map['backup_schedule_time'] as String?,
      backupCustomName: map['backup_custom_name'] as String?,
      backupRetries: map['backup_retries'] as int? ?? 3,
      allowManualExchangeRate:
          (map['allow_manual_exchange_rate'] as int? ?? 0) == 1,
      disbursementRateType: map['disbursement_rate_type'] as String? ?? 'SELL',
      paymentRateType: map['payment_rate_type'] as String? ?? 'BUY',
      recoveryPriority: map['recovery_priority'] as String? ?? 'CAPITAL_FIRST',
      collectionPlanDays: map['collection_plan_days'] as int? ?? 3,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Identificador único de los ajustes (normalmente 'global').
  final String settingsId;

  /// Código de la moneda base del sistema (ej: 'NIO').
  final String baseCurrency;

  /// Indica si se debe capitalizar el interés no pagado al final del ciclo.
  final bool capitalizeUnpaidInterest;

  /// Días de gracia antes de considerar un pago en mora.
  final int moratoriumDays;

  /// Orden de aplicación de los pagos (ej: 'INTEREST_FIRST').
  final String paymentApplyOrder;

  /// Indica si la tasa quincenal se deriva simplemente dividiendo la mensual.
  final bool deriveBiweeklyRate;

  /// Siguiente número de recibo a generar.
  final String receiptNextNumber;

  /// Siguiente número de préstamo a generar.
  final String loanNextNumber;

  /// Capital total disponible para prestar.
  final double availableCapital;

  /// Indica si se debe validar que haya capital disponible antes de prestar.
  final bool validateCapital;

  /// Indica si el devengo de intereses es diario.
  final bool dailyAccrualEnabled;

  /// Permite que un cliente tenga más de un préstamo activo.
  final bool allowMultipleLoans;

  /// Indica si es obligatorio validar el DNI del cliente.
  final bool validateDni;

  /// Indica si se debe validar el formato del DNI.
  final bool validateDniFormat;

  /// Máscara de formato para el DNI.
  final String? dniMask;

  /// Nombre de la empresa o prestamista.
  final String? companyName;

  /// Indica si se muestra el nombre de la empresa en documentos.
  final bool showCompanyName;

  /// RUC de la empresa.
  final String? companyRuc;

  /// Indica si se muestra el RUC en documentos.
  final bool showCompanyRuc;

  /// Teléfono fijo de la empresa.
  final String? companyPhone;

  /// Indica si se muestra el teléfono fijo en documentos.
  final bool showCompanyPhone;

  /// Celular de la empresa.
  final String? companyCell;

  /// Indica si se muestra el celular en documentos.
  final bool showCompanyCell;

  /// WhatsApp de contacto de la empresa.
  final String? companyWhatsapp;

  /// Indica si se muestra el WhatsApp en documentos.
  final bool showCompanyWhatsapp;

  /// Dirección física de la empresa.
  final String? companyAddress;

  /// Indica si se muestra la dirección en documentos.
  final bool showCompanyAddress;

  /// Ruta al logo de la empresa.
  final String? companyLogoPath;

  /// Indica si se muestra el logo en documentos.
  final bool showCompanyLogo;

  /// Ruta base para los respaldos de base de datos.
  final String? backupPath;

  /// Indica si se deben compartir los recibos por WhatsApp automáticamente.
  final bool shareReceiptsWhatsApp;

  /// Código de país de la empresa (para WhatsApp/formatos).
  final String? companyCountryCode;

  // Report settings
  /// Indica si se muestran firmas en el documento de desembolso.
  final bool showDisbursementSignatures;

  /// Indica si se muestran firmas en el recibo de pago.
  final bool showPaymentSignatures;

  /// Leyenda legal o aclaratoria para desembolsos.
  final String? disbursementLegend;

  /// Indica si se muestra la leyenda en desembolsos.
  final bool showDisbursementLegend;

  /// Leyenda legal para recibos de pago.
  final String? paymentLegend;

  /// Indica si se muestra la leyenda en pagos.
  final bool showPaymentLegend;

  // Capital Payment Restriction
  /// Indica si está habilitada la restricción de pagos a capital.
  final bool enableCapitalRestriction;

  /// Días mínimos de antigüedad del préstamo para permitir abonos a capital.
  final int capitalRestrictionDays;

  // Report Currency Settings (for prestamista reports)
  /// Código de moneda para reportes financieros (ej: 'USD').
  final String reportCurrency;

  /// Tasa de cambio: 1 unidad de [reportCurrency] equivale a X unidades de base.
  final double exchangeRate;

  // Scheduled Backup Settings
  /// Frecuencia de respaldos automáticos ('DAILY', 'WEEKLY', etc).
  final String backupFrequency;

  /// Días de retención para archivos de respaldo antiguos.
  final int backupRetentionDays;

  /// Indica si se debe respaldar al crear un nuevo préstamo.
  final bool backupOnLoanCreation;

  /// Indica si se debe respaldar al registrar un pago.
  final bool backupOnPayment;

  /// Hora programada para el respaldo automático (HH:MM).
  final String? backupScheduleTime;

  /// Prefijo para el nombre de los archivos de respaldo.
  final String? backupCustomName;

  /// Cantidad de reintentos en caso de fallo del respaldo.
  final int backupRetries;

  /// Permite ingresar una tasa de cambio manual en transacciones.
  final bool allowManualExchangeRate;

  // Rate Type Configuration (Buy vs Sell)
  /// Tipo de tasa para desembolsos ('BUY', 'SELL', 'MID').
  final String disbursementRateType;

  /// Tipo de tasa para cobros de pagos ('BUY', 'SELL', 'MID').
  final String paymentRateType;

  // Recovery Priority
  /// Prioridad de recuperación de saldo ('CAPITAL_FIRST' o 'INTEREST_FIRST').
  final String recoveryPriority;

  /// Días de antelación para planificar cobros en pantalla 'A Cobrar'.
  final int collectionPlanDays;

  /// Fecha de creación de la configuración.
  final DateTime createdAt;

  /// Fecha de última modificación de los ajustes.
  final DateTime updatedAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'settings_id': settingsId,
      'base_currency': baseCurrency,
      'capitalize_unpaid_interest': capitalizeUnpaidInterest ? 1 : 0,
      'moratorium_days': moratoriumDays,
      'payment_apply_order': paymentApplyOrder,
      'derive_biweekly_rate': deriveBiweeklyRate ? 1 : 0,
      'receipt_next_number': receiptNextNumber,
      'loan_next_number': loanNextNumber,
      'available_capital': availableCapital,
      'validate_capital': validateCapital ? 1 : 0,
      'daily_accrual_enabled': dailyAccrualEnabled ? 1 : 0,
      'allow_multiple_loans': allowMultipleLoans ? 1 : 0,
      'validate_dni': validateDni ? 1 : 0,
      'validate_dni_format': validateDniFormat ? 1 : 0,
      'dni_mask': dniMask,
      'company_name': companyName,
      'show_company_name': showCompanyName ? 1 : 0,
      'company_ruc': companyRuc,
      'show_company_ruc': showCompanyRuc ? 1 : 0,
      'company_phone': companyPhone,
      'show_company_phone': showCompanyPhone ? 1 : 0,
      'company_cell': companyCell,
      'show_company_cell': showCompanyCell ? 1 : 0,
      'company_whatsapp': companyWhatsapp,
      'show_company_whatsapp': showCompanyWhatsapp ? 1 : 0,
      'company_address': companyAddress,
      'show_company_address': showCompanyAddress ? 1 : 0,
      'company_logo_path': companyLogoPath,
      'show_company_logo': showCompanyLogo ? 1 : 0,
      'backup_path': backupPath,
      'share_receipts_whatsapp': shareReceiptsWhatsApp ? 1 : 0,
      'company_country_code': companyCountryCode,
      'show_disbursement_signatures': showDisbursementSignatures ? 1 : 0,
      'show_payment_signatures': showPaymentSignatures ? 1 : 0,
      'disbursement_legend': disbursementLegend,
      'show_disbursement_legend': showDisbursementLegend ? 1 : 0,
      'payment_legend': paymentLegend,
      'show_payment_legend': showPaymentLegend ? 1 : 0,
      'enable_capital_restriction': enableCapitalRestriction ? 1 : 0,
      'capital_restriction_days': capitalRestrictionDays,
      'report_currency': reportCurrency,
      'exchange_rate': exchangeRate,
      'backup_frequency': backupFrequency,
      'backup_retention_days': backupRetentionDays,
      'backup_on_loan_creation': backupOnLoanCreation ? 1 : 0,
      'backup_on_payment': backupOnPayment ? 1 : 0,
      'backup_schedule_time': backupScheduleTime,
      'backup_custom_name': backupCustomName,
      'backup_retries': backupRetries,
      'allow_manual_exchange_rate': allowManualExchangeRate ? 1 : 0,
      'disbursement_rate_type': disbursementRateType,
      'payment_rate_type': paymentRateType,
      'recovery_priority': recoveryPriority,
      'collection_plan_days': collectionPlanDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  AppSettings copyWith({
    String? baseCurrency,
    bool? capitalizeUnpaidInterest,
    int? moratoriumDays,
    String? paymentApplyOrder,
    bool? deriveBiweeklyRate,
    String? receiptNextNumber,
    String? loanNextNumber,
    double? availableCapital,
    bool? validateCapital,
    bool? dailyAccrualEnabled,
    bool? allowMultipleLoans,
    bool? validateDni,
    bool? validateDniFormat,
    String? dniMask,
    String? companyName,
    bool? showCompanyName,
    String? companyRuc,
    bool? showCompanyRuc,
    String? companyPhone,
    bool? showCompanyPhone,
    String? companyCell,
    bool? showCompanyCell,
    String? companyWhatsapp,
    bool? showCompanyWhatsapp,
    String? companyAddress,
    bool? showCompanyAddress,
    String? companyLogoPath,
    bool? showCompanyLogo,
    String? backupPath,
    bool? shareReceiptsWhatsApp,
    String? companyCountryCode,
    bool? showDisbursementSignatures,
    bool? showPaymentSignatures,
    String? disbursementLegend,
    bool? showDisbursementLegend,
    String? paymentLegend,
    bool? showPaymentLegend,
    bool? enableCapitalRestriction,
    int? capitalRestrictionDays,
    String? reportCurrency,
    double? exchangeRate,
    String? backupFrequency,
    int? backupRetentionDays,
    bool? backupOnLoanCreation,
    bool? backupOnPayment,
    String? backupScheduleTime,
    String? backupCustomName,
    int? backupRetries,
    bool? allowManualExchangeRate,
    String? disbursementRateType,
    String? paymentRateType,
    String? recoveryPriority,
    int? collectionPlanDays,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      settingsId: settingsId,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      capitalizeUnpaidInterest:
          capitalizeUnpaidInterest ?? this.capitalizeUnpaidInterest,
      moratoriumDays: moratoriumDays ?? this.moratoriumDays,
      paymentApplyOrder: paymentApplyOrder ?? this.paymentApplyOrder,
      deriveBiweeklyRate: deriveBiweeklyRate ?? this.deriveBiweeklyRate,
      receiptNextNumber: receiptNextNumber ?? this.receiptNextNumber,
      loanNextNumber: loanNextNumber ?? this.loanNextNumber,
      availableCapital: availableCapital ?? this.availableCapital,
      validateCapital: validateCapital ?? this.validateCapital,
      dailyAccrualEnabled: dailyAccrualEnabled ?? this.dailyAccrualEnabled,
      allowMultipleLoans: allowMultipleLoans ?? this.allowMultipleLoans,
      validateDni: validateDni ?? this.validateDni,
      validateDniFormat: validateDniFormat ?? this.validateDniFormat,
      dniMask: dniMask ?? this.dniMask,
      companyName: companyName ?? this.companyName,
      showCompanyName: showCompanyName ?? this.showCompanyName,
      companyRuc: companyRuc ?? this.companyRuc,
      showCompanyRuc: showCompanyRuc ?? this.showCompanyRuc,
      companyPhone: companyPhone ?? this.companyPhone,
      showCompanyPhone: showCompanyPhone ?? this.showCompanyPhone,
      companyCell: companyCell ?? this.companyCell,
      showCompanyCell: showCompanyCell ?? this.showCompanyCell,
      companyWhatsapp: companyWhatsapp ?? this.companyWhatsapp,
      showCompanyWhatsapp: showCompanyWhatsapp ?? this.showCompanyWhatsapp,
      companyAddress: companyAddress ?? this.companyAddress,
      showCompanyAddress: showCompanyAddress ?? this.showCompanyAddress,
      companyLogoPath: companyLogoPath ?? this.companyLogoPath,
      showCompanyLogo: showCompanyLogo ?? this.showCompanyLogo,
      backupPath: backupPath ?? this.backupPath,
      shareReceiptsWhatsApp:
          shareReceiptsWhatsApp ?? this.shareReceiptsWhatsApp,
      companyCountryCode: companyCountryCode ?? this.companyCountryCode,
      showDisbursementSignatures:
          showDisbursementSignatures ?? this.showDisbursementSignatures,
      showPaymentSignatures:
          showPaymentSignatures ?? this.showPaymentSignatures,
      disbursementLegend: disbursementLegend ?? this.disbursementLegend,
      showDisbursementLegend:
          showDisbursementLegend ?? this.showDisbursementLegend,
      paymentLegend: paymentLegend ?? this.paymentLegend,
      showPaymentLegend: showPaymentLegend ?? this.showPaymentLegend,
      enableCapitalRestriction:
          enableCapitalRestriction ?? this.enableCapitalRestriction,
      capitalRestrictionDays:
          capitalRestrictionDays ?? this.capitalRestrictionDays,
      reportCurrency: reportCurrency ?? this.reportCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupRetentionDays: backupRetentionDays ?? this.backupRetentionDays,
      backupOnLoanCreation: backupOnLoanCreation ?? this.backupOnLoanCreation,
      backupOnPayment: backupOnPayment ?? this.backupOnPayment,
      backupScheduleTime: backupScheduleTime ?? this.backupScheduleTime,
      backupCustomName: backupCustomName ?? this.backupCustomName,
      backupRetries: backupRetries ?? this.backupRetries,
      allowManualExchangeRate:
          allowManualExchangeRate ?? this.allowManualExchangeRate,
      disbursementRateType: disbursementRateType ?? this.disbursementRateType,
      paymentRateType: paymentRateType ?? this.paymentRateType,
      recoveryPriority: recoveryPriority ?? this.recoveryPriority,
      collectionPlanDays: collectionPlanDays ?? this.collectionPlanDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get remaining capital (available - used)
  /// Calcula el capital restante disponible para prestar.
  double getRemainingCapital(double capitalColocado) {
    if (availableCapital <= 0) return double.infinity;
    return availableCapital - capitalColocado;
  }

  @override
  List<Object?> get props => [
    settingsId,
    baseCurrency,
    capitalizeUnpaidInterest,
    moratoriumDays,
    paymentApplyOrder,
    deriveBiweeklyRate,
    receiptNextNumber,
    loanNextNumber,
    availableCapital,
    validateCapital,
    dailyAccrualEnabled,
    allowMultipleLoans,
    validateDni,
    validateDniFormat,
    dniMask,
    companyName,
    showCompanyName,
    companyRuc,
    showCompanyRuc,
    companyPhone,
    showCompanyPhone,
    companyCell,
    showCompanyCell,
    companyWhatsapp,
    showCompanyWhatsapp,
    companyAddress,
    showCompanyAddress,
    companyLogoPath,
    showCompanyLogo,
    backupPath,
    shareReceiptsWhatsApp,
    companyCountryCode,
    showDisbursementSignatures,
    showPaymentSignatures,
    disbursementLegend,
    showDisbursementLegend,
    paymentLegend,
    showPaymentLegend,
    enableCapitalRestriction,
    capitalRestrictionDays,
    reportCurrency,
    exchangeRate,
    backupFrequency,
    backupRetentionDays,
    backupOnLoanCreation,
    backupOnPayment,
    backupScheduleTime,
    backupCustomName,
    backupRetries,
    allowManualExchangeRate,
    disbursementRateType,
    paymentRateType,
    recoveryPriority,
    collectionPlanDays,
    createdAt,
    updatedAt,
  ];
}
