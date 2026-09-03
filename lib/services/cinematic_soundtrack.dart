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
  // The previous mix peaked around -22 dBFS after AAC encoding and was barely
  // audible on phone speakers. These levels retain generous headroom while
  // bringing the ambient bed and paper turn into a practical listening range.
  static const double _padLevel = 0.104;
  static const double _pageNoiseLevel = 0.078;

  /// Renders the PCM payload corresponding to [frameIndex].
  ///
  /// Sample boundaries are derived from the global frame index instead of
  /// rounding a fixed samples-per-frame value. This keeps audio and video in
  /// lockstep even when [sampleRate] is not evenly divisible by [fps].
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

    // Oscillators are advanced recursively inside the frame. Only their
    // starting phases need trigonometric calls, keeping long exports cheap.
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

    for (var index = 0; index < sampleCount; index++) {
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

      if (beatPosition.beat.kind == CinematicBeatKind.pageTurn) {
        final pageEnvelope = _pageTurnEnvelope(beatProgress);
        final globalSample = firstSample + index;
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
    // A short deterministic FIR filter turns hash noise into a softer paper
    // texture without keeping mutable state between video frames.
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
    // The synthesis peaks well below this guard; keeping headroom also avoids
    // encoder-side clipping when clips are concatenated.
    final safeSample = sample.clamp(-0.24, 0.24);
    return (safeSample * 32767).round();
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
