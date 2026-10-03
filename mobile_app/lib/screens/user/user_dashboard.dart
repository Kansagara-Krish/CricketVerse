import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/socket_service.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/widgets/exit_app_dialog.dart';
import 'home_tab_view.dart';
import 'schedules_tab_view.dart';
import 'prediction_tab_view.dart';
import 'live_tab_view.dart';
import 'profile_tab_view.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0; // Default to Home
  final List<int> _tabHistory = [0];
  String? _selectedPredictionMatchId;

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
  }

  void _navigateToTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _tabHistory.remove(index);
        _tabHistory.add(index);
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> views = [
      const HomeTabView(),
      const SchedulesTabView(),
      PredictionTabView(
        initialMatchId: _selectedPredictionMatchId,
      ),
      LiveTabView(
        onOpenPrediction: (matchId) {
          setState(() {
            _selectedPredictionMatchId = matchId;
            _navigateToTab(2); // Switch to Prediction Tab with this match
          });
        },
        onViewSchedule: () {
          _navigateToTab(1); // Switch to Matches / Schedules tab
        },
      ),
      const ProfileTabView(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If user has navigated through tabs, pop to the previous tab
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _currentIndex = _tabHistory.last;
          });
          return;
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _tabHistory.clear();
            _tabHistory.add(0);
          });
          return;
        }

        // 2. Already on Home tab (last page) -> Ask for exit confirmation
        final shouldExit = await ExitAppDialog.show(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          child: views[_currentIndex],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.bgSurface, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _navigateToTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF854D0E), // Gold-brown selection matching theme
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_cricket_outlined), activeIcon: Icon(Icons.sports_cricket), label: 'Matches'),
              BottomNavigationBarItem(icon: Icon(Icons.online_prediction_outlined), activeIcon: Icon(Icons.online_prediction), label: 'Prediction'),
              BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv), label: 'Live'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
