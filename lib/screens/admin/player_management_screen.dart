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
import '../../core/widgets/custom_notification.dart';

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
        backgroundColor: AppTheme.bgDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showAddPlayerDialog(context, storage),
            tooltip: 'Add Player',
          ),
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
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search players by name or nationality...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textMuted),
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
                      color: selected ? col.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? col : Colors.black.withOpacity(0.1)),
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
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
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
                                            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
                                            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                        const SizedBox(width: 4),
                                        Text('• ${pw.player.nationality}',
                                            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
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
                                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
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

  void _showAddPlayerDialog(BuildContext context, StorageService storage) {
    final nameCtrl = TextEditingController();
    final natCtrl = TextEditingController();
    String selectedRole = 'Batter';
    String selectedTeamId = storage.teams.isNotEmpty ? storage.teams[0].id : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add New Player',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  prefixIcon: Icon(Icons.person, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: natCtrl,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nationality (e.g. IND)',
                  prefixIcon: Icon(Icons.flag, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: selectedRole,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Player Role',
                  prefixIcon: Icon(Icons.sports_cricket_rounded, color: AppTheme.textMuted),
                ),
                items: ['Batter', 'Bowler', 'All-rounder']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedRole = v ?? selectedRole),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: selectedTeamId,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Assign Team',
                  prefixIcon: Icon(Icons.groups, color: AppTheme.textMuted),
                ),
                items: storage.teams
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedTeamId = v ?? selectedTeamId),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      CustomNotification.show(context, 'Please enter a name!', type: NotificationType.warning);
                      return;
                    }
                    if (natCtrl.text.trim().isEmpty) {
                      CustomNotification.show(context, 'Please enter nationality!', type: NotificationType.warning);
                      return;
                    }
                    if (selectedTeamId.isEmpty) {
                      CustomNotification.show(context, 'Please assign a team!', type: NotificationType.warning);
                      return;
                    }

                    final newPlayer = Player(
                      id: 'player_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text.trim(),
                      role: selectedRole,
                      nationality: natCtrl.text.trim(),
                    );

                    storage.addPlayer(selectedTeamId, newPlayer);
                    Navigator.pop(ctx);
                    
                    final teamName = storage.teams.firstWhere((t) => t.id == selectedTeamId).name;
                    CustomNotification.show(
                      context,
                      'Player "${newPlayer.name}" successfully added to $teamName!',
                      type: NotificationType.success,
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text('Add Player', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
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
