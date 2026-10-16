# Vibe Study Timer — Project Structure & Code Guide

A Flutter focus timer built around the **60-Minute Vibe Coding Lab**. This document
explains every folder, every file, how each piece works, and how the pieces depend
on one another.

---

## Table of Contents

1. [What the app does](#1-what-the-app-does)
2. [Top-level folder map](#2-top-level-folder-map)
3. [Layering and dependency rules](#3-layering-and-dependency-rules)
4. [Boot sequence: how the object graph is built](#4-boot-sequence-how-the-object-graph-is-built)
5. [`lib/main.dart` — entry point](#5-libmaindart--entry-point)
6. [`lib/app.dart` — dependency injection](#6-libappdart--dependency-injection)
7. [`lib/models/` — pure data](#7-libmodels--pure-data)
8. [`lib/data/` — on-device persistence](#8-libdata--on-device-persistence)
9. [`lib/services/` — infrastructure](#9-libservices--infrastructure)
10. [`lib/controllers/` — state](#10-libcontrollers--state)
11. [`lib/screens/` — pages](#11-libscreens--pages)
12. [`lib/widgets/` — reusable UI](#12-libwidgets--reusable-ui)
13. [`lib/theme/` — design tokens](#13-libtheme--design-tokens)
14. [`test/` — the test suite](#14-test--the-test-suite)
15. [`tool/` — developer scripts](#15-tool--developer-scripts)
16. [`assets/`, `android/`, `ios/`, `web/`](#16-assets-android-ios-web)
17. [Config files at the root](#17-config-files-at-the-root)
18. [Key data flows](#18-key-data-flows)
19. [Guest vs signed-in behaviour](#19-guest-vs-signed-in-behaviour)
20. [Dependency summary table](#20-dependency-summary-table)
21. [Design decisions worth knowing](#21-design-decisions-worth-knowing)
22. [Known gaps](#22-known-gaps)

---

## 1. What the app does

A portrait-locked, dark-themed Flutter study timer. It runs one of five focus
presets (60m Vibe Coding Lab, 25m Pomodoro, 50m Deep Work, 15m Sprint, Custom),
logs completed sessions and prompt/error iterations, plays synthesized chimes, and
optionally syncs everything to Firebase when the user signs in.

**Sign-in is optional by design.** A fresh clone runs immediately in guest mode
with no server and no Firebase project.

---

## 2. Top-level folder map

```
vibe-study-timer-mobile/
├── pubspec.yaml            # Package name, dependencies, bundled font declarations
├── analysis_options.yaml   # Analyzer + lint config (flutter_lints)
├── firebase.json           # Firestore rules path + FlutterFire platform registry
├── firestore.rules         # Firestore security rules (per-uid access boundary)
├── .firebaserc             # Default Firebase project id
├── README.md               # Product-facing docs, setup, migration table
├── assets/
│   └── fonts/              # 10 TTFs: Outfit, PlusJakartaSans, JetBrainsMono
├── lib/                    # ← all application code (see below)
├── test/                   # Unit + widget tests
├── tool/                   # Standalone Dart diagnostics scripts
├── android/                # Android runner (Gradle, manifest, google-services.json)
├── ios/                    # iOS runner (Xcode project, Info.plist, AppDelegate)
├── web/                    # Web runner (index.html, manifest.json, icons)
├── build/                  # Generated build output (gitignored)
└── .dart_tool/             # Generated Dart tooling state (gitignored)
```

### The `lib/` tree

```
lib/
├── main.dart                    # Process entry: build the graph, run the app
├── app.dart                     # MultiProvider wiring + MaterialApp
├── firebase_options.dart        # GENERATED credentials (do not hand-edit)
│
├── models/                      # Plain data. No Flutter imports, no I/O.
│   ├── study_models.dart        # StudySession, PromptLog, StudyStats
│   ├── lab_phase.dart           # LabPhase, kLabPhases, StudyPreset, kPresets, stageCopyFor
│   └── auth_user.dart           # AuthUser (uid, email, initials)
│
├── data/
│   └── local_store.dart         # SharedPreferences-backed store + stats + merge
│
├── services/                    # Side-effecting infrastructure
│   ├── audio_service.dart       # WAV synthesis + playback
│   ├── firebase_bootstrap.dart  # Classify Firebase startup into FirebaseStatus
│   ├── auth_service.dart        # AuthService port + Firebase/No implementations
│   ├── sync_service.dart        # SyncService port + FirestoreSyncService + SyncBackend port
│   └── firestore_backend.dart   # The ONLY file that touches the Firestore SDK
│
├── controllers/                 # ChangeNotifier state holders
│   ├── timer_controller.dart    # Countdown + lab phase tracking
│   ├── stats_controller.dart    # Aggregate metrics + prompt log
│   └── auth_controller.dart     # Session lifecycle + drives sync
│
├── screens/                     # Full pages (routed)
│   ├── home_screen.dart         # The timer page
│   ├── auth_screen.dart         # Sign in / register
│   └── settings_screen.dart     # Profile + sync status + sign out
│
├── widgets/                     # Reusable pieces used inside screens
│   ├── timer_dial.dart          # CustomPainter progress ring + digits
│   ├── timer_controls.dart      # Start/Pause, Next, Reset
│   ├── preset_selector.dart     # Horizontal preset chips
│   ├── lab_roadmap.dart         # 4-stage lab tracker
│   ├── class_rule_card.dart     # Slide 14 class rule banner
│   ├── session_stats_bar.dart   # Minutes / sessions / prompts row
│   ├── quick_prompt_sheet.dart  # Prompt + error log bottom sheet
│   ├── custom_timer_sheet.dart  # Minutes + seconds picker
│   ├── toast_banner.dart        # Transient status pill
│   └── auth_widgets.dart        # GradientButton, AuthTextField, banners, toggle
│
└── theme/
    └── app_theme.dart           # Colours, fonts, radii, text styles, ThemeData
```

---

## 3. Layering and dependency rules

The project is organised in strict layers. **Dependencies only ever point downward.**

```
                    screens/          (routed pages)
                        │
                   widgets/          (reusable UI pieces)
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
     controllers/               theme/   (pure token classes)
     (ChangeNotifier state)
            │
            ▼
        services/        (ports + side effects: audio, auth, sync, firebase)
            │
            ▼
          data/           (LocalStore — the single read path)
            │
            ▼
        models/           (pure data structures, imports nothing local)
```

Rules that keep this intact:

| Rule | Why |
|---|---|
| `models/` imports **nothing** from `lib/` | Makes the data shapes trivially testable and reusable. |
| `theme/` imports **nothing** from `lib/` | Design tokens must be leaf-level. |
| `data/` imports only `models/` | The store is a persistence detail, not business logic. |
| `services/` never import `controllers/` or `screens/` | Services are injected, not aware of the UI. |
| `controllers/` import `models/`, `data/`, `services/` | State logic composes infrastructure. |
| `screens/` and `widgets/` never import `firestore_backend.dart` | The Firebase SDK is confined to one file. |
| Only `services/firestore_backend.dart` imports `cloud_firestore` | Testability: cloud access sits behind a 2-method port. |
| Only `services/auth_service.dart` imports `firebase_auth` | Keeps SDK exceptions out of the widget tree. |

**Provider usage pattern:** `screens/` uses `context.watch<T>()` to subscribe to a
controller and `context.read<T>()` to invoke one-shot actions without subscribing.
`widgets/` receive plain values and callbacks — they never touch Provider, so each
one can be dropped into any tree.

---

## 4. Boot sequence: how the object graph is built

`main()` builds everything by hand, in order, then hands the finished graph to
`runApp`. There is no service locator and no lazy `Provider.create`.

```
1. WidgetsFlutterBinding.ensureInitialized()
        ↓
2. SystemChrome.setPreferredOrientations([portraitUp])   ← portrait lock
        ↓
3. await LocalStore.open()            ← opens SharedPreferences, seeds demo rows
        ↓
4. AudioService()..restoreMuteState(store.isMuted)
        ↓
5. await bootstrapFirebase()          ← FirebaseReady | NotConfigured | InitFailed | UnsupportedPlatform
        ↓
6. Branch on the status:
     ready        → FirebaseAuthService()          + FirestoreBackend(FirebaseFirestore.instance)
     not ready    → NoAuthService(reasonString)   + null backend
        ↓
7. FirestoreSyncService(store, backend)
        ↓
8. TimerController(store, audio, sync)
   StatsController(store, sync)
   AuthController(authService, sync, stats, reason)..start()
        ↓
9. runApp(VibeTimerApp(...all of the above...))
```

The ordering matters: `AuthController` needs a `StatsController` so it can repaint
the stats bar after a sync merge wipes or populates local rows.

---

## 5. `lib/main.dart` — entry point

**What it is:** the composition root. Its only job is to construct the object graph
in the correct order and hand it to the widget tree.

**How it works:**

| Lines | What happens |
|---|---|
| 1–14 | Imports the whole app surface. |
| 17 | `ensureInitialized()` — required before any plugin call. |
| 19–21 | Locks to `portraitUp`. |
| 25 | `LocalStore.open()` — async because `SharedPreferences.getInstance()` is. Seeds demo data on first launch. |
| 27–28 | `AudioService` is a plain object; mute state is restored from disk. |
| 35–43 | `bootstrapFirebase()` classifies startup. The status string becomes `accountsReason`, which is threaded all the way to the auth screen so a misconfigured build explains itself *before* the user types a password. |
| 45–47 | **Dependency substitution.** Ready → `FirebaseAuthService`; otherwise → `NoAuthService(reason)`. Both satisfy the same `AuthService` interface. |
| 49–54 | `FirestoreSyncService` gets the store and a **nullable** backend. A null backend is what makes every sync operation a silent no-op in guest-only builds. |
| 56–59 | Controllers. `AuthController..start()` subscribes to the auth stream immediately. |
| 61–71 | `runApp`. |

**Depends on:** everything. **Used by:** nothing — it is the root.

**Why it is written this way:** Firebase is treated as an *optional* runtime
dependency. A fresh clone with no `flutterfire configure` still boots, still plays
the timer, and prints `Firebase disabled, running in guest mode: <reason>`.

---

## 6. `lib/app.dart` — dependency injection

**What it is:** a `StatelessWidget` that publishes the already-built objects into
the widget tree via `provider`.

**How it works:**

```dart
MultiProvider(
  providers: [
    Provider<LocalStore>.value(value: store),          // plain services: .value
    Provider<AudioService>.value(value: audio),
    Provider<AuthService>.value(value: authService),
    Provider<SyncService>.value(value: syncService),
    ChangeNotifierProvider<TimerController>.value(...), // reactive: notifiers
    ChangeNotifierProvider<StatsController>.value(...),
    ChangeNotifierProvider<AuthController>.value(...),
  ],
  child: MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
)
```

- **`.value` everywhere** — the objects were constructed in `main.dart`, not by
  Provider. This is what lets `AuthController` receive a live `StatsController`
  reference, and it means nothing is created lazily.
- **`home: HomeScreen`** with **no auth gate.** Login is optional, so the app opens
  straight into the timer and the user can stay a guest forever.

**Depends on:** `controllers/`, `data/`, `screens/`, `services/`, `theme/`.
**Used by:** `main.dart`, and `test/support/test_harness.dart` (which builds a fake
version of the exact same graph).

---

## 7. `lib/models/` — pure data

No Flutter imports, no I/O, no side effects. Everything here is a `toJson`/`fromJson`
pair or a `const` table.

### `models/study_models.dart`

| Class | Role |
|---|---|
| `StudySession` | One completed focus session: `id`, `mode`, `title`, `durationMinutes`, `completedAt`, `notes?`. |
| `PromptLog` | One prompt iteration or pasted error traceback: `id`, `phase`, `text`, `outcome?`, `timestamp`. |
| `StudyStats` | Aggregate: `totalMinutes`, `totalSessions`, `totalPrompts`, `lastSession?`. |

**How it works:** every `fromJson` is *defensive*. `DateTime.tryParse(...) ?? DateTime.now()`
means a corrupt or missing timestamp degrades to "now" instead of throwing.
`_toInt` accepts `int`, `num` or a parseable string. `notes`/`outcome` are omitted
from `toJson` when null so documents stay small. `DateTime` is serialised as
ISO-8601, which Firestore and JSON both round-trip losslessly.

**Depends on:** nothing local. **Used by:** `data/local_store.dart`,
`controllers/stats_controller.dart`, `screens/home_screen.dart`,
`widgets/quick_prompt_sheet.dart`, `widgets/session_stats_bar.dart`,
`services/sync_service.dart`, tests.

### `models/lab_phase.dart`

- **`LabPhase`** — one lab stage with `id`, `title`, `timeTag` (human window),
  `startSec`, `endSec`, `tip`, plus a derived `durationSec`.
- **`kLabPhases`** — the four hard-coded stages of the 60-Minute Vibe Coding Lab:

  | # | id | Window | Meaning |
  |---|---|---|---|
  | 1 | `plan` | 0–10 min | Draft the prompt spec: Context, Goal & Constraints |
  | 2 | `build` | 10–40 min | Iterate with AI, commit often, feed back errors |
  | 3 | `audit` | 40–50 min | Security check: OWASP Top 10 & slopsquatting |
  | 4 | `reflect` | 50–60 min | Class rule: explain every line before submitting |

- **`StudyPreset`** + **`kPresets`** — id / label / minutes. `isLab` is `id == 'vibe_lab_60'`,
  which is the single switch that turns phase tracking on.
- **`stageCopyFor(presetId, phase)`** — a function returning a record
  `({String label, String tip})`. In lab mode it derives copy from the current
  phase; otherwise it returns per-preset copy; otherwise a generic fallback. This
  is pure logic living in the model layer precisely so it can be unit-tested
  without pumping a widget.

**Depends on:** nothing. **Used by:** `controllers/timer_controller.dart`,
`widgets/timer_dial.dart`, `widgets/lab_roadmap.dart`, `widgets/preset_selector.dart`,
`test/widget_test.dart`.

### `models/auth_user.dart`

A 23-line adapter that decouples the rest of the app from `firebase_auth`'s `User`.
Carries `uid`, `email`, `displayName`, and an `initials` getter for the avatar chip
(`ada@example.com` → `AD`). **No widget or controller ever imports the Firebase SDK
to read a user.**

---

## 8. `lib/data/` — on-device persistence

### `data/local_store.dart`

**What it is:** the app's single source of truth. Replaces the old React+Node
backend entirely. Backed by `shared_preferences` (JSON strings in key–value
storage).

**Storage keys:**

| Key | Type | Contents |
|---|---|---|
| `vibe_m_sessions` | JSON array | `StudySession[]`, newest first |
| `vibe_m_prompts` | JSON array | `PromptLog[]`, newest first |
| `vibe_mobile_muted` | bool | Audio mute preference |
| `vibe_m_claimed_uid` | String | The uid that first claimed this device's guest data |

**How it works, part by part:**

- **`LocalStore.open()`** — async factory; loads `SharedPreferences` then calls
  `_seedIfEmpty()`. Seeding keys off `containsKey`, so it only happens once.
- **Synchronous reads by design.** `getSessions()` / `getPrompts()` return
  immediately, so no widget or controller had to become `async` when this layer was
  built. Reads go through `_read`, which swallows `FormatException` and returns an
  empty list — a corrupt payload starts clean instead of crashing the app.
- **`_track()` / `flushPendingWrites()`** — `shared_preferences` on Android uses
  `apply()`, which is asynchronous. If the OS kills the process mid-flush the write
  is silently lost. Every write future is tracked in `_pendingWrites`; the sync
  service awaits this before promising the cloud has the row. This closes the
  window where the cloud ends up *ahead* of the disk.
- **`addSession()` / `addPrompt()`** — prepend to the list and rewrite the whole
  array. Ids are `sess_<uuid v4>` / `p_<uuid v4>`, deliberately **uuid and not a
  millisecond timestamp**, because these become Firestore document ids — two devices
  with agreeing clocks would otherwise collide and silently merge two distinct
  sessions into one document.
- **`mergeSessions()` / `mergePrompts()`** — union by id. Sessions and prompts are
  write-once (there is no edit and no delete anywhere in the UI), so there are no
  conflicts to resolve: no `updatedAt`, no tombstones, no last-write-wins. Each
  merge re-sorts **newest first**, which matters because `getStats().lastSession`
  reads `sessions.first`. Returns the count of genuinely new rows.
- **`clearUserData()`** — writes `'[]'` rather than removing the key, because
  `_seedIfEmpty()` treats an *absent* key as first launch and would resurrect the
  demo rows. Called on sign-out so the next person to open the app as a guest
  cannot read the previous account's history.
- **`claimedMigrationUid` / `setClaimedMigrationUid()`** — records which uid claimed
  this device's guest data, so a *second* account on the same device never
  re-imports an already-migrated (and since wiped) dataset.
- **`getStats()`** — sums durations, counts rows, exposes the newest session. The
  same aggregation the old `db.getStats()` produced.

**Depends on:** `models/study_models.dart`, `shared_preferences`, `uuid`.
**Used by:** `main.dart`, all three controllers, `services/sync_service.dart`, tests.

---

## 9. `lib/services/` — infrastructure

Each service defines an **abstract port** plus an implementation. The port is what
makes guest-only operation and unit testing possible.

### `services/firebase_bootstrap.dart` — *why*, not *what*

Classifies Firebase startup into a `sealed class FirebaseStatus`:

| Status | Meaning | User-facing advice |
|---|---|---|
| `FirebaseReady` | Accounts and sync are live. | (none) |
| `FirebaseNotConfigured` | `firebase_options.dart` is still the placeholder. | Run `flutterfire configure`. |
| `FirebaseInitFailed` | A project is linked but `initializeApp` rejected it. | Re-run `flutterfire configure`, check the platform config files. |
| `FirebaseUnsupportedPlatform` | Running on Windows/macOS/Linux, where Firebase ships no SDK. | Use `flutter run -d chrome` or a mobile device. The timer works fine as a guest. |

**How it works:** it distinguishes three *different* exceptions from
`DefaultFirebaseOptions.currentPlatform` — `UnimplementedError` (placeholder still
in place), `UnsupportedError` (desktop, which advice "re-run flutterfire configure"
can never fix), and anything else (a genuinely broken generated file) — then wraps
`Firebase.initializeApp` in its own try/catch. `describeFirebaseStatus()` turns any
of these into a ready-to-display sentence. `initializeApp` performs no network I/O,
so a throw here always means the config is wrong, never a flaky connection.

**Depends on:** `firebase_options.dart`, `firebase_core`, `flutter/foundation`.
**Used by:** `main.dart`, `test/firebase_bootstrap_test.dart`.

### `services/auth_service.dart`

| Symbol | Role |
|---|---|
| `AuthService` (abstract) | `authStateChanges()`, `currentUser`, `signIn`, `register`, `signOut`, `sendPasswordResetEmail`. |
| `AuthUnavailable` | Exception carrying a ready-to-display reason. |
| `FirebaseAuthService` | Real implementation over `firebase_auth`. Maps `fb.User` → `AuthUser`. |
| `NoAuthService` | Guest-only stand-in. Empty auth stream, `currentUser == null`, and every real action throws `AuthUnavailable(reason)`. `signOut()` is a harmless no-op. |
| `authErrorMessage(error)` | Translates SDK codes into human sentences. |

**How it works:** every call is written defensively. `_require()` guards the SDK's
nullable `User` — a null after a successful credential would otherwise NPE the UI.
`authErrorMessage` maps the codes people actually hit: `wrong-password` /
`user-not-found` / `invalid-credential` all collapse to "Incorrect email or
password" (no user enumeration), while `operation-not-allowed` and
`configuration-not-found` get long, specific console walkthroughs because those are
the two failures no code change can fix.

**Depends on:** `models/auth_user.dart`, `firebase_auth`.
**Used by:** `controllers/auth_controller.dart`, `main.dart`, tests.

### `services/sync_service.dart` — the heart of the cloud story

Four declarations in one file:

**`SyncPhase`** — `idle | syncing | synced | failed`.
**`SyncStatus`** — phase + optional message + `lastSyncedAt`.
**`SyncBackend`** (abstract) — the whole cloud surface, two methods:

```dart
Future<void> put(String uid, String collection, String id, Map<String, dynamic> data);
Future<List<Map<String, dynamic>>> fetchAll(String uid, String collection);
```

This port exists because `cloud_firestore` 7.x has no supported test double
(`fake_cloud_firestore` pins an older platform interface). Keeping the dependency
behind two methods is what makes the migration and merge logic testable at all.

**`SyncService`** (abstract) — `isActive`, `status`, `statusChanges`,
`pushSession`, `pushPrompt`, `onUserSignedIn(uid)`, `onUserSignedOut()`.

**`FirestoreSyncService`** — the implementation. Document layout:

```
users/{uid}/sessions/{sessionId}   { mode, title, durationMinutes, completedAt, notes? }
users/{uid}/prompts/{promptId}     { phase, text, outcome?, timestamp }
```

How it behaves:

| Operation | Behaviour |
|---|---|
| `_push()` | Returns immediately if `_uid == null` or `_backend == null` — this is exactly what makes guest mode work. Otherwise `await store.flushPendingWrites()` then `backend.put(...)`. Any throw becomes `SyncPhase.failed` with a friendly message; **it never rethrows**, so controllers can fire-and-forget safely. |
| `onUserSignedIn(uid)` | Idempotent per uid (`_bootstrappedUid`). Emits `syncing`. If `store.claimedMigrationUid == null` (first account ever on this device) it **uploads all local rows**, then stamps the uid. Then always pulls. |
| `onUserSignedOut()` | Clears the uid, calls `store.clearUserData()`, awaits the flush, emits `idle`. Cloud copy untouched. |
| `_pullAll()` | Guarded by a `_pulling` re-entrancy flag, because `authStateChanges()` can replay on resume and two concurrent merges would fight over the same `SharedPreferences` value. Flushes, fetches both collections, unions them via `store.merge*`, emits `synced`. |

**Depends on:** `data/local_store.dart`, `models/study_models.dart`.
**Used by:** `main.dart`, `controllers/auth_controller.dart`,
`controllers/timer_controller.dart`, `controllers/stats_controller.dart`,
`lib/firestore_backend.dart`, tests.

### `services/firestore_backend.dart`

The **only** file in the app that imports `cloud_firestore`. 41 lines.
`collectionPath(uid, collection) => 'users/$uid/$collection'`. `fetchAll` re-stamps
each document with its Firestore document id, because the document id is
authoritative — it's the uuid we minted, so a doc that lost its embedded `id` field
still restores correctly.

**Depends on:** `cloud_firestore`, `services/sync_service.dart` (for the `SyncBackend`
interface). **Used by:** `main.dart`.

### `services/audio_service.dart`

**What it is:** a pure-Dart synthesizer. Flutter has no built-in synth, so the four
sounds are rendered as **16-bit PCM WAV byte buffers** in Dart and handed to
`audioplayers`.

| Voice | Waveform | Frequencies | When |
|---|---|---|---|
| `playChime()` | sine | 528 Hz, 2.1 s decay | Session start |
| `playStageBell()` | triangle | E5 659.25 + A5 880 (offset 220 ms) | Lab phase change / skip |
| `playCompletionFanfare()` | sine | C5 → E5 → G5 → C6, 160 ms apart | Session finish |
| `playClick()` | triangle sweep | 400 Hz → 100 Hz over 40 ms | Start/pause/reset taps |

**How it works:**

1. `_Tone` describes one voice: frequency (optional sweep target), start offset,
   duration, attack, peak/end gain, waveform flag.
2. `_renderWav()` computes the total buffer length, allocates a `Float64List` mix
   buffer, and for every sample of every tone: computes `t`, evaluates the gain
   envelope, applies the optional exponential frequency sweep, generates sine or
   triangle (`(2/π)·asin(sin φ))`, and **adds** it into the mix — so overlapping
   tones sum naturally.
3. Samples are clamped to `[-1, 1]`, scaled to `±32767`, and written as little-endian
   `Int16` via `ByteData`.
4. `_withWavHeader()` writes a standard 44-byte RIFF/WAVE header in front.
5. `_play()` round-robins across a pool of **3** `AudioPlayer` instances so a bell
   never cuts off a fanfare.

`_Tone.gainAt()` reproduces Web Audio's `linearRampToValueAtTime` +
`exponentialRampToValueAtTime` shape with a `_floor` of 0.001. Every frequency and
gain value was copied from the original `services/audio.js`, so the app sounds
identical to the React version.

Failures are swallowed (`catch (_) {}`) — audio is a nicety and must never break
the timer. `restoreMuteState` / `toggleMute` manage the mute flag; the flag is
persisted by `HomeScreen._toggleSound()` via `LocalStore.setMuted` and read back at
boot by `main()` (`AudioService()..restoreMuteState(store.isMuted)`), so the
preference survives a restart.

**Depends on:** `audioplayers`, `dart:math`, `dart:typed_data`.
**Used by:** `controllers/timer_controller.dart`, `screens/home_screen.dart`,
`main.dart`, tests.

---

## 10. `lib/controllers/` — state

All three extend `ChangeNotifier`. They are constructed in `main.dart` and injected,
never created by Provider.

### `controllers/timer_controller.dart`

**What it is:** the countdown clock and lab-phase tracker — a direct port of the old
`src/hooks/useTimer.js`, same 250 ms tick and same wall-clock delta maths.

**State it owns:** `_preset`, `_totalDuration`, `_remainingSeconds` (a `double`, so
fractional seconds carry smoothly between ticks), `_isRunning`, `_phaseIndex`,
`_lastTick`, `_ticker`.

**Getters the UI binds to:** `timeFormatted` (`MM:SS`, zero-padded from
`_remainingSeconds.ceil()`), `progressFraction` (elapsed fraction 0–1 driving the
dial ring), `currentPhase`, `isLabActive`.

**Actions:**

| Method | Behaviour |
|---|---|
| `selectPreset(id, {customSeconds})` | Stops the ticker, resets the clock and phase index. For `custom`, clamps to a 5 s minimum. Fires `onToast` with a humanised duration. |
| `toggle()` | Start → `playChime()` + ticker. Pause → `playClick()` + ticker stop. |
| `reset()` | Back to full duration, phase 0, click sound, toast. |
| `skipPhase()` | Lab mode only. Jumps `_remainingSeconds` to the start of the next phase, plays the stage bell. No-op on the last phase. |
| `_onTick()` | Computes `elapsed` from `DateTime.now()` deltas (not a decrement counter), so a throttled or delayed tick never drifts. On `next <= 0` calls `_complete()`. In lab mode, re-derives `_phaseIndex` by finding the phase whose `[startSec, endSec)` contains the elapsed time — a crossing is detected even if the app was backgrounded across a boundary. |
| `_complete()` | Stops the ticker, plays the fanfare, writes a `StudySession` to the store, fire-and-forget `sync.pushSession`, invokes `onSessionComplete`, notifies. |

**Two important details:**

- `_startTicker()` enables `WakelockPlus` and `_stopTicker()` disables it, so the
  screen stays awake only while a session is actually running.
- `onToast` and `onSessionComplete` are **callback properties**, not Provider
  listeners. `HomeScreen.initState` assigns them. This is the equivalent of the
  original hook's `onToast` argument.

**Depends on:** `data/`, `models/`, `services/audio_service.dart`,
`services/sync_service.dart`, `wakelock_plus`.
**Used by:** `screens/home_screen.dart` (via Provider), `test/support/test_harness.dart`.

### `controllers/stats_controller.dart`

Holds `StudyStats` and the `List<PromptLog>`. `prompts` is returned
`unmodifiable` so widgets cannot mutate state.

- Constructor calls `refresh()` immediately.
- `refresh()` re-reads `store.getStats()` and `store.getPrompts()`.
- `addPrompt({phase, text, outcome})` persists through the store, prepends to the
  in-memory list, recomputes stats, notifies, then `unawaited(sync.pushPrompt(prompt))`
  — Firestore queues the write offline and the local row is already durable, so
  there is nothing for the caller to await.
- `refreshAfterSession()` is called by `HomeScreen` when the timer completes.

**Depends on:** `data/`, `models/`, `services/sync_service.dart`.
**Used by:** `screens/home_screen.dart`, `screens/settings_screen.dart`,
`controllers/auth_controller.dart`, tests.

### `controllers/auth_controller.dart`

**What it is:** owns the session lifecycle and drives `SyncService` on every
transition. **Nothing here gates the timer.**

`AuthStatus` is `unknown | signedOut | signedIn`.

**State:** `_status`, `_user`, `_busy`, `_error`, two stream subscriptions, and
`accountsUnavailableReason` — a ready-to-display string, non-null when this build
has no usable auth provider. `accountsAvailable` is simply its negation.

**Flow:**

- `start()` — idempotent. Subscribes to `authStateChanges()` and to
  `sync.statusChanges` (so the settings screen's cloud indicator repaints). Then
  reads `currentUser` **synchronously**, because Firebase Auth restores a persisted
  session on cold start; waiting on the stream would show a false signed-out flash.
- `_handleAuthState(user)` — the core of the class:
  ```
  previousUid = _user?.uid
  _user = user; _status = user == null ? signedOut : signedIn
  if (user != null && previousUid != user.uid)   → await sync.onUserSignedIn(uid)
  if (user == null && previousUid != null)        → await sync.onUserSignedOut()
                                                    then stats.refresh()  ← repaint wiped stats
  ```
  The `previousUid != user.uid` guard means a replayed identical user (resume, token
  refresh) re-runs nothing.
- `signIn` / `register` / `sendPasswordResetEmail` / `signOut` all funnel through
  `_run(...)`-style busy-flag wrappers that return `bool`, set `error` via
  `authErrorMessage`, and always clear `_busy` in a `finally`.
- `_safeNotify()` swallows notifications after `dispose()`; `dispose()` cancels
  both subscriptions.

**Also exports three pure validators** used directly by `AuthScreen`:
`validateEmail`, `validatePassword({isRegister})`, `validatePasswordConfirmation`.
The email regex is deliberately loose — Firebase is the real authority on
deliverability, and a stricter regex just rejects valid-but-unusual addresses.

**Depends on:** `models/auth_user.dart`, `services/auth_service.dart`,
`services/sync_service.dart`, **`controllers/stats_controller.dart`** (the only
controller→controller dependency in the app).

---

## 11. `lib/screens/` — pages

### `screens/home_screen.dart` — the only screen you land on

**How it's put together:**

- `initState` seeds `_soundMuted` from `AudioService`, then **wires the timer
  callbacks**: `timer.onToast = _showToast` and `timer.onSessionComplete = …`
  which refreshes stats and shows a celebratory toast. This is the only place the
  timer's imperative hooks are connected to the UI.
- `_showToast` sets `_toastMessage` and clears it after 2800 ms, guarded by
  `if (_toastMessage != message) return` so overlapping toasts don't cut each other
  off early.
- `_handlePresetSelect` — tapping `custom` opens `CustomTimerSheet` and feeds the
  returned seconds back into `timer.selectPreset('custom', customSeconds: …)`.
- `_toggleSound` — flips the flag on `AudioService` **and awaits
  `store.setMuted(next)`** before repainting, so the preference is on disk before
  the UI updates. `main()` reads it back on the next launch.
- `_openPromptSheet` — passes the current lab phase id so the sheet pre-selects the
  right dropdown, and hands `stats.addPrompt` in as the submit callback.
- `_openAccount` — signed out → push `AuthScreen`, then toast based on
  `auth.syncStatus.phase`; signed in → push `SettingsScreen`.
- `build` watches all three controllers and assembles the page:
  `AppBar` (gradient title + three `_HeaderAction` buttons) → `ListView` of
  `ToastBanner?` → `PresetSelector` → `TimerDial` → `TimerControls` → `LabRoadmap`
  → `ClassRuleCard` → `SessionStatsBar`.

Widgets receive **values and callbacks only**; no widget below reads a controller.
`_HeaderAction` is a private circular icon button with a `Tooltip`.

**Depends on:** `controllers/`, `models/`, `services/`, `theme/`, all widgets,
`auth_screen.dart`, `settings_screen.dart`.

### `screens/auth_screen.dart` — sign in / register

One screen with a segmented toggle rather than two, so form state and autofill hints
stay in one place. `AuthScreen.show(context)` returns `true` if a session was
established.

**Key behaviours:**

- The **unavailable banner renders before the user types anything** — a build with
  no Firebase project must never look like it rejected their password.
- `GradientButton.onPressed` is `auth.accountsAvailable ? _submit : null`, so the
  submit path is closed up front.
- `_submit` **also fails closed**, because keyboard "done"/submit on a field
  bypasses a disabled button.
- Client-side validation runs first (`validateEmail`, `validatePassword`,
  `validatePasswordConfirmation`) and never reaches the network on failure.
- Bottom padding includes `MediaQuery.viewInsetsOf(context).bottom` so the keyboard
  does not cover the CTA.

**Depends on:** `controllers/auth_controller.dart`, `theme/`, `widgets/auth_widgets.dart`.

### `screens/settings_screen.dart` — profile, sync status, sign out

Reached only when signed in. Contains four private cards:

- **`_ProfileCard`** — gradient avatar circle from `auth.user!.initials` + email.
- **`_SyncCard`** — switches on `SyncStatus.phase`: `syncing` (spinner),
  `synced` ("Last synced Xm ago" via a `_format` relative-time helper),
  `failed` ("OFFLINE"), `idle` ("LOCAL ONLY").
- **`_StatsCard`** — sessions / minutes / prompts.
- **`_InfoCard`** — the shared icon + badge + body layout.

`_confirmSignOut` shows an `AlertDialog` explaining that cloud data survives and the
device copy will be cleared, then pops back after signing out.

**Depends on:** `controllers/auth_controller.dart`, `controllers/stats_controller.dart`,
`services/sync_service.dart`, `theme/`, `widgets/auth_widgets.dart`.

---

## 12. `lib/widgets/` — reusable UI

None of these import `provider`. Each takes plain values and callbacks, so each is
independently testable and reusable.

| Widget | Purpose | Notable technique |
|---|---|---|
| `timer_dial.dart` | 270 px progress ring + countdown digits + phase badge. | `_DialPainter extends CustomPainter`: background track, `SweepGradient` progress arc starting at `-π/2`, and a blurred second arc that only paints while running (`MaskFilter.blur`). `TweenAnimationBuilder` animates the ring over 400 ms so 250 ms ticks read smoothly. `shouldRepaint` compares only `progress` and `isRunning`. |
| `timer_controls.dart` | Start/Pause (flex 2), Next (lab only), Reset. | `_PrimaryButton` is a `DecoratedBox` gradient wrapping `Material`+`InkWell` so the glow shadow survives the ripple. `_SecondaryButton` is a stadium `Material` with `clipBehavior: antiAlias`. |
| `preset_selector.dart` | Horizontal scrolling preset chips. | `AnimatedContainer` morphs the active chip from a faint fill to the purple gradient. Reads `kPresets` from the model layer. |
| `lab_roadmap.dart` | 4-stage tracker card. | Returns `SizedBox.shrink()` unless `isLabActive`. Each step derives `isActive` / `isCompleted` from `currentPhaseIndex`, and animates fill + border colour. |
| `class_rule_card.dart` | Slide 14 banner: *"You may vibe code. You may not submit code you can't explain."* | Purely static copy. No dependencies beyond the theme. |
| `session_stats_bar.dart` | Total focus / sessions / prompts. | Formats minutes as `"2 h 5 m"`. `FittedBox` + `BoxFit.scaleDown` keeps long values from overflowing on narrow phones. |
| `quick_prompt_sheet.dart` | Slide-up prompt + error traceback logger with the session's prompt history. | `showModalBottomSheet(isScrollControlled: true)`; capped at 85 % of screen height with a `Flexible` + `SingleChildScrollView` body; padding includes `viewInsetsOf` for the keyboard. Uses `intl`'s `DateFormat.jm()` for timestamps. |
| `custom_timer_sheet.dart` | Minutes + seconds picker. | Full validation chain: minutes ≥ 0, seconds 0–59, total ≥ 5 s, total ≤ 8 h. Six quick chips, a live total readout, and `FilteringTextInputFormatter.digitsOnly` + `LengthLimitingTextInputFormatter` on both fields. |
| `toast_banner.dart` | Transient pill under the header. | `TweenAnimationBuilder` keyed on the message replays a 220 ms fade + 12 px slide-down each time the text changes. |
| `auth_widgets.dart` | Shared auth UI primitives: `GradientButton`, `AuthTextField`, `AuthErrorBanner`, `AuthNoticeBanner`, `AuthModeToggle`. | `GradientButton` handles the busy state (opacity 0.55 + spinner) and a nullable `onPressed`. `AuthTextField` inherits the global `inputDecorationTheme` and only adds label, icon and error line; it denies whitespace in email fields. |

---

## 13. `lib/theme/` — design tokens

`theme/app_theme.dart` is a 1:1 port of the old `src/styles/variables.css`. Five
token classes plus one theme builder:

| Class | Contents |
|---|---|
| `AppColors` | Surfaces (`bgApp` `#090615`, `bgPhone` `#0E0922`, `bgCard`, `bgSheet`, `bgInput`), accents (`accentPurple` `#8B5CF6`, `accentCyan` `#06B6D4` + glows), functional (`success` / `warning` / `danger`), text ramp, borders. |
| `AppFonts` | `main = Outfit`, `body = PlusJakartaSans`, `mono = JetBrainsMono`. Names must match the `fonts:` block in `pubspec.yaml`. |
| `AppRadii` | `sm 8`, `md 14`, `lg 24`, `xl 36`, `full 9999`. |
| `AppTextStyles` | `display` (the big timer digits, 51.2 px mono w700), `heading`, `cardTitle`, `body`, `badge`, `monoSmall`, `caption`. |
| `buildAppTheme()` | Assembles `ThemeData`: Material 3, `Brightness.dark`, transparent system overlay, transparent bottom sheets, rounded dark dialogs, floating snackbars, and an `inputDecorationTheme` with a purple focus border. |

Two shared gradients are exported as top-level constants:
`kPrimaryButtonGradient` (purple → darker purple, for CTAs) and
`kPurpleCyanGradient` (purple → light purple → cyan, for the title and dial ring).

**Depends on:** nothing local. **Used by:** `app.dart` and every file under
`screens/` and `widgets/`.

---

## 14. `test/` — the test suite

Three test files plus two support files. Firebase is never touched.

| File | What it covers |
|---|---|
| `test/widget_test.dart` | The timer UI (renders, preset chips switch duration, roadmap hides outside lab mode, mute persists across a relaunch) and the whole account flow: sign in, inline validation, register-mode confirm field, readable failure, guest dismissal, up-front warning when Firebase is missing, submit disabled/enabled, sign-out clears the device copy. Also `stageCopyFor` and `LocalStore` aggregation/id-uniqueness. |
| `test/sync_test.dart` | `LocalStore.merge` (union, idempotency, no-overwrite, newest-first ordering, empty-id skipping), the sign-out user boundary, and eleven `FirestoreSyncService` scenarios: no-op when signed out, no-op with no backend, first-sign-in migration, cross-device pull, post-sign-in push, second-account isolation, returning to an account, sign-out wipes device not cloud, replayed uid, cloud unreachable, and a failed push not throwing at the caller. |
| `test/firebase_bootstrap_test.dart` | Desktop must report `FirebaseUnsupportedPlatform` (not "misconfigured"), the four status messages must differ from each other, `NoAuthService` behaviour, and every `authErrorMessage` mapping. |
| `test/support/test_harness.dart` | `FakeAuthService` (in-memory `AuthService`, optionally throwing), `RecordingSyncService` (records pushes and uid transitions, no network), and `TestHarness.create()` which assembles the **exact same object graph as `main.dart`** with the fakes swapped in. |
| `test/support/load_fonts.dart` | Loads the real TTFs into the test font collection via `FontLoader`. Without it `flutter_test` substitutes a fallback font where every glyph is a full-em box, so correct layouts report bogus `RenderFlex` overflows. |

A documented quirk lives in `TestHarness.dispose()`: `TimerController` is
intentionally *not* disposed because `dispose()` calls `WakelockPlus.disable()`,
which goes through a pigeon platform channel with no test double and throws after
the test has already finished.

---

## 15. `tool/` — developer scripts

### `tool/verify_firebase_auth.dart`

Run with `dart run tool/verify_firebase_auth.dart`.

A standalone diagnostic that answers, without guessing at app error messages:

1. **Is Email/Password actually enabled** (or was Auth never initialised)?
2. **Does the Firestore database exist, and are the rules deployed?**

It scrapes `apiKey` / `projectId` out of `lib/firebase_options.dart`, masks the key
before printing, and asks the Identity Toolkit and Firestore REST APIs two
read-only questions. It signs in with an `example.invalid` address (reserved by
RFC 2606, guaranteed undeliverable and unregistered) so no account is created and
no email is sent. The only side effect is a failed-attempt counter, and one request
will not move it.

Response codes are mapped to verdicts: `API_KEY_INVALID` → broken key;
`CONFIGURATION_NOT_FOUND` → Auth never initialised; `OPERATION_NOT_ALLOWED` →
provider off; `EMAIL_NOT_FOUND` / `INVALID_LOGIN_CREDENTIALS` → **OK**. For
Firestore: "does not exist" → create the database; HTTP 403 → **OK**, rules are
correctly denying anonymous access; "Requested entity was not found" → rules were
never deployed.

---

## 16. `assets/`, `android/`, `ios/`, `web/`

### `assets/fonts/`

Ten TTFs bundled so the app works fully offline — no Google Fonts CDN. Four
`Outfit` weights (500/600/700/800), four `PlusJakartaSans` (400–700), two
`JetBrainsMono` (500/700). Every weight is declared individually in
`pubspec.yaml`, which is why `load_fonts.dart` has to register each one.

### `android/`

Standard Flutter Gradle project (Kotlin DSL). Two Firebase-specific decisions:

- **`app/build.gradle.kts` applies `com.google.gms.google-services`
  conditionally**, guarded by `if (file("google-services.json").exists())`. The
  plugin errors out when the file is absent, so an unconditional apply would make a
  fresh clone unbuildable — the exact opposite of "guest mode always works".
- **`minSdk = maxOf(flutter.minSdkVersion, 23)`** — Firebase Auth requires API 23+.
- `INTERNET` permission lives in the **main** manifest, not just debug/profile, or
  release builds fail with a `SocketException` on the first sync.

### `ios/`

Xcode project + `Runner/Info.plist`, `AppDelegate.swift`, `SceneDelegate.swift`.
`GoogleService-Info.plist` is **not** committed — after `flutterfire configure` you
must drag it into the Runner target manually.

### `web/`

`index.html`, `manifest.json`, `favicon.png`, `icons/`. Web is the one desktop-ish
target where Firebase *does* work, which is why the bootstrap message points
desktop users at `flutter run -d chrome`.

---

## 17. Config files at the root

| File | Purpose |
|---|---|
| `pubspec.yaml` | Package name, SDK constraint, dependencies, and the `fonts:` block declaring every bundled TTF by family + weight. |
| `analysis_options.yaml` | Includes `package:flutter_lints/flutter.yaml`; excludes `build/`, `android/`, `ios/`, `web/`. |
| `firebase.json` | Points `firestore.rules` at the rules file, plus the FlutterFire CLI's platform registry (app ids per platform, where `firebase_options.dart` goes). |
| `firestore.rules` | **Must be deployed.** A fresh Firebase project ships wide-open "test mode" rules. The shipped rules allow read/write only under `users/{userId}/**` when `request.auth.uid == userId`, and default-deny everything else. |
| `.firebaserc` | Default project id (`vibe-study-timer`). |
| `lib/firebase_options.dart` | **Generated.** Per-platform `FirebaseOptions` plus a `currentPlatform` getter. The desktop branches `throw UnsupportedError` — which is exactly what `firebase_bootstrap.dart` catches to produce `FirebaseUnsupportedPlatform`. |

**Dependencies in use:** `provider` (state), `shared_preferences` (local store),
`audioplayers` (sound), `wakelock_plus` (screen awake), `intl` (timestamps),
`uuid` (collision-free ids), `firebase_core` + `firebase_auth` + `cloud_firestore`
(accounts and sync), `cupertino_icons`, and `flutter_lints` as a dev dependency.

---

## 18. Key data flows

### Flow A — Start a session and finish it

```
User taps Start
  → TimerControls.onToggle
  → TimerController.toggle()
      → AudioService.playChime()
      → _startTicker()  ── enables WakelockPlus
  → notifyListeners()
  → HomeScreen / TimerDial / LabRoadmap rebuild

...every 250 ms...
  → TimerController._onTick()
      → DateTime delta maths
      → maybe phase crossed? → _phaseIndex = idx; AudioService.playStageBell()
      → notifyListeners()

Remaining hits 0
  → TimerController._complete()
      → AudioService.playCompletionFanfare()
      → LocalStore.addSession()              ← writes SharedPreferences (tracked)
      → unawaited(SyncService.pushSession())
            → await LocalStore.flushPendingWrites()   ← local is durable first
            → SyncBackend.put(uid, 'sessions', id, json)
      → onSessionComplete()
            → StatsController.refreshAfterSession()  → SessionStatsBar updates
            → toast "🎉 Session Complete!"
```

### Flow B — Log a prompt

```
User taps ✍ in the app bar
  → HomeScreen._openPromptSheet(timer.currentPhase?.id)
  → QuickPromptSheet.show(...)
  → submit
      → StatsController.addPrompt(phase:, text:, outcome:)
          → LocalStore.addPrompt()             ← persists, prepends
          → in-memory list + stats updated
          → notifyListeners()
          → unawaited(SyncService.pushPrompt(prompt))
      → fields cleared, sheet stays open, history list grows
```

### Flow C — First sign-in on a fresh device

```
AuthScreen._submit
  → validateEmail / validatePassword (no network yet)
  → AuthController.signIn → AuthService.signIn → FirebaseAuthService
  → firebase_auth emits on authStateChanges()
  → AuthController._handleAuthState(user)
      → previousUid (null) != user.uid
      → await SyncService.onUserSignedIn(uid)
            claimedMigrationUid == null?
              yes → _uploadAll()          ← every local row goes to the cloud
                   → store.setClaimedMigrationUid(uid)   ← permanent claim
              → _pullAll()
                    → flushPendingWrites()
                    → backend.fetchAll(uid, 'sessions')
                    → backend.fetchAll(uid, 'prompts')
                    → store.mergeSessions / mergePrompts   ← union, newest first
                    → emit synced
      → _stats.refresh()  (only on sign-out)
  → HomeScreen pops the route, shows a toast reflecting syncStatus.phase
```

### Flow D — Sign out

```
SettingsScreen._confirmSignOut → AuthController.signOut()
  → _auth.signOut()
  → stream emits null
  → _handleAuthState(null)
      → await SyncService.onUserSignedOut()
            → _uid = null
            → store.clearUserData()      ← writes '[]', does NOT remove the keys
            → await store.flushPendingWrites()
            → emit idle
      → StatsController.refresh()        ← repaint the now-empty stats bar
```

---

## 19. Guest vs signed-in behaviour

| Event | Guest | Signed in |
|---|---|---|
| Session / prompt logged | device only | device + Firestore, queued while offline |
| App closed | persists | persists |
| App uninstalled | **lost** | restored on next sign-in |
| New phone | **lost** | restored on next sign-in |
| Sign out | — | device copy wiped, cloud copy kept |

Guest data accumulated before the first sign-in is migrated **once** to whichever
account signs in first, then claimed by that device permanently — a second account
on the same device never inherits it (pinned by the
`a second account never inherits the first account data` test).

---

## 20. Dependency summary table

| File | Imports from `lib/` | Imported by |
|---|---|---|
| `main.dart` | everything | — (entry point) |
| `app.dart` | controllers, data, screens, services, theme | `main.dart`, tests |
| `models/study_models.dart` | — | data, controllers, screens, widgets, services, tests |
| `models/lab_phase.dart` | — | timer_controller, timer_dial, lab_roadmap, preset_selector, tests |
| `models/auth_user.dart` | — | auth_service, auth_controller, tests |
| `data/local_store.dart` | models | main, all controllers, sync_service, tests |
| `services/firebase_bootstrap.dart` | — (`firebase_options.dart`) | main, tests |
| `services/auth_service.dart` | models | main, auth_controller, tests |
| `services/sync_service.dart` | data, models | main, all controllers, firestore_backend, tests |
| `services/firestore_backend.dart` | sync_service | main |
| `services/audio_service.dart` | — | main, timer_controller, home_screen, tests |
| `controllers/timer_controller.dart` | data, models, services | home_screen, tests |
| `controllers/stats_controller.dart` | data, models, services | home_screen, settings_screen, auth_controller, tests |
| `controllers/auth_controller.dart` | models, services, stats_controller | home_screen, auth_screen, settings_screen, tests |
| `screens/home_screen.dart` | controllers, data, models, services, theme, all widgets | `app.dart` |
| `screens/auth_screen.dart` | auth_controller, theme, auth_widgets | home_screen |
| `screens/settings_screen.dart` | auth_controller, stats_controller, sync_service, theme, auth_widgets | home_screen |
| `widgets/*` | models + theme only (never controllers, never provider) | screens |
| `theme/app_theme.dart` | — | app, screens, widgets |

---

## 21. Design decisions worth knowing

1. **Ports around every side-effecting SDK.** `AuthService`, `SyncService` and
   `SyncBackend` are abstract interfaces. This is what lets a guest-only build pass
   a no-op implementation and lets the entire sync/migration state machine be unit
   tested against an in-memory map.
2. **`LocalStore` stays the read path.** Every read is a synchronous
   `SharedPreferences` hit, so sync is a *side effect on writes* and no widget ever
   had to become `async`. Offline is Firestore's problem, not the app's.
3. **Union, not reconciliation.** Sessions and prompts are write-once by product
   design, so merging is a set union keyed by uuid. No `updatedAt`, no tombstones,
   no conflict UI.
4. **Uuid ids, not timestamps.** These become Firestore document ids; timestamp ids
   would collide across devices with agreeing clocks.
5. **Failures are classified, never swallowed.** `FirebaseStatus` distinguishes four
   states because "you never configured a project" and "your project is broken"
   need completely different fixes.
6. **The object graph is built by hand in `main.dart`.** Not for purity — because
   `AuthController` needs a live `StatsController`, and because it keeps the whole
   graph mockable in tests.
7. **Widgets never touch Provider.** They take values and callbacks, so `HomeScreen`
   stays the only place that knows both the controllers and the widget tree.
8. **Re-entrancy guards where streams replay.** `_bootstrappedUid` in sync and
   `_pulling` prevent duplicate migrations and merge fights on resume.

---

## 22. Known gaps

- **`_pullAll()` reads the full collection.** Fine against the 50k reads/day free
  tier for a personal timer. If that ever changes, the fix is a
  `.where('timestamp', isGreaterThan: lastSyncAt)` cursor in
  `firestore_backend.dart` — not a change to the merge logic.
- **`google-services.json` is committed.** Fine for a client-only Firebase key, but
  it is regenerated by `flutterfire configure` and will show up in diffs.
- **iOS setup is manual.** `GoogleService-Info.plist` must be dragged into the
  Runner target in Xcode after `flutterfire configure`.
- **A failed sync never retries on its own.** It reports `failed` and leaves local
  data intact; recovery happens on the next pull/push or next sign-in.
- **Release builds are signed with debug keys** (`android/app/build.gradle.kts`),
  so `flutter run --release` works but Play Store distribution does not.