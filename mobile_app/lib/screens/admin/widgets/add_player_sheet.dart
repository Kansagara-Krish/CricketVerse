import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_notification.dart';
import '../../../models/models.dart';
import '../../../services/storage_service.dart';

class AddPlayerSheet extends StatefulWidget {
  final StorageService storage;

  const AddPlayerSheet({super.key, required this.storage});

  static Future<void> show(BuildContext context, StorageService storage) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddPlayerSheet(storage: storage),
    );
  }

  @override
  State<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<AddPlayerSheet> {
  final _nameCtrl = TextEditingController();
  final _natCtrl = TextEditingController();
  String _selectedRole = 'Batter';
  late String _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.storage.teams.isNotEmpty ? widget.storage.teams[0].id : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _natCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Player Name',
              prefixIcon: Icon(Icons.person, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _natCtrl,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Nationality (e.g. IND)',
              prefixIcon: Icon(Icons.flag, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            initialValue: _selectedRole,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: const InputDecoration(
              labelText: 'Player Role',
              prefixIcon: Icon(Icons.sports_cricket_rounded, color: AppTheme.textMuted),
            ),
            items: const [
              DropdownMenuItem(value: 'Batter', child: Text('Batter')),
              DropdownMenuItem(value: 'Bowler', child: Text('Bowler')),
              DropdownMenuItem(value: 'All-rounder', child: Text('All-rounder')),
            ],
            onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            initialValue: _selectedTeamId,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: const InputDecoration(
              labelText: 'Assign Team',
              prefixIcon: Icon(Icons.groups, color: AppTheme.textMuted),
            ),
            items: widget.storage.teams
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedTeamId = v ?? _selectedTeamId),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) {
                  CustomNotification.show(context, 'Please enter a name!', type: NotificationType.warning);
                  return;
                }
                if (_natCtrl.text.trim().isEmpty) {
                  CustomNotification.show(context, 'Please enter nationality!', type: NotificationType.warning);
                  return;
                }
                if (_selectedTeamId.isEmpty) {
                  CustomNotification.show(context, 'Please assign a team!', type: NotificationType.warning);
                  return;
                }

                final newPlayer = Player(
                  id: 'player_${DateTime.now().millisecondsSinceEpoch}',
                  name: _nameCtrl.text.trim(),
                  role: _selectedRole,
                  nationality: _natCtrl.text.trim(),
                );

                widget.storage.addPlayer(_selectedTeamId, newPlayer);
                Navigator.pop(context);

                final teamName = widget.storage.teams.firstWhere((t) => t.id == _selectedTeamId).name;
                CustomNotification.show(
                  context,
                  'Player "${newPlayer.name}" successfully added to $teamName!',
                  type: NotificationType.success,
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text('Add Player', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
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
    );
  }
}
