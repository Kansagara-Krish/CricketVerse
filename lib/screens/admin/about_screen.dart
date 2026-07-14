// lib/screens/admin/about_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text('About', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const AppLogo(size: 100, withGlow: true),
            const SizedBox(height: 20),
            Text(AppConstants.appName,
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('Version ${AppConstants.appVersion}',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
            const SizedBox(height: 8),
            Text(AppConstants.appTagline,
                style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            const SizedBox(height: 30),

            // Description Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('ABOUT THE APP'),
                  const SizedBox(height: 10),
                  Text(
                    'CricketVerse AI is an intelligent mobile application for live cricket scoring, AI-powered commentary, match prediction, and real-time analytics. Designed as a production-quality B.Tech Major Project prototype.',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tech Stack
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('TECHNOLOGY STACK'),
                  const SizedBox(height: 12),
                  ...[
                    ['Flutter 3.x', Icons.flutter_dash, AppTheme.primaryBlue],
                    ['Dart 3.x', Icons.code_rounded, AppTheme.accentGold],
                    ['Provider (State)', Icons.hub_rounded, AppTheme.accentPurple],
                    ['Google Fonts (Outfit)', Icons.text_fields_rounded, AppTheme.primaryGreen],
                    ['fl_chart', Icons.bar_chart_rounded, AppTheme.accentOrange],
                    ['Material 3 Design', Icons.design_services_rounded, AppTheme.accentRed],
                    ['SharedPreferences', Icons.storage_rounded, Colors.white60],
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(item[1] as IconData, color: item[2] as Color, size: 20),
                        const SizedBox(width: 12),
                        Text(item[0] as String,
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Features
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('KEY FEATURES'),
                  const SizedBox(height: 12),
                  ...[
                    '🏏 Live Ball-by-Ball Scoring',
                    '🤖 AI Commentary Generation',
                    '📊 Real-Time Win Prediction',
                    '📈 Player & Team Statistics',
                    '🏆 Tournament Management',
                    '👥 Team & Player CRUD',
                    '🔔 Smart Notifications',
                    '🌙 Premium Dark UI Design',
                  ].map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(f, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Credits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('PROJECT INFO'),
                  const SizedBox(height: 12),
                  _InfoRow('Author', 'B.Tech Computer Science Student'),
                  _InfoRow('Guide', 'Project Faculty Supervisor'),
                  _InfoRow('Institute', 'Engineering College'),
                  _InfoRow('Academic Year', '2025–2026'),
                  _InfoRow('Project Type', 'B.Tech Major Project'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('© 2026 CricketVerse AI. All rights reserved.',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1.4));
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
