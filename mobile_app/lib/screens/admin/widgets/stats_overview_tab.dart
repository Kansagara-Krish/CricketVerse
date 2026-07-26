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
    final allPlayers = storage.teams.expand((t) => t.players).toList();
    final totalRuns = allPlayers.fold<int>(0, (sum, p) => sum + p.runsScored);
    final totalWickets = allPlayers.fold<int>(0, (sum, p) => sum + p.wicketsTaken);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metric Overview Cards (2 rows for rich data)
          Row(
            children: [
              _buildMetricCard('Total Matches', '${storage.matches.length}', Icons.sports_cricket, AppTheme.primaryBlue),
              const SizedBox(width: 10),
              _buildMetricCard('Teams Enrolled', '${storage.teams.length}', Icons.groups_outlined, AppTheme.accentGold),
              const SizedBox(width: 10),
              _buildMetricCard('Total Players', '${allPlayers.length}', Icons.person_outline, AppTheme.accentPurple),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricCard('Total Runs', '$totalRuns', Icons.bolt, const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _buildMetricCard('Wickets Taken', '$totalWickets', Icons.sports_baseball, const Color(0xFFEF4444)),
              const SizedBox(width: 10),
              _buildMetricCard('Avg Run Rate', '8.42', Icons.trending_up, const Color(0xFF0284C7)),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Tournament Highlights / Meaningful Insights
          Text(
            'TOURNAMENT MILESTONES & INSIGHTS',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInsightRow(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Highest Team Total',
                  value: '218/3 in 20.0 ov',
                  subtitle: 'UVPCE - Titans vs UVPCE - Warriors',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildInsightRow(
                  icon: Icons.flash_on_rounded,
                  iconColor: AppTheme.primaryBlue,
                  title: 'Best Individual Strike Rate',
                  value: '184.5 (50+ runs)',
                  subtitle: 'Aarav Patel (UVPCE - Titans)',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildInsightRow(
                  icon: Icons.sports_cricket_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Best Bowling Figure in Match',
                  value: '4/18 (4.0 ov)',
                  subtitle: 'Advik Shah (UVPCE - Warriors)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Match Status Chart Section
          Text(
            'MATCH STATUS DISTRIBUTION',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            height: 210,
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

          // 4. Top Performers Section
          Text(
            'TOP PERFORMERS',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          _buildTopPerformers(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bgSurface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
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

