import 'package:albumium/models/cinematic_storyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('storyboard has a prologue, memories, transitions and epilogue', () {
    final story = CinematicStoryboard.forPositions(4);

    expect(story.fps, 30);
    expect(story.beats.first.kind, CinematicBeatKind.prologue);
    expect(story.beats.last.kind, CinematicBeatKind.epilogue);
    expect(
      story.beats.where((beat) => beat.kind == CinematicBeatKind.memory),
      hasLength(4),
    );
    expect(
      story.beats.where((beat) => beat.kind == CinematicBeatKind.pageTurn),
      hasLength(3),
    );
    expect(
      story.beats
          .where((beat) => beat.kind == CinematicBeatKind.pageTurn)
          .map((beat) => beat.transitionStyle)
          .toSet(),
      containsAll(CinematicTransitionStyle.values),
    );
  });

  test('short albums open smoothly instead of holding on the cover', () {
    final story = CinematicStoryboard.forPositions(4);
    final memories = story.beats
        .where((beat) => beat.kind == CinematicBeatKind.memory)
        .toList();
    final transitions = story.beats
        .where((beat) => beat.kind == CinematicBeatKind.pageTurn)
        .toList();

    expect(memories.first.from, 0);
    expect(memories.first.frameCount, lessThan(memories[1].frameCount));
    expect(memories.first.frameCount, closeTo(story.fps * .7, 1));
    expect(memories[1].frameCount, closeTo(story.fps * 1.85, 1));
    expect(transitions.first.frameCount, closeTo(story.fps * .96, 1));
  });

  test('long albums stay within the sharing duration budget', () {
    final story = CinematicStoryboard.forPositions(100);

    expect(story.duration, lessThanOrEqualTo(const Duration(seconds: 90)));
    expect(story.totalFrames, greaterThan(0));
  });

  test('the same album always gets the same visual rhythm', () {
    final first = CinematicStoryboard.forPositions(14);
    final second = CinematicStoryboard.forPositions(14);

    expect(first.totalFrames, second.totalFrames);
    expect(
      first.beats.map(
        (beat) => (
          beat.kind,
          beat.from,
          beat.to,
          beat.frameCount,
          beat.shotVariant,
          beat.transitionStyle,
        ),
      ),
      second.beats.map(
        (beat) => (
          beat.kind,
          beat.from,
          beat.to,
          beat.frameCount,
          beat.shotVariant,
          beat.transitionStyle,
        ),
      ),
    );
  });
}
