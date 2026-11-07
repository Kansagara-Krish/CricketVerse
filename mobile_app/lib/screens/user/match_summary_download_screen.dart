import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../services/pdf_report_service.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';

class MatchSummaryDownloadScreen extends StatefulWidget {
  final Map<String, dynamic> matchDetails;

  const MatchSummaryDownloadScreen({super.key, required this.matchDetails});

  @override
  State<MatchSummaryDownloadScreen> createState() => _MatchSummaryDownloadScreenState();
}

class _MatchSummaryDownloadScreenState extends State<MatchSummaryDownloadScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _handleDownloadPdf(String title, CricketMatch? match) async {
    setState(() => _isGeneratingPdf = true);
    CustomNotification.show(
      context,
      'Generating high quality PDF report...',
      type: NotificationType.info,
    );

    try {
      final detailsWithMatch = Map<String, dynamic>.from(widget.matchDetails);
      if (match != null) {
        detailsWithMatch['match'] = match;
      }

      await PdfReportService.generateAndShareReport(
        context: context,
        matchDetails: detailsWithMatch,
      );
      if (!mounted) return;
      CustomNotification.show(
        context,
        '✅ PDF Report successfully compiled!',
        type: NotificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomNotification.show(
        context,
        'Failed to generate PDF: ${e.toString()}',
        type: NotificationType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final matchId = widget.matchDetails['matchId'] as String?;
    final CricketMatch? match = widget.matchDetails['match'] as CricketMatch? ??
        (matchId != null && storage.matches.isNotEmpty
            ? storage.matches.where((m) => m.id == matchId).firstOrNull
            : null);

    final title = widget.matchDetails['title'] ?? (match != null ? '${match.teamA.shortName} vs ${match.teamB.shortName}' : 'Match Summary');
    final teamAName = match?.teamA.name ?? widget.matchDetails['teamAName'] ?? 'Team A';
    final teamBName = match?.teamB.name ?? widget.matchDetails['teamBName'] ?? 'Team B';
    final scoreA = match != null ? '${match.runsA}/${match.wicketsA}' : (widget.matchDetails['scoreA'] ?? '0/0');
    final scoreB = match != null ? '${match.runsB}/${match.wicketsB}' : (widget.matchDetails['scoreB'] ?? '0/0');
    final oversA = match != null ? '${match.oversA} Overs' : (widget.matchDetails['oversA'] ?? '0.0 Overs');
    final oversB = match != null ? '${match.oversB} Overs' : (widget.matchDetails['oversB'] ?? '0.0 Overs');
    final resultText = match != null && match.resultText.isNotEmpty
        ? match.resultText
        : (widget.matchDetails['result'] ?? 'No result available');

    final teamAPlayers = match != null
        ? (match.playingXI_A.isNotEmpty ? match.playingXI_A : match.teamA.players)
        : <Player>[];
    final teamBPlayers = match != null
        ? (match.playingXI_B.isNotEmpty ? match.playingXI_B : match.teamB.players)
        : <Player>[];

    final fallbackNamesA = List<String>.from(widget.matchDetails['teamAPlayers'] ?? []);
    final fallbackNamesB = List<String>.from(widget.matchDetails['teamBPlayers'] ?? []);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Match Summary', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                  )
                : const Icon(Icons.download, color: AppTheme.primaryBlue),
            onPressed: _isGeneratingPdf ? null : () => _handleDownloadPdf(title, match),
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
            _buildTopPerformersCard(context, match, fallbackNamesA, fallbackNamesB),
            const SizedBox(height: 16),
            _buildInningsSummaryCard(context, "$teamAName Innings", scoreA, oversA, teamAPlayers, fallbackNamesA, teamBPlayers),
            const SizedBox(height: 16),
            _buildInningsSummaryCard(context, "$teamBName Innings", scoreB, oversB, teamBPlayers, fallbackNamesB, teamAPlayers),
            const SizedBox(height: 16),
            _buildRunRateGraphCard(context, match),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isGeneratingPdf ? null : () => _handleDownloadPdf(title, match),
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Download Full Match Report'),
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

  Widget _buildTopPerformersCard(BuildContext context, CricketMatch? match, List<String> fallbackA, List<String> fallbackB) {
    if (match != null) {
      final allPlayers = [...match.playingXI_A, ...match.playingXI_B];
      final batters = allPlayers
          .where((p) => p.runsScored > 0 || p.ballsFaced > 0)
          .toList()
        ..sort((a, b) => b.runsScored.compareTo(a.runsScored));
      final bowlers = allPlayers
          .where((p) => p.oversBowled > 0 || p.wicketsTaken > 0 || p.runsConceded > 0)
          .toList()
        ..sort((a, b) {
          final c = b.wicketsTaken.compareTo(a.wicketsTaken);
          if (c != 0) return c;
          return a.runsConceded.compareTo(b.runsConceded);
        });

      final p1 = batters.isNotEmpty ? batters[0] : null;
      final p2 = bowlers.isNotEmpty ? bowlers[0] : null;
      final p3 = batters.length > 1 ? batters[1] : (bowlers.length > 1 ? bowlers[1] : null);

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
                "Top Match Performers",
                style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const Divider(height: 20),
              if (p1 != null)
                _buildPerformerRow(p1.name, "Top Batter", "${p1.runsScored}${p1.isOut ? '' : '*'} (${p1.ballsFaced})")
              else
                _buildPerformerRow(fallbackA.isNotEmpty ? fallbackA[0] : 'Top Batter', "Batting", "0 (0)"),
              if (p2 != null)
                _buildPerformerRow(p2.name, "Top Bowler", "${p2.wicketsTaken}/${p2.runsConceded} (${p2.oversBowled.toStringAsFixed(1)})")
              else
                _buildPerformerRow(fallbackB.isNotEmpty ? fallbackB[0] : 'Top Bowler', "Bowling", "0/0 (0.0)"),
              if (p3 != null)
                _buildPerformerRow(
                  p3.name,
                  p3.runsScored > 0 ? "Key Batter" : "Key Bowler",
                  p3.runsScored > 0
                      ? "${p3.runsScored}${p3.isOut ? '' : '*'} (${p3.ballsFaced})"
                      : "${p3.wicketsTaken}/${p3.runsConceded} (${p3.oversBowled.toStringAsFixed(1)})",
                ),
            ],
          ),
        ),
      );
    }

    final p1 = fallbackA.isNotEmpty ? fallbackA[0] : 'Batter 1';
    final p2 = fallbackB.isNotEmpty ? fallbackB[0] : 'Bowler 1';
    final p3 = fallbackA.length > 1 ? fallbackA[1] : 'Batter 2';

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
            _buildPerformerRow(p1, "Batting", "0 (0)"),
            _buildPerformerRow(p2, "Bowling", "0/0 (0.0)"),
            _buildPerformerRow(p3, "Batting", "0 (0)"),
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

  Widget _buildInningsSummaryCard(
    BuildContext context,
    String title,
    String score,
    String overs,
    List<Player> batPlayers,
    List<String> fallbackNames,
    List<Player> bowlPlayers,
  ) {
    final sortedBatters = batPlayers.where((p) => p.runsScored > 0 || p.ballsFaced > 0).toList()..sort((a, b) => b.runsScored.compareTo(a.runsScored));
    final sortedBowlers = bowlPlayers.where((p) => p.oversBowled > 0 || p.wicketsTaken > 0).toList()..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken));

    final b1Name = sortedBatters.isNotEmpty ? sortedBatters[0].name : (fallbackNames.isNotEmpty ? fallbackNames[0] : 'Batter 1');
    final b1Stats = sortedBatters.isNotEmpty ? "${sortedBatters[0].runsScored}${sortedBatters[0].isOut ? '' : '*'} (${sortedBatters[0].ballsFaced})" : "0 (0)";
    final b2Name = sortedBatters.length > 1 ? sortedBatters[1].name : (fallbackNames.length > 1 ? fallbackNames[1] : 'Batter 2');
    final b2Stats = sortedBatters.length > 1 ? "${sortedBatters[1].runsScored}${sortedBatters[1].isOut ? '' : '*'} (${sortedBatters[1].ballsFaced})" : "0 (0)";

    final bwName = sortedBowlers.isNotEmpty ? sortedBowlers[0].name : 'Bowler 1';
    final bwStats = sortedBowlers.isNotEmpty ? "${sortedBowlers[0].wicketsTaken}/${sortedBowlers[0].runsConceded} (${sortedBowlers[0].oversBowled.toStringAsFixed(1)})" : "0/0 (0.0)";

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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(b1Name, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)), Text(b1Stats, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(b2Name, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)), Text(b2Stats, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Text("Top Bowlers", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(bwName, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)), Text(bwStats, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildRunProgressionSpots(CricketMatch? match, bool forTeamA) {
    if (match == null) return const [FlSpot(0, 0)];
    final teamId = forTeamA ? match.teamA.id : match.teamB.id;
    final totalRuns = forTeamA ? match.runsA : match.runsB;
    final totalOvers = forTeamA ? match.oversA : match.oversB;

    if (totalOvers <= 0 && totalRuns <= 0) {
      return const [FlSpot(0, 0)];
    }

    final teamBalls = match.balls.where((b) {
      if (b.battingTeamId != null && b.battingTeamId!.isNotEmpty) {
        return b.battingTeamId == teamId;
      }
      final isTeamAInnings1 = (match.tossDecision.toLowerCase() == 'bat' &&
              (match.tossWinner == match.teamA.name || match.tossWinner == 'Team A' || match.tossWinner == match.teamA.shortName)) ||
          (match.tossDecision.toLowerCase() == 'bowl' &&
              (match.tossWinner == match.teamB.name || match.tossWinner == 'Team B' || match.tossWinner == match.teamB.shortName));
      final teamAInnings = isTeamAInnings1 ? 1 : 2;
      return forTeamA ? (b.innings == teamAInnings) : (b.innings != teamAInnings);
    }).toList();

    if (teamBalls.isNotEmpty) {
      final List<FlSpot> spots = [const FlSpot(0, 0)];
      int cumulative = 0;
      final Map<int, int> overEndRuns = {};

      for (final b in teamBalls) {
        cumulative += (b.run + b.extraRun);
        final ov = b.over ?? 0.0;
        overEndRuns[ov.floor()] = cumulative;
      }

      final int completedOvers = totalOvers.floor();
      for (int ov = 1; ov <= completedOvers; ov++) {
        if (overEndRuns.containsKey(ov)) {
          spots.add(FlSpot(ov.toDouble(), overEndRuns[ov]!.toDouble()));
        } else if (overEndRuns.containsKey(ov - 1)) {
          spots.add(FlSpot(ov.toDouble(), overEndRuns[ov - 1]!.toDouble()));
        }
      }
      if (spots.isEmpty || (spots.last.x - totalOvers).abs() > 0.05) {
        spots.add(FlSpot(totalOvers, totalRuns.toDouble()));
      }
      return spots;
    }

    return [const FlSpot(0, 0), FlSpot(totalOvers > 0 ? totalOvers : 1, totalRuns.toDouble())];
  }

  Widget _buildRunRateGraphCard(BuildContext context, CricketMatch? match) {
    final spotsA = _buildRunProgressionSpots(match, true);
    final spotsB = _buildRunProgressionSpots(match, false);
    final maxScore = match != null ? (match.runsA > match.runsB ? match.runsA : match.runsB) : 100;
    final maxY = ((maxScore * 1.15) / 25).ceil() * 25.0;

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
              "Match Score Progression (Runs / Overs)",
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY > 50 ? maxY : 50,
                  minX: 0,
                  maxX: 20,
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
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}ov', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spotsA,
                      isCurved: spotsA.length > 2,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withValues(alpha: 0.08)),
                    ),
                    LineChartBarData(
                      spots: spotsB,
                      isCurved: spotsB.length > 2,
                      color: AppTheme.accentRed,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
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
