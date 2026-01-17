import 'package:equatable/equatable.dart';

/// AuditLog model - General audit trail
class AuditLog extends Equatable {
  /// Crea un [AuditLog] para registrar una acción en el rastro de auditoría.
  const AuditLog({
    required this.auditLogId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.details,
  });

  /// Create from database map
  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      auditLogId: map['audit_log_id'] as String,
      action: map['action'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      details: map['details'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Identificador único del log de auditoría.
  final String auditLogId;

  /// Acción realizada (ej: 'CREATE_CUSTOMER').
  final String action;

  /// Tipo de entidad afectada (ej: 'Customer').
  final String entityType;

  /// Identificador de la entidad afectada.
  final String entityId;

  /// Detalles adicionales en formato JSON o texto.
  final String? details;

  /// Fecha y hora en que ocurrió el evento.
  final DateTime createdAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'audit_log_id': auditLogId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    auditLogId,
    action,
    entityType,
    entityId,
    details,
    createdAt,
  ];
}

/// Audit action constants
class AuditAction {
  AuditAction._();

  /// Creación de un nuevo cliente.
  static const String createCustomer = 'CREATE_CUSTOMER';

  /// Actualización de datos de un cliente.
  static const String updateCustomer = 'UPDATE_CUSTOMER';

  /// Otorgamiento de un nuevo préstamo.
  static const String createLoan = 'CREATE_LOAN';

  /// Cierre o liquidación de un préstamo.
  static const String closeLoan = 'CLOSE_LOAN';

  /// Registro de un nuevo pago.
  static const String recordPayment = 'RECORD_PAYMENT';

  /// Anulación de un pago existente.
  static const String voidPayment = 'VOID_PAYMENT';

  /// Capitalización de intereses pendientes.
  static const String capitalizeInterest = 'CAPITALIZE_INTEREST';

  /// Cambio en la configuración global de la app.
  static const String updateSettings = 'UPDATE_SETTINGS';

  /// Restauración de una copia de seguridad.
  static const String restoreBackup = 'RESTORE_BACKUP';
}

/// Entity type constants
class EntityType {
  EntityType._();

  /// Entidad de tipo Cliente.
  static const String customer = 'Customer';

  /// Entidad de tipo Préstamo.
  static const String loan = 'Loan';

  /// Entidad de tipo Pago.
  static const String payment = 'Payment';

  /// Entidad de tipo Ciclo de Facturación.
  static const String billingCycle = 'BillingCycle';

  /// Entidad de tipo Configuración Global.
  static const String settings = 'Settings';
}
