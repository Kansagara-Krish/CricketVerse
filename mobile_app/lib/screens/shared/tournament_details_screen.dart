import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../core/widgets/team_logo.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;
  const TournamentDetailsScreen({super.key, required this.tournament});

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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPurple,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
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
    final tournId = widget.tournament['id']?.toString() ?? '';
    final rawParticipating = widget.tournament['participatingTeamIds'];
    final List<String> participatingIds = rawParticipating is List
        ? rawParticipating.map((e) => e.toString()).toList()
        : [];

    final tournMatches = storage.matches.where((m) {
      if (tournId.isNotEmpty && m.tournamentId == tournId) return true;
      if (participatingIds.isNotEmpty) {
        return participatingIds.contains(m.teamA.id) && participatingIds.contains(m.teamB.id);
      }
      return true;
    }).toList();

    List<Team> teams = participatingIds.isNotEmpty
        ? storage.teams.where((t) => participatingIds.contains(t.id)).toList()
        : storage.teams;

    if (teams.isEmpty) teams = storage.teams;

    // Helper to convert overs like 19.4 to decimal 19.666
    double toDecimalOvers(double oversVal) {
      if (oversVal <= 0) return 0.0;
      final int completed = oversVal.floor();
      final int balls = ((oversVal - completed) * 10).round();
      return completed + (balls / 6.0);
    }

    // Dynamic Team Stats record
    final List<Map<String, dynamic>> standings = teams.map((team) {
      int played = 0;
      int won = 0;
      int lost = 0;
      int tied = 0;
      int runsScored = 0;
      double oversFacedDec = 0.0;
      int runsConceded = 0;
      double oversBowledDec = 0.0;

      for (var m in tournMatches) {
        final isTeamA = m.teamA.id == team.id;
        final isTeamB = m.teamB.id == team.id;
        if (!isTeamA && !isTeamB) continue;

        if (m.status == 'Live' || m.status == 'Completed') {
          if (isTeamA) {
            runsScored += m.runsA;
            oversFacedDec += toDecimalOvers(m.oversA);
            runsConceded += m.runsB;
            oversBowledDec += toDecimalOvers(m.oversB);
          } else {
            runsScored += m.runsB;
            oversFacedDec += toDecimalOvers(m.oversB);
            runsConceded += m.runsA;
            oversBowledDec += toDecimalOvers(m.oversA);
          }
        }

        if (m.status == 'Completed') {
          played += 1;
          final isWinner = m.winnerTeamId.isNotEmpty
              ? m.winnerTeamId == team.id
              : (m.winnerName.isNotEmpty
                  ? m.winnerName == team.name
                  : (isTeamA ? m.runsA > m.runsB : m.runsB > m.runsA));

          final isTie = m.winnerName == 'Tie' || (m.runsA == m.runsB && m.runsA > 0);

          if (isTie) {
            tied += 1;
          } else if (isWinner) {
            won += 1;
          } else {
            lost += 1;
          }
        }
      }

      final int pts = (won * 2) + (tied * 1);
      final double forRate = oversFacedDec > 0 ? (runsScored / oversFacedDec) : 0.0;
      final double againstRate = oversBowledDec > 0 ? (runsConceded / oversBowledDec) : 0.0;
      final double nrrVal = forRate - againstRate;
      final String nrr = nrrVal >= 0 ? '+${nrrVal.toStringAsFixed(2)}' : nrrVal.toStringAsFixed(2);

      return {
        'team': team,
        'played': played,
        'won': won,
        'lost': lost,
        'tied': tied,
        'pts': pts,
        'nrr': nrr,
        'nrrVal': nrrVal,
      };
    }).toList();

    // Sort by Points (desc), NRR (desc), Won (desc), Name (asc)
    standings.sort((a, b) {
      if (b['pts'] != a['pts']) return (b['pts'] as int).compareTo(a['pts'] as int);
      if (b['nrrVal'] != a['nrrVal']) return (b['nrrVal'] as double).compareTo(a['nrrVal'] as double);
      if (b['won'] != a['won']) return (b['won'] as int).compareTo(a['won'] as int);
      return (a['team'] as Team).name.compareTo((b['team'] as Team).name);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassCard,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('TEAM', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                  Expanded(child: Center(child: Text('P', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(child: Center(child: Text('W', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(child: Center(child: Text('L', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(child: Center(child: Text('PTS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                  Expanded(flex: 2, child: Center(child: Text('NRR', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)))),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: standings.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (ctx, idx) {
                final item = standings[idx];
                final Team t = item['team'] as Team;
                final int played = item['played'] as int;
                final int wins = item['won'] as int;
                final int losses = item['lost'] as int;
                final int pts = item['pts'] as int;
                final String nrr = item['nrr'] as String;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text('${idx + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            TeamLogo(teamName: t.name, shortName: t.shortName, logoColorHex: t.logoColorHex, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.shortName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Expanded(child: Center(child: Text('$played', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary)))),
                      Expanded(child: Center(child: Text('$wins', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('$losses', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.accentRed)))),
                      Expanded(child: Center(child: Text('$pts', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)))),
                      Expanded(flex: 2, child: Center(child: Text(nrr, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: nrr.startsWith('+') ? AppTheme.primaryGreen : AppTheme.accentRed)))),
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
    final tournId = widget.tournament['id']?.toString() ?? '';
    final rawParticipating = widget.tournament['participatingTeamIds'];
    final List<String> participatingIds = rawParticipating is List
        ? rawParticipating.map((e) => e.toString()).toList()
        : [];

    final matches = storage.matches.where((m) {
      if (tournId.isNotEmpty && m.tournamentId == tournId) return true;
      if (participatingIds.isNotEmpty) {
        return participatingIds.contains(m.teamA.id) && participatingIds.contains(m.teamB.id);
      }
      return true;
    }).toList();

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_cricket_rounded, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'No matches scheduled yet for this tournament.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (ctx, idx) {
        final match = matches[idx];
        final scoreText = match.status != 'Upcoming'
            ? '${match.teamA.shortName} ${match.runsA}/${match.wicketsA} (${match.oversA}) vs ${match.teamB.shortName} ${match.runsB}/${match.wicketsB} (${match.oversB})'
            : '${match.date} • ${match.time} • ${match.venue}';

        final resultOrLiveText = match.status == 'Completed'
            ? (match.resultText.isNotEmpty ? match.resultText : 'Completed')
            : match.status;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.glassCard,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () {
                Navigator.pushNamed(
                  ctx,
                  storage.currentRole == 'Admin' ? AppRoutes.matchDetail : AppRoutes.userMatchDetails,
                  arguments: storage.currentRole == 'Admin' ? match : match.id,
                );
              },
              title: Text(
                '${match.teamA.name} vs ${match.teamB.name}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                scoreText,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (match.status == 'Live'
                          ? AppTheme.accentRed
                          : (match.status == 'Completed' ? AppTheme.primaryGreen : AppTheme.primaryBlue))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resultOrLiveText,
                  style: GoogleFonts.plusJakartaSans(
                    color: match.status == 'Live'
                        ? AppTheme.accentRed
                        : (match.status == 'Completed' ? AppTheme.primaryGreen : AppTheme.primaryBlue),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab(StorageService storage) {
    final rawParticipating = widget.tournament['participatingTeamIds'];
    final List<String> participatingIds = rawParticipating is List
        ? rawParticipating.map((e) => e.toString()).toList()
        : [];

    final teams = participatingIds.isNotEmpty
        ? storage.teams.where((t) => participatingIds.contains(t.id)).toList()
        : storage.teams;

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
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.glassCard,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamLogo(teamName: team.name, shortName: team.shortName, logoColorHex: team.logoColorHex, size: 36),
                const SizedBox(height: 8),
                Text(
                  team.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                ),
                Text(
                  '${team.players.length} Players',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
