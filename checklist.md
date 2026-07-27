# CricketVerse AI - End-to-End Connectivity & Mock Data Removal Checklist

This document tracks the tasks required to remove mock data from the Flutter mobile app, establish full end-to-end connectivity with the Node.js/Prisma backend, and execute complete system testing.

---

## 1. Mock Data Removal & Mobile App Cleanup

- [x] **Remove Local Offline Mock Data in Storage Service**
  - [x] Strip hardcoded dummy team list seeding from `StorageService._seedDefaultTeams()` in `mobile_app/lib/services/storage_service.dart`.
  - [x] Strip hardcoded dummy match seeding from `StorageService._seedDefaultMatches()` in `storage_service.dart`.
  - [x] Enforce live backend API fetching (`ApiService.getTeams()`, `ApiService.getMatches()`) as the primary data source.
- [x] **Remove Hardcoded Screen Mock Data**
  - [x] Remove hardcoded player lists in `edit_team_screen.dart` and `team_management_screen.dart`.
  - [x] Remove hardcoded win probabilities & mock prediction charts in `prediction_tab_view.dart` and `prediction_screen.dart`.
  - [x] Remove mock commentary fallbacks in `match_details_screen.dart`.
- [x] **Clean Up Offline Fallbacks**
  - [x] Ensure app fails gracefully with clear error messages/snackbars when network connectivity fails instead of silently falling back to mock data.

---

## 2. End-to-End API & Real-Time Connectivity

### 2.1 Authentication & User Session
- [x] Connect `AuthScreen` login form to `ApiService.login(email, password)`.
- [x] Connect registration form to `ApiService.register(email, password)`.
- [x] Store backend JWT token in `SharedPreferences` securely.
- [x] Verify `getMe()` token authentication on app launch in `SplashScreen`.

### 2.2 Team & Player Management
- [x] Connect `getTeams()` to fetch live teams from `GET /api/v1/teams`.
- [x] Connect `addTeam()` to post new teams to `POST /api/v1/teams`.
- [x] Connect `updateTeam()` and `deleteTeam()` to `PUT /api/v1/teams/:id` and `DELETE /api/v1/teams/:id`.
- [x] Connect `addPlayer()`, `updatePlayer()`, and `removePlayer()` to respective backend player API routes.

### 2.3 Match Management & Scheduling
- [x] Connect `getMatches()` to fetch all matches from `GET /api/v1/matches`.
- [x] Connect `scheduleMatch()` form in `schedule_match_screen.dart` to `POST /api/v1/matches`.
- [x] Connect match activation (`adminActivateMatch`) to `POST /api/v1/matches/:id/activate`.
- [x] Connect match reset (`resetMatchToZero`) to `POST /api/v1/matches/:id/reset`.

### 2.4 Live Scoring & Socket.IO Real-Time Sync
- [x] Connect `updateScore()` ball entry to `POST /api/v1/scoring/:matchId/ball`.
- [x] Connect `undoLastBall()` to `POST /api/v1/scoring/:matchId/undo`.
- [x] Connect `swapStrikers()` to `POST /api/v1/scoring/:matchId/swap-strike`.
- [x] Connect `switchBowler()` to `POST /api/v1/scoring/:matchId/switch-bowler`.
- [x] Connect `endInningsOrMatch()` to `POST /api/v1/scoring/:matchId/end-innings`.
- [x] Verify Socket.IO room subscriptions (`join_match`, `leave_match`) and real-time `match_update` event listeners in `SocketService`.

---

## 3. Complete End-to-End Testing Matrix

- [x] **Auth Tests**:
  - [x] Test Admin login (`admin@cricketverse.ai` / `admin123`).
  - [x] Test Scorer login with match-specific credentials.
  - [x] Test standard User registration and login flow.
- [x] **Admin Workflow Tests**:
  - [x] Create a new team with 11 players and verify persistence in PostgreSQL via Prisma.
  - [x] Schedule a new match between Team A and Team B with assigned scorer credentials.
  - [x] Activate match to LIVE status and verify real-time status update across client apps.
- [x] **Scorer Live Scoring Tests**:
  - [x] Perform toss setup (winner, decision, first batting team).
  - [x] Record normal runs (0, 1, 2, 3, 4, 6) and verify strike rotation.
  - [x] Record extra runs (Wides, No Balls, Leg Byes).
  - [x] Record wickets (Bowled, Caught, LBW, Run Out) and select next incoming batsman.
  - [x] Test "Undo Last Ball" functionality and verify score/stat reversal in database.
  - [x] Complete first innings and verify target calculation and innings transition.
- [x] **User Live View & Real-Time Sync Tests**:
  - [x] Open user match detail screen on phone and verify instant Socket.IO updates on every ball scored by scorer.
  - [x] Verify live commentary feed updates dynamically.
  - [x] Download PDF summary report and verify accuracy of scores and scorecard statistics.
