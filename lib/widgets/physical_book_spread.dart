import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/album_models.dart';
import 'album_cover.dart';
import 'album_page_canvas.dart';

/// A single, persistent physical book.
///
/// [leftPageIndex] and [rightPageIndex] describe the visible spread. Use
/// [titlePageIndex] for the inside title/endpaper and [blankPageIndex] for a
/// deliberately empty page. Supplying the `next*` values and a
/// [turnProgress] animates one physical leaf without replacing the book body.
class PhysicalBookSpread extends StatelessWidget {
  const PhysicalBookSpread({
    super.key,
    required this.album,
    required this.leftPageIndex,
    required this.rightPageIndex,
    this.closed = false,
    this.nextLeftPageIndex,
    this.nextRightPageIndex,
    this.nextClosed = false,
    this.turnProgress = 0,
    this.turningForward = true,
    this.interactive = false,
    this.focusedPageIndex,
    this.companionPageFraction = 0.11,
    this.activePageIndex,
    this.selectedElementId,
    this.onSelectPage,
    this.onSelectElement,
    this.onChanged,
  });

  static const int titlePageIndex = -2;
  static const int blankPageIndex = -1;

  final AlbumModel album;
  final int leftPageIndex;
  final int rightPageIndex;
  final bool closed;
  final int? nextLeftPageIndex;
  final int? nextRightPageIndex;
  final bool nextClosed;
  final double turnProgress;
  final bool turningForward;
  final bool interactive;

  /// When set, keeps this page at its natural portrait ratio and reveals only
  /// a narrow strip of the companion page. The binding remains visible between
  /// them. Editors use this on phones; previews and tablet editors leave it
  /// null to show the complete spread.
  final int? focusedPageIndex;
  final double companionPageFraction;
  final int? activePageIndex;
  final String? selectedElementId;
  final ValueChanged<int>? onSelectPage;
  final ValueChanged<String?>? onSelectElement;
  final VoidCallback? onChanged;

  bool get _hasTransition =>
      nextLeftPageIndex != null && nextRightPageIndex != null;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (interactive &&
            focusedPageIndex != null &&
            !closed &&
            !_hasTransition) {
          return _buildFocusedEditor(constraints: constraints, theme: theme);
        }

        var width = constraints.maxWidth;
        var height = width / 1.5;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * 1.5;
        }

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: RepaintBoundary(
              child: _buildBook(
                width: width,
                height: height,
                theme: theme,
                progress: turnProgress.clamp(0.0, 1.0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusedEditor({
    required BoxConstraints constraints,
    required AlbumThemePreset theme,
  }) {
    const pageAspectRatio = 9 / 14;
    final companion = companionPageFraction.clamp(0.08, 0.18);
    final pageWidthFromViewport = math.max(
      1.0,
      (constraints.maxWidth - 32) / (1 + companion),
    );
    final pageWidthFromHeight = math.max(
      1.0,
      (constraints.maxHeight - 24) * pageAspectRatio,
    );
    final pageWidth = math.min(pageWidthFromViewport, pageWidthFromHeight);
    final virtualWidth = pageWidth * 2 + 32;
    final virtualHeight = pageWidth / pageAspectRatio + 24;
    final viewportWidth = math.min(
      constraints.maxWidth,
      pageWidth * (1 + companion) + 32,
    );
    final focusedLeft =
        focusedPageIndex == leftPageIndex || rightPageIndex == blankPageIndex;
    final left = focusedLeft ? 0.0 : viewportWidth - virtualWidth;

    return Center(
      child: Semantics(
        label:
            'Odaklı sayfa görünümü, karşı sayfanın yüzde ${(companion * 100).round()} kadarı görünür',
        container: true,
        explicitChildNodes: true,
        child: SizedBox(
          key: const ValueKey('focused-book-viewport'),
          width: viewportWidth,
          height: virtualHeight,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: 0,
                  width: virtualWidth,
                  height: virtualHeight,
                  child: RepaintBoundary(
                    child: _buildOpenBook(
                      theme: theme,
                      leftIndex: leftPageIndex,
                      rightIndex: rightPageIndex,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBook({
    required double width,
    required double height,
    required AlbumThemePreset theme,
    required double progress,
  }) {
    if (!_hasTransition) {
      if (closed) {
        return _ClosedBook(album: album);
      }
      return _buildOpenBook(
        theme: theme,
        leftIndex: leftPageIndex,
        rightIndex: rightPageIndex,
      );
    }

    if (closed != nextClosed) {
      final openingProgress = closed ? progress : 1 - progress;
      final openLeft = closed ? nextLeftPageIndex! : leftPageIndex;
      final openRight = closed ? nextRightPageIndex! : rightPageIndex;
      return _buildCoverTurn(
        width: width,
        height: height,
        theme: theme,
        openingProgress: openingProgress,
        openLeftIndex: openLeft,
        openRightIndex: openRight,
      );
    }

    if (closed && nextClosed) {
      return _ClosedBook(album: album);
    }

    return _buildOpenBook(
      theme: theme,
      leftIndex: turningForward ? leftPageIndex : nextLeftPageIndex!,
      rightIndex: turningForward ? nextRightPageIndex! : rightPageIndex,
      turningLeaf: _TurningLeaf(
        progress: progress,
        forward: turningForward,
        front: _buildPageSide(
          index: turningForward ? rightPageIndex : leftPageIndex,
          isLeft: !turningForward,
          theme: theme,
        ),
        back: _buildPageSide(
          index: turningForward ? nextLeftPageIndex! : nextRightPageIndex!,
          isLeft: turningForward,
          theme: theme,
        ),
      ),
    );
  }

  Widget _buildCoverTurn({
    required double width,
    required double height,
    required AlbumThemePreset theme,
    required double openingProgress,
    required int openLeftIndex,
    required int openRightIndex,
  }) {
    final eased = Curves.easeInOutCubic.transform(openingProgress);
    final pageWidth = (width - 32) / 2;
    final coverLeft = _lerp(width * 0.5 - pageWidth / 2, width / 2 + 2, eased);
    final coverTop = _lerp(5, 12, eased);
    final coverHeight = _lerp(height - 10, height - 24, eased);
    final showFront = eased < 0.5;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: Curves.easeOut.transform(
            ((eased - 0.06) / 0.42).clamp(0.0, 1.0),
          ),
          child: _buildOpenBook(
            theme: theme,
            leftIndex: openLeftIndex,
            rightIndex: openRightIndex,
          ),
        ),
        if (eased < 0.55)
          Positioned(
            left: coverLeft + 3,
            top: coverTop + 4,
            width: pageWidth,
            height: coverHeight,
            child: Opacity(
              opacity: (1 - eased / 0.55).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFD7C7A7),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 20,
                      offset: Offset(8, 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: coverLeft,
          top: coverTop,
          width: pageWidth,
          height: coverHeight,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateY(math.pi * eased),
            filterQuality: FilterQuality.high,
            child: showFront
                ? _CoverLeaf(album: album)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _InsideCover(
                      theme: theme,
                      page: _buildPageSide(
                        index: openLeftIndex,
                        isLeft: true,
                        theme: theme,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          left: width / 2 - 9,
          top: 14,
          bottom: 14,
          width: 18,
          child: IgnorePointer(
            child: Opacity(
              opacity: math.sin(math.pi * eased).abs() * 0.55,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xB0000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenBook({
    required AlbumThemePreset theme,
    required int leftIndex,
    required int rightIndex,
    Widget? turningLeaf,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pageWidth = (width - 32) / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 20,
              right: 20,
              bottom: -7,
              height: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.68),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: theme.coverEnd.withValues(alpha: 0.22),
                      blurRadius: 45,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(theme.coverStart, Colors.black, 0.25)!,
                      Color.lerp(theme.coverEnd, Colors.black, 0.52)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: theme.accent.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 7,
              right: 7,
              top: 8,
              bottom: 8,
              child: CustomPaint(
                painter: _PageStackDepthPainter(theme.pageColor),
              ),
            ),
            Positioned(
              left: 14,
              top: 12,
              width: pageWidth,
              bottom: 12,
              child: _buildPageSide(
                index: leftIndex,
                isLeft: true,
                theme: theme,
              ),
            ),
            Positioned(
              left: 18 + pageWidth,
              top: 12,
              width: pageWidth,
              bottom: 12,
              child: _buildPageSide(
                index: rightIndex,
                isLeft: false,
                theme: theme,
              ),
            ),
            if (turningLeaf != null)
              Positioned(
                left: 14,
                right: 14,
                top: 12,
                bottom: 12,
                child: turningLeaf,
              ),
            Positioned(
              top: 12,
              bottom: 12,
              left: width / 2 - 31,
              width: 62,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x25000000),
                        Color(0x81000000),
                        Color(0x2C000000),
                        Colors.transparent,
                      ],
                      stops: [0, 0.34, 0.5, 0.66, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              bottom: 10,
              left: width / 2 - 20,
              width: 40,
              child: IgnorePointer(
                child: _buildBindingOverlay(album.bindingType),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageSide({
    required int index,
    required bool isLeft,
    required AlbumThemePreset theme,
  }) {
    final radius = BorderRadius.horizontal(
      left: isLeft ? const Radius.circular(9) : Radius.zero,
      right: isLeft ? Radius.zero : const Radius.circular(9),
    );

    Widget content;
    if (index == titlePageIndex) {
      content = _TitleEndpaper(album: album, theme: theme);
    } else if (index == blankPageIndex || index >= album.pages.length) {
      content = const SizedBox.expand();
    } else {
      final page = album.pages[index];
      content = AlbumPageCanvas(
        key: ValueKey(page.id),
        page: page,
        theme: theme,
        interactive: interactive,
        selectedId: selectedElementId,
        onSelect: (id) {
          onSelectPage?.call(index);
          onSelectElement?.call(id);
        },
        onChanged: onChanged,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.pageColor),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            IgnorePointer(
              child: CustomPaint(painter: _PaperPatinaPainter(theme.accent)),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isLeft
                        ? const [
                            Color(0x0C000000),
                            Colors.transparent,
                            Color(0x30000000),
                          ]
                        : const [
                            Color(0x30000000),
                            Colors.transparent,
                            Color(0x0C000000),
                          ],
                    stops: const [0, 0.7, 1],
                  ),
                ),
              ),
            ),
            if (interactive && activePageIndex == index)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.accent.withValues(alpha: 0.82),
                        width: 2,
                      ),
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBindingOverlay(AlbumBindingType binding) {
    return Semantics(
      label: 'Cilt merkezi: ${binding.title}',
      image: true,
      child: switch (binding) {
        AlbumBindingType.spiral => const _SpiralBinding(),
        AlbumBindingType.stitched => const _StitchedBinding(),
        AlbumBindingType.leatherStrap => const _LeatherStrapBinding(),
        AlbumBindingType.hardcover => const _HardcoverCrease(),
        AlbumBindingType.vintageCord => const _VintageCordBinding(),
      },
    );
  }

  double _lerp(double start, double end, double amount) =>
      start + (end - start) * amount;
}

class _TurningLeaf extends StatelessWidget {
  const _TurningLeaf({
    required this.progress,
    required this.forward,
    required this.front,
    required this.back,
  });

  final double progress;
  final bool forward;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeInOutCubicEmphasized.transform(progress);
    final angle = (forward ? 1 : -1) * math.pi * eased;
    final face = eased >= 0.5
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: back,
          )
        : front;

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = constraints.maxWidth / 2;
        final leaf = SizedBox(
          width: halfWidth,
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              face,
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: forward
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      end: forward
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(
                          alpha: 0.05 + math.sin(math.pi * eased).abs() * 0.35,
                        ),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: forward ? halfWidth - 4 : halfWidth - 28,
              top: 4,
              bottom: 4,
              width: 32,
              child: IgnorePointer(
                child: Opacity(
                  opacity: math.sin(math.pi * eased).abs() * 0.62,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: forward
                            ? const [Color(0x99000000), Colors.transparent]
                            : const [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: forward ? halfWidth : 0,
              top: 0,
              width: halfWidth,
              bottom: 0,
              child: Transform(
                alignment: forward
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0022)
                  ..rotateY(angle),
                filterQuality: FilterQuality.high,
                child: leaf,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClosedBook extends StatelessWidget {
  const _ClosedBook({required this.album});

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.49,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 9,
            right: -4,
            top: 8,
            bottom: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFD5C4A3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF9A8767)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xA0000000),
                    blurRadius: 28,
                    offset: Offset(10, 18),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: _CoverLeaf(album: album)),
        ],
      ),
    );
  }
}

class _CoverLeaf extends StatelessWidget {
  const _CoverLeaf({required this.album});

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x78000000),
            blurRadius: 15,
            offset: Offset(6, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AlbumCover(album: album),
      ),
    );
  }
}

class _InsideCover extends StatelessWidget {
  const _InsideCover({required this.theme, required this.page});

  final AlbumThemePreset theme;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.coverEnd, theme.coverStart]),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(padding: const EdgeInsets.all(7), child: page),
    );
  }
}

class _TitleEndpaper extends StatelessWidget {
  const _TitleEndpaper({required this.album, required this.theme});

  final AlbumModel album;
  final AlbumThemePreset theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.15,
          colors: [
            Color.lerp(theme.pageColor, Colors.white, 0.08)!,
            Color.lerp(theme.pageColor, theme.accent, 0.09)!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.accent.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(80),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 18,
                  color: theme.accent.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 8),
                Text(
                  album.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.accent.withValues(alpha: 0.7),
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ALBUMIUM',
                  style: TextStyle(
                    color: theme.accent.withValues(alpha: 0.42),
                    fontSize: 7,
                    letterSpacing: 2.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperPatinaPainter extends CustomPainter {
  const _PaperPatinaPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final fleckPaint = Paint()..color = accent.withValues(alpha: 0.055);
    final fiberPaint = Paint()
      ..color = accent.withValues(alpha: 0.035)
      ..strokeWidth = 0.45;

    // Deterministic positions keep the paper texture stable between frames.
    for (var i = 0; i < 38; i++) {
      final x = ((i * 47 + 13) % 101) / 101 * size.width;
      final y = ((i * 71 + 29) % 103) / 103 * size.height;
      final radius = 0.35 + (i % 3) * 0.22;
      canvas.drawCircle(Offset(x, y), radius, fleckPaint);
    }
    for (var i = 0; i < 10; i++) {
      final y = ((i * 31 + 11) % 97) / 97 * size.height;
      final x = ((i * 23 + 7) % 89) / 89 * size.width;
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 10 + i).clamp(0, size.width), y + 0.8),
        fiberPaint,
      );
    }

    final edgePaint = Paint()
      ..shader = RadialGradient(
        radius: 0.82,
        colors: const [Colors.transparent, Color(0x16000000)],
        stops: const [0.76, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _PaperPatinaPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _SpiralBinding extends StatelessWidget {
  const _SpiralBinding();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 27.0;
        final count = (constraints.maxHeight / spacing).floor();
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 1; i < count; i++)
              Positioned(
                top: i * spacing - 6,
                child: Container(
                  width: 32,
                  height: 11,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF9F2D7),
                        Color(0xFF77736B),
                        Color(0xFFD4AF64),
                        Color(0xFF3E3A35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StitchedBinding extends StatelessWidget {
  const _StitchedBinding();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _ThreadStitchPainter());
}

class _ThreadStitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final thread = Paint()
      ..color = const Color(0xFFEADBCE)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final hole = Paint()..color = const Color(0xFF1E1A17);
    for (double y = 14; y < size.height - 14; y += 18) {
      canvas.drawCircle(Offset(centerX, y), 2.2, hole);
      canvas.drawLine(Offset(centerX, y + 3), Offset(centerX, y + 15), thread);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeatherStrapBinding extends StatelessWidget {
  const _LeatherStrapBinding();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 14,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A3425), Color(0xFF20140E)],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (_) => Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFDF88), Color(0xFF7F5D23)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HardcoverCrease extends StatelessWidget {
  const _HardcoverCrease();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 6,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.43),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}

class _VintageCordBinding extends StatelessWidget {
  const _VintageCordBinding();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 6,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E4E2E), Color(0xFFD2A56F), Color(0xFF6E4E2E)],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3)],
      ),
    ),
  );
}

class _PageStackDepthPainter extends CustomPainter {
  const _PageStackDepthPainter(this.pageColor);

  final Color pageColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var inset = 0; inset < 5; inset++) {
      final paint = Paint()
        ..color = Color.lerp(
          pageColor,
          const Color(0xFF74654E),
          0.12 + inset * 0.035,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      final rect = Rect.fromLTWH(
        inset.toDouble(),
        inset.toDouble(),
        size.width - inset * 2,
        size.height - inset * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PageStackDepthPainter oldDelegate) =>
      oldDelegate.pageColor != pageColor;
}

/// Photo corner mounts used by [AlbumPageCanvas].
class PhotoCornerMounts extends StatelessWidget {
  const PhotoCornerMounts({
    super.key,
    required this.style,
    required this.child,
  });

  final int style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = style == 4
        ? const Color(0xFFD4AF37)
        : const Color(0xFF2B2118);
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          child: _CornerBracket(color: color, rotation: 0),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _CornerBracket(color: color, rotation: 1),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _CornerBracket(color: color, rotation: 2),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _CornerBracket(color: color, rotation: 3),
        ),
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.color, required this.rotation});

  final Color color;
  final int rotation;

  @override
  Widget build(BuildContext context) => RotatedBox(
    quarterTurns: rotation,
    child: CustomPaint(
      size: const Size(18, 18),
      painter: _CornerBracketPainter(color),
    ),
  );
}

class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white30
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
