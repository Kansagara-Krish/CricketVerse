// lib/screens/admin/ai_commentary_screen.dart
// Unified Live AI Commentary Screen (mirrors User AI Commentary feed in real time)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/storage_service.dart';
import '../shared/ai_commentary_feed_view.dart';

class AiCommentaryScreen extends StatefulWidget {
  final CricketMatch match;
  const AiCommentaryScreen({super.key, required this.match});

  @override
  State<AiCommentaryScreen> createState() => _AiCommentaryScreenState();
}

class _AiCommentaryScreenState extends State<AiCommentaryScreen> {
  @override
  void initState() {
    super.initState();
    ElevenLabsService().init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final storage = Provider.of<StorageService>(context, listen: false);
      storage.subscribeToMatchLiveUpdates(widget.match.id);
      storage.refreshMatch(widget.match.id);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (context, storage, _) {
        final liveMatch = storage.matches.firstWhere(
          (m) => m.id == widget.match.id,
          orElse: () => widget.match,
        );
        final isLive = liveMatch.status == 'Live';
        final isTeamABatting = liveMatch.battingTeamId.isEmpty || liveMatch.battingTeamId == liveMatch.teamA.id;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Commentary',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${liveMatch.teamA.shortName} vs ${liveMatch.teamB.shortName} • ${isTeamABatting ? "${liveMatch.runsA}/${liveMatch.wicketsA} (${liveMatch.oversA} ov)" : "${liveMatch.runsB}/${liveMatch.wicketsB} (${liveMatch.oversB} ov)"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isLive ? AppTheme.primaryGreen : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue),
                tooltip: 'AI & Voice Settings',
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/ai-settings').then((_) async {
                    await ElevenLabsService().loadSettings();
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
          body: AiCommentaryFeedView(match: liveMatch),
        );
      },
    );
  }
}
