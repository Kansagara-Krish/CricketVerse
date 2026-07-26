# 🛠️ Tech Stack Reference
## CricketVerse AI

**Version:** 1.0.0  
**Platform:** Android (primary), Web & Windows (secondary)  

---

## Overview

CricketVerse AI is a **100% frontend, offline-first** Flutter application. It has no backend server, no cloud database, and makes no network calls at runtime. All dependencies are Dart/Flutter packages that run entirely on-device.

---

## Core Framework

| Technology | Version | Role |
|---|---|---|
| **Flutter** | 3.x (SDK >=3.0.0 <4.0.0) | Cross-platform UI framework |
| **Dart** | 3.x | Programming language |
| **Material Design 3** | Built-in | Design system |

---

## Dependencies

### State Management

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | ChangeNotifier-based reactive state management. Single `StorageService` provider mounted at app root handles all app state. |

### Data Persistence

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | ^2.2.2 | On-device key-value storage (JSON blobs). Stores teams, matches, and users across sessions. |

### UI & Visualization

| Package | Version | Purpose |
|---|---|---|
| `fl_chart` | ^0.66.0 | Bar charts, line charts, and pie charts for statistics and prediction screens. |
| `shimmer` | ^3.0.0 | Shimmer skeleton loading effects replacing traditional spinners for premium UX. |
| `google_fonts` | ^6.1.0 | Plus Jakarta Sans typeface loaded via Google Fonts CDN (cached offline after first load). |
| `intl` | ^0.19.0 | Date/time formatting and internationalization utilities. |
| `cupertino_icons` | ^1.0.6 | iOS-style icon set for cross-platform icon coverage. |

### Media

| Package | Version | Purpose |
|---|---|---|
| `video_player` | ^2.8.6 | Video playback support (included for future highlight clips feature). |
| `flutter_tts` | ^4.2.5 | Text-to-Speech engine for AI voice commentary feature. Converts generated commentary strings to audio. |

### PDF & Printing

| Package | Version | Purpose |
|---|---|---|
| `pdf` | ^3.12.0 | Pure Dart PDF generation library. Used in `PdfReportService` to build multi-page A4 match summary documents. |
| `printing` | ^5.15.0 | Native print/share dialog integration. Bridges the generated PDF bytes to the OS share sheet. |
| `path_provider` | ^2.1.5 | File system path resolution for saving PDF files to device storage. |

---

## Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | ^3.0.0 | Dart/Flutter lint rules for code quality enforcement |
| `flutter_test` | SDK | Built-in Flutter testing framework |
| `flutter_launcher_icons` | ^0.14.4 | Generates Android/iOS launcher icons from source image (`assets/images/logo.jpg`) |

---

## Launcher Icon Configuration

```yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/images/logo.jpg"
  adaptive_icon_background: "#010C22"       # Deep navy background
  adaptive_icon_foreground: "assets/images/logo_foreground.png"
```

---

## Assets

```
assets/
└── images/
    ├── logo.jpg                # App launcher icon source
    └── logo_foreground.png     # Adaptive icon foreground layer
```

---

## Typography

| Font | Weight | Usage |
|---|---|---|
| Plus Jakarta Sans | 800 (ExtraBold) | Large headings, hero text |
| Plus Jakarta Sans | 700 (Bold) | Section headings, buttons |
| Plus Jakarta Sans | 600 (SemiBold) | Card titles, labels |
| Plus Jakarta Sans | 400 (Regular) | Body text, descriptions |

Loaded via `google_fonts: ^6.1.0`. Font is cached locally after first download.

---

## Color Palette

| Name | Hex | Usage |
|---|---|---|
| Primary Emerald | `#028A6B` | Primary buttons, active indicators, links |
| Mint Green | `#10B981` | Live status badges, success states |
| Gold | `#F59E0B` | Match highlights, star ratings, gold accents |
| Amber | `#D97706` | Secondary accents, all-rounder badge |
| Crimson | `#E11D48` | Wicket indicators, error states, bowler badge |
| Rust Orange | `#EA580C` | Warning states, orange accents |
| Deep Navy Text | `#0F172A` | Primary text |
| Slate Grey | `#475569` | Secondary text |
| Muted Grey | `#94A3B8` | Placeholder text, disabled states |
| Background (Sage) | `#F7FAF8` | Scaffold background |
| Surface White | `#FFFFFF` | Cards, input fields |

---

## Navigation & Routing

| Technology | Details |
|---|---|
| Named Routes | `onGenerateRoute` with switch-case router in `AppRoutes.generateRoute()` |
| Slide Transition | 320ms, `easeInOutCubic`, right-to-left for push screens |
| Fade Transition | 400ms for role dashboards (Admin, Scorer, User) |
| Route Arguments | Passed via `RouteSettings.arguments` (typed casts per route) |

---

## Architecture Pattern

| Concern | Solution |
|---|---|
| State Management | Provider (ChangeNotifier) |
| Data Persistence | SharedPreferences (JSON) |
| Navigation | Named Routes + AppRoutes class |
| Business Logic | StorageService (single class) |
| UI Theming | AppTheme (centralized) |
| Constants | AppConstants (static pools) |
| PDF Reports | PdfReportService (static methods) |

---

## Build & Run

### Prerequisites
- Flutter SDK >= 3.0.0
- Android SDK (API 21+ recommended)
- Java JDK 11+

### Commands
```bash
# Install dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release

# Build for Web
flutter build web
```

### Android Manifest Permissions
The app requires no special permissions at runtime.  
`flutter_tts` may request audio permissions on some devices for voice commentary.

---

## Tooling

| Tool | Purpose |
|---|---|
| Android Studio / VS Code | Primary IDEs |
| `analysis_options.yaml` | Flutter lint configuration |
| `pubspec.lock` | Dependency lockfile (pinned versions) |
| `.metadata` | Flutter SDK version metadata |
| `.flutter-plugins-dependencies` | Plugin dependency graph |

---

## Why This Stack?

| Choice | Reason |
|---|---|
| Flutter over React Native | Better animation performance, single codebase for Android + Web |
| Provider over Riverpod/Bloc | Simpler for a single-service prototype; less boilerplate |
| SharedPreferences over SQLite | No complex relational queries needed; JSON blobs are sufficient |
| pdf + printing over flutter_pdf_viewer | Full generation control; no external dependencies for viewing |
| fl_chart over syncfusion | Open-source, no licensing restrictions for academic project |
| Plus Jakarta Sans | Clean, modern, highly legible — ideal for data-dense cricket UIs |
