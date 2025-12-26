import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de Prestazo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset('assets/Icono.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              'Prestazo',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versión 1.0.0',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),

            // Description Card
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Tu aliado financiero',
                      style: AppTypography.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prestazo es una aplicación diseñada para simplificar la gestión de tus préstamos personales. '
                      'Con Prestazo, puedes mantener un control total sobre tus clientes, créditos y cobros, '
                      'todo desde la palma de tu mano.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureItem(
                      icon: Icons.people,
                      text: 'Gestiona tu cartera de clientes fácilmente.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.monetization_on,
                      text:
                          'Calcula intereses y amortizaciones automáticamente.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.calendar_today,
                      text:
                          'Visualiza cobros pendientes por día, semana o mes.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.bar_chart,
                      text:
                          'Genera reportes de ganancias y proyección de ingresos.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              '© ${DateTime.now().year} Prestazo',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
