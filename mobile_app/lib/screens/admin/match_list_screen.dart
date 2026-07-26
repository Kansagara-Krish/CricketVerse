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
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text('Matches', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: 'LIVE (${live.length})'),
            Tab(text: 'UPCOMING (${upcoming.length})'),
            Tab(text: 'COMPLETED (${completed.length})'),
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
      backgroundColor: Colors.white,
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 800)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (_, i) => CardEntranceAnimation(
          index: i,
          child: _MatchTile(match: matches[i]),
        ),
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
        decoration: AppTheme.glassCard,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isLive ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isLive ? '● LIVE' : match.status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: statusColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(match.matchType,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      match.venue.split(',').first,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
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
                    child: Row(
                      children: [
                        TeamLogo(
                          teamName: match.teamA.name,
                          shortName: match.teamA.shortName,
                          logoColorHex: match.teamA.logoColorHex,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                match.teamA.shortName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              Text(match.teamA.name,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (match.runsA > 0 || match.wicketsA > 0 || match.oversA > 0) ...[
                                const SizedBox(height: 4),
                                Text('${match.runsA}/${match.wicketsA}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                Text('(${match.oversA} ov)',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // VS Center
                  Column(
                    children: [
                      Text('VS',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0x2D0F172A))),
                      if (match.target > 0 && !match.isFirstInnings)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('T: ${match.target}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.accentGold, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  // Team B
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(
                                match.teamB.shortName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              Text(match.teamB.name,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (match.runsB > 0 || match.wicketsB > 0 || match.oversB > 0) ...[
                                const SizedBox(height: 4),
                                Text('${match.runsB}/${match.wicketsB}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                Text('(${match.oversB} ov)',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TeamLogo(
                          teamName: match.teamB.name,
                          shortName: match.teamB.shortName,
                          logoColorHex: match.teamB.logoColorHex,
                          size: 32,
                        ),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textMuted)),
                  const Spacer(),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
