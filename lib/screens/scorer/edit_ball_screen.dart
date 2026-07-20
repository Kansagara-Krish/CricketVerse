import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';

class EditBallScreen extends StatefulWidget {
  const EditBallScreen({super.key});

  @override
  State<EditBallScreen> createState() => _EditBallScreenState();
}

class _EditBallScreenState extends State<EditBallScreen> {
  bool _isPaused = false;

  void _deleteBall(int index, CricketMatch match) {
    setState(() {
      final ball = match.balls.removeAt(index);
      
      // Deduct from totals
      int totalRunsThisBall = ball.run + ball.extraRun;
      if (match.isFirstInnings) {
        match.runsA -= totalRunsThisBall;
        if (ball.isWicket) match.wicketsA -= 1;
        match.oversA = _decrementOvers(match.oversA);
      } else {
        match.runsB -= totalRunsThisBall;
        if (ball.isWicket) match.wicketsB -= 1;
        match.oversB = _decrementOvers(match.oversB);
      }
    });

    Provider.of<StorageService>(context, listen: false).saveMatchesState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ball deleted. Scores updated.')),
    );
  }

  double _decrementOvers(double currentOvers) {
    int oversInt = currentOvers.toInt();
    int ballsInt = ((currentOvers - oversInt) * 10).round();
    
    ballsInt -= 1;
    if (ballsInt < 0) {
      if (oversInt > 0) {
        oversInt -= 1;
        ballsInt = 5;
      } else {
        ballsInt = 0;
      }
    }
    
    return oversInt + (ballsInt / 10.0);
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final matchId = storage.activeScorerMatchId;
    
    if (matchId == null) {
      return const Scaffold(body: Center(child: Text('No active match')));
    }

    final match = storage.matches.firstWhere((m) => m.id == matchId);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Official Timeline Editor',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pause/Resume Match Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPaused ? 'Match Paused' : 'Match Active',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isPaused ? 'Status broadcasts halted' : 'Broadcasting real-time data...',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPaused = !_isPaused;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isPaused ? 'Match paused officially!' : 'Match resumed!')),
                      );
                    },
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? 'Resume' : 'Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaused ? AppTheme.primaryGreen : AppTheme.accentRed,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'BALL TIMELINE',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0x990F172A), letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: match.balls.isEmpty
                  ? Center(child: Text('No balls bowled in this innings yet.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)))
                  : ListView.builder(
                      itemCount: match.balls.length,
                      itemBuilder: (context, index) {
                        // Reverse so latest is on top
                        final revIdx = match.balls.length - 1 - index;
                        final ball = match.balls[revIdx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimary.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.04)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: ball.isWicket ? Colors.redAccent : AppTheme.primaryBlue,
                                radius: 18,
                                child: Text(
                                  ball.isWicket ? 'W' : '${ball.run}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bowler: ${ball.bowlerName} ➔ Batsman: ${ball.batsmanName}',
                                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 12),
                                    ),
                                    Text(
                                      ball.commentary,
                                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteBall(revIdx, match),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
