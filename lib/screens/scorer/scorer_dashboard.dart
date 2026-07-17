import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';

class ScorerDashboard extends StatefulWidget {
  const ScorerDashboard({Key? key}) : super(key: key);

  @override
  State<ScorerDashboard> createState() => _ScorerDashboardState();
}

class _ScorerDashboardState extends State<ScorerDashboard> with SingleTickerProviderStateMixin {
  String? _tossWinner;
  String _tossDecision = 'Bat';
  bool _isAutoCommentary = true;
  String _selectedWicketType = 'Bowled';
  int _currentViewIndex = 0; // 0: Live Scoring, 1: Profile

  late AnimationController _drawerAnimationController;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerAnimationController.forward();
      } else {
        _drawerAnimationController.reverse();
      }
    });
  }

  void _logout() {
    Provider.of<StorageService>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, AppRoutes.auth);
  }

  Widget _buildMenuDrawer(BuildContext context, CricketMatch? match) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                    radius: 22,
                    child: const Icon(Icons.sports_cricket_rounded, color: AppTheme.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Scorer',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Official Manager',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Menu Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.dashboard_rounded, 'Dashboard', () {
                        setState(() => _currentViewIndex = 0);
                        _toggleDrawer();
                      }, isSelected: _currentViewIndex == 0),
                      _buildMenuItem(Icons.assignment_turned_in_rounded, 'Assigned Matches', () {
                        _toggleDrawer();
                        if (match != null) {
                          CustomNotification.show(
                            context,
                            'Active Match: ${match.teamA.shortName} vs ${match.teamB.shortName}',
                            type: NotificationType.info,
                          );
                        } else {
                          CustomNotification.show(
                            context,
                            'No match currently assigned.',
                            type: NotificationType.warning,
                          );
                        }
                      }),
                      _buildMenuItem(Icons.offline_bolt_rounded, 'Live Scoring', () {
                        setState(() => _currentViewIndex = 0);
                        _toggleDrawer();
                        if (match == null || match.status != 'Live') {
                          CustomNotification.show(
                            context,
                            'No active live match to score. Set up toss first.',
                            type: NotificationType.warning,
                          );
                        }
                      }),
                      _buildMenuItem(Icons.comment_bank_rounded, 'Commentary', () {
                        _toggleDrawer();
                        if (match != null) {
                          Navigator.pushNamed(context, AppRoutes.aiCommentary, arguments: match);
                        } else {
                          CustomNotification.show(
                            context,
                            'Start a match to view AI Commentary.',
                            type: NotificationType.warning,
                          );
                        }
                      }),
                      _buildMenuItem(Icons.bar_chart_rounded, 'Statistics', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.statistics);
                      }),
                      _buildMenuItem(Icons.notifications_rounded, 'Notifications', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.notifications);
                      }),
                      _buildMenuItem(Icons.person_rounded, 'Profile', () {
                        setState(() => _currentViewIndex = 1);
                        _toggleDrawer();
                      }, isSelected: _currentViewIndex == 1),
                    ],
                  ),
                ),
              ),
              
              // Logout
              _buildMenuItem(Icons.logout_rounded, 'Logout', () {
                _toggleDrawer();
                _logout();
              }, isLogout: true),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
    bool isLogout = false,
  }) {
    final color = isLogout
        ? const Color(0xFFEF4444)
        : (isSelected ? AppTheme.primaryBlue : Colors.white70);
        
    return Container(
      margin: const EdgeInsets.only(bottom: 6, right: 40),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              const Text('No Match Assigned', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _logout, child: const Text('Logout')),
            ],
          ),
        ),
      );
    }

    final match = storage.matches.firstWhere((m) => m.id == matchId);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Drawer menu
          _buildMenuDrawer(context, match),
          
          // Dashboard Body Zoom animation
          AnimatedBuilder(
            animation: _drawerAnimationController,
            builder: (context, child) {
              final double scale = 1.0 - (_drawerAnimationController.value * 0.12);
              final double slide = _drawerAnimationController.value * 230.0;
              final double radius = _drawerAnimationController.value * 20.0;
              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: Scaffold(
              backgroundColor: AppTheme.bgDark,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _drawerAnimationController,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: _toggleDrawer,
                ),
                title: Text(
                  _currentViewIndex == 0 ? 'Official Scorer Portal' : 'My Profile',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  if (_currentViewIndex == 0 && match.status == 'Live')
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: AppTheme.accentGold),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.editBall);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppTheme.accentRed),
                    onPressed: _logout,
                  ),
                ],
              ),
              body: _currentViewIndex == 1
                  ? _buildProfileView()
                  : (match.status == 'Upcoming'
                      ? _buildSetupView(match, storage)
                      : _buildScoringView(match, storage)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Profile View ---
  Widget _buildProfileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
            radius: 36,
            child: const Icon(Icons.sports_cricket_rounded, color: AppTheme.primaryGreen, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Match Official Portal', style: GoogleFonts.outfit(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          Text('scorer1@cricketverse.ai', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Text('Role: Match Official Manager', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
        ],
      ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 6,
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED MATCH',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamA.name} vs ${match.teamB.name}',
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.matchType} • ${match.venue} • ${match.date} ${match.time}',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Toss Configuration',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),

          Text('Toss Winner', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
            value: _tossWinner,
            decoration: InputDecoration(
              fillColor: Colors.black.withOpacity(0.02),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              DropdownMenuItem(value: match.teamA.name, child: Text(match.teamA.name)),
              DropdownMenuItem(value: match.teamB.name, child: Text(match.teamB.name)),
            ],
            onChanged: (val) => setState(() => _tossWinner = val),
            hint: const Text('Select Toss Winner', style: TextStyle(color: Colors.black38)),
          ),
          const SizedBox(height: 16),

          Text('Toss Decision', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
            value: _tossDecision,
            decoration: InputDecoration(
              fillColor: Colors.black.withOpacity(0.02),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_tossWinner == null) {
                  CustomNotification.show(
                    context,
                    'Please select the toss winner!',
                    type: NotificationType.warning,
                  );
                  return;
                }
                
                String firstBattingId;
                if (_tossWinner == match.teamA.name) {
                  firstBattingId = _tossDecision == 'Bat' ? match.teamA.id : match.teamB.id;
                } else {
                  firstBattingId = _tossDecision == 'Bat' ? match.teamB.id : match.teamA.id;
                }

                storage.startMatchSetup(match.id, _tossWinner!, _tossDecision, firstBattingId);
                CustomNotification.show(
                  context,
                  'Match started successfully! Playing XIs initialized.',
                  type: NotificationType.success,
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start Match & Lineups'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
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

    return Column(
      children: [
        // 1. Sticky Scoreboard Panel (does not scroll)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${match.teamA.shortName} vs ${match.teamB.shortName} - ${match.matchType}',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 2.5, backgroundColor: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text('LIVE', style: GoogleFonts.outfit(color: AppTheme.primaryGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Large Score Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${battingTeam.shortName} ',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '$runs/$wickets',
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Overs: ${overs.toStringAsFixed(1)} (CRR: ${crr.toStringAsFixed(1)})',
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // 2. Scrollable Scoring Controls
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Batsmen & Bowler interactive selector card (Minimum Taps)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      _buildInteractiveRow(
                        context,
                        'Striker',
                        striker.name,
                        '🏏',
                        () => _showPlayerSelectionSheet(context, true, battingTeam.players, storage),
                      ),
                      const Divider(height: 16),
                      _buildInteractiveRow(
                        context,
                        'Non-Striker',
                        nonStriker.name,
                        '🏃',
                        () => _showPlayerSelectionSheet(context, false, battingTeam.players, storage),
                      ),
                      const Divider(height: 16),
                      _buildInteractiveRow(
                        context,
                        'Active Bowler',
                        bowler.name,
                        '⚡',
                        () => _showBowlerSelectionSheet(context, bowlingTeam.players, storage),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Large Run Buttons Grid (0, 1, 2, 3, 4, 6)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _buildScoreBtn('0', 'Dot', AppTheme.textSecondary, () => _scoreBall(storage, 0, 'None', 0, false)),
                    _buildScoreBtn('1', 'Single', AppTheme.textPrimary, () => _scoreBall(storage, 1, 'None', 0, false)),
                    _buildScoreBtn('2', 'Double', AppTheme.textPrimary, () => _scoreBall(storage, 2, 'None', 0, false)),
                    _buildScoreBtn('3', 'Triple', AppTheme.textPrimary, () => _scoreBall(storage, 3, 'None', 0, false)),
                    _buildScoreBtn('4', 'Boundary', const Color(0xFFD97706), () => _scoreBall(storage, 4, 'None', 0, false)),
                    _buildScoreBtn('6', 'Maximum', Colors.white, () => _scoreBall(storage, 6, 'None', 0, false), isMaximum: true),
                  ],
                ),
                const SizedBox(height: 14),

                // Extras & Wickets (Pill Buttons)
                Row(
                  children: [
                    Expanded(child: _buildExtraBtn('Wide (+1)', Icons.compare_arrows_rounded, () => _scoreBall(storage, 0, 'Wide', 1, false))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildExtraBtn('No Ball (+1)', Icons.sports_baseball_rounded, () => _scoreBall(storage, 0, 'No Ball', 1, false))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildExtraBtn('Leg Bye (+1)', Icons.directions_walk_rounded, () => _scoreBall(storage, 0, 'Leg Bye', 1, false))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showWicketDialog(storage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentRed.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.outbox_rounded, color: AppTheme.accentRed, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Wicket',
                                style: GoogleFonts.outfit(color: AppTheme.accentRed, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Toggle Auto Commentary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'AI Commentary Generator',
                            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAutoCommentary,
                        onChanged: (val) => setState(() => _isAutoCommentary = val),
                        activeColor: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Actions: End Over, Innings / Match
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          storage.endOver();
                          CustomNotification.show(
                            context,
                            'Over completed. Strike rotated.',
                            type: NotificationType.success,
                          );
                        },
                        icon: const Icon(Icons.rotate_right_rounded, size: 16),
                        label: const Text('End Over'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          storage.endInningsOrMatch();
                          CustomNotification.show(
                            context,
                            match.isFirstInnings ? 'Match Ended!' : 'Innings Switched! Target updated.',
                            type: NotificationType.success,
                          );
                        },
                        icon: const Icon(Icons.sports_cricket_rounded, size: 16),
                        label: Text(match.isFirstInnings ? 'End Innings' : 'End Match'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveRow(
    BuildContext context,
    String label,
    String name,
    String icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBtn(String val, String sub, Color col, VoidCallback onTap, {bool isMaximum = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isMaximum ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              val,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: col),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: GoogleFonts.outfit(fontSize: 9.5, color: isMaximum ? Colors.white70 : AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 15),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
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

  void _showPlayerSelectionSheet(
    BuildContext context,
    bool isStriker,
    List<Player> players,
    StorageService storage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStriker ? 'Select New Striker' : 'Select New Non-Striker',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) {
                    final p = players[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        radius: 14,
                        child: Text(p.name.substring(0, 1), style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                      ),
                      title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      subtitle: Text(p.role, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
                      onTap: () {
                        if (isStriker) {
                          storage.setStriker(p.id);
                        } else {
                          storage.setNonStriker(p.id);
                        }
                        Navigator.pop(ctx);
                        CustomNotification.show(context, '${p.name} set as ${isStriker ? "Striker" : "Non-Striker"}', type: NotificationType.info);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBowlerSelectionSheet(
    BuildContext context,
    List<Player> players,
    StorageService storage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Active Bowler',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) {
                    final p = players[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accentRed.withOpacity(0.1),
                        radius: 14,
                        child: Text(p.name.substring(0, 1), style: const TextStyle(fontSize: 11, color: AppTheme.accentRed)),
                      ),
                      title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      subtitle: Text(p.role, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
                      onTap: () {
                        storage.switchBowler(p.id);
                        Navigator.pop(ctx);
                        CustomNotification.show(context, 'Bowler switched to ${p.name}', type: NotificationType.info);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
              title: Text('Record Wicket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
              content: DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                value: _selectedWicketType,
                decoration: InputDecoration(
                  fillColor: Colors.black.withOpacity(0.02),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
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
                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _scoreBall(storage, 0, 'None', 0, true);
                    CustomNotification.show(context, 'Wicket recorded: $_selectedWicketType', type: NotificationType.error);
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
