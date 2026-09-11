// lib/screens/admin/team_management_screen.dart
// Full Team & Player CRUD with Light Mint Theme, Watermarks, and Professional Tab Animation

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/card_entrance_animation.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  String _searchQuery = '';
  String _selectedRoleFilter = 'All'; // All, Batter, Bowler, All-rounder, Wicketkeeper

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showAddTeamDialog() {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();
    final colorOptions = [
      {'label': 'Emerald', 'hex': '0xFF028A6B'},
      {'label': 'Green', 'hex': '0xFF10B981'},
      {'label': 'Gold', 'hex': '0xFFFBBF24'},
      {'label': 'Amber', 'hex': '0xFFD97706'},
      {'label': 'Red', 'hex': '0xFFEF4444'},
      {'label': 'Orange', 'hex': '0xFFF97316'},
    ];
    String selectedColor = '0xFF028A6B';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add New Team',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon: Icon(Icons.groups_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: shortCtrl,
                maxLength: 4,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  labelText: 'Short Code (e.g. RCB)',
                  prefixIcon: const Icon(Icons.label_outline, color: AppTheme.textMuted),
                  counterStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Team Theme Color',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0x990F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: colorOptions.map((c) {
                  final isSelected = c['hex'] == selectedColor;
                  final color = Color(int.parse(c['hex']!));
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedColor = c['hex']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isSelected ? 0.25 : 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : color.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        c['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final short = shortCtrl.text.trim().toUpperCase();
                    if (name.isEmpty || short.isEmpty) {
                      CustomNotification.show(
                        context,
                        'Please fill all required fields',
                        type: NotificationType.warning,
                      );
                      return;
                    }
                    Provider.of<StorageService>(context, listen: false)
                        .addTeam(name, short, selectedColor, []);
                    Navigator.pop(ctx);
                    CustomNotification.show(
                      context,
                      'Team "$name" created successfully!',
                      type: NotificationType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF028A6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add Team',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final filteredTeams = storage.teams
        .where((t) =>
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.shortName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // Flatten all players across teams
    final List<Map<String, dynamic>> allPlayers = [];
    for (var team in storage.teams) {
      for (var p in team.players) {
        if (_searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            team.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          if (_selectedRoleFilter == 'All' || p.role.toLowerCase() == _selectedRoleFilter.toLowerCase()) {
            allPlayers.add({
              'player': p,
              'team': team,
            });
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F6),
      body: Stack(
        children: [
          // Background Watermarks (Top Right & Bottom Right Cricket Balls with motion arcs)
          Positioned.fill(
            child: CustomPaint(
              painter: CricketBallWatermarkPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team Management',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Manage teams and players for this tournament',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF028A6B),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Animated Sliding Pill Tab Bar (Teams / Players)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: _buildSlidingPillTabBar(),
                ),

                // Search Bar + Filter/Add Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13.5,
                                  ),
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: _tabController.index == 0
                                        ? 'Search teams by name or code...'
                                        : 'Search players by name or role...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppTheme.textPrimary, size: 20),
                          onPressed: () {
                            if (_tabController.index == 1) {
                              _showPlayerFilterSheet();
                            } else {
                              CustomNotification.show(
                                context,
                                'Filtering by team code & activity status',
                                type: NotificationType.info,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Action & Counter Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_tabController.index == 0) {
                            _showAddTeamDialog();
                          } else {
                            Navigator.pushNamed(context, AppRoutes.playerManagement);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF028A6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          elevation: 2,
                          shadowColor: const Color(0xFF028A6B).withValues(alpha: 0.3),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          _tabController.index == 0 ? 'Add Team' : 'Add Player',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Text(
                        _tabController.index == 0
                            ? '${filteredTeams.length} ${filteredTeams.length == 1 ? 'Team' : 'Teams'}'
                            : '${allPlayers.length} ${allPlayers.length == 1 ? 'Player' : 'Players'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // PageView with Smooth Tab Transition
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      _tabController.animateTo(idx);
                      setState(() {});
                    },
                    children: [
                      // TAB 1: TEAMS LIST VIEW
                      _buildTeamsTabContent(filteredTeams, storage),

                      // TAB 2: PLAYERS LIST VIEW
                      _buildPlayersTabContent(allPlayers, storage),
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

  // --- Professional Sliding Pill Tab Switcher ---
  Widget _buildSlidingPillTabBar() {
    final bool isTeamsActive = _tabController.index == 0;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;

          return Stack(
            children: [
              // Animated Background Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: isTeamsActive ? 0 : tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF028A6B).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Tab Text Buttons
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _tabController.animateTo(0);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: isTeamsActive ? FontWeight.w800 : FontWeight.w600,
                            color: isTeamsActive ? const Color(0xFF028A6B) : AppTheme.textMuted,
                          ),
                          child: const Text('Teams'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _tabController.animateTo(1);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: !isTeamsActive ? FontWeight.w800 : FontWeight.w600,
                            color: !isTeamsActive ? const Color(0xFF028A6B) : AppTheme.textMuted,
                          ),
                          child: const Text('Players'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- TEAMS TAB CONTENT ---
  Widget _buildTeamsTabContent(List<Team> filteredTeams, StorageService storage) {
    if (filteredTeams.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: 'No Teams Found',
        subtitle: 'Add your first team to get started with CricketVerse.',
        buttonLabel: 'Add Team',
        onButtonTap: _showAddTeamDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: filteredTeams.length,
      itemBuilder: (_, i) {
        final team = filteredTeams[i];
        final color = Color(int.tryParse(team.logoColorHex) ?? 0xFF028A6B);

        return CardEntranceAnimation(
          key: ValueKey(team.id),
          index: i,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                // Shield / Team Logo
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppTheme.accentRed,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Team Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            team.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              team.shortName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team.players.length} Players • 8 Support Staff',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF16A34A),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF028A6B), size: 18),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.editTeam, arguments: team),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_rounded, color: AppTheme.accentRed, size: 18),
                        onPressed: () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Delete Team',
                            message: 'Are you sure you want to delete "${team.name}"? This action cannot be undone.',
                          );
                          if (confirmed == true && mounted) {
                            storage.deleteTeam(team.id);
                            if (mounted) {
                              CustomNotification.show(
                                context,
                                'Team "${team.name}" deleted',
                                type: NotificationType.error,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- PLAYERS TAB CONTENT ---
  Widget _buildPlayersTabContent(List<Map<String, dynamic>> allPlayers, StorageService storage) {
    if (allPlayers.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_rounded,
        title: 'No Players Found',
        subtitle: 'Try adjusting your search query or role filter.',
        buttonLabel: 'Add Player',
        onButtonTap: () => Navigator.pushNamed(context, AppRoutes.playerManagement),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: allPlayers.length,
      itemBuilder: (_, i) {
        final player = allPlayers[i]['player'] as Player;
        final team = allPlayers[i]['team'] as Team;
        final teamColor = Color(int.tryParse(team.logoColorHex) ?? 0xFF028A6B);

        return CardEntranceAnimation(
          key: ValueKey('${team.id}_${player.id}'),
          index: i,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                // Avatar with role badge
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFDCFCE7),
                  child: Text(
                    player.name.isNotEmpty ? player.name[0] : 'P',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF028A6B),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            player.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (player.isCaptain) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentGold),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              player.role,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${team.name}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: teamColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 18),
                  onPressed: () {
                    storage.removePlayer(team.id, player.id);
                    CustomNotification.show(context, '${player.name} removed from ${team.shortName}', type: NotificationType.info);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Filter sheet for Players Role
  void _showPlayerFilterSheet() {
    final roles = ['All', 'Batter', 'Bowler', 'All-rounder', 'Wicketkeeper'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Players by Role',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((r) {
                final isSel = r == _selectedRoleFilter;
                return ChoiceChip(
                  label: Text(r),
                  selected: isSel,
                  selectedColor: const Color(0xFFDCFCE7),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: isSel ? const Color(0xFF028A6B) : AppTheme.textSecondary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedRoleFilter = r);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter for Translucent Mint Green Cricket Ball Watermarks ---
class CricketBallWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ballPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final seamPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // 1. TOP RIGHT CRICKET BALL WATERMARK
    final topCenter = Offset(size.width * 0.88, size.height * 0.07);
    final topRadius = size.width * 0.22;
    canvas.drawCircle(topCenter, topRadius, ballPaint);

    // Seam Arcs for top ball
    final topPath = Path();
    topPath.addArc(
      Rect.fromCircle(center: topCenter, radius: topRadius * 0.85),
      -math.pi / 4,
      math.pi * 0.9,
    );
    canvas.drawPath(topPath, seamPaint);

    final topMotionPath = Path();
    topMotionPath.addArc(
      Rect.fromCircle(center: Offset(topCenter.dx - 15, topCenter.dy + 10), radius: topRadius * 1.1),
      math.pi * 0.7,
      math.pi * 0.6,
    );
    canvas.drawPath(topMotionPath, arcPaint);

    // 2. BOTTOM RIGHT CRICKET BALL WATERMARK
    final bottomCenter = Offset(size.width * 0.82, size.height * 0.86);
    final bottomRadius = size.width * 0.32;
    canvas.drawCircle(bottomCenter, bottomRadius, ballPaint);

    // Dual Seam Lines for bottom ball
    final bottomSeamPath1 = Path();
    bottomSeamPath1.addArc(
      Rect.fromCircle(center: bottomCenter, radius: bottomRadius * 0.88),
      -math.pi * 0.6,
      math.pi * 0.85,
    );
    canvas.drawPath(bottomSeamPath1, seamPaint);

    final bottomSeamPath2 = Path();
    bottomSeamPath2.addArc(
      Rect.fromCircle(center: bottomCenter, radius: bottomRadius * 0.72),
      -math.pi * 0.55,
      math.pi * 0.8,
    );
    canvas.drawPath(bottomSeamPath2, seamPaint);

    // Dynamic Swoosh Trails
    final trailPath = Path();
    trailPath.moveTo(size.width * 0.5, size.height * 0.98);
    trailPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.92,
      bottomCenter.dx,
      bottomCenter.dy + bottomRadius * 0.5,
    );
    canvas.drawPath(trailPath, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
