import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/album_models.dart';
import '../l10n/albumium_localizations.dart';
import '../services/personal_sticker_storage.dart';
import 'sticker_packs.dart';

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
    this.onFitPhoto,
  });
  final AlbumElementModel element;
  final VoidCallback onChanged, onClose, onStyle, onCrop, onDuplicate, onDelete;
  final VoidCallback? onFitPhoto;
  final ValueChanged<AlbumElementLayerAction> onLayer;
  final bool Function(AlbumElementLayerAction) canMoveLayer;
  @override
  State<ElementEditPanel> createState() => _ElementEditPanelState();
}

class _ElementEditPanelState extends State<ElementEditPanel> {
  /// Above this width the summary and the tool strip share a single row.
  static const _wideBreakpoint = 600.0;

  /// The extra panels stay collapsed so the strip alone carries the selection.
  String? _section;

  void _change(VoidCallback action) {
    if (widget.element.locked) return;
    setState(action);
    widget.onChanged();
  }

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

  Widget _tool(
    String tooltip,
    IconData icon,
    VoidCallback? action, {
    Color? color,
  }) => IconButton(
    tooltip: context.tr(tooltip),
    onPressed: widget.element.locked ? null : action,
    icon: Icon(icon, size: 22),
    color: color,
    visualDensity: VisualDensity.compact,
  );

  Widget _buildPrecision() {
    final e = widget.element;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PrecisionMoveButton(
          key: ValueKey('${e.id}-Sola'),
          tooltip: context.tr('Sola'),
          onStep: e.locked ? null : () => _change(() => e.x -= 1 / 500),
          icon: const Icon(Icons.arrow_back),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrecisionMoveButton(
              key: ValueKey('${e.id}-Yukarı'),
              tooltip: context.tr('Yukarı'),
              onStep: e.locked ? null : () => _change(() => e.y -= 1 / 700),
              icon: const Icon(Icons.arrow_upward),
            ),
            Padding(
              padding: const EdgeInsets.all(3),
              child: Text(context.tr('Tek adım')),
            ),
            _PrecisionMoveButton(
              key: ValueKey('${e.id}-Aşağı'),
              tooltip: context.tr('Aşağı'),
              onStep: e.locked ? null : () => _change(() => e.y += 1 / 700),
              icon: const Icon(Icons.arrow_downward),
            ),
          ],
        ),
        _PrecisionMoveButton(
          key: ValueKey('${e.id}-Sağa'),
          tooltip: context.tr('Sağa'),
          onStep: e.locked ? null : () => _change(() => e.x += 1 / 500),
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget _buildAlign() {
    final e = widget.element;
    return Column(
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
  }

  static String _layerLabel(AlbumElementLayerAction action) => switch (action) {
    AlbumElementLayerAction.moveUp => 'Bir üste getir',
    AlbumElementLayerAction.moveDown => 'Bir alta gönder',
    AlbumElementLayerAction.bringToFront => 'En üste getir',
    AlbumElementLayerAction.sendToBack => 'En alta gönder',
  };

  Widget _layerButton() => PopupMenuButton<AlbumElementLayerAction>(
    tooltip: context.tr('Katman sırası'),
    icon: const Icon(Icons.layers_rounded, size: 22),
    enabled: !widget.element.locked,
    onSelected: widget.onLayer,
    itemBuilder: (context) => [
      for (final action in AlbumElementLayerAction.values)
        PopupMenuItem<AlbumElementLayerAction>(
          key: ValueKey('layer-action-${action.name}'),
          value: action,
          enabled: widget.canMoveLayer(action),
          child: Text(context.tr(_layerLabel(action))),
        ),
    ],
  );

  Widget _moreButton(List<String> sections) => PopupMenuButton<String>(
    tooltip: context.tr('Daha fazla'),
    icon: const Icon(Icons.more_horiz_rounded, size: 22),
    enabled: !widget.element.locked,

    onSelected: (value) =>
        setState(() => _section = _section == value ? null : value),

    itemBuilder: (context) => [
      for (final section in sections)
        PopupMenuItem<String>(
          key: ValueKey('section-$section'),
          value: section,
          child: Row(
            children: [
              Icon(
                _section == section
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(context.tr(section)),
            ],
          ),
        ),
    ],
  );

  List<Widget> _tools(AlbumElementModel e, List<String> sections) => [
    if (e.type == AlbumElementType.photo)
      _tool('Kırp', Icons.crop_rounded, widget.onCrop),
    if (e.type == AlbumElementType.sticker &&
        isAlbumShape(e.content) &&
        widget.onFitPhoto != null)
      _tool(
        'Fotoğraf Ekle',
        Icons.add_photo_alternate_outlined,
        widget.onFitPhoto,
      ),
    _tool(
      'Küçült',
      Icons.zoom_out_rounded,
      () => _change(() => scaleAlbumElementBy(e, 1 / albumElementScaleStep)),
    ),
    _tool(
      'Büyüt',
      Icons.zoom_in_rounded,
      () => _change(() => scaleAlbumElementBy(e, albumElementScaleStep)),
    ),
    // One button, one direction: each tap turns the element a further 90°.
    _tool(
      '90° döndür',
      Icons.rotate_right_rounded,
      () => _change(() => e.rotation += math.pi / 2),
    ),
    if (e.type == AlbumElementType.text)
      PopupMenuButton<TextAlign>(
        tooltip: context.tr('Yazı hizalama'),
        icon: const Icon(Icons.format_align_center),
        enabled: !e.locked,
        onSelected: (value) => _change(() => e.textAlign = value),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: TextAlign.left,
            child: Text(context.tr('Sola hizala')),
          ),
          PopupMenuItem(
            value: TextAlign.center,
            child: Text(context.tr('Ortala')),
          ),
          PopupMenuItem(
            value: TextAlign.right,
            child: Text(context.tr('Sağa hizala')),
          ),
        ],
      ),
    _layerButton(),
    // A sticker cut from the user's own photo keeps its file reference in
    // `content`, the same field an ornament id uses. "Düzenle" opens the
    // ornament catalogue, which would overwrite the photo, so it is not
    // offered for one.
    if (!isPersonalStickerElement(e))
      _tool('Düzenle', Icons.tune_rounded, widget.onStyle),
    _tool('Kopyala', Icons.content_copy_rounded, widget.onDuplicate),
    _tool(
      'Sil',
      Icons.delete_outline_rounded,
      widget.onDelete,
      color: Theme.of(context).colorScheme.error,
    ),
    _moreButton(sections),
  ];

  @override
  Widget build(BuildContext context) {
    final e = widget.element;
    final theme = Theme.of(context);
    final type = switch (e.type) {
      AlbumElementType.photo => 'Fotoğraf',
      AlbumElementType.text => 'Yazı',
      AlbumElementType.card => 'Kart',
      AlbumElementType.sticker => 'Şekil / Süs',
      AlbumElementType.drawing => 'Çizim',
    };
    final sections = <String>[
      'Hassas ayar',
      'Hizala',
      if (e.type == AlbumElementType.card) 'Renk',
    ];

    final summary = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            context.tr(type),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '${(e.scale * 100).round()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );

    final lockButton = IconButton(
      tooltip: context.tr(e.locked ? 'Kilidi aç' : 'Sabitle'),
      onPressed: () {
        setState(() => e.locked = !e.locked);
        widget.onChanged();
      },
      icon: Icon(e.locked ? Icons.lock : Icons.lock_open, size: 20),
      visualDensity: VisualDensity.compact,
    );
    final doneButton = IconButton(
      tooltip: context.tr('Bitti'),
      onPressed: widget.onClose,
      icon: const Icon(Icons.check),
      visualDensity: VisualDensity.compact,
    );

    // With a width the icons spread across the row; without one they stay
    // packed. Either way an overlong strip still scrolls instead of clipping.
    Widget strip(List<Widget> children, [double? width]) =>
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: width == null
              ? Row(mainAxisSize: MainAxisSize.min, children: children)
              : ConstrainedBox(
                  constraints: BoxConstraints(minWidth: width),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: children,
                  ),
                ),
        );

    return Material(
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .34,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _wideBreakpoint;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Row(
                        key: const ValueKey('selection-toolbar-wide'),
                        children: [
                          Flexible(flex: 2, child: summary),
                          const SizedBox(width: 12),
                          Flexible(
                            flex: 5,
                            child: strip([
                              ..._tools(e, sections),
                              lockButton,
                              doneButton,
                            ]),
                          ),
                        ],
                      )
                    else
                      Column(
                        key: const ValueKey('selection-toolbar-stacked'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: summary),
                              lockButton,
                              doneButton,
                            ],
                          ),
                          const SizedBox(height: 2),
                          strip(_tools(e, sections), constraints.maxWidth),
                        ],
                      ),
                    if (e.locked)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          context.tr('Nesne sabit. Düzenlemek için kilidi aç.'),
                        ),
                      ),
                    if (_section == 'Hassas ayar') _buildPrecision(),
                    if (_section == 'Hizala') _buildAlign(),
                    if (_section == 'Renk')
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final color in editorCardColors)
                            IconButton(
                              tooltip:
                                  '#${color.toRadixString(16).substring(2)}',
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A tap nudges once; a held press repeats the same small step.
class _PrecisionMoveButton extends StatefulWidget {
  const _PrecisionMoveButton({
    super.key,
    required this.tooltip,
    required this.onStep,
    required this.icon,
  });
  final String tooltip;
  final VoidCallback? onStep;
  final Widget icon;

  @override
  State<_PrecisionMoveButton> createState() => _PrecisionMoveButtonState();
}

class _PrecisionMoveButtonState extends State<_PrecisionMoveButton>
    with WidgetsBindingObserver {
  Timer? _repeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  void _start(LongPressStartDetails _) {
    _stop();
    widget.onStep?.call();
    _repeat = Timer.periodic(const Duration(milliseconds: 40), (_) {
      widget.onStep?.call();
    });
  }

  @override
  void didUpdateWidget(covariant _PrecisionMoveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onStep == null) _stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip,
    // Holding this control moves the element; it must not open a tooltip.
    triggerMode: TooltipTriggerMode.manual,
    child: GestureDetector(
      onLongPressStart: widget.onStep == null ? null : _start,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      onLongPressMoveUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null ||
            !(Offset.zero & box.size).contains(details.localPosition)) {
          _stop();
        }
      },
      child: IconButton.filledTonal(
        onPressed: widget.onStep,
        icon: widget.icon,
      ),
    ),
  );
}
