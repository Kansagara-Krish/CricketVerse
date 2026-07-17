// lib/screens/admin/create_tournament_screen.dart
// Tournament creation form

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_notification.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({Key? key}) : super(key: key);

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Create Tournament', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.tournamentList),
            child: Text('View All', style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
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
              // Icon banner (White text on purple gradient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Tournament', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Set up your cricket competition', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _Label('TOURNAMENT NAME'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. CricketVerse Premier League 2026',
                  prefixIcon: const Icon(Icons.emoji_events_outlined, color: AppTheme.textMuted, size: 20),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Tournament name is required' : null,
              ),

              const SizedBox(height: 20),
              _Label('MATCH FORMAT'),
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
                          color: selected ? AppTheme.accentPurple.withOpacity(0.08) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppTheme.accentPurple : Colors.black.withOpacity(0.08),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(type,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                  color: selected ? AppTheme.accentPurple : AppTheme.textSecondary)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              _Label('KNOCKOUT TYPE'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: AppTheme.bgMedium,
                value: _knockoutType,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  fillColor: Colors.black.withOpacity(0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: ['Single Elimination', 'Double Elimination', 'Round Robin', 'Group Stage + Knockouts']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _knockoutType = v ?? _knockoutType),
              ),

              const SizedBox(height: 20),
              _Label('TOURNAMENT DATES'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, initialDate: DateTime.now(),
                          firstDate: DateTime.now(), lastDate: DateTime(2027),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppTheme.accentPurple,
                                onPrimary: Colors.white,
                                onSurface: AppTheme.textPrimary,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) _startCtrl.text = '${picked.day}-${picked.month}-${picked.year}';
                      },
                      child: AbsOrbPointer(
                        child: TextFormField(
                          controller: _startCtrl,
                          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Start Date',
                            prefixIcon: const Icon(Icons.play_arrow_rounded, color: AppTheme.textMuted, size: 18),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(), lastDate: DateTime(2027),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppTheme.accentPurple,
                                onPrimary: Colors.white,
                                onSurface: AppTheme.textPrimary,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) _endCtrl.text = '${picked.day}-${picked.month}-${picked.year}';
                      },
                      child: AbsOrbPointer(
                        child: TextFormField(
                          controller: _endCtrl,
                          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'End Date',
                            prefixIcon: const Icon(Icons.stop_rounded, color: AppTheme.textMuted, size: 18),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _Label('PARTICIPATING TEAMS'),
              const SizedBox(height: 10),
              ...storage.teams.map((team) {
                final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7);
                final selected = _selectedTeams.contains(team.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) _selectedTeams.remove(team.id);
                    else _selectedTeams.add(team.id);
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color.withOpacity(0.4) : const Color(0xFFE2E8F0),
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withOpacity(0.12),
                          child: Text(team.shortName.substring(0, 2),
                              style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(team.name, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        ),
                        if (selected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    if (_selectedTeams.isEmpty) {
                      CustomNotification.show(
                        context,
                        'Please select at least one participating team!',
                        type: NotificationType.warning,
                      );
                      return;
                    }
                    CustomNotification.show(
                      context,
                      'Tournament "${_nameCtrl.text}" created successfully!',
                      type: NotificationType.success,
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.emoji_events_rounded, size: 18),
                  label: const Text('Create Tournament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
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

class AbsOrbPointer extends StatelessWidget {
  final Widget child;
  const AbsOrbPointer({Key? key, required this.child}) : super(key: key);

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
    return Text(text,
        style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1.2));
  }
}
