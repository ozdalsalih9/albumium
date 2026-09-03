import 'dart:math' as math;

enum CinematicBeatKind { prologue, memory, pageTurn, epilogue }

enum CinematicTransitionStyle { pageCurl, warmLightLeak, projectorDip }

class CinematicBeat {
  const CinematicBeat({
    required this.kind,
    required this.from,
    required this.frameCount,
    this.to,
    this.shotVariant = 0,
    this.transitionStyle = CinematicTransitionStyle.pageCurl,
  });

  final CinematicBeatKind kind;
  final int from;
  final int? to;
  final int frameCount;
  final int shotVariant;
  final CinematicTransitionStyle transitionStyle;
}

class CinematicStoryboard {
  const CinematicStoryboard({required this.fps, required this.beats});

  final int fps;
  final List<CinematicBeat> beats;

  int get totalFrames =>
      beats.fold(0, (total, beat) => total + beat.frameCount);

  Duration get duration =>
      Duration(milliseconds: (totalFrames / fps * 1000).round());

  /// Builds a deterministic visual story. Normal albums get relaxed holds;
  /// very long albums automatically tighten their rhythm to stay close to the
  /// 90-second sharing budget instead of producing an unbounded movie.
  factory CinematicStoryboard.forPositions(
    int positionCount, {
    int fps = 30,
    Duration maximumDuration = const Duration(seconds: 90),
  }) {
    assert(positionCount > 0);
    final maxFrames = maximumDuration.inMilliseconds * fps ~/ 1000;
    final prologueFrames = (fps * 1.25).round();
    final epilogueFrames = (fps * 1.4).round();
    final transitionCount = math.max(0, positionCount - 1);
    final interiorMemoryCount = math.max(0, positionCount - 1);

    // The cover already receives its own title sequence. Keeping it on screen
    // for another full memory beat made short exports feel stalled before the
    // first page suddenly opened. Interior spreads deserve the longer hold.
    final relaxedRhythm = positionCount <= 12;
    var coverHoldFrames = (fps * (relaxedRhythm ? .7 : .6)).round();
    var transitionFrames =
        (fps *
                switch (positionCount) {
                  <= 12 => .96,
                  <= 24 => .78,
                  _ => .5,
                })
            .round();
    var holdFrames =
        (fps *
                switch (positionCount) {
                  <= 12 => 1.85,
                  <= 24 => 1.45,
                  _ => 1.1,
                })
            .round();

    final fixedFrames = prologueFrames + epilogueFrames;
    final projected =
        fixedFrames +
        coverHoldFrames +
        interiorMemoryCount * holdFrames +
        transitionCount * transitionFrames;
    if (projected > maxFrames) {
      // Scale every variable beat proportionally. Prefer this over shortening
      // only page turns: sub-half-second turns are the most visible source of
      // stutter in long albums.
      final available = math.max(1, maxFrames - fixedFrames);
      final desiredVariableFrames = math.max(1, projected - fixedFrames);
      final scale = math.min(1.0, available / desiredVariableFrames);
      coverHoldFrames = math.max(1, (coverHoldFrames * scale).floor());
      transitionFrames = math.max(1, (transitionFrames * scale).floor());
      holdFrames = math.max(1, (holdFrames * scale).floor());
    }

    final beats = <CinematicBeat>[
      CinematicBeat(
        kind: CinematicBeatKind.prologue,
        from: 0,
        frameCount: prologueFrames,
      ),
    ];
    for (var position = 0; position < positionCount; position++) {
      beats.add(
        CinematicBeat(
          kind: CinematicBeatKind.memory,
          from: position,
          frameCount: position == 0 ? coverHoldFrames : holdFrames,
          shotVariant: position % 4,
        ),
      );
      if (position < positionCount - 1) {
        beats.add(
          CinematicBeat(
            kind: CinematicBeatKind.pageTurn,
            from: position,
            to: position + 1,
            frameCount: transitionFrames,
            shotVariant: position % 3,
            transitionStyle: switch (position % 3) {
              1 => CinematicTransitionStyle.warmLightLeak,
              2 => CinematicTransitionStyle.projectorDip,
              _ => CinematicTransitionStyle.pageCurl,
            },
          ),
        );
      }
    }
    beats.add(
      CinematicBeat(
        kind: CinematicBeatKind.epilogue,
        from: positionCount - 1,
        frameCount: epilogueFrames,
      ),
    );
    return CinematicStoryboard(fps: fps, beats: beats);
  }
}
