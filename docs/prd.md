# 📋 Product Requirements Document (PRD)
## CricketVerse AI — Intelligent Mobile Cricket Management System

**Version:** 1.0.0  
**Status:** Development Complete (Prototype)  
**Platform:** Android (Flutter)  
**Type:** B.Tech Major Project — Offline-First Flutter Application  
**Tagline:** *Intelligence Meets Action*

---

## 1. Executive Summary

CricketVerse AI is a premium, offline-first Flutter mobile application designed to digitize and intelligently automate cricket tournament management, live scoring, and fan engagement. The system is purpose-built for college/club-level tournaments (seeded with UVPCE Cricket League data) and is architected to scale to any cricket organization.

The application eliminates the need for paper-based scorecards, fragmented WhatsApp scorecards, and manual analytics — replacing them with a unified, role-aware digital platform with AI-generated commentary, live win probability predictions, and exportable PDF match reports.

---

## 2. Problem Statement

College and club-level cricket tournaments face significant operational challenges:

| Problem | Impact |
|---|---|
| Manual paper scorecards | Error-prone, slow, no real-time fan access |
| No centralized team/player database | Repetitive data entry per match |
| Zero live analytics | No tactical insights during matches |
| Poor fan engagement | Fans have no live visibility into ongoing matches |
| No post-match records | Historical data lost after each game |

---

## 3. Goals & Success Metrics

### Primary Goals
- Provide a **real-time digital scoring terminal** for match scorers
- Give **admins** a full-featured tournament management dashboard
- Give **fans** a clean, live match-following experience
- Generate **AI commentary** automatically from ball events
- Produce **exportable PDF reports** for official match records

### Success Metrics
| Metric | Target |
|---|---|
| Screen coverage for admin workflows | 100% (19 screens) |
| Ball-by-ball latency (local) | < 100ms |
| PDF generation time | < 3 seconds |
| Undo support for scorer | Last N balls |
| Platforms supported | Android (primary), Web/Windows (secondary) |

---

## 4. User Roles & Personas

### 4.1 Admin 🛡️
**Who:** Tournament organizer / system owner  
**Credentials:** `admin@cricketverse.ai` / `admin123`  
**Needs:**
- Full CRUD over teams, players, matches, tournaments
- Ability to activate and monitor live matches
- Access to analytics, statistics, and prediction engine
- Broadcast notifications (simulated)
- AI commentary review and settings

### 4.2 Match Scorer 📝
**Who:** Official scorer assigned per match  
**Credentials:** Unique per match (scorer1 / 123, scorer2 / 456)  
**Needs:**
- Simple, fast ball-by-ball entry interface
- Support for all delivery types: run, extras (Wide, No Ball, Leg Bye), wicket
- Wicket type selection (Bowled, Caught, LBW, Run Out, Stumped, Retired)
- Over end management, bowler change, striker swap
- Undo last ball capability
- Auto-generated AI commentary per delivery

### 4.3 Cricket Fan (User) 👤
**Who:** End-user following the tournament  
**Credentials:** user@gmail.com / user123 (or self-registered)  
**Needs:**
- Live scorecard with ball-by-ball updates
- Match schedule view (Upcoming / Live / Completed)
- Win probability prediction with visual gauge
- Player and team statistics
- Downloadable PDF match summary

### 4.4 Guest 🌐
**Who:** Unauthenticated visitor  
**Access:** Read-only match data (no scoring or admin features)

---

## 5. Functional Requirements

### 5.1 Authentication Module
| ID | Requirement | Priority |
|---|---|---|
| AUTH-01 | Admin login with hardcoded credentials | P0 |
| AUTH-02 | Scorer login matched against per-match credentials | P0 |
| AUTH-03 | User login from registered accounts (SharedPreferences) | P0 |
| AUTH-04 | User self-registration with email + password | P1 |
| AUTH-05 | Guest login (read-only access) | P1 |
| AUTH-06 | Role-based routing post-login (Admin/Scorer/User/Guest) | P0 |
| AUTH-07 | Logout with confirmation dialog | P1 |

### 5.2 Tournament Management
| ID | Requirement | Priority |
|---|---|---|
| TOURN-01 | Create tournament with name, format, dates, participating teams | P0 |
| TOURN-02 | View list of all tournaments | P0 |
| TOURN-03 | View tournament details (teams, schedule) | P0 |
| TOURN-04 | Delete tournament | P1 |

### 5.3 Team & Player Management
| ID | Requirement | Priority |
|---|---|---|
| TEAM-01 | Add new team with name, short name, color | P0 |
| TEAM-02 | Edit existing team details | P0 |
| TEAM-03 | Delete team | P0 |
| TEAM-04 | Add player to team with role & nationality | P0 |
| TEAM-05 | Edit player stats and details | P0 |
| TEAM-06 | Remove player from team | P0 |
| TEAM-07 | View full team roster with color-coded roles | P0 |
| TEAM-08 | View individual player career stats | P0 |

### 5.4 Match Scheduling
| ID | Requirement | Priority |
|---|---|---|
| MATCH-01 | Schedule a match: Team A, Team B, venue, date, time, match type | P0 |
| MATCH-02 | Assign scorer credentials per match | P0 |
| MATCH-03 | Match defaults to "Upcoming" status on creation | P0 |
| MATCH-04 | Admin can manually activate any match to "Live" | P0 |

### 5.5 Live Scoring
| ID | Requirement | Priority |
|---|---|---|
| SCORE-01 | Toss input (winner + decision) before innings start | P0 |
| SCORE-02 | Record runs (0, 1, 2, 3, 4, 6) per delivery | P0 |
| SCORE-03 | Record extra type: Wide, No Ball, Leg Bye, None | P0 |
| SCORE-04 | Record wicket with type: Bowled, Caught, LBW, Run Out, Stumped, Retired | P0 |
| SCORE-05 | Automatic strike rotation on odd runs | P0 |
| SCORE-06 | Manual striker swap | P0 |
| SCORE-07 | Over end automation (strike rotates, next bowler auto-selected) | P0 |
| SCORE-08 | Bowler change mid-over support | P1 |
| SCORE-09 | Undo last ball (reverses score + player stats) | P0 |
| SCORE-10 | End innings / declare innings complete | P0 |
| SCORE-11 | Auto target calculation at innings switch | P0 |
| SCORE-12 | End match (force complete) | P0 |
| SCORE-13 | Wide/No Ball does not count as a legal delivery | P0 |
| SCORE-14 | Real-time AI commentary generated per ball | P0 |

### 5.6 AI Commentary
| ID | Requirement | Priority |
|---|---|---|
| AI-01 | Context-aware commentary templates for: 6, 4, 1-3, 0, Wide, No Ball, Wicket | P0 |
| AI-02 | Commentary includes player names (batsman + bowler) | P0 |
| AI-03 | Commentary displayed in scoring terminal ball-by-ball | P0 |
| AI-04 | Admin AI Commentary screen for reviewing generated commentary | P1 |
| AI-05 | TTS (Text-to-Speech) voice commentary toggle | P1 |

### 5.7 Win Probability Prediction
| ID | Requirement | Priority |
|---|---|---|
| PRED-01 | Live win probability for 1st innings: CRR vs par rate + wickets | P0 |
| PRED-02 | Live win probability for 2nd innings: RRR vs CRR, balls remaining, wickets | P0 |
| PRED-03 | Visual probability gauge/progress bar for fans | P0 |
| PRED-04 | Display prediction factors: CRR, RRR, Wickets in Hand, Powerplay | P1 |

### 5.8 Statistics & Analytics
| ID | Requirement | Priority |
|---|---|---|
| STAT-01 | Admin statistics screen with charts | P0 |
| STAT-02 | Player batting stats: runs, balls faced, SR, matches | P0 |
| STAT-03 | Player bowling stats: wickets, overs, economy, matches | P0 |
| STAT-04 | Team-level aggregate stats | P1 |
| STAT-05 | fl_chart bar/line charts for visual representation | P1 |

### 5.9 PDF Match Report
| ID | Requirement | Priority |
|---|---|---|
| PDF-01 | Generate multi-page A4 PDF with match summary | P0 |
| PDF-02 | PDF includes: match title, scores, overs, result, team rosters | P0 |
| PDF-03 | Native print/share dialog via printing package | P0 |
| PDF-04 | Fallback in-app viewer if native print channel unavailable | P1 |

### 5.10 Notifications
| ID | Requirement | Priority |
|---|---|---|
| NOTIF-01 | Notification list screen with type-coded notifications | P1 |
| NOTIF-02 | Notification types: match, wicket, prediction, milestone, schedule, alert, result, team, tournament | P1 |

---

## 6. Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | UI renders at 60fps on mid-range Android devices |
| **Offline** | 100% offline — all data in SharedPreferences, no network calls |
| **Persistence** | All teams, matches, users survive app restarts |
| **Security** | Role isolation via in-memory session; admin credentials hardcoded |
| **UX** | Shimmer loading, page transitions (slide/fade), entrance animations |
| **Orientation** | Portrait-only (locked via SystemChrome) |
| **Typography** | Plus Jakarta Sans via Google Fonts |
| **Accessibility** | Minimum 44x44 tap targets on all interactive elements |

---

## 7. Out of Scope (v1.0)

- Real backend / Firebase / Supabase integration
- Push notifications (FCM)
- Real-time websocket multiplayer scoring
- Payment / subscription management
- Test match format (only T20 and ODI in scope)
- iOS build (Android primary)

---

## 8. Default Seed Data

The app ships with pre-seeded data for the **UVPCE Cricket League 2026**:

| Entity | Count | Details |
|---|---|---|
| Teams | 8 | UVPCE A, B, C, Titans, Warriors, Challengers, Strikers, Legends |
| Players per team | 11 | Auto-generated Indian names with realistic stats |
| Matches | 2 | 1 Live (Titans vs Warriors), 1 Completed (A vs B) |
| Users | 2 default | user@gmail.com, alex@gmail.com |

---

## 9. Release Milestones

| Milestone | Status |
|---|---|
| Core data models (Player, Team, Match, BallRecord) | Complete |
| Authentication (all 4 roles) | Complete |
| Admin dashboard + all admin screens (19) | Complete |
| Scorer dashboard + live scoring terminal | Complete |
| User/fan dashboard (5 screens) | Complete |
| AI Commentary engine | Complete |
| Win probability engine | Complete |
| PDF report generation | Complete |
| Undo last ball | Complete |
| Default seed data (UVPCE 2026) | Complete |
