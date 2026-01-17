import 'package:flutter/material.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';

/// Reusable card component with optional header and actions
class AppCard extends StatelessWidget {
  /// Crea un [AppCard] con contenido y cabecera opcional.
  const AppCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.showBorder = true,
    this.leading,
    this.trailing,
  });

  /// Título opcional de la tarjeta.
  final String? title;

  /// Subtítulo opcional de la tarjeta.
  final String? subtitle;

  /// Widget principal que se muestra en el cuerpo de la tarjeta.
  final Widget child;

  /// Lista de widgets de acción que se muestran al final de la tarjeta.
  final List<Widget>? actions;

  /// Acción a ejecutar al presionar la tarjeta completa.
  final VoidCallback? onTap;

  /// Espaciado interno de la tarjeta.
  final EdgeInsetsGeometry? padding;

  /// Color de fondo personalizado de la tarjeta.
  final Color? backgroundColor;

  /// Indica si se debe mostrar el borde de la tarjeta.
  final bool showBorder;

  /// Widget que se muestra antes del título.
  final Widget? leading;

  /// Widget que se muestra después del título o al final de la cabecera.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || leading != null || trailing != null) ...[
          _buildHeader(context),
          if (subtitle == null) const SizedBox(height: 12),
        ],
        if (subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        child,
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ],
    );

    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: showBorder
            ? Border.all(
                color: isDark ? colorScheme.outlineVariant : AppColors.border,
              )
            : null,
        boxShadow: showBorder
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: cardContent,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        if (title != null)
          Expanded(
            child: Text(
              title!,
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions!
          .map(
            (action) =>
                Padding(padding: const EdgeInsets.only(left: 8), child: action),
          )
          .toList(),
    );
  }
}

/// Simple stat card for dashboard KPIs
class AppStatCard extends StatelessWidget {
  /// Crea un [AppStatCard] para mostrar métricas e indicadores.
  const AppStatCard({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
    this.trend,
    this.isTrendPositive = true,
  });

  /// Etiqueta descriptiva del dato estadístico.
  final String label;

  /// Valor numérico o textual de la estadística.
  final String value;

  /// Icono representativo de la métrica.
  final IconData? icon;

  /// Color del icono decorativo.
  final Color? iconColor;

  /// Color del texto del valor.
  final Color? valueColor;

  /// Acción al presionar la tarjeta estadística.
  final VoidCallback? onTap;

  /// Texto opcional que indica una tendencia (ej: "+5%").
  final String? trend;

  /// Indica si la tendencia es positiva (éxito) o negativa (peligro).
  final bool isTrendPositive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.moneyLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isTrendPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isTrendPositive ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: AppTypography.labelSmall.copyWith(
                    color: isTrendPositive
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
