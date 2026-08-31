import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/albumium_app_theme.dart';

/// The material simulated by [CraftBackdrop].
enum CraftBackdropVariant { paper, cork }

/// Places a decorative strip of [CraftTape] over a [PaperPanel].
enum CraftTapePosition { topLeft, topCenter, topRight, bottomLeft, bottomRight }

/// A full-size, asset-free paper or cork surface.
///
/// Its texture is deterministic and is only repainted when its colors, size or
/// intensity change. Wrapping the paint in a [RepaintBoundary] also keeps child
/// animations from repainting the texture.
class CraftBackdrop extends StatelessWidget {
  const CraftBackdrop({
    super.key,
    this.child,
    this.variant = CraftBackdropVariant.paper,
    this.padding = EdgeInsets.zero,
    this.baseColor,
    this.textureColor,
    this.textureIntensity = 0.55,
  }) : assert(textureIntensity >= 0 && textureIntensity <= 1);

  final Widget? child;
  final CraftBackdropVariant variant;
  final EdgeInsetsGeometry padding;
  final Color? baseColor;
  final Color? textureColor;
  final double textureIntensity;

  @override
  Widget build(BuildContext context) {
    final palette = _CraftPalette.of(context);
    final background =
        baseColor ??
        switch (variant) {
          CraftBackdropVariant.paper => palette.paper,
          CraftBackdropVariant.cork => palette.cork,
        };
    final texture = textureColor ?? palette.ink;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              painter: _CraftBackdropPainter(
                variant: variant,
                baseColor: background,
                textureColor: texture,
                intensity: textureIntensity,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// A subtly textured paper card with optional rotation, shadow and tape.
class PaperPanel extends StatelessWidget {
  const PaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.rotationDegrees = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.showShadow = true,
    this.showBorder = true,
    this.textureIntensity = 0.28,
    this.tapePositions = const <CraftTapePosition>[],
    this.tapeColor,
    this.tapeWidth = 68,
    this.tapeHeight = 22,
  }) : assert(textureIntensity >= 0 && textureIntensity <= 1),
       assert(tapeWidth > 0),
       assert(tapeHeight > 0);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double rotationDegrees;
  final BorderRadius borderRadius;
  final bool showShadow;
  final bool showBorder;
  final double textureIntensity;
  final List<CraftTapePosition> tapePositions;
  final Color? tapeColor;
  final double tapeWidth;
  final double tapeHeight;

  @override
  Widget build(BuildContext context) {
    final palette = _CraftPalette.of(context);
    final paperColor = color ?? palette.paper;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(color: palette.border.withValues(alpha: 0.72))
            : null,
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.12),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _PaperSurfacePainter(
            fiberColor: palette.ink,
            intensity: textureIntensity,
          ),
          isComplex: true,
          willChange: false,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    final panel = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        card,
        for (final position in tapePositions) _positionTape(position, palette),
      ],
    );

    if (rotationDegrees == 0) return panel;
    return Transform.rotate(
      angle: _degreesToRadians(rotationDegrees),
      child: panel,
    );
  }

  Widget _positionTape(CraftTapePosition position, _CraftPalette palette) {
    final isTop = switch (position) {
      CraftTapePosition.topLeft ||
      CraftTapePosition.topCenter ||
      CraftTapePosition.topRight => true,
      CraftTapePosition.bottomLeft || CraftTapePosition.bottomRight => false,
    };
    final alignment = switch (position) {
      CraftTapePosition.topLeft ||
      CraftTapePosition.bottomLeft => Alignment.centerLeft,
      CraftTapePosition.topCenter => Alignment.center,
      CraftTapePosition.topRight ||
      CraftTapePosition.bottomRight => Alignment.centerRight,
    };
    final rotation = switch (position) {
      CraftTapePosition.topLeft => -5.0,
      CraftTapePosition.topCenter => -1.5,
      CraftTapePosition.topRight => 4.5,
      CraftTapePosition.bottomLeft => 4.0,
      CraftTapePosition.bottomRight => -4.0,
    };
    final tape = Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: CraftTape(
          width: tapeWidth,
          height: tapeHeight,
          color: tapeColor ?? palette.tape,
          rotationDegrees: rotation,
        ),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      top: isTop ? -tapeHeight * 0.42 : null,
      bottom: isTop ? null : -tapeHeight * 0.42,
      child: tape,
    );
  }
}

/// A reusable label clipped to a deterministic deckled-paper silhouette.
class TornPaperLabel extends StatelessWidget {
  const TornPaperLabel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.color,
    this.rotationDegrees = 0,
    this.edgeDepth = 3.5,
    this.segmentLength = 10,
    this.showShadow = true,
    this.showBorder = true,
  }) : assert(edgeDepth >= 0),
       assert(segmentLength > 0);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double rotationDegrees;
  final double edgeDepth;
  final double segmentLength;
  final bool showShadow;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final palette = _CraftPalette.of(context);
    final clipper = DeckledPaperClipper(
      edgeDepth: edgeDepth,
      segmentLength: segmentLength,
    );
    final label = PhysicalShape(
      clipper: clipper,
      clipBehavior: Clip.antiAlias,
      color: color ?? palette.paper,
      elevation: showShadow ? 5 : 0,
      shadowColor: palette.shadow.withValues(alpha: 0.42),
      child: CustomPaint(
        painter: _PaperSurfacePainter(fiberColor: palette.ink, intensity: 0.25),
        foregroundPainter: showBorder
            ? _DeckledBorderPainter(
                clipper: clipper,
                color: palette.border.withValues(alpha: 0.65),
              )
            : null,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (rotationDegrees == 0) return label;
    return Transform.rotate(
      angle: _degreesToRadians(rotationDegrees),
      child: label,
    );
  }
}

/// A deterministic torn-edge clipper that can also be used outside
/// [TornPaperLabel].
class DeckledPaperClipper extends CustomClipper<Path> {
  const DeckledPaperClipper({this.edgeDepth = 3.5, this.segmentLength = 10})
    : assert(edgeDepth >= 0),
      assert(segmentLength > 0);

  final double edgeDepth;
  final double segmentLength;

  static const _edgePattern = <double>[
    0.05,
    0.72,
    0.20,
    0.92,
    0.36,
    0.64,
    0.12,
    0.48,
  ];

  @override
  Path getClip(Size size) {
    if (size.isEmpty) return Path();
    final depth = math.min(edgeDepth, size.shortestSide * 0.14);
    if (depth == 0) {
      return Path()..addRect(Offset.zero & size);
    }
    final horizontalSegments = math.max(
      2,
      ((size.width - depth * 2) / segmentLength).ceil(),
    );
    final verticalSegments = math.max(
      2,
      ((size.height - depth * 2) / segmentLength).ceil(),
    );
    final path = Path()
      ..moveTo(0, depth)
      ..lineTo(depth, 0);

    for (var i = 1; i < horizontalSegments; i++) {
      final x = depth + (size.width - depth * 2) * i / horizontalSegments;
      path.lineTo(x, depth * _edgePattern[i % _edgePattern.length]);
    }
    path
      ..lineTo(size.width - depth, 0)
      ..lineTo(size.width, depth);

    for (var i = 1; i < verticalSegments; i++) {
      final y = depth + (size.height - depth * 2) * i / verticalSegments;
      path.lineTo(
        size.width - depth * _edgePattern[(i + 2) % _edgePattern.length],
        y,
      );
    }
    path
      ..lineTo(size.width, size.height - depth)
      ..lineTo(size.width - depth, size.height);

    for (var i = 1; i < horizontalSegments; i++) {
      final x =
          size.width -
          depth -
          (size.width - depth * 2) * i / horizontalSegments;
      path.lineTo(
        x,
        size.height - depth * _edgePattern[(i + 4) % _edgePattern.length],
      );
    }
    path
      ..lineTo(depth, size.height)
      ..lineTo(0, size.height - depth);

    for (var i = 1; i < verticalSegments; i++) {
      final y =
          size.height -
          depth -
          (size.height - depth * 2) * i / verticalSegments;
      path.lineTo(depth * _edgePattern[(i + 6) % _edgePattern.length], y);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant DeckledPaperClipper oldClipper) {
    return edgeDepth != oldClipper.edgeDepth ||
        segmentLength != oldClipper.segmentLength;
  }
}

/// A translucent washi/masking-tape accent with irregular cut edges.
class CraftTape extends StatelessWidget {
  const CraftTape({
    super.key,
    this.width = 72,
    this.height = 24,
    this.color,
    this.rotationDegrees = 0,
    this.opacity = 0.78,
    this.showShadow = true,
  }) : assert(width > 0),
       assert(height > 0),
       assert(opacity >= 0 && opacity <= 1);

  final double width;
  final double height;
  final Color? color;
  final double rotationDegrees;
  final double opacity;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final palette = _CraftPalette.of(context);
    return IgnorePointer(
      child: Transform.rotate(
        angle: _degreesToRadians(rotationDegrees),
        child: CustomPaint(
          painter: _TapePainter(
            color: (color ?? palette.tape).withValues(alpha: opacity),
            fiberColor: palette.ink,
            shadowColor: palette.shadow,
            showShadow: showShadow,
          ),
          willChange: false,
          child: SizedBox(width: width, height: height),
        ),
      ),
    );
  }
}

/// A hand-sewn horizontal divider.
class StitchedDivider extends StatelessWidget {
  const StitchedDivider({
    super.key,
    this.color,
    this.height = 18,
    this.indent = 0,
    this.endIndent = 0,
    this.strokeWidth = 1.4,
    this.stitchLength = 6,
    this.gap = 4,
  }) : assert(height > 0),
       assert(indent >= 0),
       assert(endIndent >= 0),
       assert(strokeWidth > 0),
       assert(stitchLength > 0),
       assert(gap >= 0);

  final Color? color;
  final double height;
  final double indent;
  final double endIndent;
  final double strokeWidth;
  final double stitchLength;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final palette = _CraftPalette.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StitchedDividerPainter(
          color: color ?? palette.stitch,
          indent: indent,
          endIndent: endIndent,
          strokeWidth: strokeWidth,
          stitchLength: stitchLength,
          gap: gap,
        ),
        willChange: false,
      ),
    );
  }
}

/// Draws a dashed, sewn-looking outline around [child].
class StitchedBorder extends StatelessWidget {
  const StitchedBorder({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.inset = 4,
    this.strokeWidth = 1.4,
    this.stitchLength = 6,
    this.gap = 4,
  }) : assert(inset >= 0),
       assert(strokeWidth > 0),
       assert(stitchLength > 0),
       assert(gap >= 0);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;
  final double inset;
  final double strokeWidth;
  final double stitchLength;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final palette = _CraftPalette.of(context);
    return CustomPaint(
      foregroundPainter: _StitchedBorderPainter(
        color: color ?? palette.stitch,
        borderRadius: borderRadius,
        inset: inset,
        strokeWidth: strokeWidth,
        stitchLength: stitchLength,
        gap: gap,
      ),
      willChange: false,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _CraftBackdropPainter extends CustomPainter {
  const _CraftBackdropPainter({
    required this.variant,
    required this.baseColor,
    required this.textureColor,
    required this.intensity,
  });

  final CraftBackdropVariant variant;
  final Color baseColor;
  final Color textureColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final lightWash = Color.lerp(baseColor, Colors.white, 0.08)!;
    final darkWash = Color.lerp(baseColor, Colors.black, 0.06)!;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[lightWash, baseColor, darkWash],
          stops: const <double>[0, 0.55, 1],
        ).createShader(bounds),
    );
    if (intensity == 0 || size.isEmpty) return;

    switch (variant) {
      case CraftBackdropVariant.paper:
        _paintPaper(canvas, size);
      case CraftBackdropVariant.cork:
        _paintCork(canvas, size);
    }
  }

  void _paintPaper(Canvas canvas, Size size) {
    final step = math.max(10.0, math.sqrt(size.width * size.height / 1800));
    final fiberPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.55;
    final columns = (size.width / step).ceil();
    final rows = (size.height / step).ceil();

    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final noise = _unitNoise(column, row, 17);
        if (noise < 0.38) continue;
        final x = (column + _unitNoise(column, row, 29) * 0.8) * step;
        final y = (row + _unitNoise(column, row, 43) * 0.8) * step;
        final length = step * (0.13 + noise * 0.35);
        final angle = (_unitNoise(column, row, 71) - 0.5) * 0.42;
        fiberPaint.color = textureColor.withValues(
          alpha: intensity * (0.018 + noise * 0.035),
        );
        canvas.drawLine(
          Offset(x, y),
          Offset(x + math.cos(angle) * length, y + math.sin(angle) * length),
          fiberPaint,
        );
      }
    }

    final wash = Paint()
      ..color = textureColor.withValues(alpha: intensity * 0.013);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.12, size.height * 0.22),
        width: size.width * 0.34,
        height: size.height * 0.17,
      ),
      wash,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.88, size.height * 0.76),
        width: size.width * 0.42,
        height: size.height * 0.22,
      ),
      wash,
    );
  }

  void _paintCork(Canvas canvas, Size size) {
    final step = math.max(12.0, math.sqrt(size.width * size.height / 1250));
    final columns = (size.width / step).ceil();
    final rows = (size.height / step).ceil();
    final chipPaint = Paint();
    final seamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final noise = _unitNoise(column, row, 101);
        if (noise < 0.25) continue;
        final center = Offset(
          (column + _unitNoise(column, row, 113) * 0.75) * step,
          (row + _unitNoise(column, row, 127) * 0.75) * step,
        );
        final radius = step * (0.09 + noise * 0.16);
        final isDark = _unitNoise(column, row, 149) > 0.48;
        final chipColor = Color.lerp(
          baseColor,
          isDark ? Colors.black : Colors.white,
          0.16 + noise * 0.12,
        )!;
        chipPaint.color = chipColor.withValues(alpha: intensity * 0.60);
        seamPaint.color = textureColor.withValues(
          alpha: intensity * (0.035 + noise * 0.055),
        );

        final path = Path();
        for (var point = 0; point < 6; point++) {
          final angle = point * math.pi / 3;
          final wobble = 0.72 + _unitNoise(column + point, row, 173) * 0.46;
          final offset = Offset(
            center.dx + math.cos(angle) * radius * wobble * 1.7,
            center.dy + math.sin(angle) * radius * wobble,
          );
          if (point == 0) {
            path.moveTo(offset.dx, offset.dy);
          } else {
            path.lineTo(offset.dx, offset.dy);
          }
        }
        path.close();
        canvas
          ..drawPath(path, chipPaint)
          ..drawPath(path, seamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CraftBackdropPainter oldDelegate) {
    return variant != oldDelegate.variant ||
        baseColor != oldDelegate.baseColor ||
        textureColor != oldDelegate.textureColor ||
        intensity != oldDelegate.intensity;
  }
}

class _PaperSurfacePainter extends CustomPainter {
  const _PaperSurfacePainter({
    required this.fiberColor,
    required this.intensity,
  });

  final Color fiberColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity == 0 || size.isEmpty) return;
    final step = math.max(9.0, math.sqrt(size.width * size.height / 320));
    final columns = (size.width / step).ceil();
    final rows = (size.height / step).ceil();
    final paint = Paint()
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final noise = _unitNoise(column, row, 211);
        if (noise < 0.52) continue;
        final start = Offset(
          (column + _unitNoise(column, row, 223) * 0.7) * step,
          (row + _unitNoise(column, row, 227) * 0.7) * step,
        );
        paint.color = fiberColor.withValues(
          alpha: intensity * (0.025 + noise * 0.045),
        );
        canvas.drawLine(
          start,
          start + Offset(step * (0.12 + noise * 0.20), step * 0.025),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperSurfacePainter oldDelegate) {
    return fiberColor != oldDelegate.fiberColor ||
        intensity != oldDelegate.intensity;
  }
}

class _DeckledBorderPainter extends CustomPainter {
  const _DeckledBorderPainter({required this.clipper, required this.color});

  final DeckledPaperClipper clipper;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      clipper.getClip(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DeckledBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        clipper.edgeDepth != oldDelegate.clipper.edgeDepth ||
        clipper.segmentLength != oldDelegate.clipper.segmentLength;
  }
}

class _TapePainter extends CustomPainter {
  const _TapePainter({
    required this.color,
    required this.fiberColor,
    required this.shadowColor,
    required this.showShadow,
  });

  final Color color;
  final Color fiberColor;
  final Color shadowColor;
  final bool showShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = math.min(3.0, size.shortestSide / 5);
    final path = Path()
      ..moveTo(0, edge)
      ..lineTo(edge, 0)
      ..lineTo(size.width * 0.23, edge * 0.35)
      ..lineTo(size.width * 0.47, 0)
      ..lineTo(size.width * 0.72, edge * 0.42)
      ..lineTo(size.width - edge * 1.4, 0)
      ..lineTo(size.width, edge)
      ..lineTo(size.width - edge * 0.3, size.height * 0.31)
      ..lineTo(size.width, size.height * 0.57)
      ..lineTo(size.width - edge * 0.45, size.height * 0.82)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.74, size.height - edge * 0.40)
      ..lineTo(size.width * 0.49, size.height)
      ..lineTo(size.width * 0.26, size.height - edge * 0.32)
      ..lineTo(edge * 1.3, size.height)
      ..lineTo(0, size.height - edge)
      ..lineTo(edge * 0.35, size.height * 0.73)
      ..lineTo(0, size.height * 0.48)
      ..lineTo(edge * 0.35, size.height * 0.24)
      ..close();

    if (showShadow) {
      canvas.drawShadow(path, shadowColor.withValues(alpha: 0.35), 2, true);
    }
    canvas.drawPath(path, Paint()..color = color);

    canvas
      ..save()
      ..clipPath(path);
    final fiberPaint = Paint()
      ..color = fiberColor.withValues(alpha: 0.075)
      ..strokeWidth = 0.55;
    for (double y = 4; y < size.height; y += 5) {
      canvas.drawLine(
        Offset(2, y),
        Offset(size.width - 2, y + math.sin(y) * 0.6),
        fiberPaint,
      );
    }
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = fiberColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant _TapePainter oldDelegate) {
    return color != oldDelegate.color ||
        fiberColor != oldDelegate.fiberColor ||
        shadowColor != oldDelegate.shadowColor ||
        showShadow != oldDelegate.showShadow;
  }
}

class _StitchedDividerPainter extends CustomPainter {
  const _StitchedDividerPainter({
    required this.color,
    required this.indent,
    required this.endIndent,
    required this.strokeWidth,
    required this.stitchLength,
    required this.gap,
  });

  final Color color;
  final double indent;
  final double endIndent;
  final double strokeWidth;
  final double stitchLength;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final end = math.max(indent, size.width - endIndent);
    final path = Path()
      ..moveTo(indent, size.height / 2)
      ..lineTo(end, size.height / 2);
    _drawStitches(
      canvas,
      path,
      color: color,
      strokeWidth: strokeWidth,
      stitchLength: stitchLength,
      gap: gap,
    );
  }

  @override
  bool shouldRepaint(covariant _StitchedDividerPainter oldDelegate) {
    return color != oldDelegate.color ||
        indent != oldDelegate.indent ||
        endIndent != oldDelegate.endIndent ||
        strokeWidth != oldDelegate.strokeWidth ||
        stitchLength != oldDelegate.stitchLength ||
        gap != oldDelegate.gap;
  }
}

class _StitchedBorderPainter extends CustomPainter {
  const _StitchedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.inset,
    required this.strokeWidth,
    required this.stitchLength,
    required this.gap,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double inset;
  final double strokeWidth;
  final double stitchLength;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final safeInset = math.max(inset, strokeWidth / 2);
    final rect = (Offset.zero & size).deflate(safeInset);
    if (rect.isEmpty) return;
    final path = Path()..addRRect(borderRadius.toRRect(rect));
    _drawStitches(
      canvas,
      path,
      color: color,
      strokeWidth: strokeWidth,
      stitchLength: stitchLength,
      gap: gap,
    );
  }

  @override
  bool shouldRepaint(covariant _StitchedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        borderRadius != oldDelegate.borderRadius ||
        inset != oldDelegate.inset ||
        strokeWidth != oldDelegate.strokeWidth ||
        stitchLength != oldDelegate.stitchLength ||
        gap != oldDelegate.gap;
  }
}

void _drawStitches(
  Canvas canvas,
  Path path, {
  required Color color,
  required double strokeWidth,
  required double stitchLength,
  required double gap,
}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + stitchLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += stitchLength + gap;
    }
  }
}

class _CraftPalette {
  const _CraftPalette({
    required this.paper,
    required this.cork,
    required this.ink,
    required this.border,
    required this.tape,
    required this.stitch,
    required this.shadow,
  });

  final Color paper;
  final Color cork;
  final Color ink;
  final Color border;
  final Color tape;
  final Color stitch;
  final Color shadow;

  factory _CraftPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final albumium = theme.extension<AlbumiumThemeColors>();
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surface = albumium?.surface ?? scheme.surface;
    final background = albumium?.background ?? scheme.surfaceContainerLowest;
    final ink = albumium?.text ?? scheme.onSurface;
    final border = albumium?.border ?? scheme.outline;
    final secondary = albumium?.secondary ?? scheme.secondary;

    final paper = isDark
        ? Color.lerp(surface, const Color(0xFF5A4638), 0.20)!
        : Color.lerp(surface, const Color(0xFFF2E2C9), 0.42)!;
    final cork = isDark
        ? Color.lerp(background, const Color(0xFF684629), 0.64)!
        : Color.lerp(secondary, const Color(0xFFB98250), 0.70)!;
    final tape = isDark
        ? Color.lerp(secondary, const Color(0xFFCDAE75), 0.55)!
        : Color.lerp(secondary, const Color(0xFFF1D7A4), 0.62)!;

    return _CraftPalette(
      paper: paper,
      cork: cork,
      ink: ink,
      border: Color.lerp(border, ink, isDark ? 0.15 : 0.08)!,
      tape: tape,
      stitch: Color.lerp(secondary, ink, isDark ? 0.34 : 0.42)!,
      shadow: isDark ? Colors.black : const Color(0xFF4A3222),
    );
  }
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

double _unitNoise(int x, int y, int salt) {
  final value =
      math.sin(x * 12.9898 + y * 78.233 + salt * 0.417) * 43758.5453123;
  return value - value.floorToDouble();
}
