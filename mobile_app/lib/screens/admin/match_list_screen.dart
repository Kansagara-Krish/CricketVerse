// lib/screens/admin/match_list_screen.dart
// Upcoming / Live / Completed matches with TabBar

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../core/widgets/app_notification.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final live = storage.matches.where((m) => m.status == 'Live').toList();
    final upcoming = storage.matches.where((m) => m.status == 'Upcoming').toList();
    final completed = storage.matches.where((m) => m.status == 'Completed').toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Matches', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: 'LIVE (${live.length})'),
            Tab(text: 'UPCOMING (${upcoming.length})'),
            Tab(text: 'COMPLETED (${completed.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scheduleMatch),
            tooltip: 'Schedule Match',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MatchListView(matches: live, emptyMsg: 'No live matches right now.', emptyIcon: Icons.sports_cricket),
          _MatchListView(matches: upcoming, emptyMsg: 'No upcoming matches scheduled.\nTap + to schedule one.', emptyIcon: Icons.calendar_today_outlined,
              onAdd: () => Navigator.pushNamed(context, AppRoutes.scheduleMatch)),
          _MatchListView(matches: completed, emptyMsg: 'No completed matches yet.', emptyIcon: Icons.check_circle_outline),
        ],
      ),
    );
  }
}

class _MatchListView extends StatelessWidget {
  final List<CricketMatch> matches;
  final String emptyMsg;
  final IconData emptyIcon;
  final VoidCallback? onAdd;

  const _MatchListView({
    required this.matches,
    required this.emptyMsg,
    required this.emptyIcon,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: 'No Matches',
        subtitle: emptyMsg,
        buttonLabel: onAdd != null ? 'Schedule Match' : null,
        onButtonTap: onAdd,
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      backgroundColor: Colors.white,
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 800)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (_, i) => CardEntranceAnimation(
          index: i,
          child: _MatchTile(
            key: ValueKey(matches[i].id),
            match: matches[i],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatefulWidget {
  final CricketMatch match;
  const _MatchTile({super.key, required this.match});

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile> with SingleTickerProviderStateMixin {
  late AnimationController _exitController;
  late Animation<double> _fadeAnim;
  late Animation<double> _sizeAnim;
  late Animation<Offset> _slideAnim;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOutCubic,
    );
    _sizeAnim = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.15, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    final confirmed = await _showDeleteConfirmationDialog(context, widget.match);
    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);

      // Play smooth card collapse/slide exit animation
      await _exitController.reverse();

      if (!mounted) return;
      final storage = Provider.of<StorageService>(context, listen: false);
      final success = await storage.deleteMatch(widget.match.id);

      if (mounted) {
        if (success) {
          AppNotification.success(
            context,
            title: 'Match Deleted',
            message: '${widget.match.teamA.shortName} vs ${widget.match.teamB.shortName} was deleted successfully.',
          );
        } else {
          // In case deletion fails, animate back
          _exitController.forward();
          setState(() => _isDeleting = false);
          AppNotification.error(
            context,
            title: 'Delete Failed',
            message: 'Unable to delete match. Please try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final statusColor = AppTheme.statusColor(match.status);
    final isLive = match.status == 'Live';

    return SizeTransition(
      sizeFactor: _sizeAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: GestureDetector(
            onTap: _isDeleting ? null : () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: match),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isLive ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isLive ? '● LIVE' : match.status.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          match.matchType,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primaryBlue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Match Details',
                          onPressed: _isDeleting
                              ? null
                              : () => Navigator.pushNamed(context, AppRoutes.scheduleMatch, arguments: match),
                        ),
                      ],
                    ),
                  ),

                  // Score Display
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Team A
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      match.teamA.shortName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (match.runsA > 0 || match.wicketsA > 0 || match.oversA > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${match.runsA}/${match.wicketsA}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '(${match.oversA} ov)',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // VS Center
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Text(
                                'VS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0x3D0F172A),
                                ),
                              ),
                              if (match.target > 0 && !match.isFirstInnings)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'T: ${match.target}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      color: AppTheme.accentGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Team B
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      match.teamB.shortName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                    if (match.runsB > 0 || match.wicketsB > 0 || match.oversB > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${match.runsB}/${match.wicketsB}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '(${match.oversB} ov)',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted),
                                      ),
                                    ],
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
                  ),

                  // Footer Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          '${match.date} • ${match.time}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textMuted),
                        ),
                        const Spacer(),
                        _ActionChip(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: AppTheme.accentRed,
                          onTap: _handleDelete,
                        ),
                        const SizedBox(width: 8),
                        _ActionChip(
                          icon: Icons.info_outline,
                          label: 'Details',
                          color: AppTheme.primaryBlue,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: match),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _isPressed ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color.withValues(alpha: _isPressed ? 0.45 : 0.2)),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: widget.color),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass animated delete confirmation dialog
Future<bool?> _showDeleteConfirmationDialog(BuildContext context, CricketMatch match) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curve = Curves.easeOutBack.transform(anim.value);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8 * anim.value, sigmaY: 8 * anim.value),
        child: Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + (0.15 * curve),
            child: Center(
              child: _DeleteConfirmationDialogContent(match: match),
            ),
          ),
        ),
      );
    },
  );
}

class _DeleteConfirmationDialogContent extends StatefulWidget {
  final CricketMatch match;
  const _DeleteConfirmationDialogContent({required this.match});

  @override
  State<_DeleteConfirmationDialogContent> createState() => _DeleteConfirmationDialogContentState();
}

class _DeleteConfirmationDialogContentState extends State<_DeleteConfirmationDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final statusColor = AppTheme.statusColor(match.status);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.accentRed.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Pulsing Danger Badge
            ScaleTransition(
              scale: _pulseScale,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentRed.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentRed.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 30,
                  color: AppTheme.accentRed,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Delete Match?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are you sure you want to permanently delete this match?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Match Card Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      TeamLogo(
                        teamName: match.teamA.name,
                        shortName: match.teamA.shortName,
                        logoColorHex: match.teamA.logoColorHex,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.teamA.shortName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'VS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0x3D0F172A),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          match.teamB.shortName,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TeamLogo(
                        teamName: match.teamB.name,
                        shortName: match.teamB.shortName,
                        logoColorHex: match.teamB.logoColorHex,
                        size: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          match.status.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Text(
                        '${match.date} • ${match.venue}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Warning Notice Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 15, color: AppTheme.accentRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'All ball-by-ball commentary, scorecard, and player stats for this match will be lost.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shadowColor: AppTheme.accentRed.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

