import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import 'album_page_canvas.dart';

@immutable
class AlbumPhotoStyleSelection {
  const AlbumPhotoStyleSelection({
    required this.frameStyle,
    required this.shape,
  });

  final int frameStyle;
  final AlbumPhotoShape shape;
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
};

IconData albumPhotoShapeIcon(AlbumPhotoShape shape) => switch (shape) {
  AlbumPhotoShape.free => Icons.crop_free_rounded,
  AlbumPhotoShape.square => Icons.crop_square_rounded,
  AlbumPhotoShape.landscape => Icons.crop_16_9_rounded,
  AlbumPhotoShape.portrait => Icons.crop_portrait_rounded,
  AlbumPhotoShape.circle => Icons.circle_outlined,
  AlbumPhotoShape.arch => Icons.architecture_rounded,
  AlbumPhotoShape.torn => Icons.broken_image_outlined,
};

/// Updates the saved crop shape and, for fixed-ratio shapes, adjusts the
/// element around its existing centre. Coordinates are normalized to a 5:7
/// album page, matching both the editor page and special-card canvas.
void applyAlbumPhotoShape(AlbumElementModel element, AlbumPhotoShape shape) {
  element.photoShape = shape;
  final visualAspect = switch (shape) {
    AlbumPhotoShape.square || AlbumPhotoShape.circle => 1.0,
    AlbumPhotoShape.landscape || AlbumPhotoShape.torn => 4 / 3,
    AlbumPhotoShape.portrait || AlbumPhotoShape.arch => 4 / 5,
    AlbumPhotoShape.free => null,
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
}) {
  return showModalBottomSheet<AlbumPhotoStyleSelection>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PhotoStylePickerSheet(
      selectedFrameStyle: selectedFrameStyle % albumPhotoFrameCount,
      selectedShape: selectedShape,
    ),
  );
}

class _PhotoStylePickerSheet extends StatefulWidget {
  const _PhotoStylePickerSheet({
    required this.selectedFrameStyle,
    required this.selectedShape,
  });

  final int selectedFrameStyle;
  final AlbumPhotoShape selectedShape;

  @override
  State<_PhotoStylePickerSheet> createState() => _PhotoStylePickerSheetState();
}

class _PhotoStylePickerSheetState extends State<_PhotoStylePickerSheet> {
  late int _frameStyle;
  late AlbumPhotoShape _shape;

  @override
  void initState() {
    super.initState();
    _frameStyle = widget.selectedFrameStyle;
    _shape = widget.selectedShape;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return FractionallySizedBox(
      heightFactor: tablet ? .76 : .88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.auto_fix_high_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Fotoğraf Stüdyosu'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.tr('Biçimi ve çerçeveyi birlikte tasarla'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('Biçim'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final shape in AlbumPhotoShape.values)
                  ChoiceChip(
                    key: ValueKey('photo-shape-${shape.name}'),
                    selected: _shape == shape,
                    showCheckmark: false,
                    avatar: Icon(albumPhotoShapeIcon(shape), size: 16),
                    label: Text(context.tr(albumPhotoShapeLabel(shape))),
                    onSelected: (_) => setState(() => _shape = shape),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  context.tr('Çerçeve'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  context.tr(
                    '{count} seçenek',
                    values: {'count': albumPhotoFrameCount},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: tablet ? 5 : 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .92,
                ),
                itemCount: albumPhotoFrameCount,
                itemBuilder: (context, index) => _FrameChoiceTile(
                  index: index,
                  selected: index == _frameStyle,
                  onTap: () => setState(() => _frameStyle = index),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('apply-photo-style'),
                onPressed: () => Navigator.pop(
                  context,
                  AlbumPhotoStyleSelection(
                    frameStyle: _frameStyle,
                    shape: _shape,
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(context.tr('Fotoğrafa uygula')),
              ),
            ),
          ],
        ),
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
                  CustomPaint(painter: _FramePreviewPainter(index)),
                  Center(
                    child: Icon(
                      _frameIcons[index],
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
