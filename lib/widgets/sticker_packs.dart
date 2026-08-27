import 'dart:math' as math;

import 'package:flutter/material.dart';

const _illustratedPrefix = 'albumium:';

bool isIllustratedSticker(String value) => value.startsWith(_illustratedPrefix);

String albumStickerLabel(String value) => switch (value) {
  'albumium:washi_blush' => 'Pudra washi bant',
  'albumium:washi_sage' => 'Adaçayı washi bant',
  'albumium:washi_script' => 'El yazılı washi bant',
  'albumium:film_strip' => 'Analog film şeridi',
  'albumium:ribbon_blush' => 'Pudra kurdele',
  'albumium:ribbon_navy' => 'Lacivert kurdele',
  'albumium:pressed_lavender' => 'Preslenmiş lavanta',
  'albumium:pressed_daisy' => 'Preslenmiş papatya',
  'albumium:pressed_rose' => 'Preslenmiş gül',
  'albumium:fern' => 'Botanik eğrelti',
  'albumium:gold_branch' => 'Altın dal',
  'albumium:postage_rose' => 'Gül posta pulu',
  'albumium:postage_airmail' => 'Hava postası pulu',
  'albumium:wax_burgundy' => 'Bordo mum mühür',
  'albumium:wax_gold' => 'Altın mum mühür',
  'albumium:vintage_ticket' => 'Vintage bilet',
  'albumium:star_doodle' => 'Yıldız çizimi',
  _ => value,
};

class StickerCategory {
  const StickerCategory({
    required this.name,
    required this.icon,
    required this.stickers,
  });

  final String name;
  final IconData icon;
  final List<String> stickers;

  bool get illustrated =>
      stickers.isNotEmpty && isIllustratedSticker(stickers.first);
}

const stickerPacks = <StickerCategory>[
  StickerCategory(
    name: 'Kolaj Kiti',
    icon: Icons.auto_awesome_mosaic_outlined,
    stickers: [
      'albumium:washi_blush',
      'albumium:washi_sage',
      'albumium:washi_script',
      'albumium:film_strip',
      'albumium:ribbon_blush',
      'albumium:ribbon_navy',
    ],
  ),
  StickerCategory(
    name: 'Botanik Arşiv',
    icon: Icons.local_florist_outlined,
    stickers: [
      'albumium:pressed_lavender',
      'albumium:pressed_daisy',
      'albumium:pressed_rose',
      'albumium:fern',
      'albumium:gold_branch',
      'albumium:star_doodle',
    ],
  ),
  StickerCategory(
    name: 'Posta & Mühür',
    icon: Icons.local_post_office_outlined,
    stickers: [
      'albumium:postage_rose',
      'albumium:postage_airmail',
      'albumium:wax_burgundy',
      'albumium:wax_gold',
      'albumium:vintage_ticket',
      'albumium:star_doodle',
    ],
  ),
  StickerCategory(
    name: 'Aşk',
    icon: Icons.favorite_border_rounded,
    stickers: [
      '❤️',
      '💕',
      '💖',
      '💍',
      '💌',
      '🌹',
      '🕊️',
      '🥂',
      '💐',
      '💝',
      '💘',
      '🧸',
    ],
  ),
  StickerCategory(
    name: 'Kutlama',
    icon: Icons.celebration_outlined,
    stickers: [
      '🎂',
      '🎉',
      '🎈',
      '🥳',
      '🍾',
      '🎁',
      '🪩',
      '👑',
      '🎊',
      '🍰',
      '🧁',
      '🏆',
    ],
  ),
  StickerCategory(
    name: 'Seyahat',
    icon: Icons.flight_takeoff_rounded,
    stickers: [
      '✈️',
      '🗺️',
      '🧭',
      '🏖️',
      '🏔️',
      '📸',
      '🧳',
      '🚂',
      '🌴',
      '⛺',
      '🌅',
      '🎒',
    ],
  ),
  StickerCategory(
    name: 'Doğa',
    icon: Icons.eco_outlined,
    stickers: [
      '🌿',
      '🌸',
      '🌻',
      '🌺',
      '🍀',
      '🌵',
      '🍄',
      '🍃',
      '🌷',
      '🌼',
      '🌾',
      '🍁',
    ],
  ),
];

/// Renders both legacy emoji stickers and Albumium's code-native illustrated
/// collage motifs. The same asset-free drawing is used in the editor, book
/// preview and exported frames.
class AlbumStickerView extends StatelessWidget {
  const AlbumStickerView({
    super.key,
    required this.content,
    this.preview = false,
  });

  final String content;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (!isIllustratedSticker(content)) {
      return FittedBox(
        fit: BoxFit.contain,
        child: Text(content, textAlign: TextAlign.center),
      );
    }

    return Semantics(
      image: true,
      label: albumStickerLabel(content),
      child: CustomPaint(
        painter: _IllustratedStickerPainter(content),
        child: preview ? const SizedBox.expand() : null,
      ),
    );
  }
}

class StickerPackPickerSheet extends StatefulWidget {
  const StickerPackPickerSheet({super.key});

  @override
  State<StickerPackPickerSheet> createState() => _StickerPackPickerSheetState();
}

class _StickerPackPickerSheetState extends State<StickerPackPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: stickerPacks.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: colors.onPrimaryContainer,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Albüm Süsleri',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Vektör kolajlar, botanik parçalar ve klasik çıkartmalar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                for (final pack in stickerPacks)
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(pack.icon, size: 17),
                        const SizedBox(width: 6),
                        Text(pack.name, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 286,
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final pack in stickerPacks)
                    GridView.builder(
                      padding: const EdgeInsets.only(top: 2, bottom: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: pack.illustrated
                            ? (tablet ? 5 : 3)
                            : (tablet ? 8 : 5),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: pack.illustrated ? 0.86 : 1,
                      ),
                      itemCount: pack.stickers.length,
                      itemBuilder: (context, index) {
                        final sticker = pack.stickers[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, sticker),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: pack.illustrated
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      8,
                                      8,
                                      6,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: AlbumStickerView(
                                            content: sticker,
                                            preview: true,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          albumStickerLabel(sticker),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            height: 1.05,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      sticker,
                                      style: const TextStyle(fontSize: 29),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustratedStickerPainter extends CustomPainter {
  const _IllustratedStickerPainter(this.id);

  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    if (id.contains('washi_')) {
      _paintWashi(canvas);
    } else if (id == 'albumium:film_strip') {
      _paintFilmStrip(canvas);
    } else if (id.contains('ribbon_')) {
      _paintRibbon(canvas);
    } else if (id.contains('pressed_') || id.endsWith(':fern')) {
      _paintBotanical(canvas);
    } else if (id.endsWith(':gold_branch')) {
      _paintGoldBranch(canvas);
    } else if (id.contains('postage_')) {
      _paintPostage(canvas);
    } else if (id.contains('wax_')) {
      _paintWaxSeal(canvas);
    } else if (id.endsWith(':vintage_ticket')) {
      _paintTicket(canvas);
    } else {
      _paintStarDoodle(canvas);
    }

    canvas.restore();
  }

  void _paintWashi(Canvas canvas) {
    final base = switch (id) {
      'albumium:washi_sage' => const Color(0xFFC1C8A9),
      'albumium:washi_script' => const Color(0xFFD7C9AF),
      _ => const Color(0xFFDDAEB8),
    };
    final path = Path()
      ..moveTo(1, 14)
      ..lineTo(5, 8)
      ..lineTo(2, 3)
      ..lineTo(97, 6)
      ..lineTo(94, 12)
      ..lineTo(99, 18)
      ..lineTo(96, 88)
      ..lineTo(91, 94)
      ..lineTo(96, 98)
      ..lineTo(4, 95)
      ..lineTo(7, 88)
      ..lineTo(2, 82)
      ..close();
    canvas.drawShadow(path, const Color(0x55000000), 3, false);
    canvas.drawPath(path, Paint()..color = base.withValues(alpha: 0.88));

    final ink = Paint()
      ..color = const Color(0xFF5C4A45).withValues(alpha: 0.34)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    if (id == 'albumium:washi_script') {
      final script = Path()
        ..moveTo(8, 58)
        ..cubicTo(18, 25, 30, 78, 43, 45)
        ..cubicTo(54, 20, 64, 75, 74, 44)
        ..cubicTo(81, 26, 88, 42, 94, 30);
      canvas.drawPath(script, ink..strokeWidth = 2.2);
      for (var x = 12.0; x < 92; x += 18) {
        canvas.drawLine(Offset(x, 70), Offset(x + 12, 70), ink);
      }
    } else if (id == 'albumium:washi_sage') {
      for (var x = 10.0; x < 96; x += 21) {
        canvas.drawLine(Offset(x, 18), Offset(x + 8, 82), ink);
        canvas.drawCircle(Offset(x + 8, 41), 4, ink);
      }
    } else {
      for (var x = 11.0; x < 96; x += 18) {
        canvas.drawCircle(Offset(x, 34), 2.5, ink);
        canvas.drawCircle(Offset(x + 8, 64), 1.8, ink);
      }
    }
  }

  void _paintFilmStrip(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 5, 98, 90),
      const Radius.circular(5),
    );
    canvas.drawShadow(
      Path()..addRRect(body),
      const Color(0x66000000),
      4,
      false,
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF24201E));
    final holePaint = Paint()..color = const Color(0xFFE8DCC8);
    for (var x = 7.0; x < 97; x += 11) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 10, 6, 9),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 81, 6, 9),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
    }
    final framePaint = Paint()
      ..color = const Color(0xFF7F6957)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var x = 6.0; x < 94; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, 25, 25, 50), framePaint);
      canvas.drawLine(Offset(x + 3, 68), Offset(x + 21, 31), framePaint);
    }
  }

  void _paintRibbon(Canvas canvas) {
    final base = id.endsWith('navy')
        ? const Color(0xFF2F4058)
        : const Color(0xFFB87483);
    final dark = Color.lerp(base, Colors.black, 0.28)!;
    final tails = Path()
      ..moveTo(2, 30)
      ..lineTo(21, 30)
      ..lineTo(21, 75)
      ..lineTo(2, 88)
      ..lineTo(9, 58)
      ..close()
      ..moveTo(98, 30)
      ..lineTo(79, 30)
      ..lineTo(79, 75)
      ..lineTo(98, 88)
      ..lineTo(91, 58)
      ..close();
    canvas.drawPath(tails, Paint()..color = dark);
    final center = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 20, 72, 58),
      const Radius.circular(5),
    );
    canvas.drawShadow(
      Path()..addRRect(center),
      const Color(0x55000000),
      3,
      false,
    );
    canvas.drawRRect(center, Paint()..color = base);
    canvas.drawLine(
      const Offset(20, 30),
      const Offset(80, 30),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 2,
    );
  }

  void _paintBotanical(Canvas canvas) {
    final stemColor = id.endsWith('lavender')
        ? const Color(0xFF6D7051)
        : const Color(0xFF657052);
    final stem = Paint()
      ..color = stemColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mainStem = Path()
      ..moveTo(50, 96)
      ..cubicTo(45, 67, 57, 38, 49, 6);
    canvas.drawPath(mainStem, stem);

    if (id.endsWith(':fern')) {
      for (var i = 0; i < 9; i++) {
        final y = 18.0 + i * 7.8;
        final spread = 28.0 - i * 1.5;
        canvas.drawLine(Offset(49, y), Offset(49 - spread, y - 10), stem);
        canvas.drawLine(Offset(50, y + 2), Offset(50 + spread, y - 7), stem);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(49 - spread, y - 10),
            width: 8,
            height: 4,
          ),
          Paint()..color = const Color(0xFF879276).withValues(alpha: 0.72),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(50 + spread, y - 7),
            width: 8,
            height: 4,
          ),
          Paint()..color = const Color(0xFF879276).withValues(alpha: 0.72),
        );
      }
      return;
    }

    final petalColor = switch (id) {
      'albumium:pressed_lavender' => const Color(0xFF8A769A),
      'albumium:pressed_rose' => const Color(0xFFA8646D),
      _ => const Color(0xFFE0C987),
    };
    for (var i = 0; i < 6; i++) {
      final y = 16.0 + i * 11;
      final side = i.isEven ? -1.0 : 1.0;
      canvas.drawLine(
        Offset(50, y + 8),
        Offset(50 + side * 22, y),
        stem..strokeWidth = 1.4,
      );
      _drawFlower(canvas, Offset(50 + side * 24, y), petalColor, i * 0.7);
    }
    _drawFlower(canvas, const Offset(49, 10), petalColor, 0.2);
  }

  void _drawFlower(Canvas canvas, Offset center, Color color, double phase) {
    final petal = Paint()..color = color.withValues(alpha: 0.76);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + phase;
      final offset = Offset(math.cos(angle) * 6, math.sin(angle) * 6);
      canvas.drawOval(
        Rect.fromCenter(center: center + offset, width: 9, height: 4),
        petal,
      );
    }
    canvas.drawCircle(center, 2.4, Paint()..color = const Color(0xFF745E42));
  }

  void _paintGoldBranch(Canvas canvas) {
    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E6A2D), Color(0xFFE5C980), Color(0xFF9D7535)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final branch = Path()
      ..moveTo(10, 91)
      ..cubicTo(36, 75, 48, 49, 88, 10);
    canvas.drawPath(branch, gold);
    for (var i = 0; i < 8; i++) {
      final t = i / 8;
      final x = 22 + t * 58;
      final y = 81 - t * 61;
      final side = i.isEven ? -1.0 : 1.0;
      canvas.drawLine(Offset(x, y), Offset(x + side * 17, y - 8), gold);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + side * 19, y - 9),
          width: 13,
          height: 6,
        ),
        Paint()
          ..shader = gold.shader
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintPostage(Canvas canvas) {
    final paper = id.endsWith('airmail')
        ? const Color(0xFFD8E0DC)
        : const Color(0xFFE9D1C2);
    final ink = id.endsWith('airmail')
        ? const Color(0xFF345B65)
        : const Color(0xFF8B4A56);
    final stamp = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 5, 86, 90),
      const Radius.circular(3),
    );
    canvas.drawShadow(
      Path()..addRRect(stamp),
      const Color(0x55000000),
      3,
      false,
    );
    canvas.drawRRect(stamp, Paint()..color = paper);
    final edge = Paint()
      ..color = const Color(0xFF9E8875).withValues(alpha: 0.7);
    for (var i = 0; i < 10; i++) {
      final p = 9.0 + i * 9;
      canvas.drawCircle(Offset(p, 5), 1.7, edge);
      canvas.drawCircle(Offset(p, 95), 1.7, edge);
      canvas.drawCircle(Offset(7, p), 1.7, edge);
      canvas.drawCircle(Offset(93, p), 1.7, edge);
    }
    final border = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(16, 14, 68, 70), border);
    if (id.endsWith('airmail')) {
      canvas.drawCircle(const Offset(50, 47), 18, border);
      canvas.drawLine(const Offset(32, 47), const Offset(68, 47), border);
      canvas.drawLine(const Offset(50, 29), const Offset(50, 65), border);
      canvas.drawLine(const Offset(23, 74), const Offset(77, 20), border);
    } else {
      final stem = Paint()
        ..color = ink
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(50, 72), const Offset(50, 47), stem);
      _drawFlower(canvas, const Offset(50, 38), ink, 0);
      canvas.drawOval(const Rect.fromLTWH(35, 51, 16, 8), stem);
      canvas.drawOval(const Rect.fromLTWH(49, 58, 16, 8), stem);
    }
  }

  void _paintWaxSeal(Canvas canvas) {
    final base = id.endsWith('gold')
        ? const Color(0xFFB99245)
        : const Color(0xFF8C3742);
    final path = Path();
    for (var i = 0; i < 32; i++) {
      final angle = i * math.pi * 2 / 32;
      final radius = i.isEven ? 42.0 : 38.0;
      final point = Offset(
        50 + math.cos(angle) * radius,
        51 + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, const Color(0x77000000), 5, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            Color.lerp(base, Colors.white, 0.24)!,
            base,
            Color.lerp(base, Colors.black, 0.3)!,
          ],
        ).createShader(const Rect.fromLTWH(8, 9, 84, 84)),
    );
    final emboss = Paint()
      ..color = Color.lerp(base, Colors.black, 0.32)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(const Offset(50, 51), 27, emboss);
    final monogram = Path()
      ..moveTo(36, 65)
      ..lineTo(50, 31)
      ..lineTo(64, 65)
      ..moveTo(41, 54)
      ..lineTo(59, 54);
    canvas.drawPath(monogram, emboss..strokeWidth = 4);
  }

  void _paintTicket(Canvas canvas) {
    final ticket = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 16, 94, 68),
      const Radius.circular(7),
    );
    canvas.drawShadow(
      Path()..addRRect(ticket),
      const Color(0x44000000),
      3,
      false,
    );
    canvas.drawRRect(ticket, Paint()..color = const Color(0xFFD8C2A0));
    final ink = Paint()
      ..color = const Color(0xFF735849)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 22, 82, 56),
        const Radius.circular(4),
      ),
      ink,
    );
    for (var y = 27.0; y < 76; y += 8) {
      canvas.drawLine(Offset(68, y), Offset(68, y + 4), ink);
    }
    for (var x = 18.0; x < 61; x += 9) {
      canvas.drawLine(Offset(x, 42), Offset(x + 5, 42), ink);
      canvas.drawLine(Offset(x, 58), Offset(x + 5, 58), ink);
    }
    canvas.drawCircle(const Offset(80, 50), 8, ink);
  }

  void _paintStarDoodle(Canvas canvas) {
    final ink = Paint()
      ..color = const Color(0xFFB88B45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stars = <Offset>[
      const Offset(22, 27),
      const Offset(52, 48),
      const Offset(81, 22),
      const Offset(77, 78),
      const Offset(25, 76),
    ];
    for (var i = 0; i < stars.length; i++) {
      final c = stars[i];
      final r = i == 1 ? 15.0 : 8.0;
      canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), ink);
      canvas.drawLine(c - Offset(0, r), c + Offset(0, r), ink);
      canvas.drawLine(
        c - Offset(r * .45, r * .45),
        c + Offset(r * .45, r * .45),
        ink,
      );
      canvas.drawLine(
        c + Offset(-r * .45, r * .45),
        c + Offset(r * .45, -r * .45),
        ink,
      );
    }
    canvas.drawCircle(const Offset(52, 48), 24, ink..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _IllustratedStickerPainter oldDelegate) =>
      oldDelegate.id != id;
}
