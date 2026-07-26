// lib/core/routes/app_routes.dart
// CricketVerse AI — Named Routes (Role-Separated, Custom Transitions)

import 'package:flutter/material.dart';
import '../../models/models.dart';

// ── Shared (pre-auth) ───────────────────────────────────────────────────────
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/auth_screen.dart';
import '../../screens/shared/tournament_details_screen.dart';

// ── Admin ───────────────────────────────────────────────────────────────────
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_profile_screen.dart';
import '../../screens/admin/ai_commentary_screen.dart';
import '../../screens/admin/ai_settings_screen.dart';
import '../../screens/admin/create_tournament_screen.dart';
import '../../screens/admin/tournament_management_screen.dart';
import '../../screens/admin/team_management_screen.dart';
import '../../screens/admin/team_detail_screen.dart';
import '../../screens/admin/edit_team_screen.dart';
import '../../screens/admin/player_management_screen.dart';

import '../../screens/admin/player_detail_screen.dart';
import '../../screens/admin/schedule_match_screen.dart';
import '../../screens/admin/match_list_screen.dart';
import '../../screens/admin/match_detail_screen.dart';
import '../../screens/admin/prediction_screen.dart';
import '../../screens/admin/statistics_screen.dart';
import '../../screens/admin/notifications_screen.dart';
import '../../screens/admin/about_screen.dart';
import '../../screens/admin/help_screen.dart';

// ── Scorer ──────────────────────────────────────────────────────────────────
import '../../screens/scorer/scorer_dashboard.dart';
import '../../screens/scorer/edit_ball_screen.dart';

// ── User / Fan ───────────────────────────────────────────────────────────────
import '../../screens/user/user_dashboard.dart';
import '../../screens/user/match_details_screen.dart';
import '../../screens/user/team_details_screen.dart';
import '../../screens/user/player_details_screen.dart';
import '../../screens/user/match_summary_download_screen.dart';

class AppRoutes {
  // ─── Shared Route Names ───────────────────────────────────────────────────
  static const String splash             = '/';
  static const String onboarding         = '/onboarding';
  static const String auth               = '/auth';
  static const String tournamentDetail   = '/shared/tournament-details';

  // ─── Admin Route Names ────────────────────────────────────────────────────
  static const String adminDashboard     = '/admin';
  static const String adminProfile       = '/admin/profile';
  static const String aiCommentary       = '/admin/commentary';
  static const String aiSettings         = '/admin/ai-settings';
  static const String createTournament   = '/admin/tournaments/create';
  static const String tournamentList     = '/admin/tournaments';
  static const String teamManagement     = '/admin/teams';
  static const String teamDetail         = '/admin/teams/detail';
  static const String editTeam           = '/admin/teams/edit';
  static const String playerManagement   = '/admin/players';
  static const String playerDetail       = '/admin/players/detail';
  static const String scheduleMatch      = '/admin/matches/schedule';
  static const String matchList          = '/admin/matches';
  static const String matchDetail        = '/admin/matches/detail';
  static const String prediction         = '/admin/prediction';
  static const String statistics         = '/admin/statistics';
  static const String notifications      = '/admin/notifications';
  static const String about              = '/admin/about';
  static const String help               = '/admin/help';

  // ─── Scorer Route Names ───────────────────────────────────────────────────
  static const String scorerDashboard  = '/scorer';
  static const String editBall         = '/scorer/edit-ball';

  // ─── User / Fan Route Names ───────────────────────────────────────────────
  static const String userDashboard        = '/user';
  static const String userMatchDetails     = '/user/match-details';
  static const String userTeamDetails      = '/user/team-details';
  static const String userPlayerDetails    = '/user/player-details';
  static const String matchSummaryDownload = '/user/match-summary';

  // ─── Route Generator ──────────────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      // Shared
      case splash:
        return _slideRoute(const SplashScreen());
      case onboarding:
        return _slideRoute(const OnboardingScreen());
      case auth:
        return _fadeRoute(const AuthScreen());
      case tournamentDetail:
        return _slideRoute(TournamentDetailsScreen(tournament: settings.arguments as Map<String, dynamic>));

      // Admin
      case adminDashboard:
        return _fadeRoute(const AdminDashboard());
      case adminProfile:
        return _slideRoute(const AdminProfileScreen());
      case aiCommentary:
        return _slideRoute(AiCommentaryScreen(match: settings.arguments as dynamic));
      case aiSettings:
        return _slideRoute(const AiSettingsScreen());
      case createTournament:
        return _slideRoute(const CreateTournamentScreen());
      case tournamentList:
        return _slideRoute(const TournamentManagementScreen());
      case teamManagement:
        return _slideRoute(const TeamManagementScreen());
      case teamDetail:
        return _slideRoute(TeamDetailScreen(team: settings.arguments as dynamic));
      case editTeam:
        return _slideRoute(EditTeamScreen(team: settings.arguments as dynamic));
      case playerManagement:

        return _slideRoute(const PlayerManagementScreen());
      case playerDetail:
        return _slideRoute(PlayerDetailScreen(player: settings.arguments as dynamic));
      case scheduleMatch:
        return _slideRoute(const ScheduleMatchScreen());
      case matchList:
        return _slideRoute(const MatchListScreen());
      case matchDetail:
        return _slideRoute(MatchDetailScreen(match: settings.arguments as dynamic));
      case prediction:
        return _slideRoute(PredictionScreen(match: settings.arguments as dynamic));
      case statistics:
        return _slideRoute(const StatisticsScreen());
      case notifications:
        return _slideRoute(const NotificationsScreen());
      case about:
        return _slideRoute(const AboutScreen());
      case help:
        return _slideRoute(const HelpScreen());

      // Scorer
      case scorerDashboard:
        return _fadeRoute(const ScorerDashboard());
      case editBall:
        return _slideRoute(const EditBallScreen());

      // User / Fan
      case userDashboard:
        return _fadeRoute(const UserDashboard());
      case userMatchDetails:
        return _slideRoute(MatchDetailsScreen(matchId: settings.arguments as String));
      case userTeamDetails:
        return _slideRoute(TeamDetailsScreen(team: settings.arguments as Team));
      case userPlayerDetails:
        return _slideRoute(PlayerDetailsScreen(player: settings.arguments as Player));
      case matchSummaryDownload:
        return _slideRoute(MatchSummaryDownloadScreen(
          matchDetails: settings.arguments as Map<String, dynamic>,
        ));

      default:
        return _fadeRoute(const AuthScreen());
    }
  }

  // ─── Transition Builders ──────────────────────────────────────────────────
  static PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
