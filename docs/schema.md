# 🗄️ Data Schema Reference
## CricketVerse AI — Models & Persistence Schema

**Version:** 1.0.0  
**Storage:** SharedPreferences (JSON serialized Dart objects)  
**Location:** `lib/models/models.dart`

---

## Overview

CricketVerse AI uses four Dart model classes as its complete data schema. All models are serialized to JSON and stored in SharedPreferences. There is no SQL schema or external database.

```
┌───────────┐       ┌──────────────┐
│  Player   │ many  │     Team     │
│           │◄──────│              │
└───────────┘       └──────┬───────┘
                           │ 2 teams
                    ┌──────▼───────┐       ┌────────────┐
                    │ CricketMatch │ 1:N   │ BallRecord │
                    │              │──────►│            │
                    └──────────────┘       └────────────┘
```

---

## 1. Player

Represents a cricket player in a team's roster.

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | String | required | Unique player ID. Format: `{teamShort}_{firstName}_{index}` |
| `name` | String | required | Full display name (e.g., "Aarav Patel") |
| `role` | String | required | One of: `"Batter"`, `"Bowler"`, `"All-rounder"` |
| `nationality` | String | required | Country code (e.g., `"IND"`) |
| `runsScored` | int | 0 | Career/session total runs scored |
| `ballsFaced` | int | 0 | Career/session total balls faced |
| `wicketsTaken` | int | 0 | Career/session wickets taken |
| `runsConceded` | int | 0 | Career/session runs conceded while bowling |
| `oversBowled` | double | 0.0 | Overs bowled in decimal format (e.g., `3.4` = 3 overs 4 balls) |
| `matchesPlayed` | int | 0 | Total matches played |

### Computed Stats (derived, not stored)
| Stat | Formula |
|---|---|
| Strike Rate | `(runsScored / ballsFaced) * 100` |
| Batting Average | `runsScored / matchesPlayed` |
| Economy Rate | `runsConceded / oversBowled` |
| Bowling Average | `runsConceded / wicketsTaken` |

### JSON Representation
```json
{
  "id": "uvpce_titans_aarav_0",
  "name": "Aarav Patel",
  "role": "Batter",
  "nationality": "IND",
  "runsScored": 540,
  "ballsFaced": 420,
  "wicketsTaken": 2,
  "runsConceded": 85,
  "oversBowled": 8.2,
  "matchesPlayed": 18
}
```

### SharedPreferences Key
Stored as part of `Team.players` list, which is embedded inside the `teams` JSON array.

---

## 2. Team

Represents a cricket team with its full player roster.

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | String | required | Unique team ID. Format: lowercase name with underscores (e.g., `"uvpce_titans"`) |
| `name` | String | required | Full team name (e.g., `"UVPCE - Titans"`) |
| `shortName` | String | required | Abbreviated name for scorecard display |
| `logoColorHex` | String | required | Team color as 0xFF-prefixed hex string (e.g., `"0xFFF59E0B"`) |
| `players` | List\<Player\> | required | Full 11-player roster |

### JSON Representation
```json
{
  "id": "uvpce_titans",
  "name": "UVPCE - Titans",
  "shortName": "UVPCE - Titans",
  "logoColorHex": "0xFFF59E0B",
  "players": [
    { "id": "...", "name": "...", ... }
  ]
}
```

### SharedPreferences Key
`"teams"` → JSON array of Team objects

### Team Color Reference (Default Seeds)

| Team | Color Hex | Display Color |
|---|---|---|
| UVPCE A | `0xFF028A6B` | Emerald Green |
| UVPCE B | `0xFF10B981` | Mint Green |
| UVPCE C | `0xFFD97706` | Amber |
| UVPCE Titans | `0xFFF59E0B` | Gold |
| UVPCE Warriors | `0xFFEF4444` | Red |
| UVPCE Challengers | `0xFFEA580C` | Orange |
| UVPCE Strikers | `0xFF0B6623` | Forest Green |
| UVPCE Legends | `0xFF14B8A6` | Teal |

---

## 3. BallRecord

Represents a single ball delivery event. Immutable once recorded.

| Field | Type | Default | Description |
|---|---|---|---|
| `run` | int | required | Runs scored off the bat (0–6) |
| `extraRun` | int | required | Additional runs from extras |
| `extraType` | String | required | One of: `"Wide"`, `"No Ball"`, `"Leg Bye"`, `"None"` |
| `isWicket` | bool | required | Whether a wicket fell on this delivery |
| `wicketType` | String | required | One of: `"Bowled"`, `"Caught"`, `"LBW"`, `"Run Out"`, `"Stumped"`, `"Retired Hurt"`, `"None"` |
| `batsmanName` | String | required | Display name of the striker at the time of delivery |
| `bowlerName` | String | required | Display name of the bowler |
| `commentary` | String | required | AI-generated commentary string for this ball |
| `timestamp` | DateTime | required | ISO 8601 timestamp when ball was recorded |
| `strikerId` | String? | null | Snapshot of striker ID (used for undo) |
| `nonStrikerId` | String? | null | Snapshot of non-striker ID (used for undo) |
| `bowlerId` | String? | null | Snapshot of bowler ID (used for undo) |

### Business Rules
- **Wide / No Ball:** `ballVal = 0` — does not count as a legal delivery. Over counter does not increment.
- **Leg Bye:** Runs count to team total but NOT to batsman's `runsScored` or `ballsFaced`.
- **Run Out / Retired Out / Retired Hurt:** Wicket type; bowler does NOT get credit for wicket.
- **Strike Rotation:** If `runs % 2 != 0` AND extraType is `"None"` or `"Leg Bye"`, strikers swap.

### JSON Representation
```json
{
  "run": 4,
  "extraRun": 0,
  "extraType": "None",
  "isWicket": false,
  "wicketType": "None",
  "batsmanName": "Aarav Patel",
  "bowlerName": "Rohan Shah",
  "commentary": "FOUR! Beautiful shot! Races to the boundary at third man!",
  "timestamp": "2026-07-17T19:45:30.000Z",
  "strikerId": "uvpce_titans_aarav_0",
  "nonStrikerId": "uvpce_titans_vihaan_1",
  "bowlerId": "uvpce_warriors_rudra_10"
}
```

---

## 4. CricketMatch

The primary match entity. Contains all match state including both teams, innings data, and ball-by-ball history.

### Identity & Metadata

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | String | required | Unique match ID. Format: `match_{millisecondsSinceEpoch}` |
| `teamA` | Team | required | First team (home/left side on scoreboard) |
| `teamB` | Team | required | Second team (away/right side) |
| `matchType` | String | required | `"T20"` or `"ODI"` |
| `venue` | String | required | Venue display name |
| `date` | String | required | Date in `"DD-MM-YYYY"` format |
| `time` | String | required | Time in `"HH:MM"` format |

### Match Status

| Field | Type | Default | Description |
|---|---|---|---|
| `status` | String | `"Upcoming"` | One of: `"Upcoming"`, `"Live"`, `"Completed"` |
| `tossWinner` | String | `""` | Name of team that won the toss |
| `tossDecision` | String | `""` | `"Bat"` or `"Bowl"` |
| `battingTeamId` | String | `""` | Team ID of the team currently batting |

### Playing XI

| Field | Type | Default | Description |
|---|---|---|---|
| `playingXI_A` | List\<Player\> | required | 11-player batting/playing list for Team A |
| `playingXI_B` | List\<Player\> | required | 11-player batting/playing list for Team B |

### Innings 1 Scorecard

| Field | Type | Default | Description |
|---|---|---|---|
| `runsA` | int | 0 | Total runs scored by Team A |
| `wicketsA` | int | 0 | Wickets fallen for Team A |
| `oversA` | double | 0.0 | Overs completed by Team A (e.g., `15.4` = 15 overs 4 balls) |

### Innings 2 Scorecard

| Field | Type | Default | Description |
|---|---|---|---|
| `runsB` | int | 0 | Total runs scored by Team B |
| `wicketsB` | int | 0 | Wickets fallen for Team B |
| `oversB` | double | 0.0 | Overs completed by Team B |
| `target` | int | 0 | Target for the chasing team (set at innings switch as runsA + 1) |

### Innings State

| Field | Type | Default | Description |
|---|---|---|---|
| `isFirstInnings` | bool | true | Whether the match is currently in the first innings |

### Scorer Access

| Field | Type | Default | Description |
|---|---|---|---|
| `scorerUsername` | String | required | Username for scorer login (per match) |
| `scorerPassword` | String | required | Password for scorer login (per match) |

### Live State (Active Player IDs)

| Field | Type | Default | Description |
|---|---|---|---|
| `currentStrikerId` | String | `""` | Player ID of the current striker |
| `currentNonStrikerId` | String | `""` | Player ID of the current non-striker |
| `currentBowlerId` | String | `""` | Player ID of the current bowler |

### Ball History

| Field | Type | Default | Description |
|---|---|---|---|
| `balls` | List\<BallRecord\> | required | Complete ball-by-ball delivery log |

### JSON Representation
```json
{
  "id": "live_world_cup_final",
  "teamA": { "id": "uvpce_titans", "name": "UVPCE - Titans", ... },
  "teamB": { "id": "uvpce_warriors", "name": "UVPCE - Warriors", ... },
  "matchType": "T20",
  "venue": "Narendra Modi Stadium",
  "date": "17-07-2026",
  "time": "19:30",
  "status": "Live",
  "tossWinner": "UVPCE - Titans",
  "tossDecision": "Bat",
  "battingTeamId": "uvpce_titans",
  "playingXI_A": [...],
  "playingXI_B": [...],
  "runsA": 145,
  "wicketsA": 4,
  "oversA": 15.4,
  "runsB": 0,
  "wicketsB": 0,
  "oversB": 0.0,
  "target": 185,
  "scorerUsername": "scorer1",
  "scorerPassword": "123",
  "currentStrikerId": "uvpce_titans_aarav_0",
  "currentNonStrikerId": "uvpce_titans_vihaan_1",
  "currentBowlerId": "uvpce_warriors_rudra_10",
  "balls": [...],
  "isFirstInnings": true
}
```

### SharedPreferences Key
`"matches"` → JSON array of CricketMatch objects

---

## 5. User Accounts (In-Memory Map)

Not a Dart model class — stored as a simple JSON map.

| Structure | Type | Description |
|---|---|---|
| Key | String | User email address |
| Value | String | Plain-text password |

### JSON Structure
```json
{
  "user@gmail.com": "user123",
  "alex@gmail.com": "alex123",
  "newuser@example.com": "mypassword"
}
```

### SharedPreferences Key
`"users"` → JSON-encoded map

### Default Accounts (seeded on first load)
| Email | Password | Role |
|---|---|---|
| `admin@cricketverse.ai` | `admin123` | Admin (hardcoded, not in map) |
| `scorer1` | `123` | Scorer (per live_world_cup_final match) |
| `scorer2` | `456` | Scorer (per completed_bilateral_1 match) |
| `user@gmail.com` | `user123` | User (in map) |
| `alex@gmail.com` | `alex123` | User (in map) |

---

## 6. SharedPreferences Key Reference

| Key | Value Type | Contents | Notes |
|---|---|---|---|
| `users` | String (JSON) | `Map<String, String>` | Email → Password map |
| `teams` | String (JSON) | `List<Team>` | All teams with embedded players |
| `matches` | String (JSON) | `List<CricketMatch>` | All matches with embedded ball records |
| `data_version_uvpce_2026_v2` | bool | Seed flag | Prevents re-seeding on restart |

---

## 7. Overs Format Convention

Overs are stored as `double` using a non-standard decimal format:

```
15.4 means "15 overs and 4 balls" (NOT 15.4 mathematical overs)

Increment logic:
  ballsInt += 1
  if (ballsInt >= 6):
    oversInt += 1
    ballsInt = 0
  result = oversInt + (ballsInt / 10.0)

Examples:
  15.5 + 1 ball = 16.0  (over complete)
  3.4  + 1 ball = 3.5
  3.5  + 1 ball = 4.0   (over complete)
```

---

## 8. Match Status Lifecycle

```
"Upcoming"
    │
    │ Admin activates (adminActivateMatch) OR
    │ Scorer sets up toss (startMatchSetup)
    ▼
 "Live"
    │
    │ endInningsOrMatch() called when:
    │   - All 10 wickets fall
    │   - Max overs reached (manual trigger)
    │   - endMatchForce() called
    ▼
"Completed"
    │
    │ undoLastBall() can revert:
    └──────────────────────────► "Live" (if status was "Completed")
```

---

## 9. Player Role System

| Role | Color | Description |
|---|---|---|
| `"Batter"` | Emerald Green (#028A6B) | Specialist batsman |
| `"Bowler"` | Crimson (#E11D48) | Specialist bowler |
| `"All-rounder"` | Gold (#F59E0B) | Batting and bowling capability |

Default team composition (per 11-player roster):
- Positions 0-3: Batter
- Positions 4-6: All-rounder  
- Positions 7-10: Bowler

---

## 10. Seed Data Specification (UVPCE 2026)

### Seeded Teams
Generated by `StorageService._loadDefaultTeams()` using deterministic algorithm:

| Team ID | Name | Color | Start Index |
|---|---|---|---|
| `uvpce_a` | UVPCE - A | Emerald Green | 0 |
| `uvpce_b` | UVPCE - B | Mint Green | 5 |
| `uvpce_c` | UVPCE - C | Amber | 10 |
| `uvpce_titans` | UVPCE - Titans | Gold | 15 |
| `uvpce_warriors` | UVPCE - Warriors | Red | 20 |
| `uvpce_challengers` | UVPCE - Challengers | Orange | 25 |
| `uvpce_strikers` | UVPCE - Strikers | Forest Green | 3 |
| `uvpce_legends` | UVPCE - Legends | Teal | 8 |

### Seeded Matches

**Match 1 — Live:**
```
id: live_world_cup_final
Teams: UVPCE Titans vs UVPCE Warriors
Type: T20
Venue: Narendra Modi Stadium
Date: 17-07-2026 19:30
Status: Live
Innings 1: 145/4 (15.4)
Target: 185
Scorer: scorer1 / 123
```

**Match 2 — Completed:**
```
id: completed_bilateral_1
Teams: UVPCE A vs UVPCE B
Type: T20
Venue: Wankhede Stadium
Date: 15-07-2026 14:30
Status: Completed
UVPCE A: 168/6 (20.0)
UVPCE B: 169/5 (19.3) — Won by 5 wickets
Scorer: scorer2 / 456
```
