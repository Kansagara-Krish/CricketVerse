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
import 'widgets/player_list_item.dart';
import 'widgets/add_player_sheet.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

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
        title: Text('Player Management', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.textPrimary),
            onPressed: () => AddPlayerSheet.show(context, storage),
            tooltip: 'Add Player',
          ),
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.teamManagement),
            tooltip: 'Manage Teams',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search players by name or nationality...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),

          // Role Filter Chips (High-Contrast Redesign)
          SizedBox(
            height: 38,
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
                            : AppTheme.textPrimary;

                return GestureDetector(
                  onTap: () => setState(() => _roleFilter = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? col : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? col : AppTheme.bgSurface,
                      ),
                      boxShadow: [
                        if (!selected)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        r,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: selected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${allPlayers.length} players found',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Players List View
          Expanded(
            child: allPlayers.isEmpty
                ? const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'No Players Found',
                    subtitle: 'Try adjusting the search or role filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: allPlayers.length,
                    itemBuilder: (context, i) {
                      final pw = allPlayers[i];
                      return PlayerListItem(
                        player: pw.player,
                        teamShort: pw.teamShort,
                        teamColorHex: pw.teamColorHex,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.playerDetail,
                          arguments: pw.player,
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
