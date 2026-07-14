import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'match_details_screen.dart';
import 'auth_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0; // Default to Home
  String _selectedFilter = 'Live'; // 'Live', 'Upcoming', 'Completed'

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: views[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF854D0E), // Gold-brown selection matching screenshot
          unselectedItemColor: const Color(0xFF64748B),
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
                        style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
                      ),
                      Text(
                        'Hello, Alex',
                        style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF0F172A)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search teams, players, matches...',
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                const Icon(Icons.mic, color: Color(0xFF64748B), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filters row (Chips styling matching light mode)
          Row(
            children: ['Live', 'Upcoming', 'Completed'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
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
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      'No $_selectedFilter matches found.',
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchesList.length,
                  itemBuilder: (context, index) {
                    final match = matchesList[index];
                    return _buildMatchCard(match, storage);
                  },
                ),
          const SizedBox(height: 24),

          // Trending Players Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Players',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text('View all', style: GoogleFonts.outfit(color: const Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: Color(0xFF0284C7), size: 14),
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
                _buildPlayerTrendCard('V. Kohli', 'Batter • IND', 'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?q=80&w=120&auto=format&fit=crop', Icons.sports_cricket, const Color(0xFFF59E0B)),
                _buildPlayerTrendCard('P. Cummins', 'Bowler • AUS', 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120&auto=format&fit=crop', Icons.circle, const Color(0xFF10B981)),
                _buildPlayerTrendCard('R. Khan', 'All-rounder • AFG', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=120&auto=format&fit=crop', Icons.trending_up, const Color(0xFF0284C7)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Latest Updates Section
          Text(
            'Latest Updates',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANALYSIS',
                        style: GoogleFonts.outfit(color: const Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How AI predicted the live win probability swing during final over.',
                        style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
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
    final teamAIntColor = int.tryParse(match.teamA.logoColorHex) ?? 0xFF0284C7;
    final teamBIntColor = int.tryParse(match.teamB.logoColorHex) ?? 0xFFFFBF00;
    final winProb = storage.calculateWinProbability(match);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MatchDetailsScreen(matchId: match.id)),
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
              color: const Color(0xFF0284C7).withValues(alpha: 0.05),
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
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: match.status == 'Live' ? Colors.redAccent : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: match.status == 'Live' ? Colors.redAccent : const Color(0xFF475569),
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
                    CircleAvatar(backgroundColor: Color(teamAIntColor), child: Text(match.teamA.shortName, style: const TextStyle(color: const Color(0xFF0F172A)))),
                    const SizedBox(height: 8),
                    Text(match.teamA.shortName, style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    if (match.status != 'Upcoming') ...[
                      const SizedBox(height: 4),
                      Text('${match.runsA}/${match.wicketsA}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('(${match.oversA} ov)', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text('Yet to play', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11)),
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
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CRR ${(match.oversA > 0 ? (match.runsA / match.oversA) : 0.0).toStringAsFixed(1)}',
                          style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(backgroundColor: Color(teamBIntColor), child: Text(match.teamB.shortName, style: const TextStyle(color: const Color(0xFF0F172A)))),
                    const SizedBox(height: 8),
                    Text(match.teamB.shortName, style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    if (match.status == 'Live') ...[
                      const SizedBox(height: 4),
                      Text('Yet to bat', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13)),
                    ] else if (match.status == 'Completed') ...[
                      const SizedBox(height: 4),
                      Text('${match.runsB}/${match.wicketsB}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('(${match.oversB} ov)', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text('Yet to play', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Footer of card matching Screenshot 2026-07-09 152229.png
            const Divider(color: Color(0xFFBAE6FD)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kohli 65*(42)',
                  style: GoogleFonts.outfit(color: const Color(0xFF0369A1), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF0284C7), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      'AI Predicts: ${match.teamA.shortName} ${winProb.toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(color: const Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.bold),
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
              CircleAvatar(
                backgroundImage: NetworkImage(imgUrl),
                radius: 32,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(badgeIcon, size: 10, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name, 
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role, 
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10), 
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournaments & Matches', 
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: storage.matches.length,
              itemBuilder: (context, index) {
                final match = storage.matches[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.sports_cricket, color: Color(0xFF0284C7))),
                    title: Text('${match.teamA.name} vs ${match.teamB.name}', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                    subtitle: Text('${match.venue} • ${match.date} ${match.time}', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                    trailing: Text(
                      match.status, 
                      style: GoogleFonts.outfit(
                        color: match.status == 'Live' ? Colors.redAccent : const Color(0xFF854D0E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
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
          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
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
          // Match Header matching Screenshot 2026-07-09 152201.png
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF0284C7),
                      radius: 20,
                      child: Text(match.teamA.shortName, style: const TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: const Text('VS', style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFFBF00),
                      radius: 20,
                      child: Text(match.teamB.shortName, style: const TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(match.teamA.shortName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(width: 20),
                    Text(match.teamB.shortName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Finals • Wankhede Stadium',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // WIN PROBABILITY CIRCULAR CHARTS matching Screenshot 2026-07-09 152201.png
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              children: [
                Text(
                  'Win Probability',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
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
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${winProb.toStringAsFixed(0)}%', 
                          style: GoogleFonts.outfit(fontSize: 38, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                        ),
                        Text(
                          'AI CONFIDENCE', 
                          style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF10B981), fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                        Text('${winProb.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                        Text(match.teamA.shortName, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(100 - winProb).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                        Text(match.teamB.shortName, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PROJECTED SCORE CARD matching Screenshot 2026-07-09 152201.png
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
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
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(match.teamA.shortName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 100,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '315-330',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(match.teamB.shortName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '280-295',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // MOMENTUM CARD matching Screenshot 2026-07-09 152201.png
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
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
                    const Icon(Icons.show_chart, color: Color(0xFF0284C7), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Momentum',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
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
      return const Center(child: Text('No active Live match right now.', style: TextStyle(color: const Color(0xDE0F172A))));
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
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            storage.currentUserEmail ?? 'guest@cricketverse.ai',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 40),
          
          _buildProfileTile(Icons.favorite_border, 'Favorite Teams'),
          _buildProfileTile(Icons.notifications_none, 'Notification Settings'),
          _buildProfileTile(Icons.palette_outlined, 'Choose Theme (Dark Mode)'),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                storage.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              label: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFEF4444),
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

  Widget _buildProfileTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0284C7)),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

class MomentumLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.15),
          const Color(0xFF0284C7).withValues(alpha: 0.0),
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
