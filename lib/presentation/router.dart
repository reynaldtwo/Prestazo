import 'package:go_router/go_router.dart';
import 'package:prestamos_app/presentation/screens/cobrar/cobrar_screen.dart';
import 'package:prestamos_app/presentation/screens/customers/customer_detail_screen.dart';
import 'package:prestamos_app/presentation/screens/customers/customer_form_screen.dart';
import 'package:prestamos_app/presentation/screens/customers/customers_screen.dart';
import 'package:prestamos_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:prestamos_app/presentation/screens/loans/loan_detail_screen.dart';
import 'package:prestamos_app/presentation/screens/loans/loan_edit_screen.dart';
import 'package:prestamos_app/presentation/screens/loans/loan_form_screen.dart';
import 'package:prestamos_app/presentation/screens/payments/payment_form_screen.dart';
import 'package:prestamos_app/presentation/screens/payments/payment_history_screen.dart';
import 'package:prestamos_app/presentation/screens/reports/currency_differential_report_screen.dart';
import 'package:prestamos_app/presentation/screens/reports/reports_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/about_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/company_settings_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/country_selection_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/currency_selection_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/customer_categories_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/dni_format_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/exchange_rate_form_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/exchange_rate_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/monetary_settings_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/payment_frequencies_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/payment_plans_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/plan_form_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/report_currency_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/scheduled_backup_screen.dart';
import 'package:prestamos_app/presentation/screens/settings/settings_screen.dart';
import 'package:prestamos_app/presentation/shell_screen.dart';

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
            GoRoute(
              path: 'about',
              name: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
            GoRoute(
              path: 'dni-format',
              name: 'dni-format',
              builder: (context, state) => const DniFormatScreen(),
            ),
            GoRoute(
              path: 'currency-selection',
              name: 'currency-selection',
              builder: (context, state) => const CurrencySelectionScreen(),
            ),
            GoRoute(
              path: 'monetary',
              name: 'monetary-settings',
              builder: (context, state) => const MonetarySettingsScreen(),
            ),
            GoRoute(
              path: 'report-currency',
              name: 'report-currency',
              builder: (context, state) => const ReportCurrencyScreen(),
            ),
            GoRoute(
              path: 'scheduled-backup',
              name: 'scheduled-backup',
              builder: (context, state) => const ScheduledBackupScreen(),
            ),
            GoRoute(
              path: 'country-selection',
              name: 'country-selection',
              builder: (context, state) => const CountrySelectionScreen(),
            ),
            GoRoute(
              path: 'exchange-rates',
              name: 'exchange-rates',
              builder: (context, state) => const ExchangeRateScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'new-exchange-rate',
                  builder: (context, state) => const ExchangeRateFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: 'edit-exchange-rate',
                  builder: (context, state) => ExchangeRateFormScreen(
                    rateId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'currency-differential',
              name: 'currency-differential',
              builder: (context, state) =>
                  const CurrencyDifferentialReportScreen(),
            ),
            GoRoute(
              path: 'customer-categories',
              name: 'customer-categories',
              builder: (context, state) => const CustomerCategoriesScreen(),
            ),
            GoRoute(
              path: 'payment-frequencies',
              name: 'payment-frequencies',
              builder: (context, state) => const PaymentFrequenciesScreen(),
            ),
            GoRoute(
              path: 'payment-plans',
              name: 'payment-plans',
              builder: (context, state) => const PaymentPlansScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'add-payment-plan',
                  builder: (context, state) => const PlanFormScreen(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: 'edit-payment-plan',
                  builder: (context, state) {
                    final id = state.pathParameters['id'];
                    return PlanFormScreen(planId: id);
                  },
                ),
              ],
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
