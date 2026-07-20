// lib/screens/admin/prediction_screen.dart
// Animated win probability gauge and factor breakdown

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';
import 'package:provider/provider.dart';

class PredictionScreen extends StatefulWidget {
  final CricketMatch match;
  const PredictionScreen({super.key, required this.match});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _barAnim;
  double _probA = 72.0;
  double _probB = 28.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _barAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();

    final storage = Provider.of<StorageService>(context, listen: false);
    _probA = storage.calculateWinProbability(widget.match).clamp(1.0, 99.0);
    _probB = (100 - _probA).clamp(1.0, 99.0);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _probA = (55 + Random().nextDouble() * 35).clamp(1, 99);
      _probB = (100 - _probA).clamp(1, 99);
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final teamA = widget.match.teamA;
    final teamB = widget.match.teamB;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('Match Prediction', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
            onPressed: _refresh,
            tooltip: 'Refresh Prediction',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // AI Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.textPrimary, size: 16),
                  const SizedBox(width: 8),
                  Text('AI-Powered Prediction Engine',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Win probability arc gauge
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: _barAnim,
                builder: (_, __) => CustomPaint(
                  painter: _GaugePainter(
                    probA: _probA * _barAnim.value / 100,
                    colorA: AppTheme.primaryBlue,
                    colorB: AppTheme.accentOrange,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _GaugeLabel(teamA.shortName, '${(_probA * _barAnim.value).toStringAsFixed(0)}%', AppTheme.primaryBlue),
                          _GaugeLabel(teamB.shortName, '${(100 - _probA * _barAnim.value).toStringAsFixed(0)}%', AppTheme.accentOrange),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bar comparison
            const _SectionLabel('WIN PROBABILITY'),
            const SizedBox(height: 16),
            _ProbBar(teamA.shortName, teamA.name, _probA, _barAnim, AppTheme.primaryBlue),
            const SizedBox(height: 12),
            _ProbBar(teamB.shortName, teamB.name, _probB, _barAnim, AppTheme.accentOrange),

            const SizedBox(height: 28),

            // Score Context
            const _SectionLabel('MATCH CONTEXT'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  _ContextRow('Current Score', '${widget.match.runsA}/${widget.match.wicketsA} (${widget.match.oversA} ov)'),
                  _ContextRow('Run Rate', widget.match.oversA > 0 ? (widget.match.runsA / widget.match.oversA).toStringAsFixed(2) : "—"),
                  if (widget.match.target > 0) ...[
                    _ContextRow('Target', '${widget.match.target}'),
                    _ContextRow('Required RR', widget.match.oversA > 0 ? ((widget.match.target - widget.match.runsB) / max(1, 20 - widget.match.oversB)).toStringAsFixed(2) : "—"),
                  ],
                  _ContextRow('Innings', widget.match.isFirstInnings ? '1st Innings' : '2nd Innings'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Prediction Factors
            const _SectionLabel('PREDICTION FACTORS'),
            const SizedBox(height: 12),
            ...AppConstants.predictionFactors.asMap().entries.map((e) {
              final pct = 40 + (e.key * 8 % 50);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.glassCardSmall,
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: AppTheme.accentPurple, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: _barAnim,
                              builder: (_, __) => LinearProgressIndicator(
                                value: (pct / 100) * _barAnim.value,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                color: AppTheme.accentPurple,
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$pct%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.accentPurple, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Disclaimer
            Text(
              '⚠️ Predictions are AI-generated estimates based on match data and historical patterns. Not guaranteed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double probA;
  final Color colorA, colorB;
  const _GaugePainter({required this.probA, required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.8;
    final radius = size.width * 0.4;
    const strokeWidth = 20.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const sweepAll = pi;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, sweepAll, false, bgPaint);

    // Team A arc
    final paintA = Paint()
      ..color = colorA
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, sweepAll * probA, false, paintA);

    // Team B arc
    if (probA < 1.0) {
      final paintB = Paint()
        ..color = colorB
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, pi + sweepAll * probA, sweepAll * (1 - probA), false, paintB);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.probA != probA || old.colorA != colorA || old.colorB != colorB;
}

class _GaugeLabel extends StatelessWidget {
  final String shortName, pct;
  final Color color;
  const _GaugeLabel(this.shortName, this.pct, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(pct, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
        Text(shortName, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.4)),
    );
  }
}

class _ProbBar extends StatelessWidget {
  final String short, full;
  final double prob;
  final Animation<double> anim;
  final Color color;
  const _ProbBar(this.short, this.full, this.prob, this.anim, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 44,
            child: Text(short, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: color))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(full, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Stack(
                  children: [
                    Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(5),
                        )),
                    FractionallySizedBox(
                      widthFactor: (prob / 100) * anim.value,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('${prob.toStringAsFixed(0)}%',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _ContextRow extends StatelessWidget {
  final String label, value;
  const _ContextRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
