// lib/core/theme/app_theme.dart
// CricketVerse AI — Centralized Premium Light Theme
// All screens import from here for consistent Material 3 look

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF0284C7); // Vibrant Sky Blue
  static const Color primaryGreen  = Color(0xFF10B981); // Emerald Green
  static const Color accentGold    = Color(0xFFF59E0B); // Glowing Gold
  static const Color accentPurple  = Color(0xFF8B5CF6); // Premium Purple
  static const Color accentRed     = Color(0xFFEF4444); // Coral Red
  static const Color accentOrange  = Color(0xFFF97316); // Orange

  // ─── Background Layers ──────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFFF1F5F9); // Light Deep background
  static const Color bgDark    = Color(0xFFF8FAFC); // Scaffold background
  static const Color bgMedium  = Colors.white; // Card background
  static const Color bgCard    = Colors.white; // Card container
  static const Color bgSurface = Color(0xFFE2E8F0); // Surface highlights

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
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
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
        color: primaryBlue.withOpacity(0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── Text Styles ────────────────────────────────────────────────────────────
  static TextStyle headingLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary,
  );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
  );

  static TextStyle headingSmall(BuildContext context) => GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 14, color: textPrimary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 13, color: textSecondary,
  );

  static TextStyle caption(BuildContext context) => GoogleFonts.outfit(
    fontSize: 11, color: textMuted, letterSpacing: 0.5,
  );

  static TextStyle labelBold(BuildContext context) => GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary, letterSpacing: 1.2,
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
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary,
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
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 13),
      labelStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 13),
    ),
    dividerColor: Colors.black.withOpacity(0.08),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
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
