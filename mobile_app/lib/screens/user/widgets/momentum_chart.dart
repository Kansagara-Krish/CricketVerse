import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class MomentumChart extends StatelessWidget {
  final CricketMatch match;

  const MomentumChart({
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
    final teamBColor = _parseColor(match.teamB.logoColorHex, AppTheme.accentOrange);

    // Simulated momentum data points from -1.0 to 1.0 (Team B advantage to Team A advantage)
    final List<double> momentumPoints = [
      0.1, 0.3, 0.4, 0.2, -0.1, -0.3, -0.2, 0.2, 0.5, 0.7, 0.4, 0.6, 0.5, 0.3, -0.1, -0.4, -0.5, -0.2, 0.3, 0.5
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Match Momentum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE TRACKER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _SplitMomentumPainter(
                points: momentumPoints,
                colorA: teamAColor,
                colorB: teamBColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '▲ ${match.teamA.shortName} Advantage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: teamAColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '▼ ${match.teamB.shortName} Advantage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: teamBColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitMomentumPainter extends CustomPainter {
  final List<double> points;
  final Color colorA;
  final Color colorB;

  _SplitMomentumPainter({
    required this.points,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double midY = size.height / 2;
    final double stepX = size.width / (points.length - 1);

    // Draw midline (Neutral)
    final Paint linePaint = Paint()
      ..color = AppTheme.bgSurface
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);

    final Path path = Path();
    // Build path starting at first point
    double getMappedY(double value) {
      // value is from -1.0 to 1.0. Map it to height.
      // -1.0 -> bottom (size.height), 1.0 -> top (0)
      return midY - (value * (size.height / 2) * 0.8);
    }

    path.moveTo(0, getMappedY(points.first));

    for (int i = 1; i < points.length; i++) {
      final double x = i * stepX;
      final double y = getMappedY(points[i]);
      final double prevX = (i - 1) * stepX;
      final double prevY = getMappedY(points[i - 1]);

      // Control points for smooth bezier curve
      final double cx1 = prevX + stepX / 2;
      final double cy1 = prevY;
      final double cx2 = prevX + stepX / 2;
      final double cy2 = y;

      path.cubicTo(cx1, cy1, cx2, cy2, x, y);
    }

    // Draw the gradient filled area under the curve
    final Path fillPath = Path.from(path)
      ..lineTo(size.width, midY)
      ..lineTo(0, midY)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          colorA.withValues(alpha: 0.25),
          colorA.withValues(alpha: 0.0),
          colorB.withValues(alpha: 0.0),
          colorB.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.48, 0.52, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw curve line
    final Paint pathPaint = Paint()
      ..shader = LinearGradient(
        colors: [colorA, colorB],
        stops: const [0.35, 0.65],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _SplitMomentumPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.colorA != colorA ||
      oldDelegate.colorB != colorB;
}
