import '../../core/theme/app_theme.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/team_logo.dart';

class MatchDetailsScreen extends StatefulWidget {
  final String matchId;
  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {'sender': 'ai', 'text': 'Hello! I am your AI Match Assistant. Ask me anything about the live match!'}
  ];
  bool _isPlayingVoice = false;
  int _playingVoiceIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _sendChatMessage(String userQuery, CricketMatch match, StorageService storage) {
    if (userQuery.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({'sender': 'user', 'text': userQuery});
    });
    _chatController.clear();

    // Determine mock reply
    String reply = "I'm analyzing the match data...";
    final query = userQuery.toLowerCase();
    
    final runs = match.isFirstInnings ? match.runsA : match.runsB;
    final wickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    final overs = match.isFirstInnings ? match.oversA : match.oversB;
    final winProb = storage.calculateWinProbability(match);

    if (query.contains('who is winning') || query.contains('win probability')) {
      reply = "According to our CricketVerse AI engine, Team A (${match.teamA.shortName}) has a ${winProb.toStringAsFixed(0)}% probability of winning the match, while ${match.teamB.shortName} stands at ${(100 - winProb).toStringAsFixed(0)}%.";
    } else if (query.contains('score') || query.contains('current score')) {
      reply = "The current score is ${match.battingTeamId == match.teamA.id ? match.teamA.shortName : match.teamB.shortName} $runs/$wickets in $overs overs.";
    } else if (query.contains('last ball') || query.contains('last over')) {
      if (match.balls.isNotEmpty) {
        reply = "The last event was: '${match.balls.last.commentary}' by bowler ${match.balls.last.bowlerName} to batsman ${match.balls.last.batsmanName}.";
      } else {
        reply = "No balls have been bowled yet in this match.";
      }
    } else if (query.contains('batter') || query.contains('batsman') || query.contains('kohli')) {
      reply = "Virat Kohli is currently batting on 78* runs off 45 balls, displaying incredible control under pressure.";
    } else if (query.contains('summary') || query.contains('highlights')) {
      reply = "Match Highlights: IND had a strong start in the powerplay. V. Kohli anchored the innings scoring 78, while Suryakumar Yadav accelerated. Current run rate is at ${(runs / (overs > 0 ? overs : 1)).toStringAsFixed(1)}.";
    } else {
      reply = "That's an interesting question! AI engine notes: The batsman's control rating is 92% and the pitch momentum favors batsman in the current block.";
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _chatMessages.add({'sender': 'ai', 'text': reply});
        });
      }
    });
  }

  void _playVoiceCommentary(int index, String text) {
    setState(() {
      _isPlayingVoice = true;
      _playingVoiceIndex = index;
    });

    // Simulate speech audio waves animation
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final match = storage.matches.firstWhere((m) => m.id == widget.matchId, orElse: () => storage.matches[0]);

    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    final striker = battingTeam.players.firstWhere((p) => p.id == match.currentStrikerId, orElse: () => battingTeam.players[0]);
    final nonStriker = battingTeam.players.firstWhere((p) => p.id == match.currentNonStrikerId, orElse: () => battingTeam.players[1]);
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == match.currentBowlerId, orElse: () => bowlingTeam.players[bowlingTeam.players.length - 1]);

    final runs = match.isFirstInnings ? match.runsA : match.runsB;
    final wickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    final overs = match.isFirstInnings ? match.oversA : match.oversB;
    final crr = overs > 0 ? (runs / overs) : 0.0;
    
    final winProb = storage.calculateWinProbability(match);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'),
              radius: 16,
            ),
            const SizedBox(width: 12),
            Text(
              'CricketVerse AI',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.matchSummaryDownload,
                arguments: {
                  'title': '${match.teamA.shortName} vs ${match.teamB.shortName}',
                  'teamAName': match.teamA.name,
                  'teamAShort': match.teamA.shortName,
                  'teamBName': match.teamB.name,
                  'teamBShort': match.teamB.shortName,
                  'scoreA': '${match.runsA}/${match.wicketsA}',
                  'oversA': '${match.oversA} Overs',
                  'scoreB': '${match.runsB}/${match.wicketsB}',
                  'oversB': '${match.oversB} Overs',
                  'result': match.status == 'Completed'
                      ? '${match.runsA > match.runsB ? match.teamA.name : match.teamB.name} won the match'
                      : 'Match is ${match.status.toLowerCase()}',
                  'teamAPlayers': match.teamA.players.map((p) => p.name).toList(),
                  'teamBPlayers': match.teamB.players.map((p) => p.name).toList(),
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Score Header matches Screenshot 2026-07-09 152247.png
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (LIVE tag and Tournament Type)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text('LIVE', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Text(
                      'T20 World Cup - Final',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Batting Team Row (Premium layout)
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.userTeamDetails,
                      arguments: battingTeam,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        TeamLogo(
                          teamName: battingTeam.name,
                          shortName: battingTeam.shortName,
                          logoColorHex: battingTeam.logoColorHex,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                battingTeam.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Batting Now',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$runs/$wickets',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($overs ov)',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CRR: ${crr.toStringAsFixed(1)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bowling Team Row
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.userTeamDetails,
                      arguments: bowlingTeam,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      children: [
                        TeamLogo(
                          teamName: bowlingTeam.name,
                          shortName: bowlingTeam.shortName,
                          logoColorHex: bowlingTeam.logoColorHex,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bowlingTeam.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Yet to Bat',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Target statement
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_cricket_rounded, color: AppTheme.accentPurple, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.isFirstInnings
                              ? 'First Innings in progress. Team A setting target.'
                              : 'Target ${match.target} • Need ${match.target - match.runsB} runs in ${(120 - (match.oversB * 6).round())} balls.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.accentPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar (Styled for Light Theme)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Live Details'),
              Tab(text: 'AI Commentary'),
              Tab(text: 'Analytics'),
              Tab(text: 'AI Chat'),
            ],
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Live Details
                _buildLiveDetailsView(match, storage, striker, nonStriker, bowler, winProb),
                // 2. AI Commentary Feed
                _buildCommentaryFeed(match),
                // 3. Analytics (Wagon Wheel & Manhattan charts!)
                _buildAnalyticsView(match),
                // 4. AI Chat Assistant
                _buildChatView(match, storage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Live details tab matching Screenshot 2026-07-09 152247.png ---
  Widget _buildLiveDetailsView(CricketMatch match, StorageService storage, Player striker, Player nonStriker, Player bowler, double winProb) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Win probability card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.accentPurple, size: 18),
                    const SizedBox(width: 8),
                    Text('AI Win Probability', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                // Team names and percentage above the bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${match.teamA.name} (${winProb.toStringAsFixed(0)}%)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${(100 - winProb).toStringAsFixed(0)}%) ${match.teamB.name}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Smooth rounded track bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(
                          flex: winProb.round(),
                          child: Container(
                            color: AppTheme.primaryBlue, 
                          ),
                        ),
                        Expanded(
                          flex: (100 - winProb).round(),
                          child: Container(
                            color: AppTheme.accentRed, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // RECENT timeline
          Text('RECENT', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: match.balls.length > 6 ? 6 : match.balls.length,
              itemBuilder: (context, index) {
                final ball = match.balls[match.balls.length - 1 - index];
                
                Color bg = AppTheme.bgSurface;
                Color textCol = AppTheme.textPrimary;
                String display = ball.run.toString();

                if (ball.isWicket) {
                  bg = AppTheme.accentRed;
                  textCol = Colors.white;
                  display = 'W';
                } else if (ball.run == 6) {
                  bg = AppTheme.accentPurple;
                  textCol = Colors.white;
                } else if (ball.run == 4) {
                  bg = const Color(0xFFFEF08A);
                  textCol = const Color(0xFF854D0E);
                } else if (ball.extraType == 'Wide') {
                  display = 'WD';
                } else if (ball.extraType == 'No Ball') {
                  display = 'NB';
                }

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                  ),
                  child: Center(child: Text(display, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: textCol))),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // BATTERS Section
          Text('BATTERS', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                )
              ]
            ),
            child: Column(
              children: [
                _buildBatterRow(context, striker, isStriker: true),
                const Divider(color: AppTheme.bgSurface),
                _buildBatterRow(context, nonStriker),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // BOWLER Section
          Text('BOWLER', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                )
              ]
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.userPlayerDetails,
                  arguments: bowler,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bowler.name, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text('${bowler.oversBowled.toStringAsFixed(1)} ov • ${bowler.wicketsTaken}/${bowler.runsConceded}', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // MATCH PROGRESSION Section matching Screenshot 2026-07-09 152247.png
          Text('MATCH PROGRESSION', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProgressionBar(10, 30),
                _buildProgressionBar(20, 50),
                _buildProgressionBar(15, 40),
                _buildProgressionBar(30, 80),
                _buildProgressionBar(45, 100),
                _buildProgressionBar(25, 60),
                _buildProgressionBar(40, 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionBar(double height, double maxVal) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBatterRow(BuildContext context, Player player, {bool isStriker = false}) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.userPlayerDetails,
          arguments: player,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isStriker) 
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  '${player.name}${isStriker ? "*" : ""}', 
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary, 
                    fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Text('${player.runsScored} (${player.ballsFaced})', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- 2. AI Commentary Feed ---
  Widget _buildCommentaryFeed(CricketMatch match) {
    if (match.balls.isEmpty) {
      return const Center(child: Text('Waiting for match scoring events to start...', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: match.balls.length,
      itemBuilder: (context, index) {
        // Reverse order so latest is on top
        final ball = match.balls[match.balls.length - 1 - index];
        final isVoicePlaying = _isPlayingVoice && _playingVoiceIndex == index;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.textPrimary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bowler: ${ball.bowlerName} ➔ Batsman: ${ball.batsmanName}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (isVoicePlaying)
                        const Icon(Icons.graphic_eq, color: AppTheme.primaryBlue, size: 16),
                      IconButton(
                        icon: Icon(
                          isVoicePlaying ? Icons.volume_up : Icons.volume_mute_outlined,
                          color: isVoicePlaying ? AppTheme.primaryBlue : Colors.white70,
                          size: 18,
                        ),
                        onPressed: () => _playVoiceCommentary(index, ball.commentary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ball.commentary,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. Analytics custom-painted charts ---
  Widget _buildAnalyticsView(CricketMatch match) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wagon Wheel (AI Spatial Analysis)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          
          // Wagon Wheel canvas
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.textPrimary.withValues(alpha: 0.02),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 2),
              ),
              child: CustomPaint(
                painter: WagonWheelPainter(match.balls),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text('Manhattan Chart (Runs Per Over)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          
          // Manhattan custom chart
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomPaint(
              painter: ManhattanPainter(match.balls),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- 4. AI Chat Assistant ---
  Widget _buildChatView(CricketMatch match, StorageService storage) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isAi = msg['sender'] == 'ai';
              return Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAi ? Colors.black.withValues(alpha: 0.05) : const Color(0xFF0F4C81),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isAi ? const Radius.circular(0) : const Radius.circular(16),
                      bottomRight: isAi ? const Radius.circular(16) : const Radius.circular(0),
                    ),
                    border: Border.all(color: isAi ? Colors.white10 : Colors.transparent),
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(
                    msg['text'] ?? '',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Input bar
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ask: Who is winning? What happened in last over?',
                    hintStyle: TextStyle(color: Color(0x4D0F172A), fontSize: 12),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) => _sendChatMessage(val, match, storage),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primaryBlue),
                onPressed: () => _sendChatMessage(_chatController.text, match, storage),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for Wagon Wheel
class WagonWheelPainter extends CustomPainter {
  final List<BallRecord> balls;
  WagonWheelPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fieldPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw boundary line
    canvas.drawCircle(center, size.width / 2 - 10, fieldPaint);
    
    // Draw cricket pitch mock
    final pitchPaint = Paint()..color = Colors.yellow.withValues(alpha: 0.08);
    canvas.drawRect(Rect.fromCenter(center: center, width: 12, height: 40), pitchPaint);

    final random = Random(42); // Seed to keep shots constant
    
    // Draw shots lines from pitch center
    for (var ball in balls) {
      if (ball.run > 0 && ball.extraType == 'None') {
        double angle = random.nextDouble() * 2 * pi;
        double shotLength = (size.width / 2 - 14) * (ball.run == 6 ? 1.0 : (ball.run == 4 ? 0.8 : 0.5));
        
        final shotPaint = Paint()
          ..color = ball.run == 6 ? const Color(0xFF60A5FA) : (ball.run == 4 ? const Color(0xFFFBBF24) : Colors.black38)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
          
        final dest = Offset(
          center.dx + shotLength * cos(angle),
          center.dy + shotLength * sin(angle),
        );
        canvas.drawLine(center, dest, shotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for Manhattan bar chart
class ManhattanPainter extends CustomPainter {
  final List<BallRecord> balls;
  ManhattanPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    // Generate over totals
    // Group balls by 6-ball blocks (overs)
    final List<int> runsPerOver = [];
    int currentOverSum = 0;
    int ballCount = 0;

    for (var ball in balls) {
      if (ball.extraType != 'Wide' && ball.extraType != 'No Ball') {
        currentOverSum += ball.run + ball.extraRun;
        ballCount++;
        if (ballCount == 6) {
          runsPerOver.add(currentOverSum);
          currentOverSum = 0;
          ballCount = 0;
        }
      } else {
        currentOverSum += ball.run + ball.extraRun;
      }
    }
    // Add current incomplete over if any
    if (ballCount > 0) {
      runsPerOver.add(currentOverSum);
    }

    if (runsPerOver.isEmpty) {
      // Mock data to display something clean
      runsPerOver.addAll([8, 12, 4, 15, 6, 22, 10, 14]);
    }

    final int maxVal = runsPerOver.fold(10, (max, v) => v > max ? v : max);

    final double widthPerBar = size.width / (runsPerOver.length * 1.5);
    final double spacing = widthPerBar / 2;

    for (int i = 0; i < runsPerOver.length; i++) {
      final runs = runsPerOver[i];
      final double barHeight = (runs / maxVal) * size.height;
      
      final barPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF0F4C81)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(i * (widthPerBar + spacing), size.height - barHeight, widthPerBar, barHeight))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (widthPerBar + spacing), size.height - barHeight, widthPerBar, barHeight),
          const Radius.circular(4),
        ),
        barPaint,
      );

      // Draw text values above bars
      final textPainter = TextPainter(
        text: TextSpan(text: '$runs', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(i * (widthPerBar + spacing) + (widthPerBar / 2) - (textPainter.width / 2), size.height - barHeight - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
