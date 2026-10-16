import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/study_models.dart';

/// On-device store. Reads stay synchronous so the existing widgets and
/// controllers keep working unchanged; the cloud copy ([SyncService]) is a
/// side-effect layered on top of writes.
final Uuid _uuid = Uuid();

class LocalStore {
  LocalStore(this._prefs);

  static const String _sessionsKey = 'vibe_m_sessions';
  static const String _promptsKey = 'vibe_m_prompts';
  static const String _mutedKey = 'vibe_mobile_muted';

  /// Set to the uid that first claimed this device's guest data. Its presence
  /// is what stops a *second* account on the same device from re-importing an
  /// already-migrated (and since wiped) local dataset.
  static const String _claimedUidKey = 'vibe_m_claimed_uid';

  final SharedPreferences _prefs;

  /// In-flight [SharedPreferences] writes. `shared_preferences` uses Android's
  /// `apply()`, which is asynchronous — if the OS kills the process before the
  /// flush lands, the write is silently lost. Callers await this to close that
  /// window before reporting success.
  final Set<Future<bool>> _pendingWrites = <Future<bool>>{};

  /// Loads the store, seeding demo data on first run.
  static Future<LocalStore> open() async {
    final store = LocalStore(await SharedPreferences.getInstance());
    store._seedIfEmpty();
    return store;
  }

  /// Waits for every write issued so far to hit disk.
  Future<void> flushPendingWrites() async {
    if (_pendingWrites.isEmpty) return;
    await Future.wait(_pendingWrites.toList());
  }

  void _track(Future<bool> write) {
    _pendingWrites.add(write);
    write.then<void>(
      (_) => _pendingWrites.remove(write),
      onError: (Object _, StackTrace _) => _pendingWrites.remove(write),
    );
  }

  void _seedIfEmpty() {
    if (!_prefs.containsKey(_sessionsKey)) {
      final seeded = <StudySession>[
        StudySession(
          id: 'sess_1',
          mode: 'vibe_lab_60',
          title: '60-Min Vibe Lab Demo',
          durationMinutes: 60,
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
          notes: 'Completed Plan, Build, Audit, and Reflect stages',
        ),
      ];
      _writeSessions(seeded);
    }
    if (!_prefs.containsKey(_promptsKey)) {
      final seeded = <PromptLog>[
        PromptLog(
          id: 'prompt_1',
          phase: 'plan',
          text:
              'Build a single-page study timer for mobile with 60-min lab stages',
          outcome: 'Generated Flutter mobile scaffold',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      _writePrompts(seeded);
    }
  }

  // ---------------------------------------------------------------- sessions

  List<StudySession> getSessions() {
    return _read(_sessionsKey)
        .map(StudySession.fromJson)
        .toList(growable: false);
  }

  StudySession addSession({
    required String mode,
    required String title,
    required int durationMinutes,
    String? notes,
  }) {
    final sessions = getSessions();
    final session = StudySession(
      // A uuid, not a millisecond timestamp: these ids become Firestore
      // document ids, and two devices whose clocks agree would otherwise
      // collide and silently merge two distinct sessions into one document.
      id: 'sess_${_uuid.v4()}',
      mode: mode,
      title: title,
      durationMinutes: durationMinutes,
      completedAt: DateTime.now(),
      notes: notes,
    );
    _writeSessions(<StudySession>[session, ...sessions]);
    return session;
  }

  void _writeSessions(List<StudySession> sessions) {
    _track(_prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    ));
  }

  // ----------------------------------------------------------------- prompts

  List<PromptLog> getPrompts() {
    return _read(_promptsKey).map(PromptLog.fromJson).toList();
  }

  PromptLog addPrompt({
    required String phase,
    required String text,
    String? outcome,
  }) {
    final prompts = getPrompts();
    final prompt = PromptLog(
      id: 'p_${_uuid.v4()}',
      phase: phase,
      text: text,
      outcome: (outcome == null || outcome.isEmpty) ? null : outcome,
      timestamp: DateTime.now(),
    );
    _writePrompts(<PromptLog>[prompt, ...prompts]);
    return prompt;
  }

  void _writePrompts(List<PromptLog> prompts) {
    _track(_prefs.setString(
      _promptsKey,
      jsonEncode(prompts.map((p) => p.toJson()).toList()),
    ));
  }

  // -------------------------------------------------------------- sync merge

  /// Unions [incoming] into local storage by id.
  ///
  /// Sessions and prompts are write-once in this app — there is no edit and no
  /// delete anywhere in the UI — so the merge is a plain set union. No
  /// timestamps, no conflict resolution, no last-write-wins.
  ///
  /// Returns the number of genuinely new rows added.
  int mergeSessions(Iterable<StudySession> incoming) {
    final byId = <String, StudySession>{
      for (final s in getSessions()) s.id: s,
    };
    var added = 0;
    for (final s in incoming) {
      if (s.id.isEmpty || byId.containsKey(s.id)) continue;
      byId[s.id] = s;
      added++;
    }
    if (added > 0) {
      // `getStats()` treats `sessions.first` as the most recent session, so a
      // merge must restore the newest-first ordering the append paths produce.
      final merged = byId.values.toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      _writeSessions(merged);
    }
    return added;
  }

  /// Prompt-log counterpart of [mergeSessions]; union by id, newest first.
  int mergePrompts(Iterable<PromptLog> incoming) {
    final byId = <String, PromptLog>{
      for (final p in getPrompts()) p.id: p,
    };
    var added = 0;
    for (final p in incoming) {
      if (p.id.isEmpty || byId.containsKey(p.id)) continue;
      byId[p.id] = p;
      added++;
    }
    if (added > 0) {
      final merged = byId.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _writePrompts(merged);
    }
    return added;
  }

  // ----------------------------------------------------------- user boundary

  /// Drops the account's rows from this device.
  ///
  /// Called on sign-out. Without it, account A's study history stays readable
  /// by whoever next opens the app as a guest. Note this writes an empty list
  /// rather than removing the key — `_seedIfEmpty()` treats an absent key as
  /// "first launch" and would re-seed the demo rows.
  void clearUserData() {
    _track(_prefs.setString(_sessionsKey, '[]'));
    _track(_prefs.setString(_promptsKey, '[]'));
  }

  /// The uid that already claimed this device's guest data, if any.
  String? get claimedMigrationUid => _prefs.getString(_claimedUidKey);

  Future<void> setClaimedMigrationUid(String uid) {
    return _prefs.setString(_claimedUidKey, uid);
  }

  // ------------------------------------------------------------------- stats

  /// Same aggregation as `db.getStats()`.
  StudyStats getStats() {
    final sessions = getSessions();
    final prompts = getPrompts();
    return StudyStats(
      totalMinutes: sessions.fold<int>(
        0,
        (sum, s) => sum + s.durationMinutes,
      ),
      totalSessions: sessions.length,
      totalPrompts: prompts.length,
      lastSession: sessions.isEmpty ? null : sessions.first,
    );
  }

  // -------------------------------------------------------------- settings

  bool get isMuted => _prefs.getBool(_mutedKey) ?? false;

  Future<bool> setMuted(bool value) => _prefs.setBool(_mutedKey, value);

  // -------------------------------------------------------------- internals

  List<Map<String, dynamic>> _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } on FormatException {
      // Corrupt payload — start clean rather than crashing the app.
      return <Map<String, dynamic>>[];
    }
  }
}
