import '../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../core/routes/app_routes.dart';
import 'match_details_screen.dart';
import '../../core/widgets/custom_notification.dart';
import 'prediction_tab_view.dart';
import 'profile_tab_view.dart';
import 'home_tab_view.dart';
import 'schedules_tab_view.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});


  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0; // Default to Home

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    final List<Widget> views = [
      const HomeTabView(),
      const SchedulesTabView(),
      _buildAIWinPredictionView(storage),
      _buildLiveRedirectView(storage),
      _buildProfileView(storage),
    ];

    return Scaffold(
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
          onTap: (index) {
            if (index == 3) {
              final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
              if (liveMatches.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.userMatchDetails,
                  arguments: liveMatches.first.id,
                );
              } else {
                CustomNotification.show(
                  context,
                  'No active Live match right now.',
                  type: NotificationType.warning,
                );
              }
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF854D0E), // Gold-brown selection matching screenshot
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
    );
  }



  // --- View 3: Win predictions dashboard ---
  Widget _buildAIWinPredictionView(StorageService storage) {
    final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
    if (liveMatches.isEmpty) {
      return Center(
        child: Text(
          'No active Live matches for AI analytics.',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 14),
        ),
      );
    }
    final match = liveMatches.first;
    return PredictionTabView(match: match);
  }

  // --- View 4: Live redirect button ---
  Widget _buildLiveRedirectView(StorageService storage) {
    final liveMatches = storage.matches.where((m) => m.status == 'Live').toList();
    if (liveMatches.isEmpty) {
      return const Center(child: Text('No active Live match right now.', style: TextStyle(color: AppTheme.textPrimary)));
    }
    return MatchDetailsScreen(matchId: liveMatches.first.id);
  }

  // --- View 5: Profile & Settings ---
  Widget _buildProfileView(StorageService storage) {
    return const ProfileTabView();
  }
}

