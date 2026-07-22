// lib/screens/admin/edit_team_screen.dart
// Admin screen to edit specific team details, manage roster (add, update, remove players), and delete team.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/card_entrance_animation.dart';

class EditTeamScreen extends StatefulWidget {
  final Team team;
  const EditTeamScreen({super.key, required this.team});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _shortCtrl;
  late String _selectedColorHex;

  final colorOptions = [
    {'label': 'Emerald', 'hex': '0xFF028A6B'},
    {'label': 'Green', 'hex': '0xFF10B981'},
    {'label': 'Blue', 'hex': '0xFF0284C7'},
    {'label': 'Indigo', 'hex': '0xFF4F46E5'},
    {'label': 'Gold', 'hex': '0xFFFBBF24'},
    {'label': 'Amber', 'hex': '0xFFD97706'},
    {'label': 'Red', 'hex': '0xFFEF4444'},
    {'label': 'Orange', 'hex': '0xFFF97316'},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team.name);
    _shortCtrl = TextEditingController(text: widget.team.shortName);
    _selectedColorHex = widget.team.logoColorHex;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    super.dispose();
  }

  void _saveTeamDetails(StorageService storage) {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final short = _shortCtrl.text.trim().toUpperCase();

    storage.updateTeam(widget.team.id, name, short, _selectedColorHex);

    CustomNotification.show(
      context,
      'Team "$name" updated successfully!',
      type: NotificationType.success,
    );
  }

  void _showAddOrEditPlayerModal({Player? player}) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final nameCtrl = TextEditingController(text: player?.name ?? '');
    final nationalityCtrl = TextEditingController(text: player?.nationality ?? widget.team.shortName);
    final runsCtrl = TextEditingController(text: player != null ? '${player.runsScored}' : '0');
    final wicketsCtrl = TextEditingController(text: player != null ? '${player.wicketsTaken}' : '0');
    String selectedRole = player?.role ?? 'Batter';

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
          child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                Text(
                  player == null ? 'Add Player to Squad' : 'Edit Player Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Name field
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Player Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 12),

                // Role Selector
                Text('Player Role', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['Batter', 'All-rounder', 'Bowler'].map((r) {
                    final selected = selectedRole == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedRole = r),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? AppTheme.primaryBlue : Colors.black.withValues(alpha: 0.08),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              r,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Nationality & Stats
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nationalityCtrl,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                        decoration: const InputDecoration(
                          labelText: 'Country / Code',
                          prefixIcon: Icon(Icons.flag_outlined, color: AppTheme.textMuted, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: runsCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                        decoration: const InputDecoration(
                          labelText: 'Runs Scored',
                          prefixIcon: Icon(Icons.sports_cricket, color: AppTheme.textMuted, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: wicketsCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                        decoration: const InputDecoration(
                          labelText: 'Wickets',
                          prefixIcon: Icon(Icons.sports_baseball_outlined, color: AppTheme.textMuted, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        CustomNotification.show(context, 'Please enter a player name', type: NotificationType.warning);
                        return;
                      }

                      final pId = player?.id ?? '${widget.team.shortName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
                      final updatedPlayer = Player(
                        id: pId,
                        name: name,
                        role: selectedRole,
                        nationality: nationalityCtrl.text.trim(),
                        runsScored: int.tryParse(runsCtrl.text) ?? 0,
                        wicketsTaken: int.tryParse(wicketsCtrl.text) ?? 0,
                        matchesPlayed: player?.matchesPlayed ?? 1,
                        ballsFaced: player?.ballsFaced ?? 0,
                      );

                      storage.updatePlayer(widget.team.id, updatedPlayer);
                      Navigator.pop(ctx);
                      setState(() {});

                      CustomNotification.show(
                        context,
                        player == null ? 'Player "$name" added to squad!' : 'Player "$name" updated!',
                        type: NotificationType.success,
                      );
                    },
                    icon: Icon(player == null ? Icons.add_rounded : Icons.check_rounded),
                    label: Text(player == null ? 'Add Player' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removePlayer(StorageService storage, Player player) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Remove Player',
      message: 'Are you sure you want to remove "${player.name}" from ${widget.team.name}?',
    );

    if (confirm == true && mounted) {
      storage.removePlayer(widget.team.id, player.id);
      setState(() {});
      CustomNotification.show(
        context,
        'Removed "${player.name}" from team squad',
        type: NotificationType.info,
      );
    }
  }

  void _deleteTeam(StorageService storage) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Team',
      message: 'Are you sure you want to permanently delete "${widget.team.name}"? This action cannot be undone.',
    );

    if (confirm == true && mounted) {
      storage.deleteTeam(widget.team.id);
      CustomNotification.show(
        context,
        'Team "${widget.team.name}" deleted',
        type: NotificationType.error,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final teamColor = Color(int.tryParse(_selectedColorHex) ?? 0xFF028A6B);
    final currentTeam = storage.teams.firstWhere(
      (t) => t.id == widget.team.id,
      orElse: () => widget.team,
    );

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
          'Edit ${currentTeam.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
            onPressed: () => _deleteTeam(storage),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Header Card
              CardEntranceAnimation(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: teamColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: teamColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: teamColor.withValues(alpha: 0.15),
                        child: Text(
                          _shortCtrl.text.isNotEmpty ? _shortCtrl.text.substring(0, _shortCtrl.text.length > 2 ? 2 : _shortCtrl.text.length) : 'TM',
                          style: GoogleFonts.plusJakartaSans(color: teamColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Team Name',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentTeam.players.length} Squad Players',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Team Info Form Section
              CardEntranceAnimation(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TEAM INFORMATION',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2)),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _nameCtrl,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                        onChanged: (v) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Team Full Name',
                          prefixIcon: Icon(Icons.groups_outlined, color: AppTheme.textMuted, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _shortCtrl,
                        maxLength: 6,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14, letterSpacing: 1.5),
                        onChanged: (v) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Short Code (e.g. UVP-A)',
                          prefixIcon: Icon(Icons.label_outlined, color: AppTheme.textMuted, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Short code required' : null,
                      ),
                      const SizedBox(height: 10),

                      Text('Team Theme Color', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colorOptions.map((c) {
                          final isSelected = c['hex'] == _selectedColorHex;
                          final col = Color(int.parse(c['hex']!));
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColorHex = c['hex']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: col.withValues(alpha: isSelected ? 0.25 : 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? col : col.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
                              ),
                              child: Text(
                                c['label']!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: col, fontWeight: FontWeight.w700),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _saveTeamDetails(storage),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Save Team Info'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Squad Roster Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SQUAD PLAYERS',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2)),
                  TextButton.icon(
                    onPressed: () => _showAddOrEditPlayerModal(),
                    icon: const Icon(Icons.person_add_rounded, size: 16, color: AppTheme.primaryBlue),
                    label: Text('Add Player', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...currentTeam.players.asMap().entries.map((entry) {
                final idx = entry.key;
                final player = entry.value;
                Color roleColor = AppTheme.primaryBlue;
                if (player.role == 'All-rounder') roleColor = AppTheme.accentGold;
                if (player.role == 'Bowler') roleColor = AppTheme.accentRed;

                return CardEntranceAnimation(
                  index: idx + 2,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: roleColor.withValues(alpha: 0.12),
                          child: Text(
                            player.name.substring(0, 1),
                            style: GoogleFonts.plusJakartaSans(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      player.role,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: roleColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${player.runsScored} runs • ${player.wicketsTaken} wkts',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 18),
                          onPressed: () => _showAddOrEditPlayerModal(player: player),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.accentRed, size: 18),
                          onPressed: () => _removePlayer(storage, player),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              // Danger Zone: Delete Team
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteTeam(storage),
                  icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.accentRed, size: 18),
                  label: Text('Delete Team', style: GoogleFonts.plusJakartaSans(color: AppTheme.accentRed, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
