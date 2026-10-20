import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'occasion_cards.dart';

/// Resolution independent artwork shared by the studio, thumbnails and export.
class CardArtwork extends CustomPainter {
  CardArtwork(this.template);
  final OccasionCardTemplate template;
  @override
  void paint(Canvas canvas, Size size) {
    if (template.layout == 'scrapbook') return;
    canvas.save();
    canvas.scale(size.width / 500, size.height / 700);
    final accent = template.accentColor;
    final pen = Paint()
      ..color = accent.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = template.secondaryColor.withValues(alpha: .5);
    // Small paper fibres and imperfect ink edges remain crisp at export size.
    if (template.layout != 'blank') {
      final fibres = math.Random(71);
      final grain = Paint()..color = accent.withValues(alpha: .045);
      for (var i = 0; i < 620; i++) {
        final x = fibres.nextDouble() * 500;
        final y = fibres.nextDouble() * 700;
        canvas.drawLine(Offset(x, y), Offset(x + 1.8, y + .5), grain);
      }
    }
    switch (template.layout) {
      case 'herbarium':
        _wash(
          canvas,
          const Offset(408, 190),
          const Size(115, 210),
          template.secondaryColor,
          8,
        );
        _branch(canvas, const Offset(422, 640), -2.85, 1.2, accent, 32);
        _branch(canvas, const Offset(34, 20), -.20, .56, accent, 12);
        canvas.drawLine(const Offset(55, 565), const Offset(195, 565), pen);
      case 'letterpress':
        canvas.drawLine(
          const Offset(48, 105),
          const Offset(452, 105),
          pen..strokeWidth = 2,
        );
        canvas.drawLine(
          const Offset(48, 585),
          const Offset(285, 585),
          pen..strokeWidth = 1,
        );
        canvas.save();
        canvas.translate(401, 599);
        canvas.rotate(-.12);
        for (var i = 0; i < 3; i++) {
          canvas.drawRect(
            Rect.fromLTWH(-37 + i * 4, -37 + i * 4, 74 - i * 8, 74 - i * 8),
            pen..color = accent.withValues(alpha: .45),
          );
        }
        _asterisk(canvas, Offset.zero, 18, accent);
        canvas.restore();
      case 'celestial':
        final random = math.Random(112);
        for (var i = 0; i < 75; i++) {
          final p = Offset(
            25 + random.nextDouble() * 450,
            20 + random.nextDouble() * 660,
          );
          if (p.dy > 195 && p.dy < 515 && p.dx > 65 && p.dx < 435) continue;
          canvas.drawCircle(
            p,
            random.nextDouble() * 1.6 + .4,
            Paint()
              ..color = accent.withValues(
                alpha: .25 + random.nextDouble() * .5,
              ),
          );
        }
        canvas.drawArc(
          const Rect.fromLTWH(46, 38, 408, 624),
          -.35,
          3.9,
          false,
          pen
            ..color = accent.withValues(alpha: .3)
            ..strokeWidth = .8,
        );
        canvas.drawArc(
          const Rect.fromLTWH(60, 51, 380, 598),
          2.8,
          2.1,
          false,
          pen,
        );
        _asterisk(canvas, const Offset(250, 131), 23, accent);
        canvas.drawCircle(
          const Offset(237, 573),
          20,
          pen
            ..color = accent.withValues(alpha: .7)
            ..strokeWidth = 1.8,
        );
        canvas.drawCircle(const Offset(263, 573), 20, pen);
      case 'cutout':
        _tornShape(
          canvas,
          const Rect.fromLTWH(-35, -25, 226, 192),
          template.secondaryColor,
          4,
          -.12,
        );
        _tornShape(
          canvas,
          const Rect.fromLTWH(331, 575, 214, 246),
          accent,
          12,
          .18,
        );
        _tornShape(
          canvas,
          const Rect.fromLTWH(-20, 571, 180, 166),
          const Color(0xFFDAB85A),
          23,
          .24,
        );
        _asterisk(canvas, const Offset(414, 125), 48, const Color(0xFFDAB85A));
        _asterisk(canvas, const Offset(78, 536), 23, template.secondaryColor);
      case 'postcard':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(32, 30, 436, 640),
            const Radius.circular(4),
          ),
          pen..color = accent.withValues(alpha: .25),
        );
        final stamp = Paint()
          ..color = accent.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawRect(const Rect.fromLTWH(376, 60, 68, 90), stamp);
        for (var i = 0; i < 10; i++) {
          canvas.drawCircle(
            Offset(376, 63 + i * 9),
            2.5,
            Paint()..color = template.primaryColor,
          );
          canvas.drawCircle(
            Offset(444, 63 + i * 9),
            2.5,
            Paint()..color = template.primaryColor,
          );
        }
        _branch(canvas, const Offset(413, 139), -math.pi, .26, accent, 44);
        canvas.drawCircle(const Offset(352, 120), 40, stamp);
        canvas.drawCircle(const Offset(352, 120), 34, stamp);
        for (var i = 0; i < 3; i++) {
          final path = Path()..moveTo(45, 557 + i * 19);
          for (var j = 0; j < 6; j++) {
            path.relativeQuadraticBezierTo(13, -8, 26, 0);
          }
          canvas.drawPath(path, stamp);
        }
      case 'gallery':
        canvas.save();
        canvas.translate(250, 258);
        canvas.rotate(-.035);
        canvas.drawShadow(
          Path()..addRect(const Rect.fromLTWH(-183, -174, 366, 345)),
          Colors.black,
          7,
          false,
        );
        canvas.drawRect(
          const Rect.fromLTWH(-183, -174, 366, 345),
          Paint()..color = const Color(0xFFFFFCF5),
        );
        final rect = const Rect.fromLTWH(-166, -157, 332, 278);
        canvas.drawRect(
          rect,
          Paint()..color = template.secondaryColor.withValues(alpha: .55),
        );
        canvas.drawCircle(
          const Offset(-65, -63),
          25,
          Paint()..color = template.primaryColor.withValues(alpha: .8),
        );
        canvas.drawPath(
          Path()
            ..moveTo(-166, 121)
            ..lineTo(-56, -10)
            ..lineTo(20, 66)
            ..lineTo(80, 8)
            ..lineTo(166, 121)
            ..close(),
          Paint()..color = accent.withValues(alpha: .13),
        );
        canvas.restore();
        _tornShape(
          canvas,
          const Rect.fromLTWH(191, 56, 118, 34),
          const Color(0xFFE1C69D).withValues(alpha: .65),
          31,
          -.06,
        );
        canvas.drawLine(
          const Offset(52, 647),
          const Offset(448, 647),
          pen..color = accent.withValues(alpha: .25),
        );
      case 'coastal':
        for (var i = 0; i < 5; i++) {
          final y = 525 + i * 33.0;
          final wave = Path()
            ..moveTo(0, y)
            ..cubicTo(130, y - 50, 280, y + 50, 500, y - 12)
            ..lineTo(500, 700)
            ..lineTo(0, 700)
            ..close();
          canvas.drawPath(
            wave,
            Paint()
              ..color = Color.lerp(
                template.secondaryColor,
                accent,
                i / 6,
              )!.withValues(alpha: .25),
          );
        }
        canvas.drawCircle(
          const Offset(390, 125),
          39,
          Paint()..color = const Color(0xFFD3B57A).withValues(alpha: .55),
        );
        for (var i = 0; i < 3; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(68 + i * 24, 108 + i * 10)
              ..quadraticBezierTo(
                77 + i * 24,
                94 + i * 10,
                88 + i * 24,
                106 + i * 10,
              ),
            pen..color = accent.withValues(alpha: .4),
          );
        }
      case 'ribbon':
        canvas.drawRect(
          const Rect.fromLTWH(33, 33, 434, 634),
          pen..color = accent.withValues(alpha: .55),
        );
        canvas.drawRect(
          const Rect.fromLTWH(40, 40, 420, 620),
          pen..color = accent.withValues(alpha: .18),
        );
        final ribbon = Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(250, 128)
            ..cubicTo(114, 5, 134, 184, 250, 128)
            ..cubicTo(351, 12, 394, 189, 250, 128),
          ribbon,
        );
        canvas.drawPath(
          Path()
            ..moveTo(250, 128)
            ..cubicTo(210, 165, 248, 196, 204, 211),
          ribbon..strokeWidth = 6,
        );
        canvas.drawPath(
          Path()
            ..moveTo(250, 128)
            ..cubicTo(281, 176, 265, 194, 305, 221),
          ribbon,
        );
        _branch(
          canvas,
          const Offset(309, 615),
          -2.2,
          .45,
          accent.withValues(alpha: .6),
          14,
        );
      case 'floral':
        _wash(
          canvas,
          const Offset(60, 135),
          const Size(95, 122),
          template.secondaryColor,
          61,
        );
        _wash(
          canvas,
          const Offset(449, 570),
          const Size(92, 119),
          template.secondaryColor,
          29,
        );
        _branch(canvas, const Offset(39, 242), -2.9, .8, accent, 34);
        _branch(canvas, const Offset(468, 498), .3, .8, accent, 28);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(49, 40, 402, 620),
            const Radius.circular(180),
          ),
          pen
            ..color = accent.withValues(alpha: .18)
            ..strokeWidth = .8,
        );
      case 'geometric':
        for (final inset in [18.0, 27.0, 42.0]) {
          canvas.drawRect(
            Rect.fromLTRB(inset, inset, 500 - inset, 700 - inset),
            pen,
          );
        }
        for (final center in [const Offset(250, 110), const Offset(250, 598)]) {
          final moon = Path.combine(
            PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: center, radius: 27)),
            Path()..addOval(
              Rect.fromCircle(
                center: center + const Offset(13, -7),
                radius: 24,
              ),
            ),
          );
          canvas.drawPath(moon, Paint()..color = accent.withValues(alpha: .8));
        }
      case 'arch':
        final arch = Path()
          ..moveTo(60, 650)
          ..lineTo(60, 250)
          ..cubicTo(60, 20, 440, 20, 440, 250)
          ..lineTo(440, 650)
          ..close();
        canvas.drawPath(arch, fill);
        canvas.drawPath(arch, pen);
        canvas.drawCircle(
          const Offset(250, 115),
          30,
          Paint()..color = template.primaryColor,
        );
        canvas.drawLine(const Offset(190, 595), const Offset(310, 595), pen);
      case 'confetti':
        final random = math.Random(
          template.id.codeUnits.fold<int>(0, (a, b) => a + b),
        );
        for (var i = 0; i < 42; i++) {
          final x = random.nextDouble() * 500;
          final y = random.nextBool()
              ? random.nextDouble() * 90
              : 590 + random.nextDouble() * 110;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(random.nextDouble() * math.pi);
          final paint = Paint()
            ..color = [
              accent,
              template.secondaryColor,
              const Color(0xFFD7AE58),
            ][i % 3].withValues(alpha: .65);
          if (i.isEven) {
            canvas.drawCircle(Offset.zero, 3 + random.nextDouble() * 4, paint);
          } else {
            canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 13), paint);
          }
          canvas.restore();
        }
      case 'editorial':
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 18, 700),
          Paint()..color = accent,
        );
        canvas.drawLine(const Offset(50, 95), const Offset(450, 95), pen);
        canvas.drawLine(
          const Offset(50, 600),
          const Offset(220, 600),
          pen..strokeWidth = 4,
        );
        canvas.drawCircle(const Offset(427, 605), 24, fill);
      case 'photo':
        canvas.save();
        canvas.translate(250, 275);
        canvas.rotate(-.04);
        canvas.drawRect(
          const Rect.fromLTWH(-180, -140, 360, 280),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(const Rect.fromLTWH(-164, -124, 328, 226), fill);
        canvas.drawRect(const Rect.fromLTWH(-180, -140, 360, 280), pen);
        canvas.restore();
      default:
        break;
    }
    canvas.restore();
  }

  void _branch(
    Canvas canvas,
    Offset origin,
    double rotation,
    double scale,
    Color color,
    int seed,
  ) {
    final random = math.Random(seed);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(-20, 76, 34, 175, 3, 254),
      Paint()
        ..color = color.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    for (var i = 0; i < 9; i++) {
      canvas.save();
      canvas.translate(4 + math.sin(i * .8) * 8, 30 + i * 24);
      canvas.rotate((i.isEven ? -1 : 1) * (.55 + random.nextDouble() * .35));
      final leaf = Path()
        ..moveTo(0, 0)
        ..cubicTo(-16, 18, -12, 47, 1, 64)
        ..cubicTo(17, 43, 19, 16, 0, 0)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..color = color.withValues(alpha: .14 + random.nextDouble() * .2),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, 4)
          ..quadraticBezierTo(3, 32, 1, 59),
        Paint()
          ..color = color.withValues(alpha: .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _wash(Canvas canvas, Offset center, Size size, Color color, int seed) {
    final random = math.Random(seed);
    for (var i = 0; i < 16; i++) {
      final path = Path();
      for (var j = 0; j <= 32; j++) {
        final angle = j / 32 * math.pi * 2;
        final r = .8 + random.nextDouble() * .2;
        final p = Offset(
          center.dx + math.cos(angle) * size.width * r,
          center.dy + math.sin(angle) * size.height * r,
        );
        j == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path..close(),
        Paint()..color = color.withValues(alpha: .025),
      );
    }
  }

  void _tornShape(
    Canvas canvas,
    Rect rect,
    Color color,
    int seed,
    double angle,
  ) {
    final random = math.Random(seed);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);
    final path = Path();
    for (var side = 0; side < 4; side++) {
      for (var i = 0; i < 16; i++) {
        final t = i / 16;
        final wobble = random.nextDouble() * 4;
        final p = switch (side) {
          0 => Offset(
            -rect.width / 2 + rect.width * t,
            -rect.height / 2 + wobble,
          ),
          1 => Offset(
            rect.width / 2 - wobble,
            -rect.height / 2 + rect.height * t,
          ),
          2 => Offset(
            rect.width / 2 - rect.width * t,
            rect.height / 2 - wobble,
          ),
          _ => Offset(
            -rect.width / 2 + wobble,
            rect.height / 2 - rect.height * t,
          ),
        };
        side == 0 && i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawShadow(
      path..close(),
      Colors.black.withValues(alpha: .15),
      2,
      false,
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _asterisk(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final r = i.isEven ? radius : radius * .34;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(CardArtwork oldDelegate) =>
      oldDelegate.template != template;
}
