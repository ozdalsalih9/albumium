import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/album_models.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTap: interactive ? () => onSelect?.call(null) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(page.backgroundColor),
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
                  theme.accent.withValues(alpha: 0.055),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final element in page.elements)
                      _AlbumElementView(
                        key: ValueKey(element.id),
                        element: element,
                        pageSize: size,
                        interactive: interactive,
                        selected: selectedId == element.id,
                        onSelect: () => onSelect?.call(element.id),
                        onChanged: onChanged,
                      ),
                    Positioned(
                      right: 10,
                      bottom: 7,
                      child: Text(
                        '${page.id.hashCode.abs() % 97 + 1}',
                        style: TextStyle(
                          color: theme.accent.withValues(alpha: 0.28),
                          fontSize: 8,
                        ),
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
    required this.pageSize,
    required this.interactive,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final AlbumElementModel element;
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
            onScaleStart: widget.interactive
                ? (_) {
                    widget.onSelect();
                    _startScale = element.scale;
                    _startRotation = element.rotation;
                  }
                : null,
            onScaleUpdate: widget.interactive
                ? (details) {
                    setState(() {
                      element.x =
                          (element.x +
                                  details.focalPointDelta.dx /
                                      widget.pageSize.width)
                              .clamp(-0.35, 0.92);
                      element.y =
                          (element.y +
                                  details.focalPointDelta.dy /
                                      widget.pageSize.height)
                              .clamp(-0.25, 0.94);
                      element.scale = (_startScale * details.scale).clamp(
                        0.45,
                        3.2,
                      );
                      element.rotation = _startRotation + details.rotation;
                    });
                    widget.onChanged?.call();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: widget.selected
                  ? BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFA95C),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(5),
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
            style: TextStyle(
              color: Color(element.textColor),
              fontSize: element.fontSize,
              height: 1.08,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        );
      case AlbumElementType.sticker:
        return FittedBox(fit: BoxFit.contain, child: Text(element.content));
    }
  }

  Widget _photo(AlbumElementModel element) {
    final image = Image.file(
      File(element.content),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE2DCD4),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF8B8177)),
        ),
      ),
    );
    switch (element.frameStyle % 4) {
      case 1:
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 25),
          color: Colors.white,
          child: ClipRect(child: image),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF342D28),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: image,
          ),
        );
      case 3:
        return ClipRRect(borderRadius: BorderRadius.circular(24), child: image);
      default:
        return ClipRRect(borderRadius: BorderRadius.circular(4), child: image);
    }
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = color;
    for (var i = 0; i < 180; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 0.9 + 0.15,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) =>
      oldDelegate.color != color;
}
