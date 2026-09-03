import 'package:albumium/models/single_page_export_storyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('single-page export storyboard', () {
    test('shows every album page once and in editor order', () {
      final story = SinglePageExportStoryboard.forPages(5);

      expect(story.pageCount, 5);
      expect(story.holds.map((beat) => beat.fromPage), [0, 1, 2, 3, 4]);
      expect(story.holds.map((beat) => beat.fromSide), [
        SinglePageExportSide.left,
        SinglePageExportSide.right,
        SinglePageExportSide.left,
        SinglePageExportSide.right,
        SinglePageExportSide.left,
      ]);
    });

    test('pans from a left page to the neighbouring right page', () {
      final story = SinglePageExportStoryboard.forPages(4);
      final firstTransition = story.transitions.first;

      expect(firstTransition.kind, SinglePageExportBeatKind.pan);
      expect(firstTransition.fromPage, 0);
      expect(firstTransition.toPage, 1);
      expect(firstTransition.fromSide, SinglePageExportSide.left);
      expect(firstTransition.toSide, SinglePageExportSide.right);
    });

    test('turns from a right page to the following left page', () {
      final story = SinglePageExportStoryboard.forPages(4);
      final transitions = story.transitions.toList();

      expect(transitions[1].kind, SinglePageExportBeatKind.pageTurn);
      expect(transitions[1].fromPage, 1);
      expect(transitions[1].toPage, 2);
      expect(transitions[1].fromSide, SinglePageExportSide.right);
      expect(transitions[1].toSide, SinglePageExportSide.left);
      expect(transitions[2].kind, SinglePageExportBeatKind.pan);
      expect(transitions[2].fromPage, 2);
      expect(transitions[2].toPage, 3);
    });

    test('a single page has one hold and no artificial transition', () {
      final story = SinglePageExportStoryboard.forPages(1);

      expect(story.beats, hasLength(1));
      expect(story.beats.single.kind, SinglePageExportBeatKind.hold);
      expect(story.beats.single.fromPage, 0);
      expect(story.transitions, isEmpty);
      expect(story.totalFrames, greaterThan(0));
    });

    test('an empty album produces an empty, safe timeline', () {
      final story = SinglePageExportStoryboard.forPages(0);

      expect(story.beats, isEmpty);
      expect(story.holds, isEmpty);
      expect(story.transitions, isEmpty);
      expect(story.totalFrames, 0);
      expect(story.duration, Duration.zero);
    });

    test('uses distinct deterministic timing for pan and page turn', () {
      final story = SinglePageExportStoryboard.forPages(
        3,
        fps: 20,
        holdDuration: const Duration(seconds: 1),
        panDuration: const Duration(milliseconds: 500),
        pageTurnDuration: const Duration(milliseconds: 750),
      );
      final transitions = story.transitions.toList();

      expect(story.holds.every((beat) => beat.frameCount == 20), isTrue);
      expect(transitions[0].frameCount, 10);
      expect(transitions[1].frameCount, 15);
      expect(story.totalFrames, 85);
      expect(story.duration, const Duration(milliseconds: 4250));
    });

    test('a 100-page album stays within the default 90-second budget', () {
      final story = SinglePageExportStoryboard.forPages(100);
      final holds = story.holds.toList();
      final pans = story.transitions
          .where((beat) => beat.kind == SinglePageExportBeatKind.pan)
          .toList();
      final turns = story.transitions
          .where((beat) => beat.kind == SinglePageExportBeatKind.pageTurn)
          .toList();

      expect(story.duration, lessThanOrEqualTo(const Duration(seconds: 90)));
      expect(holds, hasLength(100));
      expect(holds.every((beat) => beat.frameCount < story.fps), isTrue);
      expect(
        pans.every((beat) => beat.frameCount >= (story.fps * .45).round()),
        isTrue,
      );
      expect(
        turns.every((beat) => beat.frameCount >= (story.fps * .55).round()),
        isTrue,
      );
    });

    test('rejects invalid page counts and frame rates', () {
      expect(
        () => SinglePageExportStoryboard.forPages(-1),
        throwsArgumentError,
      );
      expect(
        () => SinglePageExportStoryboard.forPages(1, fps: 0),
        throwsArgumentError,
      );
      expect(
        () => SinglePageExportStoryboard.forPages(
          1,
          maximumDuration: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });
}
