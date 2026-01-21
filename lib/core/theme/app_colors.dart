import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Deep Blue (tech, trust)
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);

  // Secondary - Teal (data, growth)
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF0F766E);

  // Tertiary - Amber (highlights, accents)
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryLight = Color(0xFFFBBF24);
  static const Color tertiaryDark = Color(0xFFD97706);

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFF22C55E);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // Neutrals - Light theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1E293B);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineVariantLight = Color(0xFFCBD5E1);

  // Neutrals - Dark theme
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color onSurfaceDark = Color(0xFFF1F5F9);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);
  static const Color outlineDark = Color(0xFF334155);
  static const Color outlineVariantDark = Color(0xFF475569);

  // Upload status colors
  static const Color statusPending = Color(0xFF64748B);
  static const Color statusUploading = Color(0xFF3B82F6);
  static const Color statusSuccess = Color(0xFF16A34A);
  static const Color statusFailed = Color(0xFFDC2626);
}
