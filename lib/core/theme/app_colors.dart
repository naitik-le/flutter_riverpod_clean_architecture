import 'package:flutter/material.dart';

/// AppColors provides a professionally curated, premium palette
/// tailored for a collaborative workspace app (Web and Mobile).
/// It features custom Slate and Indigo themes with glassmorphic accents.
class AppColors {
  // Brand Core
  static const Color primary = Color(0xFF6366F1); // Indigo HSL(239, 84%, 66%)
  static const Color primaryLight = Color(0xFF818CF8); // Indigo Light
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo Dark

  static const Color accent = Color(0xFF10B981); // Emerald Accent (Green for success/indicators)
  static const Color accentLight = Color(0xFF34D399);

  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color error = Color(0xFFEF4444); // Red Error

  // --- Light Theme Colors ---
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceElevatedLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // --- Dark Theme Colors ---
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceElevatedDark = Color(0xFF334155); // Slate 700
  static const Color borderDark = Color(0xFF334155); // Slate 700

  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Slate 300
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  // Glassmorphic / Transparent Accents
  static Color glassWhite(double opacity) => Colors.white.withOpacity(opacity);
  static Color glassBlack(double opacity) => Colors.black.withOpacity(opacity);

  /// Helper to fetch adaptive color based on brightness context
  static Color adaptiveText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  }
}
