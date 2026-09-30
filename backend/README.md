# 🏏 CricketVerse AI — Production Backend Documentation

CricketVerse AI is a high-performance, real-time Node.js & TypeScript backend powered by **MongoDB Atlas** and **Socket.IO**. It drives live ball-by-ball scoring with official cricket rules, role-based dashboards (Admin, Manager/Scorer, Fan/User), automated AI commentary, ML-powered win probability prediction, audio TTS commentary synthesis, tournament management, and real-time event broadcasting.

---

## 🏗️ 1. Architecture Overview

- **Runtime & Language**: Node.js, TypeScript, Express.js
- **Database**: MongoDB Atlas (`mongoose` ODM) with auto-indexing, strict schemas, and graceful reconnection handling
- **Real-Time Layer**: Socket.IO for live match rooms (`match:<id>`) and global broadcast notifications (`global_notification`)
- **Machine Learning Layer**: Python ML Win Predictor (`ml_model/predict.py` using `joblib` & `scikit-learn`)
- **Authentication**: Stateless JWT Tokens (`jsonwebtoken`), bcrypt password hashing, and role-based middleware (`requireRole`)
- **AI Voice Commentary**: Server-side TTS synthesis (`ElevenLabs`) with local caching to avoid duplicate credit consumption

---

## 🔐 2. Environment Configuration (`.env`)

Create a `.env` file in `/backend` using the template below:

```env
# MongoDB Atlas Connection URI
MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.cxx9cqz.mongodb.net/cricketverse?retryWrites=true&w=majority

# JWT Authentication Secret
JWT_SECRET=cricketverse_super_secret_key_123!

# Server Port
PORT=3000

# Optional Redis Cache / Scaling
REDIS_URL=

# Optional ElevenLabs TTS Voice Key
ELEVENLABS_API_KEY=
```

---

## 🚀 3. Quick Start & Commands

```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Seed initial database records (Admin, Demo Tournament, Teams, Live Match)
npm run seed

# 4. Run automated end-to-end integration tests
npm test

# 5. Start development server with hot-reload
npm run dev

# 6. Build production JavaScript bundle
npm run build

# 7. Start production server
npm start
```

---

## 👥 4. User Roles & Default Credentials

| Role | Email / Identifier | Password | Access Rights |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@gmail.com` | `admin123` | Full administrative control: Tournaments, Teams, Players, Match Scheduling, System Stats |
| **Manager / Scorer** | Match-specific scorer username (e.g. `scorer_wankhede`) | `scorer123` | Official Scorer Portal: Toss setup, Ball-by-ball scoring, Strike swap, Bowler switch, Wickets, Undo, Innings conclusion |
| **Fan / User** | `user@gmail.com` (or registered email) | `user123` | Live match viewing, Live scoreboards, AI commentary audio, Scenario simulator & Win predictions, Profile management |

---

## 📡 5. Complete REST API Specification

Base URL: `http://localhost:3000/api/v1`

### 🔑 Authentication (`/api/v1/auth`)
| Method | Endpoint | Auth | Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/login` | Public | All | Authenticate Admin, Scorer, or User |
| `POST` | `/auth/register` | Public | User | Register a new user account |
| `GET` | `/auth/me` | Bearer JWT | All | Get current authenticated session & profile |
| `PUT` | `/auth/profile` | Bearer JWT | User/Admin | Update display name, email, and preferences |
| `POST` | `/auth/password-otp` | Bearer JWT | User/Admin | Request a 4-digit OTP for secure password update |
| `PUT` | `/auth/password` | Bearer JWT | User/Admin | Verify OTP and update password |
| `POST` | `/auth/broadcast` | Public | All | Broadcast in-app system notification |
| `POST` | `/auth/logout` | Bearer JWT | All | Terminate session and broadcast sign-out event |

### 🏆 Tournaments (`/api/v1/tournaments`)
| Method | Endpoint | Auth | Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/tournaments` | Public | All | Get list of all tournaments |
| `GET` | `/tournaments/:id` | Public | All | Get details of a specific tournament |
| `POST` | `/tournaments` | Bearer JWT | Admin | Create a new tournament |
| `PUT` | `/tournaments/:id` | Bearer JWT | Admin | Edit tournament details & status |
| `DELETE` | `/tournaments/:id` | Bearer JWT | Admin | Delete a tournament |

### 🛡️ Teams & Players (`/api/v1/teams`)
| Method | Endpoint | Auth | Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/teams` | Public | All | Get all registered teams and squads |
| `GET` | `/teams/:id` | Public | All | Get team roster and stats |
| `POST` | `/teams` | Bearer JWT | Admin | Create a new team with player roster |
| `PUT` | `/teams/:id` | Bearer JWT | Admin | Update team name, code, or branding |
| `DELETE` | `/teams/:id` | Bearer JWT | Admin | Delete a team |
| `POST` | `/teams/:teamId/players` | Bearer JWT | Admin | Add a new player to a team |
| `PUT` | `/teams/players/:id` | Bearer JWT | Admin | Update player statistics/roles |
| `DELETE` | `/teams/players/:playerId`| Bearer JWT | Admin | Remove a player from team roster |

### 🏏 Matches & Scheduling (`/api/v1/matches`)
| Method | Endpoint | Auth | Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/matches` | Public | All | Get all matches (Upcoming, Live, Completed) |
| `GET` | `/matches/:id` | Public | All | Get match details with live scoreboard |
| `GET` | `/matches/:id/prediction`| Public | All | Get dynamic ML-driven win probability & factors |
| `POST` | `/matches` | Bearer JWT | Admin | Schedule a match and assign scorer credentials |
| `PUT` | `/matches/:id` | Bearer JWT | Admin | Update match schedule details |
| `DELETE` | `/matches/:id` | Bearer JWT | Admin | Delete a scheduled match |
| `POST` | `/matches/:id/activate` | Bearer JWT | Admin | Activate match to LIVE status |
| `POST` | `/matches/:id/reset` | Bearer JWT | Admin | Reset match scores and ball history to zero |

### ⚡ Live Scoring Terminal (`/api/v1/scoring`)
| Method | Endpoint | Auth | Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/scoring/:matchId/toss` | Bearer JWT | Scorer/Admin | Record toss winner, decision, and opening batsmen/bowler |
| `POST` | `/scoring/:matchId/ball` | Bearer JWT | Scorer/Admin | Record ball delivery (runs, extras, wickets, commentary) |
| `POST` | `/scoring/:matchId/undo` | Bearer JWT | Scorer/Admin | Revert previous ball, batsman/bowler stats, and over count |
| `POST` | `/scoring/:matchId/swap-strike` | Bearer JWT | Scorer/Admin | Swap striker and non-striker positions |
| `POST` | `/scoring/:matchId/switch-bowler` | Bearer JWT | Scorer/Admin | Change current active bowler |
| `POST` | `/scoring/:matchId/end-innings` | Bearer JWT | Scorer/Admin | Conclude first innings or mark match as completed |
| `POST` | `/scoring/:matchId/end-match` | Bearer JWT | Scorer/Admin | Force complete match |

### 🔔 Notifications & AI (`/api/v1/notifications` & `/api/v1/ai`)
| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/notifications` | Bearer JWT | Fetch user and global notifications |
| `POST` | `/notifications` | Bearer JWT (Admin) | Broadcast custom notification |
| `PUT` | `/notifications/:id/read` | Bearer JWT | Mark notification as read |
| `POST` | `/ai/voice` | Public | Generate/stream ElevenLabs TTS voice commentary audio |
| `POST` | `/ai/commentary` | Public | Generate custom cricket event commentary |
| `GET` | `/analytics/stats` | Public | System analytics and tournament aggregates |

---

## ⚡ 6. Real-Time Socket.IO Protocol

Clients connect to the Socket.IO server and can subscribe to live match rooms:

```typescript
// Connect socket
const socket = io('http://localhost:3000');

// Join live match room
socket.emit('join_match', { matchId: 'match_123' });

// Listen for ball-by-ball scoreboard and commentary updates
socket.on('match_update', (matchData) => {
  console.log('Real-time match update received:', matchData);
});

// Listen for global system and tournament notifications
socket.on('global_notification', (notif) => {
  console.log('Global notification:', notif.title, notif.message);
});

// Leave match room
socket.emit('leave_match', { matchId: 'match_123' });
```
