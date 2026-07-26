# CricketVerse AI - End-to-End Connectivity & Mock Data Removal Checklist

This document tracks the tasks required to remove mock data from the Flutter mobile app, establish full end-to-end connectivity with the Node.js/Prisma backend, and execute complete system testing.

---

## 1. Mock Data Removal & Mobile App Cleanup

- [ ] **Remove Local Offline Mock Data in Storage Service**
  - [ ] Strip hardcoded dummy team list seeding from `StorageService._seedDefaultTeams()` in `mobile_app/lib/services/storage_service.dart`.
  - [ ] Strip hardcoded dummy match seeding from `StorageService._seedDefaultMatches()` in `storage_service.dart`.
  - [ ] Enforce live backend API fetching (`ApiService.getTeams()`, `ApiService.getMatches()`) as the primary data source.
- [ ] **Remove Hardcoded Screen Mock Data**
  - [ ] Remove hardcoded player lists in `edit_team_screen.dart` and `team_management_screen.dart`.
  - [ ] Remove hardcoded win probabilities & mock prediction charts in `prediction_tab_view.dart` and `prediction_screen.dart`.
  - [ ] Remove mock commentary fallbacks in `match_details_screen.dart`.
- [ ] **Clean Up Offline Fallbacks**
  - [ ] Ensure app fails gracefully with clear error messages/snackbars when network connectivity fails instead of silently falling back to mock data.

---

## 2. End-to-End API & Real-Time Connectivity

### 2.1 Authentication & User Session
- [ ] Connect `AuthScreen` login form to `ApiService.login(email, password)`.
- [ ] Connect registration form to `ApiService.register(email, password)`.
- [ ] Store backend JWT token in `SharedPreferences` securely.
- [ ] Verify `getMe()` token authentication on app launch in `SplashScreen`.

### 2.2 Team & Player Management
- [ ] Connect `getTeams()` to fetch live teams from `GET /api/v1/teams`.
- [ ] Connect `addTeam()` to post new teams to `POST /api/v1/teams`.
- [ ] Connect `updateTeam()` and `deleteTeam()` to `PUT /api/v1/teams/:id` and `DELETE /api/v1/teams/:id`.
- [ ] Connect `addPlayer()`, `updatePlayer()`, and `removePlayer()` to respective backend player API routes.

### 2.3 Match Management & Scheduling
- [ ] Connect `getMatches()` to fetch all matches from `GET /api/v1/matches`.
- [ ] Connect `scheduleMatch()` form in `schedule_match_screen.dart` to `POST /api/v1/matches`.
- [ ] Connect match activation (`adminActivateMatch`) to `POST /api/v1/matches/:id/activate`.
- [ ] Connect match reset (`resetMatchToZero`) to `POST /api/v1/matches/:id/reset`.

### 2.4 Live Scoring & Socket.IO Real-Time Sync
- [ ] Connect `updateScore()` ball entry to `POST /api/v1/scoring/:matchId/ball`.
- [ ] Connect `undoLastBall()` to `POST /api/v1/scoring/:matchId/undo`.
- [ ] Connect `swapStrikers()` to `POST /api/v1/scoring/:matchId/swap-strike`.
- [ ] Connect `switchBowler()` to `POST /api/v1/scoring/:matchId/switch-bowler`.
- [ ] Connect `endInningsOrMatch()` to `POST /api/v1/scoring/:matchId/end-innings`.
- [ ] Verify Socket.IO room subscriptions (`join_match`, `leave_match`) and real-time `match_update` event listeners in `SocketService`.

---

## 3. Complete End-to-End Testing Matrix

- [ ] **Auth Tests**:
  - [ ] Test Admin login (`admin@cricketverse.ai` / `admin123`).
  - [ ] Test Scorer login with match-specific credentials.
  - [ ] Test standard User registration and login flow.
- [ ] **Admin Workflow Tests**:
  - [ ] Create a new team with 11 players and verify persistence in PostgreSQL via Prisma.
  - [ ] Schedule a new match between Team A and Team B with assigned scorer credentials.
  - [ ] Activate match to LIVE status and verify real-time status update across client apps.
- [ ] **Scorer Live Scoring Tests**:
  - [ ] Perform toss setup (winner, decision, first batting team).
  - [ ] Record normal runs (0, 1, 2, 3, 4, 6) and verify strike rotation.
  - [ ] Record extra runs (Wides, No Balls, Leg Byes).
  - [ ] Record wickets (Bowled, Caught, LBW, Run Out) and select next incoming batsman.
  - [ ] Test "Undo Last Ball" functionality and verify score/stat reversal in database.
  - [ ] Complete first innings and verify target calculation and innings transition.
- [ ] **User Live View & Real-Time Sync Tests**:
  - [ ] Open user match detail screen on phone and verify instant Socket.IO updates on every ball scored by scorer.
  - [ ] Verify live commentary feed updates dynamically.
  - [ ] Download PDF summary report and verify accuracy of scores and scorecard statistics.
