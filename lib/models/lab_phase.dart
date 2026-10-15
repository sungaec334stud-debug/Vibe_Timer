/// One of the four structured stages of the 60-Minute Vibe Coding Lab.
/// Ported from `LAB_PHASES` in `src/hooks/useTimer.js`.
class LabPhase {
  const LabPhase({
    required this.id,
    required this.title,
    required this.timeTag,
    required this.startSec,
    required this.endSec,
    required this.tip,
  });

  final String id;
  final String title;

  /// Human readable window, e.g. `10–40 min`.
  final String timeTag;
  final int startSec;
  final int endSec;
  final String tip;

  int get durationSec => endSec - startSec;
}

const List<LabPhase> kLabPhases = <LabPhase>[
  LabPhase(
    id: 'plan',
    title: 'Plan',
    timeTag: '0–10 min',
    startSec: 0,
    endSec: 10 * 60,
    tip: 'Draft your prompt spec: Context, Goal & Constraints',
  ),
  LabPhase(
    id: 'build',
    title: 'Build',
    timeTag: '10–40 min',
    startSec: 10 * 60,
    endSec: 40 * 60,
    tip: 'Iterate with AI, commit often & feed back errors',
  ),
  LabPhase(
    id: 'audit',
    title: 'Audit',
    timeTag: '40–50 min',
    startSec: 40 * 60,
    endSec: 50 * 60,
    tip: 'Security check: OWASP Top 10 & slopsquatting',
  ),
  LabPhase(
    id: 'reflect',
    title: 'Reflect',
    timeTag: '50–60 min',
    startSec: 50 * 60,
    endSec: 60 * 60,
    tip: 'Class Rule: Explain every line before submitting',
  ),
];

/// Ported from `PRESETS` in `src/hooks/useTimer.js`.
class StudyPreset {
  const StudyPreset({
    required this.id,
    required this.label,
    required this.minutes,
  });

  final String id;
  final String label;
  final int minutes;

  bool get isLab => id == 'vibe_lab_60';
}

const List<StudyPreset> kPresets = <StudyPreset>[
  StudyPreset(id: 'vibe_lab_60', label: '⚡ 60m Vibe Lab', minutes: 60),
  StudyPreset(id: 'pomodoro_25', label: '🍅 25m Pomodoro', minutes: 25),
  StudyPreset(id: 'deep_50', label: '🎯 50m Deep Work', minutes: 50),
  StudyPreset(id: 'sprint_15', label: '🚀 15m Sprint', minutes: 15),
  StudyPreset(id: 'custom', label: '⚙️ Custom', minutes: 45),
];

/// Stage label + tip shown under the dial digits. Ported from `TimerDial.jsx`.
({String label, String tip}) stageCopyFor(String presetId, LabPhase? phase) {
  if (presetId == 'vibe_lab_60' && phase != null) {
    return (
      label: 'PHASE: ${phase.title.toUpperCase()} (${phase.timeTag})',
      tip: phase.tip,
    );
  }

  switch (presetId) {
    case 'pomodoro_25':
      return (
        label: 'Pomodoro Focus (25m)',
        tip: 'Work on one task with zero distractions.',
      );
    case 'deep_50':
      return (
        label: 'Deep Work (50m)',
        tip: 'Deep cognitive immersion and code writing.',
      );
    case 'sprint_15':
      return (
        label: 'Review Sprint (15m)',
        tip: 'Audit diffs and test app behavior.',
      );
    default:
      return (
        label: 'Focus Session',
        tip: 'Stay in the flow state.',
      );
  }
}