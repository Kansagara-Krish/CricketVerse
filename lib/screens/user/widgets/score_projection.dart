import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class ScoreProjection extends StatelessWidget {
  final CricketMatch match;

  const ScoreProjection({
    super.key,
    required this.match,
  });

  Color _parseColor(String hex, Color fallback) {
    try {
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      try {
        return Color(int.parse(hex));
      } catch (_) {
        return fallback;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAColor = _parseColor(match.teamA.logoColorHex, AppTheme.primaryBlue);
    final teamBColor = _parseColor(match.teamB.logoColorHex, AppTheme.textSecondary);

    // Simulated projected scores (Normally calculated using overs and run rates)
    final projMinA = match.runsA + (match.oversA > 0 ? (match.runsA / match.oversA * (20 - match.oversA)).round() : 160);
    final projMaxA = projMinA + 15;
    final projMinB = match.runsB + (match.oversB > 0 ? (match.runsB / match.oversB * (20 - match.oversB)).round() : 150);
    final projMaxB = projMinB + 15;

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
              const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Projected Total Scores',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProjectionBarRow(
            teamShortName: match.teamA.shortName,
            minScore: projMinA,
            maxScore: projMaxA,
            color: teamAColor,
            relativeStartPercent: 0.45,
            relativeWidthPercent: 0.35,
          ),
          const SizedBox(height: 20),
          _ProjectionBarRow(
            teamShortName: match.teamB.shortName,
            minScore: projMinB,
            maxScore: projMaxB,
            color: teamBColor,
            relativeStartPercent: 0.3,
            relativeWidthPercent: 0.3,
          ),
        ],
      ),
    );
  }
}

class _ProjectionBarRow extends StatelessWidget {
  final String teamShortName;
  final int minScore;
  final int maxScore;
  final Color color;
  final double relativeStartPercent;
  final double relativeWidthPercent;

  const _ProjectionBarRow({
    required this.teamShortName,
    required this.minScore,
    required this.maxScore,
    required this.color,
    required this.relativeStartPercent,
    required this.relativeWidthPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              teamShortName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '$minScore - $maxScore runs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: relativeStartPercent + relativeWidthPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: relativeWidthPercent / (relativeStartPercent + relativeWidthPercent),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.7), color],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
