# 📱 Vibe Study Timer — Flutter App

> **"Building software by describing what you want — and knowing when to look under the hood."**
> A dedicated mobile study timer built in **Flutter**, structured directly around the **60-Minute Vibe Coding Lab** (Slide 15) and lessons from Andrej Karpathy's lecture.

This is the Flutter rewrite of the original React + Node project. The `frontend/`
and `backend/` folders have been merged into a single self-contained Flutter app.

---

## 🌟 Highlights & Features

- **Native Mobile UI:** Portrait-locked, dark OLED theme, safe-area aware, with the
  bundled `Outfit`, `Plus Jakarta Sans` and `JetBrains Mono` typefaces.
- **60-Minute Vibe Coding Lab Timer (Slide 15):** Tracks the 4 structured phases of vibe-coding:
  - `0–10 min` **Phase 1: Plan** — Formulate prompt anatomy (Context, Goal, Constraints, Example, Done when).
  - `10–40 min` **Phase 2: Build** — Fast AI iterations, frequent Git commits, and feeding runtime errors back.
  - `40–50 min` **Phase 3: Audit** — Security checks against OWASP Top 10 flaws and slopsquatting.
  - `50–60 min` **Phase 4: Reflect** — Complete reflection and defend your code.
- **Study Presets:** 60m Vibe Lab, 25m Pomodoro, 50m Deep Work, 15m Sprint, and Custom (minutes + seconds).
- **Quick Prompt & Error Logger:** Slide-up bottom sheet for logging prompt iterations or pasting error tracebacks on the fly.
- **Class Rule Banner (Slide 14):** *"You may vibe code. You may not submit code you can't explain."*
- **Synthesized Chimes:** The original Web Audio API tones are now rendered as PCM WAV
  bytes in pure Dart and played through `audioplayers` — 528 Hz bowl chime, E5+A5 stage
  bell, C5→E5→G5→C6 completion fanfare, and a UI click.
- **Screen Wake Lock:** The display stays awake while a session is running.

---

## 🗂️ Project Structure

```
vibe-study-timer-mobile/
├── pubspec.yaml                  # Dependencies + bundled font declarations
├── assets/fonts/                 # Outfit, Plus Jakarta Sans, JetBrains Mono (TTF)
│
├── lib/
│   ├── main.dart                 # Entry point: opens the store, locks to portrait
│   ├── app.dart                  # MultiProvider wiring + MaterialApp
│   │
│   ├── theme/
│   │   └── app_theme.dart        # Colour/text/radius tokens ported from variables.css
│   │
│   ├── models/
│   │   ├── lab_phase.dart        # LAB_PHASES + PRESETS data
│   │   └── study_models.dart     # StudySession, PromptLog, StudyStats
│   │
│   ├── data/
│   │   └── local_store.dart      # On-device store (absorbs the old Node backend)
│   │
│   ├── services/
│   │   └── audio_service.dart    # WAV synthesis + playback
│   │
│   ├── controllers/
│   │   ├── timer_controller.dart # Countdown + phase tracking (ChangeNotifier)
│   │   └── stats_controller.dart # Aggregate metrics + prompt log
│   │
│   ├── screens/
│   │   └── home_screen.dart      # The single screen
│   │
│   └── widgets/
│       ├── timer_dial.dart       # CustomPainter progress ring + digits
│       ├── timer_controls.dart   # Start/Pause, Next phase, Reset
│       ├── preset_selector.dart  # Horizontal preset chips
│       ├── lab_roadmap.dart      # 4-stage 60m lab tracker
│       ├── class_rule_card.dart  # Slide 14 class rule banner
│       ├── session_stats_bar.dart# Focus minutes / sessions / prompts
│       ├── quick_prompt_sheet.dart   # Prompt + error log bottom sheet
│       ├── custom_timer_sheet.dart   # Minutes + seconds picker with validation
│       └── toast_banner.dart     # Transient status pill
│
├── android/                      # Android runner
├── ios/                          # iOS runner
└── web/                          # Web runner
```

---

## 🚀 Running the App

The backend is gone — sessions and prompts are stored **on the device**, so there is
no server to start.

```bash
flutter pub get

flutter run                 # attached device / emulator
flutter run -d chrome       # run in a browser
flutter run -d windows      # desktop
```

Build a release bundle:

```bash
flutter build apk --release   # Android
flutter build ios --release   # iOS
flutter build web --release   # Web  → build/web
```

Quality gates:

```bash
flutter analyze
flutter test
```

---

## 🔀 What Changed From The React + Node Version

| Original | Now |
|---|---|
| `backend/server.js` + `backend/db.js` (HTTP API + JSON file) | `lib/data/local_store.dart` — `shared_preferences`, same data shape and stats aggregation |
| `frontend/src/services/api.js` (`fetch` + `localStorage` fallback) | Merged into `LocalStore`; no network calls |
| `frontend/src/services/audio.js` (Web Audio API) | `lib/services/audio_service.dart` — WAV bytes synthesized in Dart |
| `frontend/src/hooks/useTimer.js` | `lib/controllers/timer_controller.dart` (`ChangeNotifier`) |
| `frontend/src/components/MobileFrame.jsx` | Dropped — native `Scaffold`/`AppBar`/`SafeArea` (the fake status bar and dynamic island were web-simulator artifacts) |
| `frontend/src/styles/*.css` | `lib/theme/app_theme.dart` design tokens |
| Google Fonts via CDN | TTFs bundled in `assets/fonts/` so the app works fully offline |

---

## 📄 License

MIT