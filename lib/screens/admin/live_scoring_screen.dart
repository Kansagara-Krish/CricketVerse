// lib/screens/admin/live_scoring_screen.dart
// Full live scoring interface with run buttons, extras, wicket, end over

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_notification.dart';

class LiveScoringScreen extends StatefulWidget {
  final CricketMatch match;
  const LiveScoringScreen({super.key, required this.match});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final List<String> _currentOverBalls = [];

  @override
  void initState() {
    super.initState();
    // Activate match for admin scoring (bypasses scorer login requirement)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StorageService>(context, listen: false)
          .adminActivateMatch(widget.match.id);
    });
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _addBall(String label) {
    setState(() {
      _currentOverBalls.add(label);
      if (_currentOverBalls.length >= 6) _currentOverBalls.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _recordRun(int runs) {
    final storage = Provider.of<StorageService>(context, listen: false);
    storage.updateScore(
      runs: runs, extraType: 'None', extraRuns: 0, isWicket: false, wicketType: 'None',
    );
    _addBall('$runs');
  }

  void _recordExtra(String type) {
    final storage = Provider.of<StorageService>(context, listen: false);
    storage.updateScore(
      runs: 0, extraType: type, extraRuns: 1, isWicket: false, wicketType: 'None',
    );
    _addBall(type == 'Wide' ? 'Wd' : type == 'No Ball' ? 'NB' : type == 'Leg Bye' ? 'LB' : 'B');
  }

  void _recordWicket() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Wicket Type', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Wrap(
          spacing: 8, runSpacing: 8,
          children: ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket'].map((type) =>
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                final storage = Provider.of<StorageService>(context, listen: false);
                storage.updateScore(runs: 0, extraType: 'None', extraRuns: 0, isWicket: true, wicketType: type);
                _addBall('W');
                HapticFeedback.heavyImpact();
                CustomNotification.show(
                  context,
                  'Wicket recorded: $type!',
                  type: NotificationType.error,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.4)),
                ),
                child: Text(type, style: GoogleFonts.plusJakartaSans(color: AppTheme.accentRed, fontWeight: FontWeight.w600)),
              ),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _endOver() {
    final storage = Provider.of<StorageService>(context, listen: false);
    storage.endOver();
    setState(() => _currentOverBalls.clear());
    CustomNotification.show(
      context,
      'Over ended. Strike rotated.',
      type: NotificationType.success,
    );
  }

  void _nextInnings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End First Innings?', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('This will start the second innings. Are you sure?',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<StorageService>(context, listen: false).endInningsOrMatch();
              CustomNotification.show(
                context,
                'Second Innings Started!',
                type: NotificationType.info,
              );
            },
            child: const Text('Start 2nd Innings'),
          ),
        ],
      ),
    );
  }

  void _finishMatch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Finish Match?', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('This will mark the match as Completed.',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<StorageService>(context, listen: false).endMatchForce();
              Navigator.pop(context);
              CustomNotification.show(
                context,
                'Match Completed successfully!',
                type: NotificationType.success,
              );
            },
            child: const Text('Finish Match'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final m = storage.matches.firstWhere(
      (x) => x.id == widget.match.id,
      orElse: () => widget.match,
    );

    final currentRuns = m.isFirstInnings ? m.runsA : m.runsB;
    final currentWickets = m.isFirstInnings ? m.wicketsA : m.wicketsB;
    final currentOvers = m.isFirstInnings ? m.oversA : m.oversB;
    final battingTeam = m.battingTeamId == m.teamA.id ? m.teamA : m.teamB;
    final bowlingTeam = m.battingTeamId == m.teamA.id ? m.teamB : m.teamA;
    final striker = battingTeam.players.firstWhere(
      (p) => p.id == m.currentStrikerId, orElse: () => battingTeam.players[0]);
    final bowler = bowlingTeam.players.firstWhere(
      (p) => p.id == m.currentBowlerId, orElse: () => bowlingTeam.players.last);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('Live Scoring', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.aiCommentary, arguments: m),
            icon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primaryBlue, size: 18),
            label: Text('Commentary', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Score Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(6)),
                        child: Text('● LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Text('${m.matchType} • ${m.isFirstInnings ? "1st" : "2nd"} Innings',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                    child: Text(
                      '$currentRuns/$currentWickets',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                    ),
                  ),
                  Text('($currentOvers overs)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white70)),
                  if (m.target > 0 && !m.isFirstInnings)
                    Text('Target: ${m.target} • Need: ${m.target - currentRuns} off ${(20 - currentOvers).toStringAsFixed(1)} ov',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white)),
                  const SizedBox(height: 12),
                  // Current Over Balls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ..._currentOverBalls.map((b) {
                        Color bc = b == 'W'
                            ? AppTheme.accentRed
                            : b == '6'
                                ? AppTheme.primaryGreen
                                : b == '4'
                                    ? AppTheme.primaryBlue
                                    : (b == 'Wd' || b == 'NB')
                                        ? AppTheme.accentOrange
                                        : Colors.white70;
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bc.withValues(alpha: 0.15),
                            border: Border.all(color: bc.withValues(alpha: 0.6)),
                          ),
                          child: Center(
                            child: Text(b, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: bc, fontWeight: FontWeight.w800)),
                          ),
                        );
                      }),
                      ...List.generate(6 - _currentOverBalls.length, (_) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textPrimary.withValues(alpha: 0.05),
                          border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.1)),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),

            // Batters & Bowler Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _PlayerChip(
                      '${striker.name} *',
                      '${striker.runsScored} (${striker.ballsFaced})',
                      AppTheme.primaryBlue,
                      Icons.sports_cricket,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlayerChip(
                      bowler.name,
                      '${bowler.wicketsTaken}/${bowler.runsConceded} (${bowler.oversBowled.toStringAsFixed(1)})',
                      AppTheme.accentRed,
                      Icons.sports_baseball,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Run Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Main runs
                  Row(
                    children: [0, 1, 2, 3].map((r) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _RunButton(
                          label: '$r',
                          color: r == 0 ? Colors.black26 : AppTheme.primaryBlue,
                          onTap: () => _recordRun(r),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: _RunButton(label: '4', color: AppTheme.accentGold, onTap: () => _recordRun(4), large: true),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: _RunButton(label: '6', color: AppTheme.primaryGreen, onTap: () => _recordRun(6), large: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Extras
                  Row(
                    children: [
                      Expanded(child: Padding(padding: const EdgeInsets.all(4),
                          child: _RunButton(label: 'Wide', color: AppTheme.accentOrange, onTap: () => _recordExtra('Wide'), small: true))),
                      Expanded(child: Padding(padding: const EdgeInsets.all(4),
                          child: _RunButton(label: 'No Ball', color: AppTheme.accentOrange, onTap: () => _recordExtra('No Ball'), small: true))),
                      Expanded(child: Padding(padding: const EdgeInsets.all(4),
                          child: _RunButton(label: 'Bye', color: AppTheme.textMuted, onTap: () => _recordExtra('Bye'), small: true))),
                      Expanded(child: Padding(padding: const EdgeInsets.all(4),
                          child: _RunButton(label: 'Leg Bye', color: AppTheme.textMuted, onTap: () => _recordExtra('Leg Bye'), small: true))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Wicket button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _RunButton(
                      label: '🔴 WICKET',
                      color: AppTheme.accentRed,
                      onTap: _recordWicket,
                      large: true,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('↩️ Last ball undone')));
                          },
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Undo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.textMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _endOver,
                          icon: const Icon(Icons.navigate_next_rounded, size: 20),
                          label: const Text('End Over'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _nextInnings,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text('Next Innings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentGold,
                            side: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _finishMatch,
                          icon: const Icon(Icons.flag_rounded, size: 18),
                          label: const Text('Finish Match'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentRed.withValues(alpha: 0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Recent commentary
            if (m.balls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAST BALL', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassCardSmall,
                      child: Text(
                        m.balls.last.commentary,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool large;
  final bool small;
  final bool fullWidth;

  const _RunButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.large = false,
    this.small = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: large ? 64 : small ? 44 : 54,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: large ? 20 : small ? 12 : 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String name, stats;
  final Color color;
  final IconData icon;
  const _PlayerChip(this.name, this.stats, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(stats, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
