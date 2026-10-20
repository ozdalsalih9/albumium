import 'photo_crop_editor.dart';
import 'dart:math' as math;
import 'paper_materials.dart';
import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import 'album_page_canvas.dart';

@immutable
class AlbumPhotoStyleSelection {
  const AlbumPhotoStyleSelection({
    required this.frameStyle,
    required this.shape,
    this.frameScale = 1,
    this.frameSpacing = 0,
    this.draft,
    this.scope = PhotoStyleScope.selected,
  });

  final int frameStyle;
  final AlbumPhotoShape shape;
  final double frameScale, frameSpacing;
  final AlbumElementModel? draft;
  final PhotoStyleScope scope;
}

enum PhotoStyleScope { selected, page, album }

void applyPhotoStudioResult(
  AlbumElementModel target,
  AlbumPhotoStyleSelection result, {
  bool includeCrop = false,
}) {
  if (target.locked) return;
  target.frameStyle = result.frameStyle;
  target.frameScale = result.frameScale;
  target.frameSpacing = result.frameSpacing;
  applyAlbumPhotoShape(target, result.shape);
  if (includeCrop && result.draft != null) {
    final draft = result.draft!;
    target.photoCrop = draft.photoCrop;
    target.photoFit = draft.photoFit;
    target.x = draft.x;
    target.y = draft.y;
    target.width = draft.width;
    target.height = draft.height;
  }
}

const _frameIcons = <IconData>[
  Icons.crop_square_rounded,
  Icons.photo_outlined,
  Icons.bookmarks_outlined,
  Icons.rounded_corner_rounded,
  Icons.filter_vintage_outlined,
  Icons.filter_frames_outlined,
  Icons.texture_rounded,
  Icons.movie_outlined,
  Icons.museum_outlined,
  Icons.grid_goldenratio_rounded,
  Icons.local_post_office_outlined,
  Icons.auto_awesome_mosaic_outlined,
  Icons.photo_size_select_large_outlined,
  Icons.slideshow_rounded,
  Icons.linear_scale_rounded,
  Icons.view_stream_rounded,
];

String albumPhotoShapeLabel(AlbumPhotoShape shape) => switch (shape) {
  AlbumPhotoShape.free => 'Serbest',
  AlbumPhotoShape.square => 'Kare',
  AlbumPhotoShape.landscape => 'Yatay',
  AlbumPhotoShape.portrait => 'Dikey',
  AlbumPhotoShape.circle => 'Yuvarlak',
  AlbumPhotoShape.arch => 'Kemer',
  AlbumPhotoShape.torn => 'Yırtık',
  AlbumPhotoShape.rounded => 'Yumuşak köşe',
  AlbumPhotoShape.heart => 'Kalp',
  AlbumPhotoShape.diamond => 'Elmas',
  AlbumPhotoShape.hexagon => 'Altıgen',
};

IconData albumPhotoShapeIcon(AlbumPhotoShape shape) => switch (shape) {
  AlbumPhotoShape.free => Icons.crop_free_rounded,
  AlbumPhotoShape.square => Icons.crop_square_rounded,
  AlbumPhotoShape.landscape => Icons.crop_16_9_rounded,
  AlbumPhotoShape.portrait => Icons.crop_portrait_rounded,
  AlbumPhotoShape.circle => Icons.circle_outlined,
  AlbumPhotoShape.arch => Icons.architecture_rounded,
  AlbumPhotoShape.torn => Icons.broken_image_outlined,
  AlbumPhotoShape.rounded => Icons.rounded_corner_rounded,
  AlbumPhotoShape.heart => Icons.favorite_border_rounded,
  AlbumPhotoShape.diamond => Icons.diamond_outlined,
  AlbumPhotoShape.hexagon => Icons.hexagon_outlined,
};

/// Updates the saved crop shape and, for fixed-ratio shapes, adjusts the
/// element around its existing centre. Coordinates are normalized to a 5:7
/// album page, matching both the editor page and special-card canvas.
void applyAlbumPhotoShape(AlbumElementModel element, AlbumPhotoShape shape) {
  element.photoShape = shape;
  if (element.groupId != null) return;
  final visualAspect = switch (shape) {
    AlbumPhotoShape.square ||
    AlbumPhotoShape.circle ||
    AlbumPhotoShape.heart ||
    AlbumPhotoShape.diamond ||
    AlbumPhotoShape.hexagon => 1.0,
    AlbumPhotoShape.landscape || AlbumPhotoShape.torn => 4 / 3,
    AlbumPhotoShape.portrait || AlbumPhotoShape.arch => 4 / 5,
    AlbumPhotoShape.free || AlbumPhotoShape.rounded => null,
  };
  if (visualAspect == null) return;

  const pageAspect = 5 / 7;
  final centerX = element.x + element.width / 2;
  final centerY = element.y + element.height / 2;
  final targetHeight = (element.width * pageAspect / visualAspect).clamp(
    .12,
    .88,
  );
  element.height = targetHeight;
  element.x = (centerX - element.width / 2).clamp(-.3, 1 - element.width);
  element.y = (centerY - targetHeight / 2).clamp(-.2, 1 - targetHeight);
}

Future<AlbumPhotoStyleSelection?> showAlbumPhotoStylePicker(
  BuildContext context, {
  required int selectedFrameStyle,
  required AlbumPhotoShape selectedShape,
  AlbumElementModel? element,
  bool allowAlbumScope = false,
}) {
  return showModalBottomSheet<AlbumPhotoStyleSelection>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PhotoStylePickerSheet(
      selectedFrameStyle: selectedFrameStyle % albumPhotoFrameCount,
      selectedShape: selectedShape,
      element: element,
      allowAlbumScope: allowAlbumScope,
    ),
  );
}

class _PhotoStylePickerSheet extends StatefulWidget {
  const _PhotoStylePickerSheet({
    required this.selectedFrameStyle,
    required this.selectedShape,
    this.element,
    this.allowAlbumScope = false,
  });

  final int selectedFrameStyle;
  final AlbumPhotoShape selectedShape;
  final AlbumElementModel? element;
  final bool allowAlbumScope;

  @override
  State<_PhotoStylePickerSheet> createState() => _PhotoStylePickerSheetState();
}

class _PhotoStylePickerSheetState extends State<_PhotoStylePickerSheet> {
  late AlbumElementModel _draft;
  int _section = 0;
  PhotoStyleScope _scope = PhotoStyleScope.selected;
  @override
  void initState() {
    super.initState();
    _draft = widget.element == null
        ? AlbumElementModel(
            id: 'photo-style-preview',
            type: AlbumElementType.photo,
            content: '',
            x: .15,
            y: .15,
            width: .7,
            height: .7,
            photoSlot: true,
            frameStyle: widget.selectedFrameStyle,
            photoShape: widget.selectedShape,
          )
        : AlbumElementModel.fromJson(widget.element!.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final previewScale = math.min(.8 / _draft.width, .8 / _draft.height);
    final preview = AlbumElementModel.fromJson(_draft.toJson())
      ..width = _draft.width * previewScale
      ..height = _draft.height * previewScale
      ..scale = 1
      ..rotation = 0;
    preview.x = (1 - preview.width) / 2;
    preview.y = (1 - preview.height) / 2;
    final previewHeight = (MediaQuery.sizeOf(context).height * .23).clamp(
      70.0,
      200.0,
    );
    final showTabIcons = MediaQuery.sizeOf(context).width >= 400;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('Fotoğraf Stüdyosu'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Vazgeç'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              width: previewHeight * 5 / 7,
              height: previewHeight,
              child: RepaintBoundary(
                key: const ValueKey('photo-studio-live-preview'),
                child: AlbumPageCanvas(
                  showPageNumber: false,
                  page: AlbumPageModel(
                    id: 'studio-preview',
                    backgroundColor: 0xFFF0EBE2,
                    elements: [preview],
                  ),
                  theme: themeById('minimal_editorial'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: showTabIcons
                      ? const Icon(Icons.category_outlined)
                      : null,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(context.tr('Şekil'), softWrap: false),
                  ),
                ),
                ButtonSegment(
                  value: 1,
                  icon: showTabIcons
                      ? const Icon(Icons.filter_frames_outlined)
                      : null,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(context.tr('Çerçeve'), softWrap: false),
                  ),
                ),
                ButtonSegment(
                  value: 2,
                  icon: showTabIcons ? const Icon(Icons.crop) : null,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(context.tr('Kırp'), softWrap: false),
                  ),
                ),
              ],
              selected: {_section},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _section = v.first),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('photo-studio-section-$_section'),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_section == 0)
                    LayoutBuilder(
                      builder: (context, bounds) => GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: bounds.maxWidth > 500 ? 5 : 3,
                          mainAxisExtent:
                              55 +
                              MediaQuery.textScalerOf(context).scale(12) * 2.5,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                        ),
                        children: [
                          for (final shape in AlbumPhotoShape.values)
                            Semantics(
                              selected: _draft.photoShape == shape,
                              button: true,
                              child: InkWell(
                                key: ValueKey('photo-shape-${shape.name}'),
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(
                                  () => applyAlbumPhotoShape(_draft, shape),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _draft.photoShape == shape
                                        ? colors.primaryContainer
                                        : colors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _draft.photoShape == shape
                                          ? colors.primary
                                          : colors.outlineVariant,
                                      width: _draft.photoShape == shape ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        albumPhotoShapeIcon(shape),
                                        size: 25,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        context.tr(albumPhotoShapeLabel(shape)),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_section == 1) ...[
                    LayoutBuilder(
                      builder: (context, bounds) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: bounds.maxWidth > 500 ? 5 : 3,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          mainAxisExtent:
                              85 +
                              MediaQuery.textScalerOf(context).scale(10) * 2,
                        ),
                        itemCount: albumPhotoFrameCount,
                        itemBuilder: (context, index) => _FrameChoiceTile(
                          index: index,
                          selected: index == _draft.frameStyle,
                          onTap: () =>
                              setState(() => _draft.frameStyle = index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(context.tr('Çerçeve kalınlığı')),
                    Slider(
                      key: const ValueKey('photo-frame-thickness'),
                      value: _draft.frameScale,
                      min: .4,
                      max: 2.4,
                      divisions: 20,
                      label: '${(_draft.frameScale * 100).round()}%',
                      onChanged: (v) => setState(() => _draft.frameScale = v),
                    ),
                    Text(context.tr('İç boşluk')),
                    Slider(
                      key: const ValueKey('photo-frame-spacing'),
                      value: _draft.frameSpacing,
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: '${_draft.frameSpacing.round()}',
                      onChanged: (v) => setState(() => _draft.frameSpacing = v),
                    ),
                  ],
                  if (_section == 2) ...[
                    Text(context.tr('Kırpma yalnızca bu fotoğrafa uygulanır.')),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      key: const ValueKey('studio-crop-photo'),
                      onPressed: _draft.content.isEmpty
                          ? null
                          : () async {
                              if (await editAlbumPhotoCrop(context, _draft) &&
                                  mounted) {
                                setState(() {});
                              }
                            },
                      icon: const Icon(Icons.crop),
                      label: Text(context.tr('Kırp')),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _draft.photoCrop = fullPhotoCrop),
                      child: Text(context.tr('Kırpmayı sıfırla')),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    context.tr('Stili uygula'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PhotoStyleScope>(
                    key: const ValueKey('photo-style-scope'),
                    isExpanded: true,
                    initialValue: _scope,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final scope in PhotoStyleScope.values)
                        if (scope != PhotoStyleScope.album ||
                            widget.allowAlbumScope)
                          DropdownMenuItem(
                            value: scope,
                            child: Text(
                              context.tr(switch (scope) {
                                PhotoStyleScope.selected =>
                                  'Yalnızca bu fotoğrafa',
                                PhotoStyleScope.page =>
                                  'Bu sayfadaki fotoğraflara',
                                PhotoStyleScope.album =>
                                  'Albümdeki fotoğraflara',
                              }),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    ],
                    onChanged: (v) => setState(() => _scope = v!),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('Kilitli fotoğraflar değiştirilmez.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr('Vazgeç')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('apply-photo-style'),
                      onPressed: () => Navigator.pop(
                        context,
                        AlbumPhotoStyleSelection(
                          frameStyle: _draft.frameStyle,
                          shape: _draft.photoShape,
                          frameScale: _draft.frameScale,
                          frameSpacing: _draft.frameSpacing,
                          draft: _draft,
                          scope: _scope,
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(context.tr('Uygula')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameChoiceTile extends StatelessWidget {
  const _FrameChoiceTile({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('photo-frame-$index'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: .62)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (index >= 16)
                    PaperKitImage(
                      'frame_${paperPhotoFrames[index - 16]}',
                      preview: true,
                    )
                  else
                    CustomPaint(painter: _FramePreviewPainter(index)),
                  Center(
                    child: Icon(
                      index < _frameIcons.length
                          ? _frameIcons[index]
                          : Icons.photo_outlined,
                      size: 22,
                      color: const Color(0xFFD9C39C),
                    ),
                  ),
                  if (selected)
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              context.tr(albumPhotoFrameLabel(index)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? colors.primary : colors.onSurface,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramePreviewPainter extends CustomPainter {
  const _FramePreviewPainter(this.style);

  final int style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * .18,
      size.height * .08,
      size.width * .64,
      size.height * .82,
    );
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    canvas.drawShadow(shadowPath, const Color(0x55000000), 3, false);

    final outerColor = switch (style) {
      2 || 5 || 7 || 15 => const Color(0xFF29231F),
      4 || 8 => const Color(0xFFC5A357),
      9 => const Color(0xFFC59BA3),
      10 || 12 || 13 => const Color(0xFFE7D8BE),
      14 => const Color(0xFFB7A48B),
      _ => const Color(0xFFF1E8D9),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style == 3 ? 13 : 3)),
      Paint()..color = outerColor,
    );
    final inset = style == 1
        ? const EdgeInsets.fromLTRB(5, 5, 5, 12)
        : style == 9 || style == 12
        ? const EdgeInsets.fromLTRB(7, 7, 7, 9)
        : const EdgeInsets.all(5);
    final inner = Rect.fromLTRB(
      rect.left + inset.left,
      rect.top + inset.top,
      rect.right - inset.right,
      rect.bottom - inset.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C7A6D), Color(0xFF39474A)],
        ).createShader(inner),
    );

    if (style == 7) {
      final hole = Paint()..color = const Color(0xFFE8DCC8);
      for (var y = rect.top + 5; y < rect.bottom - 2; y += 9) {
        canvas.drawRect(Rect.fromLTWH(rect.left + 1, y, 3, 4), hole);
        canvas.drawRect(Rect.fromLTWH(rect.right - 4, y, 3, 4), hole);
      }
    } else if (style == 11) {
      final tape = Paint()..color = const Color(0xB8D6A8B2);
      canvas.save();
      canvas.translate(rect.left + 2, rect.top + 4);
      canvas.rotate(-.18);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 25, 7), tape);
      canvas.restore();
    } else if (style == 4 || style == 5) {
      final corner = Paint()
        ..color = style == 4 ? const Color(0xFFE0BF6B) : const Color(0xFF191817)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawLine(
        inner.topLeft,
        inner.topLeft + const Offset(10, 0),
        corner,
      );
      canvas.drawLine(
        inner.topLeft,
        inner.topLeft + const Offset(0, 10),
        corner,
      );
      canvas.drawLine(
        inner.bottomRight,
        inner.bottomRight - const Offset(10, 0),
        corner,
      );
      canvas.drawLine(
        inner.bottomRight,
        inner.bottomRight - const Offset(0, 10),
        corner,
      );
    } else if (style == 14) {
      final stitch = Paint()
        ..color = const Color(0xFFF2DFC0)
        ..strokeWidth = 1;
      for (var x = rect.left + 4; x < rect.right - 4; x += 6) {
        canvas.drawLine(
          Offset(x, rect.top + 3),
          Offset(x + 2, rect.top + 3),
          stitch,
        );
        canvas.drawLine(
          Offset(x, rect.bottom - 3),
          Offset(x + 2, rect.bottom - 3),
          stitch,
        );
      }
    } else if (style == 15) {
      final separator = Paint()
        ..color = const Color(0xBDEFE4D3)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(inner.left, inner.top + inner.height / 3),
        Offset(inner.right, inner.top + inner.height / 3),
        separator,
      );
      canvas.drawLine(
        Offset(inner.left, inner.top + inner.height * 2 / 3),
        Offset(inner.right, inner.top + inner.height * 2 / 3),
        separator,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FramePreviewPainter oldDelegate) =>
      oldDelegate.style != style;
}
