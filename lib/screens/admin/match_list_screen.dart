// lib/screens/admin/match_list_screen.dart
// Upcoming / Live / Completed matches with TabBar

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/empty_state.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({Key? key}) : super(key: key);

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final live = storage.matches.where((m) => m.status == 'Live').toList();
    final upcoming = storage.matches.where((m) => m.status == 'Upcoming').toList();
    final completed = storage.matches.where((m) => m.status == 'Completed').toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: AppTheme.bgDeep,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          tabs: [
            Tab(text: 'Live (${live.length})'),
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scheduleMatch),
            tooltip: 'Schedule Match',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MatchListView(matches: live, emptyMsg: 'No live matches right now.', emptyIcon: Icons.sports_cricket),
          _MatchListView(matches: upcoming, emptyMsg: 'No upcoming matches scheduled.\nTap + to schedule one.', emptyIcon: Icons.calendar_today_outlined,
              onAdd: () => Navigator.pushNamed(context, AppRoutes.scheduleMatch)),
          _MatchListView(matches: completed, emptyMsg: 'No completed matches yet.', emptyIcon: Icons.check_circle_outline),
        ],
      ),
    );
  }
}

class _MatchListView extends StatelessWidget {
  final List<CricketMatch> matches;
  final String emptyMsg;
  final IconData emptyIcon;
  final VoidCallback? onAdd;

  const _MatchListView({
    required this.matches,
    required this.emptyMsg,
    required this.emptyIcon,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: 'No Matches',
        subtitle: emptyMsg,
        buttonLabel: onAdd != null ? 'Schedule Match' : null,
        onButtonTap: onAdd,
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      backgroundColor: AppTheme.bgMedium,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (_, i) => _MatchTile(match: matches[i]),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final CricketMatch match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(match.status);
    final isLive = match.status == 'Live';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLive ? AppTheme.primaryGreen.withOpacity(0.4) : Colors.black.withOpacity(0.07),
          ),
          boxShadow: isLive
              ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.1), blurRadius: 12)]
              : [],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isLive ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      isLive ? '● LIVE' : match.status.toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 10, color: statusColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(match.matchType,
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 12, color: const Color(0x610F172A)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      match.venue.split(',').first,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A)),
                    ),
                  ),
                ],
              ),
            ),

            // Score Display
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Team A
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.teamA.shortName,
                            style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                        Text(match.teamA.name,
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                        if (match.runsA > 0) ...[
                          const SizedBox(height: 4),
                          Text('${match.runsA}/${match.wicketsA}',
                              style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xDE0F172A))),
                          Text('(${match.oversA} ov)',
                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                        ],
                      ],
                    ),
                  ),
                  // VS Center
                  Column(
                    children: [
                      Text('VS',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0x1F0F172A))),
                      if (match.target > 0 && !match.isFirstInnings)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('T: ${match.target}',
                              style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.accentGold, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  // Team B
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(match.teamB.shortName,
                            style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                        Text(match.teamB.name,
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                        if (match.runsB > 0) ...[
                          const SizedBox(height: 4),
                          Text('${match.runsB}/${match.wicketsB}',
                              style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xDE0F172A))),
                          Text('(${match.oversB} ov)',
                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text('${match.date} • ${match.time}',
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                  const Spacer(),
                  if (isLive)
                    _ActionChip(
                      Icons.scoreboard_rounded,
                      'Score',
                      AppTheme.primaryGreen,
                      () => Navigator.pushNamed(context, AppRoutes.liveScoring, arguments: match),
                    ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    Icons.info_outline,
                    'Details',
                    AppTheme.primaryBlue,
                    () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: match),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
