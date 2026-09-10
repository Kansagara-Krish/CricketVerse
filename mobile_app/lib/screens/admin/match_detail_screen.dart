import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/team_logo.dart';


class MatchDetailScreen extends StatelessWidget {
  final CricketMatch match;
  const MatchDetailScreen({super.key, required this.match});

  Color _parseTeamColor(String hex, Color fallback) {
    if (hex.isEmpty) return fallback;
    String clean = hex.replaceAll('#', '').replaceAll('0x', '');
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16);
    return val != null ? Color(val) : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'Live';

    // Score / number display
    final String scoreA;
    if (isLive || match.status == 'Completed') {
      scoreA = '${match.runsA}/${match.wicketsA}';
    } else {
      if (match.runsA > 0 || match.wicketsA > 0) {
        scoreA = '${match.runsA}/${match.wicketsA}';
      } else if (match.teamA.name.isNotEmpty &&
          match.teamA.name != match.teamA.shortName &&
          match.teamA.name.length <= 6) {
        scoreA = match.teamA.name;
      } else {
        scoreA = '${match.runsA}/${match.wicketsA}';
      }
    }

    final String scoreB;
    if (isLive || match.status == 'Completed') {
      scoreB = '${match.runsB}/${match.wicketsB}';
    } else {
      if (match.runsB > 0 || match.wicketsB > 0) {
        scoreB = '${match.runsB}/${match.wicketsB}';
      } else if (match.teamB.name.isNotEmpty &&
          match.teamB.name != match.teamB.shortName &&
          match.teamB.name.length <= 6) {
        scoreB = match.teamB.name;
      } else {
        scoreB = '${match.runsB}/${match.wicketsB}';
      }
    }

    final teamAColor = _parseTeamColor(match.teamA.logoColorHex, const Color(0xFFDC2626));
    final teamBColor = _parseTeamColor(match.teamB.logoColorHex, const Color(0xFFD97706));

    final venueText = match.venue.isNotEmpty ? match.venue.toUpperCase() : 'MAIN STADIUM';
    final dateTimeText = '${match.date.isNotEmpty ? match.date : "06-09-2026"} at ${match.time.isNotEmpty ? match.time : "6:00 PM"}';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // Hero Stadium Scoreboard Banner
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Pristine Stadium Background Image
                  Image.asset(
                    'assets/images/stadium_board.jpg',
                    fit: BoxFit.cover,
                  ),

                  // Dynamic Content aligned onto billboard & pitch
                  SafeArea(
                    child: Column(
                      children: [
                        // Top Sky: Status Badge + Match Format
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF00E5FF),
                                    width: 1.5,
                                  ),
                                  boxShadow: isLive
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  isLive ? '● LIVE' : match.status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF00E5FF),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                match.matchType,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Center Billboard Screen: Team A | VS | Team B
                        // Rendered directly on the blank billboard screen with no box wrapper
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Team A
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TeamLogo(
                                      teamName: match.teamA.name,
                                      shortName: match.teamA.shortName,
                                      logoColorHex: match.teamA.logoColorHex,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 5),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        scoreA,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      height: 2.5,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: teamAColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.teamA.shortName.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF334155),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // VS
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'VS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ),

                              // Team B
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TeamLogo(
                                      teamName: match.teamB.name,
                                      shortName: match.teamB.shortName,
                                      logoColorHex: match.teamB.logoColorHex,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 5),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        scoreB,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      height: 2.5,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: teamBColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.teamB.shortName.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF334155),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 4),

                        // Grass Pitch Area: Venue + Date & Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 15),
                            const SizedBox(width: 4),
                            Text(
                              venueText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateTimeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  if (isLive) ...[
                    const _SectionLabel('LIVE TOOLS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ActionButton(
                          Icons.record_voice_over_rounded,
                          'AI Commentary',
                          AppTheme.primaryBlue,
                          () => Navigator.pushNamed(context, AppRoutes.aiCommentary, arguments: match),
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          Icons.auto_awesome,
                          'Prediction',
                          AppTheme.accentPurple,
                          () => Navigator.pushNamed(context, AppRoutes.prediction, arguments: match),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (!isLive) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.aiCommentary, arguments: match),
                            icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                            label: const Text('View Commentary'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: AppTheme.textMuted),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.statistics),
                            icon: const Icon(Icons.bar_chart_rounded, size: 18),
                            label: const Text('Statistics'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: AppTheme.textMuted),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Match Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('MATCH INFO'),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 22),
                        tooltip: 'Edit Match Details',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.scheduleMatch, arguments: match);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(Icons.emoji_events_outlined, 'Toss', match.tossWinner.isNotEmpty ? '${match.tossWinner} — ${match.tossDecision}' : 'Not done yet'),
                  _InfoRow(Icons.location_on_outlined, 'Venue', match.venue),
                  _InfoRow(Icons.calendar_today_outlined, 'Date & Time', '${match.date} at ${match.time}'),
                  _InfoRow(Icons.sports_cricket, 'Format', match.matchType),
                  _InfoRow(Icons.person_pin_rounded, 'Manager Username', match.scorerUsername.isNotEmpty ? match.scorerUsername : 'Not assigned'),
                  _InfoRow(Icons.lock_outline_rounded, 'Manager Password', match.scorerPassword.isNotEmpty ? match.scorerPassword : 'Not set'),
                  const SizedBox(height: 20),

                  // Playing XI
                  _SectionLabel('PLAYING XI — ${match.teamA.shortName}'),
                  const SizedBox(height: 8),
                  ...match.playingXI_A.take(6).map((p) => _PlayerRow(p)),
                  if (match.playingXI_A.length > 6)
                    TextButton(
                      onPressed: () {},
                      child: Text('+ ${match.playingXI_A.length - 6} more players',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue)),
                    ),

                  const SizedBox(height: 12),
                  _SectionLabel('PLAYING XI — ${match.teamB.shortName}'),
                  const SizedBox(height: 8),
                  ...match.playingXI_B.take(6).map((p) => _PlayerRow(p)),
                  if (match.playingXI_B.length > 6)
                    TextButton(
                      onPressed: () {},
                      child: Text('+ ${match.playingXI_B.length - 6} more players',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue)),
                    ),

                  // Ball-by-ball
                  if (match.balls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionLabel('RECENT BALLS'),
                    const SizedBox(height: 10),
                    ...match.balls.reversed.take(5).map((b) {
                      String label;
                      Color bc;
                      if (b.isWicket) { label = 'W'; bc = AppTheme.accentRed; }
                      else if (b.run == 6) { label = '6'; bc = AppTheme.primaryGreen; }
                      else if (b.run == 4) { label = '4'; bc = AppTheme.primaryBlue; }
                      else if (b.extraType != 'None') { label = b.extraType.substring(0, 1); bc = AppTheme.accentOrange; }
                      else { label = '${b.run}'; bc = Colors.white38; }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.glassCardSmall,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: bc.withValues(alpha: 0.2),
                              child: Text(label,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: bc, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(b.commentary,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.4));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          Text('$label: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final dynamic player;
  const _PlayerRow(this.player);

  @override
  Widget build(BuildContext context) {
    final roleColor = AppTheme.roleColor(player.role);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: roleColor.withValues(alpha: 0.1),
            child: Text(player.name.substring(0, 1),
                style: GoogleFonts.plusJakartaSans(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(player.name, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary))),
          Text(player.role, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: roleColor)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
