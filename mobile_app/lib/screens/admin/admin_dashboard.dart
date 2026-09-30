import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../services/socket_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/widgets/team_logo.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/exit_app_dialog.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/network_status_bar.dart';
import '../../services/network_connectivity_service.dart';
import '../../models/models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // 0: Home view, 1: Profile view

  late AnimationController _drawerAnimationController;
  bool _isDrawerOpen = false;

  final List<Widget> _views = const [
    _DashboardHomeView(),
    _ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Register global socket notification listener
    SocketService.connect();
    SocketService.listenToGlobalNotifications((data) {
      if (mounted) {
        CustomNotification.show(
          context,
          data['message'] ?? 'Notification received',
          type: NotificationType.info,
        );
      }
    });

    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header with green online dot indicator
            const DrawerProfileHeader(
              initials: 'RK',
              name: 'Rajesh Kumar',
              role: 'Tournament Admin',
            ),
            const SizedBox(height: 32),

            // Menu Items List
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    AnimatedDrawerTile(
                      icon: Icons.grid_view_rounded,
                      title: 'Dashboard',
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        setState(() => _currentIndex = 0);
                        _toggleDrawer();
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.emoji_events_rounded,
                      title: 'Tournament',
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.tournamentList);
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.shield_outlined,
                      title: 'Teams',
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.teamManagement);
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Players',
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.playerManagement);
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.sports_cricket_rounded,
                      title: 'Matches',
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.matchList);
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Statistics',
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.statistics);
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      badgeCount: storage.unreadNotificationCount > 0 ? storage.unreadNotificationCount : 3,
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.notifications);
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        setState(() => _currentIndex = 1);
                        _toggleDrawer();
                      },
                    ),
                    AnimatedDrawerTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        _toggleDrawer();
                        Navigator.pushNamed(context, AppRoutes.aiSettings);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Online Mode Switcher
            Consumer<StorageService>(
              builder: (context, storage, _) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12, right: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            storage.isOnlineMode ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: storage.isOnlineMode ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
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
                        activeColor: const Color(0xFF10B981),
                        activeTrackColor: const Color(0xFF028A6B).withValues(alpha: 0.4),
                        onChanged: (val) {
                          storage.toggleOnlineMode(val);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Logout Button
            AnimatedDrawerTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              isLogout: true,
              onTap: () async {
                _toggleDrawer();
                final confirm = await LogoutDialog.show(context);
                if (confirm == true && context.mounted) {
                  await storage.logout();
                  if (context.mounted) {
                    CustomNotification.show(context, 'Successfully logged out!', type: NotificationType.success);
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_isDrawerOpen) {
          _toggleDrawer();
          return;
        }

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        final shouldExit = await ExitAppDialog.show(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Drawer3DWrapper(
        animationController: _drawerAnimationController,
        drawerMenu: _buildMenuDrawer(context),
        onTapOutsideToClose: _toggleDrawer,
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
              _currentIndex == 0 ? 'Admin Dashboard' : 'Admin Profile',
              style: GoogleFonts.plusJakartaSans(
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
              Consumer<StorageService>(
                builder: (_, storage, __) {
                  final count = storage.unreadNotificationCount;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                        onPressed: () async {
                          await Navigator.pushNamed(context, AppRoutes.notifications);
                          if (mounted) setState(() {});
                        },
                      ),
                      if (count > 0)
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
                              '$count',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              NetworkStatusBar(
                onRetry: () => NetworkConnectivityService().checkConnectivity(),
              ),
              Expanded(
                child: _views[_currentIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Home Dashboard View ─────────────────────────────────────────────────────
class _DashboardHomeView extends StatelessWidget {
  const _DashboardHomeView();

  Widget _buildCompactStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
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
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: 0.08),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
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
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 15,
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
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
                    Text('Good Day,', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('Rajesh Kumar 👋',
                        style: GoogleFonts.plusJakartaSans(
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('● LIVE',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$liveCount live match in progress',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                    ],
                  ),
                ),
              ),

            // Stats Grid
            Text('SYSTEM OVERVIEW',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800,
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
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800,
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
                    AppTheme.accentPurple,
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
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted, letterSpacing: 1.3)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.65,
              children: [
                _QuickActionCard(
                  icon: Icons.add_circle_rounded,
                  title: 'Schedule Match',
                  subtitle: 'Set up fixture & scorer',
                  color: AppTheme.primaryBlue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.scheduleMatch),
                ),
                _QuickActionCard(
                  icon: Icons.group_add_rounded,
                  title: 'Manage Teams',
                  subtitle: 'Rosters & players',
                  color: AppTheme.accentGold,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.teamManagement),
                ),
                _QuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Statistics',
                  subtitle: 'Tournament analytics',
                  color: AppTheme.accentPurple,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.statistics),
                ),
                _QuickActionCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Tournament',
                  subtitle: 'Format & schedule',
                  color: AppTheme.accentRed,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.createTournament),
                ),
              ],
            ),


            const SizedBox(height: 24),

            // Recent Matches
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT MATCHES',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted, letterSpacing: 1.3)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.matchList),
                  child: Text('View All',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
             const SizedBox(height: 4),
            ...storage.matches.asMap().entries.take(3).map((entry) {
              final index = entry.key;
              final m = entry.value;
              return CardEntranceAnimation(
                index: index,
                child: _MatchCard(match: m),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      borderOnForeground: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    match.status == 'Live' ? '● ${match.status}' : match.status,
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(match.matchType,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textMuted)),
                const SizedBox(width: 8),
                Text(match.date,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 12),
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
                              match.teamA.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            Text(
                              match.teamA.shortName,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (match.runsA > 0)
                              Text('${match.runsA}/${match.wicketsA} (${match.oversA})',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('VS',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              match.teamB.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            Text(
                              match.teamB.shortName,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                            if (match.runsB > 0)
                              Text('${match.runsB}/${match.wicketsB} (${match.oversB})',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
            const SizedBox(height: 4),
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
          Text('Rajesh Kumar', style: GoogleFonts.plusJakartaSans(fontSize: 20, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          Text('admin@cricketverse.ai', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
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

// ─── Search Helper Class ────────────────────────────────────────────────────
class _SearchSuggestion {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'Team', 'Player', 'Match', 'Tournament', 'Action'
  final dynamic targetData;
  final IconData icon;

  _SearchSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    this.targetData,
    required this.icon,
  });
}

// ─── Search Delegate with 1-Week History Retention & Dataset Hints Redirection ─
class _CricketSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final historyList = storage.getSearchHistory();
    final allSuggestions = _generateDatasetSuggestions(storage);

    if (query.isEmpty) {
      return Container(
        color: AppTheme.bgDark,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          children: [
            // --- 1-Week Search History Section ---
            if (historyList.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18, color: Color(0xFF028A6B)),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Searches (1-Week Retention)',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => storage.clearSearchHistory(),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...historyList.map((item) => _buildHistoryTile(context, storage, item)),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 16),
            ],

            // --- Dataset Suggestions Section ---
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  'Dataset Hints & Quick Actions',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...allSuggestions.take(8).map((s) => _buildSuggestionTile(context, storage, s)),
          ],
        ),
      );
    }

    // Filter results matching search query
    final filtered = allSuggestions
        .where((s) =>
            s.title.toLowerCase().contains(query.toLowerCase()) ||
            s.subtitle.toLowerCase().contains(query.toLowerCase()) ||
            s.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return Container(
        color: AppTheme.bgDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'No dataset match for "$query"',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try searching for Team, Player, Match, or Tournament name',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.bgDark,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final s = filtered[index];
          return _buildSuggestionTile(context, storage, s);
        },
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, StorageService storage, SearchHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: const Icon(Icons.history_rounded, size: 20, color: AppTheme.textMuted),
        title: Text(
          item.title,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${item.subtitle} • ${_formatTimeAgo(item.timestamp)}',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryBadge(item.category),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
              onPressed: () => storage.removeSearchHistoryItem(item.id),
            ),
          ],
        ),
        onTap: () {
          query = item.title;
          _handleRedirection(context, storage, _SearchSuggestion(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            icon: _getCategoryIcon(item.category),
          ));
        },
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, StorageService storage, _SearchSuggestion s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _getCategoryColor(s.category).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(s.icon, size: 18, color: _getCategoryColor(s.category)),
        ),
        title: Text(
          s.title,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          s.subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 11.5,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryBadge(s.category),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
          ],
        ),
        onTap: () => _handleRedirection(context, storage, s),
      ),
    );
  }

  void _handleRedirection(BuildContext context, StorageService storage, _SearchSuggestion s) async {
    // 1. Record search query in 1-week retention storage
    await storage.addSearchHistoryItem(SearchHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: s.title,
      subtitle: s.subtitle,
      category: s.category,
      timestamp: DateTime.now(),
      targetId: s.id,
    ));

    if (!context.mounted) return;

    // 2. Redirect to specific page containing that dataset object
    close(context, s.title);

    if (s.category == 'Team' && s.targetData is Team) {
      Navigator.pushNamed(context, AppRoutes.teamDetail, arguments: s.targetData as Team);
    } else if (s.category == 'Player' && s.targetData is Player) {
      Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: s.targetData as Player);
    } else if (s.category == 'Match' && s.targetData is CricketMatch) {
      Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: s.targetData as CricketMatch);
    } else if (s.category == 'Tournament') {
      Navigator.pushNamed(context, AppRoutes.tournamentList);
    } else if (s.category == 'Action') {
      if (s.title.contains('Schedule')) {
        Navigator.pushNamed(context, AppRoutes.scheduleMatch);
      } else if (s.title.contains('Tournament')) {
        Navigator.pushNamed(context, AppRoutes.createTournament);
      } else if (s.title.contains('Teams')) {
        Navigator.pushNamed(context, AppRoutes.teamManagement);
      } else if (s.title.contains('Commentary')) {
        Navigator.pushNamed(context, AppRoutes.aiCommentary);
      } else if (s.title.contains('Statistics')) {
        Navigator.pushNamed(context, AppRoutes.statistics);
      } else if (s.title.contains('Notifications')) {
        Navigator.pushNamed(context, AppRoutes.notifications);
      }
    } else {
      // Fallback redirection by search title matching
      final matchTeam = storage.teams.firstWhere(
        (t) => t.name.toLowerCase() == s.title.toLowerCase() || t.shortName.toLowerCase() == s.title.toLowerCase(),
        orElse: () => Team(id: '', name: '', shortName: '', logoColorHex: '', players: []),
      );
      if (matchTeam.id.isNotEmpty) {
        Navigator.pushNamed(context, AppRoutes.teamDetail, arguments: matchTeam);
      }
    }
  }

  Widget _buildCategoryBadge(String category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Team':
        return const Color(0xFF0284C7);
      case 'Player':
        return const Color(0xFF10B981);
      case 'Match':
        return const Color(0xFFF59E0B);
      case 'Tournament':
        return const Color(0xFF8B5CF6);
      case 'Action':
        return const Color(0xFF028A6B);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Team':
        return Icons.shield_outlined;
      case 'Player':
        return Icons.person_outline_rounded;
      case 'Match':
        return Icons.sports_cricket_rounded;
      case 'Tournament':
        return Icons.emoji_events_outlined;
      case 'Action':
        return Icons.touch_app_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  List<_SearchSuggestion> _generateDatasetSuggestions(StorageService storage) {
    List<_SearchSuggestion> list = [];

    // 1. Teams
    for (var t in storage.teams) {
      list.add(_SearchSuggestion(
        id: 'team_${t.id}',
        title: t.name,
        subtitle: 'Team (${t.shortName}) • ${t.players.length} Roster Players',
        category: 'Team',
        targetData: t,
        icon: Icons.shield_outlined,
      ));

      // 2. Players in Team
      for (var p in t.players) {
        list.add(_SearchSuggestion(
          id: 'player_${p.id}',
          title: p.name,
          subtitle: 'Player (${p.role}) • ${t.shortName}',
          category: 'Player',
          targetData: p,
          icon: Icons.person_outline_rounded,
        ));
      }
    }

    // 3. Matches
    for (var m in storage.matches) {
      list.add(_SearchSuggestion(
        id: 'match_${m.id}',
        title: '${m.teamA.name} vs ${m.teamB.name}',
        subtitle: 'Match • ${m.status} • Venue: ${m.venue}',
        category: 'Match',
        targetData: m,
        icon: Icons.sports_cricket_rounded,
      ));
    }

    // 4. Tournaments
    for (var tourn in storage.tournaments) {
      list.add(_SearchSuggestion(
        id: 'tourn_${tourn.id}',
        title: tourn.name,
        subtitle: 'Tournament • ${tourn.format} • ${tourn.status}',
        category: 'Tournament',
        targetData: tourn,
        icon: Icons.emoji_events_outlined,
      ));
    }

    // Default Tournaments if dataset list is small
    if (storage.tournaments.isEmpty) {
      list.addAll([
        _SearchSuggestion(
          id: 'tourn_default_1',
          title: 'UVPCE Premier League 2024',
          subtitle: 'Tournament • T20 Format • Live',
          category: 'Tournament',
          icon: Icons.emoji_events_outlined,
        ),
        _SearchSuggestion(
          id: 'tourn_default_2',
          title: 'Gujarat State Cricket Championship',
          subtitle: 'Tournament • ODI Format • Upcoming',
          category: 'Tournament',
          icon: Icons.emoji_events_outlined,
        ),
      ]);
    }

    // 5. System Quick Actions
    list.addAll([
      _SearchSuggestion(
        id: 'act_1',
        title: 'Schedule New Match',
        subtitle: 'Create & assign teams to upcoming fixture',
        category: 'Action',
        icon: Icons.add_circle_outline_rounded,
      ),
      _SearchSuggestion(
        id: 'act_2',
        title: 'Create Tournament',
        subtitle: 'Configure new tournament structure',
        category: 'Action',
        icon: Icons.emoji_events_rounded,
      ),
      _SearchSuggestion(
        id: 'act_3',
        title: 'Manage Teams & Players',
        subtitle: 'Edit team profiles and player rosters',
        category: 'Action',
        icon: Icons.groups_rounded,
      ),
      _SearchSuggestion(
        id: 'act_4',
        title: 'AI Performance Analytics',
        subtitle: 'View overall tournament & player insights',
        category: 'Action',
        icon: Icons.bar_chart_rounded,
      ),
    ]);

    return list;
  }

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppTheme.bgDark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      );
}
