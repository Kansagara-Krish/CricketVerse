// lib/screens/admin/match_detail_screen.dart
// Full match detail: scoreboard, commentary, prediction links, and actions

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class MatchDetailScreen extends StatelessWidget {
  final CricketMatch match;
  const MatchDetailScreen({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'Live';
    final statusColor = AppTheme.statusColor(match.status);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // Hero Scoreboard App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.bgDeep,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLive
                        ? [const Color(0xFF064E3B), AppTheme.bgDeep]
                        : [const Color(0xFF1E293B), AppTheme.bgDeep],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                    child: Column(
                      children: [
                        // Status + Match Type
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                isLive ? '● LIVE' : match.status.toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 11, color: statusColor, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(match.matchType,
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0x610F172A))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Main Score Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _TeamScore(
                              shortName: match.teamA.shortName,
                              fullName: match.teamA.name,
                              runs: match.runsA,
                              wickets: match.wicketsA,
                              overs: match.oversA,
                              isBatting: match.isFirstInnings && match.status == 'Live',
                            ),
                            Column(
                              children: [
                                Text('VS',
                                    style: GoogleFonts.outfit(
                                        fontSize: 18, fontWeight: FontWeight.w900,
                                        color: const Color(0x3D0F172A))),
                                if (match.target > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('Target: ${match.target}',
                                        style: GoogleFonts.outfit(
                                            fontSize: 10, color: AppTheme.accentGold)),
                                  ),
                              ],
                            ),
                            _TeamScore(
                              shortName: match.teamB.shortName,
                              fullName: match.teamB.name,
                              runs: match.runsB,
                              wickets: match.wicketsB,
                              overs: match.oversB,
                              isBatting: !match.isFirstInnings && match.status == 'Live',
                              alignRight: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '📍 ${match.venue}',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0x610F172A)),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${match.date} at ${match.time}',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x3D0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    _SectionLabel('LIVE TOOLS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ActionButton(
                          Icons.scoreboard_rounded,
                          'Live Scoring',
                          AppTheme.primaryGreen,
                          () => Navigator.pushNamed(context, AppRoutes.liveScoring, arguments: match),
                        ),
                        const SizedBox(width: 12),
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
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: const Color(0x3D0F172A)),
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
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: const Color(0x3D0F172A)),
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
                  _SectionLabel('MATCH INFO'),
                  const SizedBox(height: 12),
                  _InfoRow(Icons.emoji_events_outlined, 'Toss', '${match.tossWinner} — ${match.tossDecision}'),
                  _InfoRow(Icons.location_on_outlined, 'Venue', match.venue),
                  _InfoRow(Icons.calendar_today_outlined, 'Date & Time', '${match.date} at ${match.time}'),
                  _InfoRow(Icons.sports_cricket, 'Format', match.matchType),
                  _InfoRow(Icons.person_pin_rounded, 'Scorer', match.scorerUsername.isNotEmpty ? match.scorerUsername : 'Not assigned'),
                  const SizedBox(height: 20),

                  // Playing XI
                  _SectionLabel('PLAYING XI — ${match.teamA.shortName}'),
                  const SizedBox(height: 8),
                  ...match.playingXI_A.take(6).map((p) => _PlayerRow(p)).toList(),
                  if (match.playingXI_A.length > 6)
                    TextButton(
                      onPressed: () {},
                      child: Text('+ ${match.playingXI_A.length - 6} more players',
                          style: GoogleFonts.outfit(color: AppTheme.primaryBlue)),
                    ),

                  const SizedBox(height: 12),
                  _SectionLabel('PLAYING XI — ${match.teamB.shortName}'),
                  const SizedBox(height: 8),
                  ...match.playingXI_B.take(6).map((p) => _PlayerRow(p)).toList(),
                  if (match.playingXI_B.length > 6)
                    TextButton(
                      onPressed: () {},
                      child: Text('+ ${match.playingXI_B.length - 6} more players',
                          style: GoogleFonts.outfit(color: AppTheme.primaryBlue)),
                    ),

                  // Ball-by-ball
                  if (match.balls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionLabel('RECENT BALLS'),
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
                              backgroundColor: bc.withOpacity(0.2),
                              child: Text(label,
                                  style: GoogleFonts.outfit(fontSize: 12, color: bc, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(b.commentary,
                                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xDE0F172A), height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

class _TeamScore extends StatelessWidget {
  final String shortName, fullName;
  final int runs, wickets;
  final double overs;
  final bool isBatting;
  final bool alignRight;

  const _TeamScore({
    required this.shortName,
    required this.fullName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.isBatting,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (isBatting)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('BATTING', style: GoogleFonts.outfit(fontSize: 8, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
          ),
        Text(shortName,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        Text(fullName,
            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0x610F172A))),
        if (runs > 0 || overs > 0) ...[
          const SizedBox(height: 6),
          Text('$runs/$wickets',
              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          Text('($overs overs)',
              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x8A0F172A))),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0x610F172A), letterSpacing: 1.4));
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
          Text('$label: ', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x8A0F172A))),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xDE0F172A), fontWeight: FontWeight.w600),
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
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(player.name.substring(0, 1),
                style: GoogleFonts.outfit(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(player.name, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xDE0F172A)))),
          Text(player.role, style: GoogleFonts.outfit(fontSize: 11, color: roleColor)),
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
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
