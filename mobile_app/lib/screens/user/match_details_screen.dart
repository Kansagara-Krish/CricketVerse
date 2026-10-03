import '../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/storage_service.dart';
import '../../services/elevenlabs_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/network_status_bar.dart';
import '../../services/network_connectivity_service.dart';



class MatchDetailsScreen extends StatefulWidget {
  final String matchId;
  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _livePulseController;
  late Animation<double> _livePulseAnimation;
  bool _isPlayingVoice = false;
  int _playingVoiceIndex = -1;
  int _selectedInnings = 0;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _livePulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _livePulseController, curve: Curves.easeInOut),
    );
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
    _livePulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _playVoiceCommentary(int index, String text) async {
    if (_isPlayingVoice && _playingVoiceIndex == index) {
      await ElevenLabsService().stopAudio();
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
      }
    } else {
      await ElevenLabsService().stopAudio();
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = true;
          _playingVoiceIndex = index;
        });
        final voiceName = ElevenLabsService().settings.voiceName;
        CustomNotification.show(
          context,
          '🎙️ Playing AI Voice Commentary ($voiceName)...',
          type: NotificationType.info,
        );
      }
      await ElevenLabsService().speakCommentary(
        text,
        onComplete: () {
          if (mounted) {
            setState(() {
              _isPlayingVoice = false;
              _playingVoiceIndex = -1;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isPlayingVoice = false;
              _playingVoiceIndex = -1;
            });
          }
        },
      );
    }
  }

  void _togglePlayAllCommentary(CricketMatch match) async {
    if (_isPlayingVoice) {
      await ElevenLabsService().stopAudio();
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

    final striker = battingTeam.players.firstWhere(
      (p) => p.id == match.currentStrikerId,
      orElse: () => battingTeam.players.isNotEmpty
          ? battingTeam.players[0]
          : Player(id: '', name: 'Batsman', role: 'Batter', nationality: ''),
    );
    final nonStriker = battingTeam.players.firstWhere(
      (p) => p.id == match.currentNonStrikerId,
      orElse: () => battingTeam.players.length > 1
          ? battingTeam.players[1]
          : (battingTeam.players.isNotEmpty
              ? battingTeam.players[0]
              : Player(id: '', name: 'Batsman', role: 'Batter', nationality: '')),
    );
    final bowler = bowlingTeam.players.firstWhere(
      (p) => p.id == match.currentBowlerId,
      orElse: () => bowlingTeam.players.isNotEmpty
          ? bowlingTeam.players.last
          : Player(id: '', name: 'Bowler', role: 'Bowler', nationality: ''),
    );

    final runs = match.isFirstInnings ? match.runsA : match.runsB;
    final wickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    final overs = match.isFirstInnings ? match.oversA : match.oversB;
    final crr = overs > 0 ? (runs / overs) : 0.0;
    
    final winProb = storage.calculateWinProbability(match);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F9F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Color(0xFF64748B), size: 22),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CricketVerse AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Play • Predict • Stay Ahead',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A), size: 22),
            onPressed: () {},
          ),
          InkWell(
            onTap: () {
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
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF059669), size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          NetworkStatusBar(
            pendingCount: storage.pendingScoreCount,
            onRetry: () => NetworkConnectivityService().checkConnectivity(),
          ),
          // Hero Live Match Banner matching Reference Image
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: const LiveCardWatermarkPainter(),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Pulsing LIVE badge & Tournament Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FadeTransition(
                                  opacity: _livePulseAnimation,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF047857),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'T20 World Cup • Final',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Team A Row
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF028A6B),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF028A6B).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '12',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            battingTeam.name.isNotEmpty ? battingTeam.name : 'Team A',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Batting',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFF047857),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$runs/$wickets',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF028A6B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($overs ov)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CRR ${crr.toStringAsFixed(1)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Team B Row
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '18',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            bowlingTeam.name.isNotEmpty ? bowlingTeam.name : 'Team B',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Yet to Bat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Orange/Peach Target Summary Bar matching reference image
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.architecture_rounded, color: Color(0xFFC2410C), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                match.isFirstInnings
                                    ? '1st Innings in progress • 12 setting target'
                                    : 'Target ${match.target} • Need ${match.target - match.runsB} runs in ${(120 - (match.oversB * 6).round())} balls',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFFC2410C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2410C), size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab Bar matching Reference Image
          Container(
            color: const Color(0xFFF3F9F6),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF10B981),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF64748B),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Live Details'),
                Tab(text: 'AI Commentary'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Live Details (Exact layout matching reference screenshot)
                _buildLiveDetailsView(match, storage, striker, nonStriker, bowler, winProb),
                // 2. AI Commentary Feed
                _buildCommentaryFeed(match),
                // 3. Analytics
                _buildAnalyticsView(match),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Live Details View with Full Batting & Bowling Scorecard ---
  Widget _buildLiveDetailsView(CricketMatch match, StorageService storage, Player striker, Player nonStriker, Player bowler, double winProb) {
    // Current Active Live stats
    final runsStriker = striker.runsScored;
    final ballsStriker = striker.ballsFaced;
    final srStriker = ballsStriker > 0 ? ((runsStriker / ballsStriker) * 100).toStringAsFixed(1) : '0.0';

    final runsNonStriker = nonStriker.runsScored;
    final ballsNonStriker = nonStriker.ballsFaced;
    final srNonStriker = ballsNonStriker > 0 ? ((runsNonStriker / ballsNonStriker) * 100).toStringAsFixed(1) : '0.0';

    final bowlerEco = bowler.oversBowled > 0 ? (bowler.runsConceded / bowler.oversBowled).toStringAsFixed(1) : '0.0';

    final currentRuns = match.isFirstInnings ? match.runsA : match.runsB;
    final currentOvers = match.isFirstInnings ? match.oversA : match.oversB;
    final crr = currentOvers > 0 ? (currentRuns / currentOvers) : 0.0;

    final projMin = (currentRuns + (crr * (20 - currentOvers))).round();
    final projMax = (projMin + 14);

    final teamAWin = winProb.round().clamp(1, 99);
    final teamBWin = 100 - teamAWin;

    final partRuns = runsStriker + runsNonStriker;
    final partBalls = ballsStriker + ballsNonStriker;

    // Selected Innings Data for full scorecard:
    // Innings 0 = Team A Batting, Team B Bowling
    // Innings 1 = Team B Batting, Team A Bowling
    final isInn1 = _selectedInnings == 0;
    final innBatTeam = isInn1 ? match.teamA : match.teamB;
    final innBowlTeam = isInn1 ? match.teamB : match.teamA;
    final innBatPlayers = isInn1
        ? (match.playingXI_A.isNotEmpty ? match.playingXI_A : match.teamA.players)
        : (match.playingXI_B.isNotEmpty ? match.playingXI_B : match.teamB.players);
    final innBowlPlayers = isInn1
        ? (match.playingXI_B.isNotEmpty ? match.playingXI_B : match.teamB.players)
        : (match.playingXI_A.isNotEmpty ? match.playingXI_A : match.teamA.players);

    final innRuns = isInn1 ? match.runsA : match.runsB;
    final innWickets = isInn1 ? match.wicketsA : match.wicketsB;
    final innOvers = isInn1 ? match.oversA : match.oversB;
    final innCrr = innOvers > 0 ? (innRuns / innOvers).toStringAsFixed(2) : '0.00';

    // Calculate Extras breakdown from match.balls
    int wides = 0;
    int noBalls = 0;
    int legByes = 0;
    int byes = 0;
    for (var b in match.balls) {
      if (b.extraType == 'Wide') wides += (b.extraRun > 0 ? b.extraRun : 1);
      if (b.extraType == 'No Ball') noBalls += (b.extraRun > 0 ? b.extraRun : 1);
      if (b.extraType == 'Leg Bye') legByes += (b.extraRun > 0 ? b.extraRun : 1);
      if (b.extraType == 'Bye') byes += (b.extraRun > 0 ? b.extraRun : 1);
    }
    final totalExtras = wides + noBalls + legByes + byes;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. AI WIN PREDICTOR Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF028A6B), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'AI WIN PREDICTOR',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${match.teamA.shortName} $teamAWin% | ${match.teamB.shortName} $teamBWin%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: teamAWin,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Expanded(
                          flex: teamBWin,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Projected Score Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Color(0xFF059669), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'PROJECTED SCORE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$projMin – $projMax @ ${(crr > 0 ? crr : 8.5).toStringAsFixed(1)} CRR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF028A6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. CURRENT ACTIVE BATTERS & BOWLER LIVE MINI-CARD
          if (match.status == 'Live') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                          const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            'ON STRIKE & LIVE ACTION',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF047857),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Partnership: $partRuns ($partBalls b)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.sports_cricket, size: 14, color: Color(0xFF028A6B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${striker.name} *',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF0F172A)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$runsStriker ($ballsStriker) • SR $srStriker',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF028A6B), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.directions_run, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      nonStriker.name,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF0F172A)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$runsNonStriker ($ballsNonStriker) • SR $srNonStriker',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Color(0xFF2563EB), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              'Bowler: ${bowler.name}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                        Text(
                          '${bowler.oversBowled.toStringAsFixed(1)} ov • ${bowler.wicketsTaken}/${bowler.runsConceded} (Eco: $bowlerEco)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 3. INNINGS SELECTOR PILL TABS
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedInnings = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isInn1 ? const Color(0xFF028A6B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isInn1 ? const Color(0xFF028A6B) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        if (isInn1)
                          BoxShadow(
                            color: const Color(0xFF028A6B).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${match.teamA.shortName} (${match.runsA}/${match.wicketsA})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isInn1 ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedInnings = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isInn1 ? const Color(0xFF028A6B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: !isInn1 ? const Color(0xFF028A6B) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        if (!isInn1)
                          BoxShadow(
                            color: const Color(0xFF028A6B).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${match.teamB.shortName} (${match.runsB}/${match.wicketsB})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: !isInn1 ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. BATTING SCORECARD CARD (Full List of Players with Score & Status)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${innBatTeam.name.toUpperCase()} BATTING',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                    ],
                  ),
                ),

                // Full Batters List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: innBatPlayers.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, i) {
                    final p = innBatPlayers[i];
                    final isCurrentStriker = p.id == match.currentStrikerId && match.status == 'Live';
                    final isCurrentNonStriker = p.id == match.currentNonStrikerId && match.status == 'Live';

                    // Compute runs and boundaries from match balls or player object
                    final pBalls = match.balls.where((b) => b.strikerId == p.id).toList();
                    final fours = pBalls.where((b) => b.run == 4 && (b.extraType == 'None' || b.extraType == 'No Ball')).length;
                    final sixes = pBalls.where((b) => b.run == 6 && (b.extraType == 'None' || b.extraType == 'No Ball')).length;
                    final runsScored = p.runsScored;
                    final ballsFaced = p.ballsFaced;
                    final sr = ballsFaced > 0 ? ((runsScored / ballsFaced) * 100).toStringAsFixed(1) : '0.0';

                    // Determine dismissal status
                    String statusText = 'Yet to bat';
                    Color statusColor = const Color(0xFF94A3B8);
                    final dismissalBall = match.balls.reversed.firstWhere(
                      (b) => b.isWicket && (b.strikerId == p.id || b.batsmanName == p.name),
                      orElse: () => BallRecord(run: 0, extraRun: 0, extraType: '', isWicket: false, wicketType: '', batsmanName: '', bowlerName: '', commentary: '', timestamp: DateTime.now()),
                    );

                    if (isCurrentStriker) {
                      statusText = 'batting (striker) *';
                      statusColor = const Color(0xFF047857);
                    } else if (isCurrentNonStriker) {
                      statusText = 'batting (non-striker) *';
                      statusColor = const Color(0xFF059669);
                    } else if (dismissalBall.isWicket) {
                      statusText = dismissalBall.wicketType.isNotEmpty
                          ? '${dismissalBall.wicketType} b ${dismissalBall.bowlerName}'
                          : 'out';
                      statusColor = const Color(0xFFEF4444);
                    } else if (runsScored > 0 || ballsFaced > 0) {
                      statusText = 'not out *';
                      statusColor = const Color(0xFF047857);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isCurrentStriker || isCurrentNonStriker)
                                      Container(
                                        margin: const EdgeInsets.only(right: 5),
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        p.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: (isCurrentStriker || isCurrentNonStriker) ? FontWeight.bold : FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (p.isCaptain) ...[
                                      const SizedBox(width: 4),
                                      Text('(c)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                    ] else if (p.isViceCaptain) ...[
                                      const SizedBox(width: 4),
                                      Text('(vc)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: statusColor,
                                    fontWeight: (isCurrentStriker || isCurrentNonStriker) ? FontWeight.bold : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              (runsScored > 0 || ballsFaced > 0 || isCurrentStriker || isCurrentNonStriker) ? '$runsScored' : '-',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: (isCurrentStriker || isCurrentNonStriker) ? const Color(0xFF028A6B) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Expanded(flex: 1, child: Text((runsScored > 0 || ballsFaced > 0 || isCurrentStriker || isCurrentNonStriker) ? '$ballsFaced' : '-', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)))),
                          Expanded(flex: 1, child: Text((runsScored > 0 || ballsFaced > 0 || isCurrentStriker || isCurrentNonStriker) ? '$fours' : '-', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)))),
                          Expanded(flex: 1, child: Text((runsScored > 0 || ballsFaced > 0 || isCurrentStriker || isCurrentNonStriker) ? '$sixes' : '-', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)))),
                          Expanded(
                            flex: 2,
                            child: Text(
                              (runsScored > 0 || ballsFaced > 0 || isCurrentStriker || isCurrentNonStriker) ? sr : '-',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Extras & Total Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Extras', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text(
                            '$totalExtras (b $byes, lb $legByes, w $wides, nb $noBalls)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Score', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                          Text(
                            '$innRuns/$innWickets ($innOvers ov, RR: $innCrr)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF028A6B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. BOWLERS SCORECARD CARD (Full List of Bowlers)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${innBowlTeam.name.toUpperCase()} BOWLING',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('ECO', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)))),
                    ],
                  ),
                ),

                // Bowlers List
                Builder(
                  builder: (context) {
                    final bowlersWhoBowled = innBowlPlayers.where((b) {
                      return b.oversBowled > 0 || b.runsConceded > 0 || b.wicketsTaken > 0 || (b.id == match.currentBowlerId && match.status == 'Live');
                    }).toList();

                    final displayBowlers = bowlersWhoBowled.isNotEmpty ? bowlersWhoBowled : innBowlPlayers.take(4).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayBowlers.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final b = displayBowlers[i];
                        final isLiveBowler = b.id == match.currentBowlerId && match.status == 'Live';
                        final eco = b.oversBowled > 0 ? (b.runsConceded / b.oversBowled).toStringAsFixed(1) : '0.0';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    if (isLiveBowler)
                                      Container(
                                        margin: const EdgeInsets.only(right: 5),
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        '${b.name}${isLiveBowler ? " *" : ""}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: isLiveBowler ? FontWeight.bold : FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(flex: 1, child: Text(b.oversBowled.toStringAsFixed(1), textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)))),
                              Expanded(flex: 1, child: Text('0', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)))),
                              Expanded(flex: 1, child: Text('${b.runsConceded}', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)))),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${b.wicketsTaken}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  eco,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. SQUADS / PLAYING XI SECTION
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                        const Icon(Icons.groups_rounded, color: Color(0xFF028A6B), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'PLAYING XI & SQUADS',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${match.teamA.shortName} vs ${match.teamB.shortName}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Team Squads Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team A Playing XI
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              match.teamA.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...((match.playingXI_A.isNotEmpty ? match.playingXI_A : match.teamA.players).map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.5),
                                child: Row(
                                  children: [
                                    const Text('• ', style: TextStyle(color: Color(0xFF028A6B), fontSize: 12)),
                                    Expanded(
                                      child: Text(
                                        '${p.name}${p.isCaptain ? " (c)" : p.isViceCaptain ? " (vc)" : ""}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Team B Playing XI
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              match.teamB.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...((match.playingXI_B.isNotEmpty ? match.playingXI_B : match.teamB.players).map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.5),
                                child: Row(
                                  children: [
                                    const Text('• ', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                                    Expanded(
                                      child: Text(
                                        '${p.name}${p.isCaptain ? " (c)" : p.isViceCaptain ? " (vc)" : ""}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
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
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Waiting for overs to be completed...',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
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

class LiveCardWatermarkPainter extends CustomPainter {
  const LiveCardWatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right soft mint wave gradient
    final wavePaint = Paint()
      ..color = const Color(0xFFE6F4EA).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..cubicTo(size.width * 0.7, size.height * 0.3, size.width * 0.8, size.height * 0.1, size.width, size.height * 0.5)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, wavePaint);

    // Bottom-right subtle cricket ball watermark
    final ballPaint = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ballCenter = Offset(size.width * 0.88, size.height * 0.72);
    canvas.drawCircle(ballCenter, 32, ballPaint);

    // Cricket ball seam curves
    final seamPaint = Paint()
      ..color = const Color(0xFFA7F3D0).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final seamPath1 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.72), radius: 24),
        -0.8,
        1.6,
      );
    canvas.drawPath(seamPath1, seamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


