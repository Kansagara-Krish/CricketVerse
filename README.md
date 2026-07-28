<p align="center">
  <img src="mobile_app/assets/images/logo.jpg" alt="CricketVerse AI Logo" width="200" height="200" />
</p>

# 🏏 CricketVerse AI
> **An Intelligent Mobile Application for Live Cricket Scoring, AI Commentary, Match Prediction, and Real-Time Analytics.**

CricketVerse AI is a premium, high-fidelity Flutter prototype showcasing a comprehensive cricket tournament management and live-scoring ecosystem. It features a modern dark-mode aesthetic with glassmorphism elements, custom animations, and an intuitive user experience.

---

## 📸 App Screenshots

Here are the application walkthrough screens:

### 🛡️ Admin Screens

### Admin Panels & Dashboard

| Admin Login | Admin Dashboard | Tournament List |
| :---: | :---: | :---: |
| ![Admin Login](mobile_app/ss/admin/login_screen.jpeg) | ![Admin Dashboard](mobile_app/ss/admin/admin_dashboard.jpeg) | ![Tournament List](mobile_app/ss/admin/tournament_list.jpeg) |
| *Admin / Multi-Role Authentication* | *System Overview & Analytics Home* | *Active Tournaments Feed* |

| Team Management | Player Management | Player Details |
| :---: | :---: | :---: |
| ![Team Management](mobile_app/ss/admin/team_management.jpeg) | ![Player Management](mobile_app/ss/admin/player_management.jpeg) | ![Player Details](mobile_app/ss/admin/player_details.jpeg) |
| *Franchise Roster & Squad Control* | *Player Directory & Category Filters* | *Individual Player Career Statistics* |

| AI Settings | Notifications | General Statistics |
| :---: | :---: | :---: |
| ![AI Settings](mobile_app/ss/admin/ai_settings.jpeg) | ![Notifications](mobile_app/ss/admin/notifications.jpeg) | ![General Statistics](mobile_app/ss/admin/statistics.jpeg) |
| *Voice Commentary & Win Predictor Config* | *Real-Time Live Match Notifications* | *Tournament Overviews & Milestones* |

### 📝 Manager Screens

### Live Scoring & Control Panels

| Live Scoring Terminal | Record Wicket Dialog |
| :---: | :---: |
| ![Live Scoring Terminal](mobile_app/ss/manager/live_scoring.jpeg) | ![Record Wicket Dialog](mobile_app/ss/manager/record_wicket.jpeg) |
| *Live scoring terminal for official managers* | *Wicket recording overlay dialog* |

### 👤 User / Fan Screens

### Live Match View & Analytics

| Fan Dashboard | Fan Live Match Details | Match Summary Report |
| :---: | :---: | :---: |
| ![Fan Dashboard](mobile_app/ss/user/fan_dashboard.jpeg) | ![Fan Live Match Details](mobile_app/ss/user/fan_match_details.jpeg) | ![Match Summary Report](mobile_app/ss/user/match_summary.jpeg) |
| *Fan live match scoring hub* | *Live scoreboard & player stats* | *Innings summary & download report* |

| Match Predictions | Scenario Simulator | AI Commentary |
| :---: | :---: | :---: |
| ![Match Predictions](mobile_app/ss/user/match_predictions.jpeg) | ![Scenario Simulator](mobile_app/ss/user/prediction_simulator.jpeg) | ![AI Commentary](mobile_app/ss/user/ai_commentary.jpeg) |
| *AI analytics & momentum tracker* | *What-If prediction scenario sliders* | *Live AI generated audio commentary* |

---

## 🚀 Key Features

- **Live Match Center**: Real-time scoring, ball-by-ball updates, and dynamic scoreboards.
- **AI-Powered Insights**: Simulated AI voice commentary feed and live win probability predictions using advanced factor analysis.
- **Tournament Management**: Complete administration of tournaments, matches, teams, and players.
- **Comprehensive Statistics**: High-fidelity charts and graphs for player/team performance tracking.
- **Role-Based Access**: Dedicated dashboards and workflows for Admins, Managers, and End-Users.
- **Premium UI/UX**: Dark mode by default, Hero animations, smooth page transitions, shimmer loading effects, and modern typography.

---

## 🛠 Technology Stack

This prototype is built entirely as a **Frontend Application** using dummy data, demonstrating architectural best practices and UI excellence.

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider (Centralized `StorageService` for dummy data)
- **Navigation**: Custom Named Routes (`onGenerateRoute`) with slide/fade page transitions
- **Styling**: Vanilla Flutter + Material 3 + Custom Theme (`AppTheme`)
- **Typography**: Google Fonts (Outfit)
- **Data Persistence**: In-memory dummy data (No Firebase, No external APIs)
- **Animations**: `flutter_animate`, Lottie, Custom Tween animations

---

## 👥 User Roles & Page Architecture

The application is structured around **3 distinct user roles**, totaling over **30 meticulously designed screens**.

### 1. 🛡️ Admin (19 Dedicated Pages)
*Credentials: `admin@cricketverse.ai` / `admin123`*
The Admin has full control over the ecosystem.
*   **Dashboards**: Admin Home Dashboard
*   **Match Management**: Match List, Match Details, Schedule Match
*   **Team & Player Management**: Team List, Team Details, Player List, Player Details
*   **Tournament Management**: Tournament List, Create Tournament
*   **Live Operations**: Live Scoring Terminal (Admin Override)
*   **AI & Analytics**: AI Commentary Feed, Prediction Engine, Analytics & Statistics
*   **System**: Notifications, Admin Profile, AI Settings, Help & Support, About Project

### 2. 📝 Match Manager (Official/Moderator) (2 Dedicated Pages)
*Credentials: `manager@cricketverse.ai` / `manager123`*
The Match Manager is responsible for updating live match events.
*   **Dashboards**: Manager Dashboard (Active Matches)
*   **Live Operations**: Live Ball-by-Ball Entry Screen

### 3. 👤 User (Cricket Fan) (2 Dedicated Pages)
*Credentials: `user@gmail.com` / `user123`*
The User consumes the live data, statistics, and predictions.
*   **Dashboards**: Fan Dashboard (Live Scores, News, Standing)
*   **Export**: Match Summary Download / Export Screen

### 🌐 Shared & Core Pages (7 Pages)
Common screens accessible during the user journey.
*   **App Entry**: Splash Screen, Interactive Onboarding, Authentication (Login/Signup)
*   **Shared Details**: Public Match Details, Public Team Details, Public Player Details, News Details

---

## 🎨 Design Philosophy

CricketVerse AI prioritizes **Visual Excellence**. 
- **Zero Dead Buttons**: Every clickable element leads to a meaningful interaction or screen.
- **Harmonious Palette**: Deep space backgrounds (`#0F172A`) contrasted with vibrant accents (Emerald Green, Sky Blue, Amber).
- **Micro-interactions**: Pulse animations on live scores, haptic feedback on scoring events.
- **Graceful Loading**: Shimmer effects replace traditional loading spinners for a premium feel.

---

## 🏃‍♂️ How to Run Locally

1. Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. Clone the repository and navigate to the project directory.
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application (Windows, Web, or Mobile Emulator):
   ```bash
   flutter run
   ```

*(Note: Ensure your device/emulator is running for a smooth 60fps experience.)*

---
*Built as a B.Tech Major Project Prototype.*
