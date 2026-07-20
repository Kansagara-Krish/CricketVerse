// lib/core/theme/app_theme.dart
// CricketVerse AI — Centralized Premium Light Theme
// All screens import from here for consistent Material 3 look

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF028A6B); // Redefined to Premium Emerald Green (maintaining compile-time name)
  static const Color primaryGreen  = Color(0xFF10B981); // Vibrant Mint Green
  static const Color accentGold    = Color(0xFFF59E0B); // Glowing Gold
  static const Color accentPurple  = Color(0xFFD97706); // Redefined to Amber Gold (removing purple)
  static const Color accentRed     = Color(0xFFE11D48); // Athletic Crimson Red
  static const Color accentOrange  = Color(0xFFEA580C); // Warm Rust Orange

  // ─── Background Layers ──────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFFF0F4F2); // Light Deep background (Sage tinted)
  static const Color bgDark    = Color(0xFFF7FAF8); // Scaffold background (Sage tinted)
  static const Color bgMedium  = Colors.white; // Card background
  static const Color bgCard    = Colors.white; // Card container
  static const Color bgSurface = Color(0xFFE5EBE7); // Surface highlights (Sage tinted)

  // ─── Text Colors ────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Deep Navy Text
  static const Color textSecondary = Color(0xFF475569); // Slate Grey Text
  static const Color textMuted     = Color(0xFF94A3B8); // Muted Grey Text

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)], // Amber to Gold
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgDeep, bgDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Glass Card Decoration ──────────────────────────────────────────────────
  static BoxDecoration get glassCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get glassCardSmall => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE2E8F0)),
  );

  static BoxDecoration get accentCard => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withValues(alpha: 0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── Text Styles ────────────────────────────────────────────────────────────
  static TextStyle headingLarge(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, height: 1.2,
  );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary, height: 1.25,
  );

  static TextStyle headingSmall(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, height: 1.3,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 15, color: textPrimary, height: 1.45,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 14, color: textSecondary, height: 1.4,
  );

  static TextStyle caption(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 12, color: textMuted, letterSpacing: 0.5, height: 1.35,
  );

  static TextStyle labelBold(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary, letterSpacing: 1.2,
  );

  // ─── MaterialApp ThemeData ──────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryGreen,
      tertiary: accentGold,
      surface: bgMedium,
      error: accentRed,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgMedium,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: bgMedium,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 14),
      labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 14),
    ),
    dividerColor: Colors.black.withValues(alpha: 0.08),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
  );

  // Keep darkTheme alias for backward compatibility with existing screen files
  static ThemeData get darkTheme => lightTheme;

  // ─── Helpers ────────────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'Live':      return primaryGreen;
      case 'Upcoming':  return primaryBlue;
      case 'Completed': return textMuted;
      default:          return textMuted;
    }
  }

  static Color roleColor(String role) {
    switch (role) {
      case 'Batter':       return primaryBlue;
      case 'Bowler':       return accentRed;
      case 'All-rounder':  return accentGold;
      default:             return textMuted;
    }
  }
}
