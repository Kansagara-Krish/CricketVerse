// lib/core/theme/app_theme.dart
// CricketVerse AI — Centralized Premium Dark Theme
// All screens import from here for consistent Material 3 look

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF0284C7);
  static const Color primaryGreen  = Color(0xFF10B981);
  static const Color accentGold    = Color(0xFFFBBF24);
  static const Color accentPurple  = Color(0xFF8B5CF6);
  static const Color accentRed     = Color(0xFFEF4444);
  static const Color accentOrange  = Color(0xFFF97316);

  // ─── Background Layers ──────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF070F1E);
  static const Color bgDark    = Color(0xFF0F172A);
  static const Color bgMedium  = Color(0xFF1E293B);
  static const Color bgCard    = Color(0xFF253046);
  static const Color bgSurface = Color(0xFF2D3F5A);

  // ─── Text Colors ────────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted     = Color(0xFF64748B);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
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
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get glassCardSmall => BoxDecoration(
    color: Colors.white.withOpacity(0.04),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white.withOpacity(0.07)),
  );

  static BoxDecoration get accentCard => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withOpacity(0.3),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // ─── Text Styles ────────────────────────────────────────────────────────────
  static TextStyle headingLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary,
  );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
  );

  static TextStyle headingSmall(BuildContext context) => GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 15, color: textPrimary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 13, color: textSecondary,
  );

  static TextStyle caption(BuildContext context) => GoogleFonts.outfit(
    fontSize: 11, color: textMuted, letterSpacing: 0.5,
  );

  static TextStyle labelBold(BuildContext context) => GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary, letterSpacing: 1.2,
  );

  // ─── MaterialApp ThemeData ──────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryGreen,
      tertiary: accentGold,
      surface: bgMedium,
      background: bgDark,
      error: accentRed,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDeep,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgMedium,
      selectedItemColor: accentGold,
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
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue),
      ),
      hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
      labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
    ),
    dividerColor: Colors.white.withOpacity(0.08),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
  );

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
