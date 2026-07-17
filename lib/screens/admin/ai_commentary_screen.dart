// lib/screens/admin/ai_commentary_screen.dart
// Animated scrolling commentary feed with color-coded ball badges

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AiCommentaryScreen extends StatefulWidget {
  final CricketMatch match;
  const AiCommentaryScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<AiCommentaryScreen> createState() => _AiCommentaryScreenState();
}

class _AiCommentaryScreenState extends State<AiCommentaryScreen> {
  final List<_CommentaryItem> _feed = [];
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _autoTimer;
  bool _isAutoGenerating = false;
  final _random = Random();

  final _batsmen = ['V. Kohli', 'S. Yadav', 'R. Sharma', 'KL Rahul', 'H. Pandya'];
  final _bowlers = ['M. Starc', 'P. Cummins', 'A. Zampa', 'J. Hazlewood', 'G. Maxwell'];

  @override
  void initState() {
    super.initState();
    // Load existing balls from match
    for (final b in widget.match.balls) {
      String label;
      Color bc;
      if (b.isWicket) { label = 'W'; bc = AppTheme.accentRed; }
      else if (b.run == 6) { label = '6'; bc = AppTheme.primaryGreen; }
      else if (b.run == 4) { label = '4'; bc = AppTheme.primaryBlue; }
      else if (b.extraType != 'None') { label = b.extraType.substring(0, 1).toUpperCase(); bc = AppTheme.accentOrange; }
      else { label = '${b.run}'; bc = Colors.white54; }
      _feed.add(_CommentaryItem(label: label, color: bc, text: b.commentary, batsman: b.batsmanName, bowler: b.bowlerName));
    }
    // Add dummy seed if no balls
    if (_feed.isEmpty) {
      _seedDummyCommentary();
    }
  }

  void _seedDummyCommentary() {
    final items = [
      _CommentaryItem(label: '1', color: AppTheme.textSecondary, text: 'Quick single. Kohli taps it to mid-on and they cross comfortably.', batsman: 'V. Kohli', bowler: 'M. Starc'),
      _CommentaryItem(label: '4', color: AppTheme.primaryBlue, text: 'FOUR! Beautiful cover drive by Kohli through extra cover!', batsman: 'V. Kohli', bowler: 'M. Starc'),
      _CommentaryItem(label: '0', color: AppTheme.textMuted, text: 'Dot ball. Good length, Yadav pushes back to the bowler.', batsman: 'S. Yadav', bowler: 'P. Cummins'),
      _CommentaryItem(label: '6', color: AppTheme.primaryGreen, text: 'SIX! Suryakumar steps out and launches it over long-on!', batsman: 'S. Yadav', bowler: 'P. Cummins'),
      _CommentaryItem(label: 'W', color: AppTheme.accentRed, text: 'WICKET! Clean bowled! Starc gets one through the gate!', batsman: 'R. Sharma', bowler: 'M. Starc'),
    ];
    setState(() => _feed.addAll(items.reversed));
  }

  void _generateOne() {
    final bat = _batsmen[_random.nextInt(_batsmen.length)];
    final bowl = _bowlers[_random.nextInt(_bowlers.length)];
    final rng = _random.nextInt(10);
    String label;
    Color bc;
    String text;

    if (rng == 0) {
      label = 'W'; bc = AppTheme.accentRed;
      text = AppConstants.wicketCommentary[_random.nextInt(AppConstants.wicketCommentary.length)];
    } else if (rng == 1) {
      label = '6'; bc = AppTheme.primaryGreen;
      text = AppConstants.sixCommentary[_random.nextInt(AppConstants.sixCommentary.length)];
    } else if (rng == 2 || rng == 3) {
      label = '4'; bc = AppTheme.primaryBlue;
      text = AppConstants.fourCommentary[_random.nextInt(AppConstants.fourCommentary.length)];
    } else if (rng == 4) {
      label = 'Wd'; bc = AppTheme.accentOrange;
      text = AppConstants.wideCommentary[_random.nextInt(AppConstants.wideCommentary.length)];
    } else if (rng == 5 || rng == 6) {
      label = '1'; bc = Colors.white54;
      text = AppConstants.singleCommentary[_random.nextInt(AppConstants.singleCommentary.length)];
    } else {
      label = '0'; bc = Colors.white24;
      text = AppConstants.dotCommentary[_random.nextInt(AppConstants.dotCommentary.length)];
    }

    setState(() => _feed.insert(0, _CommentaryItem(label: label, color: bc, text: text, batsman: bat, bowler: bowl)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _toggleAutoGenerate() {
    setState(() => _isAutoGenerating = !_isAutoGenerating);
    if (_isAutoGenerating) {
      _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) => _generateOne());
    } else {
      _autoTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('AI Commentary', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: _generateOne,
            icon: const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primaryBlue),
            label: Text('Generate', style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Match Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: AppTheme.bgMedium,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                  ),
                  child: Text('● LIVE', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Text('${widget.match.teamA.shortName} vs ${widget.match.teamB.shortName}',
                    style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${widget.match.runsA}/${widget.match.wicketsA}',
                    style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Auto-generate toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('Auto Commentary',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary)),
                const Spacer(),
                Switch(
                  value: _isAutoGenerating,
                  onChanged: (_) => _toggleAutoGenerate(),
                  activeColor: AppTheme.primaryGreen,
                ),
                if (_isAutoGenerating)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('Every 3s',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.primaryGreen)),
                  ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _Legend('6', AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _Legend('4', AppTheme.primaryBlue),
                const SizedBox(width: 8),
                _Legend('W', AppTheme.accentRed),
                const SizedBox(width: 8),
                _Legend('Ext', AppTheme.accentOrange),
                const SizedBox(width: 8),
                _Legend('•', Colors.white38),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Commentary Feed
          Expanded(
            child: _feed.isEmpty
                ? Center(
                    child: Text('No commentary yet.\nTap Generate to start.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textMuted)),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: _feed.length,
                    itemBuilder: (_, i) {
                      final item = _feed[i];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? item.color.withOpacity(0.08)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: i == 0
                                  ? item.color.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ball badge
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.color.withOpacity(0.15),
                                  border: Border.all(color: item.color.withOpacity(0.5)),
                                ),
                                child: Center(
                                  child: Text(item.label,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12, color: item.color, fontWeight: FontWeight.w800)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(item.batsman,
                                            style: GoogleFonts.outfit(
                                                fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w700)),
                                        Text(' to ', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                        Text(item.bowler,
                                            style: GoogleFonts.outfit(
                                                fontSize: 11, color: AppTheme.accentRed, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.text,
                                        style: GoogleFonts.outfit(
                                            fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateOne,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.mic_rounded, color: AppTheme.textPrimary),
        label: Text('AI Generate', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CommentaryItem {
  final String label, text, batsman, bowler;
  final Color color;
  const _CommentaryItem({
    required this.label, required this.color, required this.text,
    required this.batsman, required this.bowler,
  });
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Center(child: Text(label, style: GoogleFonts.outfit(fontSize: 8, color: color, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 4),
        Text(label == '6' ? 'Six' : label == '4' ? 'Four' : label == 'W' ? 'Wicket' : label == 'Ext' ? 'Extra' : 'Dot/Run',
            style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }
}
