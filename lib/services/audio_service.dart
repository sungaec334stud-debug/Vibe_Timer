import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Synthesizes and plays the chimes, bells and fanfare.
///
/// The web build drove an `AudioContext` directly (`services/audio.js`).
/// Flutter has no built-in synth, so the same waveforms are rendered here as
/// 16-bit PCM WAV bytes in pure Dart and handed to `audioplayers`.
///
/// Every frequency, delay and gain value below is copied from the original
/// service so the app sounds the same as the React version.
class AudioService {
  AudioService() : _playerCount = 3;

  static const int _sampleRate = 44100;
  static const int _bitsPerSample = 16;
  static const int _channels = 1;
  static const int _headerBytes = 44;

  /// Small pool so overlapping sounds (e.g. a bell while a fanfare plays)
  /// do not cut each other off.
  final int _playerCount;
  final List<AudioPlayer> _players = <AudioPlayer>[];
  int _nextPlayer = 0;

  bool _muted = false;

  bool get isMuted => _muted;

  void restoreMuteState(bool muted) => _muted = muted;

  Future<bool> toggleMute() async {
    _muted = !_muted;
    return _muted;
  }

  // ------------------------------------------------------------------ voices

  /// Tibetan bowl style start tone — 528 Hz sine with a slow decay.
  Future<void> playChime() {
    return _play(
      <_Tone>[
        _Tone.sine(
          frequency: 528.0,
          start: Duration.zero,
          duration: const Duration(milliseconds: 2100),
          attack: const Duration(milliseconds: 40),
          peakGain: 0.28,
          endGain: 0.0001,
        ),
      ],
    );
  }

  /// Stage-transition bell — an E5/A5 fifth, played as triangle waves.
  Future<void> playStageBell() {
    return _play(
      <_Tone>[
        _Tone.triangle(
          frequency: 659.25, // E5
          start: Duration.zero,
          duration: const Duration(milliseconds: 800),
          attack: const Duration(milliseconds: 30),
          peakGain: 0.22,
          endGain: 0.0001,
        ),
        _Tone.triangle(
          frequency: 880.0, // A5
          start: const Duration(milliseconds: 220),
          duration: const Duration(milliseconds: 1300),
          attack: const Duration(milliseconds: 30),
          peakGain: 0.22,
          endGain: 0.0001,
        ),
      ],
    );
  }

  /// Completion fanfare — the C5 → E5 → G5 → C6 arpeggio.
  Future<void> playCompletionFanfare() {
    const List<double> notes = <double>[
      523.25, // C5
      659.25, // E5
      783.99, // G5
      1046.50, // C6
    ];
    return _play(
      <_Tone>[
        for (int i = 0; i < notes.length; i++)
          _Tone.sine(
            frequency: notes[i],
            start: Duration(milliseconds: i * 160),
            duration: const Duration(milliseconds: 1200),
            attack: const Duration(milliseconds: 40),
            peakGain: 0.25,
            endGain: 0.0001,
          ),
      ],
    );
  }

  /// Short UI tick — a fast downward frequency sweep.
  Future<void> playClick() {
    return _play(
      <_Tone>[
        _Tone.triangle(
          frequency: 400.0,
          frequencyEnd: 100.0,
          start: Duration.zero,
          duration: const Duration(milliseconds: 40),
          attack: Duration.zero,
          peakGain: 0.06,
          endGain: 0.001,
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ player

  Future<void> _play(List<_Tone> tones) async {
    if (_muted) return;
    try {
      final bytes = _renderWav(tones);
      final player = _playerAt(_nextPlayer);
      _nextPlayer = (_nextPlayer + 1) % _playerCount;
      await player.stop();
      await player.play(
        BytesSource(bytes),
        mode: PlayerMode.lowLatency,
        volume: 1,
      );
    } catch (_) {
      // Audio is a nicety — never let a playback failure break the timer.
    }
  }

  AudioPlayer _playerAt(int index) {
    while (_players.length <= index) {
      _players.add(AudioPlayer(playerId: 'vibe_sound_$_players.length'));
    }
    return _players[index];
  }

  void dispose() {
    for (final AudioPlayer player in _players) {
      player.dispose();
    }
    _players.clear();
  }

  // ---------------------------------------------------------------- renderer

  /// Mixes [tones] into a single mono 16-bit PCM WAV buffer.
  Uint8List _renderWav(List<_Tone> tones) {
    final int totalSeconds = tones.fold<int>(
      0,
      (max, tone) => math.max(
        max,
        (tone.start.inMicroseconds + tone.duration.inMicroseconds) ~/ 1000000,
      ),
    );
    final int frames = math.max(1, totalSeconds * _sampleRate + 1);
    final Float64List mix = Float64List(frames);

    for (final _Tone tone in tones) {
      final int startFrame =
          (tone.start.inMicroseconds * _sampleRate) ~/ 1000000;
      final int toneFrames =
          (tone.duration.inMicroseconds * _sampleRate) ~/ 1000000;
      final int attackFrames =
          (tone.attack.inMicroseconds * _sampleRate) ~/ 1000000;

      for (int i = 0; i < toneFrames; i++) {
        final int frame = startFrame + i;
        if (frame >= frames) break;

        final double t = i / _sampleRate;
        final double gain = tone.gainAt(t, i, toneFrames, attackFrames);
        if (gain <= 0) continue;

        // Optional exponential frequency sweep (used by the click sound).
        double frequency = tone.frequency;
        if (tone.frequencyEnd != null) {
          final double ratio = tone.frequencyEnd! / tone.frequency;
          frequency = tone.frequency * math.pow(ratio, i / toneFrames).toDouble();
        }

        final double phase = 2 * math.pi * frequency * t;
        final double wave = tone.isTriangle
            ? (2 / math.pi) * math.asin(math.sin(phase))
            : math.sin(phase);

        mix[frame] += wave * gain;
      }
    }

    // Clamp and convert to 16-bit PCM.
    final Uint8List pcm = Uint8List(frames * 2);
    final ByteData view = ByteData.sublistView(pcm);
    for (int i = 0; i < frames; i++) {
      final double clamped = mix[i].clamp(-1.0, 1.0);
      view.setInt16(
        i * 2,
        (clamped * 32767).round(),
        Endian.little,
      );
    }

    return _withWavHeader(pcm, frames);
  }

  Uint8List _withWavHeader(Uint8List pcm, int frames) {
    final int dataBytes = pcm.length;
    final int byteRate = _sampleRate * _channels * _bitsPerSample ~/ 8;
    final int blockAlign = _channels * _bitsPerSample ~/ 8;

    final Uint8List out = Uint8List(_headerBytes + dataBytes);
    final ByteData view = ByteData.sublistView(out);

    void writeAscii(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        view.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    view.setUint32(4, 36 + dataBytes, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // PCM chunk size
    view.setUint16(20, 1, Endian.little); // format = PCM
    view.setUint16(22, _channels, Endian.little);
    view.setUint32(24, _sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, _bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    view.setUint32(40, dataBytes, Endian.little);

    out.setRange(_headerBytes, _headerBytes + dataBytes, pcm);
    return out;
  }
}

/// A single voice in the mix, with a Web-Audio-style gain envelope.
class _Tone {
  const _Tone({
    required this.frequency,
    required this.start,
    required this.duration,
    required this.attack,
    required this.peakGain,
    required this.endGain,
    required this.isTriangle,
    this.frequencyEnd,
  });

  factory _Tone.sine({
    required double frequency,
    required Duration start,
    required Duration duration,
    required Duration attack,
    required double peakGain,
    required double endGain,
  }) => _Tone(
    frequency: frequency,
    start: start,
    duration: duration,
    attack: attack,
    peakGain: peakGain,
    endGain: endGain,
    isTriangle: false,
  );

  factory _Tone.triangle({
    required double frequency,
    required Duration start,
    required Duration duration,
    required Duration attack,
    required double peakGain,
    required double endGain,
    double? frequencyEnd,
  }) => _Tone(
    frequency: frequency,
    start: start,
    duration: duration,
    attack: attack,
    peakGain: peakGain,
    endGain: endGain,
    isTriangle: true,
    frequencyEnd: frequencyEnd,
  );

  final double frequency;
  final double? frequencyEnd;
  final Duration start;
  final Duration duration;
  final Duration attack;
  final double peakGain;
  final double endGain;
  final bool isTriangle;

  static const double _floor = 0.001;

  /// Linear attack followed by an exponential decay — the same shape as
  /// `linearRampToValueAtTime` + `exponentialRampToValueAtTime`.
  double gainAt(double t, int frame, int toneFrames, int attackFrames) {
    if (frame >= toneFrames) return 0;

    if (attackFrames > 0 && frame < attackFrames) {
      final double ratio = peakGain / _floor;
      return _floor * math.pow(ratio, frame / attackFrames).toDouble();
    }

    final int decayFrames = math.max(1, toneFrames - attackFrames);
    final int into = frame - attackFrames;
    final double ratio = endGain / peakGain;
    return peakGain * math.pow(ratio, into / decayFrames).toDouble();
  }
}