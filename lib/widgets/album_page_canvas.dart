import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../themes/theme_image_helper.dart';
import 'font_selector_dialog.dart';
import 'handwriting_painter.dart';
import 'occasion_cards.dart';
import 'photo_crop_editor.dart';
import 'physical_book_spread.dart';
import 'sticker_packs.dart';
import 'theme_page_decoration.dart';

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
  'Krem paspartu',
  'Retro slayt',
  'Dikişli keten',
  'Fotoğraf kabini',
];

int get albumPhotoFrameCount => albumPhotoFrameLabels.length;

/// Space consumed by each frame around the image, including Container border
/// padding (DecoratedBox borders, unlike Container borders, do not add space).
/// Keep these in sync with _photoFrame; regression tests measure all frames.
EdgeInsets albumPhotoFrameInsets(int style) =>
    switch (style % albumPhotoFrameCount) {
      1 => const EdgeInsets.fromLTRB(8, 8, 8, 24),
      2 => const EdgeInsets.all(5),
      3 => const EdgeInsets.all(8),
      6 => const EdgeInsets.all(9),
      7 => const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      8 => const EdgeInsets.all(12.5),
      9 => const EdgeInsets.fromLTRB(15.9, 15.9, 15.9, 18.9),
      10 => const EdgeInsets.all(12),
      11 => const EdgeInsets.fromLTRB(8, 10, 8, 9),
      12 => const EdgeInsets.all(14.2),
      13 => const EdgeInsets.fromLTRB(10, 12, 10, 20),
      14 => const EdgeInsets.all(10),
      15 => const EdgeInsets.fromLTRB(7, 7, 7, 18),
      _ => EdgeInsets.zero,
    };

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
    this.showPageNumber = true,
  });

  final AlbumPageModel page;
  final AlbumThemePreset theme;
  final bool interactive;
  final String? selectedId;
  final ValueChanged<String?>? onSelect;
  final VoidCallback? onChanged;
  final bool showPageNumber;

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
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    // Keep the hundreds of static paper/ornament paint
                    // operations out of the layer repainted by each drag.
                    child: RepaintBoundary(
                      key: ValueKey('album-page-art-${page.id}'),
                      child: CustomPaint(
                        painter: _PaperTexturePainter(
                          backgroundColor: background,
                          accentColor: theme.accent,
                        ),
                        child: ThemePageDecoration(
                          theme: theme,
                          paperColor: background,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: _AlbumElementsLayer(
                      page: page,
                      theme: theme,
                      pageSize: size,
                      interactive: interactive,
                      selectedId: selectedId,
                      onSelect: onSelect,
                      onChanged: onChanged,
                    ),
                  ),
                  if (showPageNumber)
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
        );
      },
    );
  }
}

class _AlbumElementsLayer extends StatefulWidget {
  const _AlbumElementsLayer({
    required this.page,
    required this.theme,
    required this.pageSize,
    required this.interactive,
    required this.selectedId,
    required this.onSelect,
    required this.onChanged,
  });

  final AlbumPageModel page;
  final AlbumThemePreset theme;
  final Size pageSize;
  final bool interactive;
  final String? selectedId;
  final ValueChanged<String?>? onSelect;
  final VoidCallback? onChanged;

  @override
  State<_AlbumElementsLayer> createState() => _AlbumElementsLayerState();
}

class _AlbumElementsLayerState extends State<_AlbumElementsLayer> {
  void _geometryChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AlbumElementModel? selected;
    for (final element in widget.page.elements) {
      if (element.id == widget.selectedId) selected = element;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final element in widget.page.elements)
          _AlbumElementView(
            key: ValueKey(element.id),
            element: element,
            theme: widget.theme,
            pageSize: widget.pageSize,
            interactive: widget.interactive,
            onSelect: () => widget.onSelect?.call(element.id),
            onGeometryChanged: _geometryChanged,
            onChanged: widget.onChanged,
          ),
        if (widget.interactive && selected != null)
          Positioned.fill(
            child: _AlbumSelectionOverlay(
              key: ValueKey('selection-overlay-${selected.id}'),
              element: selected,
              pageSize: widget.pageSize,
              onGeometryChanged: _geometryChanged,
              onChanged: widget.onChanged,
            ),
          ),
      ],
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
    required this.onSelect,
    required this.onGeometryChanged,
    required this.onChanged,
  });

  final AlbumElementModel element;
  final AlbumThemePreset theme;
  final Size pageSize;
  final bool interactive;
  final VoidCallback onSelect;
  final VoidCallback onGeometryChanged;
  final VoidCallback? onChanged;

  @override
  State<_AlbumElementView> createState() => _AlbumElementViewState();
}

class _AlbumElementViewState extends State<_AlbumElementView> {
  late double _startScale;
  late double _startRotation;
  RenderBox? _gestureCoordinateSpace;
  Offset _gestureAnchor = Offset.zero;
  bool _transformChanged = false;

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
    _startScale = element.scale.isFinite
        ? element.scale.clamp(albumElementMinScale, albumElementMaxScale)
        : 1;
    _startRotation = element.rotation;
    _transformChanged = false;

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
    final scale = (_startScale * details.scale).clamp(
      albumElementMinScale,
      albumElementMaxScale,
    );
    final rotation = _startRotation + details.rotation;
    final focalPoint = _pageFocalPoint(details.focalPoint);
    final transformedAnchor = _rotate(_gestureAnchor * scale, rotation);
    final center = focalPoint - transformedAnchor;
    final x = (center.dx / widget.pageSize.width - element.width / 2).clamp(
      -0.35,
      0.92,
    );
    final y = (center.dy / widget.pageSize.height - element.height / 2).clamp(
      -0.25,
      0.94,
    );
    _transformChanged =
        _transformChanged ||
        (element.x - x).abs() > .000001 ||
        (element.y - y).abs() > .000001 ||
        (element.scale - scale).abs() > .000001 ||
        (element.rotation - rotation).abs() > .000001;
    element.x = x;
    element.y = y;
    element.scale = scale;
    element.rotation = rotation;
    widget.onGeometryChanged();
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _gestureCoordinateSpace = null;
    if (!_transformChanged) return;
    _transformChanged = false;
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
            onScaleEnd: widget.interactive ? _handleScaleEnd : null,
            // Transforms can reuse a recorded display list while the element
            // moves. Read-only/export pages do not need a layer per element.
            child: widget.interactive
                ? RepaintBoundary(
                    key: ValueKey('album-element-art-${element.id}'),
                    child: _elementContent(element),
                  )
                : _elementContent(element),
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: _FittedAlbumText(
            text: element.content,
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
    if (element.photoCrop != null &&
        element.photoShape == AlbumPhotoShape.free) {
      return CroppedAlbumPhoto(
        path: element.content,
        crop: element.photoCrop!,
        frameInsets: albumPhotoFrameInsets(element.frameStyle),
        frameBuilder: (photo) => _photoFrame(element, photo),
      );
    }
    final image = _PhotoShapeClip(
      shape: element.photoShape,
      child: element.photoCrop != null
          ? CroppedAlbumPhoto(
              path: element.content,
              crop: element.photoCrop!,
              fit: element.photoShape == AlbumPhotoShape.free
                  ? BoxFit.contain
                  : BoxFit.cover,
            )
          : ThemeImage(
              url: element.content,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
    );

    return _photoFrame(element, image);
  }

  Widget _photoFrame(AlbumElementModel element, Widget image) {
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
      case 12:
        // Wide museum mat with a restrained archival keyline.
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF2E9D8),
            border: Border.all(color: const Color(0xFFB6A58B), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 11,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF75624C), width: 1),
            ),
            child: image,
          ),
        );
      case 13:
        return _SlideMountFrame(child: image);
      case 14:
        return _StitchedLinenPhotoFrame(child: image);
      case 15:
        return _PhotoBoothFrame(child: image);
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

enum _ResizeCorner { topLeft, topRight, bottomRight, bottomLeft }

Offset _cornerSigns(_ResizeCorner corner) => switch (corner) {
  _ResizeCorner.topLeft => const Offset(-1, -1),
  _ResizeCorner.topRight => const Offset(1, -1),
  _ResizeCorner.bottomRight => const Offset(1, 1),
  _ResizeCorner.bottomLeft => const Offset(-1, 1),
};

String _cornerSemanticsLabel(_ResizeCorner corner) => switch (corner) {
  _ResizeCorner.topLeft => 'Sol üst köşeden yeniden boyutlandır',
  _ResizeCorner.topRight => 'Sağ üst köşeden yeniden boyutlandır',
  _ResizeCorner.bottomRight => 'Sağ alt köşeden yeniden boyutlandır',
  _ResizeCorner.bottomLeft => 'Sol alt köşeden yeniden boyutlandır',
};

MouseCursor _cornerCursor(_ResizeCorner corner) => switch (corner) {
  _ResizeCorner.topLeft ||
  _ResizeCorner.bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
  _ResizeCorner.topRight ||
  _ResizeCorner.bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
};

Offset _rotateOffset(Offset point, double angle) {
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  return Offset(
    point.dx * cosine - point.dy * sine,
    point.dx * sine + point.dy * cosine,
  );
}

class _AlbumSelectionOverlay extends StatefulWidget {
  const _AlbumSelectionOverlay({
    super.key,
    required this.element,
    required this.pageSize,
    required this.onGeometryChanged,
    required this.onChanged,
  });

  final AlbumElementModel element;
  final Size pageSize;
  final VoidCallback onGeometryChanged;
  final VoidCallback? onChanged;

  @override
  State<_AlbumSelectionOverlay> createState() => _AlbumSelectionOverlayState();
}

class _AlbumSelectionOverlayState extends State<_AlbumSelectionOverlay> {
  RenderBox? _coordinateSpace;
  Offset _fixedCorner = Offset.zero;
  Offset _baseHandleVector = Offset.zero;
  Offset _rotationCenter = Offset.zero;
  double _rotationStart = 0;
  double _rotationPointerAngle = 0;
  bool _resizeChanged = false;
  bool _rotationChanged = false;

  double get _safeScale {
    final scale = widget.element.scale;
    return scale.isFinite
        ? scale.clamp(albumElementMinScale, albumElementMaxScale)
        : 1;
  }

  double get _safeRotation =>
      widget.element.rotation.isFinite ? widget.element.rotation : 0;

  Offset get _center => Offset(
    (widget.element.x + widget.element.width / 2) * widget.pageSize.width,
    (widget.element.y + widget.element.height / 2) * widget.pageSize.height,
  );

  Offset _pagePoint(Offset globalPosition) {
    final coordinateSpace = _coordinateSpace;
    if (coordinateSpace == null || !coordinateSpace.attached) {
      return globalPosition;
    }
    return coordinateSpace.globalToLocal(globalPosition);
  }

  Offset _cornerPosition(_ResizeCorner corner) {
    final signs = _cornerSigns(corner);
    final localCorner = Offset(
      signs.dx * widget.element.width * widget.pageSize.width * _safeScale / 2,
      signs.dy *
          widget.element.height *
          widget.pageSize.height *
          _safeScale /
          2,
    );
    return _center + _rotateOffset(localCorner, _safeRotation);
  }

  Offset get _topEdgeCenter {
    final localTopEdge = Offset(
      0,
      -widget.element.height * widget.pageSize.height * _safeScale / 2,
    );
    return _center + _rotateOffset(localTopEdge, _safeRotation);
  }

  Offset _rotationHandlePosition(Offset topEdgeCenter) {
    final outward = topEdgeCenter - _center;
    final direction = outward.distanceSquared > .000001
        ? outward / outward.distance
        : const Offset(0, -1);
    return topEdgeCenter + direction * 34;
  }

  void _handleResizeStart(_ResizeCorner corner, DragStartDetails details) {
    final signs = _cornerSigns(corner);
    _coordinateSpace = context.findAncestorRenderObjectOfType<RenderStack>();
    _baseHandleVector = Offset(
      signs.dx * widget.element.width * widget.pageSize.width / 2,
      signs.dy * widget.element.height * widget.pageSize.height / 2,
    );
    _fixedCorner =
        _center - _rotateOffset(_baseHandleVector * _safeScale, _safeRotation);
    _resizeChanged = false;
  }

  void _handleResizeUpdate(DragUpdateDetails details) {
    final diagonal = _rotateOffset(_baseHandleVector * 2, _safeRotation);
    final denominator = diagonal.distanceSquared;
    if (denominator <= .000001) return;
    final fromFixedCorner = _pagePoint(details.globalPosition) - _fixedCorner;
    final projectedScale =
        (fromFixedCorner.dx * diagonal.dx + fromFixedCorner.dy * diagonal.dy) /
        denominator;
    final scale = projectedScale.clamp(
      albumElementMinScale,
      albumElementMaxScale,
    );
    final center =
        _fixedCorner + _rotateOffset(_baseHandleVector * scale, _safeRotation);
    final x = (center.dx / widget.pageSize.width - widget.element.width / 2)
        .clamp(-0.35, 0.92);
    final y = (center.dy / widget.pageSize.height - widget.element.height / 2)
        .clamp(-0.25, 0.94);
    final changed =
        (widget.element.x - x).abs() > .000001 ||
        (widget.element.y - y).abs() > .000001 ||
        (widget.element.scale - scale).abs() > .000001;
    if (!changed) return;
    widget.element.x = x;
    widget.element.y = y;
    widget.element.scale = scale;
    _resizeChanged = true;
    widget.onGeometryChanged();
  }

  void _finishResize() {
    _coordinateSpace = null;
    if (!_resizeChanged) return;
    _resizeChanged = false;
    widget.onChanged?.call();
  }

  void _handleRotationStart(DragStartDetails details) {
    _coordinateSpace = context.findAncestorRenderObjectOfType<RenderStack>();
    _rotationCenter = _center;
    _rotationStart = _safeRotation;
    final pointer = _pagePoint(details.globalPosition) - _rotationCenter;
    _rotationPointerAngle = pointer.distanceSquared > .000001
        ? math.atan2(pointer.dy, pointer.dx)
        : _rotationStart - math.pi / 2;
    _rotationChanged = false;
  }

  void _handleRotationUpdate(DragUpdateDetails details) {
    final pointer = _pagePoint(details.globalPosition) - _rotationCenter;
    if (pointer.distanceSquared <= .000001) return;
    final pointerAngle = math.atan2(pointer.dy, pointer.dx);
    final rawDelta = pointerAngle - _rotationPointerAngle;
    final delta = math.atan2(math.sin(rawDelta), math.cos(rawDelta));
    final rotation = _rotationStart + delta;
    if ((widget.element.rotation - rotation).abs() <= .000001) return;
    widget.element.rotation = rotation;
    _rotationChanged = true;
    widget.onGeometryChanged();
  }

  void _finishRotation() {
    _coordinateSpace = null;
    if (!_rotationChanged) return;
    _rotationChanged = false;
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final corners = [
      for (final corner in _ResizeCorner.values) _cornerPosition(corner),
    ];
    final rotationAnchor = _topEdgeCenter;
    final rotationHandle = _rotationHandlePosition(rotationAnchor);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SelectionChromePainter(
                corners: corners,
                color: color,
                rotationAnchor: rotationAnchor,
                rotationHandle: rotationHandle,
              ),
            ),
          ),
        ),
        for (var index = 0; index < _ResizeCorner.values.length; index++)
          Positioned(
            left: corners[index].dx - 20,
            top: corners[index].dy - 20,
            width: 40,
            height: 40,
            child: Semantics(
              label: context.tr(
                _cornerSemanticsLabel(_ResizeCorner.values[index]),
              ),
              button: true,
              child: MouseRegion(
                cursor: _cornerCursor(_ResizeCorner.values[index]),
                child: GestureDetector(
                  key: ValueKey(
                    'selection-resize-${_ResizeCorner.values[index].name}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      _handleResizeStart(_ResizeCorner.values[index], details),
                  onPanUpdate: _handleResizeUpdate,
                  onPanEnd: (_) => _finishResize(),
                  onPanCancel: _finishResize,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55000000), blurRadius: 3),
                        ],
                      ),
                      child: const SizedBox.square(dimension: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: rotationHandle.dx - 24,
          top: rotationHandle.dy - 24,
          width: 48,
          height: 48,
          child: Semantics(
            label: context.tr(
              widget.element.type == AlbumElementType.photo
                  ? 'Fotoğrafı döndür'
                  : 'Öğeyi döndür',
            ),
            hint: context.tr('Sürükleyerek döndür'),
            button: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                key: const ValueKey('selection-rotate'),
                behavior: HitTestBehavior.opaque,
                onPanStart: _handleRotationStart,
                onPanUpdate: _handleRotationUpdate,
                onPanEnd: (_) => _finishRotation(),
                onPanCancel: _finishRotation,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x55000000), blurRadius: 3),
                      ],
                    ),
                    child: SizedBox.square(
                      dimension: 32,
                      child: Icon(
                        Icons.rotate_right_rounded,
                        size: 19,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionChromePainter extends CustomPainter {
  const _SelectionChromePainter({
    required this.corners,
    required this.color,
    this.rotationAnchor,
    this.rotationHandle,
  });

  final List<Offset> corners;
  final Color color;
  final Offset? rotationAnchor;
  final Offset? rotationHandle;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    path.close();
    final anchor = rotationAnchor;
    final handle = rotationHandle;
    if (anchor != null && handle != null) {
      canvas.drawLine(
        anchor,
        handle,
        Paint()
          ..color = Colors.white.withValues(alpha: .9)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        anchor,
        handle,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SelectionChromePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.corners != corners ||
      oldDelegate.rotationAnchor != rotationAnchor ||
      oldDelegate.rotationHandle != rotationHandle;
}

class _PhotoShapeClip extends StatelessWidget {
  const _PhotoShapeClip({required this.shape, required this.child});

  final AlbumPhotoShape shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final expanded = SizedBox.expand(child: child);
    return switch (shape) {
      AlbumPhotoShape.circle => ClipOval(child: expanded),
      AlbumPhotoShape.arch => ClipPath(
        clipper: const _PhotoArchClipper(),
        child: expanded,
      ),
      AlbumPhotoShape.torn => ClipPath(
        clipper: const _SoftTornPhotoClipper(),
        child: expanded,
      ),
      AlbumPhotoShape.free ||
      AlbumPhotoShape.square ||
      AlbumPhotoShape.landscape ||
      AlbumPhotoShape.portrait => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: expanded,
      ),
    };
  }
}

class _PhotoArchClipper extends CustomClipper<Path> {
  const _PhotoArchClipper();

  @override
  Path getClip(Size size) {
    final radius = size.width / 2;
    return Path()
      ..moveTo(0, radius)
      ..arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _PhotoArchClipper oldClipper) => false;
}

class _SoftTornPhotoClipper extends CustomClipper<Path> {
  const _SoftTornPhotoClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(2, 1);
    const steps = 16;
    for (var index = 1; index <= steps; index++) {
      final x = size.width * index / steps;
      path.lineTo(x, index.isEven ? 2.3 : .4);
    }
    for (var index = 1; index <= steps; index++) {
      final y = size.height * index / steps;
      path.lineTo(size.width - (index.isEven ? 2.2 : .3), y);
    }
    for (var index = steps - 1; index >= 0; index--) {
      final x = size.width * index / steps;
      path.lineTo(x, size.height - (index.isEven ? 2.2 : .3));
    }
    for (var index = steps - 1; index >= 0; index--) {
      final y = size.height * index / steps;
      path.lineTo(index.isEven ? 2.2 : .3, y);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant _SoftTornPhotoClipper oldClipper) => false;
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

class _SlideMountFrame extends StatelessWidget {
  const _SlideMountFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0D0),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF8D8273), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: child),
            const Positioned(
              left: 0,
              right: 0,
              bottom: -16,
              child: Text(
                '36 · ALBUMIUM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6D6254),
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StitchedLinenPhotoFrame extends StatelessWidget {
  const _StitchedLinenPhotoFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFB8A58C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF786650), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const _StitchedPhotoFramePainter(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _StitchedPhotoFramePainter extends CustomPainter {
  const _StitchedPhotoFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xCFF4E5C9)
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round;
    const inset = 5.0;
    const step = 8.0;
    for (var x = inset; x < size.width - inset; x += step) {
      canvas.drawLine(Offset(x, inset), Offset(x + 3, inset), paint);
      canvas.drawLine(
        Offset(x, size.height - inset),
        Offset(x + 3, size.height - inset),
        paint,
      );
    }
    for (var y = inset; y < size.height - inset; y += step) {
      canvas.drawLine(Offset(inset, y), Offset(inset, y + 3), paint);
      canvas.drawLine(
        Offset(size.width - inset, y),
        Offset(size.width - inset, y + 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StitchedPhotoFramePainter oldDelegate) => false;
}

class _PhotoBoothFrame extends StatelessWidget {
  const _PhotoBoothFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF181716),
        boxShadow: [
          BoxShadow(
            color: Color(0x48000000),
            blurRadius: 11,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 18),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            child,
            Align(
              alignment: const Alignment(0, -.34),
              child: Container(height: 1.2, color: const Color(0xAAEEE4D5)),
            ),
            Align(
              alignment: const Alignment(0, .34),
              child: Container(height: 1.2, color: const Color(0xAAEEE4D5)),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: -14,
              child: Text(
                'MEMORY STRIP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEDE3D3),
                  fontSize: 6,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
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

/// Keeps the complete text and its font ascenders inside the saved element
/// rectangle. This matters for off-screen MP4 capture where a late Google Font
/// swap previously changed the line metrics and clipped the last line.
class _FittedAlbumText extends StatelessWidget {
  const _FittedAlbumText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 12,
              softWrap: true,
              overflow: TextOverflow.visible,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
              ),
              style: style,
            ),
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
