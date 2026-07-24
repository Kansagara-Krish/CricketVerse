# 🔌 Internal API Reference
## CricketVerse AI — StorageService Interface

> **Note:** CricketVerse AI is a 100% offline Flutter application. There are no HTTP endpoints or external REST/GraphQL APIs. All "API" contracts are internal Dart method interfaces on the `StorageService` (a `ChangeNotifier` Provider). This document describes every public method, its parameters, return values, and side effects — serving as the internal API contract for any future backend migration.

---

## StorageService

**Location:** `lib/services/storage_service.dart`  
**Pattern:** Provider (`ChangeNotifier`) — singleton mounted at app root  
**Persistence:** `SharedPreferences` (JSON serialized)

---

## State Getters

| Getter | Type | Description |
|---|---|---|
| `teams` | `List<Team>` | All teams in the system |
| `matches` | `List<CricketMatch>` | All matches (Upcoming, Live, Completed) |
| `currentRole` | `String?` | Active session role: "Admin", "Scorer", "User", "Guest", or null |
| `currentUserEmail` | `String?` | Logged-in user's email |
| `activeScorerMatchId` | `String?` | Match ID currently being scored; null if no active session |

---

## Authentication Methods

### `login(String usernameOrEmail, String password) → bool`
Validates credentials against three layers (in order):
1. Hardcoded admin check (`admin@cricketverse.ai` / `admin123`)
2. Per-match scorer credentials stored on `CricketMatch`
3. Registered user map (`SharedPreferences["users"]`)

**Side Effects:**
- Sets `_currentUserEmail`, `_currentRole`
- Calls `notifyListeners()`

**Returns:** `true` on success, `false` on failure

---

### `register(String email, String password) → bool`
Registers a new user account.

**Parameters:**
| Name | Type | Description |
|---|---|---|
| `email` | String | Unique user email |
| `password` | String | Plain-text password (stored in SharedPreferences) |

**Returns:** `true` if registered successfully, `false` if email already exists  
**Side Effects:** Persists to `SharedPreferences["users"]`, auto-logs-in as "User"

---

### `loginAsGuest() → void`
Sets session as Guest with email `guest@cricketverse.ai` and role `"Guest"`.

---

### `logout() → void`
Clears `_currentUserEmail`, `_currentRole`, `_activeScorerMatchId`.  
Calls `notifyListeners()`.

---

## Admin — Team Methods

### `addTeam(String name, String shortName, String colorHex, List<Player> players) → void`

Creates and persists a new `Team`.

| Parameter | Type | Example |
|---|---|---|
| `name` | String | "UVPCE Titans" |
| `shortName` | String | "TIT" |
| `colorHex` | String | "0xFFF59E0B" |
| `players` | List\<Player\> | [] (empty or pre-populated) |

**Side Effects:** Appends to `_teams`, saves to SharedPreferences, notifies.

---

### `updateTeam(String teamId, String name, String shortName, String colorHex) → void`

Updates display fields of an existing team (does NOT modify players).

---

### `deleteTeam(String teamId) → void`

Removes a team by ID from `_teams`.  
**Warning:** Does not cascade-delete from scheduled matches.

---

### `addPlayer(String teamId, Player player) → void`

Appends a `Player` to the specified team's `players` list.

---

### `updatePlayer(String teamId, Player updatedPlayer) → void`

Replaces player by ID. If player ID not found, appends as new.

---

### `removePlayer(String teamId, String playerId) → void`

Removes a player by ID from the specified team.

---

### `saveTeamsState() → void`

Force-saves current `_teams` state to SharedPreferences. Used after bulk mutations.

---

## Admin — Match Methods

### `scheduleMatch({...}) → void`

Creates a new `CricketMatch` with status `"Upcoming"`.

| Parameter | Type | Description |
|---|---|---|
| `teamAId` | String | ID of first team |
| `teamBId` | String | ID of second team |
| `matchType` | String | "T20" or "ODI" |
| `venue` | String | Venue display name |
| `date` | String | Date string (DD-MM-YYYY) |
| `time` | String | Time string (HH:MM) |
| `scorerUser` | String | Scorer login username |
| `scorerPass` | String | Scorer login password |

**Match ID format:** `match_{DateTime.now().millisecondsSinceEpoch}`

---

### `adminActivateMatch(String matchId) → void`

Transitions a match from `"Upcoming"` to `"Live"`.  
Auto-sets: battingTeamId (teamA), tossWinner, tossDecision ("Bat"), currentStrikerId, currentNonStrikerId, currentBowlerId.

---

### `resetMatchToZero(String matchId) → void`

Resets all scoring data for a match to initial state:
- Runs, wickets, overs → 0
- Target → 0
- Ball records → []
- Player stats → 0
- isFirstInnings → true
- Re-sets striker/non-striker/bowler to defaults

---

## Scorer — Live Scoring Methods

### `setActiveScorerMatchId(String? matchId) → void`

Sets the active match for all scorer operations. Must be called before any scoring methods.

---

### `startMatchSetup(String matchId, String tossWinnerTeam, String decision, String firstBattingTeamId) → void`

Finalizes toss and sets initial playing positions.

| Parameter | Type | Description |
|---|---|---|
| `matchId` | String | Target match ID |
| `tossWinnerTeam` | String | Team name that won toss |
| `decision` | String | "Bat" or "Bowl" |
| `firstBattingTeamId` | String | ID of the team batting first |

---

### `updateScore({...}) → void`

The core scoring method. Records a ball event, updates all affected state.

| Parameter | Type | Description |
|---|---|---|
| `runs` | int | Runs scored by batsman (0-6) |
| `extraType` | String | "Wide", "No Ball", "Leg Bye", "None" |
| `extraRuns` | int | Additional runs from extras |
| `isWicket` | bool | Whether a wicket fell |
| `wicketType` | String | "Bowled", "Caught", "LBW", "Run Out", "Stumped", "Retired Hurt", "None" |
| `dismissedPlayerId` | String? | ID of dismissed batsman |
| `newBatsmanId` | String? | ID of incoming batsman |
| `newBatsmanPosition` | String? | "Striker" or "Non-Striker" |

**Side Effects (per call):**
1. Increments team runs (runsA or runsB)
2. Increments wickets if applicable
3. Updates overs counter (Wide/No Ball = 0 balls)
4. Updates striker's `runsScored` and `ballsFaced`
5. Updates bowler's `runsConceded`, `wicketsTaken`, `oversBowled`
6. Generates AI commentary string
7. Appends `BallRecord` to `match.balls`
8. Rotates strike on odd runs
9. Handles incoming batsman on wicket
10. Calls `endInningsOrMatch()` if all-out
11. Persists + notifies

---

### `undoLastBall() → void`

Reverses the last `BallRecord` from `match.balls`:
- Decrements team runs/wickets/overs
- Decrements player stats (runs, balls, wickets, economy)
- Restores striker/non-striker/bowler IDs from the BallRecord snapshot
- Resets status back to "Live" if match was "Completed"

---

### `swapStrikers() → void`

Swaps `currentStrikerId` and `currentNonStrikerId`.

---

### `switchBowler(String newBowlerId) → void`

Sets `currentBowlerId` for the active match.

---

### `setStriker(String strikerId) → void`

Directly sets the striker player ID.

---

### `setNonStriker(String nonStrikerId) → void`

Directly sets the non-striker player ID.

---

### `endOver() → void`

Called at end of each over:
1. Rotates strike (swap striker/non-striker)
2. Auto-selects next bowler (cycles backwards through bowling team roster)
3. Persists + notifies

---

### `endInningsOrMatch() → void`

Handles innings/match completion:

**If first innings:**
- Flips `isFirstInnings` to `false`
- Switches `battingTeamId`
- Sets target = `runsA + 1`
- Resets striker/non-striker/bowler for 2nd innings

**If second innings:**
- Sets `match.status = "Completed"`

---

### `endMatchForce() → void`

Immediately sets `match.status = "Completed"` without innings logic.

---

## Analytics Methods

### `calculateWinProbability(CricketMatch match) → double`

Returns a win probability (1.0–99.0) for Team A.

**Logic:**

*If Upcoming:* `50.0`  
*If Completed:* `100.0` (Team A won) or `0.0` (Team B won)  
*If Live, 1st Innings:*
```
prob = 50 + (CRR - 7.5) * 5
if wicketsA > 5: prob -= (wicketsA - 5) * 8
```
*If Live, 2nd Innings:*
```
runsNeeded = target - runsB
ballsRemaining = totalBalls - ballsBowled
requiredRate = (runsNeeded / ballsRemaining) * 6
prob = 50 - (requiredRate - 7.5) * 7 + (10 - wicketsB) * 3
```

---

## AI Commentary Method

### `_generateAICommentary(String batsman, String bowler, int runs, String extraType, bool isWicket, String wicketType) → String`

Private method, auto-called within `updateScore()`. Returns randomized context-aware commentary from template pools:

| Event | Template Pool Size |
|---|---|
| Wicket | 4 templates |
| Wide | 1 template |
| No Ball | 1 template |
| Six (6) | 3 templates |
| Four (4) | 3 templates |
| Dot (0) | 3 templates |
| 1-3 runs | 3 templates |

---

## PDF Report Service

**Location:** `lib/services/pdf_report_service.dart`  
**Class:** `PdfReportService` (static methods only)

### `generateAndShareReport({BuildContext context, Map<String, dynamic> matchDetails}) → Future<void>`

Builds a PDF document and opens the native print/share dialog.

**Input (`matchDetails` keys):**
| Key | Type | Description |
|---|---|---|
| `title` | String | Match title string |
| `teamAName` | String | Team A display name |
| `teamBName` | String | Team B display name |
| `scoreA` | String | Score string (e.g. "145/4") |
| `scoreB` | String | Score string |
| `oversA` | String | Overs string (e.g. "15.4 Overs") |
| `oversB` | String | Overs string |
| `result` | String | Result text |
| `teamAPlayers` | List\<String\> | Player name list |
| `teamBPlayers` | List\<String\> | Player name list |

---

### `buildPdfDocument(Map<String, dynamic> matchDetails) → Future<Uint8List>`

Builds and returns raw PDF bytes (A4, multi-page). Includes:
- Branded header banner (dark navy)
- Match summary card
- Score comparison section
- Team rosters (two-column layout)
- Footer with generation timestamp

---

## Persistence Keys (SharedPreferences)

| Key | Type | Contents |
|---|---|---|
| `users` | String (JSON) | Map of email → password |
| `teams` | String (JSON) | List of serialized Team objects |
| `matches` | String (JSON) | List of serialized CricketMatch objects |
| `data_version_uvpce_2026_v2` | bool | Seed data load flag (prevents re-seeding) |

---

## Future Migration Notes

When migrating to a real backend (e.g., Firebase/Supabase), the following surface area maps to REST endpoints:

| StorageService Method | Equivalent REST Endpoint |
|---|---|
| `login()` | `POST /auth/login` |
| `register()` | `POST /auth/register` |
| `addTeam()` | `POST /teams` |
| `updateTeam()` | `PUT /teams/:id` |
| `deleteTeam()` | `DELETE /teams/:id` |
| `addPlayer()` | `POST /teams/:id/players` |
| `scheduleMatch()` | `POST /matches` |
| `updateScore()` | `POST /matches/:id/balls` |
| `undoLastBall()` | `DELETE /matches/:id/balls/last` |
| `endInningsOrMatch()` | `PUT /matches/:id/innings` |
| `calculateWinProbability()` | `GET /matches/:id/prediction` |
