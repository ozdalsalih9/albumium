import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'paper_materials.dart';

const scrapbookArt = <String, (String, double)>{
  'denim_strip': ('Denim şerit', .32),
  'burgundy_strip': ('Bordo kumaş', .25),
  'sage_strip': ('Yeşil ekose şerit', .35),
  'lace_strip': ('Dantel şerit', .12),
  'pocket': ('Kot cebi', 1.4),
  'button_gold': ('Pirinç düğme', 1),
  'button_green': ('Yeşil düğme', 1),
  'button_blue': ('Mavi düğme', 1),
  'ticket': ('Hatıra bileti', 3.2),
  'hat': ('Kovboy şapkası', 1.8),
  'music': ('Nota şeridi', .8),
  'lime_panel': ('Fıstık yeşili kumaş', .85),
  'blue_panel': ('Mavi ekose parça', .8),
  'star_navy': ('Lacivert kumaş yıldız', 1),
  'star_sage': ('Yeşil kumaş yıldız', 1),
  'star_gold': ('Sarı kumaş yıldız', 1),
  'star_pink': ('Pembe kumaş yıldız', 1),
  'bow_sage': ('Yeşil fiyonk', 1.7),
  'bow_red': ('Kırmızı fiyonk', 1.7),
  'tree': ('Küçük ağaç', .8),
  'leaf': ('Yaprak dalı', .65),
  'strawberry': ('Kumaş çilek', .8),
  'vinyl': ('Yeşil plak', 1),
  'lily': ('Zambak kolajı', 1.25),
};

class ScrapbookArtImage extends StatelessWidget {
  const ScrapbookArtImage(this.design, {super.key, this.preview = false});
  final String design;
  final bool preview;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/scrapbook/$design.webp',
    fit: preview ? BoxFit.contain : BoxFit.fill,
    cacheWidth: preview
        ? (140 * math.min(1, scrapbookArt[design]?.$2 ?? 1)).ceil()
        : (scrapbookArt[design]?.$2 ?? 1) < .4
        ? 200
        : 600,
    filterQuality: FilterQuality.low,
  );
}

/// Source for bundled raster artwork. This painter runs only in the asset tool.
class ScrapbookArtPainter extends CustomPainter {
  const ScrapbookArtPainter(this.design);
  final String design;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 200, size.height / 200);
    const cream = Color(0xFFECE1C4);
    const green = Color(0xFF637B4F);
    const red = Color(0xFFA43143);
    final paint = Paint();
    void fill(Path path, Color color) {
      c.drawShadow(path, const Color(0x55000000), 2, false);
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .18)!,
              color,
              Color.lerp(color, Colors.black, .22)!,
            ],
          ).createShader(const Rect.fromLTWH(0, 0, 200, 200)),
      );
    }

    void stitch(Path path, Color color) {
      for (final metric in path.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 6) {
          c.drawPath(
            metric.extractPath(d, math.min(d + 3, metric.length)),
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.1,
          );
        }
      }
    }

    final rect = Rect.fromLTWH(4, 3, 192, 194);
    if (design.endsWith('_strip') && design != 'lace_strip' ||
        design.endsWith('_panel')) {
      final material = switch (design) {
        'denim_strip' => 'denim',
        'burgundy_strip' => 'burgundy',
        'sage_strip' => 'sage',
        'blue_panel' => 'blue',
        _ => 'lime',
      };
      PaperMaterialPainter.paintMaterial(c, rect, material);
      stitch(Path()..addRect(rect.deflate(3)), cream.withValues(alpha: .7));
    } else if (design == 'lace_strip') {
      final thread = Paint()
        ..color = cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (double y = 10; y < 200; y += 18) {
        for (var side = 0; side < 2; side++) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(side == 0 ? 55 : 145, y),
              width: 90,
              height: 26,
            ),
            thread,
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset(side == 0 ? 55 : 145, y),
              width: 65,
              height: 18,
            ),
            thread,
          );
          for (var i = 0; i < 6; i++) {
            c.drawLine(
              Offset(100, y),
              Offset(side == 0 ? 10.0 : 190.0, y - 9 + i * 3),
              thread..strokeWidth = .8,
            );
          }
        }
      }
      c.drawRect(
        const Rect.fromLTWH(75, 0, 50, 200),
        Paint()..color = cream.withValues(alpha: .6),
      );
      stitch(
        Path()
          ..moveTo(95, 0)
          ..lineTo(95, 200),
        const Color(0xFF907D58),
      );
    } else if (design == 'pocket') {
      final path = Path()
        ..moveTo(9, 10)
        ..lineTo(190, 10)
        ..lineTo(179, 154)
        ..quadraticBezierTo(100, 199, 22, 154)
        ..close();
      c.drawShadow(path, Colors.black54, 4, false);
      c.save();
      c.clipPath(path);
      PaperMaterialPainter.paintMaterial(c, rect, 'denim');
      c.restore();
      stitch(
        Path()
          ..moveTo(17, 16)
          ..lineTo(181, 16)
          ..lineTo(171, 150)
          ..quadraticBezierTo(100, 184, 30, 150)
          ..close(),
        const Color(0xFFD4AC61),
      );
      stitch(
        Path()
          ..moveTo(20, 24)
          ..lineTo(179, 24),
        const Color(0xFFC29544),
      );
      for (final x in [20.0, 178.0]) {
        c.drawCircle(
          Offset(x, 22),
          3.5,
          Paint()..color = const Color(0xFFC9A361),
        );
      }
    } else if (design.startsWith('button_')) {
      final base = design.endsWith('gold')
          ? const Color(0xFFB9A26F)
          : design.endsWith('green')
          ? green
          : const Color(0xFF48667A);
      fill(Path()..addOval(const Rect.fromLTWH(16, 16, 168, 168)), base);
      c.drawCircle(
        const Offset(100, 100),
        65,
        Paint()
          ..color = Color.lerp(base, Colors.black, .3)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      c.drawCircle(
        const Offset(98, 97),
        65,
        Paint()
          ..color = cream.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final x in [85.0, 115.0]) {
        for (final y in [85.0, 115.0]) {
          c.drawCircle(
            Offset(x, y),
            6,
            Paint()..color = const Color(0xFF323C32),
          );
        }
      }
      c.drawLine(
        const Offset(85, 85),
        const Offset(115, 115),
        Paint()
          ..color = cream
          ..strokeWidth = 4,
      );
      c.drawLine(
        const Offset(115, 85),
        const Offset(85, 115),
        Paint()
          ..color = cream
          ..strokeWidth = 4,
      );
    } else if (design.startsWith('star_')) {
      final color = switch (design) {
        'star_navy' => const Color(0xFF233A5D),
        'star_pink' => const Color(0xFFCE96AA),
        'star_gold' => const Color(0xFFCFAD43),
        _ => green,
      };
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final r = i.isEven ? 88 : 39;
        final x = 100 + math.cos(a) * r, y = 100 + math.sin(a) * r;
        if (i == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      star.close();
      fill(star, color);
      c.save();
      c.translate(16, 16);
      c.scale(.84);
      stitch(star, cream.withValues(alpha: .65));
      c.restore();
    } else if (design.startsWith('bow_')) {
      final color = design.endsWith('red') ? red : green;
      fill(
        Path()
          ..moveTo(92, 87)
          ..cubicTo(28, 0, 0, 35, 19, 99)
          ..quadraticBezierTo(40, 135, 92, 103)
          ..lineTo(62, 180)
          ..lineTo(83, 163)
          ..lineTo(100, 183)
          ..lineTo(109, 106)
          ..quadraticBezierTo(176, 142, 187, 92)
          ..cubicTo(195, 30, 160, 16, 108, 87)
          ..close(),
        color,
      );
      c.drawOval(
        const Rect.fromLTWH(86, 75, 29, 42),
        Paint()..color = Color.lerp(color, Colors.black, .15)!,
      );
      c.drawPath(
        Path()
          ..moveTo(20, 56)
          ..quadraticBezierTo(60, 75, 85, 95)
          ..moveTo(179, 58)
          ..quadraticBezierTo(138, 80, 116, 95),
        Paint()
          ..color = cream.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (design == 'vinyl') {
      fill(
        Path()..addOval(const Rect.fromLTWH(5, 5, 190, 190)),
        const Color(0xFF28583F),
      );
      for (double r = 42; r < 91; r += 2.3) {
        c.drawCircle(
          const Offset(100, 100),
          r,
          Paint()
            ..color = cream.withValues(alpha: .12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .45,
        );
      }
      c.drawCircle(const Offset(100, 100), 39, Paint()..color = cream);
      final rand = math.Random(78);
      for (var i = 0; i < 28; i++) {
        final a = rand.nextDouble() * math.pi * 2, r = rand.nextDouble() * 32;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(100 + math.cos(a) * r, 100 + math.sin(a) * r),
            width: 5,
            height: 2,
          ),
          Paint()..color = red.withValues(alpha: .7),
        );
      }
      c.drawCircle(
        const Offset(100, 100),
        5,
        Paint()..color = const Color(0xFF1D3428),
      );
      c.drawArc(
        const Rect.fromLTWH(20, 20, 160, 160),
        -.8,
        .7,
        false,
        Paint()
          ..color = cream.withValues(alpha: .15)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke,
      );
    } else if (design == 'hat') {
      fill(
        Path()..addOval(const Rect.fromLTWH(6, 105, 188, 64)),
        const Color(0xFF9F693A),
      );
      fill(
        Path()
          ..moveTo(45, 124)
          ..lineTo(59, 36)
          ..quadraticBezierTo(78, 24, 100, 40)
          ..quadraticBezierTo(125, 20, 145, 36)
          ..lineTo(161, 124)
          ..quadraticBezierTo(100, 146, 45, 124)
          ..close(),
        const Color(0xFFAE7B48),
      );
      c.drawPath(
        Path()
          ..moveTo(48, 112)
          ..quadraticBezierTo(105, 131, 158, 111),
        Paint()
          ..color = const Color(0xFF513427)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(90, 110, 22, 14),
          const Radius.circular(2),
        ),
        Paint()
          ..color = cream
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    } else if (design == 'ticket' || design == 'music') {
      fill(Path()..addRect(rect), cream);
      c.drawRect(
        rect.deflate(8),
        Paint()
          ..color = red.withValues(alpha: .55)
          ..style = PaintingStyle.stroke,
      );
      if (design == 'ticket') {
        final rand = math.Random(52);
        for (double x = 20; x < 180; x += 3) {
          c.drawRect(
            Rect.fromLTWH(x, 75, 1 + rand.nextDouble() * 1.3, 70),
            Paint()..color = const Color(0xFF514332),
          );
        }
        for (double y = 25; y < 65; y += 13) {
          c.drawLine(
            Offset(30, y),
            Offset(170, y),
            Paint()
              ..color = red.withValues(alpha: .6)
              ..strokeWidth = 2,
          );
        }
      } else {
        for (double y = 30; y < 190; y += 45) {
          for (var i = 0; i < 5; i++) {
            c.drawLine(
              Offset(10, y + i * 5),
              Offset(190, y + i * 5),
              Paint()
                ..color = const Color(0xFF6B624E)
                ..strokeWidth = .8,
            );
          }
          for (final x in [32.0, 94.0, 157.0]) {
            c.drawOval(
              Rect.fromLTWH(x, y + 8, 16, 8),
              Paint()..color = const Color(0xFF514332),
            );
            c.drawLine(
              Offset(x + 14, y + 12),
              Offset(x + 14, y - 13),
              Paint()
                ..color = const Color(0xFF514332)
                ..strokeWidth = 2,
            );
          }
        }
      }
    } else if (design == 'strawberry') {
      fill(
        Path()
          ..moveTo(100, 189)
          ..cubicTo(-25, 100, 15, 24, 70, 42)
          ..quadraticBezierTo(100, 22, 134, 43)
          ..cubicTo(198, 18, 217, 105, 100, 189)
          ..close(),
        red,
      );
      final rand = math.Random(3);
      for (var i = 0; i < 45; i++) {
        final x = 35 + rand.nextDouble() * 130,
            y = 55 + rand.nextDouble() * 100;
        if ((x - 100).abs() < (190 - y) * .65) {
          c.drawOval(Rect.fromLTWH(x, y, 2, 5), Paint()..color = cream);
        }
      }
      for (var i = 0; i < 5; i++) {
        c.save();
        c.translate(100, 40);
        c.rotate(i * .65 - .9);
        c.drawOval(
          const Rect.fromLTWH(-8, -35, 16, 53),
          Paint()..color = green,
        );
        c.restore();
      }
    } else if (design == 'tree' || design == 'leaf') {
      c.drawPath(
        Path()
          ..moveTo(90, 190)
          ..quadraticBezierTo(104, 110, 95, 40),
        Paint()
          ..color = const Color(0xFF796146)
          ..style = PaintingStyle.stroke
          ..strokeWidth = design == 'tree' ? 13 : 3,
      );
      final rand = math.Random(8);
      for (var i = 0; i < (design == 'tree' ? 45 : 9); i++) {
        final x = design == 'tree'
                ? 40 + rand.nextDouble() * 120
                : (i.isEven ? 60.0 : 125.0),
            y = design == 'tree' ? 20 + rand.nextDouble() * 95 : 20 + i * 16.0;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: design == 'tree' ? 37 : 55,
            height: design == 'tree' ? 30 : 22,
          ),
          Paint()
            ..color = Color.lerp(
              green,
              const Color(0xFFB4BB74),
              rand.nextDouble() * .65,
            )!,
        );
      }
    } else if (design == 'lily') {
      c.drawLine(
        const Offset(110, 190),
        const Offset(96, 105),
        Paint()
          ..color = green
          ..strokeWidth = 4,
      );
      for (var i = 0; i < 6; i++) {
        c.save();
        c.translate(100, 98);
        c.rotate(i * math.pi / 3);
        fill(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(-35, -38, 0, -86)
            ..quadraticBezierTo(33, -35, 0, 0),
          const Color(0xFFE4BEC4),
        );
        c.drawLine(
          Offset.zero,
          const Offset(0, -65),
          Paint()
            ..color = red.withValues(alpha: .5)
            ..strokeWidth = 1,
        );
        c.restore();
      }
      c.drawCircle(
        const Offset(100, 98),
        11,
        Paint()..color = const Color(0xFFD2A748),
      );
    }
    // Small printed irregularities are baked once, not recomputed in the editor.
    final random = math.Random(31);
    paint.color = cream.withValues(alpha: .08);
    // Do not put noise in transparent margins.
    if (design.contains('strip') && design != 'lace_strip') {
      for (var i = 0; i < 350; i++) {
        c.drawCircle(
          Offset(8 + random.nextDouble() * 184, 8 + random.nextDouble() * 184),
          .4,
          paint,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ScrapbookArtPainter oldDelegate) =>
      design != oldDelegate.design;
}
