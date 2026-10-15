import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../models/study_models.dart';

/// Holds the aggregate metrics and the prompt log shown on the home screen.
///
/// Replaces the `refreshData()` wiring in `App.jsx`, which used to fetch
/// `/api/stats` and `/api/prompts` from the Node backend.
class StatsController extends ChangeNotifier {
  StatsController(this._store) {
    refresh();
  }

  final LocalStore _store;

  StudyStats _stats = const StudyStats();
  List<PromptLog> _prompts = <PromptLog>[];

  StudyStats get stats => _stats;
  List<PromptLog> get prompts => List<PromptLog>.unmodifiable(_prompts);

  /// Re-reads everything from disk.
  void refresh() {
    _stats = _store.getStats();
    _prompts = _store.getPrompts();
    notifyListeners();
  }

  /// Persists a prompt iteration and updates the in-memory counters.
  PromptLog addPrompt({
    required String phase,
    required String text,
    String? outcome,
  }) {
    final PromptLog prompt = _store.addPrompt(
      phase: phase,
      text: text,
      outcome: outcome,
    );
    _prompts = <PromptLog>[prompt, ..._prompts];
    _stats = _store.getStats();
    notifyListeners();
    return prompt;
  }

  /// Refreshes after the timer logs a finished session.
  void refreshAfterSession() => refresh();
}