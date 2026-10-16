import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_study_timer/app.dart';
import 'package:vibe_study_timer/controllers/auth_controller.dart';
import 'package:vibe_study_timer/controllers/stats_controller.dart';
import 'package:vibe_study_timer/controllers/timer_controller.dart';
import 'package:vibe_study_timer/data/local_store.dart';
import 'package:vibe_study_timer/models/auth_user.dart';
import 'package:vibe_study_timer/models/study_models.dart';
import 'package:vibe_study_timer/services/audio_service.dart';
import 'package:vibe_study_timer/services/auth_service.dart';
import 'package:vibe_study_timer/services/sync_service.dart';

/// In-memory [AuthService] so the widget tree never reaches Firebase.
class FakeAuthService implements AuthService {
  FakeAuthService({this.failWith});

  /// When set, sign-in/register throws it instead of succeeding.
  final Object? failWith;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _current;
  int signOutCount = 0;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (failWith != null) throw failWith!;
    return _emit(AuthUser(uid: 'uid-1', email: email.trim()));
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    if (failWith != null) throw failWith!;
    return _emit(AuthUser(uid: 'uid-1', email: email.trim()));
  }

  AuthUser _emit(AuthUser user) {
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (failWith != null) throw failWith!;
  }
}

/// Records what [FirestoreSyncService] would have done, without a network.
class RecordingSyncService implements SyncService {
  final List<StudySession> pushedSessions = <StudySession>[];
  final List<PromptLog> pushedPrompts = <PromptLog>[];
  final List<String> signedInUids = <String>[];
  int signOutCount = 0;

  bool _active = false;
  SyncStatus _status = const SyncStatus(SyncPhase.idle);
  final StreamController<SyncStatus> _controller =
      StreamController<SyncStatus>.broadcast();

  @override
  bool get isActive => _active;

  @override
  SyncStatus get status => _status;

  @override
  Stream<SyncStatus> get statusChanges => _controller.stream;

  @override
  Future<void> pushSession(StudySession session) async {
    if (!_active) return;
    pushedSessions.add(session);
  }

  @override
  Future<void> pushPrompt(PromptLog prompt) async {
    if (!_active) return;
    pushedPrompts.add(prompt);
  }

  @override
  Future<void> onUserSignedIn(String uid) async {
    signedInUids.add(uid);
    _active = true;
    _set(const SyncStatus(SyncPhase.synced));
  }

  @override
  Future<void> onUserSignedOut() async {
    signOutCount++;
    _active = false;
    _set(const SyncStatus(SyncPhase.idle));
  }

  void _set(SyncStatus next) {
    _status = next;
    if (!_controller.isClosed) _controller.add(next);
  }
}

/// The full object graph, with Firebase swapped for fakes.
class TestHarness {
  TestHarness._({
    required this.store,
    required this.audio,
    required this.authService,
    required this.syncService,
    required this.timer,
    required this.stats,
    required this.auth,
  });

  final LocalStore store;
  final AudioService audio;
  final FakeAuthService authService;
  final RecordingSyncService syncService;
  final TimerController timer;
  final StatsController stats;
  final AuthController auth;

  static Future<TestHarness> create({
    Object? authFailsWith,
    String? accountsUnavailableReason,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final LocalStore store = await LocalStore.open();
    final AudioService audio = AudioService();
    final FakeAuthService authService =
        FakeAuthService(failWith: authFailsWith);
    final RecordingSyncService sync = RecordingSyncService();

    final StatsController stats = StatsController(store, sync);
    final TimerController timer = TimerController(store, audio, sync);
    final AuthController auth =
        AuthController(authService, sync, stats, accountsUnavailableReason)
          ..start();

    return TestHarness._(
      store: store,
      audio: audio,
      authService: authService,
      syncService: sync,
      timer: timer,
      stats: stats,
      auth: auth,
    );
  }

  Widget wrapApp() {
    return VibeTimerApp(
      store: store,
      audio: audio,
      authService: authService,
      syncService: syncService,
      timer: timer,
      stats: stats,
      auth: auth,
    );
  }

  /// [TimerController] is intentionally not disposed: `dispose()` calls
  /// `WakelockPlus.disable()`, which goes through a pigeon platform channel
  /// with no test double and throws `PlatformException` after the test has
  /// already completed. Nothing in the app registers these notifiers with
  /// `ChangeNotifierProvider.create`, so there is nothing to leak-check.
  void dispose() {
    stats.dispose();
    auth.dispose();
  }
}
