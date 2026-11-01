import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/widgets/team_logo.dart';
import '../../core/widgets/exit_app_dialog.dart';
import '../../core/widgets/card_entrance_animation.dart';
import '../../services/socket_service.dart';
import '../../core/widgets/network_status_bar.dart';
import '../../services/network_connectivity_service.dart';

class ScorerDashboard extends StatefulWidget {
  const ScorerDashboard({super.key});

  @override
  State<ScorerDashboard> createState() => _ScorerDashboardState();
}

class _ScorerDashboardState extends State<ScorerDashboard> {
  String? _tossWinner;
  String _tossDecision = 'Bat';
  bool _isSubmittingToss = false;

  // Centralized scoring action processing & button locking state
  bool _isProcessing = false;
  bool _isOverDialogOpen = false;
  String? _processingAction;
  String? _successAction;
  String? _errorAction;

  Future<void> _handleScoringAction({
    required String actionId,
    required Future<bool> Function() execute,
    String? successMessage,
    VoidCallback? onSuccess,
  }) async {
    if (_isProcessing) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
      _processingAction = actionId;
      _successAction = null;
      _errorAction = null;
    });

    bool success = false;
    try {
      success = await execute();
    } catch (err) {
      success = false;
      debugPrint('Error executing scoring action: $err');
    }

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      setState(() {
        _successAction = actionId;
      });

      // Allow 280ms for user to perceive green checkmark and success flash
      await Future.delayed(const Duration(milliseconds: 280));

      if (mounted) {
        if (successMessage != null && successMessage.isNotEmpty) {
          CustomNotification.show(context, successMessage, type: NotificationType.success);
        }
        setState(() {
          _isProcessing = false;
          _processingAction = null;
          _successAction = null;
        });

        if (onSuccess != null) {
          onSuccess();
        }
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorAction = actionId;
      });

      if (mounted) {
        CustomNotification.show(
          context,
          'Failed to record delivery. Please retry.',
          type: NotificationType.error,
        );
      }

      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingAction = null;
          _errorAction = null;
        });
      }
    }
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = Provider.of<StorageService>(context, listen: false);
      if (storage.activeScorerMatchId != null) {
        storage.subscribeToMatchLiveUpdates(storage.activeScorerMatchId!);
      }
    });
  }

  @override
  void dispose() {
    final storage = Provider.of<StorageService>(context, listen: false);
    if (storage.activeScorerMatchId != null) {
      storage.unsubscribeFromMatchLiveUpdates(storage.activeScorerMatchId!);
    }
    super.dispose();
  }

  void _logout() async {
    final confirm = await LogoutDialog.show(context);
    if (confirm == true && mounted) {
      await Provider.of<StorageService>(context, listen: false).logout();
      if (mounted) {
        CustomNotification.show(context, 'Successfully logged out!', type: NotificationType.success);
        Navigator.pushReplacementNamed(context, AppRoutes.auth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final matchId = storage.activeScorerMatchId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If currently on a specific match score update page, pressing back returns to Assigned Matches List
        if (storage.activeScorerMatchId != null) {
          storage.setActiveScorerMatchId(null);
          return;
        }

        // 2. On Assigned Matches List -> confirm exit
        final shouldExit = await ExitAppDialog.show(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: matchId == null
          ? _buildAssignedMatchesListView(storage)
          : _buildMatchScoreUpdatePage(storage, matchId),
    );
  }

  // ===========================================================================
  // PAGE 1: ASSIGNED MATCHES LIST
  // ===========================================================================
  Widget _buildAssignedMatchesListView(StorageService storage) {
    final assignedMatches = storage.matches.where((m) {
      if (storage.currentUserEmail == null || storage.currentUserEmail!.isEmpty) return true;
      final email = storage.currentUserEmail!.toLowerCase().trim();
      final scorer = m.scorerUsername.toLowerCase().trim();
      if (scorer.isEmpty) return true;
      if (scorer == email) return true;
      if (email.contains('scorer') || email.contains('manager') || email.contains('admin')) return true;
      return scorer.contains(email.split('@')[0]);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Assigned Matches',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRed),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          NetworkStatusBar(
            pendingCount: storage.pendingScoreCount,
            onRetry: () => NetworkConnectivityService().checkConnectivity(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: () async => await storage.loadData(),
              child: assignedMatches.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.bgSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.assignment_turned_in_outlined,
                                    size: 44,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Matches Assigned',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Matches assigned to your manager/scorer account will appear here. Pull down to refresh.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: assignedMatches.length,
                      itemBuilder: (context, i) {
                        final match = assignedMatches[i];
                        final statusColor = AppTheme.statusColor(match.status);

                        return CardEntranceAnimation(
                          index: i,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCard,
                            child: InkWell(
                              onTap: () async {
                                storage.setActiveScorerMatchId(match.id);
                                storage.subscribeToMatchLiveUpdates(match.id);
                                await storage.refreshMatch(match.id);
                              },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        match.status == 'Live' ? '● LIVE' : match.status.toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${match.matchType} • ${match.date}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
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
                                                  match.teamA.shortName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (match.status != 'Upcoming')
                                                  Text(
                                                    '${match.runsA}/${match.wicketsA} (${match.oversA})',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      color: AppTheme.textSecondary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        'VS',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
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
                                                  match.teamB.shortName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (match.status != 'Upcoming')
                                                  Text(
                                                    '${match.runsB}/${match.wicketsB} (${match.oversB})',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      color: AppTheme.textSecondary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
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
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tap to Update Score',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryBlue),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE 2: SPECIFIC MATCH SCORE UPDATE PAGE
  // ===========================================================================
  Widget _buildMatchScoreUpdatePage(StorageService storage, String matchId) {
    final matches = storage.matches.where((m) => m.id == matchId).toList();
    if (matches.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => storage.setActiveScorerMatchId(null),
          ),
          title: const Text('Match Not Found'),
        ),
        body: const Center(child: Text('Assigned match not found.')),
      );
    }

    final match = matches.first;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          tooltip: 'Back to Assigned Matches',
          onPressed: () => storage.setActiveScorerMatchId(null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${match.teamA.shortName} vs ${match.teamB.shortName}',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              'Score Update Control',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (match.status == 'Live' || match.status == 'Completed' || match.balls.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.accentRed),
              tooltip: 'Reset Score to 0/0',
              onPressed: _isProcessing ? null : () => _showResetConfirmation(context, storage, match.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.accentGold),
              tooltip: 'Undo / Edit Ball',
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.pushNamed(context, AppRoutes.editBall);
                    },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRed),
            tooltip: 'Logout',
            onPressed: _isProcessing ? null : _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          NetworkStatusBar(
            pendingCount: storage.pendingScoreCount,
            onRetry: () => NetworkConnectivityService().checkConnectivity(),
          ),
          Expanded(
            child: ((match.status == 'Upcoming' || match.tossWinner.isEmpty || match.tossDecision.isEmpty)
                ? _buildSetupView(match, storage)
                : _buildScoringView(match, storage)),
          ),
        ],
      ),
    );
  }

  // --- Match Setup View (Toss & Starting Lineup) ---
  Widget _buildSetupView(CricketMatch match, StorageService storage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED MATCH',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamA.name} vs ${match.teamB.name}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.matchType} • ${match.date} ${match.time}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Toss Configuration',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),

          Text('Toss Winner', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            initialValue: _tossWinner,
            decoration: InputDecoration(
              fillColor: Colors.black.withValues(alpha: 0.02),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              DropdownMenuItem(value: match.teamA.name, child: Text(match.teamA.name)),
              DropdownMenuItem(value: match.teamB.name, child: Text(match.teamB.name)),
            ],
            onChanged: (val) => setState(() => _tossWinner = val),
            hint: const Text('Select Toss Winner', style: TextStyle(color: Colors.black38)),
          ),
          const SizedBox(height: 16),

          Text('Toss Decision', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bgMedium,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            initialValue: _tossDecision,
            decoration: InputDecoration(
              fillColor: Colors.black.withValues(alpha: 0.02),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'Bat', child: Text('Choose to Bat')),
              DropdownMenuItem(value: 'Bowl', child: Text('Choose to Bowl')),
            ],
            onChanged: (val) => setState(() => _tossDecision = val ?? 'Bat'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingToss
                  ? null
                  : () async {
                      if (_tossWinner == null) {
                        CustomNotification.show(
                          context,
                          'Please select the toss winner!',
                          type: NotificationType.warning,
                        );
                        return;
                      }

                      final teamAPlayers = _getTeamPlayers(match, match.teamA.id, storage);
                      final teamBPlayers = _getTeamPlayers(match, match.teamB.id, storage);

                      final captainA = teamAPlayers.firstWhere(
                        (p) => p.isCaptain,
                        orElse: () => teamAPlayers.isNotEmpty
                            ? teamAPlayers[0]
                            : Player(id: '', name: 'Captain A', role: 'Batter', nationality: ''),
                      ).name;

                      final captainB = teamBPlayers.firstWhere(
                        (p) => p.isCaptain,
                        orElse: () => teamBPlayers.isNotEmpty
                            ? teamBPlayers[0]
                            : Player(id: '', name: 'Captain B', role: 'Batter', nationality: ''),
                      ).name;

                      final winnerCaptain = (_tossWinner == match.teamA.name) ? captainA : captainB;
                      
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Confirm Toss Results'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Winner: $_tossWinner (Captain: $winnerCaptain)'),
                              const SizedBox(height: 8),
                              Text('Decision: $_tossDecision first'),
                              const SizedBox(height: 12),
                              Text('Team A: ${match.teamA.name}\nCaptain: $captainA', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                              Text('Team B: ${match.teamB.name}\nCaptain: $captainB', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        setState(() => _isSubmittingToss = true);
                        try {
                          String firstBattingId;
                          if (_tossWinner == match.teamA.name) {
                            firstBattingId = _tossDecision == 'Bat' ? match.teamA.id : match.teamB.id;
                          } else {
                            firstBattingId = _tossDecision == 'Bat' ? match.teamB.id : match.teamA.id;
                          }

                          final ok = await storage.startMatchSetup(match.id, _tossWinner!, _tossDecision, firstBattingId);
                          if (ok) {
                            if (mounted) {
                              CustomNotification.show(
                                context,
                                'Toss confirmed! Live scoring started.',
                                type: NotificationType.success,
                              );
                            }
                          } else {
                            if (mounted) {
                              CustomNotification.show(
                                context,
                                'Failed to confirm toss. Please try again.',
                                type: NotificationType.error,
                              );
                            }
                          }
                        } catch (err) {
                          if (mounted) {
                            CustomNotification.show(
                              context,
                              'Error confirming toss: $err',
                              type: NotificationType.error,
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSubmittingToss = false);
                          }
                        }
                      }
                    },
              icon: _isSubmittingToss
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(_isSubmittingToss ? 'Saving Toss...' : 'Start Match & Lineups'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getMaxOvers(String matchType) {
    if (matchType.isEmpty) return 20;
    final mt = matchType.toUpperCase().trim();
    if (mt.contains('10')) return 10;
    if (mt.contains('20')) return 20;
    if (mt.contains('50') || mt.contains('ODI')) return 50;
    if (mt.contains('TEST')) return 90;
    final match = RegExp(r'(\d+)').firstMatch(mt);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 20;
    }
    return 20;
  }

  void _showEditTargetDialog(BuildContext context, StorageService storage, CricketMatch match) {
    final ctrl = TextEditingController(text: match.target > 0 ? match.target.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.track_changes_rounded, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 8),
            Text(
              'Set Chase Target',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the chase target for this match. Remaining runs will automatically decrease dynamically as team runs increase.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Target Runs',
                hintText: 'e.g. 165',
                prefixIcon: const Icon(Icons.sports_score_rounded, color: AppTheme.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 0) {
                storage.setTarget(val);
                Navigator.pop(ctx);
                CustomNotification.show(context, 'Target set to $val runs!', type: NotificationType.success);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save Target', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Ball-by-ball Live Scoring View ---
  Widget _buildScoringView(CricketMatch match, StorageService storage) {
    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    final battingPlayers = _getBattingPlayers(match, storage);
    final bowlingPlayers = _getBowlingPlayers(match, storage);

    final striker = battingPlayers.firstWhere(
      (p) => p.id == match.currentStrikerId,
      orElse: () => battingPlayers.isNotEmpty
          ? battingPlayers[0]
          : Player(id: 'striker_fallback', name: '${battingTeam.shortName} Striker', role: 'Batter', nationality: ''),
    );
    final nonStriker = battingPlayers.firstWhere(
      (p) => p.id == match.currentNonStrikerId,
      orElse: () => battingPlayers.length > 1
          ? battingPlayers[1]
          : (battingPlayers.isNotEmpty
              ? battingPlayers[0]
              : Player(id: 'non_striker_fallback', name: '${battingTeam.shortName} Non-Striker', role: 'Batter', nationality: '')),
    );
    final bowler = bowlingPlayers.firstWhere(
      (p) => p.id == match.currentBowlerId,
      orElse: () => bowlingPlayers.isNotEmpty
          ? bowlingPlayers.last
          : Player(id: 'bowler_fallback', name: '${bowlingTeam.shortName} Bowler', role: 'Bowler', nationality: ''),
    );

    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final runs = isTeamABatting ? match.runsA : match.runsB;
    final wickets = isTeamABatting ? match.wicketsA : match.wicketsB;
    final overs = isTeamABatting ? match.oversA : match.oversB;
    final int maxOvers = _getMaxOvers(match.matchType);
    final int totalBalls = maxOvers * 6;
    final int oversInt = overs.toInt();
    final int ballsInCurrentOver = ((overs - oversInt) * 10).round();
    final int ballsBowled = (oversInt * 6) + ballsInCurrentOver;
    final int remainingBalls = (totalBalls - ballsBowled).clamp(0, totalBalls);
    final double actualOvers = ballsBowled > 0 ? (ballsBowled / 6.0) : 0.0;
    final double crr = actualOvers > 0 ? (runs / actualOvers) : 0.0;

    final bool hasTarget = match.target > 0;
    final int target = match.target;
    final int runsNeeded = target - runs;
    final int remainingRuns = runsNeeded > 0 ? runsNeeded : 0;
    final double rrr = remainingBalls > 0 && hasTarget ? (remainingRuns / remainingBalls) * 6.0 : 0.0;

    return Column(
      children: [
        // 1. Sticky Scoreboard Panel (does not scroll)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${match.teamA.shortName} vs ${match.teamB.shortName} - ${match.matchType}',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(radius: 2.5, backgroundColor: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text('LIVE', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Large Score Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TeamLogo.fromTeam(battingTeam, size: 36),
                  const SizedBox(width: 10),
                  Text(
                    '${battingTeam.shortName} ',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.25),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      '$runs/$wickets',
                      key: ValueKey('$runs/$wickets'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  'Overs: ${overs.toStringAsFixed(1)} (CRR: ${crr.toStringAsFixed(1)})',
                  key: ValueKey('${overs.toStringAsFixed(1)}_${crr.toStringAsFixed(1)}'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 10),

              // Dynamic Remaining Runs & Remaining Balls Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasTarget
                        ? (remainingRuns <= 0
                            ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                            : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)])
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasTarget
                        ? (remainingRuns <= 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : AppTheme.primaryBlue.withValues(alpha: 0.25))
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dynamic Live Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasTarget ? Icons.track_changes_rounded : Icons.sports_cricket_rounded,
                              size: 14,
                              color: hasTarget
                                  ? (remainingRuns <= 0 ? const Color(0xFF10B981) : AppTheme.primaryBlue)
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              hasTarget
                                  ? (remainingRuns <= 0
                                      ? '🎯 TARGET ACHIEVED!'
                                      : 'CHASE: NEED $remainingRuns RUNS IN $remainingBalls BALLS')
                                  : '1ST INNINGS • SETTING TARGET',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: hasTarget
                                    ? (remainingRuns <= 0 ? const Color(0xFF10B981) : AppTheme.primaryBlue)
                                    : AppTheme.textSecondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showEditTargetDialog(context, storage, match),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded, size: 12, color: AppTheme.primaryBlue),
                                const SizedBox(width: 2),
                                Text(
                                  hasTarget ? 'Target: $target' : 'Set Target',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 3 Metric Pills: Remaining Runs | Remaining Balls | RRR/Projected
                    Row(
                      children: [
                        // Dynamic Remaining Runs
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasTarget && remainingRuns <= 12
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasTarget ? 'RUNS NEEDED' : 'CURR. RUN RATE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                      child: Text(
                                        hasTarget ? '$remainingRuns' : crr.toStringAsFixed(1),
                                        key: ValueKey('first_metric_${hasTarget ? remainingRuns : crr.toStringAsFixed(1)}'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: hasTarget
                                              ? (remainingRuns <= 0 ? const Color(0xFF10B981) : const Color(0xFFD97706))
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasTarget ? 'runs' : 'CRR',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Dynamic Remaining Balls
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BALLS LEFT',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                      child: Text(
                                        '$remainingBalls',
                                        key: ValueKey('rem_balls_$remainingBalls'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: remainingBalls <= 12 ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'balls',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Dynamic RRR or Projected Score
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasTarget ? 'REQ. RUN RATE' : 'PROJECTED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                      child: Text(
                                        hasTarget
                                            ? rrr.toStringAsFixed(1)
                                            : '${crr > 0 ? (runs + (remainingBalls / 6.0) * crr).round() : (runs + remainingBalls)}',
                                        key: ValueKey('rem_metric_${hasTarget ? rrr.toStringAsFixed(1) : crr.toStringAsFixed(1)}'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: hasTarget
                                              ? (rrr > 12.0 ? const Color(0xFFDC2626) : const Color(0xFF0F172A))
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasTarget ? 'RRR' : 'runs',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
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
            ],
          ),
        ),

        // Real-time Status / Loading Banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: (_isProcessing || _successAction != null) ? 28 : 0,
          color: _successAction != null
              ? const Color(0xFF10B981).withValues(alpha: 0.10)
              : AppTheme.primaryBlue.withValues(alpha: 0.08),
          child: ClipRect(
            child: (_isProcessing || _successAction != null)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_successAction != null) ...[
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'Score updated successfully',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Updating score...',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // 2. Scrollable Scoring Controls
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryBlue,
            backgroundColor: Colors.white,
            onRefresh: () async => await storage.refreshMatch(match.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Batsmen & Bowler interactive selector card (Minimum Taps)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.glassCard,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildInteractiveRow(
                              context,
                              'Striker',
                              striker.name,
                              Image.asset(
                                'assets/images/icon_striker_bat.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              () => _showPlayerSelectionSheet(context, true, battingPlayers, storage),
                              stats: '(${striker.runsScored} off ${striker.ballsFaced})',
                            ),
                            const Divider(height: 16),
                            _buildInteractiveRow(
                              context,
                              'Non-Striker',
                              nonStriker.name,
                              Image.asset(
                                'assets/images/icon_non_striker_batsman.png',
                                width: 22,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                              () => _showPlayerSelectionSheet(context, false, battingPlayers, storage),
                              stats: '(${nonStriker.runsScored} off ${nonStriker.ballsFaced})',
                            ),
                          ],
                        ),
                      ),
                      _ScorerActionButton(
                        actionId: 'swap_strikers',
                        isProcessing: _isProcessing,
                        processingAction: _processingAction,
                        successAction: _successAction,
                        errorAction: _errorAction,
                        onTap: () => _handleScoringAction(
                          actionId: 'swap_strikers',
                          execute: () async {
                            storage.swapStrikers();
                            return true;
                          },
                          successMessage: 'Positions swapped',
                        ),
                        builder: (context, isCurrent, isAnyProcessing) {
                          final isThisProcessing = _isProcessing && _processingAction == 'swap_strikers';
                          final isThisSuccess = _successAction == 'swap_strikers';

                          return Container(
                            margin: const EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isThisSuccess
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : const Color(0xFF0D9472).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: isThisSuccess
                                        ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                                        : null,
                                  ),
                                  child: Center(
                                    child: isThisProcessing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9472)),
                                          )
                                        : isThisSuccess
                                            ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 20)
                                            : const Icon(Icons.swap_vert_rounded, color: Color(0xFF0D9472)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SWAP',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: isThisSuccess ? const Color(0xFF10B981) : const Color(0xFF0D9472),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final isAwaitingBowler = _isOverAwaitingNewBowler(match);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: isAwaitingBowler
                          ? BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            )
                          : AppTheme.glassCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAwaitingBowler)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'OVER COMPLETED • SELECT NEW BOWLER FOR OVER ${(overs + 1).toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          _buildInteractiveRow(
                            context,
                            isAwaitingBowler ? 'SELECT NEXT BOWLER' : 'Active Bowler',
                            bowler.name,
                            Image.asset(
                              'assets/images/icon_bowler_ball.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                            ),
                            () => isAwaitingBowler
                                ? _showOverCompletedDialog(context, _getBowlingPlayers(match, storage), storage, (overs).round())
                                : _showBowlerSelectionSheet(context, _getBowlingPlayers(match, storage), storage),
                            stats: isAwaitingBowler
                                ? 'Over Finished'
                                : '(${bowler.oversBowled.toStringAsFixed(1)} ov • ${bowler.wicketsTaken}/${bowler.runsConceded})',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Large Run Buttons Grid (0, 1, 2, 3, 4, 6)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _buildScoreBtn('0', 'Dot', AppTheme.textSecondary, () => _scoreBall(storage, 0, 'None', 0, false)),
                    _buildScoreBtn('1', 'Single', AppTheme.textPrimary, () => _scoreBall(storage, 1, 'None', 0, false)),
                    _buildScoreBtn('2', 'Double', AppTheme.textPrimary, () => _scoreBall(storage, 2, 'None', 0, false)),
                    _buildScoreBtn('3', 'Triple', AppTheme.textPrimary, () => _scoreBall(storage, 3, 'None', 0, false)),
                    _buildScoreBtn('4', 'Boundary', const Color(0xFFD97706), () => _scoreBall(storage, 4, 'None', 0, false)),
                    _buildScoreBtn('6', 'Maximum', Colors.white, () => _scoreBall(storage, 6, 'None', 0, false), isMaximum: true),
                  ],
                ),
                const SizedBox(height: 14),

                // Extras & Wickets (Pill Buttons)
                Row(
                  children: [
                    Expanded(child: _buildExtraBtn('Wide (+1)', Icons.compare_arrows_rounded, () => _scoreBall(storage, 0, 'Wide', 1, false))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildExtraBtn('No Ball (+1)', Icons.sports_baseball_rounded, () => _scoreBall(storage, 0, 'No Ball', 1, false))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildExtraBtn('Leg Bye (+1)', Icons.directions_walk_rounded, () => _scoreBall(storage, 0, 'Leg Bye', 1, false))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildExtraBtn('Custom Extra...', Icons.add_moderator_rounded, () => _showCustomExtraDialog(storage))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _ScorerActionButton(
                        actionId: 'record_wicket',
                        isProcessing: _isProcessing,
                        processingAction: _processingAction,
                        successAction: _successAction,
                        errorAction: _errorAction,
                        onTap: () => _showWicketDialog(storage),
                        builder: (context, isCurrent, isAnyProcessing) {
                          final isThisProcessing = _isProcessing && _processingAction == 'record_wicket';
                          final isThisSuccess = _successAction == 'record_wicket';
                          final isThisError = _errorAction == 'record_wicket';

                          Color bgColor = AppTheme.accentRed.withValues(alpha: 0.08);
                          Color borderColor = AppTheme.accentRed.withValues(alpha: 0.2);
                          if (isThisSuccess) {
                            bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                            borderColor = const Color(0xFF10B981);
                          } else if (isThisError) {
                            bgColor = AppTheme.accentRed.withValues(alpha: 0.18);
                            borderColor = AppTheme.accentRed;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: (isThisSuccess || isThisError) ? 1.6 : 1.0),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: isThisSuccess
                                  ? const Row(
                                      key: ValueKey('wicket_check'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Wicket Recorded',
                                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : isThisProcessing
                                      ? const Row(
                                          key: ValueKey('wicket_spinner'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentRed),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Recording Wicket...',
                                              style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          key: const ValueKey('wicket_normal'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.outbox_rounded, color: AppTheme.accentRed, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Record Wicket',
                                              style: GoogleFonts.plusJakartaSans(color: AppTheme.accentRed, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _ScorerActionButton(
                        actionId: 'undo_ball',
                        isProcessing: _isProcessing,
                        processingAction: _processingAction,
                        successAction: _successAction,
                        errorAction: _errorAction,
                        onTap: match.balls.isEmpty ? null : () => _showUndoConfirmation(context, storage),
                        builder: (context, isCurrent, isAnyProcessing) {
                          final isThisProcessing = _isProcessing && _processingAction == 'undo_ball';
                          final isThisSuccess = _successAction == 'undo_ball';
                          final isThisError = _errorAction == 'undo_ball';

                          Color bgColor = match.balls.isEmpty ? Colors.black.withValues(alpha: 0.02) : Colors.white;
                          Color borderColor = match.balls.isEmpty
                              ? const Color(0xFFE2E8F0)
                              : AppTheme.textSecondary.withValues(alpha: 0.4);
                          if (isThisSuccess) {
                            bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                            borderColor = const Color(0xFF10B981);
                          } else if (isThisError) {
                            bgColor = AppTheme.accentRed.withValues(alpha: 0.12);
                            borderColor = AppTheme.accentRed;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: (isThisSuccess || isThisError) ? 1.6 : 1.0),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: isThisSuccess
                                  ? const Row(
                                      key: ValueKey('undo_check'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Reverted',
                                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : isThisProcessing
                                      ? const Row(
                                          key: ValueKey('undo_spinner'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Reverting...',
                                              style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          key: const ValueKey('undo_normal'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.undo_rounded,
                                              color: match.balls.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Undo',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: match.balls.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Actions: End Over, Innings / Match
                Row(
                  children: [
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        opacity: _isProcessing ? 0.50 : 1.0,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  storage.endOver();
                                  CustomNotification.show(
                                    context,
                                    'Over completed. Strike rotated.',
                                    type: NotificationType.success,
                                  );
                                },
                          icon: const Icon(Icons.rotate_right_rounded, size: 16),
                          label: const Text('End Over'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        opacity: _isProcessing ? 0.50 : 1.0,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  storage.endInningsOrMatch();
                                  CustomNotification.show(
                                    context,
                                    match.isFirstInnings ? 'Match Ended!' : 'Innings Switched! Target updated.',
                                    type: NotificationType.success,
                                  );
                                },
                          icon: const Icon(Icons.sports_cricket_rounded, size: 16),
                          label: Text(match.isFirstInnings ? 'End Innings' : 'End Match'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveRow(
    BuildContext context,
    String label,
    String name,
    Widget iconWidget,
    VoidCallback onTap, {
    String? stats,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      opacity: _isProcessing ? 0.50 : 1.0,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 32,
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (stats != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            stats,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0284C7),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF0D9472)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBtn(String val, String sub, Color col, VoidCallback onTap, {bool isMaximum = false}) {
    final actionId = 'run_$val';
    final isThisProcessing = _isProcessing && _processingAction == actionId;
    final isThisSuccess = _successAction == actionId;
    final isThisError = _errorAction == actionId;

    return _ScorerActionButton(
      actionId: actionId,
      isProcessing: _isProcessing,
      processingAction: _processingAction,
      successAction: _successAction,
      errorAction: _errorAction,
      onTap: onTap,
      builder: (context, isCurrent, isAnyProcessing) {
        Color bgColor;
        Color borderColor;
        if (isThisSuccess) {
          bgColor = const Color(0xFF10B981).withValues(alpha: isMaximum ? 0.85 : 0.15);
          borderColor = const Color(0xFF10B981);
        } else if (isThisError) {
          bgColor = AppTheme.accentRed.withValues(alpha: 0.15);
          borderColor = AppTheme.accentRed;
        } else {
          bgColor = isMaximum ? const Color(0xFF1E3A8A) : Colors.white;
          borderColor = const Color(0xFFE2E8F0);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: (isThisSuccess || isThisError) ? 1.8 : 1.0),
            boxShadow: [
              BoxShadow(
                color: isThisSuccess
                    ? const Color(0xFF10B981).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.01),
                blurRadius: isThisSuccess ? 8 : 4,
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: isThisSuccess
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('check'),
                      color: isMaximum ? Colors.white : const Color(0xFF10B981),
                      size: 26,
                    )
                  : isThisProcessing
                      ? SizedBox(
                          key: const ValueKey('spinner'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMaximum ? Colors.white : AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : Column(
                          key: const ValueKey('normal'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              val,
                              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: col),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              sub,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: isMaximum ? Colors.white70 : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtraBtn(String label, IconData icon, VoidCallback onTap) {
    final actionId = 'extra_${label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}';
    final isThisProcessing = _isProcessing && _processingAction == actionId;
    final isThisSuccess = _successAction == actionId;
    final isThisError = _errorAction == actionId;

    return _ScorerActionButton(
      actionId: actionId,
      isProcessing: _isProcessing,
      processingAction: _processingAction,
      successAction: _successAction,
      errorAction: _errorAction,
      onTap: onTap,
      builder: (context, isCurrent, isAnyProcessing) {
        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE2E8F0);
        if (isThisSuccess) {
          bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
          borderColor = const Color(0xFF10B981);
        } else if (isThisError) {
          bgColor = AppTheme.accentRed.withValues(alpha: 0.12);
          borderColor = AppTheme.accentRed;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: (isThisSuccess || isThisError) ? 1.6 : 1.0),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isThisSuccess
                ? const Row(
                    key: ValueKey('extra_check'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Recorded',
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  )
                : isThisProcessing
                    ? const Row(
                        key: ValueKey('extra_spinner'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Updating...',
                            style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('extra_normal'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: AppTheme.textSecondary, size: 15),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  bool _isOverAwaitingNewBowler(CricketMatch match) {
    if (match.status == 'Completed') return false;
    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final overs = isTeamABatting ? match.oversA : match.oversB;
    if (overs <= 0 || (overs * 10).round() % 10 != 0) return false;

    // Check if balls have been bowled in this innings
    if (match.balls.isEmpty) return false;

    // Find the bowler who bowled the last legal ball of this completed over
    String? lastLegalBowlerId;
    for (int i = match.balls.length - 1; i >= 0; i--) {
      final b = match.balls[i];
      if (b.extraType != 'Wide' && b.extraType != 'No Ball') {
        lastLegalBowlerId = b.bowlerId;
        break;
      }
    }

    // If active bowler is still the one who bowled this completed over, bowler change is required!
    return lastLegalBowlerId != null && match.currentBowlerId == lastLegalBowlerId;
  }

  List<Player> _getTeamPlayers(CricketMatch match, String teamId, StorageService storage) {
    final isTeamA = match.teamA.id == teamId;

    // 1. Get base players currently in this match's playingXI
    List<Player> currentXI = isTeamA
        ? List<Player>.from(match.playingXI_A)
        : List<Player>.from(match.playingXI_B);

    // 2. Find authoritative squad from storage.teams, fallback to match.teamA/B
    Team liveTeam = storage.teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => isTeamA ? match.teamA : match.teamB,
    );

    if (currentXI.isEmpty && liveTeam.players.isEmpty) {
      return [];
    }

    if (currentXI.isEmpty) {
      return List<Player>.from(liveTeam.players);
    }

    final livePlayerMap = {for (var p in liveTeam.players) p.id: p};

    // 3. Merge: Every player in currentXI gets latest name, role, details from liveTeam
    // while strictly retaining their match performance (runsScored, ballsFaced, wicketsTaken, oversBowled, isOut, etc.)
    final List<Player> mergedPlayers = [];
    final Set<String> processedIds = {};

    for (var p in currentXI) {
      final live = livePlayerMap[p.id];
      if (live != null) {
        mergedPlayers.add(Player(
          id: p.id,
          name: live.name,
          role: live.role,
          nationality: live.nationality,
          isCaptain: live.isCaptain,
          isViceCaptain: live.isViceCaptain,
          runsScored: p.runsScored,
          ballsFaced: p.ballsFaced,
          wicketsTaken: p.wicketsTaken,
          runsConceded: p.runsConceded,
          oversBowled: p.oversBowled,
          matchesPlayed: p.matchesPlayed,
          isOut: p.isOut,
          dismissalInfo: p.dismissalInfo,
        ));
      } else {
        // Player was removed from squad by Admin:
        // Keep them in match list ONLY if they actively participated or are active on pitch
        final hasParticipated = (p.runsScored > 0) ||
            (p.ballsFaced > 0) ||
            (p.oversBowled > 0) ||
            p.isOut ||
            (p.id == match.currentStrikerId) ||
            (p.id == match.currentNonStrikerId) ||
            (p.id == match.currentBowlerId);
        if (hasParticipated) {
          mergedPlayers.add(p);
        }
      }
      processedIds.add(p.id);
    }

    // 4. Also include any newly added squad members from liveTeam that aren't yet in currentXI
    for (var lp in liveTeam.players) {
      if (!processedIds.contains(lp.id)) {
        mergedPlayers.add(lp);
        processedIds.add(lp.id);
      }
    }

    return mergedPlayers;
  }

  List<Player> _getBattingPlayers(CricketMatch match, StorageService storage) {
    return _getTeamPlayers(match, match.battingTeamId, storage);
  }

  List<Player> _getBowlingPlayers(CricketMatch match, StorageService storage) {
    final bowlingTeamId = match.battingTeamId == match.teamA.id ? match.teamB.id : match.teamA.id;
    return _getTeamPlayers(match, bowlingTeamId, storage);
  }

  void _scoreBall(StorageService storage, int runs, String extraType, int extraRuns, bool isWicket) {
    if (storage.activeScorerMatchId == null) return;
    final match = storage.matches.firstWhere(
      (m) => m.id == storage.activeScorerMatchId,
      orElse: () => storage.matches.first,
    );

    // Guard: Prevent scoring the 7th ball if an over has ended and a new bowler hasn't been chosen
    if (_isOverAwaitingNewBowler(match)) {
      final isTeamABatting = match.battingTeamId == match.teamA.id;
      final overs = isTeamABatting ? match.oversA : match.oversB;
      final bowlingPlayers = _getBowlingPlayers(match, storage);
      CustomNotification.show(
        context,
        'Over ${(overs).round()} is completed! Please select a new bowler before bowling Over ${(overs + 1).toInt()}.',
        type: NotificationType.warning,
      );
      _showOverCompletedDialog(context, bowlingPlayers, storage, (overs).round());
      return;
    }

    String actionId;
    if (isWicket) {
      actionId = 'record_wicket';
    } else if (extraType != 'None') {
      actionId = 'extra_${extraType.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}';
    } else {
      actionId = 'run_$runs';
    }

    _handleScoringAction(
      actionId: actionId,
      execute: () => storage.updateScore(
        runs: runs,
        extraType: extraType,
        extraRuns: extraRuns,
        isWicket: isWicket,
        wicketType: isWicket ? 'Bowled' : 'None',
      ),
      onSuccess: () => _postBallCheck(storage),
    );
  }

  int _getBowlerSelectionPriority(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('bowl')) return 1; // Bowler first
    if (r.contains('all') || r.contains('round')) return 2; // All-rounder second
    if (r.contains('bat') || r.contains('keep') || r.contains('wk')) return 3; // Batsman / WK third
    return 4;
  }

  int _getBatterSelectionPriority(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('bat') || r.contains('keep') || r.contains('wk')) return 1; // Batter first
    if (r.contains('all') || r.contains('round')) return 2; // All-rounder second
    if (r.contains('bowl')) return 3; // Bowler third
    return 4;
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color text;
    IconData icon;
    final r = role.toLowerCase().trim();

    if (r.contains('bowl')) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.12);
      text = const Color(0xFF059669);
      icon = Icons.sports_baseball_rounded;
    } else if (r.contains('all') || r.contains('round')) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.14);
      text = const Color(0xFFD97706);
      icon = Icons.swap_horiz_rounded;
    } else if (r.contains('keep') || r.contains('wk')) {
      bg = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
      text = const Color(0xFF7C3AED);
      icon = Icons.front_hand_rounded;
    } else {
      bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
      text = const Color(0xFF2563EB);
      icon = Icons.sports_cricket_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: text),
          const SizedBox(width: 4),
          Text(
            role.isEmpty ? 'Player' : role,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerSelectionSheet(
    BuildContext context,
    bool isStriker,
    List<Player> initialPlayers,
    StorageService storage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Consumer<StorageService>(
          builder: (sheetCtx, liveStorage, _) {
            final activeMatch = liveStorage.matches.firstWhere(
              (m) => m.id == liveStorage.activeScorerMatchId,
              orElse: () => liveStorage.matches.isNotEmpty ? liveStorage.matches.first : CricketMatch.fromJson({}),
            );
            final currentPlayers = _getBattingPlayers(activeMatch, liveStorage);

            final sortedPlayers = List<Player>.from(currentPlayers);
            sortedPlayers.sort((a, b) {
              final pA = _getBatterSelectionPriority(a.role);
              final pB = _getBatterSelectionPriority(b.role);
              if (pA != pB) return pA.compareTo(pB);
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (sheetContext, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isStriker ? 'Select New Striker' : 'Select New Non-Striker',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${sortedPlayers.length} Players',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (sortedPlayers.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                          alignment: Alignment.center,
                          child: Text(
                            'No players found in this team.\nYou can manage players in Team Management.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: sortedPlayers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = sortedPlayers[i];
                              final initial = p.name.trim().isNotEmpty ? p.name.trim().substring(0, 1).toUpperCase() : '?';
                              return InkWell(
                                onTap: () {
                                  if (isStriker) {
                                    liveStorage.setStriker(p.id);
                                  } else {
                                    liveStorage.setNonStriker(p.id);
                                  }
                                  Navigator.pop(ctx);
                                  CustomNotification.show(context, '${p.name} set as ${isStriker ? "Striker" : "Non-Striker"}', type: NotificationType.info);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                        radius: 16,
                                        child: Text(initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                _buildRoleBadge(p.role),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${p.runsScored} runs • ${p.ballsFaced} balls',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.6), size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showBowlerSelectionSheet(
    BuildContext context,
    List<Player> players,
    StorageService storage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<StorageService>(
          builder: (consumerContext, liveStorage, _) {
            CricketMatch? activeMatch;
            try {
              if (liveStorage.activeScorerMatchId != null) {
                activeMatch = liveStorage.matches.firstWhere(
                  (m) => m.id == liveStorage.activeScorerMatchId,
                );
              } else if (liveStorage.matches.isNotEmpty) {
                activeMatch = liveStorage.matches.first;
              }
            } catch (_) {
              if (liveStorage.matches.isNotEmpty) {
                activeMatch = liveStorage.matches.first;
              }
            }

            final currentBowlingPlayers = activeMatch != null
                ? _getBowlingPlayers(activeMatch, liveStorage)
                : players;

            final sourcePlayers = currentBowlingPlayers.isNotEmpty ? currentBowlingPlayers : players;
            // Sort players: Bowler first, then All-rounder, then Batsman
            final sortedPlayers = List<Player>.from(sourcePlayers);
            sortedPlayers.sort((a, b) {
              final pA = _getBowlerSelectionPriority(a.role);
              final pB = _getBowlerSelectionPriority(b.role);
              if (pA != pB) return pA.compareTo(pB);
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

            final currentBowlerId = activeMatch?.currentBowlerId ?? '';

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (sheetContext, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Select Active Bowler',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${sortedPlayers.length} Players',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (sortedPlayers.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                          alignment: Alignment.center,
                          child: Text(
                            'No bowlers found in this team.\nYou can manage players in Team Management.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: sortedPlayers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = sortedPlayers[i];
                              final isCurrent = p.id == currentBowlerId;
                              final initial = p.name.trim().isNotEmpty
                                  ? p.name.trim().substring(0, 1).toUpperCase()
                                  : '?';

                              return InkWell(
                                onTap: () {
                                  liveStorage.switchBowler(p.id);
                                  Navigator.pop(ctx);
                                  CustomNotification.show(
                                    context,
                                    'Bowler switched to ${p.name}',
                                    type: NotificationType.info,
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppTheme.primaryBlue
                                          : const Color(0xFFE2E8F0),
                                      width: isCurrent ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isCurrent
                                            ? AppTheme.primaryBlue
                                            : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                        radius: 17,
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent ? Colors.white : AppTheme.primaryBlue,
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
                                                Flexible(
                                                  child: Text(
                                                    p.name,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13.5,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isCurrent) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryBlue,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Active',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                _buildRoleBadge(p.role),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${p.oversBowled.toStringAsFixed(1)} ov • ${p.wicketsTaken}w • ${p.runsConceded}r',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isCurrent ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                                        color: isCurrent
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary.withValues(alpha: 0.6),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showWicketDialog(StorageService storage) {
    if (storage.activeScorerMatchId == null) return;
    final match = storage.matches.firstWhere((m) => m.id == storage.activeScorerMatchId);

    // Guard: Prevent recording ball if over ended and waiting for new bowler
    if (_isOverAwaitingNewBowler(match)) {
      final isTeamABatting = match.battingTeamId == match.teamA.id;
      final overs = isTeamABatting ? match.oversA : match.oversB;
      final bowlingPlayers = _getBowlingPlayers(match, storage);
      CustomNotification.show(
        context,
        'Over ${(overs).round()} is completed! Please select a new bowler before bowling Over ${(overs + 1).toInt()}.',
        type: NotificationType.warning,
      );
      _showOverCompletedDialog(context, bowlingPlayers, storage, (overs).round());
      return;
    }

    final battingPlayers = _getBattingPlayers(match, storage);
    final striker = battingPlayers.firstWhere(
      (p) => p.id == match.currentStrikerId,
      orElse: () => battingPlayers.isNotEmpty
          ? battingPlayers[0]
          : Player(id: '', name: 'Striker', role: 'Batter', nationality: ''),
    );
    final nonStriker = battingPlayers.firstWhere(
      (p) => p.id == match.currentNonStrikerId,
      orElse: () => battingPlayers.length > 1
          ? battingPlayers[1]
          : (battingPlayers.isNotEmpty
              ? battingPlayers[0]
              : Player(id: '', name: 'Non-Striker', role: 'Batter', nationality: '')),
    );

    String dismissedId = striker.id;
    String wicketType = 'Bowled';

    // Helper to calculate remaining batsmen who have not yet batted or been dismissed
    List<Player> getRemainingBatsmen(CricketMatch match, List<Player> battingSquad, String currentDismissedId) {
      final Set<String> dismissedNames = {};
      final Set<String> dismissedIds = {};
      for (var ball in match.balls) {
        if (ball.isWicket) {
          if (ball.batsmanName.isNotEmpty) dismissedNames.add(ball.batsmanName.trim().toLowerCase());
          if (ball.strikerId != null && ball.strikerId!.isNotEmpty) dismissedIds.add(ball.strikerId!);
        }
      }
      final remaining = battingSquad.where((p) {
        if (p.isOut) return false;
        if (p.id == match.currentStrikerId || p.id == match.currentNonStrikerId || p.id == currentDismissedId) {
          return false;
        }
        if (dismissedNames.contains(p.name.trim().toLowerCase()) || dismissedIds.contains(p.id)) {
          return false;
        }
        return true;
      }).toList();

      // Sort candidate batsmen: Batters first, then All-rounders, then Bowlers
      remaining.sort((a, b) {
        final pA = _getBatterSelectionPriority(a.role);
        final pB = _getBatterSelectionPriority(b.role);
        if (pA != pB) return pA.compareTo(pB);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return remaining;
    }

    var candidates = getRemainingBatsmen(match, battingPlayers, dismissedId);

    int currentStep = 1;
    String selectedIncomingId = candidates.isNotEmpty ? candidates[0].id : '';
    String selectedPosition = 'Striker';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WicketConfirmDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  // If striker dismissed is toggled, update position and default dismissal types accordingly
                  if (dismissedId == nonStriker.id && currentStep == 1) {
                    selectedPosition = 'Non-Striker';
                    if (!['Run Out', 'Hit Wicket', 'Retired Out', 'Retired Hurt'].contains(wicketType)) {
                      wicketType = 'Run Out';
                    }
                  } else if (dismissedId == striker.id && currentStep == 1) {
                    selectedPosition = 'Striker';
                  }

                  // Update candidates dynamically
                  candidates = getRemainingBatsmen(match, battingPlayers, dismissedId);
                  if (candidates.isNotEmpty && !candidates.any((p) => p.id == selectedIncomingId)) {
                    selectedIncomingId = candidates[0].id;
                  }

                  final List<String> dropdownItems = dismissedId == striker.id
                      ? ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket', 'Retired Out', 'Retired Hurt']
                      : ['Run Out', 'Hit Wicket', 'Retired Out', 'Retired Hurt'];

                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (currentStep == 1 ? AppTheme.accentRed : AppTheme.primaryBlue).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStep == 1 ? Icons.outbox_rounded : Icons.person_add_alt_1_rounded,
                            color: currentStep == 1 ? AppTheme.accentRed : AppTheme.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStep == 1 ? 'Record Wicket' : 'Incoming Batter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                currentStep == 1 ? 'Step 1 of 2: Dismissal Details' : 'Step 2 of 2: Select New Batter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: 340,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: currentStep == 1
                            ? Column(
                                key: const ValueKey(1),
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WHICH BATTER IS OUT?',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setDialogState(() => dismissedId = striker.id),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: dismissedId == striker.id
                                                  ? AppTheme.accentRed.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: dismissedId == striker.id ? AppTheme.accentRed : const Color(0xFFE2E8F0),
                                                width: dismissedId == striker.id ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.sports_cricket_rounded, color: AppTheme.accentRed, size: 20),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Striker',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  striker.name,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setDialogState(() => dismissedId = nonStriker.id),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: dismissedId == nonStriker.id
                                                  ? AppTheme.accentRed.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: dismissedId == nonStriker.id ? AppTheme.accentRed : const Color(0xFFE2E8F0),
                                                width: dismissedId == nonStriker.id ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.directions_run_rounded, color: AppTheme.accentRed, size: 20),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Non-Striker',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  nonStriker.name,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'DISMISSAL TYPE',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                                    initialValue: wicketType,
                                    decoration: InputDecoration(
                                      fillColor: Colors.black.withValues(alpha: 0.02),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    items: dropdownItems.map((val) {
                                      return DropdownMenuItem(value: val, child: Text(val));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() => wicketType = val);
                                      }
                                    },
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey(2),
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dismissed Context Card
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentRed.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.accentRed.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentRed.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.outbox_rounded, size: 12, color: AppTheme.accentRed),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'OUT: ${(dismissedId == striker.id ? striker.name : nonStriker.name)} • $wicketType',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.accentRed,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SELECT NEW BATSMAN',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${candidates.length} Available',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (candidates.isEmpty)
                                    Container(
                                      height: 140,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.sports_cricket_rounded, size: 28, color: Colors.grey.shade400),
                                          const SizedBox(height: 6),
                                          Text(
                                            'No Remaining Batsmen',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Team is All Out. Confirm to finalize wicket.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 175,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: ListView.separated(
                                          padding: const EdgeInsets.all(8),
                                          shrinkWrap: true,
                                          itemCount: candidates.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                                          itemBuilder: (ctx, idx) {
                                            final player = candidates[idx];
                                            final isSel = selectedIncomingId == player.id;
                                            final initial = player.name.trim().isNotEmpty
                                                ? player.name.trim().substring(0, 1).toUpperCase()
                                                : '?';

                                            return InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  selectedIncomingId = player.id;
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isSel
                                                      ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                                                      : Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isSel
                                                        ? AppTheme.primaryBlue
                                                        : const Color(0xFFE2E8F0),
                                                    width: isSel ? 1.6 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor: isSel
                                                          ? AppTheme.primaryBlue
                                                          : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                                      radius: 14,
                                                      child: Text(
                                                        initial,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: isSel ? Colors.white : AppTheme.primaryBlue,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            player.name,
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12.5,
                                                              color: isSel ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 3),
                                                          Row(
                                                            children: [
                                                              _buildRoleBadge(player.role),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                '${player.runsScored} r • ${player.ballsFaced} b',
                                                                style: GoogleFonts.plusJakartaSans(
                                                                  fontSize: 10.5,
                                                                  color: AppTheme.textSecondary,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      isSel
                                                          ? Icons.check_circle_rounded
                                                          : Icons.radio_button_unchecked_rounded,
                                                      color: isSel ? AppTheme.primaryBlue : Colors.grey.shade400,
                                                      size: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'BATSMAN CREASE POSITION',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setDialogState(() => selectedPosition = 'Striker'),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: selectedPosition == 'Striker'
                                                  ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: selectedPosition == 'Striker'
                                                    ? AppTheme.primaryBlue
                                                    : const Color(0xFFE2E8F0),
                                                width: selectedPosition == 'Striker' ? 1.8 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.sports_cricket_rounded,
                                                  size: 16,
                                                  color: selectedPosition == 'Striker'
                                                      ? AppTheme.primaryBlue
                                                      : AppTheme.textSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Striker',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: selectedPosition == 'Striker'
                                                              ? AppTheme.primaryBlue
                                                              : AppTheme.textPrimary,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Facing next ball',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 9.5,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  selectedPosition == 'Striker'
                                                      ? Icons.check_circle_rounded
                                                      : Icons.radio_button_unchecked_rounded,
                                                  size: 14,
                                                  color: selectedPosition == 'Striker'
                                                      ? AppTheme.primaryBlue
                                                      : Colors.grey.shade400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setDialogState(() => selectedPosition = 'Non-Striker'),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: selectedPosition == 'Non-Striker'
                                                  ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: selectedPosition == 'Non-Striker'
                                                    ? AppTheme.primaryBlue
                                                    : const Color(0xFFE2E8F0),
                                                width: selectedPosition == 'Non-Striker' ? 1.8 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_run_rounded,
                                                  size: 16,
                                                  color: selectedPosition == 'Non-Striker'
                                                      ? AppTheme.primaryBlue
                                                      : AppTheme.textSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Non-Striker',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: selectedPosition == 'Non-Striker'
                                                              ? AppTheme.primaryBlue
                                                              : AppTheme.textPrimary,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Runner\'s end',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 9.5,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  selectedPosition == 'Non-Striker'
                                                      ? Icons.check_circle_rounded
                                                      : Icons.radio_button_unchecked_rounded,
                                                  size: 14,
                                                  color: selectedPosition == 'Non-Striker'
                                                      ? AppTheme.primaryBlue
                                                      : Colors.grey.shade400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (currentStep == 2) {
                            setDialogState(() => currentStep = 1);
                          } else {
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          currentStep == 2 ? 'Back' : 'Cancel',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (currentStep == 1) {
                            if (candidates.isEmpty) {
                              Navigator.pop(ctx);
                              _handleScoringAction(
                                actionId: 'record_wicket',
                                execute: () => storage.updateScore(
                                  runs: 0,
                                  extraType: 'None',
                                  extraRuns: 0,
                                  isWicket: true,
                                  wicketType: wicketType,
                                  dismissedPlayerId: dismissedId,
                                ),
                                successMessage: 'Wicket recorded. Team is All Out!',
                                onSuccess: () => _postBallCheck(storage),
                              );
                            } else {
                              setDialogState(() => currentStep = 2);
                            }
                          } else {
                            Navigator.pop(ctx);
                            final nextPlayerName = battingPlayers.firstWhere(
                              (p) => p.id == selectedIncomingId,
                              orElse: () => Player(id: '', name: 'Next Batter', role: 'Batter', nationality: ''),
                            ).name;

                            _handleScoringAction(
                              actionId: 'record_wicket',
                              execute: () => storage.updateScore(
                                runs: 0,
                                extraType: 'None',
                                extraRuns: 0,
                                isWicket: true,
                                wicketType: wicketType,
                                dismissedPlayerId: dismissedId,
                                newBatsmanId: selectedIncomingId.isNotEmpty ? selectedIncomingId : null,
                                newBatsmanPosition: selectedPosition,
                              ),
                              successMessage: 'Wicket recorded. Incoming: $nextPlayerName ($selectedPosition)',
                              onSuccess: () => _postBallCheck(storage),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentStep == 1 ? AppTheme.accentRed : AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          (currentStep == 1 && candidates.isNotEmpty) ? 'Next' : 'Confirm',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomExtraDialog(StorageService storage) {
    if (storage.activeScorerMatchId == null) return;
    final match = storage.matches.firstWhere(
      (m) => m.id == storage.activeScorerMatchId,
      orElse: () => storage.matches.first,
    );

    // Guard: Prevent recording custom extra if over ended and waiting for new bowler
    if (_isOverAwaitingNewBowler(match)) {
      final isTeamABatting = match.battingTeamId == match.teamA.id;
      final overs = isTeamABatting ? match.oversA : match.oversB;
      final bowlingPlayers = _getBowlingPlayers(match, storage);
      CustomNotification.show(
        context,
        'Over ${(overs).round()} is completed! Please select a new bowler before bowling Over ${(overs + 1).toInt()}.',
        type: NotificationType.warning,
      );
      _showOverCompletedDialog(context, bowlingPlayers, storage, (overs).round());
      return;
    }

    String extraType = 'Wide';
    int runs = 1;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ExtraRunsDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_moderator_rounded, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Record Extra Runs',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXTRA TYPE',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                          initialValue: extraType,
                          decoration: InputDecoration(
                            fillColor: Colors.black.withValues(alpha: 0.02),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Wide', child: Text('Wide')),
                            DropdownMenuItem(value: 'No Ball', child: Text('No Ball')),
                            DropdownMenuItem(value: 'Leg Bye', child: Text('Leg Bye')),
                            DropdownMenuItem(value: 'Bye', child: Text('Bye')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => extraType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'EXTRA RUNS',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3, 4, 5].map((r) {
                            final isSel = runs == r;
                            return GestureDetector(
                              onTap: () => setDialogState(() => runs = r),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primaryBlue : AppTheme.bgDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '+$r',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isSel ? Colors.white : AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleScoringAction(
                            actionId: 'extra_customextra',
                            execute: () => storage.updateScore(
                              runs: 0,
                              extraType: extraType,
                              extraRuns: runs,
                              isWicket: false,
                              wicketType: 'None',
                            ),
                            successMessage: 'Custom Extra recorded: $extraType +$runs',
                            onSuccess: () => _postBallCheck(storage),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text('Confirm', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _postBallCheck(StorageService storage) {
    if (!mounted || storage.activeScorerMatchId == null) return;
    final match = storage.matches.firstWhere(
      (m) => m.id == storage.activeScorerMatchId,
      orElse: () => storage.matches.first,
    );

    // 1. Check if match has finished
    if (match.status == 'Completed') {
      _showMatchCompletedDialog(context, match);
      return;
    }

    final isTeamABatting = match.battingTeamId == match.teamA.id;
    final overs = isTeamABatting ? match.oversA : match.oversB;

    // 2. Check if over is completed and awaiting a new bowler
    if (_isOverAwaitingNewBowler(match)) {
      final bowlingPlayers = _getBowlingPlayers(match, storage);
      _showOverCompletedDialog(context, bowlingPlayers, storage, (overs).round());
    }
  }

  void _showMatchCompletedDialog(BuildContext context, CricketMatch match) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MatchCompletedDialog',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGreen, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MATCH FINISHED',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match.resultText.isNotEmpty ? match.resultText : 'Match has concluded.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(match.teamA.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('${match.runsA}/${match.wicketsA} (${match.oversA} ov)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(match.teamB.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('${match.runsB}/${match.wicketsB} (${match.oversB} ov)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      ),
                      child: Text('Close Summary', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOverCompletedDialog(
    BuildContext context,
    List<Player> players,
    StorageService storage,
    int overNumber,
  ) {
    if (_isOverDialogOpen) return;

    final match = storage.matches.firstWhere(
      (m) => m.id == storage.activeScorerMatchId,
      orElse: () => storage.matches.first,
    );

    final effectivePlayers = players.isNotEmpty ? players : _getBowlingPlayers(match, storage);
    if (effectivePlayers.isEmpty) return;

    _isOverDialogOpen = true;

    // Identify who bowled the last legal ball of this completed over
    String? justBowledId;
    if (match.balls.isNotEmpty) {
      for (int i = match.balls.length - 1; i >= 0; i--) {
        final b = match.balls[i];
        if (b.extraType != 'Wide' && b.extraType != 'No Ball') {
          justBowledId = b.bowlerId;
          break;
        }
      }
    }
    justBowledId ??= match.currentBowlerId;

    // Sort players: eligible bowlers first, putting the bowler who just bowled at the bottom
    final sortedPlayers = List<Player>.from(effectivePlayers);
    sortedPlayers.sort((a, b) {
      if (a.id == justBowledId && b.id != justBowledId) return 1;
      if (b.id == justBowledId && a.id != justBowledId) return -1;

      final pA = _getBowlerSelectionPriority(a.role);
      final pB = _getBowlerSelectionPriority(b.role);
      if (pA != pB) return pA.compareTo(pB);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final eligiblePlayers = sortedPlayers.where((p) => p.id != justBowledId).toList();
    String? selectedBowlerId = eligiblePlayers.isNotEmpty
        ? eligiblePlayers.first.id
        : (sortedPlayers.isNotEmpty ? sortedPlayers.first.id : null);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'OverCompletedDialog',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.82, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Over $overNumber Completed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Select bowler for Over ${overNumber + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHOOSE NEXT BOWLER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 240,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(8),
                                shrinkWrap: true,
                                itemCount: sortedPlayers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (ctx, idx) {
                                  final player = sortedPlayers[idx];
                                  final isJustBowled = player.id == justBowledId;
                                  final isIneligible = isJustBowled && eligiblePlayers.isNotEmpty;
                                  final isSel = selectedBowlerId == player.id;
                                  final initial = player.name.trim().isNotEmpty
                                      ? player.name.trim().substring(0, 1).toUpperCase()
                                      : '?';

                                  return InkWell(
                                    onTap: isIneligible
                                        ? () {
                                            CustomNotification.show(
                                              context,
                                              '${player.name} just bowled Over $overNumber. Bowlers cannot bowl consecutive overs.',
                                              type: NotificationType.warning,
                                            );
                                          }
                                        : () {
                                            setDialogState(() {
                                              selectedBowlerId = player.id;
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isIneligible
                                            ? Colors.grey.shade100
                                            : isSel
                                                ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isIneligible
                                              ? Colors.grey.shade300
                                              : isSel
                                                  ? AppTheme.primaryBlue
                                                  : const Color(0xFFE2E8F0),
                                          width: isSel ? 1.6 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isIneligible
                                                ? Colors.grey.shade300
                                                : isSel
                                                    ? AppTheme.primaryBlue
                                                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                            radius: 14,
                                            child: Text(
                                              initial,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isIneligible
                                                    ? Colors.grey.shade600
                                                    : isSel
                                                        ? Colors.white
                                                        : AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        player.name,
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12.5,
                                                          color: isIneligible
                                                              ? AppTheme.textMuted
                                                              : isSel
                                                                  ? AppTheme.primaryBlue
                                                                  : AppTheme.textPrimary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isJustBowled) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accentRed.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          'Just Bowled',
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppTheme.accentRed,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    _buildRoleBadge(player.role),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '${player.oversBowled.toStringAsFixed(1)} ov • ${player.wicketsTaken}w • ${player.runsConceded}r',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 10.5,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isIneligible
                                                ? Icons.block_rounded
                                                : isSel
                                                    ? Icons.check_circle_rounded
                                                    : Icons.radio_button_unchecked_rounded,
                                            color: isIneligible
                                                ? Colors.grey.shade400
                                                : isSel
                                                    ? AppTheme.primaryBlue
                                                    : Colors.grey.shade400,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: selectedBowlerId == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                storage.switchBowler(selectedBowlerId!);
                                final bowlerName = sortedPlayers.firstWhere(
                                  (p) => p.id == selectedBowlerId,
                                  orElse: () => Player(id: '', name: 'Bowler', role: 'Bowler', nationality: ''),
                                ).name;
                                CustomNotification.show(
                                  context,
                                  'Over $overNumber finished. New bowler: $bowlerName for Over ${overNumber + 1}',
                                  type: NotificationType.success,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Confirm Bowler',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isOverDialogOpen = false;
    });
  }

  void _showResetConfirmation(BuildContext context, StorageService storage, String matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Match?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to reset this match score to 0/0 and delete all balls?', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              storage.resetMatchToZero(matchId);
              CustomNotification.show(context, 'Match score reset to 0/0', type: NotificationType.success);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Reset', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUndoConfirmation(BuildContext context, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Undo Last Ball?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete the last scored ball and revert the stats?',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleScoringAction(
                actionId: 'undo_ball',
                execute: () => storage.undoLastBall(),
                successMessage: 'Last ball reverted',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Yes, Undo',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorerActionButton extends StatefulWidget {
  final String actionId;
  final bool isProcessing;
  final String? processingAction;
  final String? successAction;
  final String? errorAction;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool isCurrentAction, bool isAnyProcessing) builder;

  const _ScorerActionButton({
    required this.actionId,
    required this.isProcessing,
    required this.processingAction,
    required this.successAction,
    required this.errorAction,
    required this.onTap,
    required this.builder,
  });

  @override
  State<_ScorerActionButton> createState() => _ScorerActionButtonState();
}

class _ScorerActionButtonState extends State<_ScorerActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null || widget.isProcessing) return;
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (_pressController.status == AnimationStatus.forward || _pressController.status == AnimationStatus.completed) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (_pressController.status == AnimationStatus.forward || _pressController.status == AnimationStatus.completed) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isThisProcessing = widget.isProcessing && widget.processingAction == widget.actionId;
    final bool isThisSuccess = widget.successAction == widget.actionId;
    final bool isThisError = widget.errorAction == widget.actionId;
    final bool isAnyOtherProcessing = widget.isProcessing && !isThisProcessing;
    final bool isDisabled = widget.onTap == null || isAnyOtherProcessing;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        opacity: isAnyOtherProcessing ? 0.50 : 1.0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: isDisabled || isThisProcessing ? null : widget.onTap,
          child: AbsorbPointer(
            absorbing: widget.isProcessing,
            child: widget.builder(context, isThisProcessing || isThisSuccess || isThisError, widget.isProcessing),
          ),
        ),
      ),
    );
  }
}
