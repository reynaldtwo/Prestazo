import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/core/widgets/widgets.dart';

/// Pantalla "Acerca de".
class AboutScreen extends ConsumerWidget {
  /// Crea una instancia de [AboutScreen].
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).aboutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceElevatedDark
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: Image.asset('assets/Icono.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prestazo',
              style: AppTypography.displaySmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${S.of(context).aboutVersion} 1.0.0',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      S.of(context).aboutTagline,
                      style: AppTypography.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).aboutDescription,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.people,
                      text: S.of(context).featureCustomers,
                    ),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.monetization_on,
                      text: S.of(context).featureCalculations,
                    ),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.calendar_today,
                      text: S.of(context).featureCollections,
                    ),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.bar_chart,
                      text: S.of(context).featureReports,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              '© ${DateTime.now().year} Prestazo',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
