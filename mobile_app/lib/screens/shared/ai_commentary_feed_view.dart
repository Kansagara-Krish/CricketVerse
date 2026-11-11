import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../models/models.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/storage_service.dart';

/// Shared live AI Commentary view used identically by both User and Admin screens.
class AiCommentaryFeedView extends StatefulWidget {
  final CricketMatch match;

  const AiCommentaryFeedView({
    super.key,
    required this.match,
  });

  @override
  State<AiCommentaryFeedView> createState() => _AiCommentaryFeedViewState();
}

class _AiCommentaryFeedViewState extends State<AiCommentaryFeedView> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingVoice = false;
  int _playingVoiceIndex = -1;
  bool _isLiveAudioActive = false;
  int _lastHandledBallCount = 0;
  Timer? _liveCommentaryDelayTimer;

  @override
  void initState() {
    super.initState();
    _lastHandledBallCount = widget.match.balls.length;
    ElevenLabsService().init();
  }

  @override
  void didUpdateWidget(covariant AiCommentaryFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndHandleIncomingBall(widget.match);
  }

  @override
  void dispose() {
    _liveCommentaryDelayTimer?.cancel();
    ElevenLabsService().stopAudio();
    _flutterTts.stop();
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
        final service = ElevenLabsService();
        final isTts = service.settings.isInbuiltTts;
        final voiceName = service.settings.voiceName;
        CustomNotification.show(
          context,
          isTts
              ? '🎙️ Playing Inbuilt Voice Commentary (Free • 0 Tokens)...'
              : '🎙️ Playing ElevenLabs AI Voice ($voiceName)...',
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
        final curMatch = curStorage.matches.firstWhere((m) => m.id == widget.match.id, orElse: () => match);
        if (curMatch.balls.length >= targetBallCount && curMatch.balls.isNotEmpty) {
          final latestBall = curMatch.balls.last;
          _playVoiceCommentary(-99, latestBall.commentary);
        }
      });
    } else if (match.balls.length < _lastHandledBallCount) {
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
    final match = widget.match;

    if (match.balls.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for match scoring events to start...',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
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
                                  : (ElevenLabsService().settings.isInbuiltTts
                                      ? 'Listen to Inbuilt Voice (Free • 0 Tokens)'
                                      : 'Listen to ElevenLabs AI live voice'),
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
}

