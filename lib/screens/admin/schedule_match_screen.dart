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
      labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
      hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
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
          'Schedule Match', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 18),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary,
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
                      child: const Icon(Icons.sports_cricket, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Match', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('Fill in the match details below', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const _Label('TEAMS'),
              const SizedBox(height: 10),
              // Team A
              Text('Team A (Home)', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                value: _teamAId,
                decoration: inputDecorationTheme.copyWith(hintText: 'Select Team A'),
                items: storage.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _teamAId = v),
              ),
              const SizedBox(height: 14),
              Text('Team B (Away)', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                value: _teamBId,
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
                            style: GoogleFonts.outfit(
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
              const _Label('VENUE'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13),
                value: _venue.isEmpty ? null : _venue,
                decoration: inputDecorationTheme.copyWith(hintText: 'Select Venue'),
                items: AppConstants.venues
                    .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _venue = v ?? ''),
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
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
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
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
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

              const SizedBox(height: 20),
              const _Label('SCORER CREDENTIALS'),
              const SizedBox(height: 4),
              Text(
                'The scorer will use these to log in and update the score',
                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _scorerUserCtrl,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                      decoration: inputDecorationTheme.copyWith(
                        labelText: 'Scorer Username',
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
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
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
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11, 
        fontWeight: FontWeight.w700, 
        color: AppTheme.textSecondary, 
        letterSpacing: 1.3,
      ),
    );
  }
}
