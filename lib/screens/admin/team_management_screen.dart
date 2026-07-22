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
import '../../core/widgets/custom_notification.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  String _searchQuery = '';

  void _showAddTeamDialog() {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();
    final colorOptions = [
      {'label': 'Emerald', 'hex': '0xFF028A6B'},
      {'label': 'Green', 'hex': '0xFF10B981'},
      {'label': 'Gold', 'hex': '0xFFFBBF24'},
      {'label': 'Amber', 'hex': '0xFFD97706'},
      {'label': 'Red', 'hex': '0xFFEF4444'},
      {'label': 'Orange', 'hex': '0xFFF97316'},
    ];
    String selectedColor = '0xFF028A6B';

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
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Add New Team', style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon: Icon(Icons.groups, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: shortCtrl,
                maxLength: 4,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, letterSpacing: 2),
                decoration: InputDecoration(
                  labelText: 'Short Code (e.g. IND)',
                  prefixIcon: const Icon(Icons.label, color: AppTheme.textMuted),
                  counterStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              Text('Team Color', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0x990F172A))),
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
                        color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected ? color : color.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                      ),
                      child: Text(c['label']!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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
                      CustomNotification.show(
                        context,
                        'Please fill all fields',
                        type: NotificationType.warning,
                      );
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
                    CustomNotification.show(
                      context,
                      'Team "$name" added successfully!',
                      type: NotificationType.success,
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
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team Management',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title and subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team & Player Management',
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your franchise roster, add new talent, and organize squads.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Tabs row (Teams / Players)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.textPrimary, width: 2)),
                    ),
                    child: Center(
                      child: Text(
                        'Teams',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.playerManagement),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.bgSurface, width: 1)),
                      ),
                      child: Center(
                        child: Text(
                          'Players',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Box & Add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.bgSurface),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search teams...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                            border: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _showAddTeamDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF094CB2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16),
                      const SizedBox(width: 6),
                      Text('Add Team', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final team = filtered[i];
                      final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF028A6B);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.bgSurface),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.shield_outlined, color: color, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15, 
                                      fontWeight: FontWeight.bold, 
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${team.players.length} Players • 8 Support Staff',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF16A34A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.editTeam, arguments: team),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Delete Team',
                                  message: 'Are you sure you want to delete "${team.name}"? This action cannot be undone.',
                                );
                                if (confirmed == true && context.mounted) {
                                  storage.deleteTeam(team.id);
                                  CustomNotification.show(
                                    context,
                                    'Team "${team.name}" deleted',
                                    type: NotificationType.error,
                                  );
                                }
                              },
                            ),

                          ],
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
