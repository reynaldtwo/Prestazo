import 'package:flutter/material.dart';

/// PrestamosApp Color Palette
/// Professional, modern, corporate design system
class AppColors {
  AppColors._();

  // Primary Colors - Deep Blue (Professional/Trust)
  /// Color primario (Azul profundo).
  static const Color primary = Color(0xFF1E3A5F);

  /// Versión clara del color primario.
  static const Color primaryLight = Color(0xFF2E5A8F);

  /// Versión oscura del color primario.
  static const Color primaryDark = Color(0xFF152A45);

  // Accent - Money Green (Success/Gains)
  /// Color de acento (Verde dinero).
  static const Color accent = Color(0xFF00B894);

  /// Versión clara del color de acento.
  static const Color accentLight = Color(0xFF55EFC4);

  /// Versión oscura del color de acento.
  static const Color accentDark = Color(0xFF00866D);

  // Semantic Colors
  /// Color semántico para éxito.
  static const Color success = Color(0xFF00B894);

  /// Color semántico para advertencias.
  static const Color warning = Color(0xFFFDCB6E);

  /// Color semántico para errores o peligro.
  static const Color danger = Color(0xFFE74C3C);

  /// Color semántico para información.
  static const Color info = Color(0xFF3498DB);

  // Light Theme - Neutral Colors
  /// Color de fondo principal (Tema claro).
  static const Color background = Color(0xFFF8FAFC);

  /// Color para superficies (Tarjetas, diálogos) (Tema claro).
  static const Color surface = Color(0xFFFFFFFF);

  /// Variante de color de superficie (Tema claro).
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Light Theme - Text Colors
  /// Color de texto principal.
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Color de texto secundario (de menor énfasis).
  static const Color textSecondary = Color(0xFF64748B);

  /// Color de texto terciario (mínimo énfasis).
  static const Color textTertiary = Color(0xFF94A3B8);

  /// Color de texto sobre fondos primarios.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Color de texto sobre fondos de acento.
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Light Theme - Border Colors
  /// Color de bordes estándar.
  static const Color border = Color(0xFFE2E8F0);

  /// Color de bordes suaves.
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Color de divisores.
  static const Color divider = Color(0xFFE2E8F0);

  // ====== DARK THEME COLORS (Nocturne Emerald) ======
  // Tokens base
  /// Color de fondo principal (Tema oscuro).
  static const Color backgroundDark = Color(0xFF0B0F14);

  /// Color para superficies (Tema oscuro).
  static const Color surfaceDark = Color(0xFF121826);

  /// Color para superficies elevadas (Tema oscuro).
  static const Color surfaceElevatedDark = Color(0xFF182235);

  /// Variante de superficie (Tema oscuro).
  static const Color surfaceVariantDark = Color(0xFF1F2A44);

  // Colores vivos (acción/estados)
  /// Color primario en modo oscuro.
  static const Color primaryDarkTheme = Color(0xFF2D7DFF);

  /// Color de acento/confirmar en modo oscuro.
  static const Color secondaryDarkTheme = Color(0xFF18D6B4);

  /// Texto sobre color de acento en modo oscuro.
  static const Color onSecondaryDarkTheme = Color(0xFF062019);

  /// Color terciario (detalle/links) en modo oscuro.
  static const Color tertiaryDarkTheme = Color(0xFFB16CFF);

  /// Color de error en modo oscuro.
  static const Color errorDark = Color(0xFFFF4D6D);

  /// Color de advertencia en modo oscuro.
  static const Color warningDark = Color(0xFFFFB020);

  /// Color de información en modo oscuro.
  static const Color infoDark = Color(0xFF38BDF8);

  /// Color de éxito en modo oscuro.
  static const Color successDark = Color(0xFF22C55E);

  // Dark Theme - Text Colors
  /// Color de texto principal (Tema oscuro).
  static const Color textPrimaryDark = Color(0xFFEAF0FF);

  /// Color de texto secundario (Tema oscuro).
  static const Color textSecondaryDark = Color(0xFFB7C3DE);

  /// Color de texto terciario (Tema oscuro).
  static const Color textTertiaryDark = Color(0xFF7F8FB3);

  /// Iconos inactivos (Tema oscuro).
  static const Color iconInactiveDark = Color(0xFF7F8FB3);

  // Dark Theme - Border Colors
  /// Color de bordes (Tema oscuro).
  static const Color borderDark = Color(0xFF2C3A5A);

  /// Variante clara de bordes (Tema oscuro).
  static const Color borderLightDark = Color(0xFF1F2A44);

  /// Color de divisores (Tema oscuro).
  static const Color dividerDark = Color(0xFF22304A);

  // Status Colors for Loans (same for both themes)
  /// Color para estado activo.
  static const Color statusActive = Color(0xFF00B894);

  /// Color para estado en mora.
  static const Color statusMora = Color(0xFFE74C3C);

  /// Color para estado cerrado.
  static const Color statusClosed = Color(0xFF64748B);

  /// Color para estado pendiente.
  static const Color statusPending = Color(0xFFFDCB6E);

  // Gradient
  /// Gradiente basado en el color primario.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// Gradiente basado en el color de acento.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
}
