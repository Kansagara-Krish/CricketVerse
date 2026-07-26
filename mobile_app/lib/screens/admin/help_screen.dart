// lib/screens/admin/help_screen.dart
// FAQ accordion and support options

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _openIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('Help & FAQ', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), AppTheme.primaryBlue],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_rounded, color: AppTheme.textPrimary, size: 32),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Help Center', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('Find answers to common questions', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('FREQUENTLY ASKED QUESTIONS',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.3)),
            const SizedBox(height: 14),

            // FAQ Accordion
            ...AppConstants.faqItems.asMap().entries.map((entry) {
              final i = entry.key;
              final faq = entry.value;
              final isOpen = _openIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _openIndex = isOpen ? -1 : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOpen
                          ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['question']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: isOpen ? FontWeight.w700 : FontWeight.w500,
                                  color: isOpen ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                            Icon(
                              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: isOpen ? AppTheme.primaryBlue : Colors.black38,
                            ),
                          ],
                        ),
                      ),
                      if (isOpen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Column(
                            children: [
                              Divider(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                              const SizedBox(height: 8),
                              Text(
                                faq['answer']!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0x990F172A), height: 1.6),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            Text('CONTACT SUPPORT',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.3)),
            const SizedBox(height: 14),

            _SupportOption(Icons.email_outlined, 'Email Support', 'support@cricketverse.ai', AppTheme.primaryBlue, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening email client...')),
              );
            }),
            const SizedBox(height: 10),
            _SupportOption(Icons.chat_bubble_outline_rounded, 'Live Chat', 'Available 9 AM – 6 PM IST', AppTheme.primaryGreen, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting live chat...')),
              );
            }),
            const SizedBox(height: 10),
            _SupportOption(Icons.bug_report_outlined, 'Report a Bug', 'Help us improve the app', AppTheme.accentOrange, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report form opened')),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SupportOption(this.icon, this.title, this.subtitle, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
