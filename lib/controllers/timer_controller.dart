import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/local_store.dart';
import '../models/lab_phase.dart';
import '../models/study_models.dart';
import '../services/audio_service.dart';
import '../services/sync_service.dart';

/// Ported from `src/hooks/useTimer.js`.
///
/// Same 250 ms tick, same wall-clock delta maths, same lab phase detection,
/// and the same automatic session log on completion.
class TimerController extends ChangeNotifier {
  TimerController(this._store, this._audio, [this._sync]);

  final LocalStore _store;
  final AudioService _audio;

  /// Optional cloud mirror for completed sessions. Null in tests and
  /// guest-only builds.
  final SyncService? _sync;

  static const Duration _tickInterval = Duration(milliseconds: 250);

  StudyPreset _preset = kPresets.first;
  double _totalDuration = 3600; // seconds
  double _remainingSeconds = 3600;
  bool _isRunning = false;
  int _phaseIndex = 0;

  DateTime? _lastTick;
  Timer? _ticker;

  /// Called when the timer finishes a session.
  void Function()? onSessionComplete;

  /// Mirrors the `onToast` argument of the original `useTimer` hook.
  void Function(String message)? onToast;

  // ------------------------------------------------------------------ getters

  StudyPreset get preset => _preset;
  bool get isRunning => _isRunning;
  int get phaseIndex => _phaseIndex;
  double get totalDuration => _totalDuration;
  double get remainingSeconds => _remainingSeconds;

  bool get isLabActive => _preset.isLab;
  LabPhase? get currentPhase =>
      isLabActive && _phaseIndex < kLabPhases.length
          ? kLabPhases[_phaseIndex]
          : null;

  /// `MM:SS`, zero padded — same as `timeFormatted` in the React hook.
  String get timeFormatted {
    final int total = _remainingSeconds.ceil().clamp(0, 1 << 31);
    final int mins = total ~/ 60;
    final int secs = total % 60;
    return '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  /// 0.0 → 1.0 elapsed fraction driving the dial ring.
  double get progressFraction {
    if (_totalDuration <= 0) return 0;
    return ((_totalDuration - _remainingSeconds) / _totalDuration).clamp(
      0.0,
      1.0,
    );
  }

  // ------------------------------------------------------------------ actions

  /// Switches preset and resets the clock. Pass [customSeconds] with
  /// [presetId] `custom`.
  void selectPreset(String presetId, {double? customSeconds}) {
    _stopTicker();
    _setRunning(false);
    _preset = kPresets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => kPresets.first,
    );

    double duration = 3600;
    if (presetId == 'custom' && customSeconds != null) {
      duration = math.max(5.0, customSeconds);
    } else {
      duration = _preset.minutes * 60;
    }

    _totalDuration = duration;
    _remainingSeconds = duration;
    _phaseIndex = 0;

    final int mins = duration ~/ 60;
    final int secs = (duration % 60).toInt();
    final String timeStr = secs > 0 ? '$mins m ${secs}s' : '$mins min';
    onToast?.call('Timer set to $timeStr');
    notifyListeners();
  }

  void toggle() {
    if (_isRunning) {
      _setRunning(false);
      _stopTicker();
      _audio.playClick();
    } else {
      _audio.playChime();
      _startTicker();
      _setRunning(true);
    }
    notifyListeners();
  }

  void reset() {
    _stopTicker();
    _setRunning(false);
    _remainingSeconds = _totalDuration;
    _phaseIndex = 0;
    _audio.playClick();
    onToast?.call('Timer reset');
    notifyListeners();
  }

  /// Jumps to the start of the next lab phase (60m lab mode only).
  void skipPhase() {
    if (!isLabActive) return;
    if (_phaseIndex < kLabPhases.length - 1) {
      final int next = _phaseIndex + 1;
      final LabPhase phase = kLabPhases[next];
      _phaseIndex = next;
      _remainingSeconds = _totalDuration - phase.startSec;
      _audio.playStageBell();
      onToast?.call('Skipped to ${phase.title}');
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------- ticker

  void _startTicker() {
    _lastTick = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
    WakelockPlus.enable();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    WakelockPlus.disable();
  }

  void _onTick() {
    final DateTime now = DateTime.now();
    final DateTime last = _lastTick ?? now;
    final double elapsed = now.difference(last).inMicroseconds / 1000000.0;
    _lastTick = now;

    final double next = _remainingSeconds - elapsed;
    if (next <= 0) {
      _remainingSeconds = 0;
      _complete();
      return;
    }

    _remainingSeconds = next;

    // Phase transitions in the 60-minute lab.
    if (isLabActive) {
      final double elapsedSec = _totalDuration - next;
      final int idx = kLabPhases.indexWhere(
        (p) => elapsedSec >= p.startSec && elapsedSec < p.endSec,
      );
      if (idx != -1 && idx != _phaseIndex) {
        _phaseIndex = idx;
        _audio.playStageBell();
      }
    }

    notifyListeners();
  }

  void _complete() {
    _stopTicker();
    _setRunning(false);
    _audio.playCompletionFanfare();

    final int minutes = (_totalDuration / 60).round();
    final StudySession session = _store.addSession(
      mode: _preset.id,
      title: isLabActive ? '60-Minute Vibe Coding Lab' : '$minutes m Focus',
      durationMinutes: minutes,
    );

    final SyncService? sync = _sync;
    if (sync != null) unawaited(sync.pushSession(session));

    onSessionComplete?.call();
    notifyListeners();
  }

  void _setRunning(bool value) {
    if (_isRunning == value) return;
    _isRunning = value;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}