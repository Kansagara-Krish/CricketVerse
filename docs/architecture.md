# 🏗️ Architecture Document
## CricketVerse AI — Application Architecture

**Version:** 1.0.0  
**Framework:** Flutter 3.x  
**Pattern:** Provider + Feature-Sliced Screens  

---

## 1. High-Level Architecture

CricketVerse AI follows a **monolithic offline-first Flutter architecture** with a single centralized state provider. There is no network layer — all data flows through `StorageService` which persists via `SharedPreferences`.

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │              Presentation Layer              │   │
│  │  Screens (Admin / Scorer / User / Shared)    │   │
│  │  Widgets (Core Widgets + Screen Widgets)     │   │
│  └──────────────────┬──────────────────────────┘   │
│                     │ context.watch / Provider.of   │
│  ┌──────────────────▼──────────────────────────┐   │
│  │              Business Logic Layer            │   │
│  │         StorageService (ChangeNotifier)      │   │
│  │  - Authentication logic                      │   │
│  │  - Match scoring engine                      │   │
│  │  - Win probability calculator                │   │
│  │  - AI commentary generator                   │   │
│  │  - CRUD for Teams, Players, Matches          │   │
│  └──────────────────┬──────────────────────────┘   │
│                     │ jsonEncode / jsonDecode        │
│  ┌──────────────────▼──────────────────────────┐   │
│  │              Data Layer                      │   │
│  │  Models: Player, Team, BallRecord,           │   │
│  │          CricketMatch                        │   │
│  └──────────────────┬──────────────────────────┘   │
│                     │                               │
│  ┌──────────────────▼──────────────────────────┐   │
│  │         Persistence Layer                    │   │
│  │         SharedPreferences (on-device)        │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```
lib/
├── main.dart                       # App entry point, Provider setup
│
├── models/
│   └── models.dart                 # All data model classes
│
├── services/
│   ├── storage_service.dart        # Central state + business logic + persistence
│   └── pdf_report_service.dart     # PDF generation (stateless, static methods)
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Commentary pools, venues, FAQ, notifications
│   ├── routes/
│   │   └── app_routes.dart         # Named route table + route generator
│   ├── theme/
│   │   └── app_theme.dart          # Brand colors, text styles, ThemeData
│   └── widgets/                    # Shared reusable widgets
│       ├── app_logo.dart
│       ├── card_entrance_animation.dart
│       ├── confirm_dialog.dart
│       ├── custom_notification.dart
│       ├── empty_state.dart
│       ├── logout_dialog.dart
│       ├── shimmer_loader.dart
│       ├── stat_card.dart
│       └── team_logo.dart
│
└── screens/
    ├── splash_screen.dart           # App entry animation
    ├── onboarding_screen.dart       # 3-slide feature intro
    ├── auth_screen.dart             # Login / Register / Guest / Quick Login
    │
    ├── shared/
    │   └── tournament_details_screen.dart
    │
    ├── admin/                       # 19 admin screens
    │   ├── admin_dashboard.dart
    │   ├── admin_profile_screen.dart
    │   ├── ai_commentary_screen.dart
    │   ├── ai_settings_screen.dart
    │   ├── create_tournament_screen.dart
    │   ├── tournament_management_screen.dart
    │   ├── team_management_screen.dart
    │   ├── team_detail_screen.dart
    │   ├── edit_team_screen.dart
    │   ├── player_management_screen.dart
    │   ├── player_detail_screen.dart
    │   ├── schedule_match_screen.dart
    │   ├── match_list_screen.dart
    │   ├── match_detail_screen.dart
    │   ├── live_scoring_screen.dart
    │   ├── prediction_screen.dart
    │   ├── statistics_screen.dart
    │   ├── notifications_screen.dart
    │   ├── about_screen.dart
    │   ├── help_screen.dart
    │   └── widgets/                 # Admin-specific sub-widgets
    │
    ├── scorer/                      # 2 scorer screens
    │   ├── scorer_dashboard.dart    # Main scoring terminal (1988 lines)
    │   └── edit_ball_screen.dart    # Edit last ball
    │
    └── user/                        # 9 fan screens
        ├── user_dashboard.dart
        ├── home_tab_view.dart
        ├── match_details_screen.dart
        ├── match_summary_download_screen.dart
        ├── player_details_screen.dart
        ├── prediction_tab_view.dart
        ├── profile_tab_view.dart
        ├── schedules_tab_view.dart
        ├── team_details_screen.dart
        └── widgets/                 # User-specific sub-widgets
```

---

## 3. State Management Architecture

### Provider Pattern
The app uses a single `ChangeNotifierProvider` mounted at the root in `main.dart`:

```dart
ChangeNotifierProvider(
  create: (_) => StorageService(),
  child: const CricketVerseApp(),
)
```

All screens access state via:
- `context.watch<StorageService>()` — for reactive rebuilds
- `Provider.of<StorageService>(context, listen: false)` — for one-shot reads and mutations

### State Flow Diagram
```
User Action (tap)
      │
      ▼
Screen Widget (StatefulWidget / StatelessWidget)
      │ calls StorageService method
      ▼
StorageService (ChangeNotifier)
      │ mutates state
      │ serializes to JSON
      ▼
SharedPreferences (persisted)
      │ calls notifyListeners()
      ▼
All listening widgets rebuild
```

---

## 4. Navigation Architecture

### Named Routes
All navigation uses `MaterialApp.onGenerateRoute` with `AppRoutes.generateRoute()`.

```
Route Table:
/                    → SplashScreen
/onboarding          → OnboardingScreen
/auth                → AuthScreen
/admin               → AdminDashboard
/admin/profile       → AdminProfileScreen
/admin/commentary    → AiCommentaryScreen
/admin/ai-settings   → AiSettingsScreen
/admin/tournaments   → TournamentManagementScreen
/admin/tournaments/create → CreateTournamentScreen
/admin/teams         → TeamManagementScreen
/admin/teams/detail  → TeamDetailScreen
/admin/teams/edit    → EditTeamScreen
/admin/players       → PlayerManagementScreen
/admin/players/detail → PlayerDetailScreen
/admin/matches       → MatchListScreen
/admin/matches/schedule → ScheduleMatchScreen
/admin/matches/detail → MatchDetailScreen
/admin/matches/live-scoring → LiveScoringScreen
/admin/prediction    → PredictionScreen
/admin/statistics    → StatisticsScreen
/admin/notifications → NotificationsScreen
/admin/about         → AboutScreen
/admin/help          → HelpScreen
/scorer              → ScorerDashboard
/scorer/edit-ball    → EditBallScreen
/user                → UserDashboard
/user/match-details  → MatchDetailsScreen
/user/team-details   → TeamDetailsScreen
/user/player-details → PlayerDetailsScreen
/user/match-summary  → MatchSummaryDownloadScreen
/shared/tournament-details → TournamentDetailsScreen
```

### Transition Types
- **Slide** (right→left): All detail/push screens
- **Fade**: Role dashboards (Admin, Scorer, User), Auth screen

### Role-Based Routing Flow
```
SplashScreen (2s)
     │
     ▼
OnboardingScreen (first launch)
     │
     ▼
AuthScreen
     │
     ├─ Admin login → /admin (AdminDashboard)
     ├─ Scorer login → /scorer (ScorerDashboard)
     ├─ User login → /user (UserDashboard)
     └─ Guest → /user (UserDashboard, read-only)
```

---

## 5. Data Layer Architecture

### Serialization
All models implement bidirectional JSON serialization:
- `toJson() → Map<String, dynamic>`
- `fromJson(Map<String, dynamic>) → ModelClass`

### Persistence Strategy
```
On app start:
  SharedPreferences.getInstance()
    → Load users JSON
    → Ensure default users exist
    → Check data_version_uvpce_2026_v2 flag
    → If flag: Load teams + matches from JSON
    → If no flag: Seed default UVPCE data, set flag

On every mutation:
  _saveTeams() / _saveMatches() / _saveUsers()
  jsonEncode(list.map(m => m.toJson()).toList())
  → SharedPreferences.setString(key, jsonString)
```

---

## 6. Screen Architecture Patterns

### Admin Dashboard Pattern
The Admin Dashboard uses a **multi-view switcher** with a custom animated overlay drawer:

```
AdminDashboard
├── Custom overlay drawer (animated, dark gradient)
│   └── Menu items → push named routes
├── _DashboardHomeView (index 0)
│   ├── Stats summary cards
│   ├── Live match cards
│   └── Quick action buttons
└── _ProfileView (index 1)
    └── Profile info + settings
```

### Scorer Dashboard Pattern
The Scorer Dashboard is the most complex screen (~1988 lines):

```
ScorerDashboard
├── Toss Setup Modal (if match not started)
├── Live Scoring View
│   ├── Match scoreboard header
│   ├── Current batsmen panel (striker + non-striker)
│   ├── Current bowler panel
│   ├── Run buttons (0, 1, 2, 3, 4, 6)
│   ├── Extras panel (Wide, No Ball, Leg Bye)
│   ├── Wicket panel (type selection + new batsman)
│   ├── Controls (Swap, End Over, Undo, Change Bowler)
│   └── Ball-by-ball commentary log
└── Profile View
```

### User Dashboard Pattern
```
UserDashboard (tab controller)
├── HomeTabView (tab 0)
│   ├── Live match card
│   └── Match list by status
├── SchedulesTabView (tab 1)
├── PredictionTabView (tab 2)
└── ProfileTabView (tab 3)
```

---

## 7. AI Commentary Engine Architecture

The commentary engine lives inside `StorageService._generateAICommentary()`:

```
Ball event received
    │
    ▼
Determine event type
    │
    ├─ isWicket → wicketTpls[random]
    ├─ extraType == "Wide" → wideTemplate
    ├─ extraType == "No Ball" → noBallTemplate
    ├─ runs == 6 → sixTpls[random]
    ├─ runs == 4 → fourTpls[random]
    ├─ runs == 0 → dotTpls[random]
    └─ runs 1-3 → runTpls[random]
    │
    ▼
Insert player names (batsman, bowler) via string interpolation
    │
    ▼
Store in BallRecord.commentary
```

Extended commentary pool also defined in `AppConstants` for display in the AI Commentary Screen.

---

## 8. Win Probability Engine Architecture

```
calculateWinProbability(match)
    │
    ├─ status == "Upcoming" → return 50.0
    ├─ status == "Completed" → return 100.0 or 0.0
    │
    └─ status == "Live"
         │
         ├─ isFirstInnings == true
         │   CRR = runsA / oversA
         │   prob = 50 + (CRR - 7.5) * 5
         │   if wicketsA > 5: prob -= (wicketsA - 5) * 8
         │
         └─ isFirstInnings == false
             runsNeeded = target - runsB
             ballsRemaining = 120 - ballsBowled
             requiredRate = (runsNeeded / ballsRemaining) * 6
             prob = 50 - (requiredRate - 7.5)*7 + (10 - wicketsB)*3
         │
         ▼
    clamp(1.0, 99.0)
```

---

## 9. PDF Report Architecture

```
PdfReportService.generateAndShareReport()
    │
    ▼
buildPdfDocument(matchDetails)
    │
    ├─ pw.Document() with title + author
    ├─ pw.MultiPage (A4, 32pt margins)
    │   ├─ Header Banner (dark navy container)
    │   ├─ Match summary section
    │   ├─ Score display cards
    │   ├─ Team A roster table
    │   ├─ Team B roster table
    │   └─ Footer (CricketVerse AI + date)
    ▼
Printing.layoutPdf() → native share/print dialog
    │
    └─ On failure → fallback in-app dialog
```

---

## 10. Theme Architecture

All visual tokens are centralized in `AppTheme` (`lib/core/theme/app_theme.dart`):

```
AppTheme
├── Brand Colors (static const Color)
│   ├── primaryBlue (Emerald Green #028A6B)
│   ├── primaryGreen (#10B981)
│   ├── accentGold (#F59E0B)
│   ├── accentRed (#E11D48)
│   └── accentOrange (#EA580C)
│
├── Background Layers
│   ├── bgDeep (#F0F4F2)
│   ├── bgDark (#F7FAF8)
│   └── bgCard (white)
│
├── Text Colors
│   ├── textPrimary (#0F172A)
│   ├── textSecondary (#475569)
│   └── textMuted (#94A3B8)
│
├── Gradients (LinearGradient)
│   ├── primaryGradient
│   ├── goldGradient
│   ├── redGradient
│   └── bgGradient
│
├── Decorations
│   ├── glassCard (white + border + shadow)
│   ├── glassCardSmall
│   └── accentCard (gradient + shadow)
│
├── Text Styles (GoogleFonts.plusJakartaSans)
│   ├── headingLarge (26, w800)
│   ├── headingMedium (20, w700)
│   ├── headingSmall (16, w600)
│   ├── bodyLarge (15)
│   ├── bodyMedium (14)
│   ├── caption (12)
│   └── labelBold (12, w700)
│
└── ThemeData (Material 3, light)
    ├── AppBarTheme
    ├── BottomNavigationBarTheme
    ├── CardTheme
    ├── ElevatedButtonTheme
    └── InputDecorationTheme
```

---

## 11. Key Design Decisions

| Decision | Rationale |
|---|---|
| Single StorageService provider | Simpler than splitting into multiple providers; acceptable for prototype scale |
| SharedPreferences over SQLite | Sufficient for JSON blob storage; no complex queries needed |
| Named routes with onGenerateRoute | Enables clean role-based routing and argument passing |
| Seed data via code (not assets) | Allows dynamic name generation and stat calculation at install time |
| AI commentary as string templates | Avoids external AI API dependency; fully offline; deterministic quality |
| Portrait-only lock | Optimal for scorer terminal on small phones; prevents layout breaks |
| darkTheme alias to lightTheme | Backward compatibility during theme refactor from dark to light |
