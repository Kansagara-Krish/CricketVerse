// lib/screens/admin/schedule_match_screen.dart
// Dedicated schedule match screen with Manager dropdown and Quick Add Manager modal

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../core/widgets/custom_date_time_pickers.dart';
import '../../models/models.dart';
import 'widgets/manager_management_dialog.dart';

class ScheduleMatchScreen extends StatefulWidget {
  final CricketMatch? matchToEdit;
  const ScheduleMatchScreen({super.key, this.matchToEdit});

  @override
  State<ScheduleMatchScreen> createState() => _ScheduleMatchScreenState();
}

class _ScheduleMatchScreenState extends State<ScheduleMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _teamAId, _teamBId;
  String _matchType = 'T20';
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _scorerUserCtrl = TextEditingController();
  final _scorerPassCtrl = TextEditingController();
  CricketMatch? _editingMatch;
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _editingMatch = widget.matchToEdit;
    if (_editingMatch != null) {
      _teamAId = _editingMatch!.teamA.id;
      _teamBId = _editingMatch!.teamB.id;
      _matchType = _editingMatch!.matchType;
      _dateCtrl.text = _editingMatch!.date;
      _timeCtrl.text = _editingMatch!.time;
      _scorerUserCtrl.text = _editingMatch!.scorerUsername;
      _scorerPassCtrl.text = _editingMatch!.scorerPassword;
    }

    // Proactively fetch managers list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = Provider.of<StorageService>(context, listen: false);
      storage.loadManagers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editingMatch == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CricketMatch) {
        _editingMatch = args;
        _teamAId = _editingMatch!.teamA.id;
        _teamBId = _editingMatch!.teamB.id;
        _matchType = _editingMatch!.matchType;
        _dateCtrl.text = _editingMatch!.date;
        _timeCtrl.text = _editingMatch!.time;
        _scorerUserCtrl.text = _editingMatch!.scorerUsername;
        _scorerPassCtrl.text = _editingMatch!.scorerPassword;
      }
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _scorerUserCtrl.dispose();
    _scorerPassCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime initial = DateTime.now();
    if (_dateCtrl.text.isNotEmpty) {
      try {
        final parts = _dateCtrl.text.split('-');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }

    final picked = await CustomDatePickerDialog.show(
      context,
      initialDate: initial,
      title: 'Select Match Date',
    );

    if (picked != null && mounted) {
      setState(() {
        _dateCtrl.text = '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  void _pickTime() async {
    TimeOfDay initial = const TimeOfDay(hour: 19, minute: 30);
    if (_timeCtrl.text.isNotEmpty) {
      try {
        final parts = _timeCtrl.text.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minPart = parts[1].split(' ');
          final minute = int.parse(minPart[0]);
          initial = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (_) {}
    }

    final picked = await CustomTimePickerDialog.show(
      context,
      initialTime: initial,
      title: 'Select Match Time',
    );

    if (picked != null && mounted) {
      setState(() {
        _timeCtrl.text = picked.format(context);
      });
    }
  }

  void _showAddManagerDialog() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

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
          child: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create New Manager',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Add login credentials for official match scorer / manager',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),

                // Name
                TextFormField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Full Name (e.g. Arun Patel)',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.textMuted, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter manager name' : null,
                ),
                const SizedBox(height: 14),

                // Username
                TextFormField(
                  controller: usernameCtrl,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Username or Email (e.g. arun_scorer)',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.textMuted, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter username' : null,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: passwordCtrl,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter password' : null,
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!dialogFormKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);

                            final storage = Provider.of<StorageService>(context, listen: false);
                            final created = await storage.addManager(
                              name: nameCtrl.text.trim(),
                              username: usernameCtrl.text.trim(),
                              password: passwordCtrl.text.trim(),
                            );

                            if (ctx.mounted) {
                              setModalState(() => isSubmitting = false);
                            }

                            if (created != null) {
                              if (mounted) {
                                setState(() {
                                  _selectedManagerId = created.id;
                                  _scorerUserCtrl.text = created.username;
                                  _scorerPassCtrl.text = created.password;
                                });
                              }
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (mounted) {
                                CustomNotification.show(
                                  context,
                                  'Manager "${created.name}" created and assigned!',
                                  type: NotificationType.success,
                                );
                              }
                            } else {
                              if (mounted) {
                                CustomNotification.show(
                                  context,
                                  'Failed to create manager. Username might already exist.',
                                  type: NotificationType.error,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      isSubmitting ? 'Creating...' : 'Create & Assign Manager',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_teamAId == null || _teamBId == null) {
      CustomNotification.show(
        context,
        'Please select both teams',
        type: NotificationType.warning,
      );
      return;
    }
    if (_teamAId == _teamBId) {
      CustomNotification.show(
        context,
        'Team A and Team B must be different',
        type: NotificationType.warning,
      );
      return;
    }

    final storage = Provider.of<StorageService>(context, listen: false);

    if (_editingMatch != null) {
      storage.updateMatch(
        matchId: _editingMatch!.id,
        teamAId: _teamAId!,
        teamBId: _teamBId!,
        matchType: _matchType,
        venue: _editingMatch!.venue.isNotEmpty ? _editingMatch!.venue : 'Main Stadium',
        date: _dateCtrl.text,
        time: _timeCtrl.text,
        scorerUser: _scorerUserCtrl.text.trim(),
        scorerPass: _scorerPassCtrl.text.trim(),
      );

      CustomNotification.show(
        context,
        'Match details updated successfully!',
        type: NotificationType.success,
      );
    } else {
      storage.scheduleMatch(
        teamAId: _teamAId!,
        teamBId: _teamBId!,
        matchType: _matchType,
        venue: 'Main Stadium',
        date: _dateCtrl.text,
        time: _timeCtrl.text,
        scorerUser: _scorerUserCtrl.text.trim(),
        scorerPass: _scorerPassCtrl.text.trim(),
      );

      CustomNotification.show(
        context,
        'Match Scheduled Successfully! Scorer credentials assigned.',
        type: NotificationType.success,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.bgSurface),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.bgSurface),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accentRed),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
      hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
    );

    final isEdit = _editingMatch != null;

    // Check if current scorer username matches any known manager
    if (_selectedManagerId == null && _scorerUserCtrl.text.isNotEmpty) {
      final matching = storage.managers.where((m) => m.username == _scorerUserCtrl.text).toList();
      if (matching.isNotEmpty) {
        _selectedManagerId = matching.first.id;
      }
    }

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
          isEdit ? 'Edit Match Details' : 'Schedule Match',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              CardEntranceAnimation(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.bgSurface),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(isEdit ? Icons.edit_note_rounded : Icons.sports_cricket, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isEdit ? 'Edit Match' : 'New Match', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text(isEdit ? 'Update team, schedule & manager credentials' : 'Fill in the match details below', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const _Label('TEAMS'),
              const SizedBox(height: 10),
              // Team A
              Text('Team A (Home)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                initialValue: _teamAId,
                decoration: inputDecorationTheme.copyWith(hintText: 'Select Team A'),
                items: storage.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _teamAId = v),
              ),
              const SizedBox(height: 14),
              Text('Team B (Away)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                initialValue: _teamBId,
                decoration: inputDecorationTheme.copyWith(hintText: 'Select Team B'),
                items: storage.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _teamBId = v),
              ),

              const SizedBox(height: 20),
              const _Label('MATCH FORMAT'),
              const SizedBox(height: 10),
              Row(
                children: ['T20', 'ODI'].map((type) {
                  final selected = _matchType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _matchType = type),
                      child: Container(
                        margin: EdgeInsets.only(right: type == 'T20' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE0F2FE) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppTheme.primaryBlue : AppTheme.bgSurface,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const _Label('DATE & TIME'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                        decoration: inputDecorationTheme.copyWith(
                          hintText: 'DD-MM-YYYY',
                          prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppTheme.textMuted, size: 18),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: TextFormField(
                        controller: _timeCtrl,
                        readOnly: true,
                        onTap: _pickTime,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                        decoration: inputDecorationTheme.copyWith(
                          hintText: '--:--',
                          prefixIcon: const Icon(Icons.access_time, color: AppTheme.textMuted, size: 18),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Manager Assignment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'ASSIGNED MANAGER / SCORER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      InkWell(
                        onTap: () async {
                          final selected = await ManagerManagementDialog.show(
                            context,
                            onSelected: (mgr) {
                              setState(() {
                                _selectedManagerId = mgr.id;
                                _scorerUserCtrl.text = mgr.username;
                                _scorerPassCtrl.text = mgr.password;
                              });
                            },
                          );
                          if (selected != null && mounted) {
                            setState(() {
                              _selectedManagerId = selected.id;
                              _scorerUserCtrl.text = selected.username;
                              _scorerPassCtrl.text = selected.password;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.manage_accounts_outlined, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Manage',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _showAddManagerDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 15, color: AppTheme.primaryBlue),
                              const SizedBox(width: 3),
                              Text(
                                'Add New',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select an existing manager or enter scorer login credentials for this match.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),

              // Manager Dropdown
              DropdownButtonFormField<String>(
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                initialValue: _selectedManagerId,
                isExpanded: true,
                decoration: inputDecorationTheme.copyWith(
                  hintText: storage.managers.isEmpty
                      ? 'No managers found (Tap Add New)'
                      : 'Choose an existing Manager',
                  prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.primaryBlue, size: 20),
                ),
                items: storage.managers.map((m) {
                  return DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      '${m.name} (${m.username})',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedManagerId = val;
                    if (val != null) {
                      final selected = storage.managers.firstWhere(
                        (m) => m.id == val,
                        orElse: () => Manager(id: '', name: '', username: '', password: ''),
                      );
                      if (selected.id.isNotEmpty) {
                        _scorerUserCtrl.text = selected.username;
                        _scorerPassCtrl.text = selected.password;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // Auto-filled / Manual Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _scorerUserCtrl,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: inputDecorationTheme.copyWith(
                        labelText: 'Manager Username',
                        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 18),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _scorerPassCtrl,
                      obscureText: true,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: inputDecorationTheme.copyWith(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 18),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEdit ? Icons.save_rounded : Icons.check_circle_rounded),
                  label: Text(isEdit ? 'Update Match Details' : 'Schedule Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 1.3,
      ),
    );
  }
}
