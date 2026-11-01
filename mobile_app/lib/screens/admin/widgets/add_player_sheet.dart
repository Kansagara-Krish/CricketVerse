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
  final Set<String> _selectedRoles = {'Batsman'};
  late String _selectedTeamId;
  String _selectedLeadership = 'None'; // 'None', 'Captain', 'Vice-Captain'

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.storage.teams.isNotEmpty ? widget.storage.teams[0].id : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _formatRoleFromSelection(Set<String> roles) {
    final hasBat = roles.contains('Batsman') || roles.contains('Batter');
    final hasBowl = roles.contains('Bowler');
    final hasAll = roles.contains('All-rounder');
    final hasWk = roles.contains('Wicket Keeper') || roles.contains('Wicketkeeper');

    final isAll = hasAll || (hasBat && hasBowl);

    if (isAll && hasWk) return 'All-rounder & Wicketkeeper';
    if (isAll) return 'All-rounder';
    if (hasBat && hasWk) return 'Batsman & Wicketkeeper';
    if (hasBowl && hasWk) return 'Bowler & Wicketkeeper';
    if (hasBat) return 'Batsman';
    if (hasBowl) return 'Bowler';
    if (hasWk) return 'Wicketkeeper';
    return 'Batsman';
  }

  void _toggleRole(String role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        if (_selectedRoles.length > 1) {
          _selectedRoles.remove(role);
        }
      } else {
        if (role == 'All-rounder') {
          _selectedRoles.remove('Batsman');
          _selectedRoles.remove('Bowler');
          _selectedRoles.add('All-rounder');
        } else if (role == 'Batsman' || role == 'Bowler') {
          _selectedRoles.remove('All-rounder');
          _selectedRoles.add(role);
        } else {
          _selectedRoles.add(role);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Team? selectedTeam;
    try {
      selectedTeam = widget.storage.teams.firstWhere((t) => t.id == _selectedTeamId);
    } catch (_) {
      selectedTeam = widget.storage.teams.isNotEmpty ? widget.storage.teams[0] : null;
    }

    final hasCaptain = selectedTeam?.players.any((p) => p.isCaptain) ?? false;
    final hasViceCaptain = selectedTeam?.players.any((p) => p.isViceCaptain) ?? false;

    // Reset selection if option becomes unavailable
    if (_selectedLeadership == 'Captain' && hasCaptain) {
      _selectedLeadership = 'None';
    } else if (_selectedLeadership == 'Vice-Captain' && hasViceCaptain) {
      _selectedLeadership = 'None';
    }

    final activeRole = _formatRoleFromSelection(_selectedRoles);

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
          // Player Role Checkbox Selection with Dynamic Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.sports_cricket_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Player Role',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.roleColor(activeRole).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activeRole.contains('Wicket')
                                ? Icons.sports_handball_rounded
                                : activeRole.contains('Bowler')
                                    ? Icons.sports_baseball_rounded
                                    : activeRole.contains('All')
                                        ? Icons.swap_horiz_rounded
                                        : Icons.sports_cricket_rounded,
                            size: 11,
                            color: AppTheme.roleColor(activeRole),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activeRole,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.roleColor(activeRole),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  _buildRoleCheckboxTile('Batsman', Icons.sports_cricket_rounded, const Color(0xFF0284C7)),
                  _buildRoleCheckboxTile('Bowler', Icons.sports_baseball_rounded, const Color(0xFFE11D48)),
                  _buildRoleCheckboxTile('All-rounder', Icons.swap_horiz_rounded, const Color(0xFFD97706)),
                  _buildRoleCheckboxTile('Wicket Keeper', Icons.sports_handball_rounded, const Color(0xFF7C3AED)),
                ],
              ),
            ],
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
            onChanged: (v) => setState(() {
              _selectedTeamId = v ?? _selectedTeamId;
            }),
          ),
          const SizedBox(height: 14),

          // Dynamic Leadership Role Selection (Captain / Vice-Captain)
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            initialValue: _selectedLeadership,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Team Role / Designation',
              prefixIcon: const Icon(Icons.workspace_premium_rounded, color: AppTheme.accentGold),
              helperText: hasCaptain && hasViceCaptain
                  ? 'Team already has both Captain & Vice-Captain assigned.'
                  : hasCaptain
                      ? 'Team already has a Captain assigned.'
                      : hasViceCaptain
                          ? 'Team already has a Vice-Captain assigned.'
                          : null,
              helperStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textMuted),
            ),
            items: [
              const DropdownMenuItem(value: 'None', child: Text('Player (No Leadership)')),
              if (!hasCaptain)
                const DropdownMenuItem(value: 'Captain', child: Text('⭐ Captain (C)')),
              if (!hasViceCaptain)
                const DropdownMenuItem(value: 'Vice-Captain', child: Text('🎗️ Vice-Captain (VC)')),
            ],
            onChanged: (v) => setState(() => _selectedLeadership = v ?? 'None'),
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
                if (_selectedTeamId.isEmpty) {
                  CustomNotification.show(context, 'Please assign a team!', type: NotificationType.warning);
                  return;
                }

                final isCap = _selectedLeadership == 'Captain';
                final isVC = _selectedLeadership == 'Vice-Captain';

                final newPlayer = Player(
                  id: 'player_${DateTime.now().millisecondsSinceEpoch}',
                  name: _nameCtrl.text.trim(),
                  role: _formatRoleFromSelection(_selectedRoles),
                  nationality: 'IND',
                  isCaptain: isCap,
                  isViceCaptain: isVC,
                );

                widget.storage.addPlayer(_selectedTeamId, newPlayer);
                Navigator.pop(context);

                final teamName = widget.storage.teams.firstWhere((t) => t.id == _selectedTeamId).name;
                String designationStr = isCap ? ' as Captain' : isVC ? ' as Vice-Captain' : '';
                CustomNotification.show(
                  context,
                  'Player "${newPlayer.name}" successfully added to $teamName$designationStr!',
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

  Widget _buildRoleCheckboxTile(String role, IconData icon, Color color) {
    final isSelected = _selectedRoles.contains(role);

    return InkWell(
      onTap: () => _toggleRole(role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                activeColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(
                  color: isSelected ? color : const Color(0xFF94A3B8),
                  width: 1.5,
                ),
                onChanged: (val) {
                  _toggleRole(role);
                },
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: isSelected ? color : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
