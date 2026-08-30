import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/album_models.dart';

/// Theme-specific, asset-free page ornamentation shared by the editor,
/// physical preview and exported video frames.
class ThemePageDecoration extends StatelessWidget {
  const ThemePageDecoration({
    super.key,
    required this.theme,
    required this.paperColor,
  });

  final AlbumThemePreset theme;
  final Color paperColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: ValueKey('page-style-${theme.id}'),
        painter: _ThemePagePainter(
          themeId: theme.id,
          accent: theme.accent,
          paperColor: paperColor,
        ),
      ),
    );
  }
}

class _ThemePagePainter extends CustomPainter {
  const _ThemePagePainter({
    required this.themeId,
    required this.accent,
    required this.paperColor,
  });

  final String themeId;
  final Color accent;
  final Color paperColor;

  bool get _darkPaper => paperColor.computeLuminance() < 0.34;
  Color get _ink => _darkPaper
      ? Color.lerp(accent, Colors.white, 0.72)!
      : Color.lerp(accent, const Color(0xFF382A24), 0.18)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (themeId.startsWith('special_card_')) {
      _paintSpecialCard(canvas, size);
      return;
    }
    switch (themeId) {
      case 'soft_romance':
        _paintSoftRomance(canvas, size);
      case 'vintage_diary':
        _paintVintageDiary(canvas, size);
      case 'animals':
        _paintAnimals(canvas, size);
      case 'travel_postcard':
        _paintTravel(canvas, size);
      case 'best_friends':
        _paintBestFriends(canvas, size);
      case 'minimal_editorial':
        _paintMinimalEditorial(canvas, size);
      case 'midnight_atlas':
        _paintMidnightAtlas(canvas, size);
      case 'dark_leather':
        _paintDarkLeather(canvas, size);
      default:
        _paintMinimalEditorial(canvas, size);
    }
  }

  void _paintSpecialCard(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final ink = _ink;
    _doubleBorder(canvas, size, ink, s * 0.052, radius: s * 0.055);
    final fine = Paint()
      ..color = ink.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, s * 0.004);
    final glow = Paint()..color = ink.withValues(alpha: 0.055);
    canvas.drawCircle(
      Offset(size.width * .08, size.height * .08),
      s * .26,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * .92, size.height * .91),
      s * .30,
      glow,
    );
    for (final alignment in const [
      Alignment(-.82, -.88),
      Alignment(.82, -.88),
      Alignment(-.82, .88),
      Alignment(.82, .88),
    ]) {
      final center = alignment.alongSize(size);
      canvas.drawCircle(
        center,
        s * .016,
        Paint()..color = ink.withValues(alpha: .56),
      );
      canvas.drawCircle(center, s * .032, fine);
    }
    final dividerY = size.height * .74;
    canvas.drawLine(
      Offset(size.width * .28, dividerY),
      Offset(size.width * .72, dividerY),
      fine,
    );
  }

  void _paintSoftRomance(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final margin = s * 0.055;
    final rose = _ink;
    _doubleBorder(canvas, size, rose, margin, radius: s * 0.045);

    final wash = Paint()..color = rose.withValues(alpha: 0.045);
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.07),
      s * 0.22,
      wash,
    );
    canvas.drawCircle(
      Offset(size.width * 0.94, size.height * 0.91),
      s * 0.25,
      wash,
    );

    _paintVine(canvas, Offset(margin * 0.9, margin * 0.95), false, rose, s);
    _paintVine(
      canvas,
      Offset(size.width - margin * 0.9, size.height - margin * 0.95),
      true,
      rose,
      s,
    );
    _paintHeart(canvas, Offset(size.width / 2, margin * 1.15), s * 0.028, rose);
  }

  void _paintVintageDiary(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final sepia = _ink;
    final linePaint = Paint()
      ..color = sepia.withValues(alpha: 0.095)
      ..strokeWidth = math.max(0.5, s * 0.002);
    final top = size.height * 0.16;
    for (var i = 0; i < 14; i++) {
      final y = top + i * (size.height * 0.052);
      canvas.drawLine(
        Offset(s * 0.095, y),
        Offset(size.width - s * 0.075, y),
        linePaint,
      );
    }
    canvas.drawLine(
      Offset(s * 0.155, size.height * 0.09),
      Offset(s * 0.155, size.height * 0.9),
      Paint()
        ..color = const Color(0xFF9A4D45).withValues(alpha: 0.21)
        ..strokeWidth = math.max(0.8, s * 0.003),
    );

    final borderPaint = Paint()
      ..color = sepia.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, s * 0.003);
    canvas.drawRect(
      Rect.fromLTWH(
        s * 0.045,
        s * 0.045,
        size.width - s * 0.09,
        size.height - s * 0.09,
      ),
      borderPaint,
    );
    _paintPostmark(
      canvas,
      Offset(size.width - s * 0.16, s * 0.17),
      s * 0.075,
      sepia,
    );
    _paintCornerFlourish(
      canvas,
      Offset(s * 0.045, size.height - s * 0.045),
      sepia,
      s,
    );
  }

  void _paintAnimals(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final sage = _ink;
    final blobPaint = Paint()..color = sage.withValues(alpha: 0.055);
    final topBlob = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.52, 0)
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.11,
        size.width * 0.17,
        size.height * 0.13,
        0,
        size.height * 0.23,
      )
      ..close();
    canvas.drawPath(topBlob, blobPaint);
    final bottomBlob = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.48, size.height)
      ..cubicTo(
        size.width * 0.59,
        size.height * 0.88,
        size.width * 0.84,
        size.height * 0.88,
        size.width,
        size.height * 0.76,
      )
      ..close();
    canvas.drawPath(bottomBlob, blobPaint);
    _dottedBorder(canvas, size, sage, s * 0.06);
    _paintPaw(canvas, Offset(s * 0.15, s * 0.16), s * 0.06, sage, -0.3);
    _paintPaw(
      canvas,
      Offset(size.width - s * 0.15, size.height - s * 0.16),
      s * 0.052,
      sage,
      0.35,
    );
  }

  void _paintTravel(Canvas canvas, Size size) {
    final s = size.shortestSide;
    const postalBlue = Color(0xFF315B72);
    const postalRed = Color(0xFFB54A48);
    final stripeWidth = math.max(8.0, s * 0.045);
    final stripePaint = Paint()..strokeWidth = math.max(2.2, s * 0.012);
    for (
      double x = -size.height;
      x < size.width + size.height;
      x += stripeWidth
    ) {
      final index = ((x + size.height) / stripeWidth).round();
      stripePaint.color = (index.isEven ? postalRed : postalBlue).withValues(
        alpha: 0.34,
      );
      canvas.drawLine(Offset(x, 1), Offset(x + s * 0.055, 1), stripePaint);
      canvas.drawLine(
        Offset(x, size.height - 1),
        Offset(x + s * 0.055, size.height - 1),
        stripePaint,
      );
    }

    final routePaint = Paint()
      ..color = postalBlue.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, s * 0.003)
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(s * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.64,
        size.width * 0.58,
        size.height * 0.91,
        size.width * 0.91,
        size.height * 0.76,
      );
    canvas.drawPath(route, routePaint);
    for (var i = 0; i < 9; i++) {
      final metric = route.computeMetrics().first;
      final tangent = metric.getTangentForOffset(metric.length * i / 8);
      if (tangent != null && i.isEven) {
        canvas.drawCircle(
          tangent.position,
          s * 0.006,
          Paint()..color = postalRed.withValues(alpha: 0.42),
        );
      }
    }
    _paintPostmark(
      canvas,
      Offset(size.width - s * 0.17, s * 0.18),
      s * 0.085,
      postalBlue,
    );
    _paintPaperPlane(
      canvas,
      Offset(size.width * 0.57, size.height * 0.73),
      s * 0.065,
      postalRed,
    );
  }

  void _paintBestFriends(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final purple = _ink;
    final random = math.Random(941);
    final colors = [
      purple,
      const Color(0xFFE16B91),
      const Color(0xFFF2B84B),
      const Color(0xFF55A6A6),
    ];
    for (var i = 0; i < 34; i++) {
      final edge = i % 2 == 0;
      final x = edge
          ? (i % 4 < 2
                ? random.nextDouble() * s * 0.17
                : size.width - random.nextDouble() * s * 0.17)
          : random.nextDouble() * size.width;
      final y = edge
          ? random.nextDouble() * size.height
          : (i % 4 < 2
                ? random.nextDouble() * s * 0.14
                : size.height - random.nextDouble() * s * 0.14);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.28);
      if (i % 3 == 0) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble());
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: s * 0.026,
            height: s * 0.011,
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), s * (0.008 + (i % 2) * 0.004), paint);
      }
    }
    _scallopedBorder(canvas, size, purple, s * 0.055);
    _paintHeart(
      canvas,
      Offset(s * 0.13, s * 0.14),
      s * 0.04,
      const Color(0xFFE16B91),
    );
    _paintStar(
      canvas,
      Offset(size.width - s * 0.13, size.height - s * 0.14),
      s * 0.045,
      const Color(0xFFF2B84B),
    );
  }

  void _paintMinimalEditorial(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final ink = _ink;
    final hairline = Paint()
      ..color = ink.withValues(alpha: 0.16)
      ..strokeWidth = math.max(0.45, s * 0.0017);
    final margin = s * 0.065;
    canvas.drawRect(
      Rect.fromLTWH(
        margin,
        margin,
        size.width - margin * 2,
        size.height - margin * 2,
      ),
      hairline..style = PaintingStyle.stroke,
    );
    for (var i = 1; i < 3; i++) {
      final x = margin + (size.width - margin * 2) * i / 3;
      canvas.drawLine(
        Offset(x, margin),
        Offset(x, size.height - margin),
        hairline,
      );
    }
    canvas.drawLine(
      Offset(margin, size.height * 0.17),
      Offset(size.width - margin, size.height * 0.17),
      hairline,
    );
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, s * 0.055, s * 0.014),
      Paint()..color = const Color(0xFFD94C3D).withValues(alpha: 0.78),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - margin - s * 0.13,
        size.height - margin - s * 0.014,
        s * 0.13,
        s * 0.014,
      ),
      Paint()..color = ink.withValues(alpha: 0.72),
    );
    _paintCropMark(canvas, Offset(margin, margin), s, ink);
    _paintCropMark(
      canvas,
      Offset(size.width - margin, size.height - margin),
      s,
      ink,
      reverse: true,
    );
  }

  void _paintMidnightAtlas(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final gold = Color.lerp(accent, const Color(0xFFFFE0A0), 0.35)!;
    _doubleBorder(canvas, size, gold, s * 0.05, radius: s * 0.02);
    final starPaint = Paint()..color = gold.withValues(alpha: 0.42);
    final linePaint = Paint()
      ..color = gold.withValues(alpha: 0.18)
      ..strokeWidth = math.max(0.55, s * 0.002);
    final points = [
      Offset(s * 0.13, s * 0.2),
      Offset(s * 0.25, s * 0.11),
      Offset(s * 0.36, s * 0.24),
      Offset(size.width - s * 0.31, size.height - s * 0.16),
      Offset(size.width - s * 0.19, size.height - s * 0.27),
      Offset(size.width - s * 0.1, size.height - s * 0.13),
    ];
    canvas.drawLine(points[0], points[1], linePaint);
    canvas.drawLine(points[1], points[2], linePaint);
    canvas.drawLine(points[3], points[4], linePaint);
    canvas.drawLine(points[4], points[5], linePaint);
    for (final point in points) {
      canvas.drawCircle(point, s * 0.008, starPaint);
      canvas.drawCircle(
        point,
        s * 0.0025,
        Paint()..color = gold.withValues(alpha: 0.78),
      );
    }
    _paintCrescent(
      canvas,
      Offset(size.width - s * 0.16, s * 0.16),
      s * 0.055,
      gold,
    );
    _paintCompass(
      canvas,
      Offset(s * 0.16, size.height - s * 0.17),
      s * 0.07,
      gold,
    );
  }

  void _paintDarkLeather(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final gold = Color.lerp(accent, const Color(0xFFFFDA78), 0.3)!;
    _doubleBorder(canvas, size, gold, s * 0.05, radius: s * 0.018);
    final faint = Paint()
      ..color = gold.withValues(alpha: 0.075)
      ..strokeWidth = math.max(0.45, s * 0.0016);
    for (var i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(
        Offset(s * 0.075, y),
        Offset(size.width - s * 0.075, y),
        faint,
      );
    }
    _paintOrnateCorner(canvas, Offset(s * 0.05, s * 0.05), gold, s);
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    _paintOrnateCorner(canvas, Offset(s * 0.05, s * 0.05), gold, s);
    canvas.restore();
    _paintDiamond(canvas, Offset(size.width / 2, s * 0.052), s * 0.022, gold);
    _paintDiamond(
      canvas,
      Offset(size.width / 2, size.height - s * 0.052),
      s * 0.022,
      gold,
    );
  }

  void _doubleBorder(
    Canvas canvas,
    Size size,
    Color color,
    double margin, {
    required double radius,
  }) {
    final outer = Paint()
      ..color = color.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.shortestSide * 0.0035);
    final inner = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.45, size.shortestSide * 0.0018);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          margin,
          margin,
          size.width - margin * 2,
          size.height - margin * 2,
        ),
        Radius.circular(radius),
      ),
      outer,
    );
    final inset = margin * 0.34;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          margin + inset,
          margin + inset,
          size.width - (margin + inset) * 2,
          size.height - (margin + inset) * 2,
        ),
        Radius.circular(radius * 0.72),
      ),
      inner,
    );
  }

  void _dottedBorder(Canvas canvas, Size size, Color color, double margin) {
    final paint = Paint()..color = color.withValues(alpha: 0.34);
    final step = math.max(8.0, size.shortestSide * 0.045);
    for (double x = margin; x <= size.width - margin; x += step) {
      canvas.drawCircle(Offset(x, margin), size.shortestSide * 0.006, paint);
      canvas.drawCircle(
        Offset(x, size.height - margin),
        size.shortestSide * 0.006,
        paint,
      );
    }
    for (double y = margin; y <= size.height - margin; y += step) {
      canvas.drawCircle(Offset(margin, y), size.shortestSide * 0.006, paint);
      canvas.drawCircle(
        Offset(size.width - margin, y),
        size.shortestSide * 0.006,
        paint,
      );
    }
  }

  void _scallopedBorder(Canvas canvas, Size size, Color color, double margin) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, size.shortestSide * 0.003);
    final radius = size.shortestSide * 0.022;
    for (double x = margin; x < size.width - margin; x += radius * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, margin), radius: radius),
        0,
        math.pi,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(x, size.height - margin),
          radius: radius,
        ),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  void _paintVine(
    Canvas canvas,
    Offset origin,
    bool reverse,
    Color color,
    double s,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (reverse) canvas.rotate(math.pi);
    final stem = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, s * 0.003);
    final path = Path()
      ..moveTo(0, s * 0.19)
      ..cubicTo(s * 0.015, s * 0.1, s * 0.08, s * 0.055, s * 0.2, 0);
    canvas.drawPath(path, stem);
    final leaf = Paint()..color = color.withValues(alpha: 0.24);
    for (var i = 0; i < 4; i++) {
      final x = s * (0.045 + i * 0.038);
      final y = s * (0.13 - i * 0.03);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: s * 0.045,
          height: s * 0.018,
        ),
        leaf,
      );
    }
    canvas.restore();
  }

  void _paintHeart(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + radius * 0.8)
      ..cubicTo(
        center.dx - radius * 1.4,
        center.dy,
        center.dx - radius * 0.8,
        center.dy - radius,
        center.dx,
        center.dy - radius * 0.25,
      )
      ..cubicTo(
        center.dx + radius * 0.8,
        center.dy - radius,
        center.dx + radius * 1.4,
        center.dy,
        center.dx,
        center.dy + radius * 0.8,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.34));
  }

  void _paintPaw(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final paint = Paint()..color = color.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius * 0.28),
        width: radius * 1.15,
        height: radius * 0.9,
      ),
      paint,
    );
    for (var i = 0; i < 4; i++) {
      final x = (i - 1.5) * radius * 0.34;
      final y = -radius * (0.42 + (i == 0 || i == 3 ? 0 : 0.18));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 0.34,
          height: radius * 0.48,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  void _paintPostmark(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, radius * 0.06);
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.72, paint);
    for (var i = -1; i <= 1; i++) {
      final y = center.dy + radius * (0.75 + i * 0.18);
      canvas.drawLine(
        Offset(center.dx - radius * 1.25, y),
        Offset(center.dx + radius * 1.25, y),
        paint,
      );
    }
  }

  void _paintCornerFlourish(
    Canvas canvas,
    Offset corner,
    Color color,
    double s,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, s * 0.003);
    final path = Path()
      ..moveTo(corner.dx, corner.dy - s * 0.18)
      ..quadraticBezierTo(
        corner.dx + s * 0.02,
        corner.dy - s * 0.06,
        corner.dx + s * 0.17,
        corner.dy,
      )
      ..moveTo(corner.dx + s * 0.05, corner.dy - s * 0.05)
      ..quadraticBezierTo(
        corner.dx + s * 0.09,
        corner.dy - s * 0.12,
        corner.dx + s * 0.16,
        corner.dy - s * 0.11,
      );
    canvas.drawPath(path, paint);
  }

  void _paintPaperPlane(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final path = Path()
      ..moveTo(center.dx - size, center.dy + size * 0.35)
      ..lineTo(center.dx + size, center.dy - size * 0.55)
      ..lineTo(center.dx + size * 0.18, center.dy + size)
      ..lineTo(center.dx - size * 0.04, center.dy + size * 0.2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size * 0.08),
    );
  }

  void _paintStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * 0.42;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.35));
  }

  void _paintCropMark(
    Canvas canvas,
    Offset point,
    double s,
    Color color, {
    bool reverse = false,
  }) {
    final direction = reverse ? -1.0 : 1.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.48)
      ..strokeWidth = math.max(0.7, s * 0.003);
    canvas.drawLine(point, point + Offset(direction * s * 0.07, 0), paint);
    canvas.drawLine(point, point + Offset(0, direction * s * 0.07), paint);
  }

  void _paintCrescent(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final outer = Paint()..color = color.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius, outer);
    canvas.drawCircle(
      center + Offset(radius * 0.38, -radius * 0.16),
      radius * 0.84,
      Paint()..color = paperColor.withValues(alpha: 0.94),
    );
  }

  void _paintCompass(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, radius * 0.07);
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      center - Offset(0, radius * 1.25),
      center + Offset(0, radius * 1.25),
      paint,
    );
    canvas.drawLine(
      center - Offset(radius * 1.25, 0),
      center + Offset(radius * 1.25, 0),
      paint,
    );
    _paintDiamond(canvas, center, radius * 0.5, color);
  }

  void _paintOrnateCorner(Canvas canvas, Offset corner, Color color, double s) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, s * 0.003);
    final path = Path()
      ..moveTo(corner.dx, corner.dy + s * 0.18)
      ..lineTo(corner.dx, corner.dy)
      ..lineTo(corner.dx + s * 0.18, corner.dy)
      ..moveTo(corner.dx + s * 0.025, corner.dy + s * 0.13)
      ..quadraticBezierTo(
        corner.dx + s * 0.04,
        corner.dy + s * 0.045,
        corner.dx + s * 0.13,
        corner.dy + s * 0.025,
      )
      ..moveTo(corner.dx + s * 0.04, corner.dy + s * 0.04)
      ..lineTo(corner.dx + s * 0.1, corner.dy + s * 0.1);
    canvas.drawPath(path, paint);
  }

  void _paintDiamond(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.34));
  }

  @override
  bool shouldRepaint(covariant _ThemePagePainter oldDelegate) =>
      oldDelegate.themeId != themeId ||
      oldDelegate.accent != accent ||
      oldDelegate.paperColor != paperColor;
}
