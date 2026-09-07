import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/album_models.dart';
import '../l10n/albumium_localizations.dart';

Rect albumElementBounds(AlbumElementModel e, Size page) {
  final w = e.width * page.width * e.scale;
  final h = e.height * page.height * e.scale;
  return Rect.fromCenter(
    center: Offset(
      (e.x + e.width / 2) * page.width,
      (e.y + e.height / 2) * page.height,
    ),
    width: w * math.cos(e.rotation).abs() + h * math.sin(e.rotation).abs(),
    height: w * math.sin(e.rotation).abs() + h * math.cos(e.rotation).abs(),
  );
}

void snapAlbumElement(AlbumElementModel e, Size page) {
  if (e.locked) return;
  final r = albumElementBounds(e, page);
  double closest(List<double> deltas) {
    final value = deltas.reduce((a, b) => a.abs() < b.abs() ? a : b);
    return value.abs() <= 5 ? value : 0;
  }

  e.x +=
      closest([-r.left, page.width / 2 - r.center.dx, page.width - r.right]) /
      page.width;
  e.y +=
      closest([-r.top, page.height / 2 - r.center.dy, page.height - r.bottom]) /
      page.height;
}

class AlbumAlignmentPainter extends CustomPainter {
  AlbumAlignmentPainter(AlbumElementModel element, this.page)
    : bounds = albumElementBounds(element, page);
  final Rect bounds;
  final Size page;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xFFDB408C)
      ..strokeWidth = 1;
    final xs = [0.0, page.width / 2, page.width];
    final ys = [0.0, page.height / 2, page.height];
    final bx = [bounds.left, bounds.center.dx, bounds.right];
    final by = [bounds.top, bounds.center.dy, bounds.bottom];
    for (var i = 0; i < 3; i++) {
      if ((xs[i] - bx[i]).abs() <= 5) {
        final x = xs[i].clamp(1.0, page.width - 1);
        for (double y = 0; y < size.height; y += 9) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, math.min(y + 5, size.height)),
            pen,
          );
        }
      }
      if ((ys[i] - by[i]).abs() <= 5) {
        final y = ys[i].clamp(1.0, page.height - 1);
        for (double x = 0; x < size.width; x += 9) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 5, size.width), y),
            pen,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(AlbumAlignmentPainter oldDelegate) =>
      bounds != oldDelegate.bounds || page != oldDelegate.page;
}

const editorCardColors = <int>[
  0xFFFFF3E0,
  0xFFFCE4EC,
  0xFFE8F5E9,
  0xFFE3F2FD,
  0xFFEDE7F6,
  0xFFFFF8E1,
  0xFFFFFFFF,
  0xFFD7CCC8,
];

class ElementEditPanel extends StatefulWidget {
  const ElementEditPanel({
    super.key,
    required this.element,
    required this.onChanged,
    required this.onClose,
    required this.onStyle,
    required this.onCrop,
    required this.onDuplicate,
    required this.onDelete,
    required this.onLayer,
    required this.canMoveLayer,
  });
  final AlbumElementModel element;
  final VoidCallback onChanged, onClose, onStyle, onCrop, onDuplicate, onDelete;
  final ValueChanged<AlbumElementLayerAction> onLayer;
  final bool Function(AlbumElementLayerAction) canMoveLayer;
  @override
  State<ElementEditPanel> createState() => _ElementEditPanelState();
}

class _ElementEditPanelState extends State<ElementEditPanel> {
  String _section = 'Araçlar';
  void _change(VoidCallback action) {
    if (widget.element.locked) return;
    setState(action);
    widget.onChanged();
  }

  Widget _button(String label, IconData icon, VoidCallback? action) =>
      OutlinedButton.icon(
        onPressed: widget.element.locked ? null : action,
        icon: Icon(icon, size: 19),
        label: Text(context.tr(label)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
  void _align(int column, int row) => _change(() {
    final e = widget.element;
    const page = Size(500, 700);
    final bounds = albumElementBounds(e, page);
    final cx = column == 0
        ? bounds.width / 2
        : column == 1
        ? 250.0
        : 500 - bounds.width / 2;
    final cy = row == 0
        ? bounds.height / 2
        : row == 1
        ? 350.0
        : 700 - bounds.height / 2;
    e.x = cx / 500 - e.width / 2;
    e.y = cy / 700 - e.height / 2;
  });
  @override
  Widget build(BuildContext context) {
    final e = widget.element;
    final type = switch (e.type) {
      AlbumElementType.photo => 'Fotoğraf',
      AlbumElementType.text => 'Yazı',
      AlbumElementType.card => 'Kart',
      AlbumElementType.sticker => 'Şekil / Süs',
      AlbumElementType.drawing => 'Çizim',
    };
    final tools = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _button(
          'Öne al',
          Icons.flip_to_front,
          widget.canMoveLayer(AlbumElementLayerAction.moveUp)
              ? () => widget.onLayer(AlbumElementLayerAction.moveUp)
              : null,
        ),
        _button(
          'Arkaya al',
          Icons.flip_to_back,
          widget.canMoveLayer(AlbumElementLayerAction.moveDown)
              ? () => widget.onLayer(AlbumElementLayerAction.moveDown)
              : null,
        ),
        _button('Düzenle', Icons.edit_outlined, widget.onStyle),
        _button(
          'Sola döndür',
          Icons.rotate_left,
          () => _change(() => e.rotation -= math.pi / 12),
        ),
        _button(
          'Sağa döndür',
          Icons.rotate_right,
          () => _change(() => e.rotation += math.pi / 12),
        ),
        if (e.type == AlbumElementType.photo)
          _button('Kırp', Icons.crop, widget.onCrop),
        _button(
          'Küçült',
          Icons.remove,
          () =>
              _change(() => scaleAlbumElementBy(e, 1 / albumElementScaleStep)),
        ),
        _button(
          'Büyüt',
          Icons.add,
          () => _change(() => scaleAlbumElementBy(e, albumElementScaleStep)),
        ),
        _button(
          'Sıfırla',
          Icons.restart_alt,
          () => _change(() => resetAlbumElementTransform(e)),
        ),
        _button('Kopyala', Icons.copy, widget.onDuplicate),
        _button('Sil', Icons.delete_outline, widget.onDelete),
      ],
    );
    final precision = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: context.tr('Sola'),
          onPressed: e.locked ? null : () => _change(() => e.x -= 1 / 500),
          icon: const Icon(Icons.arrow_back),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: context.tr('Yukarı'),
              onPressed: e.locked ? null : () => _change(() => e.y -= 1 / 700),
              icon: const Icon(Icons.arrow_upward),
            ),
            Padding(
              padding: const EdgeInsets.all(3),
              child: Text(context.tr('Tek adım')),
            ),
            IconButton.filledTonal(
              tooltip: context.tr('Aşağı'),
              onPressed: e.locked ? null : () => _change(() => e.y += 1 / 700),
              icon: const Icon(Icons.arrow_downward),
            ),
          ],
        ),
        IconButton.filledTonal(
          tooltip: context.tr('Sağa'),
          onPressed: e.locked ? null : () => _change(() => e.x += 1 / 500),
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
    final align = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var col = 0; col < 3; col++)
                IconButton.filledTonal(
                  tooltip: context.tr(
                    [
                      'Sol üst',
                      'Üst orta',
                      'Sağ üst',
                      'Sol orta',
                      'Tam orta',
                      'Sağ orta',
                      'Sol alt',
                      'Alt orta',
                      'Sağ alt',
                    ][row * 3 + col],
                  ),
                  onPressed: e.locked ? null : () => _align(col, row),
                  icon: Icon(
                    [
                      Icons.north_west,
                      Icons.north,
                      Icons.north_east,
                      Icons.west,
                      Icons.filter_center_focus,
                      Icons.east,
                      Icons.south_west,
                      Icons.south,
                      Icons.south_east,
                    ][row * 3 + col],
                  ),
                ),
            ],
          ),
      ],
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .38,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.tr(type)} · ${(e.scale * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => e.locked = !e.locked);
                        widget.onChanged();
                      },
                      icon: Icon(
                        e.locked ? Icons.lock : Icons.lock_open,
                        size: 18,
                      ),
                      label: Text(
                        context.tr(e.locked ? 'Kilidi aç' : 'Sabitle'),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      tooltip: context.tr('Bitti'),
                      icon: const Icon(Icons.check),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final section in [
                        'Araçlar',
                        'Katmanlar',
                        'Hassas ayar',
                        'Hizala',
                        if (e.type == AlbumElementType.card) 'Renk',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(context.tr(section)),
                            selected: _section == section,
                            onSelected: (_) =>
                                setState(() => _section = section),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (e.locked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.tr('Nesne sabit. Düzenlemek için kilidi aç.'),
                    ),
                  ),
                if (_section == 'Araçlar') tools,
                if (_section == 'Katmanlar')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in AlbumElementLayerAction.values)
                        _button(
                          switch (action) {
                            AlbumElementLayerAction.moveUp => 'Bir üste getir',
                            AlbumElementLayerAction.moveDown =>
                              'Bir alta gönder',
                            AlbumElementLayerAction.bringToFront =>
                              'En üste getir',
                            AlbumElementLayerAction.sendToBack =>
                              'En alta gönder',
                          },
                          switch (action) {
                            AlbumElementLayerAction.moveUp =>
                              Icons.arrow_upward,
                            AlbumElementLayerAction.moveDown =>
                              Icons.arrow_downward,
                            AlbumElementLayerAction.bringToFront =>
                              Icons.vertical_align_top,
                            AlbumElementLayerAction.sendToBack =>
                              Icons.vertical_align_bottom,
                          },
                          widget.canMoveLayer(action)
                              ? () => widget.onLayer(action)
                              : null,
                        ),
                    ],
                  ),
                if (_section == 'Hassas ayar') precision,
                if (_section == 'Hizala') align,
                if (_section == 'Renk')
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final color in editorCardColors)
                        IconButton(
                          tooltip: '#${color.toRadixString(16).substring(2)}',
                          onPressed: e.locked
                              ? null
                              : () => _change(() => e.cardColor = color),
                          icon: Icon(
                            e.cardColor == color
                                ? Icons.check_circle
                                : Icons.circle,
                            color: Color(color),
                            shadows: const [
                              Shadow(color: Colors.grey, blurRadius: 2),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
