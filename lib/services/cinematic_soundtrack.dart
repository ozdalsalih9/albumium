import 'dart:math' as math;
import 'dart:typed_data';

import '../models/cinematic_storyboard.dart';

/// Produces a balanced, deterministic soundtrack for cinematic album exports.
///
/// Each call returns the audio that belongs to one video frame. The payload is
/// interleaved 48 kHz stereo, signed 16-bit little-endian PCM, which is the
/// format expected by the export encoder.
class CinematicSoundtrack {
  const CinematicSoundtrack._();

  static const int sampleRate = 48000;
  static const int channelCount = 2;
  static const int bytesPerSample = 2;

  static const double _tau = math.pi * 2;
  static const double _padLevel = 0.055;
  static const double _melodyLevel = 0.095;
  static const double _pageNoiseLevel = 0.092;

  static const int _bpm = 75;
  static const int _samplesPerBeat = sampleRate * 60 ~/ _bpm; // 38400 samples
  static const int _cycleBeats = 32;
  static const int _cycleSamples =
      _cycleBeats * _samplesPerBeat; // 1228800 samples (~25.6s)
  static const int _maxNoteSamples =
      sampleRate * 5 ~/ 2; // 120000 samples (2.5s)

  static const List<_MelodyNote> _melodyNotes = [
    // --- Bar 1: C Major (Nostalgic, warm opening) ---
    _MelodyNote(0.0, 130.81, 0.70, pan: 0.35), // C3
    _MelodyNote(0.0, 261.63, 0.65, pan: 0.45), // C4
    _MelodyNote(0.5, 392.00, 0.75, pan: 0.55), // G4
    _MelodyNote(1.0, 523.25, 0.85, pan: 0.60), // C5
    _MelodyNote(1.5, 659.25, 0.90, pan: 0.65), // E5
    _MelodyNote(2.0, 196.00, 0.60, pan: 0.40), // G3
    _MelodyNote(2.0, 523.25, 0.75, pan: 0.55), // C5
    _MelodyNote(2.5, 783.99, 0.95, pan: 0.70), // G5
    _MelodyNote(3.0, 659.25, 0.80, pan: 0.60), // E5
    _MelodyNote(3.5, 587.33, 0.80, pan: 0.55), // D5
    // --- Bar 2: G Major / B (Gentle descent) ---
    _MelodyNote(4.0, 123.47, 0.65, pan: 0.35), // B2
    _MelodyNote(4.0, 246.94, 0.60, pan: 0.45), // B3
    _MelodyNote(4.5, 293.66, 0.70, pan: 0.50), // D4
    _MelodyNote(5.0, 392.00, 0.75, pan: 0.55), // G4
    _MelodyNote(5.5, 587.33, 0.85, pan: 0.65), // D5
    _MelodyNote(6.0, 196.00, 0.60, pan: 0.40), // G3
    _MelodyNote(6.0, 493.88, 0.75, pan: 0.55), // B4
    _MelodyNote(6.5, 659.25, 0.90, pan: 0.65), // E5
    _MelodyNote(7.0, 587.33, 0.80, pan: 0.60), // D5
    _MelodyNote(7.5, 493.88, 0.75, pan: 0.50), // B4
    // --- Bar 3: A Minor (Soulful & emotional reflection) ---
    _MelodyNote(8.0, 110.00, 0.70, pan: 0.35), // A2
    _MelodyNote(8.0, 220.00, 0.65, pan: 0.45), // A3
    _MelodyNote(8.5, 329.63, 0.70, pan: 0.50), // E4
    _MelodyNote(9.0, 440.00, 0.75, pan: 0.55), // A4
    _MelodyNote(9.5, 523.25, 0.85, pan: 0.60), // C5
    _MelodyNote(10.0, 164.81, 0.60, pan: 0.40), // E3
    _MelodyNote(10.0, 659.25, 0.90, pan: 0.70), // E5
    _MelodyNote(10.5, 587.33, 0.80, pan: 0.60), // D5
    _MelodyNote(11.0, 523.25, 0.80, pan: 0.55), // C5
    _MelodyNote(11.5, 440.00, 0.75, pan: 0.50), // A4
    // --- Bar 4: F Major -> Gsus (Hopeful lift) ---
    _MelodyNote(12.0, 87.31, 0.65, pan: 0.30), // F2
    _MelodyNote(12.0, 174.61, 0.65, pan: 0.40), // F3
    _MelodyNote(12.5, 261.63, 0.70, pan: 0.50), // C4
    _MelodyNote(13.0, 349.23, 0.75, pan: 0.55), // F4
    _MelodyNote(13.5, 523.25, 0.85, pan: 0.65), // C5
    _MelodyNote(14.0, 98.00, 0.65, pan: 0.35), // G2
    _MelodyNote(14.0, 293.66, 0.70, pan: 0.45), // D4
    _MelodyNote(14.5, 392.00, 0.80, pan: 0.55), // G4
    _MelodyNote(15.0, 587.33, 0.85, pan: 0.65), // D5
    _MelodyNote(15.5, 783.99, 0.90, pan: 0.75), // G5
    // --- Bar 5: C Major / E (Bright reminiscence) ---
    _MelodyNote(16.0, 164.81, 0.65, pan: 0.35), // E3
    _MelodyNote(16.0, 261.63, 0.65, pan: 0.45), // C4
    _MelodyNote(16.5, 392.00, 0.75, pan: 0.55), // G4
    _MelodyNote(17.0, 523.25, 0.85, pan: 0.60), // C5
    _MelodyNote(17.5, 783.99, 0.95, pan: 0.70), // G5
    _MelodyNote(18.0, 130.81, 0.60, pan: 0.35), // C3
    _MelodyNote(18.0, 659.25, 0.85, pan: 0.65), // E5
    _MelodyNote(18.5, 587.33, 0.80, pan: 0.60), // D5
    _MelodyNote(19.0, 523.25, 0.80, pan: 0.55), // C5
    _MelodyNote(19.5, 659.25, 0.85, pan: 0.65), // E5
    // --- Bar 6: F Major 7 (Lush warmth) ---
    _MelodyNote(20.0, 87.31, 0.65, pan: 0.30), // F2
    _MelodyNote(20.0, 174.61, 0.65, pan: 0.40), // F3
    _MelodyNote(20.5, 261.63, 0.70, pan: 0.50), // C4
    _MelodyNote(21.0, 329.63, 0.75, pan: 0.55), // E4
    _MelodyNote(21.5, 440.00, 0.80, pan: 0.60), // A4
    _MelodyNote(22.0, 220.00, 0.60, pan: 0.45), // A3
    _MelodyNote(22.0, 523.25, 0.85, pan: 0.65), // C5
    _MelodyNote(22.5, 659.25, 0.90, pan: 0.70), // E5
    _MelodyNote(23.0, 523.25, 0.80, pan: 0.60), // C5
    _MelodyNote(23.5, 440.00, 0.75, pan: 0.55), // A4
    // --- Bar 7: D Minor 7 (Soft contemplation) ---
    _MelodyNote(24.0, 146.83, 0.65, pan: 0.35), // D3
    _MelodyNote(24.0, 293.66, 0.65, pan: 0.45), // D4
    _MelodyNote(24.5, 349.23, 0.70, pan: 0.50), // F4
    _MelodyNote(25.0, 440.00, 0.75, pan: 0.55), // A4
    _MelodyNote(25.5, 587.33, 0.85, pan: 0.65), // D5
    _MelodyNote(26.0, 220.00, 0.60, pan: 0.40), // A3
    _MelodyNote(26.0, 659.25, 0.90, pan: 0.70), // E5
    _MelodyNote(26.5, 587.33, 0.80, pan: 0.65), // D5
    _MelodyNote(27.0, 523.25, 0.80, pan: 0.60), // C5
    _MelodyNote(27.5, 440.00, 0.75, pan: 0.50), // A4
    // --- Bar 8: G7 -> C Resolution (Sweet chime resolution) ---
    _MelodyNote(28.0, 98.00, 0.65, pan: 0.35), // G2
    _MelodyNote(28.0, 196.00, 0.65, pan: 0.45), // G3
    _MelodyNote(28.5, 246.94, 0.70, pan: 0.50), // B3
    _MelodyNote(29.0, 293.66, 0.75, pan: 0.55), // D4
    _MelodyNote(29.5, 392.00, 0.80, pan: 0.60), // G4
    _MelodyNote(30.0, 130.81, 0.75, pan: 0.40), // C3
    _MelodyNote(30.0, 261.63, 0.75, pan: 0.50), // C4
    _MelodyNote(30.0, 523.25, 0.90, pan: 0.60), // C5
    _MelodyNote(30.5, 659.25, 0.90, pan: 0.65), // E5
    _MelodyNote(31.0, 783.99, 0.95, pan: 0.70), // G5
    _MelodyNote(31.5, 1046.50, 0.95, pan: 0.75), // C6 crystal chime
  ];

  /// Renders the PCM payload corresponding to [frameIndex].
  static Uint8List pcmFrame({
    required CinematicStoryboard storyboard,
    required int frameIndex,
    required int fps,
  }) {
    if (fps <= 0) {
      throw ArgumentError.value(fps, 'fps', 'Must be greater than zero.');
    }
    if (frameIndex < 0 || frameIndex >= storyboard.totalFrames) {
      throw RangeError.range(
        frameIndex,
        0,
        storyboard.totalFrames - 1,
        'frameIndex',
      );
    }

    final firstSample = frameIndex * sampleRate ~/ fps;
    final nextFrameSample = (frameIndex + 1) * sampleRate ~/ fps;
    final sampleCount = nextFrameSample - firstSample;
    final bytes = Uint8List(sampleCount * channelCount * bytesPerSample);
    final pcm = ByteData.sublistView(bytes);
    final beatPosition = _beatAt(storyboard, frameIndex);

    // Ambient warm bed oscillators
    final rootLeft = _Oscillator.atSample(
      frequency: 55,
      sample: firstSample,
      phase: 0.13,
    );
    final rootRight = _Oscillator.atSample(
      frequency: 55.16,
      sample: firstSample,
      phase: 0.31,
    );
    final fifth = _Oscillator.atSample(
      frequency: 82.41,
      sample: firstSample,
      phase: 0.71,
    );
    final octave = _Oscillator.atSample(
      frequency: 110,
      sample: firstSample,
      phase: 1.17,
    );
    final warmColor = _Oscillator.atSample(
      frequency: 164.81,
      sample: firstSample,
      phase: 2.03,
    );
    final breathing = _Oscillator.atSample(
      frequency: 0.075,
      sample: firstSample,
      phase: -0.4,
    );
    final paperFlutter = _Oscillator.atSample(
      frequency: 6.4 + beatPosition.beat.shotVariant * 0.55,
      sample: firstSample,
      phase: beatPosition.beat.shotVariant * 0.8,
    );

    // Active melody voices for this frame
    final voices = _collectActiveVoices(firstSample, nextFrameSample);

    for (var index = 0; index < sampleCount; index++) {
      final globalSample = firstSample + index;
      final rootL = rootLeft.take();
      final rootR = rootRight.take();
      final fifthTone = fifth.take();
      final octaveTone = octave.take();
      final colorTone = warmColor.take();
      final breath = 0.82 + breathing.take() * 0.12;
      final flutter = 0.82 + paperFlutter.take() * 0.18;

      final frameFraction = (index + 0.5) * fps / sampleCount;
      final beatProgress =
          (frameIndex - beatPosition.startFrame + frameFraction / fps) /
          beatPosition.beat.frameCount;
      final storyEnvelope = _storyEnvelope(
        beatPosition.beat.kind,
        beatProgress,
      );

      // Ambient warm bed
      var left =
          (rootL * 0.42 +
              fifthTone * 0.25 +
              octaveTone * 0.20 +
              colorTone * 0.13) *
          _padLevel *
          breath;
      var right =
          (rootR * 0.42 +
              fifthTone * 0.21 +
              octaveTone * 0.23 +
              colorTone * 0.14) *
          _padLevel *
          breath;

      // Melodic voices (Music Box / Chimes)
      double melodyLeft = 0.0;
      double melodyRight = 0.0;
      for (var v = 0; v < voices.length; v++) {
        final voice = voices[v];
        final sampleVal = voice.sampleAt(globalSample);
        if (sampleVal != 0.0) {
          melodyLeft += sampleVal * (1.0 - 0.40 * voice.pan);
          melodyRight += sampleVal * (0.60 + 0.40 * voice.pan);
        }
      }

      // During page turn, duck the melody slightly to let the tactile paper swoosh pop
      final pageTurnDuck = beatPosition.beat.kind == CinematicBeatKind.pageTurn
          ? (1.0 - 0.28 * _pageTurnEnvelope(beatProgress))
          : 1.0;

      left += melodyLeft * _melodyLevel * pageTurnDuck;
      right += melodyRight * _melodyLevel * pageTurnDuck;

      if (beatPosition.beat.kind == CinematicBeatKind.pageTurn) {
        final pageEnvelope = _pageTurnEnvelope(beatProgress);
        final leftPaper = _paperNoise(globalSample, 0x13579b);
        final rightPaper = _paperNoise(globalSample, 0x5bd1e9);
        final noiseGain = _pageNoiseLevel * pageEnvelope * flutter;
        left += leftPaper * noiseGain;
        right += rightPaper * noiseGain;
      }

      left *= storyEnvelope;
      right *= storyEnvelope;

      final byteOffset = index * channelCount * bytesPerSample;
      pcm.setInt16(byteOffset, _toPcm16(left), Endian.little);
      pcm.setInt16(byteOffset + bytesPerSample, _toPcm16(right), Endian.little);
    }

    return bytes;
  }

  static List<_ActiveMelodyVoice> _collectActiveVoices(
    int firstSample,
    int nextFrameSample,
  ) {
    final voices = <_ActiveMelodyVoice>[];
    final minSample = firstSample - _maxNoteSamples;
    final maxSample = nextFrameSample;
    final firstCycle = minSample ~/ _cycleSamples;
    final lastCycle = maxSample ~/ _cycleSamples;

    for (var cycle = firstCycle; cycle <= lastCycle; cycle++) {
      final cycleOffset = cycle * _cycleSamples;
      for (var i = 0; i < _melodyNotes.length; i++) {
        final note = _melodyNotes[i];
        final noteStart =
            cycleOffset + (note.beatOffset * _samplesPerBeat).round();
        if (noteStart >= minSample && noteStart < maxSample) {
          voices.add(
            _ActiveMelodyVoice(
              startSample: noteStart,
              frequency: note.frequency,
              gain: note.gain,
              pan: note.pan,
              initialSample: firstSample,
            ),
          );
        }
      }
    }
    return voices;
  }

  static ({CinematicBeat beat, int startFrame}) _beatAt(
    CinematicStoryboard storyboard,
    int frameIndex,
  ) {
    var startFrame = 0;
    for (final beat in storyboard.beats) {
      if (frameIndex < startFrame + beat.frameCount) {
        return (beat: beat, startFrame: startFrame);
      }
      startFrame += beat.frameCount;
    }
    throw StateError('Storyboard contains no beat for frame $frameIndex.');
  }

  static double _storyEnvelope(CinematicBeatKind kind, double progress) {
    final position = progress.clamp(0.0, 1.0);
    return switch (kind) {
      CinematicBeatKind.prologue => _smoothstep(position),
      CinematicBeatKind.epilogue => _smoothstep(1 - position),
      _ => 1,
    };
  }

  static double _pageTurnEnvelope(double progress) {
    // A compact, rounded pulse: quiet at both cuts and strongest just after
    // the visual transition's midpoint.
    final position = ((progress - 0.10) / 0.84).clamp(0.0, 1.0);
    final arch = 4 * position * (1 - position);
    return arch * arch;
  }

  static double _smoothstep(double value) => value * value * (3 - 2 * value);

  static double _paperNoise(int sample, int seed) {
    return _noise(sample, seed) * 0.58 +
        _noise(sample - 1, seed) * 0.28 +
        _noise(sample - 2, seed) * 0.14;
  }

  static double _noise(int sample, int seed) {
    var value = (sample ^ seed) & 0xffffffff;
    value = ((value ^ (value >>> 16)) * 0x45d9f3b) & 0xffffffff;
    value = ((value ^ (value >>> 16)) * 0x45d9f3b) & 0xffffffff;
    value ^= value >>> 16;
    return (value & 0xffff) / 32767.5 - 1;
  }

  static int _toPcm16(double sample) {
    final safeSample = sample.clamp(-0.24, 0.24);
    return (safeSample * 32767).round();
  }
}

class _MelodyNote {
  const _MelodyNote(
    this.beatOffset,
    this.frequency,
    this.gain, {
    this.pan = 0.5,
  });
  final double beatOffset;
  final double frequency;
  final double gain;
  final double pan;
}

class _ActiveMelodyVoice {
  _ActiveMelodyVoice({
    required this.startSample,
    required this.frequency,
    required this.gain,
    required this.pan,
    required int initialSample,
  }) {
    final elapsed = initialSample - startSample;
    if (elapsed >= 0) {
      final dt = elapsed / CinematicSoundtrack.sampleRate;
      decay1 = math.exp(-dt * 1.15);
      decay2 = math.exp(-dt * 2.20);
      decay3 = math.exp(-dt * 3.80);
      osc1 = _Oscillator.atSample(
        frequency: frequency,
        sample: elapsed,
        phase: 0,
      );
      osc2 = _Oscillator.atSample(
        frequency: frequency * 2,
        sample: elapsed,
        phase: 0.2,
      );
      osc3 = _Oscillator.atSample(
        frequency: frequency * 2.756,
        sample: elapsed,
        phase: 0.5,
      );
    }
  }

  final int startSample;
  final double frequency;
  final double gain;
  final double pan;

  double decay1 = 1.0;
  double decay2 = 1.0;
  double decay3 = 1.0;
  _Oscillator? osc1;
  _Oscillator? osc2;
  _Oscillator? osc3;

  static const double step1 = 0.999976; // exp(-1.15 / 48000)
  static const double step2 = 0.999954; // exp(-2.20 / 48000)
  static const double step3 = 0.999921; // exp(-3.80 / 48000)

  double sampleAt(int sample) {
    final elapsed = sample - startSample;
    if (elapsed < 0 || elapsed >= CinematicSoundtrack._maxNoteSamples) {
      return 0.0;
    }

    if (osc1 == null) {
      final dt = elapsed / CinematicSoundtrack.sampleRate;
      decay1 = math.exp(-dt * 1.15);
      decay2 = math.exp(-dt * 2.20);
      decay3 = math.exp(-dt * 3.80);
      osc1 = _Oscillator.atSample(
        frequency: frequency,
        sample: elapsed,
        phase: 0,
      );
      osc2 = _Oscillator.atSample(
        frequency: frequency * 2,
        sample: elapsed,
        phase: 0.2,
      );
      osc3 = _Oscillator.atSample(
        frequency: frequency * 2.756,
        sample: elapsed,
        phase: 0.5,
      );
    }

    final o1 = osc1!.take();
    final o2 = osc2!.take();
    final o3 = osc3!.take();

    decay1 *= step1;
    decay2 *= step2;
    decay3 *= step3;

    // 4ms (192 samples) linear anti-click attack
    final attack = elapsed < 192 ? (elapsed / 192.0) : 1.0;

    return attack *
        gain *
        (o1 * 0.58 * decay1 + o2 * 0.24 * decay2 + o3 * 0.18 * decay3);
  }
}

class _Oscillator {
  _Oscillator({
    required this.sine,
    required this.cosine,
    required this.sineStep,
    required this.cosineStep,
  });

  factory _Oscillator.atSample({
    required double frequency,
    required int sample,
    required double phase,
  }) {
    final angle =
        CinematicSoundtrack._tau *
            frequency *
            (sample + 0.5) /
            CinematicSoundtrack.sampleRate +
        phase;
    final step =
        CinematicSoundtrack._tau * frequency / CinematicSoundtrack.sampleRate;
    return _Oscillator(
      sine: math.sin(angle),
      cosine: math.cos(angle),
      sineStep: math.sin(step),
      cosineStep: math.cos(step),
    );
  }

  double sine;
  double cosine;
  final double sineStep;
  final double cosineStep;

  double take() {
    final result = sine;
    final previousSine = sine;
    sine = previousSine * cosineStep + cosine * sineStep;
    cosine = cosine * cosineStep - previousSine * sineStep;
    return result;
  }
}
