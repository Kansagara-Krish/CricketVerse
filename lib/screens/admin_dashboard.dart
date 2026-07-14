// lib/screens/admin_dashboard.dart
// CricketVerse AI — Full Admin Dashboard with Drawer + Bottom Nav

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../core/routes/app_routes.dart';
import '../core/widgets/app_logo.dart';
import '../core/widgets/stat_card.dart';
import 'auth_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  int _notificationCount = 5;

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    _NavItem(Icons.sports_cricket_outlined, Icons.sports_cricket, 'Matches'),
    _NavItem(Icons.groups_outlined, Icons.groups, 'Teams'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardHomeView(),
      _MatchesView(onNotify: () {}),
      const _TeamsView(),
      const _ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: const AppLogo(size: 36),
            ),
          ),
        ),
        title: Text(
          'CricketVerse AI',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: const Color(0xDE0F172A)),
            onPressed: () {
              showSearch(context: context, delegate: _CricketSearchDelegate());
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: const Color(0xDE0F172A)),
                onPressed: () {
                  setState(() => _notificationCount = 0);
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _AdminDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: pages[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgMedium,
          border: Border(top: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.06))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: _navItems
              .map((n) => BottomNavigationBarItem(
                    icon: Icon(n.icon),
                    activeIcon: Icon(n.activeIcon, color: AppTheme.accentGold),
                    label: n.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ─── Admin Drawer ────────────────────────────────────────────────────────────
class _AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.bgDeep, AppTheme.bgMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 52, withGlow: true),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rajesh Kumar',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      Text('Tournament Admin',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0x8A0F172A))),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                        ),
                        child: Text('Online',
                            style: GoogleFonts.outfit(
                                fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection('OVERVIEW'),
                  _DrawerItem(Icons.dashboard_rounded, 'Dashboard', () {
                    Navigator.pop(context);
                  }),
                  _DrawerItem(Icons.notifications_outlined, 'Notifications', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  }),

                  _DrawerSection('TOURNAMENTS'),
                  _DrawerItem(Icons.emoji_events_outlined, 'Create Tournament', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.createTournament);
                  }),
                  _DrawerItem(Icons.list_alt_rounded, 'Tournament List', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.tournamentList);
                  }),

                  _DrawerSection('TEAMS & PLAYERS'),
                  _DrawerItem(Icons.groups_rounded, 'Manage Teams', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.teamManagement);
                  }),
                  _DrawerItem(Icons.person_pin_rounded, 'Manage Players', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.playerManagement);
                  }),

                  _DrawerSection('MATCHES'),
                  _DrawerItem(Icons.calendar_today_rounded, 'Schedule Match', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.scheduleMatch);
                  }),
                  _DrawerItem(Icons.sports_cricket_rounded, 'Match List', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.matchList);
                  }),

                  _DrawerSection('ANALYTICS'),
                  _DrawerItem(Icons.bar_chart_rounded, 'Statistics', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.statistics);
                  }),
                  _DrawerItem(Icons.auto_awesome_rounded, 'AI Settings', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.aiSettings);
                  }),

                  _DrawerSection('ACCOUNT'),
                  _DrawerItem(Icons.manage_accounts_rounded, 'My Profile', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.adminProfile);
                  }),
                  _DrawerItem(Icons.info_outline_rounded, 'About', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.about);
                  }),
                  _DrawerItem(Icons.help_outline_rounded, 'Help & FAQ', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.help);
                  }),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<StorageService>(context, listen: false).logout();
                        Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.auth, (r) => false);
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed.withOpacity(0.15),
                        foregroundColor: AppTheme.accentRed,
                        side: BorderSide(color: AppTheme.accentRed.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'CricketVerse AI v1.0.0',
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x3D0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0x3D0F172A),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0x990F172A), size: 22),
      title: Text(label,
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xDE0F172A), fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.white.withOpacity(0.04),
    );
  }
}

// ─── Home Dashboard View ─────────────────────────────────────────────────────
class _DashboardHomeView extends StatelessWidget {
  const _DashboardHomeView();

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final liveCount = storage.matches.where((m) => m.status == 'Live').length;
    final upcomingCount = storage.matches.where((m) => m.status == 'Upcoming').length;
    final completedCount = storage.matches.where((m) => m.status == 'Completed').length;
    final teamCount = storage.teams.length;
    final playerCount = storage.teams.fold(0, (sum, t) => sum + t.players.length);

    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      backgroundColor: AppTheme.bgMedium,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning,', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x8A0F172A))),
                    Text('Rajesh Kumar 👋',
                        style: GoogleFonts.outfit(
                            fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Match Banner (if any)
            if (liveCount > 0)
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.matchList),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('● LIVE',
                            style: GoogleFonts.outfit(
                                fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$liveCount match${liveCount > 1 ? "es" : ""} in progress right now',
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: const Color(0xDE0F172A), size: 14),
                    ],
                  ),
                ),
              ),

            // Stats Grid
            Text('SYSTEM OVERVIEW',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                    color: const Color(0x610F172A), letterSpacing: 1.5)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: [
                StatCard(
                  icon: Icons.fiber_manual_record,
                  title: 'Live Matches',
                  value: '$liveCount',
                  gradient: const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF10B981)]),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.matchList),
                ),
                StatCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Upcoming',
                  value: '$upcomingCount',
                  gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)]),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.matchList),
                ),
                StatCard(
                  icon: Icons.groups_rounded,
                  title: 'Total Teams',
                  value: '$teamCount',
                  gradient: const LinearGradient(colors: [Color(0xFF92400E), Color(0xFFFBBF24)]),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.teamManagement),
                ),
                StatCard(
                  icon: Icons.person_rounded,
                  title: 'Players',
                  value: '$playerCount',
                  gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)]),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.playerManagement),
                ),
                StatCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Completed',
                  value: '$completedCount',
                  gradient: const LinearGradient(colors: [Color(0xFF374151), Color(0xFF6B7280)]),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.matchList),
                ),
                StatCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Tournaments',
                  value: '3',
                  gradient: const LinearGradient(colors: [Color(0xFF9D174D), Color(0xFFEC4899)]),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tournamentList),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text('QUICK ACTIONS',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                    color: const Color(0x610F172A), letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(Icons.add_circle_rounded, 'Schedule\nMatch', AppTheme.primaryBlue,
                    () => Navigator.pushNamed(context, AppRoutes.scheduleMatch)),
                const SizedBox(width: 12),
                _QuickAction(Icons.group_add_rounded, 'Add\nTeam', AppTheme.accentGold,
                    () => Navigator.pushNamed(context, AppRoutes.teamManagement)),
                const SizedBox(width: 12),
                _QuickAction(Icons.bar_chart_rounded, 'Statistics', AppTheme.accentPurple,
                    () => Navigator.pushNamed(context, AppRoutes.statistics)),
                const SizedBox(width: 12),
                _QuickAction(Icons.emoji_events_rounded, 'Tournament', AppTheme.accentRed,
                    () => Navigator.pushNamed(context, AppRoutes.createTournament)),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Matches
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT MATCHES',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                        color: const Color(0x610F172A), letterSpacing: 1.5)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.matchList),
                  child: Text('View All',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryBlue)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...storage.matches.take(3).map((m) => _MatchCard(match: m)).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xDE0F172A), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final dynamic match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(match.status);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassCard,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    match.status == 'Live' ? '● ${match.status}' : match.status,
                    style: GoogleFonts.outfit(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(match.matchType,
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
                const SizedBox(width: 8),
                Text(match.date,
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.teamA.shortName,
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      Text(match.teamA.name,
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x8A0F172A))),
                      if (match.runsA > 0)
                        Text('${match.runsA}/${match.wicketsA} (${match.oversA})',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xDE0F172A))),
                    ],
                  ),
                ),
                Text('VS',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0x3D0F172A))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(match.teamB.shortName,
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      Text(match.teamB.name,
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x8A0F172A))),
                      if (match.runsB > 0)
                        Text('${match.runsB}/${match.wicketsB} (${match.oversB})',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xDE0F172A))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: const Color(0x610F172A)),
                const SizedBox(width: 4),
                Text(match.venue,
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0x610F172A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Matches Tab View ────────────────────────────────────────────────────────
class _MatchesView extends StatelessWidget {
  final VoidCallback onNotify;
  _MatchesView({required this.onNotify});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_cricket, color: const Color(0x3D0F172A), size: 60),
          const SizedBox(height: 16),
          Text('Match Management', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xDE0F172A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Use the buttons below to navigate', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x610F172A))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.matchList),
            icon: const Icon(Icons.list),
            label: const Text('View All Matches'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scheduleMatch),
            icon: const Icon(Icons.add),
            label: const Text('Schedule New Match'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: const Color(0x3D0F172A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Teams Tab View ──────────────────────────────────────────────────────────
class _TeamsView extends StatelessWidget {
  const _TeamsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, color: const Color(0x3D0F172A), size: 60),
          const SizedBox(height: 16),
          Text('Team Management', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xDE0F172A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Manage teams, players and rosters', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x610F172A))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.teamManagement),
            icon: const Icon(Icons.groups),
            label: const Text('Manage Teams'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.playerManagement),
            icon: const Icon(Icons.person),
            label: const Text('Manage Players'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: const Color(0x3D0F172A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Tab View ────────────────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 72, withGlow: true),
          const SizedBox(height: 16),
          Text('Rajesh Kumar', style: GoogleFonts.outfit(fontSize: 20, color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          Text('admin@cricketverse.ai', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x8A0F172A))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminProfile),
            icon: const Icon(Icons.manage_accounts),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}

// ─── Search Delegate ─────────────────────────────────────────────────────────
class _CricketSearchDelegate extends SearchDelegate<String> {
  final List<String> _items = [
    'India vs Australia - Live Match',
    'Team India',
    'Team Australia',
    'V. Kohli - Batter',
    'J. Bumrah - Bowler',
    'Schedule New Match',
    'Statistics',
    'Notifications',
  ];

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = query.isEmpty
        ? _items
        : _items.where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();

    return Container(
      color: AppTheme.bgDark,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.search, color: const Color(0x610F172A)),
          title: Text(results[i], style: GoogleFonts.outfit(color: const Color(0xFF0F172A))),
          onTap: () => close(context, results[i]),
        ),
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppTheme.bgDark,
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.outfit(color: const Color(0x610F172A)),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      );
}
