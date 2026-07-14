// lib/screens/admin/player_management_screen.dart
// All players across all teams with search and role filter

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/empty_state.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({Key? key}) : super(key: key);

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  String _search = '';
  String _roleFilter = 'All';

  final _roles = ['All', 'Batter', 'All-rounder', 'Bowler'];

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final allPlayers = storage.teams
        .expand((t) => t.players.map((p) => _PlayerWithTeam(p, t.shortName, t.logoColorHex)))
        .where((pw) {
      final matchesSearch = pw.player.name.toLowerCase().contains(_search.toLowerCase()) ||
          pw.player.nationality.toLowerCase().contains(_search.toLowerCase());
      final matchesRole = _roleFilter == 'All' || pw.player.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Player Management'),
        backgroundColor: AppTheme.bgDeep,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.teamManagement),
            tooltip: 'Manage Teams',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search players by name or nationality...',
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () => setState(() => _search = ''))
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // Role Filter Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _roles.map((r) {
                final selected = _roleFilter == r;
                final col = r == 'Batter'
                    ? AppTheme.primaryBlue
                    : r == 'Bowler'
                        ? AppTheme.accentRed
                        : r == 'All-rounder'
                            ? AppTheme.accentGold
                            : Colors.white60;
                return GestureDetector(
                  onTap: () => setState(() => _roleFilter = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? col.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? col : Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(r,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: selected ? col : Colors.white54,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text('${allPlayers.length} players',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          Expanded(
            child: allPlayers.isEmpty
                ? const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'No Players Found',
                    subtitle: 'Try adjusting the search or role filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: allPlayers.length,
                    itemBuilder: (_, i) {
                      final pw = allPlayers[i];
                      final roleColor = AppTheme.roleColor(pw.player.role);
                      final teamColor =
                          Color(int.tryParse(pw.teamColorHex) ?? 0xFF0284C7);
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.playerDetail,
                            arguments: pw.player),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.glassCard,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: teamColor.withOpacity(0.15),
                                child: Text(
                                  pw.player.name.substring(0, 1),
                                  style: GoogleFonts.outfit(
                                      color: teamColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pw.player.name,
                                        style: GoogleFonts.outfit(
                                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(pw.player.role,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 10, color: roleColor, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(pw.teamShort,
                                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
                                        const SizedBox(width: 4),
                                        Text('• ${pw.player.nationality}',
                                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${pw.player.runsScored}',
                                      style: GoogleFonts.outfit(
                                          fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                                  Text('runs',
                                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlayerWithTeam {
  final Player player;
  final String teamShort;
  final String teamColorHex;
  const _PlayerWithTeam(this.player, this.teamShort, this.teamColorHex);
}
