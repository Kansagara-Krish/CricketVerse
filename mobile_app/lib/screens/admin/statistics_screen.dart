// lib/screens/admin/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/stats_overview_tab.dart';
import 'widgets/stats_batter_tab.dart';
import 'widgets/stats_bowler_tab.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final allPlayers = storage.teams.expand((t) => t.players).toList();
    final topBatters = List<Player>.from(allPlayers)..sort((a, b) => b.runsScored.compareTo(a.runsScored));
    final topBowlers = List<Player>.from(allPlayers)..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Text(
          'Statistics',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
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
          StatsOverviewTab(storage: storage),
          StatsBatterTab(players: topBatters.take(10).toList()),
          StatsBowlerTab(players: topBowlers.take(10).toList()),
        ],
      ),
    );
  }
}
