import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/widgets/clean_premium_nav_bar.dart';

/// Pantalla principal que actúa como contenedor (Shell) con navegación inferior.
class ShellScreen extends StatelessWidget {
  /// Crea una instancia de [ShellScreen].
  const ShellScreen({required this.child, super.key});

  /// El widget hijo que se muestra dentro del shell (generalmente la página actual).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final s = S.of(context);
    final currentIndex = _getCurrentIndex(location);

    final items = [
      CleanNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: s.navHome,
      ),
      CleanNavItem(
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments,
        label: s.navCollect,
      ),
      CleanNavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: s.navCustomers,
      ),
      CleanNavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: s.navReports,
      ),
      CleanNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: s.navSettings,
      ),
    ];

    return CleanPremiumNavBar(
      currentIndex: currentIndex,
      items: items,
      onTap: (index) => _onTap(context, index),
    );
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/cobrar')) return 1;
    if (location.startsWith('/customers') || location.startsWith('/customer')) {
      return 2;
    }
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/cobrar');
      case 2:
        context.go('/customers');
      case 3:
        context.go('/reports');
      case 4:
        context.go('/settings');
    }
  }
}
