// lib/screens/admin/create_tournament_screen.dart
// Tournament creation form with Custom Animated Date Picker matching reference design

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../core/widgets/custom_date_time_pickers.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  String _format = 'T20';
  String _knockoutType = 'Single Elimination';
  final List<String> _selectedTeams = [];
  bool _isEdit = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _isEdit = true;
          _nameCtrl.text = args['name'] ?? '';
          _startCtrl.text = args['start'] ?? '';
          _endCtrl.text = args['end'] ?? '';
          _format = args['format'] ?? 'T20';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller, {required bool isStart}) async {
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split('-');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }

    final pickedDate = await CustomDatePickerDialog.show(
      context,
      initialDate: initial,
      title: isStart ? 'Select Start Date' : 'Select End Date',
    );

    if (pickedDate != null) {
      final formatted = DateFormat('dd-MM-yyyy').format(pickedDate);
      setState(() {
        controller.text = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Tournament' : 'Create Tournament',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.tournamentList),
            child: Text(
              'View All',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
            ),
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
              // Icon banner
              CardEntranceAnimation(
                index: 0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Edit Tournament' : 'New Tournament',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Set up your cricket competition',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CardEntranceAnimation(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('TOURNAMENT NAME'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g. CricketVerse Premier League 2026',
                        prefixIcon: Icon(Icons.emoji_events_outlined, color: AppTheme.textMuted, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Tournament name is required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              CardEntranceAnimation(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('MATCH FORMAT'),
                    const SizedBox(height: 10),
                    Row(
                      children: ['T20', 'ODI', 'Test'].map((type) {
                        final selected = _format == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _format = type),
                            child: Container(
                              margin: EdgeInsets.only(right: type != 'Test' ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.accentPurple.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? AppTheme.accentPurple : Colors.black.withValues(alpha: 0.08),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  type,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                    color: selected ? AppTheme.accentPurple : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              CardEntranceAnimation(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('KNOCKOUT TYPE'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppTheme.bgMedium,
                      initialValue: _knockoutType,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        fillColor: Colors.black.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: ['Single Elimination', 'Double Elimination', 'Round Robin', 'Group Stage + Knockouts']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _knockoutType = v ?? _knockoutType),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TOURNAMENT DATES WITH CUSTOM ANIMATED DATE PICKER
              CardEntranceAnimation(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('TOURNAMENT DATES'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Start Date Field
                        Expanded(
                          child: TextFormField(
                            controller: _startCtrl,
                            readOnly: true,
                            onTap: () => _selectDate(_startCtrl, isStart: true),
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                            decoration: const InputDecoration(
                              hintText: 'Start Date',
                              prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.primaryBlue, size: 18),
                            ),
                            validator: (v) => _startCtrl.text.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // End Date Field
                        Expanded(
                          child: TextFormField(
                            controller: _endCtrl,
                            readOnly: true,
                            onTap: () => _selectDate(_endCtrl, isStart: false),
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                            decoration: const InputDecoration(
                              hintText: 'End Date',
                              prefixIcon: Icon(Icons.event_available_rounded, color: AppTheme.primaryBlue, size: 18),
                            ),
                            validator: (v) => _endCtrl.text.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              CardEntranceAnimation(
                index: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('PARTICIPATING TEAMS'),
                    const SizedBox(height: 10),
                    ...storage.teams.map((team) {
                      final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7);
                      final selected = _selectedTeams.contains(team.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedTeams.remove(team.id);
                          } else {
                            _selectedTeams.add(team.id);
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withValues(alpha: 0.12),
                                child: Text(
                                  team.shortName.length >= 2 ? team.shortName.substring(0, 2) : team.shortName,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (selected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              CardEntranceAnimation(
                index: 6,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_startCtrl.text.isEmpty || _endCtrl.text.isEmpty) {
                              CustomNotification.show(
                                context,
                                'Please select both Start Date and End Date!',
                                type: NotificationType.warning,
                              );
                              return;
                            }
                            if (!_formKey.currentState!.validate()) return;
                            if (_selectedTeams.isEmpty) {
                              CustomNotification.show(
                                context,
                                'Please select at least one participating team!',
                                type: NotificationType.warning,
                              );
                              return;
                            }

                            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                            setState(() => _isSubmitting = true);
                            try {
                              if (_isEdit) {
                                final tournId = args?['id']?.toString() ?? 'tourn_${DateTime.now().millisecondsSinceEpoch}';
                                final updated = Tournament(
                                  id: tournId,
                                  name: _nameCtrl.text.trim(),
                                  format: _format,
                                  status: args?['status']?.toString() ?? 'Upcoming',
                                  teamsCount: _selectedTeams.length,
                                  matchesCount: int.tryParse(args?['matches']?.toString() ?? '0') ?? 0,
                                  startDate: _startCtrl.text.trim(),
                                  endDate: _endCtrl.text.trim(),
                                  participatingTeamIds: List.from(_selectedTeams),
                                );
                                await storage.updateTournament(updated);
                              } else {
                                final newTourn = Tournament(
                                  id: 'tourn_${DateTime.now().millisecondsSinceEpoch}',
                                  name: _nameCtrl.text.trim(),
                                  format: _format,
                                  status: 'Upcoming',
                                  teamsCount: _selectedTeams.length,
                                  matchesCount: 0,
                                  startDate: _startCtrl.text.trim(),
                                  endDate: _endCtrl.text.trim(),
                                  participatingTeamIds: List.from(_selectedTeams),
                                );
                                await storage.addTournament(newTourn);
                              }

                              if (mounted) {
                                CustomNotification.show(
                                  context,
                                  _isEdit
                                      ? 'Tournament "${_nameCtrl.text}" updated successfully!'
                                      : 'Tournament "${_nameCtrl.text}" created successfully!',
                                  type: NotificationType.success,
                                );
                                Navigator.pop(context);
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.emoji_events_rounded, size: 18),
                    label: Text(_isSubmitting
                        ? (_isEdit ? 'Saving...' : 'Creating...')
                        : (_isEdit ? 'Save Changes' : 'Create Tournament')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
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

// Wrapper to pass taps through disabled input fields
class PointerInterceptor extends StatelessWidget {
  final Widget child;
  const PointerInterceptor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: child);
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
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}
