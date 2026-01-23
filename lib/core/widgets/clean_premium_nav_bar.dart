import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Barra de navegación premium refinada.
///
/// Basada en la estructura estable pero con efectos visuales premium:
/// - Animaciones de lift y bounce en iconos.
/// - Efecto de onda (pulse) doble.
/// - Diseño Nocturne Emerald.
class CleanPremiumNavBar extends StatefulWidget {
  /// Crea una instancia de [CleanPremiumNavBar].
  const CleanPremiumNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    super.key,
  });

  /// Índice del elemento actualmente seleccionado.
  final int currentIndex;

  /// Lista de elementos a mostrar en la barra.
  final List<CleanNavItem> items;

  /// Callback al seleccionar un elemento.
  final ValueChanged<int> onTap;

  @override
  State<CleanPremiumNavBar> createState() => _CleanPremiumNavBarState();
}

class _CleanPremiumNavBarState extends State<CleanPremiumNavBar>
    with TickerProviderStateMixin {
  // Controladores para la animación de selección (bounce/lift)
  late List<AnimationController> _iconControllers;

  // Controladores para el efecto de onda (pulse)
  late AnimationController _pulseController;
  late Animation<double> _pulseRadius1;
  late Animation<double> _pulseOpacity1;
  late Animation<double> _pulseRadius2;
  late Animation<double> _pulseOpacity2;

  @override
  void initState() {
    super.initState();

    // Controladores individuales para cada icono (Lift + Bounce)
    _iconControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
      ),
    );

    // Controlador para el efecto de onda (Pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _setupPulseAnimations();

    // Iniciar animación del ícono actual al arranque
    if (widget.currentIndex < _iconControllers.length) {
      _iconControllers[widget.currentIndex].forward();
    }
  }

  void _setupPulseAnimations() {
    // Onda 1: Primary
    _pulseRadius1 = Tween<double>(begin: 0, end: 40).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity1 = Tween<double>(begin: 0.15, end: 0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Onda 2: Secondary
    _pulseRadius2 = Tween<double>(begin: 0, end: 50).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity2 = Tween<double>(begin: 0.1, end: 0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(CleanPremiumNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _handleIndexChanged(oldWidget.currentIndex, widget.currentIndex);
    }
  }

  void _handleIndexChanged(int oldIndex, int newIndex) {
    _iconControllers[oldIndex].reverse();
    _iconControllers[newIndex].forward();
    _pulseController.forward(from: 0);
  }

  @override
  void dispose() {
    for (final controller in _iconControllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / widget.items.length;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              // Pulse effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final endX =
                        (widget.currentIndex * itemWidth) + (itemWidth / 2);
                    return CustomPaint(
                      painter: _PulsePainter(
                        center: Offset(endX, 32),
                        radius1: _pulseRadius1.value,
                        opacity1: _pulseOpacity1.value,
                        radius2: _pulseRadius2.value,
                        opacity2: _pulseOpacity2.value,
                        primaryColor: colorScheme.primary,
                        accentColor: colorScheme.secondary,
                      ),
                    );
                  },
                ),
              ),
              // Nav Items
              Row(
                children: List.generate(widget.items.length, (index) {
                  final isSelected = index == widget.currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onTap(index),
                      child: _buildItem(index, isSelected),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.items[index];

    return AnimatedBuilder(
      animation: _iconControllers[index],
      builder: (context, child) {
        final progress = _iconControllers[index].value;

        var scale = 1.0;
        if (isSelected) {
          if (progress < 0.5) {
            scale = ui.lerpDouble(1, 1.15, progress * 2)!;
          } else {
            scale = ui.lerpDouble(1.15, 1, (progress - 0.5) * 2)!;
          }
        }

        final translationY = isSelected ? ui.lerpDouble(0, -4, progress)! : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, translationY),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.center,
    required this.radius1,
    required this.opacity1,
    required this.radius2,
    required this.opacity2,
    required this.primaryColor,
    required this.accentColor,
  });

  final Offset center;
  final double radius1;
  final double opacity1;
  final double radius2;
  final double opacity2;
  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity1 > 0) {
      canvas.drawCircle(
        center,
        radius1,
        Paint()..color = primaryColor.withValues(alpha: opacity1),
      );
    }
    if (opacity2 > 0) {
      canvas.drawCircle(
        center,
        radius2,
        Paint()..color = accentColor.withValues(alpha: opacity2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => true;
}

/// Modelo para los items de navegación.
class CleanNavItem {
  /// Crea un item.
  const CleanNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  /// Icono en estado inactivo.
  final IconData icon;

  /// Icono en estado activo.
  final IconData activeIcon;

  /// Etiqueta de texto del item.
  final String label;
}
