import 'package:equatable/equatable.dart';
import '../../core/constants/app_status.dart';

/// Loan model - Loan granted to a customer
class Loan extends Equatable {
  final String loanId;
  final String customerId;
  final double principalOriginal;
  final double principalBalance;
  final double monthlyInterestRate;
  final String rateUnit;
  final String billingFrequency; // 'MONTHLY', 'BIWEEKLY', 'WEEKLY', 'DAILY'
  final DateTime disbursementDate;
  final DateTime? endDate; // Informational end date
  final String status;
  final DateTime? closedAt;
  final String? notes;
  final String? loanNumber; // Added for consecutive numbering
  final String currencyCode; // Currency for this loan (e.g., 'NIO', 'USD')
  final double? appliedExchangeRate; // Exchange rate snapshot at disbursement
  final DateTime createdAt;
  final DateTime updatedAt;

  const Loan({
    required this.loanId,
    required this.customerId,
    required this.principalOriginal,
    required this.principalBalance,
    required this.monthlyInterestRate,
    this.rateUnit = 'MONTHLY',
    this.billingFrequency = 'MONTHLY',
    required this.disbursementDate,
    this.endDate,
    this.status = AppStatus.loanActive,
    this.closedAt,
    this.notes,
    this.loanNumber,
    this.currencyCode = 'NIO',
    this.appliedExchangeRate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if loan is active (includes IN_MORA)
  bool get isActive =>
      status == AppStatus.loanActive || status == AppStatus.loanOverdue;

  /// Check if loan is in mora
  bool get isInMora => status == AppStatus.loanOverdue;

  /// Check if loan is closed
  bool get isClosed => status == AppStatus.loanClosed;

  /// Calculate biweekly rate (monthly / 2)
  double get biweeklyInterestRate => monthlyInterestRate / 2;

  /// Calculate weekly rate (monthly / 4)
  double get weeklyInterestRate => monthlyInterestRate / 4;

  /// Calculate daily rate (monthly / 30)
  double get dailyInterestRate => monthlyInterestRate / 30;

  /// Calculate interest for one month
  double calculateMonthlyInterest() {
    return _roundMoney(principalBalance * (monthlyInterestRate / 100));
  }

  /// Calculate interest for one biweek
  double calculateBiweeklyInterest() {
    return _roundMoney(principalBalance * (biweeklyInterestRate / 100));
  }

  /// Calculate interest for one week
  double calculateWeeklyInterest() {
    return _roundMoney(principalBalance * (weeklyInterestRate / 100));
  }

  /// Calculate interest for one day
  double calculateDailyInterest() {
    return _roundMoney(principalBalance * (dailyInterestRate / 100));
  }

  /// Round to 2 decimals
  double _roundMoney(double value) {
    return (value * 100).round() / 100;
  }

  /// Create from database map
  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      loanId: map['loan_id'] as String,
      customerId: map['customer_id'] as String,
      principalOriginal: (map['principal_original'] as num).toDouble(),
      principalBalance: (map['principal_balance'] as num).toDouble(),
      monthlyInterestRate: (map['monthly_interest_rate'] as num).toDouble(),
      rateUnit: map['rate_unit'] as String? ?? 'MONTHLY',
      billingFrequency: map['billing_frequency'] as String? ?? 'MONTHLY',
      disbursementDate: DateTime.parse(map['disbursement_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      status: map['status'] as String? ?? AppStatus.loanActive,
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String)
          : null,
      notes: map['notes'] as String?,
      loanNumber: map['loan_number']?.toString(),
      currencyCode: map['currency_code'] as String? ?? 'NIO',
      appliedExchangeRate: (map['applied_exchange_rate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'customer_id': customerId,
      'principal_original': principalOriginal,
      'principal_balance': principalBalance,
      'monthly_interest_rate': monthlyInterestRate,
      'rate_unit': rateUnit,
      'billing_frequency': billingFrequency,
      'disbursement_date': disbursementDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'status': status,
      'closed_at': closedAt?.toIso8601String(),
      'notes': notes,
      'loan_number': loanNumber,
      'currency_code': currencyCode,
      'applied_exchange_rate': appliedExchangeRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  Loan copyWith({
    double? principalOriginal,
    double? principalBalance,
    double? monthlyInterestRate,
    String? billingFrequency,
    DateTime? disbursementDate,
    DateTime? endDate,
    String? status,
    DateTime? closedAt,
    String? notes,
    String? loanNumber,
    String? currencyCode,
    double? appliedExchangeRate,
    DateTime? updatedAt,
  }) {
    return Loan(
      loanId: loanId,
      customerId: customerId,
      principalOriginal: principalOriginal ?? this.principalOriginal,
      principalBalance: principalBalance ?? this.principalBalance,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
      rateUnit: rateUnit,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
      loanNumber: loanNumber ?? this.loanNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      appliedExchangeRate: appliedExchangeRate ?? this.appliedExchangeRate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    loanId,
    customerId,
    principalOriginal,
    principalBalance,
    monthlyInterestRate,
    rateUnit,
    billingFrequency,
    disbursementDate,
    endDate,
    status,
    closedAt,
    notes,
    loanNumber,
    currencyCode,
    appliedExchangeRate,
    createdAt,
    updatedAt,
  ];
}
