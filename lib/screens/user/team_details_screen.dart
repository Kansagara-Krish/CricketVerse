import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;
  const TeamDetailsScreen({super.key, required this.team});

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
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(intColor),
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
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
                child: Material(
                  color: AppTheme.textPrimary.withValues(alpha: 0.03),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.textPrimary.withValues(alpha: 0.06)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(intColor).withValues(alpha: 0.1),
                      foregroundColor: Color(intColor),
                      child: Text(player.name.substring(0, 1)),
                    ),
                    title: Text(player.name, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text(player.role, style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0x4D0F172A)),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.userPlayerDetails,
                        arguments: player,
                      );
                    },
                  ),
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
              Text(opponent, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(date, style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isWon ? AppTheme.primaryGreen : Colors.redAccent).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result,
              style: GoogleFonts.plusJakartaSans(color: isWon ? AppTheme.primaryGreen : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
