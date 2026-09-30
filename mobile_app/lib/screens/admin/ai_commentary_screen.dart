// lib/screens/admin/ai_commentary_screen.dart
// AI Commentary Studio with ElevenLabs Voice Integration & Custom Text Generator

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/ai_commentary_generator.dart';
import '../../services/storage_service.dart';

class AiCommentaryScreen extends StatefulWidget {
  final CricketMatch match;
  const AiCommentaryScreen({super.key, required this.match});

  @override
  State<AiCommentaryScreen> createState() => _AiCommentaryScreenState();
}

class _AiCommentaryScreenState extends State<AiCommentaryScreen> with SingleTickerProviderStateMixin {
  final List<_CommentaryFeedItem> _feed = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _customTextController = TextEditingController();
  final ElevenLabsService _elevenLabs = ElevenLabsService();

  Timer? _autoTimer;
  bool _isAutoGenerating = false;
  bool _isGeneratingCustom = false;
  int _playingItemIndex = -1;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _elevenLabs.init();

    // Listen to ElevenLabs playback status
    _elevenLabs.isPlayingNotifier.addListener(_onPlaybackStateChanged);

    // Seed commentary from match balls
    _loadMatchBalls();
  }

  void _onPlaybackStateChanged() {
    if (!_elevenLabs.isPlaying && mounted) {
      setState(() => _playingItemIndex = -1);
    }
  }

  void _loadMatchBalls() {
    for (int i = 0; i < widget.match.balls.length; i++) {
      final b = widget.match.balls[i];
      String label;
      Color bc;
      if (b.isWicket) {
        label = 'W';
        bc = AppTheme.accentRed;
      } else if (b.run == 6) {
        label = '6';
        bc = AppTheme.primaryGreen;
      } else if (b.run == 4) {
        label = '4';
        bc = AppTheme.primaryBlue;
      } else if (b.extraType != 'None') {
        label = b.extraType.substring(0, 1).toUpperCase();
        bc = AppTheme.accentOrange;
      } else {
        label = '${b.run}';
        bc = Colors.white54;
      }
      _feed.add(_CommentaryFeedItem(
        id: 'ball_$i',
        label: label,
        color: bc,
        text: b.commentary,
        batsman: b.batsmanName,
        bowler: b.bowlerName,
        timestamp: b.timestamp,
      ));
    }

    if (_feed.isEmpty) {
      _seedDefaultFeed();
    }
  }

  void _seedDefaultFeed() {
    final now = DateTime.now();
    _feed.addAll([
      _CommentaryFeedItem(
        id: 'seed_1',
        label: '6',
        color: AppTheme.primaryGreen,
        text: 'SIX! Smashed high over long-on! That clears the boundary ropes with tremendous power! Score moves to 120/2.',
        batsman: widget.match.teamA.players.isNotEmpty ? widget.match.teamA.players[0].name : 'V. Kohli',
        bowler: widget.match.teamB.players.isNotEmpty ? widget.match.teamB.players.last.name : 'M. Starc',
        timestamp: now.subtract(const Duration(seconds: 15)),
      ),
      _CommentaryFeedItem(
        id: 'seed_2',
        label: '4',
        color: AppTheme.primaryBlue,
        text: 'FOUR! Sliced beautifully past backward point! Races away into the fence.',
        batsman: widget.match.teamA.players.isNotEmpty ? widget.match.teamA.players[0].name : 'V. Kohli',
        bowler: widget.match.teamB.players.isNotEmpty ? widget.match.teamB.players.last.name : 'M. Starc',
        timestamp: now.subtract(const Duration(seconds: 40)),
      ),
      _CommentaryFeedItem(
        id: 'seed_3',
        label: 'W',
        color: AppTheme.accentRed,
        text: 'OUT! Clean bowled! In-swinging yorker rattles the middle stump! Huge breakthrough!',
        batsman: widget.match.teamA.players.length > 1 ? widget.match.teamA.players[1].name : 'R. Sharma',
        bowler: widget.match.teamB.players.isNotEmpty ? widget.match.teamB.players.last.name : 'M. Starc',
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    ]);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _waveController.dispose();
    _scrollCtrl.dispose();
    _customTextController.dispose();
    _elevenLabs.isPlayingNotifier.removeListener(_onPlaybackStateChanged);
    _elevenLabs.stopAudio();
    super.dispose();
  }

  Future<void> _playCommentaryAudio(int index, String text) async {
    if (_playingItemIndex == index && _elevenLabs.isPlaying) {
      await _elevenLabs.stopAudio();
      setState(() => _playingItemIndex = -1);
      return;
    }

    setState(() => _playingItemIndex = index);

    final voiceName = _elevenLabs.settings.voiceName;
    CustomNotification.show(
      context,
      '🎙️ Speaking with $voiceName...',
      type: NotificationType.info,
    );

    await _elevenLabs.speakCommentary(
      text,
      onComplete: () {
        if (mounted) setState(() => _playingItemIndex = -1);
      },
      onError: (err) {
        if (mounted) {
          setState(() => _playingItemIndex = -1);
          CustomNotification.show(context, 'Audio error: $err', type: NotificationType.error);
        }
      },
    );
  }

  /// Generate a smart contextual ball using AiCommentaryGenerator
  void _generateSmartBallCommentary() {
    final storage = Provider.of<StorageService>(context, listen: false);
    final match = storage.matches.firstWhere((m) => m.id == widget.match.id, orElse: () => widget.match);

    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    final batName = battingTeam.players.isNotEmpty ? battingTeam.players[0].name : 'Batsman';
    final bowlName = bowlingTeam.players.isNotEmpty ? bowlingTeam.players.last.name : 'Bowler';

    final totalRuns = match.isFirstInnings ? match.runsA : match.runsB;
    final totalWickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    final currentOvers = match.isFirstInnings ? match.oversA : match.oversB;

    // Simulate outcome with weighted probability
    final outcomes = [0, 0, 1, 1, 2, 4, 4, 6, -1]; // -1 = wicket
    final rngOutcome = outcomes[DateTime.now().millisecond % outcomes.length];

    int run = 0;
    bool isWicket = false;
    String wicketType = 'None';
    String label = '0';
    Color color = Colors.white38;

    if (rngOutcome == -1) {
      isWicket = true;
      wicketType = (DateTime.now().second % 2 == 0) ? 'Bowled' : 'Caught';
      label = 'W';
      color = AppTheme.accentRed;
    } else if (rngOutcome == 6) {
      run = 6;
      label = '6';
      color = AppTheme.primaryGreen;
    } else if (rngOutcome == 4) {
      run = 4;
      label = '4';
      color = AppTheme.primaryBlue;
    } else if (rngOutcome > 0) {
      run = rngOutcome;
      label = '$run';
      color = Colors.white70;
    }

    final commentaryText = AiCommentaryGenerator.generate(
      AiCommentaryContext(
        batsman: batName,
        bowler: bowlName,
        runs: run,
        isWicket: isWicket,
        wicketType: wicketType,
        currentOvers: currentOvers,
        totalRuns: totalRuns + run,
        totalWickets: totalWickets + (isWicket ? 1 : 0),
        style: _elevenLabs.settings.commentaryStyle,
      ),
    );

    final newItem = _CommentaryFeedItem(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      color: color,
      text: commentaryText,
      batsman: batName,
      bowler: bowlName,
      timestamp: DateTime.now(),
    );

    setState(() {
      _feed.insert(0, newItem);
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    // If auto-play is enabled, speak it immediately
    if (_elevenLabs.settings.autoPlayVoice) {
      _playCommentaryAudio(0, commentaryText);
    }
  }

  /// Send and generate custom prompt / text into speech
  Future<void> _generateCustomCommentary() async {
    final prompt = _customTextController.text.trim();
    if (prompt.isEmpty) {
      CustomNotification.show(context, 'Please enter some commentary text to generate audio.', type: NotificationType.warning);
      return;
    }

    setState(() => _isGeneratingCustom = true);
    _customTextController.clear();
    FocusScope.of(context).unfocus();

    // Format into rich broadcast commentary
    final formattedText = AiCommentaryGenerator.formatCustomCommentary(
      prompt,
      style: _elevenLabs.settings.commentaryStyle,
    );

    String label = 'AI';
    Color color = AppTheme.accentPurple;
    if (prompt.toLowerCase().contains('six') || prompt.contains('6')) {
      label = '6';
      color = AppTheme.primaryGreen;
    } else if (prompt.toLowerCase().contains('four') || prompt.contains('4')) {
      label = '4';
      color = AppTheme.primaryBlue;
    } else if (prompt.toLowerCase().contains('wicket') || prompt.toLowerCase().contains('out')) {
      label = 'W';
      color = AppTheme.accentRed;
    }

    final newItem = _CommentaryFeedItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      color: color,
      text: formattedText,
      batsman: widget.match.teamA.players.isNotEmpty ? widget.match.teamA.players[0].name : 'Striker',
      bowler: widget.match.teamB.players.isNotEmpty ? widget.match.teamB.players.last.name : 'Bowler',
      timestamp: DateTime.now(),
    );

    setState(() {
      _feed.insert(0, newItem);
      _isGeneratingCustom = false;
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    // Automatically speak the custom generated commentary
    await _playCommentaryAudio(0, formattedText);
  }

  void _toggleAutoCommentary() {
    setState(() => _isAutoGenerating = !_isAutoGenerating);
    if (_isAutoGenerating) {
      _autoTimer = Timer.periodic(const Duration(seconds: 7), (_) => _generateSmartBallCommentary());
      CustomNotification.show(context, '⚡ Auto-generating live ball commentary every 7s', type: NotificationType.success);
    } else {
      _autoTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Commentary Studio',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
            Text(
              'Voice: ${_elevenLabs.settings.voiceName}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.accentGold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue),
            tooltip: 'AI & Voice Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/admin/ai-settings').then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Match Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgMedium,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.match.teamA.shortName} vs ${widget.match.teamB.shortName}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  widget.match.isFirstInnings
                      ? '${widget.match.runsA}/${widget.match.wicketsA} (${widget.match.oversA} ov)'
                      : '${widget.match.runsB}/${widget.match.wicketsB} (${widget.match.oversB} ov)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          // Custom Commentary Input Box
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentPurple, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Custom AI Commentary & Voice Generator',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    // Auto toggle
                    Row(
                      children: [
                        Text('Auto', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: _isAutoGenerating,
                            onChanged: (_) => _toggleAutoCommentary(),
                            activeThumbColor: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customTextController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. Batsman hit a six on second ball / over finish on 125/3',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.bgDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        onSubmitted: (_) => _generateCustomCommentary(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isGeneratingCustom ? null : _generateCustomCommentary,
                      icon: const Icon(Icons.mic_rounded, size: 16),
                      label: Text('Speak', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Commentary Feed List
          Expanded(
            child: _feed.isEmpty
                ? Center(
                    child: Text(
                      'No commentary recorded yet.\nTap "Generate Ball" or enter custom text above.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _feed.length,
                    itemBuilder: (_, index) {
                      final item = _feed[index];
                      final isPlayingThis = _playingItemIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isPlayingThis
                              ? item.color.withValues(alpha: 0.12)
                              : AppTheme.bgMedium,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPlayingThis
                                ? item.color.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.05),
                            width: isPlayingThis ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ball Badge
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.color.withValues(alpha: 0.15),
                                border: Border.all(color: item.color.withValues(alpha: 0.6)),
                              ),
                              child: Center(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: item.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Commentary Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.batsman,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      Text(' vs ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                                      Text(
                                        item.bowler,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.accentRed,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isPlayingThis)
                                        AnimatedBuilder(
                                          animation: _waveController,
                                          builder: (_, __) => Row(
                                            children: List.generate(4, (i) {
                                              return Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                width: 2.5,
                                                height: 8 + (6 * _waveController.value * ((i % 2 == 0) ? 1 : 0.5)),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlue,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.text,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Listen / Stop Button
                            IconButton(
                              icon: Icon(
                                isPlayingThis ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                color: isPlayingThis ? AppTheme.accentRed : AppTheme.primaryBlue,
                                size: 22,
                              ),
                              tooltip: isPlayingThis ? 'Stop Audio' : 'Listen with ElevenLabs Voice',
                              onPressed: () => _playCommentaryAudio(index, item.text),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateSmartBallCommentary,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: Text(
          'Generate Smart Ball',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

class _CommentaryFeedItem {
  final String id;
  final String label;
  final Color color;
  final String text;
  final String batsman;
  final String bowler;
  final DateTime timestamp;

  const _CommentaryFeedItem({
    required this.id,
    required this.label,
    required this.color,
    required this.text,
    required this.batsman,
    required this.bowler,
    required this.timestamp,
  });
}
