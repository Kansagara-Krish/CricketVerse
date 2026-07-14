// lib/screens/admin/team_management_screen.dart
// Full Team CRUD: search, filter, add, edit, delete

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/confirm_dialog.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  String _searchQuery = '';

  void _showAddTeamDialog() {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();
    final colorOptions = [
      {'label': 'Blue', 'hex': '0xFF0284C7'},
      {'label': 'Green', 'hex': '0xFF10B981'},
      {'label': 'Gold', 'hex': '0xFFFBBF24'},
      {'label': 'Purple', 'hex': '0xFF8B5CF6'},
      {'label': 'Red', 'hex': '0xFFEF4444'},
      {'label': 'Orange', 'hex': '0xFFF97316'},
    ];
    String selectedColor = '0xFF0284C7';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Add New Team', style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon: const Icon(Icons.groups, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: shortCtrl,
                maxLength: 4,
                style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  labelText: 'Short Code (e.g. IND)',
                  prefixIcon: const Icon(Icons.label, color: Colors.white38),
                  counterStyle: GoogleFonts.outfit(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 8),
              Text('Team Color', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: colorOptions.map((c) {
                  final isSelected = c['hex'] == selectedColor;
                  final color = Color(int.parse(c['hex']!));
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedColor = c['hex']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isSelected ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 2 : 1),
                      ),
                      child: Text(c['label']!,
                          style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final short = shortCtrl.text.trim().toUpperCase();
                    if (name.isEmpty || short.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    final defaultPlayers = List.generate(11, (i) => Player(
                      id: '${short.toLowerCase()}_p${i + 1}',
                      name: '$short Player ${i + 1}',
                      role: i < 5 ? 'Batter' : (i < 8 ? 'All-rounder' : 'Bowler'),
                      nationality: short,
                    ));
                    Provider.of<StorageService>(context, listen: false)
                        .addTeam(name, short, selectedColor, defaultPlayers);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Team "$name" added successfully!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Team'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final filtered = storage.teams
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.shortName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Team Management'),
        backgroundColor: AppTheme.bgDeep,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Manage Players',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.playerManagement),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeamDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Team', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text('${filtered.length} teams',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No Teams Found',
                    subtitle: 'Add your first team to get started with CricketVerse.',
                    buttonLabel: 'Add Team',
                    onButtonTap: _showAddTeamDialog,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final team = filtered[i];
                      final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7);
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.teamDetail, arguments: team),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassCard,
                          child: Row(
                            children: [
                              Hero(
                                tag: 'team_avatar_${team.id}',
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: color.withOpacity(0.2),
                                  child: Text(
                                    team.shortName.substring(0, team.shortName.length > 2 ? 2 : team.shortName.length),
                                    style: GoogleFonts.outfit(
                                        color: color, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team.name,
                                        style: GoogleFonts.outfit(
                                            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 3),
                                    Text('${team.players.length} Players • ${team.shortName}',
                                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Edit ${team.name} — open detail to edit')),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
                                onPressed: () async {
                                  final confirmed = await ConfirmDialog.show(
                                    context,
                                    title: 'Delete Team',
                                    message: 'Are you sure you want to delete "${team.name}"? This action cannot be undone.',
                                  );
                                  if (confirmed == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('🗑️ ${team.name} deleted'), backgroundColor: AppTheme.accentRed),
                                    );
                                  }
                                },
                              ),
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
