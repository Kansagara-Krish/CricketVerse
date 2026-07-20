import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class PredictionIndicators extends StatelessWidget {
  const PredictionIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    final factors = [
      _FactorData('Historical Form Index', 82, AppTheme.primaryBlue, Icons.history_edu),
      _FactorData('Pitch & Conditions Matchup', 68, AppTheme.primaryGreen, Icons.wb_sunny_outlined),
      _FactorData('Toss Advantage Impact', 45, AppTheme.accentGold, Icons.toll_outlined),
      _FactorData('Recent Head-to-Head Ratio', 75, AppTheme.accentOrange, Icons.compare_arrows),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgSurface),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppTheme.accentOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Analysis Factors',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...factors.map((f) => _FactorRow(factor: f)),
        ],
      ),
    );
  }
}

class _FactorData {
  final String title;
  final int percentage;
  final Color color;
  final IconData icon;

  _FactorData(this.title, this.percentage, this.color, this.icon);
}

class _FactorRow extends StatelessWidget {
  final _FactorData factor;

  const _FactorRow({required this.factor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: factor.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(factor.icon, color: factor.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      factor.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${factor.percentage}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: factor.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: factor.percentage / 100.0,
                    backgroundColor: AppTheme.bgSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(factor.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
