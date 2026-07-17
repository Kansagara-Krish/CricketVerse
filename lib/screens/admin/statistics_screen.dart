// lib/screens/admin/statistics_screen.dart
// Top batters, bowlers tables with fl_chart bar chart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final allPlayers = storage.teams.expand((t) => t.players).toList();
    final topBatters = List<Player>.from(allPlayers)
      ..sort((a, b) => b.runsScored.compareTo(a.runsScored));
    final topBowlers = List<Player>.from(allPlayers)
      ..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('Statistics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Batters'),
            Tab(text: 'Bowlers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(storage: storage),
          _BatterTab(players: topBatters.take(10).toList()),
          _BowlerTab(players: topBowlers.take(10).toList()),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final StorageService storage;
  const _OverviewTab({required this.storage});

  @override
  Widget build(BuildContext context) {
    final matchCounts = [
      storage.matches.where((m) => m.status == 'Upcoming').length.toDouble(),
      storage.matches.where((m) => m.status == 'Live').length.toDouble(),
      storage.matches.where((m) => m.status == 'Completed').length.toDouble(),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              _MiniCard('Total Matches', '${storage.matches.length}', AppTheme.primaryBlue),
              const SizedBox(width: 10),
              _MiniCard('Total Teams', '${storage.teams.length}', AppTheme.accentGold),
              const SizedBox(width: 10),
              _MiniCard('Total Players',
                  '${storage.teams.fold(0, (s, t) => s + t.players.length)}', AppTheme.accentPurple),
            ],
          ),
          const SizedBox(height: 24),

          Text('MATCH STATUS DISTRIBUTION',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted, letterSpacing: 1.3)),
          const SizedBox(height: 16),

          // Bar Chart
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (matchCounts.reduce((a, b) => a > b ? a : b) + 2),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = ['Upcoming', 'Live', 'Completed'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[v.toInt()],
                              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.textPrimary.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(3, (i) {
                  final colors = [AppTheme.primaryBlue, AppTheme.primaryGreen, Colors.black38];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: matchCounts[i] == 0 ? 0.5 : matchCounts[i],
                      color: colors[i],
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ]);
                }),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text('TOP PERFORMERS',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted, letterSpacing: 1.3)),
          const SizedBox(height: 12),

          // Top batter quick view
          _buildTopCard(context, storage),
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, StorageService storage) {
    final allPlayers = storage.teams.expand((t) => t.players).toList();
    final topBatter = (List<Player>.from(allPlayers)
          ..sort((a, b) => b.runsScored.compareTo(a.runsScored)))
        .first;
    final topBowler = (List<Player>.from(allPlayers)
          ..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken)))
        .first;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: topBatter),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  const Icon(Icons.sports_cricket, color: AppTheme.primaryBlue),
                  const SizedBox(height: 6),
                  Text('Top Batter', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(topBatter.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                  Text('${topBatter.runsScored} runs',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: topBowler),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  const Icon(Icons.sports_baseball, color: AppTheme.accentRed),
                  const SizedBox(height: 6),
                  Text('Top Bowler', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(topBowler.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                  Text('${topBowler.wicketsTaken} wkts',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.accentRed)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Batters Tab ──────────────────────────────────────────────────────────────
class _BatterTab extends StatelessWidget {
  final List<Player> players;
  const _BatterTab({required this.players});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        final avg = p.matchesPlayed > 0 ? p.runsScored / p.matchesPlayed : 0.0;
        final sr = p.ballsFaced > 0 ? (p.runsScored / p.ballsFaced) * 100 : 0.0;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassCard,
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < 3 ? AppTheme.accentGold.withOpacity(0.2) : Colors.black.withOpacity(0.06),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: i < 3 ? AppTheme.accentGold : Colors.black38)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('${p.role} • ${p.nationality}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${p.runsScored}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                    Text('runs', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(avg.toStringAsFixed(1),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0x990F172A))),
                    Text('avg', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Bowlers Tab ──────────────────────────────────────────────────────────────
class _BowlerTab extends StatelessWidget {
  final List<Player> players;
  const _BowlerTab({required this.players});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        final avg = p.wicketsTaken > 0 ? p.runsConceded / p.wicketsTaken : 0.0;
        final eco = p.oversBowled > 0 ? p.runsConceded / p.oversBowled : 0.0;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassCard,
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < 3 ? AppTheme.accentGold.withOpacity(0.2) : Colors.black.withOpacity(0.06),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: i < 3 ? AppTheme.accentGold : Colors.black38)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('${p.role} • ${p.nationality}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${p.wicketsTaken}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.accentRed)),
                    Text('wkts', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(eco.toStringAsFixed(2),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0x990F172A))),
                    Text('eco', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
