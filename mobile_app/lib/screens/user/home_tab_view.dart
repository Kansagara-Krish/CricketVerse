import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  String _selectedFilter = 'Live'; // 'Live', 'Upcoming', 'Completed'

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final matchesList = storage.matches.where((m) => m.status == _selectedFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Header
          _buildHeaderSection(storage),
          const SizedBox(height: 18),

          // 3. Selection Filters Row
          _buildFiltersRow(),
          const SizedBox(height: 18),

          // 4. Live Match List Section
          _buildMatchesListSection(matchesList, storage),
          const SizedBox(height: 24),

          // 5. Trending Players Section
          _buildTrendingPlayersSection(storage),
          const SizedBox(height: 24),

          // 6. Latest Analytics Updates Card
          _buildLatestUpdatesSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(StorageService storage) {
    final displayName = storage.currentUserName ?? 'Fan';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              radius: 20,
              child: const Icon(Icons.person, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Hello, $displayName',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: ['Live', 'Upcoming', 'Completed'].map((filter) {
        final isSelected = _selectedFilter == filter;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              filter,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedFilter = filter),
            selectedColor: AppTheme.primaryBlue,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.bgSurface),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchesListSection(List<CricketMatch> matchesList, StorageService storage) {
    if (matchesList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.bgSurface),
        ),
        child: Center(
          child: Text(
            'No $_selectedFilter matches found.',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matchesList.length,
      itemBuilder: (context, index) {
        final match = matchesList[index];
        return CardEntranceAnimation(
          index: index,
          child: _buildMatchCard(match, storage),
        );
      },
    );
  }

  Widget _buildMatchCard(CricketMatch match, StorageService storage) {
    final winProb = storage.calculateWinProbability(match);
    final crr = match.oversA > 0 ? (match.runsA / match.oversA) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.bgSurface),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.userMatchDetails, arguments: match.id),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CRICKETVERSE CUP 2026',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: match.status == 'Live' ? const Color(0xFFFEE2E2) : AppTheme.bgSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 2.5,
                        backgroundColor: match.status == 'Live' ? AppTheme.accentRed : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: match.status == 'Live' ? AppTheme.accentRed : AppTheme.textSecondary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTeamScoreColumn(match.teamA, match.runsA, match.wicketsA, match.oversA, match.status != 'Upcoming'),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('VS', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w800)),
                    if (match.status == 'Live') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CRR ${crr.toStringAsFixed(1)}',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryGreen, fontSize: 8, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTeamScoreColumn(match.teamB, match.runsB, match.wicketsB, match.oversB, match.status == 'Completed', isRight: true),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppTheme.bgSurface, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.status == 'Upcoming' 
                      ? 'Fixture starts at ${match.time}' 
                      : '${match.teamA.players.isNotEmpty ? match.teamA.players[0].name.split(" ").first : "Player"} 42*(28)',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.primaryGreen, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      'AI Win Prob: ${winProb.toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScoreColumn(Team team, int runs, int wickets, double overs, bool showScore, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isRight) ...[
              TeamLogo(teamName: team.name, shortName: team.shortName, logoColorHex: team.logoColorHex, size: 26),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                team.shortName,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRight) ...[
              const SizedBox(width: 6),
              TeamLogo(teamName: team.name, shortName: team.shortName, logoColorHex: team.logoColorHex, size: 26),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (showScore) ...[
          Text('$runs/$wickets', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
          Text('($overs ov)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500)),
        ] else
          Text('Yet to play', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrendingPlayersSection(StorageService storage) {
    final allPlayers = storage.teams.expand((t) => t.players).toList();
    allPlayers.sort((a, b) => b.runsScored.compareTo(a.runsScored));
    final trendingPlayers = allPlayers.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trending Players',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text('View all', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryBlue, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        trendingPlayers.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.bgSurface),
                ),
                child: Center(
                  child: Text(
                    'No player statistics available yet.',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            : SizedBox(
                height: 125,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: trendingPlayers.length,
                  itemBuilder: (context, index) {
                    final p = trendingPlayers[index];
                    String teamShort = 'IND';
                    for (final t in storage.teams) {
                      if (t.players.any((pl) => pl.id == p.id)) {
                        teamShort = t.shortName;
                        break;
                      }
                    }
                    return CardEntranceAnimation(
                      index: index,
                      child: _buildPlayerTrendCard(
                        p.name,
                        '${p.role} • $teamShort',
                        'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?q=80&w=120&auto=format&fit=crop',
                        p.role == 'Batter' ? Icons.sports_cricket : Icons.circle,
                        AppTheme.primaryBlue,
                        p.runsScored,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildPlayerTrendCard(String name, String role, String imgUrl, IconData badgeIcon, Color badgeColor, int runs) {
    final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(right: 14),
      width: 95,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgSurface),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [badgeColor.withOpacity(0.12), badgeColor.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(color: badgeColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, size: 8, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$runs Runs',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLatestUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Updates',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.bgSurface),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1540747737956-378724044282?q=80&w=150&auto=format&fit=crop',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: AppTheme.bgSurface,
                    child: const Icon(Icons.sports_cricket, color: AppTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANALYSIS',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How AI predicted the live win probability swing during final over.',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
