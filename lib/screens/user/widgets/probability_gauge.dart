import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../core/theme/app_theme.dart';

class ProbabilityGauge extends StatefulWidget {
  final CricketMatch match;
  final double winProbability; // value between 0.0 and 100.0

  const ProbabilityGauge({
    super.key,
    required this.match,
    required this.winProbability,
  });

  @override
  State<ProbabilityGauge> createState() => _ProbabilityGaugeState();
}

class _ProbabilityGaugeState extends State<ProbabilityGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProbabilityGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.winProbability != widget.winProbability) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final teamAColor = _parseColor(widget.match.teamA.logoColorHex, AppTheme.primaryBlue);
    final teamBColor = _parseColor(widget.match.teamB.logoColorHex, AppTheme.textSecondary);

    final displayProb = widget.winProbability.clamp(1.0, 99.0);
    final isLeadingA = displayProb >= 50.0;
    final leadPercentage = isLeadingA ? displayProb : (100.0 - displayProb);
    final leadTeamName = isLeadingA ? widget.match.teamA.shortName : widget.match.teamB.shortName;
    final leadColor = isLeadingA ? teamAColor : teamBColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
        children: [
          Text(
            'Match Outcome Prediction',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final animatedValue = displayProb * _animation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 175,
                    height: 175,
                    child: CircularProgressIndicator(
                      value: animatedValue / 100.0,
                      strokeWidth: 12,
                      backgroundColor: teamBColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(teamAColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    width: 140,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${leadPercentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: leadColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leadTeamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'WIN CHANCE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _TeamProbabilityRow(
                  name: widget.match.teamA.shortName,
                  fullName: widget.match.teamA.name,
                  percentage: displayProb,
                  color: teamAColor,
                  alignLeft: true,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppTheme.bgSurface,
              ),
              Expanded(
                child: _TeamProbabilityRow(
                  name: widget.match.teamB.shortName,
                  fullName: widget.match.teamB.name,
                  percentage: 100.0 - displayProb,
                  color: teamBColor,
                  alignLeft: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamProbabilityRow extends StatelessWidget {
  final String name;
  final String fullName;
  final double percentage;
  final Color color;
  final bool alignLeft;

  const _TeamProbabilityRow({
    required this.name,
    required this.fullName,
    required this.percentage,
    required this.color,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (alignLeft) ...[
                CircleAvatar(radius: 4, backgroundColor: color),
                const SizedBox(width: 6),
              ],
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (!alignLeft) ...[
                const SizedBox(width: 6),
                CircleAvatar(radius: 4, backgroundColor: color),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
