import 'dart:async';
import 'dart:math';
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
  bool _isLiveAudioActive = false;
  int _lastHandledBallCount = 0;
  Timer? _liveCommentaryDelayTimer;
  Timer? _periodicSyncTimer;

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
      final storage = Provider.of<StorageService>(context, listen: false);
      storage.subscribeToMatchLiveUpdates(widget.matchId);
      storage.refreshMatch(widget.matchId);
    });

    // Continuously communicate with database to check for new ball & AI commentary updates
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      final storage = Provider.of<StorageService>(context, listen: false);
      if (storage.matches.isNotEmpty) {
        final currentMatch = storage.matches.firstWhere(
          (m) => m.id == widget.matchId,
          orElse: () => storage.matches[0],
        );
        if (currentMatch.status == 'Live') {
          await storage.refreshMatch(widget.matchId);
        }
      }
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
    _periodicSyncTimer?.cancel();
    _liveCommentaryDelayTimer?.cancel();
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
    if (_isLiveAudioActive) {
      _liveCommentaryDelayTimer?.cancel();
      await ElevenLabsService().stopAudio();
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isLiveAudioActive = false;
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
        CustomNotification.show(context, '🔇 Live AI Commentary Stopped', type: NotificationType.warning);
      }
    } else {
      _liveCommentaryDelayTimer?.cancel();
      if (mounted) {
        setState(() {
          _isLiveAudioActive = true;
          _lastHandledBallCount = match.balls.length;
        });
      }

      final isTeamABatting = match.battingTeamId == match.teamA.id;
      final battingTeam = isTeamABatting ? match.teamA : match.teamB;
      final bowlingTeam = isTeamABatting ? match.teamB : match.teamA;
      final runs = isTeamABatting ? match.runsA : match.runsB;
      final wickets = isTeamABatting ? match.wicketsA : match.wicketsB;
      final overs = isTeamABatting ? match.oversA : match.oversB;

      String latestBallText = '';
      if (match.balls.isNotEmpty) {
        latestBallText = ' Latest update: ${match.balls.last.commentary}';
      }

      final welcomeText =
          'Welcome to CricketVerse AI Live Commentary! ${battingTeam.name} is currently $runs for $wickets in $overs overs playing against ${bowlingTeam.name}.$latestBallText';

      _playVoiceCommentary(-99, welcomeText);
    }
  }

  void _checkAndHandleIncomingBall(CricketMatch match) {
    if (!_isLiveAudioActive) {
      _lastHandledBallCount = match.balls.length;
      return;
    }
    if (_lastHandledBallCount == 0 && match.balls.isNotEmpty) {
      _lastHandledBallCount = match.balls.length;
      return;
    }
    if (match.balls.length > _lastHandledBallCount) {
      final targetBallCount = match.balls.length;
      _lastHandledBallCount = targetBallCount;
      _liveCommentaryDelayTimer?.cancel();
      _liveCommentaryDelayTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted || !_isLiveAudioActive) return;
        final curStorage = Provider.of<StorageService>(context, listen: false);
        final curMatch = curStorage.matches.firstWhere((m) => m.id == widget.matchId, orElse: () => match);
        // Ensure ball count hasn't decreased due to undo and speak only latest commentary
        if (curMatch.balls.length >= targetBallCount && curMatch.balls.isNotEmpty) {
          final latestBall = curMatch.balls.last;
          _playVoiceCommentary(-99, latestBall.commentary);
        }
      });
    } else if (match.balls.length < _lastHandledBallCount) {
      // Manager performed an undo
      _liveCommentaryDelayTimer?.cancel();
      _lastHandledBallCount = match.balls.length;
      ElevenLabsService().stopAudio();
      _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final match = storage.matches.firstWhere((m) => m.id == widget.matchId, orElse: () => storage.matches[0]);
    _checkAndHandleIncomingBall(match);

    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final battingTeam = isTeamABatting ? match.teamA : match.teamB;
    final bowlingTeam = isTeamABatting ? match.teamB : match.teamA;

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

    final runs = isTeamABatting ? match.runsA : match.runsB;
    final overs = isTeamABatting ? match.oversA : match.oversB;
    
    final winProb = storage.calculateWinProbability(match);

    // Team A and Team B stats for the live card
    final hasTeamABatted = match.runsA > 0 || match.wicketsA > 0 || match.oversA > 0 || isTeamABatting || match.status == 'Completed';
    final hasTeamBBatted = match.runsB > 0 || match.wicketsB > 0 || match.oversB > 0 || !isTeamABatting || match.status == 'Completed';

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
                      ? (match.resultText.isNotEmpty ? match.resultText : '${match.runsA > match.runsB ? match.teamA.name : match.teamB.name} won the match')
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
          // Hero Live Match Banner
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
                              color: match.status == 'Live' ? const Color(0xFFE6F4EA) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: match.status == 'Live' ? const Color(0xFF34D399).withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (match.status == 'Live') ...[
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
                                ],
                                Text(
                                  match.status == 'Live' ? 'LIVE' : match.status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: match.status == 'Live' ? const Color(0xFF047857) : const Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${match.matchType} • ${match.isFirstInnings ? "1st Innings" : "2nd Innings"}',
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
                      _buildHeaderTeamRow(
                        teamName: match.teamA.name,
                        teamShort: match.teamA.shortName,
                        teamColor: const Color(0xFF028A6B),
                        runs: match.runsA,
                        wickets: match.wicketsA,
                        overs: match.oversA,
                        hasBatted: hasTeamABatted,
                        isBatting: isTeamABatting && match.status == 'Live',
                      ),
                      const SizedBox(height: 12),

                      // Team B Row
                      _buildHeaderTeamRow(
                        teamName: match.teamB.name,
                        teamShort: match.teamB.shortName,
                        teamColor: const Color(0xFFDC2626),
                        runs: match.runsB,
                        wickets: match.wicketsB,
                        overs: match.oversB,
                        hasBatted: hasTeamBBatted,
                        isBatting: !isTeamABatting && match.status == 'Live',
                      ),
                      const SizedBox(height: 14),

                      // Orange/Peach Target Summary Bar
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
                                match.status == 'Completed'
                                    ? (match.resultText.isNotEmpty ? match.resultText : 'Match Completed')
                                    : (match.isFirstInnings
                                        ? '1st Innings in progress • ${battingTeam.shortName} setting target'
                                        : 'Target ${match.target} • Need ${(match.target - runs).clamp(0, 9999)} runs off ${((20 - overs.toInt()) * 6 - ((overs - overs.toInt()) * 10).round()).clamp(0, 120)} balls'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFFC2410C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
                RefreshIndicator(
                  color: const Color(0xFF028A6B),
                  backgroundColor: Colors.white,
                  onRefresh: () async => await storage.refreshMatch(widget.matchId),
                  child: _buildLiveDetailsView(match, storage, striker, nonStriker, bowler, winProb),
                ),
                // 2. AI Commentary Feed
                RefreshIndicator(
                  color: const Color(0xFF028A6B),
                  backgroundColor: Colors.white,
                  onRefresh: () async => await storage.refreshMatch(widget.matchId),
                  child: _buildCommentaryFeed(match),
                ),
                // 3. Analytics
                RefreshIndicator(
                  color: const Color(0xFF028A6B),
                  backgroundColor: Colors.white,
                  onRefresh: () async => await storage.refreshMatch(widget.matchId),
                  child: _buildAnalyticsView(match),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTeamRow({
    required String teamName,
    required String teamShort,
    required Color teamColor,
    required int runs,
    required int wickets,
    required double overs,
    required bool hasBatted,
    required bool isBatting,
  }) {
    final displayShort = teamShort.trim().isNotEmpty
        ? teamShort.trim()
        : (teamName.length > 4 ? teamName.substring(0, 3).toUpperCase() : teamName.toUpperCase());

    final initial = displayShort.isNotEmpty ? displayShort.substring(0, 1).toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Team Avatar Badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: teamColor.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                color: teamColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Team Name & Batting Status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayShort,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (isBatting) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Batting',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: const Color(0xFF047857),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (teamName.isNotEmpty && teamName.toLowerCase() != displayShort.toLowerCase()) ...[
                const SizedBox(height: 1),
                Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Score display on the right
        if (hasBatted)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$runs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isBatting ? const Color(0xFF028A6B) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '/$wickets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isBatting ? const Color(0xFF028A6B) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${overs.toStringAsFixed(1)} ov${isBatting && overs > 0 ? " • CRR ${(runs / overs).toStringAsFixed(1)}" : ""}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Yet to Bat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
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

    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final currentRuns = isTeamABatting ? match.runsA : match.runsB;
    final currentOvers = isTeamABatting ? match.oversA : match.oversB;
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
          // Top Compact AI Audio Commentary Control Card
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C81), AppTheme.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingVoice ? Icons.graphic_eq : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'AI Commentary',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isLiveAudioActive
                                  ? (_isPlayingVoice ? 'Speaking latest ball...' : 'Live audio active • Auto-syncing')
                                  : 'Listen to AI live voice',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _togglePlayAllCommentary(match),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLiveAudioActive ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                          color: AppTheme.primaryBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLiveAudioActive ? 'Stop' : 'Play Sound',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryBlue,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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


  // Calculate dynamic progression spots from real live match ball records
  List<FlSpot> _buildTeamProgressionSpots(CricketMatch match, bool forTeamA) {
    final teamId = forTeamA ? match.teamA.id : match.teamB.id;
    final totalRuns = forTeamA ? match.runsA : match.runsB;
    final totalOvers = forTeamA ? match.oversA : match.oversB;

    if (totalOvers <= 0 && totalRuns <= 0) {
      return const [FlSpot(0, 0)];
    }

    // Filter balls for this team from real live database records
    List<BallRecord> teamBalls = [];
    if (match.balls.isNotEmpty) {
      teamBalls = match.balls.where((b) {
        if (b.battingTeamId != null && b.battingTeamId!.isNotEmpty) {
          return b.battingTeamId == teamId;
        }
        if (b.innings != null) {
          final isTeamAInnings1 = (match.tossDecision.toLowerCase() == 'bat' &&
                  (match.tossWinner == match.teamA.name || match.tossWinner == 'Team A' || match.tossWinner == match.teamA.shortName)) ||
              (match.tossDecision.toLowerCase() == 'bowl' &&
                  (match.tossWinner == match.teamB.name || match.tossWinner == 'Team B' || match.tossWinner == match.teamB.shortName));
          final teamAInnings = isTeamAInnings1 ? 1 : 2;
          return forTeamA ? b.innings == teamAInnings : b.innings != teamAInnings;
        }
        return false;
      }).toList();
    }

    if (teamBalls.isNotEmpty) {
      final List<FlSpot> spots = [const FlSpot(0, 0)];
      int cumulativeRuns = 0;
      double lastOver = 0.0;
      final Map<int, int> overEndRuns = {};

      for (final ball in teamBalls) {
        cumulativeRuns += (ball.run + ball.extraRun);
        final ballOver = ball.over ?? lastOver;
        lastOver = ballOver;
        final int wholeOver = ballOver.floor();
        overEndRuns[wholeOver] = cumulativeRuns;
      }

      final int completedOvers = totalOvers.floor();
      for (int ov = 1; ov <= completedOvers; ov++) {
        if (overEndRuns.containsKey(ov)) {
          spots.add(FlSpot(ov.toDouble(), overEndRuns[ov]!.toDouble()));
        } else if (overEndRuns.containsKey(ov - 1)) {
          spots.add(FlSpot(ov.toDouble(), overEndRuns[ov - 1]!.toDouble()));
        }
      }

      if (spots.isEmpty || (spots.last.x - totalOvers).abs() > 0.05) {
        spots.add(FlSpot(totalOvers, totalRuns.toDouble()));
      } else {
        spots[spots.length - 1] = FlSpot(totalOvers, totalRuns.toDouble());
      }

      spots.sort((a, b) => a.x.compareTo(b.x));
      final List<FlSpot> uniqueSpots = [];
      for (final s in spots) {
        if (uniqueSpots.isEmpty || (s.x - uniqueSpots.last.x).abs() > 0.05) {
          uniqueSpots.add(s);
        } else {
          uniqueSpots[uniqueSpots.length - 1] = s;
        }
      }
      return uniqueSpots.length < 2 ? [const FlSpot(0, 0), FlSpot(totalOvers > 0 ? totalOvers : 1, totalRuns.toDouble())] : uniqueSpots;
    }

    // Fallback if individual balls are not yet tracked:
    final List<FlSpot> spots = [const FlSpot(0, 0)];
    if (totalOvers > 0) {
      final int wholeOvers = totalOvers.floor();
      final step = wholeOvers > 20 ? 5 : (wholeOvers > 10 ? 3 : 2);
      for (int ov = step; ov < wholeOvers; ov += step) {
        final ratio = ov / totalOvers;
        final estRuns = (totalRuns * ratio).roundToDouble();
        spots.add(FlSpot(ov.toDouble(), estRuns));
      }
      spots.add(FlSpot(totalOvers, totalRuns.toDouble()));
    } else {
      spots.add(FlSpot(1, totalRuns.toDouble()));
    }
    return spots;
  }

  Widget _buildChartLegendItem({
    required String teamName,
    required String score,
    required String overs,
    required Color color,
    required bool isBatting,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            teamName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            score,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            overs,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          if (isBatting) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BAT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. Analytics (Dual-Team Live Score Chart, Score Projection & Win Prediction) ---
  Widget _buildAnalyticsView(CricketMatch match) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final winProb = storage.calculateWinProbability(match);

    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final currentScore = isTeamABatting ? match.runsA : match.runsB;
    final currentOvers = isTeamABatting ? match.oversA : match.oversB;
    final double matchMaxOvers = match.matchType.toUpperCase() == 'ODI' ? 50.0 : 20.0;
    final double remainingOvers = (matchMaxOvers - currentOvers).clamp(0.0, matchMaxOvers);

    // Projected scores at different run rates (non-negative projection)
    final proj6 = (currentScore + remainingOvers * 6.0).round();
    final proj8 = (currentScore + remainingOvers * 8.0).round();
    final proj10 = (currentScore + remainingOvers * 10.0).round();

    // Live Progression Spots computed directly from database
    final spotsA = _buildTeamProgressionSpots(match, true);
    final spotsB = _buildTeamProgressionSpots(match, false);

    // Dynamic Max Y & Max X to properly scale any score (e.g. 401 runs in 21.2 overs)
    final maxScore = max(match.runsA, match.runsB);
    final double calculatedMaxY = max(50.0, (((maxScore * 1.15) / 25).ceil() * 25.0));

    final double highestOver = max(match.oversA, match.oversB);
    final double calculatedMaxX = max(matchMaxOvers, (highestOver.ceil()).toDouble());

    final double yInterval = calculatedMaxY > 300
        ? 100.0
        : (calculatedMaxY > 150 ? 50.0 : (calculatedMaxY > 60 ? 25.0 : 15.0));
    final double xInterval = calculatedMaxX > 30 ? 10.0 : 5.0;

    final shortNameA = match.teamA.shortName.isNotEmpty ? match.teamA.shortName : match.teamA.name;
    final shortNameB = match.teamB.shortName.isNotEmpty ? match.teamB.shortName : match.teamB.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dual Team Live Score Comparison Chart
          Text(
            'LIVE SCORE COMPARISON (RUNS OVER OVERS)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
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
                    Flexible(
                      child: _buildChartLegendItem(
                        teamName: shortNameA,
                        score: '${match.runsA}/${match.wicketsA}',
                        overs: '(${match.oversA} ov)',
                        color: AppTheme.primaryBlue,
                        isBatting: match.battingTeamId == match.teamA.id,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildChartLegendItem(
                        teamName: shortNameB,
                        score: '${match.runsB}/${match.wicketsB}',
                        overs: '(${match.oversB} ov)',
                        color: AppTheme.accentRed,
                        isBatting: match.battingTeamId == match.teamB.id,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((barSpot) {
                              final isA = barSpot.barIndex == 0;
                              final name = isA ? shortNameA : shortNameB;
                              return LineTooltipItem(
                                '$name\n${barSpot.y.toInt()} runs (${barSpot.x.toStringAsFixed(1)} ov)',
                                GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (v) => const FlLine(color: AppTheme.bgSurface, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: yInterval,
                            getTitlesWidget: (val, _) => Text(
                              '${val.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: xInterval,
                            getTitlesWidget: (val, _) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${val.toInt()}ov',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: calculatedMaxX,
                      minY: 0,
                      maxY: calculatedMaxY,
                      lineBarsData: [
                        // Team A Line
                        LineChartBarData(
                          spots: spotsA,
                          isCurved: spotsA.length > 2,
                          curveSmoothness: 0.2,
                          color: AppTheme.primaryBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 3.5,
                              color: AppTheme.primaryBlue,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withValues(alpha: 0.2),
                                AppTheme.primaryBlue.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Team B Line
                        LineChartBarData(
                          spots: spotsB,
                          isCurved: spotsB.length > 2,
                          curveSmoothness: 0.2,
                          color: AppTheme.accentRed,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 3.5,
                              color: AppTheme.accentRed,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentRed.withValues(alpha: 0.18),
                                AppTheme.accentRed.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI PREDICT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: AppTheme.accentPurple,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Win percentage indicators (Fixed RenderFlex overflow with Expanded & shortName)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$shortNameA: ${winProb.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$shortNameB: ${(100 - winProb).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
                        Flexible(
                          flex: winProb.round().clamp(1, 99),
                          child: Container(color: AppTheme.primaryBlue),
                        ),
                        Flexible(
                          flex: (100 - winProb.round()).clamp(1, 99),
                          child: Container(color: AppTheme.accentRed),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                Text(
                  'Projected Score Bounds (End of ${matchMaxOvers.toInt()} Overs)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
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


