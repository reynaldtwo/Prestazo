import 'package:go_router/go_router.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/cobrar/cobrar_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'screens/customers/customer_form_screen.dart';
import 'screens/loans/loan_detail_screen.dart';
import 'screens/loans/loan_form_screen.dart';
import 'screens/loans/loan_edit_screen.dart';
import 'screens/payments/payment_form_screen.dart';
import 'screens/payments/payment_history_screen.dart';
import 'screens/settings/company_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'shell_screen.dart';

/// App router configuration
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    // Shell route for bottom navigation
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/cobrar',
          name: 'cobrar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CobrarScreen()),
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomersScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
          routes: [
            GoRoute(
              path: 'company',
              name: 'company-settings',
              builder: (context, state) => const CompanySettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/payments',
          name: 'payment-history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PaymentHistoryScreen()),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          pageBuilder: (context, state) {
            final tabStr = state.uri.queryParameters['tab'];
            final tab = int.tryParse(tabStr ?? '0') ?? 0;
            return NoTransitionPage(child: ReportsScreen(initialTab: tab));
          },
        ),

        // Customer routes
        GoRoute(
          path: '/customer/new',
          name: 'new-customer',
          builder: (context, state) => const CustomerFormScreen(),
        ),
        GoRoute(
          path: '/customer/:id',
          name: 'customer-detail',
          builder: (context, state) {
            final customerId = state.pathParameters['id']!;
            return CustomerDetailScreen(customerId: customerId);
          },
        ),
        GoRoute(
          path: '/customer/:id/edit',
          name: 'edit-customer',
          builder: (context, state) {
            final customerId = state.pathParameters['id']!;
            return CustomerFormScreen(customerId: customerId);
          },
        ),

        // Loan routes
        GoRoute(
          path: '/customer/:customerId/loan/new',
          name: 'new-loan',
          builder: (context, state) {
            final customerId = state.pathParameters['customerId']!;
            return LoanFormScreen(customerId: customerId);
          },
        ),
        GoRoute(
          path: '/loan/:id',
          name: 'loan-detail',
          builder: (context, state) {
            final loanId = state.pathParameters['id']!;
            return LoanDetailScreen(loanId: loanId);
          },
        ),
        GoRoute(
          path: '/loan/:id/edit',
          name: 'edit-loan',
          builder: (context, state) {
            final loanId = state.pathParameters['id']!;
            return LoanEditScreen(loanId: loanId);
          },
        ),

        // Payment routes
        GoRoute(
          path: '/payment/new',
          name: 'new-payment',
          builder: (context, state) {
            final extra = state.extra as Map<String, String?>?;
            return PaymentFormScreen(
              customerId: extra?['customerId'],
              loanId: extra?['loanId'],
            );
          },
        ),
      ],
    ),
  ],
);
