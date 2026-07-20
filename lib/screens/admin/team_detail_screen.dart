// lib/screens/admin/team_detail_screen.dart
// Team roster view with player list, stats, and edit

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class TeamDetailScreen extends StatelessWidget {
  final Team team;
  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7);
    final batters = team.players.where((p) => p.role == 'Batter').toList();
    final allRounders = team.players.where((p) => p.role == 'All-rounder').toList();
    final bowlers = team.players.where((p) => p.role == 'Bowler').toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.4), AppTheme.bgDeep],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Hero(
                      tag: 'team_avatar_${team.id}',
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: color.withValues(alpha: 0.3),
                        child: Text(
                          team.shortName.substring(0, team.shortName.length > 2 ? 2 : team.shortName.length),
                          style: GoogleFonts.plusJakartaSans(
                              color: color, fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(team.name,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('${team.players.length} Players in Squad',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.textPrimary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit team details')),
                ),
              ),
            ],
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatChip('Batters', '${batters.length}', AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  _StatChip('All-rounders', '${allRounders.length}', AppTheme.accentGold),
                  const SizedBox(width: 10),
                  _StatChip('Bowlers', '${bowlers.length}', AppTheme.accentRed),
                ],
              ),
            ),
          ),

          // Player Sections
          _playerSection(context, 'BATTERS', batters, AppTheme.primaryBlue),
          _playerSection(context, 'ALL-ROUNDERS', allRounders, AppTheme.accentGold),
          _playerSection(context, 'BOWLERS', bowlers, AppTheme.accentRed),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _playerSection(
      BuildContext context, String title, List<Player> players, Color color) {
    if (players.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 3, height: 16, color: color,
                      margin: const EdgeInsets.only(right: 8)),
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted, letterSpacing: 1.5)),
                ],
              ),
            ),
            ...players.map((p) => GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.glassCardSmall,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(p.name.substring(0, 1),
                          style: GoogleFonts.plusJakartaSans(color: color, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          Text(p.nationality,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.runsScored} runs',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                        Text('${p.wicketsTaken} wkts',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
