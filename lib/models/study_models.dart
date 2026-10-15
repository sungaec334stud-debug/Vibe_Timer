/// A completed focus session.
///
/// Replaces a row of `backend/data/store.json` → `sessions[]`.
class StudySession {
  const StudySession({
    required this.id,
    required this.mode,
    required this.title,
    required this.durationMinutes,
    required this.completedAt,
    this.notes,
  });

  final String id;
  final String mode;
  final String title;
  final int durationMinutes;
  final DateTime completedAt;
  final String? notes;

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String? ?? '',
      mode: json['mode'] as String? ?? 'custom',
      title: json['title'] as String? ?? 'Focus Session',
      durationMinutes: _toInt(json['durationMinutes']),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'mode': mode,
    'title': title,
    'durationMinutes': durationMinutes,
    'completedAt': completedAt.toIso8601String(),
    if (notes != null) 'notes': notes,
  };
}

/// A logged prompt iteration or pasted error traceback.
///
/// Replaces a row of `backend/data/store.json` → `prompts[]`.
class PromptLog {
  const PromptLog({
    required this.id,
    required this.phase,
    required this.text,
    required this.timestamp,
    this.outcome,
  });

  final String id;
  final String phase;
  final String text;
  final DateTime timestamp;
  final String? outcome;

  factory PromptLog.fromJson(Map<String, dynamic> json) {
    return PromptLog(
      id: json['id'] as String? ?? '',
      phase: json['phase'] as String? ?? 'build',
      text: json['text'] as String? ?? '',
      outcome: json['outcome'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'phase': phase,
    'text': text,
    if (outcome != null) 'outcome': outcome,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Aggregate metrics — the direct equivalent of `db.getStats()`.
class StudyStats {
  const StudyStats({
    this.totalMinutes = 0,
    this.totalSessions = 0,
    this.totalPrompts = 0,
    this.lastSession,
  });

  final int totalMinutes;
  final int totalSessions;
  final int totalPrompts;
  final StudySession? lastSession;
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}