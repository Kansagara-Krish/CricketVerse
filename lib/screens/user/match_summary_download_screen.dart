import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';

class MatchSummaryDownloadScreen extends StatelessWidget {
  final Map<String, dynamic> matchDetails;

  const MatchSummaryDownloadScreen({super.key, required this.matchDetails});

  @override
  Widget build(BuildContext context) {
    final title = matchDetails['title'] ?? 'Match Summary';
    final teamAName = matchDetails['teamAName'] ?? 'Team A';
    final teamBName = matchDetails['teamBName'] ?? 'Team B';
    final scoreA = matchDetails['scoreA'] ?? '0/0';
    final scoreB = matchDetails['scoreB'] ?? '0/0';
    final oversA = matchDetails['oversA'] ?? '0.0 Overs';
    final oversB = matchDetails['oversB'] ?? '0.0 Overs';
    final resultText = matchDetails['result'] ?? 'No result available';
    final List<String> teamAPlayers = List<String>.from(matchDetails['teamAPlayers'] ?? []);
    final List<String> teamBPlayers = List<String>.from(matchDetails['teamBPlayers'] ?? []);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Match Summary', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.primaryBlue),
            onPressed: () {
              CustomNotification.show(
                context,
                'Downloading detailed PDF report for $title...',
                type: NotificationType.info,
              );
            },
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMatchResultCard(context, title, resultText),
            const SizedBox(height: 16),
            _buildTopPerformersCard(context, teamAPlayers, teamBPlayers),
            const SizedBox(height: 16),
            _buildInningsSummaryCard(context, "$teamAName Innings", scoreA, oversA, teamAPlayers),
            const SizedBox(height: 16),
            _buildInningsSummaryCard(context, "$teamBName Innings", scoreB, oversB, teamBPlayers),
            const SizedBox(height: 16),
            _buildRunRateGraphCard(context),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                CustomNotification.show(
                  context,
                  'Downloading detailed PDF report for $title...',
                  type: NotificationType.info,
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download Full Match Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchResultCard(BuildContext context, String title, String resultText) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Match Result",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resultText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersCard(BuildContext context, List<String> teamAPlayers, List<String> teamBPlayers) {
    final p1 = teamAPlayers.isNotEmpty ? teamAPlayers[0] : 'Aarav Patel';
    final p2 = teamBPlayers.isNotEmpty ? teamBPlayers[0] : 'Advik Shah';
    final p3 = teamAPlayers.length > 1 ? teamAPlayers[1] : 'Ishaan Mehta';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top Performers",
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const Divider(height: 20),
            _buildPerformerRow(p1, "Batting", "62* (38)"),
            _buildPerformerRow(p2, "Bowling", "3/18 (4.0)"),
            _buildPerformerRow(p3, "Batting", "45 (27)"),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerRow(String name, String role, String stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary)),
                Text(role, style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(stats, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildInningsSummaryCard(BuildContext context, String title, String score, String overs, List<String> players) {
    final p1 = players.isNotEmpty ? players[0] : 'Batsman A';
    final p2 = players.length > 1 ? players[1] : 'Batsman B';
    final p3 = players.length > 2 ? players[2] : 'Bowler X';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  "$score ($overs)",
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const Divider(height: 20),
            Text("Top Batsmen", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p1, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)), Text("45 (30)", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p2, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)), Text("30 (20)", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Text("Top Bowlers", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p3, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)), Text("2/20 (4.0)", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  Widget _buildRunRateGraphCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Run Rate Comparison",
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0),
                        FlSpot(5, 30),
                        FlSpot(10, 75),
                        FlSpot(15, 120),
                        FlSpot(20, 200),
                      ],
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withValues(alpha: 0.08)),
                    ),
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0),
                        FlSpot(5, 45),
                        FlSpot(10, 80),
                        FlSpot(15, 130),
                        FlSpot(20, 185),
                      ],
                      isCurved: true,
                      color: AppTheme.accentRed,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppTheme.accentRed.withValues(alpha: 0.08)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
