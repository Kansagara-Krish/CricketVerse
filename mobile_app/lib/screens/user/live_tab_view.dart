import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';

class LiveTabView extends StatelessWidget {
  final Function(String matchId)? onOpenPrediction;
  final Function()? onViewSchedule;

  const LiveTabView({
    super.key,
    this.onOpenPrediction,
    this.onViewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();

    return RefreshIndicator(
      color: AppTheme.accentRed,
      backgroundColor: Colors.white,
      onRefresh: () async => await storage.loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Matches',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: liveMatches.isNotEmpty
                        ? AppTheme.accentRed.withValues(alpha: 0.1)
                        : AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: liveMatches.isNotEmpty
                          ? AppTheme.accentRed.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '${liveMatches.length} IN PLAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: liveMatches.isNotEmpty ? AppTheme.accentRed : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select any live match below to view real-time ball-by-ball scoring or AI predictions.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            if (liveMatches.isEmpty) ...[
              _buildEmptyState(context),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: liveMatches.length,
                itemBuilder: (context, index) {
                  final match = liveMatches[index];
                  return CardEntranceAnimation(
                    index: index,
                    child: _buildLiveMatchCard(context, match, storage),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgSurface),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_cricket_outlined,
              size: 40,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Live Matches',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no live fixtures underway at this moment. You can browse upcoming fixtures or review completed matches in the Matches tab.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (onViewSchedule != null)
            ElevatedButton.icon(
              onPressed: onViewSchedule,
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: Text(
                'View Upcoming Fixtures',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(BuildContext context, CricketMatch match, StorageService storage) {
    final winProb = storage.calculateWinProbability(match);
    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final currentRuns = isTeamABatting ? match.runsA : match.runsB;
    final currentOvers = isTeamABatting ? match.oversA : match.oversB;
    final crr = currentOvers > 0 ? (currentRuns / currentOvers) : 0.0;

    final showScoreA = match.runsA > 0 || match.oversA > 0 || isTeamABatting || match.isFirstInnings || match.status == 'Completed';
    final showScoreB = match.runsB > 0 || match.oversB > 0 || !isTeamABatting || !match.isFirstInnings || match.status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentRed.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${match.matchType.toUpperCase()} • ${match.venue}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: AppTheme.accentRed),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentRed,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Team Scores
          Row(
            children: [
              Expanded(
                child: _buildTeamScoreColumn(
                  match.teamA,
                  match.runsA,
                  match.wicketsA,
                  match.oversA,
                  showScoreA,
                  isBatting: match.battingTeamId == match.teamA.id,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CRR: ${crr.toStringAsFixed(1)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildTeamScoreColumn(
                  match.teamB,
                  match.runsB,
                  match.wicketsB,
                  match.oversB,
                  showScoreB,
                  isBatting: match.battingTeamId == match.teamB.id,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Win Probability Bar Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_graph_rounded, size: 14, color: AppTheme.accentGold),
                    const SizedBox(width: 6),
                    Text(
                      'AI Win Probability:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${match.teamA.shortName} ${winProb.toStringAsFixed(0)}%  •  ${match.teamB.shortName} ${(100 - winProb).toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TWO ACTION BUTTONS: Live Score & AI Prediction
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.userMatchDetails,
                      arguments: match.id,
                    );
                  },
                  icon: const Icon(Icons.sports_cricket, size: 16),
                  label: Text(
                    'Live Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (onOpenPrediction != null) {
                      onOpenPrediction!(match.id);
                    } else {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.prediction,
                        arguments: match,
                      );
                    }
                  },
                  icon: const Icon(Icons.online_prediction, size: 16, color: AppTheme.accentPurple),
                  label: Text(
                    'AI Prediction',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentPurple, width: 1.3),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreColumn(
    Team team,
    int runs,
    int wickets,
    double overs,
    bool showScore, {
    bool isBatting = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            TeamLogo(
              teamName: team.name,
              shortName: team.shortName,
              logoColorHex: team.logoColorHex,
              size: 38,
            ),
            if (isBatting)
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_cricket, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          team.shortName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        if (showScore) ...[
          Text(
            '$runs/$wickets',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            '(${overs.toStringAsFixed(1)} ov)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: AppTheme.textMuted,
            ),
          ),
        ] else ...[
          Text(
            'Yet to bat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
