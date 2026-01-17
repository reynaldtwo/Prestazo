import 'package:flutter/material.dart';

/// Custom Arc Sidebar Widget with curved edge design
/// Inspired by professional arc_sidebar implementations
class ArcSideBar extends StatefulWidget {
  /// Crea un [ArcSideBar] con diseño curvo.
  const ArcSideBar({
    required this.header,
    required this.items,
    super.key,
    this.footer,
    this.backgroundColor,
    this.accentColor,
    this.width = 280,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  /// Widget de cabecera que se muestra en la parte superior.
  final Widget header;

  /// Lista de elementos de menú a mostrar.
  final List<ArcSideBarItem> items;

  /// Widget opcional de pie de página.
  final Widget? footer;

  /// Color de fondo de la barra lateral.
  final Color? backgroundColor;

  /// Color de acento para el elemento seleccionado.
  final Color? accentColor;

  /// Ancho de la barra lateral.
  final double width;

  /// Índice del elemento seleccionado actualmente.
  final int selectedIndex;

  /// Callback cuando el índice seleccionado cambia.
  final ValueChanged<int>? onItemSelected;

  @override
  State<ArcSideBar> createState() => ArcSideBarState();
}

/// Estado público para permitir el control externo (abrir/cerrar) mediante GlobalKey.
class ArcSideBarState extends State<ArcSideBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Alterna el estado de apertura de la barra lateral.
  void toggle() {
    if (_isOpen) {
      close();
    } else {
      open();
    }
  }

  /// Abre la barra lateral con una animación.
  void open() {
    _animationController.forward();
    setState(() => _isOpen = true);
  }

  /// Cierra la barra lateral con una animación.
  void close() {
    _animationController.reverse();
    setState(() => _isOpen = false);
  }

  /// Indica si la barra lateral está actualmente abierta.
  bool get isOpen => _isOpen;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final accentColor =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // Tap-to-close overlay when open
        if (_isOpen)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) => GestureDetector(
              onTap: close,
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.3 * _fadeAnimation.value,
                ),
              ),
            ),
          ),

        // Main sidebar panel
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_slideAnimation.value * widget.width, 0),
              child: child,
            );
          },
          child: Container(
            width: widget.width,
            height: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: ClipPath(
              clipper: _ArcClipper(),
              child: ColoredBox(
                color: backgroundColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      widget.header,
                      const SizedBox(height: 16),

                      // Menu items
                      Expanded(
                        child: ListView.builder(
                          // Left padding normal, right padding extra for arc curve
                          padding: const EdgeInsets.only(left: 12, right: 40),
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            final isSelected = index == widget.selectedIndex;
                            return _buildMenuItem(
                              item,
                              isSelected,
                              accentColor,
                              () {
                                widget.onItemSelected?.call(index);
                                item.onTap?.call();
                                close();
                              },
                            );
                          },
                        ),
                      ),

                      // Footer
                      if (widget.footer != null) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: widget.footer,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Edge swipe detector when closed (to open by swiping from left)
        if (!_isOpen)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 30, // Edge swipe detection area
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 100) {
                  open();
                }
              },
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem(
    ArcSideBarItem item,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: accentColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? accentColor
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? accentColor
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: accentColor, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Elemento de menú para la barra lateral Arc.
class ArcSideBarItem {
  /// Crea un elemento para la barra lateral.
  const ArcSideBarItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  /// Icono representativo del elemento.
  final IconData icon;

  /// Título del elemento de menú.
  final String title;

  /// Subtítulo opcional informativo.
  final String? subtitle;

  /// Callback que se ejecuta al presionar este elemento.
  final VoidCallback? onTap;
}

/// Custom clipper for the curved right edge
class _ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 30, 0)
      ..quadraticBezierTo(
        size.width,
        size.height * 0.25,
        size.width,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width,
        size.height * 0.75,
        size.width - 30,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
