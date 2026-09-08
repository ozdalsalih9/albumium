import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'occasion_cards.dart';

/// Resolution independent artwork shared by the studio, thumbnails and export.
class CardArtwork extends CustomPainter {
  CardArtwork(this.template);
  final OccasionCardTemplate template;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 500, size.height / 700);
    final accent = template.accentColor;
    final pen = Paint()
      ..color = accent.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = template.secondaryColor.withValues(alpha: .5);
    switch (template.layout) {
      case 'floral':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(32, 32, 436, 636),
            const Radius.circular(180),
          ),
          pen,
        );
        for (final corner in [const Offset(40, 80), const Offset(460, 620)]) {
          canvas.save();
          canvas.translate(corner.dx, corner.dy);
          if (corner.dx > 250) canvas.rotate(math.pi);
          final stem = Path()
            ..moveTo(0, -40)
            ..quadraticBezierTo(110, 80, 35, 220);
          canvas.drawPath(stem, pen..color = accent.withValues(alpha: .6));
          for (var i = 0; i < 6; i++) {
            canvas.save();
            canvas.translate(28 + i * 5, i * 32.0);
            canvas.rotate(i.isEven ? -.6 : .7);
            canvas.drawOval(const Rect.fromLTWH(-8, 0, 34, 66), fill);
            canvas.restore();
          }
          for (var petal = 0; petal < 7; petal++) {
            canvas.save();
            canvas.translate(40, 32);
            canvas.rotate(petal * math.pi * 2 / 7);
            canvas.drawOval(
              const Rect.fromLTWH(-14, -45, 28, 48),
              Paint()..color = template.secondaryColor,
            );
            canvas.restore();
          }
          canvas.drawCircle(const Offset(40, 32), 9, Paint()..color = accent);
          canvas.restore();
        }
      case 'geometric':
        for (final inset in [18.0, 27.0, 42.0]) {
          canvas.drawRect(
            Rect.fromLTRB(inset, inset, 500 - inset, 700 - inset),
            pen,
          );
        }
        for (final center in [const Offset(250, 110), const Offset(250, 598)]) {
          for (var i = 0; i < 8; i++) {
            canvas.save();
            canvas.translate(center.dx, center.dy);
            canvas.rotate(i * math.pi / 4);
            canvas.drawRect(const Rect.fromLTWH(-25, -25, 50, 50), pen);
            canvas.restore();
          }
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
        for (var i = 0; i < 90; i++) {
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

  @override
  bool shouldRepaint(CardArtwork oldDelegate) =>
      oldDelegate.template != template;
}
