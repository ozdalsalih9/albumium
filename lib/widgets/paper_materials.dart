import 'dart:math' as math;
import 'dart:ui' show ClipOp;
import 'package:flutter/material.dart';

/// Original, deterministic vector artwork. No generated images or external assets.
const paperPatterns = <String, String>{
  'plain': 'Düz kâğıt',
  'rose': 'Gül ekose',
  'blue': 'Mavi pötikare',
  'sage': 'Adaçayı ekose',
  'ochre': 'Bal rengi pötikare',
  'plaid': 'Pembe tartan',
  'floral': 'Küçük çiçekler',
  'toile': 'Mavi dallar',
  'denim': 'Lacivert denim',
  'ledger': 'Eski defter',
  'linen': 'Doğal keten',
  'navydots': 'Lacivert puantiye',
  'crumpled': 'Buruşuk zeytin kâğıdı',
  'redplaid': 'Kırmızı tartan',
  'patchwork': 'Renkli kırkyama',
  'burgundy': 'Bordo kumaş',
  'lime': 'Fıstık yeşili kumaş',
};

const paperKitLabels = <String, String>{
  'frame_rose': 'Gül ekose çerçeve',
  'frame_blue': 'Mavi pötikare çerçeve',
  'frame_sage': 'Adaçayı çerçeve',
  'frame_ochre': 'Bal rengi çerçeve',
  'frame_floral': 'Çiçekli çerçeve',
  'frame_toile': 'Mavi dal çerçeve',
  'frame_plaid': 'Pembe tartan çerçeve',
  'frame_lace': 'Dantel çerçeve',
  'paper_rose': 'Gül ekose kâğıt parçası',
  'paper_blue': 'Mavi pötikare kâğıt parçası',
  'paper_sage': 'Adaçayı kâğıt parçası',
  'paper_floral': 'Çiçekli kâğıt parçası',
  'paper_ledger': 'Yırtık defter kâğıdı',
  'paper_denim': 'Denim kumaş parçası',
  'note_lace': 'Dantelli not kâğıdı',
  'corner_rose': 'Gül ekose köşe',
  'corner_floral': 'Çiçekli köşe',
  'corner_toile': 'Mavi dal köşe',
  'corner_ledger': 'Defter köşesi',
  'tape_rose': 'Gül ekose bant',
  'tape_blue': 'Mavi pötikare bant',
  'tape_sage': 'Adaçayı bant',
  'tape_floral': 'Çiçekli bant',
  'tape_ledger': 'Defter bandı',
  'seal_burgundy': 'Bordo botanik mühür',
  'seal_gold': 'Altın botanik mühür',
  'seal_sage': 'Adaçayı botanik mühür',
  'seal_blue': 'Lacivert botanik mühür',
  'seal_blush': 'Pudra botanik mühür',
  'seal_cream': 'Fildişi botanik mühür',
};

bool isPaperKit(String id) => id.startsWith('albumium:paperkit_');
String paperKitKey(String id) => id.substring('albumium:paperkit_'.length);
double paperKitAspect(String key) => key.startsWith('tape_')
    ? 3.8
    : key.startsWith('seal_') || key.startsWith('corner_')
    ? 1
    : .76;

Color _ink(String pattern) => switch (pattern) {
  'blue' || 'toile' => const Color(0xFF395977),
  'sage' => const Color(0xFF728064),
  'ochre' => const Color(0xFFBD8E49),
  'redplaid' => const Color(0xFF97373D),
  'denim' => const Color(0xFF152B4D),
  _ => const Color(0xFFAC5B68),
};

/// Coordinates are fixed in design space, so previews and video exports match.
class PaperMaterialPainter extends CustomPainter {
  const PaperMaterialPainter(this.pattern);
  final String pattern;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 420);
    paintMaterial(canvas, const Rect.fromLTWH(0, 0, 300, 420), pattern);
    canvas.restore();
  }

  static void paintMaterial(Canvas c, Rect r, String pattern) {
    c.save();
    c.clipRect(r);
    final ink = _ink(pattern);
    c.drawRect(
      r,
      Paint()
        ..color = switch (pattern) {
          'denim' => ink,
          'navydots' => const Color(0xFF1E304A),
          'burgundy' => const Color(0xFF65353A),
          'lime' => const Color(0xFFA6B955),
          'crumpled' => const Color(0xFF77805D),
          _ => const Color(0xFFF6F0E1),
        },
    );
    if ([
      'rose',
      'blue',
      'sage',
      'ochre',
      'plaid',
      'redplaid',
    ].contains(pattern)) {
      final step = pattern == 'plaid' || pattern == 'redplaid' ? 29.0 : 15.0;
      final p = Paint()..color = ink.withValues(alpha: .27);
      for (double x = r.left; x < r.right; x += step) {
        c.drawRect(Rect.fromLTWH(x, r.top, step / 2, r.height), p);
      }
      for (double y = r.top; y < r.bottom; y += step) {
        c.drawRect(Rect.fromLTWH(r.left, y, r.width, step / 2), p);
      }
      if (pattern == 'plaid' || pattern == 'redplaid') {
        p
          ..color = ink.withValues(alpha: .45)
          ..strokeWidth = .8;
        for (double x = r.left; x < r.right; x += step) {
          for (final d in [2.0, 5.0, 23.0]) {
            c.drawLine(Offset(x + d, r.top), Offset(x + d, r.bottom), p);
          }
        }
        for (double y = r.top; y < r.bottom; y += step) {
          for (final d in [2.0, 5.0, 23.0]) {
            c.drawLine(Offset(r.left, y + d), Offset(r.right, y + d), p);
          }
        }
      }
    } else if (pattern == 'floral' || pattern == 'toile') {
      var row = 0;
      for (double y = r.top - 10; y < r.bottom + 16; y += 35) {
        for (
          double x = r.left - 10 + (row.isOdd ? 17 : 0);
          x < r.right + 15;
          x += 35
        ) {
          c.save();
          c.translate(x, y);
          c.rotate(row.isOdd ? -.25 : .25);
          _sprig(c, pattern == 'toile' ? ink : const Color(0xFF7C8964), 1);
          if (pattern == 'floral') {
            for (var i = 0; i < 5; i++) {
              final a = i * math.pi * 2 / 5;
              c.drawOval(
                Rect.fromCenter(
                  center: Offset(math.cos(a) * 2.7, -7 + math.sin(a) * 2.7),
                  width: 4,
                  height: 3,
                ),
                Paint()..color = ink.withValues(alpha: .7),
              );
            }
            c.drawCircle(
              const Offset(0, -7),
              1.4,
              Paint()..color = const Color(0xFFBA9348),
            );
          }
          c.restore();
        }
        row++;
      }
    } else if (pattern == 'ledger') {
      final p = Paint()
        ..color = const Color(0xFF63818A).withValues(alpha: .27)
        ..strokeWidth = .7;
      for (double y = r.top + 14; y < r.bottom; y += 14) {
        c.drawLine(Offset(r.left, y), Offset(r.right, y), p);
      }
      c.drawLine(
        Offset(r.left + 29, r.top),
        Offset(r.left + 29, r.bottom),
        Paint()
          ..color = const Color(0xFFB96D71).withValues(alpha: .5)
          ..strokeWidth = 1,
      );
    }
    if (pattern == 'navydots') {
      for (double y = r.top + 12; y < r.bottom; y += 28) {
        for (double x = r.left + 12; x < r.right; x += 28) {
          c.drawCircle(
            Offset(x, y),
            2.4,
            Paint()..color = const Color(0xFFECE1C4),
          );
        }
      }
    }
    if (pattern == 'patchwork') {
      final colors = [
        const Color(0xFF9C3D42),
        const Color(0xFF78945D),
        const Color(0xFF7397B2),
      ];
      for (double y = 0; y < r.height; y += 70) {
        for (double x = 0; x < r.width; x += 70) {
          final color = colors[((x / 70).floor() + (y / 70).floor()) % 3];
          for (var i = 0; i < 7; i++) {
            for (var j = 0; j < 7; j++) {
              if (i.isEven || j.isEven) {
                c.drawRect(
                  Rect.fromLTWH(
                    r.left + x + i * 10,
                    r.top + y + j * 10,
                    10,
                    10,
                  ),
                  Paint()
                    ..color = color.withValues(
                      alpha: i.isEven && j.isEven ? .7 : .35,
                    ),
                );
              }
            }
          }
        }
      }
    }
    if (['linen', 'lime', 'burgundy'].contains(pattern)) {
      final p = Paint()..strokeWidth = .6;
      for (double x = r.left; x < r.right; x += 2) {
        p.color = Colors.white.withValues(
          alpha: x.toInt() % 3 == 0 ? .14 : .05,
        );
        c.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
      }
      for (double y = r.top; y < r.bottom; y += 2.5) {
        p.color = const Color(0xFF514431).withValues(alpha: .11);
        c.drawLine(Offset(r.left, y), Offset(r.right, y), p);
      }
    }
    if (pattern == 'crumpled') {
      final random = math.Random(16);
      for (var i = 0; i < 38; i++) {
        final x = r.left + random.nextDouble() * r.width,
            y = r.top + random.nextDouble() * r.height;
        final fold = Rect.fromLTWH(x - 60, y - 2, 120, 8);
        c.save();
        c.translate(x, y);
        c.rotate(random.nextDouble() * math.pi);
        c.translate(-x, -y);
        c.drawRect(
          fold,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: .10),
                Colors.black.withValues(alpha: .05),
                Colors.transparent,
              ],
            ).createShader(fold),
        );
        c.restore();
      }
    }
    // Woven threads, paper fibers and uneven aging are repeatable at every scale.
    final random = math.Random(1977);
    final fibers = Paint()..strokeWidth = .4;
    for (var i = 0; i < 1500; i++) {
      final x = r.left + random.nextDouble() * r.width;
      final y = r.top + random.nextDouble() * r.height;
      fibers.color = (i.isEven ? Colors.white : const Color(0xFF56452F))
          .withValues(alpha: .035 + random.nextDouble() * .075);
      c.drawLine(
        Offset(x, y),
        Offset(x + random.nextDouble() * 2.8, y + .4),
        fibers,
      );
    }
    if (pattern == 'denim') {
      final p = Paint()
        ..color = const Color(0xFFCAD2CF).withValues(alpha: .19)
        ..strokeWidth = .65;
      for (double x = r.left - r.height; x < r.right; x += 3) {
        c.drawLine(Offset(x, r.top), Offset(x + r.height, r.bottom), p);
      }
    }
    c.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF795730).withValues(alpha: .14),
          ],
          radius: .83,
        ).createShader(r),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(PaperMaterialPainter oldDelegate) =>
      pattern != oldDelegate.pattern;
}

void _sprig(Canvas c, Color color, double scale) {
  c.save();
  c.scale(scale);
  final p = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = .8;
  c.drawPath(
    Path()
      ..moveTo(0, 11)
      ..quadraticBezierTo(4, 0, 0, -10),
    p,
  );
  p.style = PaintingStyle.fill;
  for (var i = 0; i < 3; i++) {
    final y = 6.0 - i * 5;
    c.drawPath(
      Path()
        ..moveTo(1, y)
        ..quadraticBezierTo(-8, y - 6, -6, y - 8)
        ..quadraticBezierTo(1, y - 7, 1, y),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(2, y - 2)
        ..quadraticBezierTo(10, y - 7, 8, y - 9)
        ..quadraticBezierTo(2, y - 8, 2, y - 2),
      p,
    );
  }
  c.restore();
}

class PaperKitPainter extends CustomPainter {
  const PaperKitPainter(this.design);
  final String design;

  @override
  void paint(Canvas c, Size size) {
    final parts = design.split('_');
    final kind = parts.first;
    final pattern = parts.last;
    final h = 200 / paperKitAspect(design);
    c.save();
    c.scale(size.width / 200, size.height / h);
    if (kind == 'seal') {
      _seal(c, pattern);
    } else {
      final r = Rect.fromLTWH(7, 7, 186, h - 14);
      final lace = pattern == 'lace';
      if (lace) _lace(c, r.deflate(13));
      final bounds = lace ? r.deflate(19) : r;
      var path = _torn(bounds, kind == 'tape' ? 18 : 3);
      if (kind == 'corner') {
        path = Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.left, r.bottom)
          ..close();
      }
      if (kind == 'frame') {
        path.fillType = PathFillType.evenOdd;
        path.addRect(bounds.deflate(lace ? 8 : 18));
      }
      c.save();
      if (kind == 'frame') {
        c.clipRect(bounds.deflate(lace ? 8 : 18), clipOp: ClipOp.difference);
      }
      c.drawShadow(
        path,
        const Color(0xFF59472E).withValues(alpha: .35),
        2,
        false,
      );
      c.save();
      c.clipPath(path);
      PaperMaterialPainter.paintMaterial(c, r, lace ? 'plain' : pattern);
      c.restore();
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF786444).withValues(alpha: .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
      c.restore();
      if (kind == 'corner') {
        c.drawLine(
          Offset(r.left + 7, r.bottom - 14),
          Offset(r.right - 14, r.top + 7),
          Paint()
            ..color = const Color(0xFF80674D).withValues(alpha: .35)
            ..strokeWidth = .7,
        );
      }
    }
    c.restore();
  }

  Path _torn(Rect r, double tooth) {
    final random = math.Random(36);
    final p = Path()..moveTo(r.left, r.top);
    for (double x = r.left; x < r.right; x += 3) {
      p.lineTo(x, r.top + random.nextDouble() * 1.8);
    }
    for (double y = r.top; y < r.bottom; y += 3) {
      p.lineTo(r.right - random.nextDouble() * tooth / 3, y);
    }
    for (double x = r.right; x > r.left; x -= 3) {
      p.lineTo(x, r.bottom - random.nextDouble() * 2);
    }
    for (double y = r.bottom; y > r.top; y -= 3) {
      p.lineTo(r.left + random.nextDouble() * tooth / 3, y);
    }
    return p..close();
  }

  void _lace(Canvas c, Rect r) {
    final thread = Paint()
      ..color = const Color(0xFFE8DCC0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05;
    void loop(Offset center, double rotation) {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(rotation);
      c.drawOval(const Rect.fromLTWH(-9, -14, 18, 25), thread);
      c.drawOval(const Rect.fromLTWH(-6, -11, 12, 20), thread);
      for (var i = 0; i < 7; i++) {
        final a = math.pi + math.pi * i / 6;
        c.drawLine(
          const Offset(0, 7),
          Offset(math.cos(a) * 8, math.sin(a) * 12),
          thread,
        );
        c.drawCircle(Offset(math.cos(a) * 9, math.sin(a) * 13), 1.35, thread);
      }
      c.restore();
    }

    for (double x = r.left + 7; x < r.right; x += 15) {
      loop(Offset(x, r.top), 0);
      loop(Offset(x, r.bottom), math.pi);
    }
    for (double y = r.top + 7; y < r.bottom; y += 15) {
      loop(Offset(r.left, y), -math.pi / 2);
      loop(Offset(r.right, y), math.pi / 2);
    }
    c.drawRect(r.deflate(3), thread);
    c.drawRect(r.deflate(6), thread);
  }

  void _seal(Canvas c, String variant) {
    final base = switch (variant) {
      'gold' => const Color(0xFFAD8642),
      'sage' => const Color(0xFF65826A),
      'blue' => const Color(0xFF254C66),
      'blush' => const Color(0xFFC49099),
      'cream' => const Color(0xFFC8BA92),
      _ => const Color(0xFF7F253C),
    };
    final light = Color.lerp(base, const Color(0xFFFFE9BC), .48)!;
    final dark = Color.lerp(base, Colors.black, .48)!;
    final p = Path();
    for (var i = 0; i <= 96; i++) {
      final a = i * math.pi * 2 / 96;
      final radius = 82 + math.sin(a * 5) * 3 + math.cos(a * 9) * 2;
      final v = Offset(100 + math.cos(a) * radius, 100 + math.sin(a) * radius);
      if (i == 0) {
        p.moveTo(v.dx, v.dy);
      } else {
        p.lineTo(v.dx, v.dy);
      }
    }
    p.close();
    c.drawShadow(p, Colors.black.withValues(alpha: .45), 4, false);
    c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, dark, base],
        ).createShader(const Rect.fromLTWH(16, 16, 168, 168)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..color = dark.withValues(alpha: .75);
    c.drawCircle(const Offset(100, 101), 66, ring);
    ring.color = light.withValues(alpha: .75);
    c.drawCircle(const Offset(100, 98), 66, ring);
    ring
      ..strokeWidth = 1
      ..color = light.withValues(alpha: .5);
    c.drawCircle(const Offset(100, 100), 59, ring);
    for (var i = 0; i < 40; i++) {
      final a = i * math.pi * 2 / 40;
      c.drawCircle(
        Offset(100 + 73 * math.cos(a), 100 + 73 * math.sin(a)),
        1.1,
        Paint()..color = light.withValues(alpha: .55),
      );
    }
    c.save();
    c.translate(97, 103);
    c.rotate(-.22);
    _sprig(c, dark, 3.6);
    c.translate(-.8, -1.1);
    _sprig(c, light, 3.6);
    c.restore();
    final random = math.Random(18);
    for (var i = 0; i < 360; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final r = math.sqrt(random.nextDouble()) * 78;
      c.drawCircle(
        Offset(100 + math.cos(a) * r, 100 + math.sin(a) * r),
        .35,
        Paint()..color = light.withValues(alpha: .17),
      );
    }
  }

  @override
  bool shouldRepaint(PaperKitPainter oldDelegate) =>
      design != oldDelegate.design;
}

const paperPhotoFrames = [
  'rose',
  'blue',
  'sage',
  'ochre',
  'floral',
  'toile',
  'plaid',
  'lace',
];

/// Rasterized from the original painters at build time. Decoded thumbnails are
/// shared by Flutter's bounded image cache, never repainted as thousands of paths.
class PaperMaterialImage extends StatelessWidget {
  const PaperMaterialImage(this.pattern, {super.key, this.preview = false});
  final String pattern;
  final bool preview;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/paper_kit/material_$pattern.png',
    fit: BoxFit.fill,
    cacheWidth: preview ? 120 : 600,
    gaplessPlayback: true,
    filterQuality: FilterQuality.low,
  );
}

class PaperKitImage extends StatelessWidget {
  const PaperKitImage(this.design, {super.key, this.preview = false});
  final String design;
  final bool preview;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/paper_kit/$design.png',
    fit: BoxFit.contain,
    cacheWidth: preview ? 160 : 600,
    gaplessPlayback: true,
    filterQuality: FilterQuality.low,
  );
}
