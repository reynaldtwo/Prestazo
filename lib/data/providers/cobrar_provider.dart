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
  final DateTime? nextDueDate;
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

    // Get moratorium days from settings for overdue calculation
    var moratoriumDays = 0;
    if (filter == CobrarFilter.overdue) {
      final settingsResult = await db.query(
        'app_settings',
        columns: ['moratorium_days'],
        where: 'settings_id = ?',
        whereArgs: ['global'],
      );
      if (settingsResult.isNotEmpty) {
        moratoriumDays = (settingsResult.first['moratorium_days'] as int?) ?? 0;
      }
    }

    // Build query based on filter
    String query;
    final args = <dynamic>[];

    switch (filter) {
      case CobrarFilter.overdue:
        // Customers with overdue cycles (status = 'OVERDUE' or due_date past cutoff)
        // Calculate the cutoff date by subtracting moratorium days from today
        final cutoffDate = today.subtract(Duration(days: moratoriumDays));
        final cutoffDateStr = cutoffDate.toIso8601String().split('T')[0];
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
            bc.billing_cycle_id,
            bc.due_date,
            bc.interest_expected,
            bc.interest_paid,
            bc.interest_pending,
            bc.status as cycle_status,
            (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
          FROM customers c
          INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
          INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
            AND (bc.status = 'OVERDUE' OR (bc.status IN ('PENDING', 'PARTIAL') AND bc.due_date < ?))
          WHERE c.status = 'ACTIVE'
          ORDER BY bc.due_date ASC, c.full_name ASC
        ''';
        args.add(cutoffDateStr);

      case CobrarFilter.upcoming:
        // Loans with cycles due within collectionPlanDays
        // Get collectionPlanDays from settings
        var collectionPlanDays = 3;
        final planResult = await db.query(
          'app_settings',
          columns: ['collection_plan_days'],
          where: 'settings_id = ?',
          whereArgs: ['global'],
        );
        if (planResult.isNotEmpty) {
          collectionPlanDays =
              (planResult.first['collection_plan_days'] as int?) ?? 3;
        }
        final futureDate = today.add(Duration(days: collectionPlanDays - 1));
        final futureDateStr = futureDate.toIso8601String().split('T')[0];
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
            bc.billing_cycle_id,
            bc.due_date,
            bc.interest_expected,
            bc.interest_paid,
            bc.interest_pending,
            (SELECT MAX(p.created_at) FROM payments p WHERE p.customer_id = c.customer_id AND p.status = 'VALID') as last_payment_date
          FROM customers c
          INNER JOIN loans l ON c.customer_id = l.customer_id AND l.status IN ('ACTIVE', 'IN_MORA')
          INNER JOIN billing_cycles bc ON l.loan_id = bc.loan_id 
            AND bc.status IN ('PENDING', 'PARTIAL')
            AND bc.due_date BETWEEN ? AND ?
          WHERE c.status = 'ACTIVE'
          ORDER BY bc.due_date ASC, c.full_name ASC
        ''';
        args.addAll([todayStr, futureDateStr]);
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
            lastPaymentDate: existingCustomer.lastPaymentDate,
            daysOverdue: existingCustomer.daysOverdue,
            isInMora: existingCustomer.daysOverdue > 7,
            loans: updatedLoans,
          );
        } else {
          // Existing loan - accumulate interest from multiple cycles
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
            lastPaymentDate: existingCustomer.lastPaymentDate,
            daysOverdue: existingCustomer.daysOverdue,
            isInMora: existingCustomer.daysOverdue > 7,
            loans: existingCustomer.loans,
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
