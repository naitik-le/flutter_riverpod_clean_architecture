import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTextStyles provides modern, highly legible typography pairings.
/// Headlines: GoogleFonts.outfit (clean, premium, soft-curved)
/// Body & Details: GoogleFonts.inter (highly legible, professional)
class AppTextStyles {
  // --- Outfit Font Styles (Headlines) ---
  
  static TextStyle display(Color color) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: color,
      );

  static TextStyle h1(Color color) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: color,
      );

  static TextStyle h2(Color color) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle h3(Color color) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // --- Inter Font Styles (Body and UI controls) ---

  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySemiBold(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: color,
      );

  static TextStyle caption(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.4,
        color: color,
      );

  static TextStyle button(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      );
}
