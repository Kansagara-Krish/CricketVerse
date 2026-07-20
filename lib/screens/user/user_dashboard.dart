import 'dart:ui';
import '../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import 'match_details_screen.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/widgets/custom_notification.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0; // Default to Home
  String _selectedFilter = 'Live'; // 'Live', 'Upcoming', 'Completed'
  String _schedulesSubTab = 'Matches';

  // Interactive Popup States
  final Set<String> _favTeamIds = {'uvpce_titans'};
  bool _notifMatchStart = true;
  bool _notifWickets = true;
  bool _notifCommentary = false;
  String _themeMode = 'Light';

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    // Filtered matches
    final filteredMatches = storage.matches.where((m) => m.status == _selectedFilter).toList();

    final List<Widget> views = [
      _buildHomeView(storage, filteredMatches),
      _buildSchedulesView(storage),
      _buildAIWinPredictionView(storage),
      _buildLiveRedirectView(storage),
      _buildProfileView(storage),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: views[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.bgSurface, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 3) {
              final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
              if (liveMatches.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.userMatchDetails,
                  arguments: liveMatches.first.id,
                );
              } else {
                CustomNotification.show(
                  context,
                  'No active Live match right now.',
                  type: NotificationType.warning,
                );
              }
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF854D0E), // Gold-brown selection matching screenshot
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_cricket_outlined), activeIcon: Icon(Icons.sports_cricket), label: 'Matches'),
            BottomNavigationBarItem(icon: Icon(Icons.online_prediction_outlined), activeIcon: Icon(Icons.online_prediction), label: 'Prediction'),
            BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // --- View 1: Fan Home View ---
  Widget _buildHomeView(StorageService storage, List<CricketMatch> matchesList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Alex
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      Text(
                        'Hello, Alex',
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppTheme.textPrimary),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search teams, players, matches...',
                      hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                const Icon(Icons.mic, color: AppTheme.textSecondary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filters row
          Row(
            children: ['Live', 'Upcoming', 'Completed'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: const Color(0xFF094CB2),
                  backgroundColor: AppTheme.bgDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.bgSurface),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Match List
          matchesList.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.bgSurface),
                  ),
                  child: Center(
                    child: Text(
                      'No $_selectedFilter matches found.',
                      style: GoogleFonts.outfit(color: AppTheme.textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchesList.length,
                  itemBuilder: (context, index) {
                    final match = matchesList[index];
                    return CardEntranceAnimation(
                      index: index,
                      child: _buildMatchCard(match, storage),
                    );
                  },
                ),
          const SizedBox(height: 24),

          // Trending Players Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Players',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text('View all', style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: AppTheme.primaryBlue, size: 14),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CardEntranceAnimation(index: 0, child: _buildPlayerTrendCard('Aarav Patel', 'Batter • UVP-TT', 'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?q=80&w=120&auto=format&fit=crop', Icons.sports_cricket, AppTheme.accentGold)),
                CardEntranceAnimation(index: 1, child: _buildPlayerTrendCard('Advik Shah', 'Bowler • UVP-WR', 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120&auto=format&fit=crop', Icons.circle, AppTheme.primaryGreen)),
                CardEntranceAnimation(index: 2, child: _buildPlayerTrendCard('Ishaan Mehta', 'All-rounder • UVP-LG', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=120&auto=format&fit=crop', Icons.trending_up, AppTheme.primaryBlue)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Latest Updates Section
          Text(
            'Latest Updates',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1540747737956-378724044282?q=80&w=150&auto=format&fit=crop',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.bgSurface,
                      child: const Icon(Icons.sports_cricket, color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANALYSIS',
                        style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How AI predicted the live win probability swing during final over.',
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(CricketMatch match, StorageService storage) {
    final winProb = storage.calculateWinProbability(match);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.userMatchDetails,
          arguments: match.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F2FE), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFBAE6FD)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ICC WORLD CUP 2024',
                  style: GoogleFonts.outfit(color: const Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.status == 'Live'
                        ? const Color(0xFFFEE2E2)
                        : AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: match.status == 'Live' ? Colors.redAccent : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: match.status == 'Live' ? Colors.redAccent : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

             // Live score team representation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    TeamLogo(
                      teamName: match.teamA.name,
                      shortName: match.teamA.shortName,
                      logoColorHex: match.teamA.logoColorHex,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(match.teamA.shortName, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    if (match.status != 'Upcoming') ...[
                      const SizedBox(height: 4),
                      Text('${match.runsA}/${match.wicketsA}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('(${match.oversA} ov)', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text('Yet to play', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ],
                ),
                Column(
                  children: [
                    Text('VS', style: GoogleFonts.outfit(color: const Color(0xFF0369A1), fontSize: 18, fontWeight: FontWeight.bold)),
                    if (match.status == 'Live')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CRR ${(match.oversA > 0 ? (match.runsA / match.oversA) : 0.0).toStringAsFixed(1)}',
                          style: GoogleFonts.outfit(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    TeamLogo(
                      teamName: match.teamB.name,
                      shortName: match.teamB.shortName,
                      logoColorHex: match.teamB.logoColorHex,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(match.teamB.shortName, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    if (match.status == 'Live') ...[
                      const SizedBox(height: 4),
                      Text('Yet to bat', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
                    ] else if (match.status == 'Completed') ...[
                      const SizedBox(height: 4),
                      Text('${match.runsB}/${match.wicketsB}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('(${match.oversB} ov)', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text('Yet to play', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Footer of card matching Screenshot
            const Divider(color: Color(0xFFBAE6FD)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${match.teamA.players.isNotEmpty ? match.teamA.players[0].name.split(" ").first : "Aarav"} 42*(28)',
                  style: GoogleFonts.outfit(color: const Color(0xFF0369A1), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.primaryBlue, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      'AI Predicts: ${match.teamA.shortName} ${winProb.toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTrendCard(String name, String role, String imgUrl, IconData badgeIcon, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 90,
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.network(
                  imgUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: AppTheme.bgSurface,
                    child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, size: 10, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name, 
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role, 
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10), 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- View 2: Schedules ---
  Widget _buildSchedulesView(StorageService storage) {
    final subTabs = ['Tournaments', 'Matches', 'Teams', 'Players'];
    
    int itemCount = 0;
    if (_schedulesSubTab == 'Matches') {
      itemCount = storage.matches.length;
    } else if (_schedulesSubTab == 'Tournaments') {
      itemCount = 5;
    } else if (_schedulesSubTab == 'Teams') {
      itemCount = storage.teams.length;
    } else if (_schedulesSubTab == 'Players') {
      itemCount = storage.teams.fold<int>(0, (sum, team) => sum + team.players.length);
    }

    final allPlayersList = storage.teams.expand((t) => t.players.map((p) => _PlayerWithTeam(p, t))).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournaments & Matches', 
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subTabs.length,
              itemBuilder: (context, idx) {
                final tab = subTabs[idx];
                final isSelected = _schedulesSubTab == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _schedulesSubTab = tab;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF854D0E) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF854D0E) : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (_schedulesSubTab == 'Matches') {
                  final match = storage.matches[index];
                  return CardEntranceAnimation(
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.bgSurface),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.userMatchDetails,
                            arguments: match.id,
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TeamLogo(
                              teamName: match.teamA.name,
                              shortName: match.teamA.shortName,
                              logoColorHex: match.teamA.logoColorHex,
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            TeamLogo(
                              teamName: match.teamB.name,
                              shortName: match.teamB.shortName,
                              logoColorHex: match.teamB.logoColorHex,
                              size: 28,
                            ),
                          ],
                        ),
                        title: Text('${match.teamA.name} vs ${match.teamB.name}', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text('${match.venue} • ${match.date} ${match.time}', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                        trailing: Text(
                          match.status, 
                          style: GoogleFonts.outfit(
                            color: match.status == 'Live' ? Colors.redAccent : const Color(0xFF854D0E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (_schedulesSubTab == 'Tournaments') {
                  final t = [
                    {'name': 'T20 World Cup 2026', 'format': 'T20', 'teams': '16', 'status': 'Live', 'start': '01-07-2026', 'end': '30-07-2026', 'matches': '45'},
                    {'name': 'IPL Season 19', 'format': 'T20', 'teams': '10', 'status': 'Upcoming', 'start': '01-09-2026', 'end': '30-11-2026', 'matches': '74'},
                    {'name': 'CricketVerse Premier League', 'format': 'T20', 'teams': '8', 'status': 'Upcoming', 'start': '15-08-2026', 'end': '14-09-2026', 'matches': '28'},
                    {'name': 'India-Australia Bilateral ODI', 'format': 'ODI', 'teams': '2', 'status': 'Completed', 'start': '01-06-2026', 'end': '20-06-2026', 'matches': '5'},
                    {'name': 'Asia Cup 2026', 'format': 'ODI', 'teams': '6', 'status': 'Upcoming', 'start': '01-10-2026', 'end': '20-10-2026', 'matches': '13'},
                  ][index];
                  return CardEntranceAnimation(
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.bgSurface),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.tournamentDetail,
                            arguments: t,
                          );
                        },
                        leading: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentPurple),
                        title: Text(t['name']!, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text('${t['teams']} Teams • ${t['matches']} Matches • ${t['format']}', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11.5)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusColor(t['status']!).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(t['status']!, style: GoogleFonts.outfit(color: AppTheme.statusColor(t['status']!), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  );
                } else if (_schedulesSubTab == 'Teams') {
                  final team = storage.teams[index];
                  return CardEntranceAnimation(
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.bgSurface),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.userTeamDetails,
                            arguments: team,
                          );
                        },
                        leading: TeamLogo(teamName: team.name, shortName: team.shortName, logoColorHex: team.logoColorHex, size: 28),
                        title: Text(team.name, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text('${team.players.length} Players • ${team.shortName}', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11.5)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ),
                    ),
                  );
                } else {
                  final item = allPlayersList[index];
                  final player = item.player;
                  final team = item.team;
                  return CardEntranceAnimation(
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.bgSurface),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.userPlayerDetails,
                            arguments: player,
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7).withOpacity(0.15),
                          child: Text(player.name.substring(0, 1), style: TextStyle(color: Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(player.name, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text('${player.role} • ${team.shortName}', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11.5)),
                        trailing: Text('${player.runsScored} runs', style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- View 3: Win predictions dashboard ---
  Widget _buildAIWinPredictionView(StorageService storage) {
    final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
    if (liveMatches.isEmpty) {
      return Center(
        child: Text(
          'No active Live matches for AI analytics.',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
        ),
      );
    }
    final match = liveMatches.first;
    final winProb = storage.calculateWinProbability(match);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Header
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TeamLogo(
                      teamName: match.teamA.name,
                      shortName: match.teamA.shortName,
                      logoColorHex: match.teamA.logoColorHex,
                      size: 40,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: const Text('VS', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TeamLogo(
                      teamName: match.teamB.name,
                      shortName: match.teamB.shortName,
                      logoColorHex: match.teamB.logoColorHex,
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(match.teamA.shortName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(width: 20),
                    Text(match.teamB.shortName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Finals • Wankhede Stadium',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // WIN PROBABILITY CIRCULAR CHARTS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              children: [
                Text(
                  'Win Probability',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: winProb / 100.0,
                        strokeWidth: 12,
                        backgroundColor: AppTheme.bgSurface,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${winProb.toStringAsFixed(0)}%', 
                          style: GoogleFonts.outfit(fontSize: 38, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                        Text(
                          'AI CONFIDENCE', 
                          style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${winProb.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        Text(match.teamA.shortName, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(100 - winProb).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        Text(match.teamB.shortName, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PROJECTED SCORE CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Color(0xFF854D0E), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Projected Score',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(match.teamA.shortName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 100,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '175-190',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(match.teamB.shortName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '160-175',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // MOMENTUM CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Momentum',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: MomentumLinePainter(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- View 4: Live redirect button ---
  Widget _buildLiveRedirectView(StorageService storage) {
    final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
    if (liveMatches.isEmpty) {
      return const Center(child: Text('No active Live match right now.', style: TextStyle(color: AppTheme.textPrimary)));
    }
    return MatchDetailsScreen(matchId: liveMatches.first.id);
  }

  // --- View 5: Profile & Settings ---
  Widget _buildProfileView(StorageService storage) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'),
          ),
          const SizedBox(height: 16),
          Text(
            'Alex',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            storage.currentUserEmail ?? 'guest@cricketverse.ai',
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          
          _buildProfileTile(Icons.favorite_border, 'Favorite Teams', () => _showFavoriteTeamsDialog(storage)),
          _buildProfileTile(Icons.notifications_none, 'Notification Settings', () => _showNotificationSettingsDialog()),
          _buildProfileTile(Icons.palette_outlined, 'Choose Theme ($_themeMode)', () => _showThemeChooserDialog()),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await LogoutDialog.show(context);
                if (confirm == true) {
                  storage.logout();
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.auth,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.accentRed),
              label: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: AppTheme.accentRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.bgSurface),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryBlue),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Feature Dialogs ---

  void _showFavoriteTeamsDialog(StorageService storage) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'FavoriteTeamsDialog',
      barrierColor: Colors.black.withOpacity(0.55),
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
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.favorite, color: AppTheme.accentRed, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Favorite Teams',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: storage.teams.length,
                          itemBuilder: (context, i) {
                            final team = storage.teams[i];
                            final isFav = _favTeamIds.contains(team.id);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: TeamLogo.fromTeam(team, size: 36),
                              title: Text(team.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                              trailing: IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? AppTheme.accentRed : AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    if (isFav) {
                                      _favTeamIds.remove(team.id);
                                    } else {
                                      _favTeamIds.add(team.id);
                                    }
                                  });
                                  setState(() {}); // Refresh user dashboard
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNotificationSettingsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotificationSettingsDialog',
      barrierColor: Colors.black.withOpacity(0.55),
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
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: AppTheme.primaryBlue, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Notification Settings',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwitchListTile(
                            title: Text('Match Alerts', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Get notified when matches start', style: GoogleFonts.outfit(fontSize: 11)),
                            value: _notifMatchStart,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setDialogState(() => _notifMatchStart = val);
                              setState(() {});
                            },
                          ),
                          SwitchListTile(
                            title: Text('Wicket Alerts', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Instantly receive live wicket updates', style: GoogleFonts.outfit(fontSize: 11)),
                            value: _notifWickets,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setDialogState(() => _notifWickets = val);
                              setState(() {});
                            },
                          ),
                          SwitchListTile(
                            title: Text('Audio Commentary', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Auto-read live commentary feeds', style: GoogleFonts.outfit(fontSize: 11)),
                            value: _notifCommentary,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setDialogState(() => _notifCommentary = val);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showThemeChooserDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ThemeChooserDialog',
      barrierColor: Colors.black.withOpacity(0.55),
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
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.palette, color: AppTheme.accentPurple, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Choose Theme',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Light', 'Dark', 'System Default'].map((theme) {
                          return RadioListTile<String>(
                            title: Text(theme, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: theme,
                            groupValue: _themeMode,
                            activeColor: AppTheme.accentPurple,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => _themeMode = val);
                                setState(() {});
                                CustomNotification.show(
                                  context,
                                  'Applied $theme successfully!',
                                  type: NotificationType.success,
                                );
                                Navigator.pop(ctx);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MomentumLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.15),
          AppTheme.primaryBlue.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25, size.height * 0.8,
      size.width * 0.3, size.height * 0.2,
      size.width * 0.5, size.height * 0.3,
    );
    path.cubicTo(
      size.width * 0.7, size.height * 0.4,
      size.width * 0.8, size.height * 0.1,
      size.width, size.height * 0.25,
    );

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerWithTeam {
  final Player player;
  final Team team;
  _PlayerWithTeam(this.player, this.team);
}
