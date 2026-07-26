import '../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/custom_notification.dart';



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
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _flutterTts = FlutterTts();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StorageService>(context, listen: false).subscribeToMatchLiveUpdates(widget.matchId);
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
      }
    });
  }

  @override
  void dispose() {
    Provider.of<StorageService>(context, listen: false).unsubscribeFromMatchLiveUpdates(widget.matchId);
    _flutterTts.stop();
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
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

  void _playVoiceCommentary(int index, String text) async {
    if (_isPlayingVoice && _playingVoiceIndex == index) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
      }
    } else {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = true;
          _playingVoiceIndex = index;
        });
        CustomNotification.show(
          context,
          '🎙️ Playing AI Voice Commentary sound...',
          type: NotificationType.info,
        );
      }
      await _flutterTts.speak(text);
    }
  }

  void _togglePlayAllCommentary(CricketMatch match) async {
    if (_isPlayingVoice) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
        CustomNotification.show(context, '🔇 AI Voice Sound Paused', type: NotificationType.warning);
      }
    } else {
      if (match.balls.isEmpty) return;
      final fullText = match.balls.reversed.take(3).map((b) => b.commentary).join(". ");
      _playVoiceCommentary(-99, fullText);
    }
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
          // Modern Compact Live Score Header Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                          const SizedBox(width: 5),
                          Text('LIVE', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF047857), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Text(
                      'T20 World Cup • Final',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Batting Team Row (Compact high contrast)
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.userTeamDetails, arguments: battingTeam),
                  child: Row(
                    children: [
                      TeamLogo(
                        teamName: battingTeam.name,
                        shortName: battingTeam.shortName,
                        logoColorHex: battingTeam.logoColorHex,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              battingTeam.shortName,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Batting', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$runs/$wickets',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($overs ov)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CRR ${crr.toStringAsFixed(1)}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Bowling Team Row
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.userTeamDetails, arguments: bowlingTeam),
                  child: Row(
                    children: [
                      TeamLogo(
                        teamName: bowlingTeam.name,
                        shortName: bowlingTeam.shortName,
                        logoColorHex: bowlingTeam.logoColorHex,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bowlingTeam.shortName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                      Text(
                        'Yet to Bat',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // Compact Target statement
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_cricket_rounded, color: AppTheme.accentPurple, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.isFirstInnings
                              ? '1st Innings in progress • ${match.teamA.shortName} setting target'
                              : 'Target ${match.target} • Need ${match.target - match.runsB} runs in ${(120 - (match.oversB * 6).round())} balls',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.accentPurple, fontWeight: FontWeight.bold),
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
            labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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

  // --- Top Grade Modern Live details view ---
  Widget _buildLiveDetailsView(CricketMatch match, StorageService storage, Player striker, Player nonStriker, Player bowler, double winProb) {
    final runsA = striker.runsScored;
    final ballsA = striker.ballsFaced;
    final srA = ballsA > 0 ? ((runsA / ballsA) * 100).toStringAsFixed(1) : '0.0';

    final runsB = nonStriker.runsScored;
    final ballsB = nonStriker.ballsFaced;
    final srB = ballsB > 0 ? ((runsB / ballsB) * 100).toStringAsFixed(1) : '0.0';

    final bowlerEco = bowler.oversBowled > 0 ? (bowler.runsConceded / bowler.oversBowled).toStringAsFixed(1) : '0.0';

    final currentRuns = match.isFirstInnings ? match.runsA : match.runsB;
    final currentOvers = match.isFirstInnings ? match.oversA : match.oversB;
    final crr = currentOvers > 0 ? (currentRuns / currentOvers) : 0.0;

    // Projected Score Calculation
    final projMin = (currentRuns + (crr * (20 - currentOvers))).round();
    final projMax = (projMin + 14);

    // Partnership calculation
    final partRuns = runsA + runsB;
    final partBalls = ballsA + ballsB;
    final partFlexA = partRuns > 0 ? (runsA / partRuns * 100).round() : 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Fixed AI Win Probability & Projected Score Card (No Horizontal Overflow!)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.accentPurple, size: 14),
                        const SizedBox(width: 6),
                        Text('AI WIN PREDICTOR', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                      ],
                    ),
                    Flexible(
                      child: Text(
                        '${match.teamA.shortName} ${winProb.toStringAsFixed(0)}% • ${match.teamB.shortName} ${(100 - winProb).toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: winProb.round().clamp(1, 99),
                          child: Container(color: AppTheme.primaryBlue),
                        ),
                        Expanded(
                          flex: (100 - winProb).round().clamp(1, 99),
                          child: Container(color: AppTheme.accentRed),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Projected Score Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: AppTheme.primaryBlue, size: 14),
                          const SizedBox(width: 6),
                          Text('PROJECTED SCORE', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                        ],
                      ),
                      Text(
                        '$projMin - $projMax @ ${(crr > 0 ? crr : 8.5).toStringAsFixed(1)} CRR',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Live Partnership Card (Useful Top-Grade Feature)
          Container(
            padding: const EdgeInsets.all(12),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.handshake_outlined, color: AppTheme.primaryBlue, size: 14),
                        const SizedBox(width: 6),
                        Text('CURRENT PARTNERSHIP', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                      ],
                    ),
                    Text(
                      '$partRuns runs ($partBalls b)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: partFlexA.clamp(1, 99),
                          child: Container(color: AppTheme.primaryBlue),
                        ),
                        Expanded(
                          flex: (100 - partFlexA).clamp(1, 99),
                          child: Container(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${striker.name.split(' ').first} $runsA ($ballsA)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    Text('${nonStriker.name.split(' ').first} $runsB ($ballsB)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Integrated High-Density Live Scorecard (Batters + Bowler in 1 unified Card)
          Container(
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
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text('BATTER', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                    ],
                  ),
                ),

                // Striker Row
                _buildCompactBatterRow(context, striker, isStriker: true, sr: srA),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Non-Striker Row
                _buildCompactBatterRow(context, nonStriker, isStriker: false, sr: srB),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Bowler Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text('BOWLER', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                      Expanded(flex: 2, child: Text('ECO', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted))),
                    ],
                  ),
                ),

                // Bowler Row
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.userPlayerDetails, arguments: bowler),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            bowler.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(flex: 1, child: Text(bowler.oversBowled.toStringAsFixed(1), textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary))),
                        Expanded(flex: 1, child: Text('0', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary))),
                        Expanded(flex: 1, child: Text('${bowler.runsConceded}', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary))),
                        Expanded(flex: 1, child: Text('${bowler.wicketsTaken}', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentRed))),
                        Expanded(flex: 2, child: Text(bowlerEco, textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. RECENT Over Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: Row(
              children: [
                Text('RECENT: ', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: match.balls.length > 8 ? 8 : match.balls.length,
                      itemBuilder: (context, index) {
                        final ball = match.balls[match.balls.length - 1 - index];
                        Color bg = const Color(0xFFF1F5F9);
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
                          margin: const EdgeInsets.only(right: 6),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bg,
                          ),
                          child: Center(
                            child: Text(
                              display,
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 5. FlChart Over-by-Over Bar Chart Trend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RUN RATE TREND (OVERS)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    Text('Over 1 - 10', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 18,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Text(
                              'O${val.toInt() + 1}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: [
                        _makeBarGroup(0, 6),
                        _makeBarGroup(1, 12),
                        _makeBarGroup(2, 8),
                        _makeBarGroup(3, 14, isWicket: true),
                        _makeBarGroup(4, 16),
                        _makeBarGroup(5, 7),
                        _makeBarGroup(6, 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, {bool isWicket = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isWicket ? AppTheme.accentRed : AppTheme.primaryBlue,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildCompactBatterRow(BuildContext context, Player player, {required bool isStriker, required String sr}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.userPlayerDetails, arguments: player),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  if (isStriker)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      '${player.name}${isStriker ? "*" : ""}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isStriker ? FontWeight.bold : FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 1, child: Text('${player.runsScored}', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
            Expanded(flex: 1, child: Text('${player.ballsFaced}', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary))),
            Expanded(flex: 1, child: Text('4', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary))),
            Expanded(flex: 1, child: Text('2', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary))),
            Expanded(flex: 2, child: Text(sr, textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
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
      itemCount: match.balls.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Top AI Audio Commentary Option Control Card
          final isGlobalPlaying = _isPlayingVoice && _playingVoiceIndex == -99;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C81), AppTheme.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingVoice ? Icons.graphic_eq : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Sound Commentary',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPlayingVoice ? 'Broadcasting live voice sound...' : 'Listen to audio match commentary',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _togglePlayAllCommentary(match),
                  icon: Icon(_isPlayingVoice ? Icons.pause : Icons.play_arrow_rounded, size: 18),
                  label: Text(isGlobalPlaying ? 'Stop' : (_isPlayingVoice ? 'Pause' : 'Play Sound')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          );
        }

        // Reverse order so latest is on top
        final ballIdx = match.balls.length - index;
        final ball = match.balls[ballIdx];
        final isVoicePlaying = _isPlayingVoice && _playingVoiceIndex == ballIdx;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isVoicePlaying ? AppTheme.primaryBlue.withValues(alpha: 0.4) : AppTheme.bgSurface),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Bowler: ${ball.bowlerName} ➔ Batsman: ${ball.batsmanName}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (isVoicePlaying)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.graphic_eq, color: AppTheme.primaryBlue, size: 16),
                        ),
                      InkWell(
                        onTap: () => _playVoiceCommentary(ballIdx, ball.commentary),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVoicePlaying ? AppTheme.primaryBlue.withValues(alpha: 0.12) : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVoicePlaying ? Icons.volume_up : Icons.volume_up_outlined,
                                color: isVoicePlaying ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isVoicePlaying ? 'Playing' : 'Listen',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isVoicePlaying ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
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


  // --- 3. Analytics (Dual-Team Live Score Chart, Score Projection & Win Prediction) ---
  Widget _buildAnalyticsView(CricketMatch match) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final winProb = storage.calculateWinProbability(match);

    final currentScore = match.isFirstInnings ? match.runsA : match.runsB;
    final currentOvers = match.isFirstInnings ? match.oversA : match.oversB;

    // Projected scores at different run rates
    final proj6 = (currentScore + (20.0 - currentOvers) * 6.0).round();
    final proj8 = (currentScore + (20.0 - currentOvers) * 8.0).round();
    final proj10 = (currentScore + (20.0 - currentOvers) * 10.0).round();


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dual Team Live Score Comparison Chart
          Text(
            'LIVE SCORE COMPARISON (RUNS OVER OVERS)',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
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
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(match.teamA.shortName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppTheme.accentRed, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(match.teamB.shortName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(color: AppTheme.bgSurface, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, _) => Text(
                              '${val.toInt()}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${val.toInt()}ov',
                                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 20,
                      minY: 0,
                      maxY: 200,
                      lineBarsData: [
                        // Team A Line
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 0),
                            FlSpot(4, 38),
                            FlSpot(8, 72),
                            FlSpot(12, 108),
                            FlSpot(16, 145),
                            FlSpot(20, 185),
                          ],
                          isCurved: true,
                          color: AppTheme.primaryBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          ),
                        ),
                        // Team B Line (Live or past)
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 0),
                            const FlSpot(4, 32),
                            const FlSpot(8, 64),
                            const FlSpot(12, 98),
                            FlSpot(currentOvers, currentScore.toDouble()),
                          ],
                          isCurved: true,
                          color: AppTheme.accentRed,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accentRed.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Live Win Prediction & Score Projection Card
          Text(
            'WIN PREDICTION & SCORE PROJECTION',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
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
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Win Prediction Gauge',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI PREDICT',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.accentPurple, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Win percentage indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${match.teamA.name}: ${winProb.toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    Text(
                      '${match.teamB.name}: ${(100 - winProb).toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentRed),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        Expanded(flex: winProb.round(), child: Container(color: AppTheme.primaryBlue)),
                        Expanded(flex: (100 - winProb).round(), child: Container(color: AppTheme.accentRed)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                Text(
                  'Projected Score Bounds (End of 20 Overs)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildProjectionBox('At 6.0 RRR', '$proj6', AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    _buildProjectionBox('At 8.0 RRR', '$proj8', AppTheme.accentPurple),
                    const SizedBox(width: 8),
                    _buildProjectionBox('At 10.0 RRR', '$proj10', AppTheme.primaryGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Manhattan Chart (Runs Per Over)
          Text(
            'MANHATTAN CHART (RUNS PER OVER)',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: CustomPaint(
              painter: ManhattanPainter(match.balls),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProjectionBox(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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

// Custom painter for Manhattan bar chart
class ManhattanPainter extends CustomPainter {
  final List<BallRecord> balls;
  ManhattanPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
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
    if (ballCount > 0) {
      runsPerOver.add(currentOverSum);
    }

    if (runsPerOver.isEmpty) {
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

