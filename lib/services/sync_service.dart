import 'dart:async';

import '../data/local_store.dart';
import '../models/study_models.dart';

enum SyncPhase {
  /// Signed out, or nothing has happened yet.
  idle,

  /// A push or pull is in flight.
  syncing,

  /// Local and cloud agree as of [SyncStatus.lastSyncedAt].
  synced,

  /// The last operation threw. Local data is still intact and will retry.
  failed,
}

class SyncStatus {
  const SyncStatus(
    this.phase, {
    this.message,
    this.lastSyncedAt,
  });

  final SyncPhase phase;
  final String? message;
  final DateTime? lastSyncedAt;
}

/// The narrow cloud surface [FirestoreSyncService] depends on.
///
/// Deliberately not `FirebaseFirestore` directly: the cloud_firestore 7.x SDK
/// has no supported test double (`fake_cloud_firestore` pins an older
/// platform interface), so keeping the dependency behind a two-method port is
/// what makes the migration and merge logic testable at all. The Firestore
/// implementation lives in `firestore_backend.dart`.
abstract class SyncBackend {
  Future<void> put(
    String uid,
    String collection,
    String id,
    Map<String, dynamic> data,
  );

  /// Returns every document in the collection, each carrying its document id
  /// under the `id` key.
  Future<List<Map<String, dynamic>>> fetchAll(String uid, String collection);
}

/// Two-way sync between the on-device [LocalStore] and the cloud.
///
/// Design notes:
///
/// * **LocalStore stays the read path.** Every read is still a synchronous
///   SharedPreferences hit, so no widget or controller had to become async.
///   Sync is a side-effect on writes.
/// * **Union, not reconciliation.** Sessions and prompts are write-once in this
///   app — there is no edit or delete anywhere in the UI — so merging is a set
///   union keyed by the uuid id. No `updatedAt`, no tombstones, no conflict UI.
/// * **Offline is handled by the SDK.** Firestore queues writes locally via
///   offline persistence, so callers can safely fire-and-forget.
/// * **No-ops when signed out**, which is what makes guest mode work.
abstract class SyncService {
  /// True when a user is signed in and pushes will reach the network.
  bool get isActive;

  SyncStatus get status;

  /// Broadcast so `AuthController` can mirror it into the widget tree.
  Stream<SyncStatus> get statusChanges;

  Future<void> pushSession(StudySession session);

  Future<void> pushPrompt(PromptLog prompt);

  /// Runs the sign-in flow: migrate this device's guest data if it has never
  /// been claimed, then pull the account's cloud data down.
  Future<void> onUserSignedIn(String uid);

  /// Detaches from the account and drops its rows from the device.
  Future<void> onUserSignedOut();
}

/// Cloud-mirroring implementation of [SyncService].
///
/// Document layout:
/// ```
/// users/{uid}/sessions/{sessionId}  { mode, title, durationMinutes, completedAt, notes? }
/// users/{uid}/prompts/{promptId}    { phase, text, outcome?, timestamp }
/// ```
class FirestoreSyncService implements SyncService {
  FirestoreSyncService(this._store, [this._backend]);

  static const String sessions = 'sessions';
  static const String prompts = 'prompts';

  final LocalStore _store;

  /// Null in guest-only builds (no Firebase project configured). Combined with
  /// the null-uid guard in [_push], every operation becomes a no-op.
  final SyncBackend? _backend;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _status = const SyncStatus(SyncPhase.idle);
  String? _uid;

  /// Guards against re-entrant pulls: `authStateChanges()` can replay on
  /// resume, and two concurrent merges of the same rows would fight over the
  /// SharedPreferences value.
  bool _pulling = false;

  /// The uid we have already run the initial migrate+pull for.
  String? _bootstrappedUid;

  @override
  bool get isActive => _uid != null && _backend != null;

  @override
  SyncStatus get status => _status;

  @override
  Stream<SyncStatus> get statusChanges => _statusController.stream;

  void _emit(SyncPhase phase, {String? message, bool keepLastSync = true}) {
    _status = SyncStatus(
      phase,
      message: message,
      lastSyncedAt: keepLastSync ? _status.lastSyncedAt : DateTime.now(),
    );
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  // -------------------------------------------------------------- pushing

  @override
  Future<void> pushSession(StudySession session) =>
      _push(sessions, session.id, session.toJson());

  @override
  Future<void> pushPrompt(PromptLog prompt) =>
      _push(prompts, prompt.id, prompt.toJson());

  Future<void> _push(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final String? uid = _uid;
    final SyncBackend? backend = _backend;
    // Signed out, or no cloud configured: the row stays on-device and is
    // claimed at the next sign-in.
    if (uid == null || backend == null || id.isEmpty) return;

    try {
      // Make sure the local write has actually landed before we promise the
      // same row exists remotely. `shared_preferences` applies asynchronously,
      // so without this the cloud could end up ahead of the disk.
      await _store.flushPendingWrites();
      await backend.put(uid, collection, id, data);
    } catch (error) {
      _emit(
        SyncPhase.failed,
        message: 'Offline — changes are queued and will sync later.',
      );
    }
  }

  // ------------------------------------------------------------- lifecycle

  @override
  Future<void> onUserSignedIn(String uid) async {
    if (_bootstrappedUid == uid) return;
    // Guest-only build that somehow got a user — nothing to sync to.
    if (_backend == null) return;

    _uid = uid;
    _bootstrappedUid = uid;
    _emit(SyncPhase.syncing, keepLastSync: false);

    try {
      // First account on this device: whatever was accumulated as a guest
      // belongs to whoever signs up first.
      if (_store.claimedMigrationUid == null) {
        await _uploadAll();
        await _store.setClaimedMigrationUid(uid);
      }
      // Otherwise the guest data was already claimed (and, on sign-out,
      // cleared) — pull only. That way a second account on this device never
      // inherits it, and an account we return to still restores its history.
      await _pullAll();
    } catch (error) {
      _emit(
        SyncPhase.failed,
        message: 'Could not reach the cloud. Your data is safe on this device.',
      );
    }
  }

  @override
  Future<void> onUserSignedOut() async {
    _uid = null;
    _bootstrappedUid = null;
    // Drop the account's rows so the next person to open the app as a guest
    // cannot read them. Writes '[]' rather than removing the key, because
    // LocalStore re-seeds demo rows when a key is absent.
    _store.clearUserData();
    await _store.flushPendingWrites();
    _emit(SyncPhase.idle, keepLastSync: false);
  }

  Future<void> _uploadAll() async {
    final String uid = _uid!;
    final SyncBackend backend = _backend!;
    await Future.wait(<Future<void>>[
      for (final StudySession s in _store.getSessions())
        backend.put(uid, sessions, s.id, s.toJson()),
      for (final PromptLog p in _store.getPrompts())
        backend.put(uid, prompts, p.id, p.toJson()),
    ]);
  }

  /// Pulls both collections and unions them into local storage.
  ///
  /// This is a full-collection read. Firestore's free tier allows 50k reads
  /// per day, which a personal study timer stays well inside; if that ever
  /// changes the fix is a `.where('timestamp', isGreaterThan: lastSyncAt)`
  /// cursor in the backend, not a change to the merge itself.
  Future<void> _pullAll() async {
    if (_pulling) return;
    _pulling = true;
    final String uid = _uid!;
    final SyncBackend backend = _backend!;

    try {
      await _store.flushPendingWrites();

      final List<Map<String, dynamic>> remoteSessions =
          await backend.fetchAll(uid, sessions);
      final List<Map<String, dynamic>> remotePrompts =
          await backend.fetchAll(uid, prompts);

      _store.mergeSessions(remoteSessions.map(StudySession.fromJson));
      _store.mergePrompts(remotePrompts.map(PromptLog.fromJson));

      _emit(SyncPhase.synced, keepLastSync: false);
    } finally {
      _pulling = false;
    }
  }

  void dispose() {
    _statusController.close();
  }
}
