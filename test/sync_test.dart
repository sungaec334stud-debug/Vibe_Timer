import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_study_timer/data/local_store.dart';
import 'package:vibe_study_timer/models/study_models.dart';
import 'package:vibe_study_timer/services/sync_service.dart';

/// In-memory [SyncBackend] standing in for Firestore.
///
/// Stores documents as `uid/collection/id` so per-account isolation can be
/// asserted, and can be pre-seeded to simulate data written by another device.
class MemoryBackend implements SyncBackend {
  final Map<String, Map<String, dynamic>> docs =
      <String, Map<String, dynamic>>{};

  int putCount = 0;
  int fetchCount = 0;

  /// Set to make every operation throw, simulating being offline.
  bool offline = false;

  String _key(String uid, String collection, String id) => '$uid/$collection/$id';

  void seed(String uid, String collection, String id, Map<String, dynamic> data) {
    docs[_key(uid, collection, id)] = data;
  }

  int countIn(String uid, String collection) => docs.keys
      .where((String k) => k.startsWith('$uid/$collection/'))
      .length;

  List<String> idsIn(String uid, String collection) => docs.entries
      .where((MapEntry<String, Map<String, dynamic>> e) =>
          e.key.startsWith('$uid/$collection/'))
      .map((MapEntry<String, Map<String, dynamic>> e) => e.key.split('/').last)
      .toList();

  @override
  Future<void> put(
    String uid,
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    if (offline) throw StateError('offline');
    putCount++;
    docs[_key(uid, collection, id)] = Map<String, dynamic>.of(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll(
    String uid,
    String collection,
  ) async {
    if (offline) throw StateError('offline');
    fetchCount++;
    return docs.entries
        .where((MapEntry<String, Map<String, dynamic>> e) =>
            e.key.startsWith('$uid/$collection/'))
        .map((MapEntry<String, Map<String, dynamic>> e) =>
            <String, dynamic>{...e.value, 'id': e.key.split('/').last})
        .toList();
  }
}

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return LocalStore.open();
}

StudySession _session(String id, DateTime at, {int minutes = 30}) {
  return StudySession(
    id: id,
    mode: 'deep_50',
    title: 'Focus $id',
    durationMinutes: minutes,
    completedAt: at,
  );
}

PromptLog _prompt(String id, DateTime at) {
  return PromptLog(
    id: id,
    phase: 'build',
    text: 'prompt $id',
    timestamp: at,
  );
}

void main() {
  group('LocalStore.merge', () {
    test('unions sessions by id and re-sorts newest first', () async {
      final LocalStore store = await _store();
      final DateTime now = DateTime.now();

      store.mergeSessions(<StudySession>[
        _session('remote_old', now.subtract(const Duration(days: 2))),
        _session('remote_new', now),
      ]);

      final List<StudySession> merged = store.getSessions();
      // Seeded demo row is 2h old, so it sorts between the two.
      expect(merged.map((StudySession s) => s.id).toList(), <String>[
        'remote_new',
        'sess_1',
        'remote_old',
      ]);
      // getStats().lastSession depends on this ordering being correct.
      expect(store.getStats().lastSession?.id, 'remote_new');
    });

    test('is idempotent — re-pulling the same rows adds nothing', () async {
      final LocalStore store = await _store();
      final DateTime now = DateTime.now();
      final List<StudySession> incoming = <StudySession>[
        _session('a', now),
        _session('b', now.subtract(const Duration(hours: 1))),
      ];

      expect(store.mergeSessions(incoming), 2);
      expect(store.mergeSessions(incoming), 0);
      expect(store.mergeSessions(incoming), 0);
      expect(store.getSessions().length, 3); // + seeded
    });

    test('never overwrites a local row with an incoming one of the same id',
        () async {
      final LocalStore store = await _store();
      final DateTime now = DateTime.now();

      final StudySession local = _session('shared', now, minutes: 60);
      store.mergeSessions(<StudySession>[local]);
      // Same id, different payload — write-once data should keep the original.
      store.mergeSessions(<StudySession>[
        _session('shared', now, minutes: 999),
      ]);

      final StudySession found =
          store.getSessions().firstWhere((StudySession s) => s.id == 'shared');
      expect(found.durationMinutes, 60);
    });

    test('prompts merge and stay newest first', () async {
      final LocalStore store = await _store();
      final DateTime now = DateTime.now();

      store.mergePrompts(<PromptLog>[
        _prompt('p_old', now.subtract(const Duration(days: 3))),
        _prompt('p_new', now),
      ]);

      expect(store.getPrompts().first.id, 'p_new');
      expect(store.getPrompts().length, 3); // + seeded
    });

    test('skips rows with an empty id rather than collapsing them', () async {
      final LocalStore store = await _store();

      final int added = store.mergeSessions(<StudySession>[
        _session('', DateTime.now()),
        _session('ok', DateTime.now()),
      ]);

      expect(added, 1);
    });
  });

  group('LocalStore user boundary', () {
    test('clearUserData empties rows without re-seeding demo data', () async {
      final LocalStore store = await _store();
      expect(store.getStats().totalSessions, 1);

      store.clearUserData();
      await store.flushPendingWrites();

      expect(store.getStats().totalSessions, 0);
      expect(store.getStats().totalPrompts, 0);

      // Re-opening the store must not resurrect the seeded rows.
      final LocalStore reopened = await LocalStore.open();
      expect(reopened.getStats().totalSessions, 0);
      expect(reopened.getStats().totalPrompts, 0);
    });
  });

  group('FirestoreSyncService', () {
    test('is a complete no-op while signed out', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      final StudySession s = store.addSession(
        mode: 'custom',
        title: 'guest',
        durationMinutes: 10,
      );
      await sync.pushSession(s);
      await sync.pushPrompt(store.addPrompt(phase: 'build', text: 'hi'));

      expect(backend.putCount, 0);
      expect(backend.docs, isEmpty);
      expect(sync.isActive, isFalse);
      expect(sync.status.phase, SyncPhase.idle);
    });

    test('is a no-op with no backend configured (guest-only build)', () async {
      final LocalStore store = await _store();
      final FirestoreSyncService sync =
          FirestoreSyncService(store);

      await sync.onUserSignedIn('uid-1');

      expect(sync.isActive, isFalse);
      expect(sync.status.phase, SyncPhase.idle);
    });

    test('first sign-in migrates guest data to the account', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      expect(store.claimedMigrationUid, isNull);
      await sync.onUserSignedIn('uid-ada');

      // Seeded session + seeded prompt were uploaded.
      expect(backend.countIn('uid-ada', FirestoreSyncService.sessions), 1);
      expect(backend.countIn('uid-ada', FirestoreSyncService.prompts), 1);
      expect(store.claimedMigrationUid, 'uid-ada');
      expect(sync.status.phase, SyncPhase.synced);
      expect(sync.isActive, isTrue);
    });

    test('pulls cloud rows made on another device', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final DateTime now = DateTime.now();

      // Data that only exists in the cloud, as if written on a phone.
      backend.seed('uid-ada', FirestoreSyncService.sessions, 'remote-1',
          _session('remote-1', now).toJson());
      backend.seed('uid-ada', FirestoreSyncService.prompts, 'remote-p1',
          _prompt('remote-p1', now).toJson());

      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);
      await sync.onUserSignedIn('uid-ada');

      expect(store.getSessions().map((StudySession s) => s.id),
          contains('remote-1'));
      expect(store.getPrompts().map((PromptLog p) => p.id),
          contains('remote-p1'));
      // Local row was preserved through the union.
      expect(store.getSessions().map((StudySession s) => s.id),
          contains('sess_1'));
    });

    test('pushes new rows after sign-in', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      await sync.onUserSignedIn('uid-ada');
      final int baseline = backend.putCount;

      final StudySession s = store.addSession(
        mode: 'deep_50',
        title: 'logged',
        durationMinutes: 50,
      );
      await sync.pushSession(s);

      expect(backend.putCount, greaterThan(baseline));
      expect(backend.docs.containsKey(
          'uid-ada/${FirestoreSyncService.sessions}/${s.id}'), isTrue);
    });

    test('a second account never inherits the first account data', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      // Account A claims the guest data, then signs out.
      await sync.onUserSignedIn('uid-ada');
      expect(store.getStats().totalSessions, 1);
      await sync.onUserSignedOut();
      expect(store.getStats().totalSessions, 0);

      // Account B signs in on the same device.
      await sync.onUserSignedIn('uid-bob');

      expect(backend.countIn('uid-bob', FirestoreSyncService.sessions), 0);
      expect(store.getStats().totalSessions, 0);
      // A's cloud copy is untouched.
      expect(backend.countIn('uid-ada', FirestoreSyncService.sessions), 1);
    });

    test('returning to an account restores its rows from the cloud', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      await sync.onUserSignedIn('uid-ada');
      await sync.pushSession(store.addSession(
        mode: 'custom',
        title: 'second device',
        durationMinutes: 25,
      ));
      final int expected = store.getStats().totalSessions;

      await sync.onUserSignedOut();
      expect(store.getStats().totalSessions, 0);

      // Signing back in must pull, not re-migrate an empty device.
      await sync.onUserSignedIn('uid-ada');
      expect(store.getStats().totalSessions, expected);
    });

    test('sign-out wipes the device copy but not the cloud', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      await sync.onUserSignedIn('uid-ada');
      await sync.onUserSignedOut();

      expect(store.getStats().totalSessions, 0);
      expect(store.getStats().totalPrompts, 0);
      expect(backend.countIn('uid-ada', FirestoreSyncService.sessions), 1);
      expect(sync.status.phase, SyncPhase.idle);
      expect(sync.isActive, isFalse);
    });

    test('replaying the same uid does not re-run migration', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      await sync.onUserSignedIn('uid-ada');
      final int fetches = backend.fetchCount;
      await sync.onUserSignedIn('uid-ada');

      expect(backend.fetchCount, fetches);
    });

    test('reports failed and keeps local data when the cloud is unreachable',
        () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      backend.offline = true;
      await sync.onUserSignedIn('uid-ada');

      expect(sync.status.phase, SyncPhase.failed);
      // Local data is untouched — nothing is lost by a failed sync.
      expect(store.getStats().totalSessions, 1);
    });

    test('a failed push does not throw at the caller', () async {
      final LocalStore store = await _store();
      final MemoryBackend backend = MemoryBackend();
      final FirestoreSyncService sync =
          FirestoreSyncService(store, backend);

      await sync.onUserSignedIn('uid-ada');
      backend.offline = true;

      final StudySession s = store.addSession(
        mode: 'custom',
        title: 'offline session',
        durationMinutes: 10,
      );
      // Must not throw — controllers call this fire-and-forget.
      await expectLater(sync.pushSession(s), completes);
      expect(sync.status.phase, SyncPhase.failed);
      // The row is still on-device and will go up on the next pull/push.
      expect(store.getSessions().map((StudySession x) => x.id),
          contains(s.id));
    });
  });
}
