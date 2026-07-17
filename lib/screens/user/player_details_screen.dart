import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';

class PlayerDetailsScreen extends StatelessWidget {
  final Player player;
  const PlayerDetailsScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strikeRate = player.ballsFaced > 0 ? (player.runsScored / player.ballsFaced) * 100 : 0.0;
    final economy = player.oversBowled > 0 ? player.runsConceded / player.oversBowled : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Player Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        player.name.substring(0, 1),
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    player.name,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player.role} • ${player.nationality}',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Career Stats Card
            Text(
              'CAREER STATISTICS',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0x990F172A), letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.textPrimary.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  _buildStatRow('Matches Played', '${player.matchesPlayed}'),
                  const Divider(color: const Color(0x1A0F172A)),
                  if (player.role != 'Bowler') ...[
                    _buildStatRow('Runs Scored', '${player.runsScored}'),
                    const Divider(color: const Color(0x1A0F172A)),
                    _buildStatRow('Balls Faced', '${player.ballsFaced}'),
                    const Divider(color: const Color(0x1A0F172A)),
                    _buildStatRow('Strike Rate', strikeRate.toStringAsFixed(1)),
                    if (player.role == 'All-rounder') const Divider(color: const Color(0x1A0F172A)),
                  ],
                  if (player.role != 'Batter') ...[
                    _buildStatRow('Wickets Taken', '${player.wicketsTaken}'),
                    const Divider(color: const Color(0x1A0F172A)),
                    _buildStatRow('Runs Conceded', '${player.runsConceded}'),
                    const Divider(color: const Color(0x1A0F172A)),
                    _buildStatRow('Overs Bowled', player.oversBowled.toStringAsFixed(1)),
                    const Divider(color: const Color(0x1A0F172A)),
                    _buildStatRow('Economy Rate', economy.toStringAsFixed(2)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Performance Graph Section
            Text(
              'PERFORMANCE WORM (LAST 8 MATCHES)',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0x990F172A), letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomPaint(
                painter: PlayerPerformancePainter(player.role == 'Bowler'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary)),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// Custom Painter for Player Performance Worm Graph
class PlayerPerformancePainter extends CustomPainter {
  final bool isBowler;
  PlayerPerformancePainter(this.isBowler);

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> values = isBowler
        ? [0, 2, 1, 3, 0, 4, 1, 2] // Wickets per match
        : [15, 45, 12, 85, 34, 120, 62, 78]; // Runs per match

    final double maxVal = values.fold(1.0, (max, v) => v > max ? v : max);
    final double widthBetweenPoints = size.width / (values.length - 1);

    final linePaint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = i * widthBetweenPoints;
      final double y = size.height - ((values[i] / maxVal) * (size.height - 20) + 10);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw dots and text
    for (int i = 0; i < values.length; i++) {
      final double x = i * widthBetweenPoints;
      final double y = size.height - ((values[i] / maxVal) * (size.height - 20) + 10);
      
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Label values above dots
      final textPainter = TextPainter(
        text: TextSpan(
          text: isBowler ? '${values[i].toInt()}W' : '${values[i].toInt()}',
          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), y - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
