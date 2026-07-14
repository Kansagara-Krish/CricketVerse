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
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: views[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFFBBF24),
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket_outlined), activeIcon: Icon(Icons.sports_cricket), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.online_prediction_outlined), activeIcon: Icon(Icons.online_prediction), label: 'Prediction'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
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
                  CircleAvatar(
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                      ),
                      Text(
                        'Hello, Alex',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white38, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search teams, players, matches...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.mic, color: Colors.white54, size: 20),
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
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: const Color(0xFF0F4C81),
                  backgroundColor: Colors.white.withOpacity(0.03),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'No $_selectedFilter matches found.',
                      style: GoogleFonts.outfit(color: Colors.white38),
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
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPlayerTrendCard('V. Kohli', 'Batter • IND', 'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?q=80&w=120&auto=format&fit=crop'),
                _buildPlayerTrendCard('P. Cummins', 'Bowler • AUS', 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120&auto=format&fit=crop'),
                _buildPlayerTrendCard('R. Khan', 'All-rounder • AFG', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=120&auto=format&fit=crop'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Latest Updates Section
          Text(
            'Latest Updates',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

    final runs = match.isFirstInnings ? match.runsA : match.runsB;
    final wickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    final overs = match.isFirstInnings ? match.oversA : match.oversB;
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
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ICC WORLD CUP 2026',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.status == 'Live'
                        ? Colors.redAccent.withOpacity(0.15)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: match.status == 'Live' ? Colors.redAccent : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: match.status == 'Live' ? Colors.redAccent : Colors.white70,
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
                    CircleAvatar(backgroundColor: Color(teamAIntColor), child: Text(match.teamA.shortName, style: const TextStyle(color: Colors.white))),
                    const SizedBox(height: 8),
                    Text(match.teamA.shortName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (match.status != 'Upcoming') ...[
                      const SizedBox(height: 4),
                      Text('${match.runsA}/${match.wicketsA}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                      Text('(${match.oversA} ov)', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text('Yet to play', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                    ],
                  ],
                ),
                Column(
                  children: [
                    Text('VS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (match.status == 'Live')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
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
                    CircleAvatar(backgroundColor: Color(teamBIntColor), child: Text(match.teamB.shortName, style: const TextStyle(color: Colors.white))),
                    const SizedBox(height: 8),
                    Text(match.teamB.shortName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (match.status == 'Live') ...[
                      const SizedBox(height: 4),
                      Text('Yet to bat', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                    ] else if (match.status == 'Completed') ...[
                      const SizedBox(height: 4),
                      Text('${match.runsB}/${match.wicketsB}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                      Text('(${match.oversB} ov)', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text('Yet to play', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Footer of card matching Screenshot 2026-07-09 152229.png
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: ${match.status == 'Upcoming' ? 'TBD' : (match.isFirstInnings ? '${match.runsA + 1}' : '${match.target}')}',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
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

  Widget _buildPlayerTrendCard(String name, String role, String imgUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(imgUrl),
            radius: 36,
          ),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(role, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
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
          Text('Tournaments & Matches', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: storage.matches.length,
              itemBuilder: (context, index) {
                final match = storage.matches[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.sports_cricket, color: Colors.white70)),
                  title: Text('${match.teamA.name} vs ${match.teamB.name}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${match.venue} • ${match.date} ${match.time}', style: const TextStyle(color: Colors.white54)),
                  trailing: Text(match.status, style: const TextStyle(color: Colors.amberAccent)),
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
      return const Center(child: Text('No active Live matches for AI analytics.', style: TextStyle(color: Colors.white70)));
    }
    final match = liveMatches.first;
    final winProb = storage.calculateWinProbability(match);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text('AI Analytics', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          
          // WIN PROBABILITY CIRCULAR CHARTS matching Screenshot 2026-07-09 152201.png
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Text('Win Probability', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 24),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: winProb / 100.0,
                        strokeWidth: 10,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    ),
                    Column(
                      children: [
                        Text('${winProb.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('AI CONFIDENCE', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('${winProb.toStringAsFixed(0)}% ${match.teamA.shortName}', style: GoogleFonts.outfit(color: const Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                    Text('${(100 - winProb).toStringAsFixed(0)}% ${match.teamB.shortName}', style: GoogleFonts.outfit(color: Colors.white70)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- View 4: Live redirect button ---
  Widget _buildLiveRedirectView(StorageService storage) {
    final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
    if (liveMatches.isEmpty) {
      return const Center(child: Text('No active Live match right now.', style: TextStyle(color: Colors.white70)));
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
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            storage.currentUserEmail ?? 'guest@cricketverse.ai',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
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
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0284C7)),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
        ],
      ),
    );
  }
}
