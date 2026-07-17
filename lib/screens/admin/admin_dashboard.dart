import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/custom_notification.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // 0: Home view, 1: Profile view
  int _notificationCount = 5;

  late AnimationController _drawerAnimationController;
  bool _isDrawerOpen = false;

  final List<Widget> _views = const [
    _DashboardHomeView(),
    _ProfileView(),
  ];

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

  Widget _buildMenuDrawer(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
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
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                    radius: 22,
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rajesh Kumar',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tournament Admin',
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
                        setState(() => _currentIndex = 0);
                        _toggleDrawer();
                      }, isSelected: _currentIndex == 0),
                      _buildMenuItem(Icons.emoji_events_rounded, 'Tournament', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.tournamentList);
                      }),
                      _buildMenuItem(Icons.groups_rounded, 'Teams', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.teamManagement);
                      }),
                      _buildMenuItem(Icons.person_pin_rounded, 'Players', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.playerManagement);
                      }),
                      _buildMenuItem(Icons.sports_cricket_rounded, 'Matches', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.matchList);
                      }),
                      _buildMenuItem(Icons.live_tv_rounded, 'Live Scoring', () {
                        _toggleDrawer();
                        final liveMatch = storage.matches.firstWhere(
                          (m) => m.status == 'Live',
                          orElse: () => storage.matches[0],
                        );
                        if (liveMatch.status == 'Live') {
                          Navigator.pushNamed(context, AppRoutes.liveScoring, arguments: liveMatch);
                        } else {
                          CustomNotification.show(
                            context,
                            'No live matches running at the moment!',
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
                      _buildMenuItem(Icons.manage_accounts_rounded, 'Profile', () {
                        setState(() => _currentIndex = 1);
                        _toggleDrawer();
                      }, isSelected: _currentIndex == 1),
                      _buildMenuItem(Icons.settings_rounded, 'Settings', () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.aiSettings);
                      }),
                    ],
                  ),
                ),
              ),
              
              // Logout
              _buildMenuItem(Icons.logout_rounded, 'Logout', () {
                _toggleDrawer();
                storage.logout();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false);
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Drawer menu
          _buildMenuDrawer(context),
          
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
                  'CricketVerse AI',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppTheme.textPrimary),
                    onPressed: () {
                      showSearch(context: context, delegate: _CricketSearchDelegate());
                    },
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                        onPressed: () {
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
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: _views[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Dashboard View ─────────────────────────────────────────────────────
class _DashboardHomeView extends StatelessWidget {
  const _DashboardHomeView();

  Widget _buildCompactStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 15,
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
      backgroundColor: Colors.white,
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 800)),
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
                    Text('Good Day,', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('Rajesh Kumar 👋',
                        style: GoogleFonts.outfit(
                            fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('● LIVE',
                            style: GoogleFonts.outfit(
                                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$liveCount live match in progress',
                          style: GoogleFonts.outfit(fontSize: 13.5, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                    ],
                  ),
                ),
              ),

            // Stats Grid
            Text('SYSTEM OVERVIEW',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted, letterSpacing: 1.3)),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                _buildCompactStatCard('Live Matches', '$liveCount', AppTheme.primaryGreen, Icons.sensors),
                _buildCompactStatCard('Upcoming', '$upcomingCount', AppTheme.primaryBlue, Icons.schedule),
                _buildCompactStatCard('Completed', '$completedCount', AppTheme.textMuted, Icons.check_circle_outline),
                _buildCompactStatCard('Total Teams', '$teamCount', AppTheme.accentGold, Icons.groups_outlined),
              ],
            ),
            const SizedBox(height: 24),
            
            // Cricket Analytics Section
            Text('CRICKET ANALYTICS',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted, letterSpacing: 1.3)),
            const SizedBox(height: 10),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildAnalyticsCard(
                    'Highest Score',
                    '218/3',
                    'UVPCE Titans',
                    Icons.sports_score,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 12),
                  _buildAnalyticsCard(
                    'Best Strike Rate',
                    '184.5',
                    'Aarav Patel (UVP-TT)',
                    Icons.bolt,
                    const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 12),
                  _buildAnalyticsCard(
                    'Top Wicket Taker',
                    '18 Wkts',
                    'Advik Shah (UVP-WR)',
                    Icons.sports_cricket,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('QUICK ACTIONS',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted, letterSpacing: 1.3)),
            const SizedBox(height: 10),
            Row(
              children: [
                _QuickAction(Icons.add_circle_rounded, 'Schedule\nMatch', AppTheme.primaryBlue,
                    () => Navigator.pushNamed(context, AppRoutes.scheduleMatch)),
                const SizedBox(width: 10),
                _QuickAction(Icons.group_add_rounded, 'Add\nTeam', AppTheme.accentGold,
                    () => Navigator.pushNamed(context, AppRoutes.teamManagement)),
                const SizedBox(width: 10),
                _QuickAction(Icons.bar_chart_rounded, 'Statistics', AppTheme.accentPurple,
                    () => Navigator.pushNamed(context, AppRoutes.statistics)),
                const SizedBox(width: 10),
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
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted, letterSpacing: 1.3)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.matchList),
                  child: Text('View All',
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 9.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    match.status == 'Live' ? '● ${match.status}' : match.status,
                    style: GoogleFonts.outfit(fontSize: 9.5, color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(match.matchType,
                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppTheme.textMuted)),
                const SizedBox(width: 8),
                Text(match.date,
                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppTheme.textMuted)),
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
                              fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      Text(match.teamA.name,
                          style: GoogleFonts.outfit(fontSize: 10.5, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (match.runsA > 0)
                        Text('${match.runsA}/${match.wicketsA} (${match.oversA})',
                            style: GoogleFonts.outfit(
                                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                Text('VS',
                    style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(match.teamB.shortName,
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      Text(match.teamB.name,
                          style: GoogleFonts.outfit(fontSize: 10.5, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (match.runsB > 0)
                        Text('${match.runsB}/${match.wicketsB} (${match.oversB})',
                            style: GoogleFonts.outfit(
                                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(match.venue,
                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
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
          Text('Rajesh Kumar', style: GoogleFonts.outfit(fontSize: 20, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          Text('admin@cricketverse.ai', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary)),
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
    'UVPCE Titans vs UVPCE Warriors - Live Match',
    'UVPCE Titans',
    'UVPCE Warriors',
    'Aarav Patel - Batter',
    'Advik Shah - Bowler',
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
          leading: const Icon(Icons.search, color: AppTheme.textMuted),
          title: Text(results[i], style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
          onTap: () => close(context, results[i]),
        ),
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppTheme.bgDark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      );
}
