import 'package:flutter/material.dart';

/// PrestamosApp Color Palette
/// Professional, modern, corporate design system
class AppColors {
  AppColors._();

  // Primary Colors - Deep Blue (Professional/Trust)
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2E5A8F);
  static const Color primaryDark = Color(0xFF152A45);

  // Accent - Money Green (Success/Gains)
  static const Color accent = Color(0xFF00B894);
  static const Color accentLight = Color(0xFF55EFC4);
  static const Color accentDark = Color(0xFF00866D);

  // Semantic Colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color danger = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Light Theme - Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Light Theme - Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Light Theme - Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // ====== DARK THEME COLORS ======

  // Dark Theme - Neutral Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);

  // Dark Theme - Text Colors
  static const Color textPrimaryDark = Color(0xFFE1E1E1);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textTertiaryDark = Color(0xFF777777);

  // Dark Theme - Border Colors
  static const Color borderDark = Color(0xFF3D3D3D);
  static const Color borderLightDark = Color(0xFF2D2D2D);
  static const Color dividerDark = Color(0xFF3D3D3D);

  // Status Colors for Loans (same for both themes)
  static const Color statusActive = Color(0xFF00B894);
  static const Color statusMora = Color(0xFFE74C3C);
  static const Color statusClosed = Color(0xFF64748B);
  static const Color statusPending = Color(0xFFFDCB6E);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
}
