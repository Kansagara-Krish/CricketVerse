// lib/screens/admin/player_detail_screen.dart
// Player Career Statistics & Profile matching Light Mint Theme with Cricket Ball Watermark

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../services/storage_service.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    // Find latest player instance if available by ID or name to get real-time aggregated stats
    final p = storage.teams
        .expand((t) => t.players)
        .firstWhere(
          (item) => item.id == player.id || item.name.toLowerCase() == player.name.toLowerCase(),
          orElse: () => player,
        );

    final battingAvg = p.ballsFaced > 0 && p.matchesPlayed > 0
        ? (p.runsScored / p.matchesPlayed).toStringAsFixed(1)
        : '0.0';
    final strikeRate = p.ballsFaced > 0
        ? ((p.runsScored / p.ballsFaced) * 100).toStringAsFixed(1)
        : '0.0';
    final bowlingAvg = p.wicketsTaken > 0
        ? (p.runsConceded / p.wicketsTaken).toStringAsFixed(1)
        : '-';
    final economy = p.oversBowled > 0
        ? (p.runsConceded / p.oversBowled).toStringAsFixed(1)
        : '-';
    final bestBowling = p.wicketsTaken > 0 ? '${p.wicketsTaken}/24' : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F6),
      body: Stack(
        children: [
          // Background Cricket Ball Watermark
          Positioned.fill(
            child: CustomPaint(
              painter: PlayerWatermarkPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top Action Bar (Back Arrow & Circular Edit Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _confirmDeletePlayer(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppTheme.accentRed,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showEditSheet(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF028A6B),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Player Profile Header
                  Column(
                    children: [
                      // Circular Initial Avatar
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF028A6B).withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            p.name.isNotEmpty ? p.name[0].toLowerCase() : 'p',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF028A6B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF028A6B).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              p.role,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF028A6B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '|  ${p.matchesPlayed} matches',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // BATTING STATISTICS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3.5,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF028A6B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BATTING STATISTICS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Overall Performance',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatBox(label: 'Runs', value: '${p.runsScored}'),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Average', value: battingAvg),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Strike Rate', value: strikeRate),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatBox(label: 'Balls Faced', value: '${p.ballsFaced}'),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Matches', value: '${p.matchesPlayed}'),
                            const SizedBox(width: 10),
                            const _StatBox(label: 'Not Outs', value: '0'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BOWLING STATISTICS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3.5,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF028A6B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BOWLING STATISTICS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Overall Performance',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatBox(label: 'Wickets', value: '${p.wicketsTaken}'),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Average', value: bowlingAvg),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Economy', value: economy),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatBox(label: 'Overs', value: p.oversBowled.toStringAsFixed(1)),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Runs Given', value: '${p.runsConceded}'),
                            const SizedBox(width: 10),
                            _StatBox(label: 'Best', value: bestBowling),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CAREER HIGHLIGHTS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF028A6B),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CAREER HIGHLIGHTS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FCF9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6F4ED)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: Color(0xFF028A6B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (p.runsScored > 0 || p.wicketsTaken > 0 || p.matchesPlayed > 0)
                                          ? '${p.name}\'s Highlights'
                                          : 'No career highlights yet.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (p.runsScored > 0 || p.wicketsTaken > 0 || p.matchesPlayed > 0)
                                          ? '${p.runsScored} Runs • ${p.wicketsTaken} Wickets • ${p.matchesPlayed} Matches'
                                          : 'Stats will appear here as matches are played.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BOTTOM TIP BANNER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF028A6B),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keep playing, keep improving!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your statistics will be updated after each match.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlayer(BuildContext context) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    Team? currentTeam;
    for (final t in storage.teams) {
      if (t.players.any((p) => p.id == player.id)) {
        currentTeam = t;
        break;
      }
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Player',
      message: 'Are you sure you want to delete "${player.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppTheme.accentRed,
    );

    if (confirmed == true && context.mounted) {
      if (currentTeam != null) {
        storage.removePlayer(currentTeam.id, player.id);
      }
      Navigator.pop(context);
      CustomNotification.show(
        context,
        'Player "${player.name}" deleted successfully.',
        type: NotificationType.success,
      );
    }
  }

  void _showEditSheet(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
    Team? currentTeam;
    for (final t in storage.teams) {
      if (t.players.any((p) => p.id == player.id)) {
        currentTeam = t;
        break;
      }
    }

    final nameCtrl = TextEditingController(text: player.name);
    String selectedRole = player.role;
    String? selectedTeamId = currentTeam?.id;
    String selectedLeadership = player.isCaptain
        ? 'Captain'
        : player.isViceCaptain
            ? 'Vice-Captain'
            : 'None';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
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
                const SizedBox(height: 16),
                Text(
                  'Edit Player Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 14),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Player Role',
                    prefixIcon: Icon(Icons.sports_cricket_outlined, color: AppTheme.textMuted),
                  ),
                  items: ['Batter', 'Bowler', 'All-rounder'].map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 14),

                // Team Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedTeamId,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Assign Team',
                    prefixIcon: Icon(Icons.shield_outlined, color: AppTheme.textMuted),
                  ),
                  items: storage.teams.map((t) {
                    return DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedTeamId = val);
                  },
                ),
                const SizedBox(height: 14),

                // Leadership Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedLeadership,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Leadership Role',
                    prefixIcon: Icon(Icons.star_outline_rounded, color: AppTheme.accentGold),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'None', child: Text('Player (No Leadership)')),
                    DropdownMenuItem(value: 'Captain', child: Text('⭐ Captain (C)')),
                    DropdownMenuItem(value: 'Vice-Captain', child: Text('🎗️ Vice-Captain (VC)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedLeadership = val);
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        CustomNotification.show(context, 'Player name is required', type: NotificationType.warning);
                        return;
                      }

                      final updatedPlayer = Player(
                        id: player.id,
                        name: name,
                        role: selectedRole,
                        nationality: player.nationality,
                        isCaptain: selectedLeadership == 'Captain',
                        isViceCaptain: selectedLeadership == 'Vice-Captain',
                        runsScored: player.runsScored,
                        ballsFaced: player.ballsFaced,
                        wicketsTaken: player.wicketsTaken,
                        runsConceded: player.runsConceded,
                        oversBowled: player.oversBowled,
                        matchesPlayed: player.matchesPlayed,
                      );

                      if (selectedTeamId != currentTeam?.id) {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Move Player',
                          message: 'Are you sure you want to reassign this player to another team?',
                        );
                        if (confirmed == true) {
                          if (currentTeam != null) storage.removePlayer(currentTeam.id, player.id);
                          if (selectedTeamId != null) storage.addPlayer(selectedTeamId!, updatedPlayer);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            CustomNotification.show(context, 'Player updated and moved successfully!', type: NotificationType.success);
                          }
                        }
                      } else {
                        if (currentTeam != null) storage.updatePlayer(currentTeam.id, updatedPlayer);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          CustomNotification.show(context, 'Player updated successfully!', type: NotificationType.success);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF028A6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Single Stat Box Component
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FCF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6F4ED)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter for Top Right Light Green Cricket Ball Watermark ---
class PlayerWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ballPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final seamPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Top Right Cricket Ball behind avatar header
    final center = Offset(size.width * 0.84, size.height * 0.14);
    final radius = size.width * 0.28;
    canvas.drawCircle(center, radius, ballPaint);

    // Seam Lines
    final seamPath1 = Path();
    seamPath1.addArc(
      Rect.fromCircle(center: center, radius: radius * 0.86),
      -math.pi * 0.5,
      math.pi * 0.85,
    );
    canvas.drawPath(seamPath1, seamPaint);

    final seamPath2 = Path();
    seamPath2.addArc(
      Rect.fromCircle(center: center, radius: radius * 0.70),
      -math.pi * 0.45,
      math.pi * 0.8,
    );
    canvas.drawPath(seamPath2, seamPaint);

    // Motion Arc Swooshes
    final motionPath = Path();
    motionPath.addArc(
      Rect.fromCircle(center: Offset(center.dx - 20, center.dy + 15), radius: radius * 1.15),
      math.pi * 0.6,
      math.pi * 0.7,
    );
    canvas.drawPath(motionPath, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
