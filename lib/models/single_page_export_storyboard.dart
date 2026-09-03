/// The physical side represented by an album page in the single-page export.
enum SinglePageExportSide { left, right }

/// A still page or one of the two deliberately simple page transitions.
enum SinglePageExportBeatKind { hold, pan, pageTurn }

/// One deterministic beat in the single-page MP4 timeline.
///
/// A [hold] has no [toPage] or [toSide]. During [pan] and [pageTurn], both
/// pages are known but the renderer must still crop the result to one page.
class SinglePageExportBeat {
  const SinglePageExportBeat({
    required this.kind,
    required this.fromPage,
    required this.fromSide,
    required this.frameCount,
    this.toPage,
    this.toSide,
  });

  final SinglePageExportBeatKind kind;
  final int fromPage;
  final SinglePageExportSide fromSide;
  final int? toPage;
  final SinglePageExportSide? toSide;
  final int frameCount;

  bool get isTransition => kind != SinglePageExportBeatKind.hold;
}

/// A minimal export timeline that always presents one editor-sized page.
///
/// Pages alternate between physical left and right sides. Moving from a left
/// page to its neighbouring right page is a horizontal pan. Moving from that
/// right page to the next left page is a page turn. The pattern repeats until
/// every page has been shown exactly once.
class SinglePageExportStoryboard {
  const SinglePageExportStoryboard({
    required this.fps,
    required this.pageCount,
    required this.beats,
  });

  final int fps;
  final int pageCount;
  final List<SinglePageExportBeat> beats;

  int get totalFrames =>
      beats.fold(0, (total, beat) => total + beat.frameCount);

  Duration get duration => fps <= 0
      ? Duration.zero
      : Duration(milliseconds: (totalFrames / fps * 1000).round());

  Iterable<SinglePageExportBeat> get holds =>
      beats.where((beat) => beat.kind == SinglePageExportBeatKind.hold);

  Iterable<SinglePageExportBeat> get transitions =>
      beats.where((beat) => beat.isTransition);

  factory SinglePageExportStoryboard.forPages(
    int pageCount, {
    int fps = 30,
    Duration holdDuration = const Duration(milliseconds: 1350),
    Duration panDuration = const Duration(milliseconds: 700),
    Duration pageTurnDuration = const Duration(milliseconds: 850),
    Duration maximumDuration = const Duration(seconds: 90),
  }) {
    if (pageCount < 0) {
      throw ArgumentError.value(
        pageCount,
        'pageCount',
        'Sayfa sayısı negatif olamaz.',
      );
    }
    if (fps <= 0) {
      throw ArgumentError.value(fps, 'fps', 'FPS sıfırdan büyük olmalı.');
    }
    if (maximumDuration <= Duration.zero) {
      throw ArgumentError.value(
        maximumDuration,
        'maximumDuration',
        'Azami süre sıfırdan büyük olmalı.',
      );
    }

    int framesFor(Duration duration) =>
        (duration.inMicroseconds * fps / Duration.microsecondsPerSecond)
            .round()
            .clamp(1, 1 << 30);

    if (pageCount == 0) {
      return SinglePageExportStoryboard(
        fps: fps,
        pageCount: 0,
        beats: const [],
      );
    }

    final maximumFrames =
        maximumDuration.inMicroseconds * fps ~/ Duration.microsecondsPerSecond;
    final transitionCount = pageCount - 1;
    final panCount = (transitionCount + 1) ~/ 2;
    final pageTurnCount = transitionCount ~/ 2;
    final minimumTimelineFrames = pageCount + transitionCount;
    if (minimumTimelineFrames > maximumFrames) {
      throw ArgumentError.value(
        maximumDuration,
        'maximumDuration',
        '$pageCount sayfayı $fps FPS ile göstermek için çok kısa.',
      );
    }

    var holdFrames = framesFor(holdDuration);
    var panFrames = framesFor(panDuration);
    var pageTurnFrames = framesFor(pageTurnDuration);
    final minimumPanFrames = framesFor(const Duration(milliseconds: 450));
    final minimumPageTurnFrames = framesFor(const Duration(milliseconds: 550));

    int projectedFrames() =>
        pageCount * holdFrames +
        panCount * panFrames +
        pageTurnCount * pageTurnFrames;

    if (projectedFrames() > maximumFrames) {
      // The motion is more noticeable than a still-page hold, so consume the
      // budget by shortening holds first. All pages retain at least one frame.
      final framesAfterFullTransitions =
          maximumFrames - panCount * panFrames - pageTurnCount * pageTurnFrames;
      if (framesAfterFullTransitions >= pageCount) {
        holdFrames = framesAfterFullTransitions ~/ pageCount;
      } else {
        holdFrames = 1;
        final transitionBudget = maximumFrames - pageCount;
        final preferredMinimumFrames =
            panCount * minimumPanFrames + pageTurnCount * minimumPageTurnFrames;

        if (preferredMinimumFrames <= transitionBudget) {
          // Keep pans near 0.45 s and turns near 0.55 s, then share any spare
          // frames proportionally up to their relaxed defaults.
          final desiredExtraFrames =
              panCount * (panFrames - minimumPanFrames) +
              pageTurnCount * (pageTurnFrames - minimumPageTurnFrames);
          final availableExtraFrames =
              transitionBudget - preferredMinimumFrames;
          final scale = desiredExtraFrames <= 0
              ? 0.0
              : (availableExtraFrames / desiredExtraFrames).clamp(0.0, 1.0);
          panFrames =
              minimumPanFrames +
              ((panFrames - minimumPanFrames) * scale).floor();
          pageTurnFrames =
              minimumPageTurnFrames +
              ((pageTurnFrames - minimumPageTurnFrames) * scale).floor();
        } else {
          // An exceptionally long album cannot preserve the preferred motion
          // minimums. Scale both transition types together, never below one
          // frame, so the timeline remains valid and inside its hard budget.
          final scale = transitionBudget / preferredMinimumFrames;
          panFrames = (minimumPanFrames * scale).floor().clamp(
            1,
            minimumPanFrames,
          );
          pageTurnFrames = (minimumPageTurnFrames * scale).floor().clamp(
            1,
            minimumPageTurnFrames,
          );
          while (projectedFrames() > maximumFrames) {
            if (pageTurnFrames > panFrames && pageTurnFrames > 1) {
              pageTurnFrames--;
            } else if (panFrames > 1) {
              panFrames--;
            } else if (pageTurnFrames > 1) {
              pageTurnFrames--;
            } else {
              break;
            }
          }
        }
      }
    }
    final beats = <SinglePageExportBeat>[];

    for (var page = 0; page < pageCount; page++) {
      final side = page.isEven
          ? SinglePageExportSide.left
          : SinglePageExportSide.right;
      beats.add(
        SinglePageExportBeat(
          kind: SinglePageExportBeatKind.hold,
          fromPage: page,
          fromSide: side,
          frameCount: holdFrames,
        ),
      );

      final nextPage = page + 1;
      if (nextPage >= pageCount) continue;

      final nextSide = nextPage.isEven
          ? SinglePageExportSide.left
          : SinglePageExportSide.right;
      final kind = side == SinglePageExportSide.left
          ? SinglePageExportBeatKind.pan
          : SinglePageExportBeatKind.pageTurn;
      beats.add(
        SinglePageExportBeat(
          kind: kind,
          fromPage: page,
          fromSide: side,
          toPage: nextPage,
          toSide: nextSide,
          frameCount: kind == SinglePageExportBeatKind.pan
              ? panFrames
              : pageTurnFrames,
        ),
      );
    }

    return SinglePageExportStoryboard(
      fps: fps,
      pageCount: pageCount,
      beats: List.unmodifiable(beats),
    );
  }
}
