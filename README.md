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
├── web/                          # Web runner
├── tool/
│   └── verify_firebase_auth.dart # Checks the console setup for accounts
└── test/
```

---

## 🚀 Running the App

The backend is gone — sessions and prompts are stored **on the device** by
default, so there is no server to start. (Cloud sync is optional; see
[Accounts & Cloud Sync](#-accounts--cloud-sync-optional) below.)

```bash
flutter pub get

flutter run                 # attached device / emulator
flutter run -d chrome       # run in a browser
flutter run -d windows      # desktop — timer only, see "Accounts" below
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

## ☁️ Accounts & Cloud Sync (optional)

Signing in is **optional**. Out of the box the app runs in **guest mode**: the
timer and prompt log work exactly as before, stored on the device only.

To enable accounts and two-way sync you need a Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

That overwrites `lib/firebase_options.dart` and writes
`android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist`.

`flutterfire configure` alone is **not enough**. Registering apps does not set up
sign-in, and no amount of reconfiguring will enable a provider that was never
turned on. Then:

1. **Firebase console → Authentication → Get started.** The very first visit
   asks you to initialise Identity Platform — accept it. Skipping this leaves
   the project with no auth configuration at all, and sign-in fails with
   `configuration not found` no matter what the app does.
2. **Authentication → Sign-in method** → enable **Email/Password**.
3. **Firebase console → Firestore Database** → create the database.
4. **Deploy the security rules** — the default rules are wide open:

   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Web only:** Authentication → Settings → **Authorized domains** must
   contain `localhost`, or `flutter run -d chrome` is refused.
6. **iOS only:** open `ios/Runner.xcworkspace` in Xcode and drag
   `GoogleService-Info.plist` into the Runner target. This step is manual.

Check all of the above at once, without reading app error messages and
guessing:

```bash
dart run tool/verify_firebase_auth.dart
```

It is read-only — it signs in with an undeliverable `.invalid` address, so it
creates no account and sends no email.

### Platform support for accounts

| Target | Accounts | Why |
|---|---|---|
| Android, iOS, Web | ✅ | Firebase ships SDKs for all three |
| Windows / macOS / Linux desktop | ❌ | Firebase ships no desktop SDK, and `flutterfire configure` has no desktop target to generate |

On desktop the timer and prompt log work normally; only sign-in is unavailable,
and the account screen says so instead of blaming the config.

Without the Firebase config the app logs `Firebase disabled, running in guest
mode` and starts normally — a fresh clone is always runnable.

### If accounts don't work

The app distinguishes the ways it can fail, instead of failing after you type
your password. `lib/services/firebase_bootstrap.dart` classifies startup into:

| State | Meaning |
|---|---|
| `FirebaseReady` | Accounts and sync are live. |
| `FirebaseNotConfigured` | `flutterfire configure` has not been run yet. |
| `FirebaseInitFailed` | A project is linked but `initializeApp` rejected it — stale or missing `google-services.json` / `GoogleService-Info.plist`. |
| `FirebaseUnsupportedPlatform` | Running on Windows/macOS/Linux desktop, where Firebase has no SDK. |

The account screen shows a banner naming the fix the moment it opens, and the
submit button is disabled so it cannot fail after you have entered credentials.
Look for this line in the console at startup:

```
Firebase disabled, running in guest mode: <reason>
```

If you get `FirebaseInitFailed` after configuring, re-run `flutterfire
configure` and do a `flutter clean` — a stale platform file is the usual cause.

### What sync does

| Event | Guest | Signed in |
|---|---|---|
| Session / prompt logged | device only | device + Firestore, queued while offline |
| App closed | persists | persists |
| App uninstalled | **lost** | restored on next sign-in |
| New phone | **lost** | restored on next sign-in |
| Sign out | — | device copy is wiped, cloud copy kept |

Guest data accumulated before the first sign-in is **migrated once** to whichever
account signs in first, then claimed by that device permanently — a second
account on the same device never inherits it.

### Layout

```
users/{uid}/sessions/{sessionId}
users/{uid}/prompts/{promptId}
```

Sessions and prompts are **write-once** (there is no edit or delete in the
UI), so syncing is a union by id — no `updatedAt`, no conflict resolution. See
`lib/services/sync_service.dart`.

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