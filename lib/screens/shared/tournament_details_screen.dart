import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/widgets/team_logo.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;
  const TournamentDetailsScreen({Key? key, required this.tournament}) : super(key: key);

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> with SingleTickerProviderStateMixin {
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
    final tourn = widget.tournament;
    final storage = Provider.of<StorageService>(context);

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
          tourn['name'] ?? 'Tournament Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPurple,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Standings'),
            Tab(text: 'Matches'),
            Tab(text: 'Teams'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Standings Tab
          _buildStandingsTab(storage),
          // 2. Matches Tab
          _buildMatchesTab(storage),
          // 3. Teams Tab
          _buildTeamsTab(storage),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(StorageService storage) {
    final teams = storage.teams;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassCard,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black.withOpacity(0.05),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('TEAM', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                  Expanded(child: Center(child: Text('P', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(child: Center(child: Text('W', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(child: Center(child: Text('L', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(child: Center(child: Text('PTS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(flex: 2, child: Center(child: Text('NRR', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teams.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (ctx, idx) {
                final t = teams[idx];
                final wins = idx == 0 ? 4 : (idx == 1 ? 3 : (idx == 2 ? 2 : 1));
                final losses = 5 - wins;
                final pts = wins * 2;
                final nrr = idx == 0 ? '+1.42' : (idx == 1 ? '+0.65' : (idx == 2 ? '-0.12' : '-1.50'));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text('${idx + 1}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            TeamLogo(teamName: t.name, shortName: t.shortName, logoColorHex: t.logoColorHex, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.shortName, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Expanded(child: Center(child: Text('5', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textPrimary)))),
                      Expanded(child: Center(child: Text('$wins', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('$losses', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.accentRed)))),
                      Expanded(child: Center(child: Text('$pts', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)))),
                      Expanded(flex: 2, child: Center(child: Text(nrr, style: GoogleFonts.outfit(fontSize: 12, color: nrr.startsWith('+') ? AppTheme.primaryGreen : AppTheme.accentRed)))),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab(StorageService storage) {
    final matches = storage.matches;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (ctx, idx) {
        final match = matches[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.glassCard,
          child: ListTile(
            onTap: () {
              Navigator.pushNamed(
                ctx,
                storage.currentRole == 'Admin' ? AppRoutes.matchDetail : AppRoutes.userMatchDetails,
                arguments: storage.currentRole == 'Admin' ? match : match.id,
              );
            },
            title: Text('${match.teamA.name} vs ${match.teamB.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary)),
            subtitle: Text('${match.venue} • ${match.date}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (match.status == 'Live' ? AppTheme.accentRed : AppTheme.primaryBlue).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(match.status, style: GoogleFonts.outfit(color: match.status == 'Live' ? AppTheme.accentRed : AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab(StorageService storage) {
    final teams = storage.teams;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: teams.length,
      itemBuilder: (ctx, idx) {
        final team = teams[idx];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              ctx,
              storage.currentRole == 'Admin' ? AppRoutes.teamDetail : AppRoutes.userTeamDetails,
              arguments: team,
            );
          },
          child: Container(
            decoration: AppTheme.glassCard,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamLogo(teamName: team.name, shortName: team.shortName, logoColorHex: team.logoColorHex, size: 36),
                const SizedBox(height: 10),
                Text(team.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${team.players.length} Players', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
