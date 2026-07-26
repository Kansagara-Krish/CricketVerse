import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';

class SchedulesTabView extends StatefulWidget {
  const SchedulesTabView({super.key});

  @override
  State<SchedulesTabView> createState() => _SchedulesTabViewState();
}

class _SchedulesTabViewState extends State<SchedulesTabView> {
  String _schedulesSubTab = 'Matches'; // 'Tournaments', 'Matches', 'Teams', 'Players'

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
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
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildSubTabBar(subTabs),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSubTabContent(itemCount, allPlayersList, storage),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabBar(List<String> subTabs) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subTabs.length,
        itemBuilder: (context, idx) {
          final tab = subTabs[idx];
          final isSelected = _schedulesSubTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _schedulesSubTab = tab),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF854D0E) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF854D0E) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                tab,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubTabContent(int itemCount, List<_PlayerWithTeam> allPlayersList, StorageService storage) {
    return ListView.builder(
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.userMatchDetails, arguments: match.id),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TeamLogo(teamName: match.teamA.name, shortName: match.teamA.shortName, logoColorHex: match.teamA.logoColorHex, size: 28),
                    const SizedBox(width: 4),
                    TeamLogo(teamName: match.teamB.name, shortName: match.teamB.shortName, logoColorHex: match.teamB.logoColorHex, size: 28),
                  ],
                ),
                title: Text('${match.teamA.name} vs ${match.teamB.name}', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('${match.venue} • ${match.date} ${match.time}', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Text(
                  match.status,
                  style: GoogleFonts.plusJakartaSans(
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.tournamentDetail, arguments: t),
                leading: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentPurple),
                title: Text(t['name']!, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('${t['teams']} Teams • ${t['matches']} Matches • ${t['format']}', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusColor(t['status']!).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t['status']!, style: GoogleFonts.plusJakartaSans(color: AppTheme.statusColor(t['status']!), fontSize: 10, fontWeight: FontWeight.bold)),
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.userTeamDetails, arguments: team),
                leading: TeamLogo(teamName: team.name, shortName: team.shortName, logoColorHex: team.logoColorHex, size: 28),
                title: Text(team.name, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('${team.players.length} Players • ${team.shortName}', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5)),
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.userPlayerDetails, arguments: player),
                leading: CircleAvatar(
                  backgroundColor: Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7).withValues(alpha: 0.15),
                  child: Text(player.name.substring(0, 1), style: TextStyle(color: Color(int.tryParse(team.logoColorHex) ?? 0xFF0284C7), fontWeight: FontWeight.bold)),
                ),
                title: Text(player.name, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('${player.role} • ${team.shortName}', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5)),
                trailing: Text('${player.runsScored} runs', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          );
        }
      },
    );
  }
}

class _PlayerWithTeam {
  final Player player;
  final Team team;
  _PlayerWithTeam(this.player, this.team);
}
