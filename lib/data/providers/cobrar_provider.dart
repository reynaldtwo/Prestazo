import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';

/// Model for customer due data in "A Cobrar" screen
class CustomerDueInfo {
  /// Crea una instancia de [CustomerDueInfo] con la información de deuda del cliente.
  const CustomerDueInfo({
    required this.customerId,
    required this.customerName,
    required this.billingFrequency,
    required this.totalCapitalBalance,
    required this.totalInterestExpected,
    required this.totalInterestPending,
    required this.totalInterestPaid,
    required this.totalInstallmentAmount,
    required this.hasSimpleLoans,
    required this.hasPlanLoans,
    required this.daysOverdue,
    required this.isInMora,
    required this.loans,
    this.alias,
    this.phone,
    this.lastPaymentDate,
  });

  /// Identificador único del cliente.
  final String customerId;

  /// Nombre completo del cliente.
  final String customerName;

  /// Alias o nombre corto (opcional).
  final String? alias;

  /// Teléfono de contacto.
  final String? phone;

  /// Frecuencia de facturación.
  final String billingFrequency;

  /// Saldo total de capital pendiente.
  final double totalCapitalBalance;

  /// Interés total esperado.
  final double totalInterestExpected;

  /// Interés total pendiente de pago.
  final double totalInterestPending;

  /// Interés total ya pagado.
  final double totalInterestPaid;

  /// Monto total de cuotas pendientes (para préstamos con plan).
  final double totalInstallmentAmount;

  /// Indica si el cliente tiene préstamos sin plan de pago.
  final bool hasSimpleLoans;

  /// Indica si el cliente tiene préstamos con plan de pago.
  final bool hasPlanLoans;

  /// Fecha del último pago realizado.
  final DateTime? lastPaymentDate;

  /// Cantidad de días de retraso.
  final int daysOverdue;

  /// Indica si el cliente está legalmente en mora (ej: > 7 días).
  final bool isInMora;

  /// Lista de deudas individuales por préstamo.
  final List<LoanDueInfo> loans;

  /// Nombre a mostrar (alias si existe, si no el nombre real).
  String get displayName => alias ?? customerName;
}

/// Model for loan due data
class LoanDueInfo {
  /// Crea información detallada de deuda para un préstamo específico.
  const LoanDueInfo({
    required this.loanId,
    required this.principalBalance,
    required this.interestExpected,
    required this.interestPending,
    this.loanNumber,
    this.nextDueDate,
    this.installmentAmount = 0,
    this.hasPlan = false,
  });

  /// ID del préstamo.
  final String loanId;

  /// Número de préstamo descriptivo.
  final String? loanNumber;

  /// Saldo actual de capital.
  final double principalBalance;

  /// Interés total esperado para este préstamo.
  final double interestExpected;

  /// Interés pendiente de pago.
  final double interestPending;

  /// Fecha del próximo vencimiento (si aplica).
  /// Fecha del próximo vencimiento (si aplica).
  final DateTime? nextDueDate;

  /// Valor de la cuota pendiente (para préstamos con plan).
  final double installmentAmount;

  /// Indica si este préstamo tiene plan de pagos.
  final bool hasPlan;
}

/// Filter type for A Cobrar screen
/// Filtros disponibles para la pantalla "A Cobrar".
enum CobrarFilter {
  /// Préstamos próximos a cobrar (según collectionPlanDays).
  upcoming,

  /// Todos los préstamos atrasados.
  overdue,
}

/// State for A Cobrar screen
class CobrarState {
  /// Crea un estado inicial para la pantalla "A Cobrar".
  const CobrarState({
    this.customers = const [],
    this.filteredCustomers = const [],
    this.isLoading = false,
    this.error,
    this.activeFilter = CobrarFilter.upcoming,
    this.searchQuery = '',
  });

  /// Lista completa de clientes con deudas según el filtro.
  final List<CustomerDueInfo> customers;

  /// Lista filtrada por la búsqueda del usuario.
  final List<CustomerDueInfo> filteredCustomers;

  /// Indica si los datos se están cargando.
  final bool isLoading;

  /// Mensaje de error si la carga falló.
  final String? error;

  /// Filtro actualmente activo.
  final CobrarFilter activeFilter;

  /// Texto de búsqueda actual.
  final String searchQuery;

  /// Crea una copia de este estado con los campos proporcionados actualizados.
  CobrarState copyWith({
    List<CustomerDueInfo>? customers,
    List<CustomerDueInfo>? filteredCustomers,
    bool? isLoading,
    String? error,
    CobrarFilter? activeFilter,
    String? searchQuery,
  }) {
    return CobrarState(
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Get customers in mora
  List<CustomerDueInfo> get customersInMora {
    return filteredCustomers.where((c) => c.isInMora).toList();
  }

  /// Get total pending interest
  double get totalPendingInterest {
    return filteredCustomers.fold(0, (sum, c) => sum + c.totalInterestPending);
  }
}

/// Notifier for A Cobrar screen data
class CobrarNotifier extends StateNotifier<CobrarState> {
  /// Crea un [CobrarNotifier] e inicia la carga de datos.
  CobrarNotifier(this._ref) : super(const CobrarState()) {
    loadData();
  }
  final Ref _ref;

  /// Load data based on current filter
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final customers = await _fetchCustomersWithDueInfo(state.activeFilter);
      final filtered = _applySearch(customers, state.searchQuery);
      state = state.copyWith(
        customers: customers,
        filteredCustomers: filtered,
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Apply search filter
  List<CustomerDueInfo> _applySearch(
    List<CustomerDueInfo> customers,
    String query,
  ) {
    if (query.isEmpty) return customers;
    final lowerQuery = query.toLowerCase();
    return customers.where((c) {
      final nameMatch = c.customerName.toLowerCase().contains(lowerQuery);
      final aliasMatch = c.alias?.toLowerCase().contains(lowerQuery) ?? false;
      final amountMatch =
          c.totalCapitalBalance.toString().contains(query) ||
          c.totalInterestPending.toString().contains(query);
      return nameMatch || aliasMatch || amountMatch;
    }).toList();
  }

  /// Set search query and filter
  void setSearch(String query) {
    final filtered = _applySearch(state.customers, query);
    state = state.copyWith(searchQuery: query, filteredCustomers: filtered);
  }

  /// Change filter and reload data
  Future<void> setFilter(CobrarFilter filter) async {
    state = state.copyWith(activeFilter: filter, searchQuery: '');
    await loadData();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadData();
  }

  /// Fetch customers with due information - simplified query
  Future<List<CustomerDueInfo>> _fetchCustomersWithDueInfo(
    CobrarFilter filter,
  ) async {
    final db = await _ref.read(databaseHelperProvider).database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = today.toIso8601String().split('T')[0];

    final settings = await _ref.read(appSettingsProvider.future);
    final advanceDays = settings.collectionPlanDays;
    final maxDate = today.add(Duration(days: advanceDays));
    final maxDateStr = maxDate.toIso8601String().split('T')[0];

    // Build query based on filter
    String query;
    final args = <dynamic>[];

    switch (filter) {
      case CobrarFilter.overdue:
        // Cuentas con ciclos vencidos (due_date anterior a hoy)
        query = '''
          SELECT 
            c.customer_id,
            c.full_name,
            c.alias,
            c.phone,
            l.billing_frequency,
            l.loan_id,
            l.loan_number,
            l.principal_balance,
            l.plan_id,
            bc.billing_cycle_id,
            bc.due_date,
            bc.interest_expected,
            bc.interest_paid,
            bc.interest_pending,
            bc.installment_pending,
            bc.status as cycle_status,
            (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
          FROM customers c
          INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
          INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
            AND (bc.status = 'OVERDUE' OR (bc.status IN ('PENDING', 'PARTIAL') AND bc.due_date < ?))
          WHERE c.status = 'ACTIVE'
          ORDER BY bc.due_date ASC, c.full_name ASC
        ''';
        args.add(todayStr);

      case CobrarFilter.upcoming:
        // Préstamos con ciclos que vencen hoy o en el futuro cercano (según advanceDays)
        // EXCLUYE clientes que tengan cualquier ciclo vencido pendiente
        query = '''
          SELECT 
            c.customer_id,
            c.full_name,
            c.alias,
            c.phone,
            l.billing_frequency,
            l.loan_id,
            l.loan_number,
            l.principal_balance,
            l.plan_id,
            bc.billing_cycle_id,
            bc.due_date,
            bc.interest_expected,
            bc.interest_paid,
            bc.interest_pending,
            bc.installment_pending,
            (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
          FROM customers c
          INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
          INNER JOIN billing_cycles bc ON bc.billing_cycle_id = (
             SELECT bc2.billing_cycle_id 
             FROM billing_cycles bc2 
             WHERE bc2.loan_id = l.loan_id 
               AND bc2.status IN ('PENDING', 'PARTIAL')
               AND bc2.due_date >= ?
               AND bc2.due_date <= ?
             ORDER BY bc2.due_date ASC
             LIMIT 1
          )
          WHERE c.status = 'ACTIVE'
            AND NOT EXISTS (
              SELECT 1 FROM billing_cycles bc3
              INNER JOIN loans l2 ON bc3.loan_id = l2.loan_id
              WHERE l2.customer_id = c.customer_id
                AND bc3.due_date < ?
                AND bc3.status IN ('PENDING', 'PARTIAL', 'OVERDUE')
            )
          ORDER BY bc.due_date ASC, c.full_name ASC
        ''';
        args.addAll([todayStr, maxDateStr, todayStr]);
    }

    final results = await db.rawQuery(query, args);

    // Group by customer
    final customerMap = <String, CustomerDueInfo>{};

    for (final row in results) {
      final customerId = row['customer_id']! as String;

      if (!customerMap.containsKey(customerId)) {
        // Calculate days overdue from billing cycle due date
        var daysOverdue = 0;
        final dueDateStr = row['due_date'] as String?;
        if (dueDateStr != null) {
          final dueDate = DateTime.parse(dueDateStr);
          if (dueDate.isBefore(today)) {
            daysOverdue = today.difference(dueDate).inDays;
          }
        }

        DateTime? lastPaymentDate;
        final lastPaymentStr = row['last_payment_date'] as String?;
        if (lastPaymentStr != null) {
          lastPaymentDate = DateTime.tryParse(lastPaymentStr);
        }

        customerMap[customerId] = CustomerDueInfo(
          customerId: customerId,
          customerName: row['full_name']! as String,
          alias: row['alias'] as String?,
          phone: row['phone'] as String?,
          billingFrequency: row['billing_frequency']! as String,
          totalCapitalBalance: 0,
          totalInterestExpected: 0,
          totalInterestPending: 0,
          totalInterestPaid: 0,
          totalInstallmentAmount: 0,
          hasSimpleLoans: false,
          hasPlanLoans: false,
          lastPaymentDate: lastPaymentDate,
          daysOverdue: daysOverdue,
          isInMora: daysOverdue > 7,
          loans: [],
        );
      }

      // Add/update loan info
      final loanId = row['loan_id'] as String?;
      if (loanId != null) {
        final principalBalance =
            (row['principal_balance'] as num?)?.toDouble() ?? 0;
        final interestExpected =
            (row['interest_expected'] as num?)?.toDouble() ?? 0;
        final interestPending =
            (row['interest_pending'] as num?)?.toDouble() ?? 0;
        final interestPaid = (row['interest_paid'] as num?)?.toDouble() ?? 0;

        final planId = row['plan_id'] as String?;
        final hasPlan = planId != null;

        var installmentAmount =
            (row['installment_pending'] as num?)?.toDouble() ?? 0;

        // If it's a plan but installment is 0 (shouldn't happen for pending cycles),
        // fallback to interest pending (better than 0).
        if (hasPlan && installmentAmount <= 0) {
          installmentAmount = interestPending;
        }

        final dueDateStr = row['due_date'] as String?;
        DateTime? nextDueDate;
        if (dueDateStr != null) {
          nextDueDate = DateTime.tryParse(dueDateStr);
        }

        final existingCustomer = customerMap[customerId]!;
        final existingLoanIndex = existingCustomer.loans.indexWhere(
          (l) => l.loanId == loanId,
        );

        if (existingLoanIndex == -1) {
          // New loan - add it
          final updatedLoans = [
            ...existingCustomer.loans,
            LoanDueInfo(
              loanId: loanId,
              loanNumber: row['loan_number'] as String?,
              principalBalance: principalBalance,
              interestExpected: interestExpected,
              interestPending: interestPending,
              nextDueDate: nextDueDate,
              hasPlan: hasPlan,
              installmentAmount: installmentAmount,
            ),
          ];

          customerMap[customerId] = CustomerDueInfo(
            customerId: existingCustomer.customerId,
            customerName: existingCustomer.customerName,
            alias: existingCustomer.alias,
            phone: existingCustomer.phone,
            billingFrequency: existingCustomer.billingFrequency,
            totalCapitalBalance:
                existingCustomer.totalCapitalBalance + principalBalance,
            totalInterestExpected:
                existingCustomer.totalInterestExpected + interestExpected,
            totalInterestPending:
                existingCustomer.totalInterestPending + interestPending,
            totalInterestPaid:
                existingCustomer.totalInterestPaid + interestPaid,
            totalInstallmentAmount:
                existingCustomer.totalInstallmentAmount + installmentAmount,
            hasSimpleLoans: existingCustomer.hasSimpleLoans || !hasPlan,
            hasPlanLoans: existingCustomer.hasPlanLoans || hasPlan,
            lastPaymentDate: existingCustomer.lastPaymentDate,
            daysOverdue: existingCustomer.daysOverdue,
            isInMora: existingCustomer.daysOverdue > 7,
            loans: updatedLoans,
          );
        } else {
          // Existing loan - accumulate interest/installments from multiple cycles
          final existingLoan = existingCustomer.loans[existingLoanIndex];
          final updatedLoan = LoanDueInfo(
            loanId: existingLoan.loanId,
            loanNumber: existingLoan.loanNumber,
            principalBalance: existingLoan.principalBalance,
            interestExpected: existingLoan.interestExpected + interestExpected,
            interestPending: existingLoan.interestPending + interestPending,
            // Keep the earliest due date for upcoming, or this row's date
            nextDueDate: existingLoan.nextDueDate ?? nextDueDate,
            hasPlan: hasPlan,
            installmentAmount:
                existingLoan.installmentAmount + installmentAmount,
          );

          final updatedLoans = [...existingCustomer.loans];
          updatedLoans[existingLoanIndex] = updatedLoan;

          customerMap[customerId] = CustomerDueInfo(
            customerId: existingCustomer.customerId,
            customerName: existingCustomer.customerName,
            alias: existingCustomer.alias,
            phone: existingCustomer.phone,
            billingFrequency: existingCustomer.billingFrequency,
            totalCapitalBalance: existingCustomer.totalCapitalBalance,
            totalInterestExpected:
                existingCustomer.totalInterestExpected + interestExpected,
            totalInterestPending:
                existingCustomer.totalInterestPending + interestPending,
            totalInterestPaid:
                existingCustomer.totalInterestPaid + interestPaid,
            totalInstallmentAmount:
                existingCustomer.totalInstallmentAmount + installmentAmount,
            hasSimpleLoans: existingCustomer.hasSimpleLoans || !hasPlan,
            hasPlanLoans: existingCustomer.hasPlanLoans || hasPlan,
            lastPaymentDate: existingCustomer.lastPaymentDate,
            daysOverdue: existingCustomer.daysOverdue,
            isInMora: existingCustomer.daysOverdue > 7,
            loans: updatedLoans,
          );
        }
      }
    }

    return customerMap.values.toList();
  }
}

/// Provider for A Cobrar screen
final cobrarProvider = StateNotifierProvider<CobrarNotifier, CobrarState>((
  ref,
) {
  // Watch refresh trigger to automatically reload data when database changes
  ref.watch(refreshTriggerProvider);
  return CobrarNotifier(ref);
});

/// Provider for customers in mora count
final customersInMoraCountProvider = Provider<int>((ref) {
  final state = ref.watch(cobrarProvider);
  return state.customersInMora.length;
});
