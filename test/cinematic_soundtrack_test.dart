import 'dart:typed_data';

import 'package:albumium/models/cinematic_storyboard.dart';
import 'package:albumium/services/cinematic_soundtrack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CinematicSoundtrack', () {
    test('renders one exact 48 kHz stereo PCM frame at 30 fps', () {
      final storyboard = CinematicStoryboard.forPositions(2);

      final frame = CinematicSoundtrack.pcmFrame(
        storyboard: storyboard,
        frameIndex: storyboard.fps,
        fps: storyboard.fps,
      );

      expect(frame, hasLength(6400));
    });

    test('is deterministic for the same storyboard and global frame', () {
      final storyboard = CinematicStoryboard.forPositions(3);

      final first = CinematicSoundtrack.pcmFrame(
        storyboard: storyboard,
        frameIndex: 48,
        fps: storyboard.fps,
      );
      final second = CinematicSoundtrack.pcmFrame(
        storyboard: storyboard,
        frameIndex: 48,
        fps: storyboard.fps,
      );

      expect(second, orderedEquals(first));
    });

    test('fades at the story ends and adds energy to a page turn', () {
      final storyboard = CinematicStoryboard.forPositions(2);
      final pageTurnStart =
          storyboard.beats.first.frameCount + storyboard.beats[1].frameCount;
      final pageTurnMiddle =
          pageTurnStart + storyboard.beats[2].frameCount ~/ 2;
      final memoryMiddle =
          storyboard.beats.first.frameCount +
          storyboard.beats[1].frameCount ~/ 2;

      final prologueEnergy = _meanSquare(
        CinematicSoundtrack.pcmFrame(
          storyboard: storyboard,
          frameIndex: 0,
          fps: storyboard.fps,
        ),
      );
      final memoryEnergy = _meanSquare(
        CinematicSoundtrack.pcmFrame(
          storyboard: storyboard,
          frameIndex: memoryMiddle,
          fps: storyboard.fps,
        ),
      );
      final turnEnergy = _meanSquare(
        CinematicSoundtrack.pcmFrame(
          storyboard: storyboard,
          frameIndex: pageTurnMiddle,
          fps: storyboard.fps,
        ),
      );
      final epilogueEnergy = _meanSquare(
        CinematicSoundtrack.pcmFrame(
          storyboard: storyboard,
          frameIndex: storyboard.totalFrames - 1,
          fps: storyboard.fps,
        ),
      );

      expect(prologueEnergy, lessThan(memoryEnergy * 0.1));
      expect(epilogueEnergy, lessThan(memoryEnergy * 0.1));
      expect(turnEnergy, greaterThan(memoryEnergy * 1.1));
    });

    test('keeps signed samples comfortably inside the int16 range', () {
      final storyboard = CinematicStoryboard.forPositions(2);
      final pageTurnStart =
          storyboard.beats.first.frameCount + storyboard.beats[1].frameCount;
      final pageTurnMiddle =
          pageTurnStart + storyboard.beats[2].frameCount ~/ 2;
      final bytes = CinematicSoundtrack.pcmFrame(
        storyboard: storyboard,
        frameIndex: pageTurnMiddle,
        fps: storyboard.fps,
      );
      final samples = _samples(bytes);
      final peak = samples.fold<int>(0, (maximum, sample) {
        final magnitude = sample.abs();
        return magnitude > maximum ? magnitude : maximum;
      });

      expect(samples, contains(isNegative));
      expect(samples, contains(isPositive));
      expect(peak, greaterThan(4000));
      expect(peak, lessThan(16000));
    });
  });
}

double _meanSquare(Uint8List bytes) {
  final samples = _samples(bytes);
  return samples
          .map((sample) => sample.toDouble() * sample)
          .reduce((sum, value) => sum + value) /
      samples.length;
}

List<int> _samples(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return [
    for (var offset = 0; offset < bytes.length; offset += 2)
      data.getInt16(offset, Endian.little),
  ];
}
