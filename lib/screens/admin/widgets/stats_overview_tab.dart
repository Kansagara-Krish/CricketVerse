import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/models.dart';
import '../../../services/storage_service.dart';

class StatsOverviewTab extends StatelessWidget {
  final StorageService storage;

  const StatsOverviewTab({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final matchCounts = [
      storage.matches.where((m) => m.status == 'Upcoming').length.toDouble(),
      storage.matches.where((m) => m.status == 'Live').length.toDouble(),
      storage.matches.where((m) => m.status == 'Completed').length.toDouble(),
    ];

    final maxVal = matchCounts.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metric Overview Cards
          Row(
            children: [
              _buildMetricCard('Matches', '${storage.matches.length}', Icons.sports_cricket, AppTheme.primaryBlue),
              const SizedBox(width: 10),
              _buildMetricCard('Teams', '${storage.teams.length}', Icons.groups_outlined, AppTheme.accentGold),
              const SizedBox(width: 10),
              _buildMetricCard('Players', '${storage.teams.fold(0, (s, t) => s + t.players.length)}', Icons.person_outline, AppTheme.accentPurple),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Chart Section
          Text(
            'MATCH STATUS DISTRIBUTION',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal == 0 ? 5 : maxVal + 1,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = ['Upcoming', 'Live', 'Completed'];
                        if (v.toInt() >= 0 && v.toInt() < 3) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[v.toInt()],
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: AppTheme.bgSurface,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(3, (i) {
                  final color = i == 0 ? AppTheme.primaryBlue : (i == 1 ? AppTheme.primaryGreen : AppTheme.textMuted);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: matchCounts[i] == 0 ? 0.2 : matchCounts[i],
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.7), color],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Top Performers Section
          Text(
            'TOP PERFORMERS',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          _buildTopPerformers(context),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bgSurface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers(BuildContext context) {
    final allPlayers = storage.teams.expand((t) => t.players).toList();
    if (allPlayers.isEmpty) return const SizedBox.shrink();

    final topBatter = (List<Player>.from(allPlayers)..sort((a, b) => b.runsScored.compareTo(a.runsScored))).first;
    final topBowler = (List<Player>.from(allPlayers)..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken))).first;

    return Row(
      children: [
        Expanded(child: _buildPerformerCard(context, topBatter, 'Top Batter', '${topBatter.runsScored} runs', Icons.sports_cricket, AppTheme.primaryBlue)),
        const SizedBox(width: 12),
        Expanded(child: _buildPerformerCard(context, topBowler, 'Top Bowler', '${topBowler.wicketsTaken} wkts', Icons.sports_baseball_outlined, AppTheme.accentRed)),
      ],
    );
  }

  Widget _buildPerformerCard(BuildContext context, Player player, String title, String stats, IconData icon, Color color) {
    final initials = player.name.split(' ').map((n) => n[0]).join().toUpperCase();

    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: player),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.bgSurface),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: AppTheme.textPrimary,
                    child: Icon(icon, size: 9, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              stats,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
