import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_models.dart';

/// On-device replacement for the old Node backend (`server.js` + `db.js` +
/// the `localStorage` fallback in `services/api.js`).
///
/// The public surface mirrors the REST routes one-for-one so the widgets
/// needed no changes:
///
/// | Old route            | Method here           |
/// |----------------------|-----------------------|
/// | GET  /api/sessions   | [getSessions]         |
/// | POST /api/sessions   | [addSession]          |
/// | GET  /api/prompts    | [getPrompts]          |
/// | POST /api/prompts    | [addPrompt]           |
/// | GET  /api/stats      | [getStats]            |
///
/// Data is stored as JSON strings under the same keys the web build used,
/// seeded on first launch with the same demo rows as `defaultData`.
class LocalStore {
  LocalStore(this._prefs);

  static const String _sessionsKey = 'vibe_m_sessions';
  static const String _promptsKey = 'vibe_m_prompts';
  static const String _mutedKey = 'vibe_mobile_muted';

  final SharedPreferences _prefs;

  /// Loads the store, seeding demo data on first run.
  static Future<LocalStore> open() async {
    final store = LocalStore(await SharedPreferences.getInstance());
    store._seedIfEmpty();
    return store;
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
        .map((e) => StudySession.fromJson(e))
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
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
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
    _prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  // ----------------------------------------------------------------- prompts

  List<PromptLog> getPrompts() {
    return _read(_promptsKey).map((e) => PromptLog.fromJson(e)).toList();
  }

  PromptLog addPrompt({
    required String phase,
    required String text,
    String? outcome,
  }) {
    final prompts = getPrompts();
    final prompt = PromptLog(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      phase: phase,
      text: text,
      outcome: (outcome == null || outcome.isEmpty) ? null : outcome,
      timestamp: DateTime.now(),
    );
    _writePrompts(<PromptLog>[prompt, ...prompts]);
    return prompt;
  }

  void _writePrompts(List<PromptLog> prompts) {
    _prefs.setString(
      _promptsKey,
      jsonEncode(prompts.map((p) => p.toJson()).toList()),
    );
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