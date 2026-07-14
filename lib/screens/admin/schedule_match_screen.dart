// lib/screens/admin/schedule_match_screen.dart
// Dedicated schedule match screen (extracted from old dashboard)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';

class ScheduleMatchScreen extends StatefulWidget {
  const ScheduleMatchScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleMatchScreen> createState() => _ScheduleMatchScreenState();
}

class _ScheduleMatchScreenState extends State<ScheduleMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _teamAId, _teamBId;
  String _matchType = 'T20';
  String _venue = '';
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _scorerUserCtrl = TextEditingController();
  final _scorerPassCtrl = TextEditingController();

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateCtrl.text = '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 30),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _timeCtrl.text = picked.format(context);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_teamAId == null || _teamBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both teams')),
      );
      return;
    }
    if (_teamAId == _teamBId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team A and Team B must be different')),
      );
      return;
    }
    if (_venue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a venue')),
      );
      return;
    }

    Provider.of<StorageService>(context, listen: false).scheduleMatch(
      teamAId: _teamAId!,
      teamBId: _teamBId!,
      matchType: _matchType,
      venue: _venue,
      date: _dateCtrl.text,
      time: _timeCtrl.text,
      scorerUser: _scorerUserCtrl.text.trim(),
      scorerPass: _scorerPassCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Match Scheduled Successfully! Scorer credentials assigned.'),
        backgroundColor: AppTheme.primaryGreen,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.matchList),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text('Schedule Match', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sports_cricket, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Match', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Fill in the match details below', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _Label('TEAMS'),
              const SizedBox(height: 10),
              // Team A
              Text('Team A (Home)', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: AppTheme.bgMedium,
                style: GoogleFonts.outfit(color: Colors.white),
                value: _teamAId,
                items: storage.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _teamAId = v),
                hint: Text('Select Team A', style: GoogleFonts.outfit(color: Colors.white30)),
              ),
              const SizedBox(height: 14),
              Text('Team B (Away)', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: AppTheme.bgMedium,
                style: GoogleFonts.outfit(color: Colors.white),
                value: _teamBId,
                items: storage.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _teamBId = v),
                hint: Text('Select Team B', style: GoogleFonts.outfit(color: Colors.white30)),
              ),

              const SizedBox(height: 20),
              _Label('MATCH FORMAT'),
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
                          color: selected ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppTheme.primaryBlue : Colors.white.withOpacity(0.1),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(type,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                  color: selected ? AppTheme.primaryBlue : Colors.white60)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              _Label('VENUE'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: AppTheme.bgMedium,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                value: _venue.isEmpty ? null : _venue,
                items: AppConstants.venues
                    .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _venue = v ?? ''),
                hint: Text('Select Venue', style: GoogleFonts.outfit(color: Colors.white30)),
              ),

              const SizedBox(height: 20),
              _Label('DATE & TIME'),
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
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'DD-MM-YYYY',
                          prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 18),
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
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '--:--',
                          prefixIcon: const Icon(Icons.access_time, color: Colors.white38, size: 18),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _Label('SCORER CREDENTIALS'),
              const SizedBox(height: 4),
              Text('The scorer will use these to log in and update the score',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _scorerUserCtrl,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Scorer Username',
                        prefixIcon: Icon(Icons.person_outline, color: Colors.white38, size: 18),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _scorerPassCtrl,
                      obscureText: true,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.white38, size: 18),
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
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Schedule Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1.3));
  }
}
