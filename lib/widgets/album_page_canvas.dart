import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/album_models.dart';
import '../themes/theme_image_helper.dart';
import 'font_selector_dialog.dart';
import 'handwriting_painter.dart';
import 'occasion_cards.dart';
import 'physical_book_spread.dart';
import 'sticker_packs.dart';

const albumPhotoFrameLabels = <String>[
  'Temiz kenar',
  'Klasik Polaroid',
  'Koyu deri',
  'Yumuşak köşe',
  'Altın köşebent',
  'Siyah köşebent',
  'Yırtık kâğıt',
  'Analog film',
  'Altın galeri',
  'Pudra keten',
  'Posta pulu',
  'Washi bant',
];

int get albumPhotoFrameCount => albumPhotoFrameLabels.length;

String albumPhotoFrameLabel(int style) =>
    albumPhotoFrameLabels[style % albumPhotoFrameLabels.length];

class AlbumPageCanvas extends StatelessWidget {
  const AlbumPageCanvas({
    super.key,
    required this.page,
    required this.theme,
    this.interactive = false,
    this.selectedId,
    this.onSelect,
    this.onChanged,
  });

  final AlbumPageModel page;
  final AlbumThemePreset theme;
  final bool interactive;
  final String? selectedId;
  final ValueChanged<String?>? onSelect;
  final VoidCallback? onChanged;

  TextStyle _getPageNumberStyle() {
    return switch (theme.id) {
      'animals' => GoogleFonts.quicksand(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: theme.accent.withValues(alpha: 0.6),
      ),
      'soft_romance' => GoogleFonts.jost(
        fontSize: 10,
        letterSpacing: 2.0,
        color: theme.accent.withValues(alpha: 0.6),
      ),
      'vintage_diary' => GoogleFonts.specialElite(
        fontSize: 10,
        color: theme.accent.withValues(alpha: 0.7),
      ),
      'travel_postcard' => GoogleFonts.ibmPlexMono(
        fontSize: 9,
        letterSpacing: 1.5,
        color: theme.accent.withValues(alpha: 0.6),
      ),
      'best_friends' => GoogleFonts.quicksand(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.accent.withValues(alpha: 0.7),
      ),
      'minimal_editorial' => GoogleFonts.inter(
        fontSize: 9,
        letterSpacing: 2.0,
        color: theme.accent.withValues(alpha: 0.5),
      ),
      'dark_leather' => GoogleFonts.marcellus(
        fontSize: 10,
        letterSpacing: 2.0,
        color: theme.accent.withValues(alpha: 0.7),
      ),
      _ => TextStyle(fontSize: 9, color: theme.accent.withValues(alpha: 0.5)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final background = Color(page.backgroundColor);
        final warmedBackground = Color.alphaBlend(
          background.computeLuminance() > 0.5
              ? const Color(0x0ED29A62)
              : const Color(0x0CFFF3D6),
          background,
        );
        return GestureDetector(
          onTap: interactive ? () => onSelect?.call(null) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: warmedBackground,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _PaperTexturePainter(
                  backgroundColor: background,
                  accentColor: theme.accent,
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final element in page.elements)
                      _AlbumElementView(
                        key: ValueKey(element.id),
                        element: element,
                        theme: theme,
                        pageSize: size,
                        interactive: interactive,
                        selected: selectedId == element.id,
                        onSelect: () => onSelect?.call(element.id),
                        onChanged: onChanged,
                      ),
                    Positioned(
                      right: 12,
                      bottom: 8,
                      child: Text(
                        '${page.id.hashCode.abs() % 97 + 1}',
                        style: _getPageNumberStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlbumElementView extends StatefulWidget {
  const _AlbumElementView({
    super.key,
    required this.element,
    required this.theme,
    required this.pageSize,
    required this.interactive,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final AlbumElementModel element;
  final AlbumThemePreset theme;
  final Size pageSize;
  final bool interactive;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onChanged;

  @override
  State<_AlbumElementView> createState() => _AlbumElementViewState();
}

class _AlbumElementViewState extends State<_AlbumElementView> {
  late double _startScale;
  late double _startRotation;
  RenderBox? _gestureCoordinateSpace;
  Offset _gestureAnchor = Offset.zero;

  Offset _rotate(Offset point, double angle) {
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    return Offset(
      point.dx * cosine - point.dy * sine,
      point.dx * sine + point.dy * cosine,
    );
  }

  Offset _elementCenter(AlbumElementModel element) => Offset(
    (element.x + element.width / 2) * widget.pageSize.width,
    (element.y + element.height / 2) * widget.pageSize.height,
  );

  Offset _pageFocalPoint(Offset globalFocalPoint) {
    final coordinateSpace = _gestureCoordinateSpace;
    if (coordinateSpace == null || !coordinateSpace.attached) {
      return globalFocalPoint;
    }
    return coordinateSpace.globalToLocal(globalFocalPoint);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    final element = widget.element;
    widget.onSelect();
    _startScale = element.scale;
    _startRotation = element.rotation;

    // Work in the page Stack's coordinate system. This also compensates for
    // any scale or perspective transform applied to the whole album page.
    _gestureCoordinateSpace = context
        .findAncestorRenderObjectOfType<RenderStack>();
    final focalPoint = _pageFocalPoint(details.focalPoint);
    final offsetFromCenter = focalPoint - _elementCenter(element);

    // Remember the exact point under the fingers in the element's unscaled,
    // unrotated coordinate system. Keeping this point under the current focal
    // point prevents the element from jumping while pinching or rotating.
    _gestureAnchor = _rotate(offsetFromCenter, -_startRotation) / _startScale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final element = widget.element;
    final scale = (_startScale * details.scale).clamp(0.35, 3.5);
    final rotation = _startRotation + details.rotation;
    final focalPoint = _pageFocalPoint(details.focalPoint);
    final transformedAnchor = _rotate(_gestureAnchor * scale, rotation);
    final center = focalPoint - transformedAnchor;

    setState(() {
      element.x = (center.dx / widget.pageSize.width - element.width / 2).clamp(
        -0.35,
        0.92,
      );
      element.y = (center.dy / widget.pageSize.height - element.height / 2)
          .clamp(-0.25, 0.94);
      element.scale = scale;
      element.rotation = rotation;
    });
    widget.onChanged?.call();
  }

  TextStyle _getTextStyle(AlbumElementModel element) {
    final baseColor = Color(element.textColor);
    final size = element.fontSize;

    // 1. If a specific font family is chosen in extraData, apply it
    if (element.extraData.isNotEmpty) {
      return getFontTextStyle(
        element.extraData,
        fontSize: size,
        color: baseColor,
      );
    }

    // 2. Default to theme typography
    return switch (widget.theme.id) {
      'animals' => GoogleFonts.quicksand(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      'soft_romance' => GoogleFonts.caveat(
        fontSize: size * 1.15,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.2,
      ),
      'vintage_diary' => GoogleFonts.caveat(
        fontSize: size * 1.1,
        color: baseColor,
        height: 1.25,
      ),
      'travel_postcard' => GoogleFonts.caveat(
        fontSize: size * 1.1,
        color: baseColor,
        height: 1.25,
      ),
      'best_friends' => GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.2,
      ),
      'minimal_editorial' => GoogleFonts.inter(
        fontSize: size * 0.85,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
        letterSpacing: 0.3,
      ),
      'dark_leather' => GoogleFonts.cormorantGaramond(
        fontSize: size * 1.1,
        fontStyle: FontStyle.italic,
        color: baseColor,
        height: 1.35,
      ),
      _ => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    return Positioned(
      left: element.x * widget.pageSize.width,
      top: element.y * widget.pageSize.height,
      width: element.width * widget.pageSize.width,
      height: element.height * widget.pageSize.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: Transform.scale(
          scale: element.scale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.interactive ? widget.onSelect : null,
            onScaleStart: widget.interactive ? _handleScaleStart : null,
            onScaleUpdate: widget.interactive ? _handleScaleUpdate : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: widget.selected
                  ? BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: _elementContent(element),
            ),
          ),
        ),
      ),
    );
  }

  Widget _elementContent(AlbumElementModel element) {
    switch (element.type) {
      case AlbumElementType.photo:
        return _photo(element);
      case AlbumElementType.text:
        return Center(
          child: Text(
            element.content,
            textAlign: TextAlign.center,
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style: _getTextStyle(element),
          ),
        );
      case AlbumElementType.sticker:
        return AlbumStickerView(content: element.content);
      case AlbumElementType.drawing:
        return HandwritingView(data: element.content);
      case AlbumElementType.card:
        return OccasionCardView(
          cardId: element.content,
          customDataRaw: element.extraData,
        );
    }
  }

  Widget _photo(AlbumElementModel element) {
    final image = ThemeImage(url: element.content, fit: BoxFit.cover);

    switch (element.frameStyle % albumPhotoFrameCount) {
      case 1:
        // Polaroid frame
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: image,
          ),
        );
      case 2:
        // Dark leather / vintage frame with border
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF2C241E),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: image,
          ),
        );
      case 3:
        // Soft rounded pill frame (Animals & Best Friends style)
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.theme.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: image,
          ),
        );
      case 4:
        // Gold corner mounts (Altın fotoğraf köşebentleri)
        return PhotoCornerMounts(
          style: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: image,
          ),
        );
      case 5:
        // Black vintage corner mounts (Siyah vintage köşebentler)
        return PhotoCornerMounts(
          style: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: image,
          ),
        );
      case 6:
        // Handmade deckled paper edge.
        return DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x32000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipPath(
            clipper: const _DeckledEdgeClipper(),
            child: ColoredBox(
              color: const Color(0xFFF0E3CA),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: ClipRect(child: image),
              ),
            ),
          ),
        );
      case 7:
        // 35 mm contact-sheet frame, including real sprocket holes.
        return _FilmNegativeFrame(child: image);
      case 8:
        // Museum-style double bevel in antique gold.
        return Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF75521E),
                Color(0xFFE1C06E),
                Color(0xFF8A6427),
                Color(0xFFF1DA91),
              ],
            ),
            border: Border.all(color: const Color(0xFF493414), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF2A211A),
              border: Border.all(color: const Color(0xFFF2D98D)),
            ),
            child: image,
          ),
        );
      case 9:
        // Dusty-rose linen mat with a fine inner keyline.
        return Container(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFC99EA5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF986C75), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE9D1C9), width: 1.4),
            ),
            child: image,
          ),
        );
      case 10:
        // Perforated postage-stamp edge.
        return CustomPaint(
          painter: const _PostageFramePainter(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: image,
            ),
          ),
        );
      case 11:
        // Scrapbook snapshot held by translucent washi tape.
        return _WashiPhotoFrame(child: image);
      default:
        // Clean rounded frame
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: image,
          ),
        );
    }
  }
}

class _DeckledEdgeClipper extends CustomClipper<Path> {
  const _DeckledEdgeClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(2, 1);
    const steps = 18;
    for (var i = 1; i <= steps; i++) {
      final x = size.width * i / steps;
      path.lineTo(x, i.isEven ? 2.7 : 0.6);
    }
    for (var i = 1; i <= steps; i++) {
      final y = size.height * i / steps;
      path.lineTo(size.width - (i.isEven ? 2.5 : 0.5), y);
    }
    for (var i = steps - 1; i >= 0; i--) {
      final x = size.width * i / steps;
      path.lineTo(x, size.height - (i.isEven ? 2.5 : 0.5));
    }
    for (var i = steps - 1; i >= 0; i--) {
      final y = size.height * i / steps;
      path.lineTo(i.isEven ? 2.5 : 0.5, y);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FilmNegativeFrame extends StatelessWidget {
  const _FilmNegativeFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B19),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            top: 11,
            bottom: 11,
            left: 5,
            right: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: child,
            ),
          ),
          const Positioned(left: 3, right: 3, top: 3, child: _SprocketRow()),
          const Positioned(left: 3, right: 3, bottom: 3, child: _SprocketRow()),
        ],
      ),
    );
  }
}

class _SprocketRow extends StatelessWidget {
  const _SprocketRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 10; i++)
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE6DDCA),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}

class _PostageFramePainter extends CustomPainter {
  const _PostageFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    final paper = Paint()..color = const Color(0xFFF0E3CB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      paper,
    );
    final punch = Paint()..blendMode = BlendMode.clear;
    const spacing = 11.0;
    for (var x = 5.0; x < size.width; x += spacing) {
      canvas.drawCircle(Offset(x, 0), 2.5, punch);
      canvas.drawCircle(Offset(x, size.height), 2.5, punch);
    }
    for (var y = 5.0; y < size.height; y += spacing) {
      canvas.drawCircle(Offset(0, y), 2.5, punch);
      canvas.drawCircle(Offset(size.width, y), 2.5, punch);
    }
    canvas.restore();

    canvas.drawRect(
      Rect.fromLTRB(7, 7, size.width - 7, size.height - 7),
      Paint()
        ..color = const Color(0xFF9F7555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WashiPhotoFrame extends StatelessWidget {
  const _WashiPhotoFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 5,
          bottom: 4,
          left: 3,
          right: 3,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF4EBDD),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(padding: const EdgeInsets.all(5), child: child),
          ),
        ),
        const Positioned(
          left: 11,
          top: 0,
          child: _PhotoTape(color: Color(0xAAD8AAB3), angle: -0.17),
        ),
        const Positioned(
          right: 10,
          bottom: 0,
          child: _PhotoTape(color: Color(0xAAC2C7A8), angle: -0.12),
        ),
      ],
    );
  }
}

class _PhotoTape extends StatelessWidget {
  const _PhotoTape({required this.color, required this.angle});

  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 40,
        height: 11,
        decoration: BoxDecoration(
          color: color,
          border: const Border.symmetric(
            horizontal: BorderSide(color: Color(0x28FFFFFF)),
          ),
        ),
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({
    required this.backgroundColor,
    required this.accentColor,
  });

  final Color backgroundColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaper = backgroundColor.computeLuminance() < 0.32;
    final warmGlaze = darkPaper
        ? const Color(0x0CFFF1D0)
        : const Color(0x12C58A50);
    canvas.drawRect(Offset.zero & size, Paint()..color = warmGlaze);

    // A broad edge patina makes even a user-selected light page feel like
    // tactile archival paper rather than a flat white digital rectangle.
    final vignetteColor = darkPaper
        ? const Color(0x34000000)
        : const Color(0x28735335);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 0.88,
          colors: [Colors.transparent, vignetteColor],
          stops: const [0.52, 1],
        ).createShader(Offset.zero & size),
    );

    final random = math.Random(4217);
    final fleckColor = darkPaper
        ? Colors.white.withValues(alpha: 0.055)
        : Color.lerp(
            accentColor,
            const Color(0xFF795D45),
            0.58,
          )!.withValues(alpha: 0.09);
    final fleckPaint = Paint()..color = fleckColor;
    for (var i = 0; i < 230; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      if (i % 5 == 0) {
        canvas.drawLine(
          point,
          point + Offset(random.nextDouble() * 3 + 1, random.nextDouble() - .5),
          fleckPaint..strokeWidth = 0.35,
        );
      } else {
        canvas.drawCircle(point, random.nextDouble() * 0.65 + 0.12, fleckPaint);
      }
    }

    final fiberPaint = Paint()
      ..color = darkPaper ? const Color(0x12F4E9D1) : const Color(0x16826B52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45;
    for (var i = 0; i < 12; i++) {
      final y = size.height * (i + 1) / 13 + (random.nextDouble() - .5) * 8;
      final path = Path()
        ..moveTo(-4, y)
        ..cubicTo(
          size.width * .3,
          y + random.nextDouble() * 4 - 2,
          size.width * .72,
          y + random.nextDouble() * 4 - 2,
          size.width + 4,
          y + random.nextDouble() * 3 - 1.5,
        );
      canvas.drawPath(path, fiberPaint);
    }

    if (!darkPaper) {
      final stainPaint = Paint()
        ..color = const Color(0x167A4D2D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, size.shortestSide * .004);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * .12, size.height * .18),
          width: size.width * .24,
          height: size.width * .21,
        ),
        -1.4,
        3.7,
        false,
        stainPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * .91, size.height * .81),
          width: size.width * .19,
          height: size.width * .17,
        ),
        1.4,
        3.2,
        false,
        stainPaint..color = const Color(0x0E7A4D2D),
      );
    }

    final edgePaint = Paint()
      ..color = darkPaper ? const Color(0x25000000) : const Color(0x24745438)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.shortestSide * .012);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(6),
      ),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.accentColor != accentColor;
}
