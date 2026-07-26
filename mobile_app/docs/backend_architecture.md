# ⚙️ Proposed Backend Architecture & Migration Guide
## CricketVerse AI — ExpressJS + PostgreSQL + Redis + Socket.IO

**Version:** 1.0.0  
**Target Stack:** Node.js (ExpressJS + TypeScript), PostgreSQL (Relational DB), Redis (In-Memory Cache & Pub/Sub), Socket.IO (Real-Time WebSockets)  
**Goal:** Transition CricketVerse AI from an offline Flutter application to a production-grade, real-time distributed system capable of serving thousands of concurrent users.

---

## 1. Stack Overview

| Component | Technology | Purpose |
|---|---|---|
| **Runtime Environment** | Node.js (TypeScript) | Strongly typed, event-driven server runtime |
| **Web Framework** | Express.js | Production-proven REST API framework for authentication, admin management, and scoring endpoints |
| **Primary Database** | PostgreSQL | Relational database ensuring ACID compliance for match scores, player stats, and tournament structures |
| **ORM / Query Builder** | Drizzle ORM / Prisma | Type-safe SQL query generation and schema migrations |
| **Cache & Real-Time Engine** | Redis | In-memory key-value store for live match snapshots, fast state retrieval, and Socket.IO Pub/Sub adapter |
| **Real-Time Communication** | Socket.IO | Bi-directional WebSocket communication for live score updates, ball-by-ball commentary, and win predictions |

---

## 2. High-Level Backend Architecture Diagram

```
                                  ┌──────────────────────────────┐
                                  │      Flutter Mobile App      │
                                  └──────────────┬───────────────┘
                                                 │
                        ┌────────────────────────┴────────────────────────┐
                        │                                                 │
                        ▼ REST API (HTTPS)                                ▼ WebSockets (WSS)
            ┌───────────────────────┐                         ┌───────────────────────┐
            │   Express.js Server   │                         │    Socket.IO Server   │
            │   (API Controllers)   │                         │  (Real-Time Gateways) │
            └───────────┬───────────┘                         └───────────┬───────────┘
                        │                                                 │
                        ├────────────────────────┬────────────────────────┤
                        │                        │                        │
                        ▼                        ▼                        ▼
             ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
             │     Drizzle ORM     │  │   Redis Pub/Sub &   │  │    Socket Adapter   │
             │   (Data Access)     │  │   Match Cache       │  │    (Redis Broadcaster)
             └──────────┬──────────┘  └──────────┬──────────┘  └─────────────────────┘
                        │                        │
                        ▼                        ▼
             ┌─────────────────────┐  ┌─────────────────────┐
             │   PostgreSQL DB     │  │     Redis Cache     │
             │ (Persistent Data)   │  │   (Active Matches)  │
             └─────────────────────┘  └─────────────────────┘
```

---

## 3. Database Schema Design (PostgreSQL)

### 3.1 Tables Overview

1. `users`: System users (Admins, Scorers, Fans)
2. `tournaments`: Tournament metadata
3. `teams`: Team profiles and metadata
4. `players`: Player profiles and career aggregates
5. `team_players`: Junction table mapping players to teams
6. `matches`: Match metadata, venue, toss details, targets, status
7. `match_playing_xi`: Junction table tracking match line-ups
8. `ball_records`: Ball-by-ball history (log of events)

---

### 3.2 SQL Schema DDL (PostgreSQL)

```sql
-- Enums
CREATE TYPE user_role AS ENUM ('ADMIN', 'SCORER', 'FAN', 'GUEST');
CREATE TYPE player_role AS ENUM ('BATTER', 'BOWLER', 'ALL_ROUNDER');
CREATE TYPE match_status AS ENUM ('UPCOMING', 'LIVE', 'COMPLETED');
CREATE TYPE match_format AS ENUM ('T20', 'ODI');
CREATE TYPE extra_type AS ENUM ('NONE', 'WIDE', 'NO_BALL', 'LEG_BYE');
CREATE TYPE wicket_type AS ENUM ('NONE', 'BOWLED', 'CAUGHT', 'LBW', 'RUN_OUT', 'STUMPED', 'RETIRED_HURT');

-- 1. Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'FAN',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tournaments Table
CREATE TABLE tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    format match_format DEFAULT 'T20',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Teams Table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50) NOT NULL,
    logo_color_hex VARCHAR(10) NOT NULL DEFAULT '0xFF028A6B',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Players Table
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    role player_role NOT NULL,
    nationality VARCHAR(10) DEFAULT 'IND',
    runs_scored INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    wickets_taken INT DEFAULT 0,
    runs_conceded INT DEFAULT 0,
    overs_bowled NUMERIC(5,1) DEFAULT 0.0,
    matches_played INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Team Players Junction Table
CREATE TABLE team_players (
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    PRIMARY KEY (team_id, player_id)
);

-- 6. Matches Table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    team_a_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    team_b_id UUID REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
    match_type match_format DEFAULT 'T20',
    venue VARCHAR(255) NOT NULL,
    match_date DATE NOT NULL,
    match_time TIME NOT NULL,
    status match_status DEFAULT 'UPCOMING',
    toss_winner_id UUID REFERENCES teams(id),
    toss_decision VARCHAR(10), -- 'Bat' or 'Bowl'
    batting_team_id UUID REFERENCES teams(id),
    
    -- Scorecard Innings 1
    runs_a INT DEFAULT 0,
    wickets_a INT DEFAULT 0,
    overs_a NUMERIC(4,1) DEFAULT 0.0,
    
    -- Scorecard Innings 2
    runs_b INT DEFAULT 0,
    wickets_b INT DEFAULT 0,
    overs_b NUMERIC(4,1) DEFAULT 0.0,
    target INT DEFAULT 0,
    
    is_first_innings BOOLEAN DEFAULT TRUE,
    
    -- Active On-Field State
    current_striker_id UUID REFERENCES players(id),
    current_non_striker_id UUID REFERENCES players(id),
    current_bowler_id UUID REFERENCES players(id),
    
    -- Scorer Credentials
    scorer_username VARCHAR(100) UNIQUE NOT NULL,
    scorer_password_hash VARCHAR(255) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Match Playing XI
CREATE TABLE match_playing_xi (
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    PRIMARY KEY (match_id, team_id, player_id)
);

-- 8. Ball Records Table
CREATE TABLE ball_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE NOT NULL,
    ball_number INT NOT NULL,
    run INT NOT NULL DEFAULT 0,
    extra_run INT NOT NULL DEFAULT 0,
    extra_type extra_type DEFAULT 'NONE',
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_type wicket_type DEFAULT 'NONE',
    batsman_id UUID REFERENCES players(id) NOT NULL,
    bowler_id UUID REFERENCES players(id) NOT NULL,
    batsman_name VARCHAR(255) NOT NULL,
    bowler_name VARCHAR(255) NOT NULL,
    commentary TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Snapshot State for Undo Operations
    striker_id UUID REFERENCES players(id),
    non_striker_id UUID REFERENCES players(id),
    bowler_snapshot_id UUID REFERENCES players(id)
);

-- Indexes for Query Acceleration
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_ball_records_match ON ball_records(match_id);
CREATE INDEX idx_players_role ON players(role);
```

---

## 4. Redis Cache & Data Invalidation Strategy

To prevent hundreds of concurrent fans from swamping the PostgreSQL database during live matches, Express.js uses Redis for caching:

### 4.1 Data Keys Pattern
| Key Structure | Data Type | Purpose | TTL |
|---|---|---|---|
| `match:{matchId}:live` | JSON String | Complete live scorecard + current active batsmen & bowler | Expire 1 hour after match completion |
| `match:{matchId}:balls` | Redis List (JSON) | Last 20 ball records for fast commentary scrolling | Expire 1 hour after match completion |
| `teams:all` | JSON String | List of all teams | 24 Hours (Invalidate on update) |
| `stats:leaderboard:runs` | Redis ZSET | Top run scorers in real-time | Updated every ball |

### 4.2 Caching Strategy Logic
1. **On Ball Update (`POST /api/v1/matches/:id/score`):**
   * Express processes ball entry within PostgreSQL transaction.
   * Express writes updated state to PostgreSQL.
   * Express updates `match:{matchId}:live` cache string in Redis.
   * Express pushes the event to Socket.IO and publishes to Redis channel `match_updates`.
2. **On Score Read (`GET /api/v1/matches/:id/live`):**
   * Query Redis `match:{matchId}:live`.
   * If Cache Hit ➔ Return JSON instantly (< 5ms).
   * If Cache Miss ➔ Query Postgres ➔ Store in Redis ➔ Return JSON.

---

## 5. Socket.IO Real-Time Messaging Spec

### 5.1 Connection Flow
* **Room-based subscriptions:** Fans join match-specific rooms `match:{matchId}` upon viewing match details.
* **Authentication:** JWT Bearer token passed in Socket.IO handshake headers.

### 5.2 Event Definitions

#### Client ➔ Server Events
| Event Name | Payload | Purpose |
|---|---|---|
| `join_match` | `{ matchId: string }` | Fan subscribes to match updates |
| `leave_match` | `{ matchId: string }` | Fan unsubscribes from match updates |

#### Server ➔ Client Broadcast Events
| Event Name | Trigger | Payload Example |
|---|---|---|
| `ball_scored` | Fired when scorer records ball | ```json { "matchId": "uuid", "runs": 4, "totalRuns": 149, "wickets": 4, "overs": 15.5, "striker": "Aarav Patel", "bowler": "Rudra Sharma", "commentary": "FOUR! Smashed down the ground!", "winProbability": 76.5 } ``` |
| `wicket_fallback` | Fired on wicket delivery | ```json { "matchId": "uuid", "dismissedPlayer": "Vihaan Patel", "wicketType": "CAUGHT", "newBatsman": "Aditya Joshi" } ``` |
| `innings_switched` | Innings 1 ends | ```json { "matchId": "uuid", "target": 185, "battingTeam": "UVPCE Warriors" } ``` |
| `match_completed` | Match finishes | ```json { "matchId": "uuid", "winner": "UVPCE Titans", "margin": "15 runs" } ``` |

---

## 6. Express.js REST API Endpoint Contracts

### 6.1 Authentication (`/api/v1/auth`)
* `POST /api/v1/auth/register` — Self-registration for users
* `POST /api/v1/auth/login` — Login for Admins, Scorers, Fans
* `GET /api/v1/auth/me` — Fetch active session details

### 6.2 Team & Player Management (`/api/v1/teams`, `/api/v1/players`)
* `GET /api/v1/teams` — List all teams (cached in Redis)
* `POST /api/v1/teams` — Create team (Admin only)
* `PUT /api/v1/teams/:id` — Update team (Admin only)
* `DELETE /api/v1/teams/:id` — Delete team (Admin only)
* `POST /api/v1/teams/:id/players` — Add player to team roster (Admin only)

### 6.3 Match Management (`/api/v1/matches`)
* `POST /api/v1/matches` — Schedule a new match (Admin only)
* `GET /api/v1/matches` — Fetch matches (filtered by status: Upcoming/Live/Completed)
* `GET /api/v1/matches/:id` — Full details for specific match
* `POST /api/v1/matches/:id/activate` — Admin override to activate match to "Live"

### 6.4 Scoring Terminal (`/api/v1/scoring`)
* `POST /api/v1/scoring/:matchId/toss` — Set toss winner and decision
* `POST /api/v1/scoring/:matchId/ball` — Submit ball update (Scorer / Admin)
* `POST /api/v1/scoring/:matchId/undo` — Revert last ball entry
* `POST /api/v1/scoring/:matchId/swap-strike` — Manual swap of strikers
* `POST /api/v1/scoring/:matchId/end-innings` — Switch or declare innings complete

---

## 7. Migration Steps: SharedPreferences to Backend

To transition the existing Flutter frontend:

1. **Service Abstraction:** Refactor `StorageService` in Flutter into an `ApiService` interface.
2. **WebSockets Integration:** Add `socket_io_client: ^2.0.0` package in `pubspec.yaml`.
3. **Offline Sync (Hybrid Mode):** Allow local ball scoring in `StorageService` when offline, syncing batch `ball_records` to `POST /api/v1/scoring/:matchId/sync` once internet reconnects.
