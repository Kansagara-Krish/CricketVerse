// lib/screens/admin/tournament_management_screen.dart
// Tournament list with dummy data

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class TournamentManagementScreen extends StatelessWidget {
  const TournamentManagementScreen({Key? key}) : super(key: key);

  static const _tournaments = [
    {'name': 'T20 World Cup 2026', 'format': 'T20', 'teams': '16', 'status': 'Live', 'start': '01-07-2026', 'end': '30-07-2026', 'matches': '45'},
    {'name': 'IPL Season 19', 'format': 'T20', 'teams': '10', 'status': 'Upcoming', 'start': '01-09-2026', 'end': '30-11-2026', 'matches': '74'},
    {'name': 'CricketVerse Premier League', 'format': 'T20', 'teams': '8', 'status': 'Upcoming', 'start': '15-08-2026', 'end': '14-09-2026', 'matches': '28'},
    {'name': 'India-Australia Bilateral ODI', 'format': 'ODI', 'teams': '2', 'status': 'Completed', 'start': '01-06-2026', 'end': '20-06-2026', 'matches': '5'},
    {'name': 'Asia Cup 2026', 'format': 'ODI', 'teams': '6', 'status': 'Upcoming', 'start': '01-10-2026', 'end': '20-10-2026', 'matches': '13'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text('Tournament List', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createTournament),
            tooltip: 'Create Tournament',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createTournament),
        backgroundColor: AppTheme.accentPurple,
        icon: const Icon(Icons.add, color: const Color(0xFF0F172A)),
        label: Text('New Tournament', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _tournaments.length,
        itemBuilder: (_, i) {
          final t = _tournaments[i];
          final statusColor = AppTheme.statusColor(t['status']!);
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: AppTheme.glassCard,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentPurple),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['name']!,
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(t['status']!,
                                      style: GoogleFonts.outfit(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                                Text(t['format']!,
                                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      _TournStat(Icons.groups_rounded, '${t['teams']} Teams'),
                      _TournStat(Icons.sports_cricket_rounded, '${t['matches']} Matches'),
                      _TournStat(Icons.calendar_today_rounded, t['start']!),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Viewing ${t['name']}')),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: const Color(0x3D0F172A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Editing ${t['name']}')),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPurple.withOpacity(0.2),
                            foregroundColor: AppTheme.accentPurple,
                            side: BorderSide(color: AppTheme.accentPurple.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TournStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TournStat(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0x610F172A)),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
