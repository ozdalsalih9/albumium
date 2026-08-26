import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/album_models.dart';
import 'album_cover.dart';
import 'album_page_canvas.dart';

/// A short, self-contained transition from a closed album to its first page.
///
/// The animation keeps the book in a mostly top-down composition while using
/// perspective, a moving key light and a hinged cover to give it physical
/// depth. When the platform requests reduced motion, the widget renders the
/// final open state immediately and still invokes [onCompleted].
class CinematicAlbumOpening extends StatefulWidget {
  const CinematicAlbumOpening({
    super.key,
    required this.album,
    this.onCompleted,
    this.duration = const Duration(milliseconds: 1950),
    this.reducedMotion,
    this.backgroundColor = const Color(0xFF171310),
  });

  final AlbumModel album;
  final VoidCallback? onCompleted;

  /// Kept intentionally short so the sequence feels like a transition rather
  /// than an intro screen. Values are clamped to 1.6–2.2 seconds.
  final Duration duration;

  /// Overrides the platform accessibility preference when non-null.
  final bool? reducedMotion;

  /// The stage color behind the book. Use [Colors.transparent] when placing
  /// the sequence over an existing background.
  final Color backgroundColor;

  @override
  State<CinematicAlbumOpening> createState() => _CinematicAlbumOpeningState();
}

class _CinematicAlbumOpeningState extends State<CinematicAlbumOpening>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _reduceMotion = false;
  bool _completionScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.duration),
    )..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final platformReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final nextReducedMotion = widget.reducedMotion ?? platformReducedMotion;

    if (!_started) {
      _started = true;
      _reduceMotion = nextReducedMotion;
      _startSequence();
      return;
    }

    if (_reduceMotion != nextReducedMotion) {
      _reduceMotion = nextReducedMotion;
      if (_reduceMotion) {
        _controller.value = 1;
      } else if (_controller.value < 1) {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant CinematicAlbumOpening oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = _effectiveDuration(widget.duration);
    }

    if (oldWidget.album.id != widget.album.id) {
      _completionScheduled = false;
      _reduceMotion =
          widget.reducedMotion ??
          (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
      _startSequence();
    } else if (oldWidget.reducedMotion != widget.reducedMotion) {
      final platformReducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      _reduceMotion = widget.reducedMotion ?? platformReducedMotion;
      if (_reduceMotion) {
        _controller.value = 1;
      } else if (_controller.value < 1) {
        _controller.forward();
      }
    }
  }

  void _startSequence() {
    _controller.stop();
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _completionScheduled) {
      return;
    }
    _completionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(widget.album.themeId);
    final title = widget.album.title.trim().isEmpty
        ? 'İsimsiz Albüm'
        : widget.album.title.trim();

    return Semantics(
      container: true,
      image: true,
      label: '$title albümü açılıyor',
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mediaSize =
                MediaQuery.maybeSizeOf(context) ?? const Size(390, 844);
            final stageWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : mediaSize.width;
            final stageHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : mediaSize.height;

            return SizedBox(
              width: stageWidth,
              height: stageHeight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final progress = _controller.value;
                  return CustomPaint(
                    painter: _CinematicBackdropPainter(
                      progress: progress,
                      backgroundColor: widget.backgroundColor,
                      accentColor: theme.accent,
                    ),
                    child: _AlbumStage(
                      album: widget.album,
                      progress: progress,
                      width: stageWidth,
                      height: stageHeight,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlbumStage extends StatelessWidget {
  const _AlbumStage({
    required this.album,
    required this.progress,
    required this.width,
    required this.height,
  });

  final AlbumModel album;
  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const pageAspectRatio = 0.68;
    final pageHeight = math.max(1.0, math.min(height * 0.64, width * 0.62));
    final pageWidth = pageHeight * pageAspectRatio;
    final spreadWidth = pageWidth * 2;
    final theme = themeById(album.themeId);

    final approach = _interval(progress, 0, 0.32, Curves.easeOutCubic);
    final reframe = _interval(progress, 0.08, 0.78, Curves.easeInOutCubic);
    final opening = _interval(progress, 0.25, 0.9, Curves.easeInOutCubic);
    final settle = _interval(progress, 0.72, 1, Curves.easeOutCubic);
    final reveal = _interval(progress, 0, 0.12, Curves.easeOut);

    final approachScale = _lerp(0.81, 1.035, approach);
    final cameraScale = _lerp(approachScale, 1, settle);
    final cameraOffset = Offset(
      _lerp(-pageWidth * 0.49, 0, reframe),
      _lerp(pageHeight * 0.055, 0, approach),
    );
    final tiltX = _lerp(0.105, 0.042, approach);
    final tiltY = _lerp(-0.032, -0.015, settle);
    final rotationZ = _lerp(-0.045, -0.012, reframe);
    final coverAngle = math.pi * 0.985 * opening;

    return ClipRect(
      child: Opacity(
        opacity: reveal,
        child: Center(
          child: Transform.translate(
            offset: cameraOffset,
            child: Transform.scale(
              scale: cameraScale,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY)
                  ..rotateZ(rotationZ),
                child: SizedBox(
                  width: spreadWidth,
                  height: pageHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _BookShadowPainter(
                              opening: opening,
                              color: theme.coverEnd,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: pageWidth,
                        top: 0,
                        width: pageWidth,
                        height: pageHeight,
                        child: _FirstPage(album: album, reveal: opening),
                      ),
                      Positioned(
                        left: pageWidth - 1,
                        top: pageHeight * 0.012,
                        width: 7,
                        height: pageHeight * 0.976,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.32),
                                  theme.coverEnd.withValues(alpha: 0.16),
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.28, 0.54, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: pageWidth,
                        top: 0,
                        width: pageWidth,
                        height: pageHeight,
                        child: IgnorePointer(
                          child: _TurningCoverShadow(opening: opening),
                        ),
                      ),
                      Positioned(
                        left: pageWidth,
                        top: -math.sin(math.pi * opening) * pageHeight * 0.012,
                        width: pageWidth,
                        height: pageHeight,
                        child: _HingedCover(
                          album: album,
                          angle: coverAngle,
                          lightProgress: progress,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FirstPage extends StatelessWidget {
  const _FirstPage({required this.album, required this.reveal});

  final AlbumModel album;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    final pageColor = album.pages.isEmpty
        ? theme.pageColor
        : Color(album.pages.first.backgroundColor);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 3,
          right: -5,
          top: 4,
          bottom: -7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(pageColor, const Color(0xFFB7AA97), 0.18),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(8, 10),
                ),
              ],
            ),
            child: CustomPaint(painter: const _PaperEdgesPainter()),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pageColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: album.pages.isEmpty
                  ? const SizedBox.expand()
                  : AlbumPageCanvas(page: album.pages.first, theme: theme),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: _lerp(0.2, 0.08, reveal)),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.06 * reveal),
                  ],
                  stops: const [0, 0.19, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HingedCover extends StatelessWidget {
  const _HingedCover({
    required this.album,
    required this.angle,
    required this.lightProgress,
  });

  final AlbumModel album;
  final double angle;
  final double lightProgress;

  @override
  Widget build(BuildContext context) {
    final showingInside = angle > math.pi / 2;
    Widget face = showingInside
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: _InsideCover(album: album),
          )
        : _FrontCover(album: album, lightProgress: lightProgress);

    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        // Positive Y rotation carries the right-hand cover out toward the
        // viewer and then across to the left. The negative direction makes it
        // visually sink through the paper block.
        ..rotateY(angle),
      child: face,
    );
  }
}

class _FrontCover extends StatelessWidget {
  const _FrontCover({required this.album, required this.lightProgress});

  final AlbumModel album;
  final double lightProgress;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 3,
          right: -4,
          top: 3,
          bottom: -5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(theme.coverEnd, Colors.black, 0.32),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.13),
              width: 0.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 18,
                offset: Offset(7, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: AlbumCover(album: album, compact: true),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 18,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  bottomLeft: Radius.circular(9),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.13),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.32, 0.65, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: _LightSweep(
                progress: _interval(
                  lightProgress,
                  0.02,
                  0.58,
                  Curves.easeInOut,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsideCover extends StatelessWidget {
  const _InsideCover({required this.album});

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    final lining = Color.lerp(theme.pageColor, theme.coverStart, 0.14)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(theme.coverEnd, Colors.black, 0.28),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(-7, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: lining,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.18),
              width: 0.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.12),
                lining,
                Color.lerp(lining, Colors.white, 0.08)!,
              ],
              stops: const [0, 0.16, 1],
            ),
          ),
          child: CustomPaint(
            painter: _LiningTexturePainter(
              color: theme.accent.withValues(alpha: 0.055),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurningCoverShadow extends StatelessWidget {
  const _TurningCoverShadow({required this.opening});

  final double opening;

  @override
  Widget build(BuildContext context) {
    final shadowStrength = math.sin(math.pi * opening).clamp(0.0, 1.0);
    final shadowReach = _lerp(0.18, 0.86, shadowStrength);

    return Opacity(
      opacity: shadowStrength * 0.72,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: shadowReach,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
              ],
              stops: const [0, 0.38, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _LightSweep extends StatelessWidget {
  const _LightSweep({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bandWidth = constraints.maxWidth * 0.38;
        final left = _lerp(
          -bandWidth * 1.4,
          constraints.maxWidth * 1.1,
          progress,
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: -constraints.maxHeight * 0.2,
              width: bandWidth,
              height: constraints.maxHeight * 1.4,
              child: Transform.rotate(
                angle: -0.18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.045),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.22, 0.5, 0.78, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CinematicBackdropPainter extends CustomPainter {
  const _CinematicBackdropPainter({
    required this.progress,
    required this.backgroundColor,
    required this.accentColor,
  });

  final double progress;
  final Color backgroundColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final lightCenter = Alignment(
      _lerp(-0.72, 0.46, progress),
      _lerp(-0.9, -0.42, progress),
    );
    final lightRect = Rect.fromCenter(
      center: lightCenter.alongSize(size),
      width: size.longestSide * 1.55,
      height: size.longestSide * 1.55,
    );
    final lightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(accentColor, Colors.white, 0.42)!.withValues(alpha: 0.18),
          accentColor.withValues(alpha: 0.065),
          Colors.transparent,
        ],
        stops: const [0, 0.38, 1],
      ).createShader(lightRect);
    canvas.drawRect(Offset.zero & size, lightPaint);

    final random = math.Random(5187);
    final dustPaint = Paint();
    for (var index = 0; index < 18; index++) {
      final baseX = random.nextDouble();
      final baseY = random.nextDouble();
      final drift = math.sin(progress * math.pi * 2 + index) * 5;
      dustPaint.color = Color.lerp(
        accentColor,
        Colors.white,
        0.7,
      )!.withValues(alpha: 0.025 + random.nextDouble() * 0.035);
      canvas.drawCircle(
        Offset(baseX * size.width + drift, baseY * size.height - drift * 0.5),
        0.35 + random.nextDouble() * 0.7,
        dustPaint,
      );
    }

    final vignettePaint = Paint()
      ..shader = const RadialGradient(
        radius: 0.9,
        colors: [Colors.transparent, Color(0x66000000)],
        stops: [0.56, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _CinematicBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.accentColor != accentColor;
  }
}

class _BookShadowPainter extends CustomPainter {
  const _BookShadowPainter({required this.opening, required this.color});

  final double opening;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = _lerp(size.width * 0.72, size.width * 0.5, opening);
    final shadowWidth = _lerp(size.width * 0.58, size.width * 1.02, opening);
    final rect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.93),
      width: shadowWidth,
      height: size.height * 0.19,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.42)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.045);
    canvas.drawOval(rect, shadowPaint);

    final bouncePaint = Paint()
      ..color = color.withValues(alpha: 0.11)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.07);
    canvas.drawOval(rect.translate(0, size.height * 0.025), bouncePaint);
  }

  @override
  bool shouldRepaint(covariant _BookShadowPainter oldDelegate) {
    return oldDelegate.opening != opening || oldDelegate.color != color;
  }
}

class _PaperEdgesPainter extends CustomPainter {
  const _PaperEdgesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.45
      ..color = const Color(0x384C4034);
    for (double y = 4; y < size.height; y += 4) {
      canvas.drawLine(
        Offset(size.width - 6, y),
        Offset(size.width, y + 0.7),
        paint,
      );
    }
    for (double x = 7; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, size.height - 4),
        Offset(x + 7, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiningTexturePainter extends CustomPainter {
  const _LiningTexturePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.45;
    for (double x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiningTexturePainter oldDelegate) =>
      oldDelegate.color != color;
}

double _interval(double value, double begin, double end, Curve curve) {
  final normalized = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(normalized);
}

double _lerp(double begin, double end, double t) => begin + (end - begin) * t;

Duration _effectiveDuration(Duration requested) =>
    Duration(milliseconds: requested.inMilliseconds.clamp(1600, 2200));
