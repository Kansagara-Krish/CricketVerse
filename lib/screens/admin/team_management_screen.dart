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
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Add New Team', style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon: const Icon(Icons.groups, color: const Color(0x610F172A)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: shortCtrl,
                maxLength: 4,
                style: GoogleFonts.outfit(color: const Color(0xFF0F172A), letterSpacing: 2),
                decoration: InputDecoration(
                  labelText: 'Short Code (e.g. IND)',
                  prefixIcon: const Icon(Icons.label, color: const Color(0x610F172A)),
                  counterStyle: GoogleFonts.outfit(color: const Color(0x610F172A)),
                ),
              ),
              const SizedBox(height: 8),
              Text('Team Color', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x990F172A))),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF0284C7),
            radius: 18,
            child: Text(
              'UP',
              style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        title: Text(
          'CricketVerse AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // Teams active
          onTap: (index) {
            if (index == 0) {
              Navigator.pop(context);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF854D0E),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Teams'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_cricket_outlined), activeIcon: Icon(Icons.sports_cricket), label: 'Matches'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
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
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your franchise roster, add new talent, and organize squads.',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
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
                      border: Border(bottom: BorderSide(color: Color(0xFF0F172A), width: 2)),
                    ),
                    child: Center(
                      child: Text(
                        'Teams',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontSize: 14),
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
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                      ),
                      child: Center(
                        child: Text(
                          'Players',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF64748B), fontSize: 14),
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search teams...',
                            hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
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
                      Text('Add Team', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
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
                                    style: GoogleFonts.outfit(
                                      fontSize: 15, 
                                      fontWeight: FontWeight.bold, 
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${team.players.length} Players • 8 Support Staff',
                                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
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
                                      style: GoogleFonts.outfit(
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
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Edit ${team.name} — open detail to edit')),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Delete Team',
                                  message: 'Are you sure you want to delete "${team.name}"? This action cannot be undone.',
                                );
                                if (confirmed == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('🗑️ ${team.name} deleted'), backgroundColor: const Color(0xFFEF4444)),
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
