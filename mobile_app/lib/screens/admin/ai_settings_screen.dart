// lib/screens/admin/ai_settings_screen.dart
// AI feature configuration settings

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  bool _aiCommentary = true;
  bool _autoGenerate = false;
  bool _winPrediction = true;
  bool _smartAlerts = true;
  bool _playerInsights = false;
  double _commentaryFrequency = 3.0;
  String _commentaryStyle = 'Professional';
  String _predictionModel = 'Advanced ML';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('AI Settings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () {
              CustomNotification.show(
                context,
                'AI Settings saved successfully!',
                type: NotificationType.success,
              );
            },
            child: Text('Save', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Branding Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CricketVerse AI Engine', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Configure AI features for your app', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('v1.0', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const _SectionLabel('COMMENTARY'),
            const SizedBox(height: 12),
            _SwitchTile(Icons.record_voice_over_rounded, 'AI Commentary', 'Generate intelligent ball-by-ball commentary', _aiCommentary,
                (v) => setState(() => _aiCommentary = v), AppTheme.primaryBlue),
            _SwitchTile(Icons.play_circle_outlined, 'Auto-Generate', 'Automatically add commentary on each ball', _autoGenerate,
                (v) => setState(() => _autoGenerate = v), AppTheme.primaryGreen),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Commentary Frequency', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary)),
                      Text('${_commentaryFrequency.toInt()}s', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _commentaryFrequency,
                    min: 1, max: 10,
                    divisions: 9,
                    activeColor: AppTheme.primaryBlue,
                    inactiveColor: Colors.white.withValues(alpha: 0.1),
                    onChanged: (v) => setState(() => _commentaryFrequency = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            _DropdownTile(
              'Commentary Style',
              _commentaryStyle,
              const ['Professional', 'Casual', 'Excited', 'Technical'],
              (v) => setState(() => _commentaryStyle = v),
            ),

            const SizedBox(height: 24),
            const _SectionLabel('PREDICTION ENGINE'),
            const SizedBox(height: 12),
            _SwitchTile(Icons.auto_awesome, 'Win Probability', 'Show real-time win probability gauge', _winPrediction,
                (v) => setState(() => _winPrediction = v), AppTheme.accentPurple),
            _SwitchTile(Icons.notifications_active_outlined, 'Smart Alerts', 'Alert on major probability shifts', _smartAlerts,
                (v) => setState(() => _smartAlerts = v), AppTheme.accentGold),
            _SwitchTile(Icons.insights_rounded, 'Player Insights', 'Show individual player contribution scores', _playerInsights,
                (v) => setState(() => _playerInsights = v), AppTheme.accentOrange),

            const SizedBox(height: 10),
            _DropdownTile(
              'Prediction Model',
              _predictionModel,
              const ['Simple Average', 'Advanced ML', 'Historical + Live'],
              (v) => setState(() => _predictionModel = v),
            ),

            const SizedBox(height: 24),
            const _SectionLabel('MODEL INFO'),
            const SizedBox(height: 12),
            ...[
              ['Current Run Rate', 'Weight: 25%'],
              ['Required Run Rate', 'Weight: 20%'],
              ['Wickets in Hand', 'Weight: 20%'],
              ['Powerplay Performance', 'Weight: 15%'],
              ['Head-to-Head', 'Weight: 12%'],
              ['Pitch & Weather', 'Weight: 8%'],
            ].map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: AppTheme.glassCardSmall,
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppTheme.accentPurple, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item[0], style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary))),
                  Text(item[1], style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.accentPurple, fontWeight: FontWeight.w600)),
                ],
              ),
            )),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  CustomNotification.show(
                    context,
                    'AI Settings saved successfully!',
                    type: NotificationType.success,
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save AI Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.4));
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  const _SwitchTile(this.icon, this.title, this.subtitle, this.value, this.onChanged, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? color : Colors.black38, size: 22),
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
          Switch(value: value, onChanged: onChanged, activeThumbColor: color),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String current;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _DropdownTile(this.label, this.current, this.options, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: current,
        dropdownColor: AppTheme.bgMedium,
        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}
