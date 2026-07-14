import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import 'player_details_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;
  const TeamDetailsScreen({Key? key, required this.team}) : super(key: key);

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final intColor = int.tryParse(widget.team.logoColorHex) ?? 0xFF0284C7;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(intColor),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Squad'),
            Tab(text: 'Matches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Squad Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.team.players.length,
            itemBuilder: (context, index) {
              final player = widget.team.players[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(intColor).withOpacity(0.1),
                    foregroundColor: Color(intColor),
                    child: Text(player.name.substring(0, 1)),
                  ),
                  title: Text(player.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(player.role, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayerDetailsScreen(player: player)),
                    );
                  },
                ),
              );
            },
          ),
          
          // 2. Matches Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildPastMatchTile('vs Team Australia', 'Won by 3 wickets', '02-07-2026', true),
                _buildPastMatchTile('vs Team Pakistan', 'Won by 45 runs', '28-06-2026', true),
                _buildPastMatchTile('vs Team England', 'Lost by 4 wickets', '24-06-2026', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastMatchTile(String opponent, String result, String date, bool isWon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(opponent, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(date, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isWon ? const Color(0xFF10B981) : Colors.redAccent).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result,
              style: GoogleFonts.outfit(color: isWon ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
