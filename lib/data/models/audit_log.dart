import 'package:equatable/equatable.dart';

/// AuditLog model - General audit trail
class AuditLog extends Equatable {
  final String auditLogId;
  final String action;
  final String entityType;
  final String entityId;
  final String? details;
  final DateTime createdAt;

  const AuditLog({
    required this.auditLogId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.createdAt,
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
  
  static const String createCustomer = 'CREATE_CUSTOMER';
  static const String updateCustomer = 'UPDATE_CUSTOMER';
  static const String createLoan = 'CREATE_LOAN';
  static const String closeLoan = 'CLOSE_LOAN';
  static const String recordPayment = 'RECORD_PAYMENT';
  static const String voidPayment = 'VOID_PAYMENT';
  static const String capitalizeInterest = 'CAPITALIZE_INTEREST';
  static const String updateSettings = 'UPDATE_SETTINGS';
  static const String restoreBackup = 'RESTORE_BACKUP';
}

/// Entity type constants
class EntityType {
  EntityType._();
  
  static const String customer = 'Customer';
  static const String loan = 'Loan';
  static const String payment = 'Payment';
  static const String billingCycle = 'BillingCycle';
  static const String settings = 'Settings';
}
