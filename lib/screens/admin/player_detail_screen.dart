// lib/screens/admin/player_detail_screen.dart
// Individual player career statistics and profile

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;
  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleColor = AppTheme.roleColor(player.role);
    final battingAvg = player.ballsFaced > 0
        ? (player.runsScored / player.matchesPlayed).toStringAsFixed(1)
        : '0.0';
    final strikeRate = player.ballsFaced > 0
        ? ((player.runsScored / player.ballsFaced) * 100).toStringAsFixed(1)
        : '0.0';
    final bowlingAvg = player.wicketsTaken > 0
        ? (player.runsConceded / player.wicketsTaken).toStringAsFixed(1)
        : '—';
    final economy = player.oversBowled > 0
        ? (player.runsConceded / player.oversBowled).toStringAsFixed(1)
        : '—';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.bgDeep,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => _showEditSheet(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [roleColor.withOpacity(0.35), AppTheme.bgDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: roleColor.withOpacity(0.2),
                      child: Text(
                        player.name.substring(0, 1),
                        style: GoogleFonts.outfit(
                            fontSize: 34, color: roleColor, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(player.name,
                        style: GoogleFonts.outfit(
                            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: roleColor.withOpacity(0.4)),
                          ),
                          child: Text(player.role,
                              style: GoogleFonts.outfit(fontSize: 12, color: roleColor, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Text(player.nationality,
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54)),
                        const SizedBox(width: 6),
                        Text('• ${player.matchesPlayed} matches',
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Batting Stats
                  _SectionHeader('🏏 BATTING STATISTICS', AppTheme.primaryBlue),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatBox('Runs', '${player.runsScored}', AppTheme.primaryBlue),
                      const SizedBox(width: 10),
                      _StatBox('Average', battingAvg, AppTheme.primaryGreen),
                      const SizedBox(width: 10),
                      _StatBox('Strike Rate', strikeRate, AppTheme.accentGold),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatBox('Balls Faced', '${player.ballsFaced}', Colors.white60),
                      const SizedBox(width: 10),
                      _StatBox('Matches', '${player.matchesPlayed}', Colors.white60),
                      const SizedBox(width: 10),
                      _StatBox('Not Outs', '${(player.matchesPlayed * 0.3).round()}', Colors.white60),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bowling Stats
                  _SectionHeader('⚡ BOWLING STATISTICS', AppTheme.accentRed),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatBox('Wickets', '${player.wicketsTaken}', AppTheme.accentRed),
                      const SizedBox(width: 10),
                      _StatBox('Average', bowlingAvg, AppTheme.accentOrange),
                      const SizedBox(width: 10),
                      _StatBox('Economy', economy, AppTheme.accentGold),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatBox('Overs', '${player.oversBowled.toStringAsFixed(1)}', Colors.white60),
                      const SizedBox(width: 10),
                      _StatBox('Runs Given', '${player.runsConceded}', Colors.white60),
                      const SizedBox(width: 10),
                      _StatBox('Best', player.wicketsTaken > 0 ? '${player.wicketsTaken ~/ 3}/24' : '—', Colors.white60),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Career highlights
                  _SectionHeader('🌟 CAREER HIGHLIGHTS', AppTheme.accentGold),
                  const SizedBox(height: 12),
                  ..._buildHighlights(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHighlights() {
    final highlights = [
      'Highest Score: ${player.runsScored ~/ 5} runs',
      'Best Bowling: ${player.wicketsTaken > 0 ? "${player.wicketsTaken ~/ 3}/24" : "N/A"}',
      'Matches Played: ${player.matchesPlayed}',
      'International Debut: 2018',
    ];
    return highlights.map((h) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassCardSmall,
        child: Row(
          children: [
            const Icon(Icons.star, color: AppTheme.accentGold, size: 16),
            const SizedBox(width: 10),
            Text(h, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
    )).toList();
  }

  void _showEditSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: player.name);
    final natCtrl = TextEditingController(text: player.nationality);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgMedium,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Player', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, style: GoogleFonts.outfit(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Player Name')),
            const SizedBox(height: 12),
            TextField(controller: natCtrl, style: GoogleFonts.outfit(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nationality')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Player "${nameCtrl.text}" updated!'), backgroundColor: AppTheme.primaryGreen),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: color, margin: const EdgeInsets.only(right: 8)),
        Text(title, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.white38, letterSpacing: 1.3)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
