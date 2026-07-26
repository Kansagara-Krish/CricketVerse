import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';

class ScorerDashboard extends StatefulWidget {
  const ScorerDashboard({super.key});

  @override
  State<ScorerDashboard> createState() => _ScorerDashboardState();
}

class _ScorerDashboardState extends State<ScorerDashboard> with SingleTickerProviderStateMixin {
  String? _tossWinner;
  String _tossDecision = 'Bat';
  bool _isAutoCommentary = true;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = Provider.of<StorageService>(context, listen: false);
      if (storage.activeScorerMatchId != null) {
        storage.subscribeToMatchLiveUpdates(storage.activeScorerMatchId!);
      }
    });
  }

  @override
  void dispose() {
    final storage = Provider.of<StorageService>(context, listen: false);
    if (storage.activeScorerMatchId != null) {
      storage.unsubscribeFromMatchLiveUpdates(storage.activeScorerMatchId!);
    }
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

  void _logout() async {
    final confirm = await LogoutDialog.show(context);
    if (confirm == true && mounted) {
      Provider.of<StorageService>(context, listen: false).logout();
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
    }
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
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    radius: 22,
                    child: const Icon(Icons.sports_cricket_rounded, color: AppTheme.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Scorer',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Official Manager',
                        style: GoogleFonts.plusJakartaSans(
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
              
              // Online Mode Switcher
              Consumer<StorageService>(
                builder: (context, storage, _) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12, right: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              storage.isOnlineMode ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                              color: storage.isOnlineMode ? AppTheme.primaryGreen : AppTheme.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              storage.isOnlineMode ? 'Online Mode' : 'Offline Mode',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: storage.isOnlineMode,
                          activeThumbColor: AppTheme.primaryGreen,
                          onChanged: (val) {
                            storage.toggleOnlineMode(val);
                          },
                        ),
                      ],
                    ),
                  );
                }
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
        color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
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
                  style: GoogleFonts.plusJakartaSans(
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
      return _buildAssignedMatchesListView(storage);
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
                transform: Matrix4.translationValues(slide, 0.0, 0.0)
                  * Matrix4.diagonal3Values(scale, scale, 1.0),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
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
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () {
                    storage.setActiveScorerMatchId(null);
                  },
                ),
                title: Text(
                  _currentViewIndex == 0 ? 'Official Scorer Portal' : 'My Profile',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  if (_currentViewIndex == 0 && match.status == 'Live') ...[
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
                      tooltip: 'Reset Score to 0/0',
                      onPressed: () => _showResetConfirmation(context, storage, match.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: AppTheme.accentGold),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.editBall);
                      },
                    ),
                  ],
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

  // --- Assigned Matches Dashboard List View ---
  Widget _buildAssignedMatchesListView(StorageService storage) {
    final assignedMatches = storage.matches
        .where((m) => m.scorerUsername == storage.currentUserEmail)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Official Scorer Portal',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.accentRed),
            onPressed: _logout,
          ),
        ],
      ),
      body: assignedMatches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_cricket_rounded, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No Matches Assigned to You',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact administrator to get scoring matches.',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignedMatches.length,
              itemBuilder: (context, i) {
                final match = assignedMatches[i];
                final statusColor = AppTheme.statusColor(match.status);
                
                return CardEntranceAnimation(
                  index: i,
                  child: GestureDetector(
                    onTap: () {
                      storage.setActiveScorerMatchId(match.id);
                      CustomNotification.show(
                        context,
                        'Opened scoring for ${match.teamA.shortName} vs ${match.teamB.shortName}',
                        type: NotificationType.info,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  match.status == 'Live' ? '● LIVE' : match.status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: statusColor, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${match.matchType} • ${match.date}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    TeamLogo(
                                      teamName: match.teamA.name,
                                      shortName: match.teamA.shortName,
                                      logoColorHex: match.teamA.logoColorHex,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            match.teamA.shortName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                          ),
                                          if (match.status != 'Upcoming')
                                            Text('${match.runsA}/${match.wicketsA} (${match.oversA})', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text('VS', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            match.teamB.shortName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                          ),
                                          if (match.status != 'Upcoming')
                                            Text('${match.runsB}/${match.wicketsB} (${match.oversB})', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TeamLogo(
                                      teamName: match.teamB.name,
                                      shortName: match.teamB.shortName,
                                      logoColorHex: match.teamB.logoColorHex,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  match.venue,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Tap to open Scoring Portal',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.primaryBlue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
            radius: 36,
            child: const Icon(Icons.sports_cricket_rounded, color: AppTheme.primaryGreen, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Match Official Portal', style: GoogleFonts.plusJakartaSans(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          Text('scorer1@cricketverse.ai', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Text('Role: Match Official Manager', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
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
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED MATCH',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamA.name} vs ${match.teamB.name}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.matchType} • ${match.venue} • ${match.date} ${match.time}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Toss Configuration',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),

          Text('Toss Winner', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            initialValue: _tossWinner,
            decoration: InputDecoration(
              fillColor: Colors.black.withValues(alpha: 0.02),
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

          Text('Toss Decision', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            initialValue: _tossDecision,
            decoration: InputDecoration(
              fillColor: Colors.black.withValues(alpha: 0.02),
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
                textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
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
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 2.5, backgroundColor: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text('LIVE', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Large Score Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TeamLogo.fromTeam(battingTeam, size: 36),
                  const SizedBox(width: 10),
                  Text(
                    '${battingTeam.shortName} ',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '$runs/$wickets',
                    style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Overs: ${overs.toStringAsFixed(1)} (CRR: ${crr.toStringAsFixed(1)})',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildInteractiveRow(
                              context,
                              'Striker',
                              striker.name,
                              '🏏',
                              () => _showPlayerSelectionSheet(context, true, battingTeam.players, storage),
                              stats: '(${striker.runsScored} off ${striker.ballsFaced})',
                            ),
                            const Divider(height: 16),
                            _buildInteractiveRow(
                              context,
                              'Non-Striker',
                              nonStriker.name,
                              '🏃',
                              () => _showPlayerSelectionSheet(context, false, battingTeam.players, storage),
                              stats: '(${nonStriker.runsScored} off ${nonStriker.ballsFaced})',
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.swap_vert_rounded, color: AppTheme.primaryBlue),
                                onPressed: () {
                                  storage.swapStrikers();
                                  CustomNotification.show(context, 'Positions swapped', type: NotificationType.info);
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SWAP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.glassCard,
                  child: _buildInteractiveRow(
                    context,
                    'Active Bowler',
                    bowler.name,
                    '⚡',
                    () => _showBowlerSelectionSheet(context, bowlingTeam.players, storage),
                    stats: '(${bowler.oversBowled.toStringAsFixed(1)} ov • ${bowler.wicketsTaken}/${bowler.runsConceded})',
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
                    Expanded(child: _buildExtraBtn('Custom Extra...', Icons.add_moderator_rounded, () => _showCustomExtraDialog(storage))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _showWicketDialog(storage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.outbox_rounded, color: AppTheme.accentRed, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Record Wicket',
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.accentRed, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: match.balls.isEmpty
                            ? null
                            : () => _showUndoConfirmation(context, storage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: match.balls.isEmpty
                                ? Colors.black.withValues(alpha: 0.02)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: match.balls.isEmpty
                                  ? const Color(0xFFE2E8F0)
                                  : AppTheme.textSecondary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.undo_rounded,
                                color: match.balls.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Undo',
                                style: GoogleFonts.plusJakartaSans(
                                  color: match.balls.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAutoCommentary,
                        onChanged: (val) => setState(() => _isAutoCommentary = val),
                        activeThumbColor: AppTheme.primaryBlue,
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
                          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
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
                          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
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
    VoidCallback onTap, {
    String? stats,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      if (stats != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          stats,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              val,
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: col),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: isMaximum ? Colors.white70 : AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
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
      wicketType: isWicket ? 'Bowled' : 'None',
    );
    _postBallCheck(storage);
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
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        radius: 14,
                        child: Text(p.name.substring(0, 1), style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                      ),
                      title: Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      subtitle: Text(p.role, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                        backgroundColor: AppTheme.accentRed.withValues(alpha: 0.1),
                        radius: 14,
                        child: Text(p.name.substring(0, 1), style: const TextStyle(fontSize: 11, color: AppTheme.accentRed)),
                      ),
                      title: Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      subtitle: Text(p.role, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
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
    if (storage.activeScorerMatchId == null) return;
    final match = storage.matches.firstWhere((m) => m.id == storage.activeScorerMatchId);
    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final striker = battingTeam.players.firstWhere((p) => p.id == match.currentStrikerId, orElse: () => battingTeam.players[0]);
    final nonStriker = battingTeam.players.firstWhere((p) => p.id == match.currentNonStrikerId, orElse: () => battingTeam.players[1]);

    String dismissedId = striker.id;
    String wicketType = 'Bowled';

    // Helper to calculate remaining batsmen who have not yet batted
    List<Player> getRemainingBatsmen(CricketMatch match, Team battingTeam) {
      final Set<String> battedPlayerNames = {};
      for (var ball in match.balls) {
        battedPlayerNames.add(ball.batsmanName);
      }
      return battingTeam.players.where((p) {
        if (p.id == match.currentStrikerId || p.id == match.currentNonStrikerId) {
          return false;
        }
        if (battedPlayerNames.contains(p.name)) {
          return false;
        }
        return true;
      }).toList();
    }

    final candidates = getRemainingBatsmen(match, battingTeam);

    int currentStep = 1;
    String selectedIncomingId = candidates.isNotEmpty ? candidates[0].id : '';
    String selectedPosition = 'Striker';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WicketConfirmDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  // If striker dismissed is toggled, update position and default dismissal types accordingly
                  if (dismissedId == nonStriker.id && currentStep == 1) {
                    selectedPosition = 'Non-Striker';
                    if (!['Run Out', 'Hit Wicket', 'Retired Out', 'Retired Hurt'].contains(wicketType)) {
                      wicketType = 'Run Out';
                    }
                  } else if (dismissedId == striker.id && currentStep == 1) {
                    selectedPosition = 'Striker';
                  }

                  final List<String> dropdownItems = dismissedId == striker.id
                      ? ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket', 'Retired Out', 'Retired Hurt']
                      : ['Run Out', 'Hit Wicket', 'Retired Out', 'Retired Hurt'];

                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStep == 1 ? Icons.outbox_rounded : Icons.person_add_rounded,
                            color: AppTheme.accentRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          currentStep == 1 ? 'Record Wicket' : 'Incoming Batsman',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: 300,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: currentStep == 1
                            ? Column(
                                key: const ValueKey(1),
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WHICH BATTER IS OUT?',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setDialogState(() => dismissedId = striker.id),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: dismissedId == striker.id
                                                  ? AppTheme.accentRed.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: dismissedId == striker.id ? AppTheme.accentRed : const Color(0xFFE2E8F0),
                                                width: dismissedId == striker.id ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.sports_cricket_rounded, color: AppTheme.accentRed, size: 20),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Striker',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  striker.name,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setDialogState(() => dismissedId = nonStriker.id),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: dismissedId == nonStriker.id
                                                  ? AppTheme.accentRed.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: dismissedId == nonStriker.id ? AppTheme.accentRed : const Color(0xFFE2E8F0),
                                                width: dismissedId == nonStriker.id ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.directions_run_rounded, color: AppTheme.accentRed, size: 20),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Non-Striker',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  nonStriker.name,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'DISMISSAL TYPE',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                                    initialValue: wicketType,
                                    decoration: InputDecoration(
                                      fillColor: Colors.black.withValues(alpha: 0.02),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    items: dropdownItems.map((val) {
                                      return DropdownMenuItem(value: val, child: Text(val));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() => wicketType = val);
                                      }
                                    },
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey(2),
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SELECT NEW BATSMAN',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: candidates.length,
                                      itemBuilder: (ctx, idx) {
                                        final player = candidates[idx];
                                        final isSel = selectedIncomingId == player.id;
                                        return ListTile(
                                          dense: true,
                                          selected: isSel,
                                          selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.06),
                                          title: Text(
                                            player.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isSel ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                            ),
                                          ),
                                          subtitle: Text(player.role, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                                          trailing: isSel ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 18) : null,
                                          onTap: () {
                                            setDialogState(() {
                                              selectedIncomingId = player.id;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'BATSMAN POSITION',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: Text('Striker', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                          selected: selectedPosition == 'Striker',
                                          onSelected: (val) {
                                            if (val) setDialogState(() => selectedPosition = 'Striker');
                                          },
                                          selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                          labelStyle: TextStyle(color: selectedPosition == 'Striker' ? AppTheme.primaryBlue : AppTheme.textSecondary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: Text('Non-Striker', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                          selected: selectedPosition == 'Non-Striker',
                                          onSelected: (val) {
                                            if (val) setDialogState(() => selectedPosition = 'Non-Striker');
                                          },
                                          selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                          labelStyle: TextStyle(color: selectedPosition == 'Non-Striker' ? AppTheme.primaryBlue : AppTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (currentStep == 2) {
                            setDialogState(() => currentStep = 1);
                          } else {
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          currentStep == 2 ? 'Back' : 'Cancel',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (currentStep == 1) {
                            if (candidates.isEmpty) {
                              Navigator.pop(ctx);
                              storage.updateScore(
                                runs: 0,
                                extraType: 'None',
                                extraRuns: 0,
                                isWicket: true,
                                wicketType: wicketType,
                                dismissedPlayerId: dismissedId,
                              );
                              CustomNotification.show(
                                context,
                                'Wicket recorded. Team is All Out!',
                                type: NotificationType.error,
                              );
                              _postBallCheck(storage);
                            } else {
                              setDialogState(() => currentStep = 2);
                            }
                          } else {
                            Navigator.pop(ctx);
                            storage.updateScore(
                              runs: 0,
                              extraType: 'None',
                              extraRuns: 0,
                              isWicket: true,
                              wicketType: wicketType,
                              dismissedPlayerId: dismissedId,
                              newBatsmanId: selectedIncomingId,
                              newBatsmanPosition: selectedPosition,
                            );
                            final nextPlayerName = battingTeam.players.firstWhere((p) => p.id == selectedIncomingId).name;
                            CustomNotification.show(
                              context,
                              'Wicket recorded. Incoming batsman: $nextPlayerName ($selectedPosition)',
                              type: NotificationType.success,
                            );
                            _postBallCheck(storage);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text(
                          (currentStep == 1 && candidates.isNotEmpty) ? 'Next' : 'Confirm',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomExtraDialog(StorageService storage) {
    String extraType = 'Wide';
    int runs = 1;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ExtraRunsDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_moderator_rounded, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Record Extra Runs',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXTRA TYPE',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                          initialValue: extraType,
                          decoration: InputDecoration(
                            fillColor: Colors.black.withValues(alpha: 0.02),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Wide', child: Text('Wide')),
                            DropdownMenuItem(value: 'No Ball', child: Text('No Ball')),
                            DropdownMenuItem(value: 'Leg Bye', child: Text('Leg Bye')),
                            DropdownMenuItem(value: 'Bye', child: Text('Bye')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => extraType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'EXTRA RUNS',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3, 4, 5].map((r) {
                            final isSel = runs == r;
                            return GestureDetector(
                              onTap: () => setDialogState(() => runs = r),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primaryBlue : AppTheme.bgDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '+$r',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isSel ? Colors.white : AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          storage.updateScore(
                            runs: 0,
                            extraType: extraType,
                            extraRuns: runs,
                            isWicket: false,
                            wicketType: 'None',
                          );
                          CustomNotification.show(
                            context,
                            'Custom Extra recorded: $extraType +$runs',
                            type: NotificationType.success,
                          );
                          _postBallCheck(storage);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text('Confirm', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _postBallCheck(StorageService storage) {
    if (storage.activeScorerMatchId == null) return;
    final match = storage.matches.firstWhere((m) => m.id == storage.activeScorerMatchId);
    final overs = match.isFirstInnings ? match.oversA : match.oversB;

    if (overs > 0 && (overs * 10).round() % 10 == 0) {
      final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;
      _showOverCompletedDialog(context, bowlingTeam.players, storage, (overs).round());
    }
  }

  void _showOverCompletedDialog(
    BuildContext context,
    List<Player> players,
    StorageService storage,
    int overNumber,
  ) {
    String? selectedBowlerId;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'OverCompletedDialog',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Over $overNumber Completed',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: 300,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHOOSE BOWLER FOR NEXT OVER',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: players.length,
                              itemBuilder: (ctx, idx) {
                                final player = players[idx];
                                final isSel = selectedBowlerId == player.id;
                                return ListTile(
                                  dense: true,
                                  selected: isSel,
                                  selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.06),
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                    radius: 12,
                                    child: Text(player.name.substring(0, 1), style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue)),
                                  ),
                                  title: Text(
                                    player.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSel ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${player.role} • ${player.oversBowled.toStringAsFixed(1)} ov', 
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11)
                                  ),
                                  trailing: isSel ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 18) : null,
                                  onTap: () {
                                    setDialogState(() {
                                      selectedBowlerId = player.id;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: selectedBowlerId == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                storage.switchBowler(selectedBowlerId!);
                                final bowlerName = players.firstWhere((p) => p.id == selectedBowlerId).name;
                                CustomNotification.show(
                                  context,
                                  'Over $overNumber finished. New bowler: $bowlerName',
                                  type: NotificationType.success,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text('Confirm Bowler', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, StorageService storage, String matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Match?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to reset this match score to 0/0 and delete all balls?', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              storage.resetMatchToZero(matchId);
              CustomNotification.show(context, 'Match score reset to 0/0', type: NotificationType.success);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Reset', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUndoConfirmation(BuildContext context, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Undo Last Ball?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete the last scored ball and revert the stats?',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              storage.undoLastBall();
              CustomNotification.show(context, 'Last ball reverted', type: NotificationType.info);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Yes, Undo',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
