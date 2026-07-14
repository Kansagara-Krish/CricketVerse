import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'auth_screen.dart';
import 'scorer/edit_ball_screen.dart';
import '../core/theme/app_theme.dart';

class ScorerDashboard extends StatefulWidget {
  const ScorerDashboard({Key? key}) : super(key: key);

  @override
  State<ScorerDashboard> createState() => _ScorerDashboardState();
}

class _ScorerDashboardState extends State<ScorerDashboard> {
  String? _tossWinner;
  String _tossDecision = 'Bat';
  bool _isAutoCommentary = true;
  String _selectedWicketType = 'Bowled';

  void _logout() {
    Provider.of<StorageService>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final matchId = storage.activeScorerMatchId;
    
    if (matchId == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No Match Assigned', style: TextStyle(color: const Color(0xFF0F172A), fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _logout, child: const Text('Logout')),
            ],
          ),
        ),
      );
    }

    final match = storage.matches.firstWhere((m) => m.id == matchId);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 2,
        title: Text(
          'Match Official Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        actions: [
          if (match?.status == 'Live')
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.amber),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditBallScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: match?.status == 'Upcoming'
          ? _buildSetupView(match, storage)
          : _buildScoringView(match, storage),
    );
  }

  // --- Match Setup View (Toss & Starting Lineup) ---
  Widget _buildSetupView(CricketMatch match, StorageService storage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Match',
                  style: GoogleFonts.outfit(color: const Color(0x8A0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamA.name} vs ${match.teamB.name}',
                  style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.matchType} • ${match.venue} • ${match.date} ${match.time}',
                  style: GoogleFonts.outfit(color: const Color(0xDE0F172A), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Toss Configuration',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),

          Text('Toss Winner', style: GoogleFonts.outfit(color: const Color(0xDE0F172A), fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
            value: _tossWinner,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              DropdownMenuItem(value: match.teamA.name, child: Text(match.teamA.name)),
              DropdownMenuItem(value: match.teamB.name, child: Text(match.teamB.name)),
            ],
            onChanged: (val) => setState(() => _tossWinner = val),
            hint: const Text('Select Toss Winner', style: TextStyle(color: const Color(0x4D0F172A))),
          ),
          const SizedBox(height: 16),

          Text('Toss Decision', style: GoogleFonts.outfit(color: const Color(0xDE0F172A), fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
            value: _tossDecision,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'Bat', child: Text('Choose to Bat')),
              DropdownMenuItem(value: 'Bowl', child: Text('Choose to Bowl')),
            ],
            onChanged: (val) => setState(() => _tossDecision = val ?? 'Bat'),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_tossWinner == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select the toss winner!')),
                  );
                  return;
                }
                
                // Determine who bats first
                String firstBattingId;
                if (_tossWinner == match.teamA.name) {
                  firstBattingId = _tossDecision == 'Bat' ? match.teamA.id : match.teamB.id;
                } else {
                  firstBattingId = _tossDecision == 'Bat' ? match.teamB.id : match.teamA.id;
                }

                storage.startMatchSetup(match.id, _tossWinner!, _tossDecision, firstBattingId);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Match & Playing XI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Ball-by-ball Live Scoring View ---
  Widget _buildScoringView(CricketMatch match, StorageService storage) {
    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    final striker = battingTeam.players.firstWhere((p) => p.id == match.currentStrikerId, orElse: () => battingTeam.players[0]);
    final nonStriker = battingTeam.players.firstWhere((p) => p.id == match.currentNonStrikerId, orElse: () => battingTeam.players[1]);
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == match.currentBowlerId, orElse: () => bowlingTeam.players[bowlingTeam.players.length - 1]);

    final runs = match.isFirstInnings ? match.runsA : match.runsB;
    final wickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    final overs = match.isFirstInnings ? match.oversA : match.oversB;
    final crr = overs > 0 ? (runs / overs) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Score Header matches Screenshot 2026-07-09 152155.png
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgMedium,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${match.teamA.shortName} vs ${match.teamB.shortName} - ${match.matchType}',
                      style: GoogleFonts.outfit(color: const Color(0xDE0F172A), fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 3, backgroundColor: const Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text('LIVE', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Large Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${battingTeam.shortName} ',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xDE0F172A)),
                    ),
                    Text(
                      '$runs/$wickets',
                      style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Overs: ${overs.toStringAsFixed(1)} (CRR: ${crr.toStringAsFixed(1)})',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x990F172A)),
                ),
                const SizedBox(height: 16),

                // Batters box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${striker.name}*', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('${nonStriker.name}', style: GoogleFonts.outfit(color: const Color(0x990F172A), fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Bowler: ${bowler.name}', style: GoogleFonts.outfit(color: const Color(0xDE0F172A), fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('Overs: ${bowler.oversBowled.toStringAsFixed(1)}', style: GoogleFonts.outfit(color: const Color(0x8A0F172A), fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Run buttons grid (0, 1, 2, 3, 4, 6) matching Screenshot 2026-07-09 152155.png
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildScoreBtn('0', 'Dot', const Color(0xFF64748B), () => _scoreBall(storage, 0, 'None', 0, false)),
              _buildScoreBtn('1', 'Run', const Color(0xFF0F172A), () => _scoreBall(storage, 1, 'None', 0, false)),
              _buildScoreBtn('2', 'Runs', const Color(0xFF0F172A), () => _scoreBall(storage, 2, 'None', 0, false)),
              _buildScoreBtn('3', 'Runs', const Color(0xFF0F172A), () => _scoreBall(storage, 3, 'None', 0, false)),
              _buildScoreBtn('4', 'Boundary', const Color(0xFFD97706), () => _scoreBall(storage, 4, 'None', 0, false)),
              _buildScoreBtn('6', 'Maximum', Colors.white, () => _scoreBall(storage, 6, 'None', 0, false), isMaximum: true),
            ],
          ),
          const SizedBox(height: 16),

          // Extras and wicket buttons row
          Row(
            children: [
              Expanded(child: _buildExtraBtn('Wide', Icons.compare_arrows, () => _scoreBall(storage, 0, 'Wide', 1, false))),
              const SizedBox(width: 8),
              Expanded(child: _buildExtraBtn('No Ball', Icons.sports_baseball, () => _scoreBall(storage, 0, 'No Ball', 1, false))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildExtraBtn('Leg Bye', Icons.directions_walk, () => _scoreBall(storage, 0, 'Leg Bye', 1, false))),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showWicketDialog(storage),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.outbox, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Wicket',
                          style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggle auto comment
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF0284C7)),
                    const SizedBox(width: 12),
                    Text(
                      'Auto-Gen AI Commentary',
                      style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Switch(
                  value: _isAutoCommentary,
                  onChanged: (val) {
                    setState(() {
                      _isAutoCommentary = val;
                    });
                  },
                  activeColor: const Color(0xFF0284C7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions: End Over, Innings / Match
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    storage.endOver();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Over Finished. Strike Rotated.')),
                    );
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('End Over'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    storage.endInningsOrMatch();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(match.isFirstInnings ? 'Match Ended!' : 'Innings Switched! Target set.')),
                    );
                  },
                  icon: const Icon(Icons.sports),
                  label: Text(match.isFirstInnings ? 'End Innings' : 'End Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBtn(String val, String sub, Color col, VoidCallback onTap, {bool isMaximum = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isMaximum ? const Color(0xFF1E3A8A) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              val,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: col),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.outfit(fontSize: 10, color: const Color(0x4D0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0x990F172A), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(color: const Color(0xDE0F172A), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _scoreBall(StorageService storage, int runs, String extraType, int extraRuns, bool isWicket) {
    storage.updateScore(
      runs: runs,
      extraType: extraType,
      extraRuns: extraRuns,
      isWicket: isWicket,
      wicketType: isWicket ? _selectedWicketType : 'None',
    );
  }

  void _showWicketDialog(StorageService storage) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Select Wicket Type', style: TextStyle(color: Color(0xFF0F172A))),
              content: DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF0F172A)),
                value: _selectedWicketType,
                items: const [
                  DropdownMenuItem(value: 'Bowled', child: Text('Bowled')),
                  DropdownMenuItem(value: 'Caught', child: Text('Caught')),
                  DropdownMenuItem(value: 'LBW', child: Text('LBW')),
                  DropdownMenuItem(value: 'Run Out', child: Text('Run Out')),
                ],
                onChanged: (val) {
                  setDialogState(() {
                    _selectedWicketType = val ?? 'Bowled';
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xDE0F172A))),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _scoreBall(storage, 0, 'None', 0, true);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
