import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../themes/theme_image_helper.dart';

const fullPhotoCrop = Rect.fromLTWH(0, 0, 1, 1);

/// Uses the same oriented, bounded decode as the canvas and video exporter.
/// The caller owns the returned image reference.
Future<ImageInfo> loadAlbumPhoto(String path) async {
  final stream = themeImageProvider(path).resolve(ImageConfiguration.empty);
  final completer = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) {
        completer.complete(info);
      } else {
        info.dispose();
      }
    },
    onError: (Object error, StackTrace? stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    },
  );
  stream.addListener(listener);
  try {
    return await completer.future;
  } finally {
    stream.removeListener(listener);
  }
}

/// Fits a source aspect into a normalized 5:7 page, without cutting any edges.
Size albumPhotoSize(
  double aspect, {
  double maxWidth = .76,
  double maxHeight = .70,
}) {
  if (!aspect.isFinite || aspect <= 0) aspect = 1;
  final width = math.min(maxWidth, maxHeight * aspect / (5 / 7));
  return Size(width, width * (5 / 7) / aspect);
}

void applyAlbumPhotoCrop(
  AlbumElementModel element,
  Rect crop,
  double sourceAspect,
) {
  final center = Offset(
    element.x + element.width / 2,
    element.y + element.height / 2,
  );
  final size = albumPhotoSize(
    sourceAspect * crop.width / crop.height,
    maxWidth: element.width.clamp(.12, .88),
    maxHeight: .80,
  );
  element.photoCrop = crop;
  element.photoShape = AlbumPhotoShape.free;
  element.width = size.width;
  element.height = size.height;
  element.x = (center.dx - size.width / 2).clamp(0, 1 - size.width);
  element.y = (center.dy - size.height / 2).clamp(0, 1 - size.height);
}

class CroppedAlbumPhoto extends StatefulWidget {
  const CroppedAlbumPhoto({
    super.key,
    required this.path,
    required this.crop,
    this.fit = BoxFit.contain,
    this.frameBuilder,
    this.frameInsets = EdgeInsets.zero,
  });
  final String path;
  final Rect crop;
  final BoxFit fit;
  final Widget Function(Widget photo)? frameBuilder;
  final EdgeInsets frameInsets;

  @override
  State<CroppedAlbumPhoto> createState() => _CroppedAlbumPhotoState();
}

class _CroppedAlbumPhotoState extends State<CroppedAlbumPhoto> {
  ImageInfo? _info;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CroppedAlbumPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    _info?.dispose();
    _info = null;
    _failed = false;
    try {
      final info = await loadAlbumPhoto(widget.path);
      if (!mounted || request != _request) {
        info.dispose();
        return;
      }
      setState(() => _info = info);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Icon(Icons.broken_image_outlined));
    final photo = CustomPaint(
      key: const ValueKey('cropped-photo-pixels'),
      painter: _CroppedPhotoPainter(_info?.image, widget.crop, widget.fit),
      size: Size.infinite,
    );
    final frameBuilder = widget.frameBuilder;
    if (frameBuilder == null) return photo;
    final source = _info?.image;
    if (source == null) return const SizedBox.shrink();

    // Fit the photo AND its frame as a unit. Fitting only the image inside a
    // separately stretched frame causes letterboxing when page aspect ratios
    // differ or a decorative frame consumes asymmetric padding.
    final aspect =
        source.width * widget.crop.width / (source.height * widget.crop.height);
    const imageWidth = 240.0;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        key: const ValueKey('cropped-photo-frame'),
        width: imageWidth + widget.frameInsets.horizontal,
        height: imageWidth / aspect + widget.frameInsets.vertical,
        child: frameBuilder(photo),
      ),
    );
  }
}

class _CroppedPhotoPainter extends CustomPainter {
  const _CroppedPhotoPainter(this.image, this.crop, this.fit);
  final ui.Image? image;
  final Rect crop;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    final source = image;
    if (source == null || size.isEmpty) return;
    final region = Rect.fromLTRB(
      crop.left * source.width,
      crop.top * source.height,
      crop.right * source.width,
      crop.bottom * source.height,
    );
    final fitted = applyBoxFit(fit, region.size, size);
    canvas.drawImageRect(
      source,
      Alignment.center.inscribe(fitted.source, region),
      Alignment.center.inscribe(fitted.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_CroppedPhotoPainter oldDelegate) =>
      image != oldDelegate.image ||
      crop != oldDelegate.crop ||
      fit != oldDelegate.fit;
}

Future<bool> editAlbumPhotoCrop(
  BuildContext context,
  AlbumElementModel element,
) async {
  ImageInfo? info;
  try {
    info = await loadAlbumPhoto(element.content);
    if (!context.mounted) return false;
    final crop = await Navigator.of(context).push<Rect>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoCropEditor(
          image: info!.image,
          initialCrop: element.photoCrop ?? fullPhotoCrop,
        ),
      ),
    );
    if (crop == null || !context.mounted) return false;
    applyAlbumPhotoCrop(element, crop, info.image.width / info.image.height);
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Fotoğraf açılamadı. Lütfen tekrar dene.')),
        ),
      );
    }
    return false;
  } finally {
    info?.dispose();
  }
}

class PhotoCropEditor extends StatefulWidget {
  const PhotoCropEditor({
    super.key,
    required this.image,
    required this.initialCrop,
  });
  final ui.Image image;
  final Rect initialCrop;

  @override
  State<PhotoCropEditor> createState() => _PhotoCropEditorState();
}

class _PhotoCropEditorState extends State<PhotoCropEditor> {
  late final ui.Image _image;
  late Rect _crop = widget.initialCrop;
  Rect? _startCrop;
  Offset _startPoint = Offset.zero;
  int? _corner;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    // Keep our own reference through the route's exit animation.
    _image = widget.image.clone();
  }

  @override
  void dispose() {
    _image.dispose();
    super.dispose();
  }

  void _start(DragStartDetails details, Size size) {
    final point = details.localPosition;
    final rect = Rect.fromLTRB(
      _crop.left * size.width,
      _crop.top * size.height,
      _crop.right * size.width,
      _crop.bottom * size.height,
    );
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    _corner = null;
    for (var i = 0; i < corners.length; i++) {
      if ((point - corners[i]).distance <= 40) {
        _corner = i;
        break;
      }
    }
    _moving = _corner == null && rect.contains(point);
    _startPoint = point;
    _startCrop = _crop;
  }

  void _update(DragUpdateDetails details, Size size) {
    final start = _startCrop;
    if (start == null || (_corner == null && !_moving)) return;
    final delta = details.localPosition - _startPoint;
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    setState(() {
      if (_moving) {
        _crop = start.shift(
          Offset(
            dx.clamp(-start.left, 1 - start.right),
            dy.clamp(-start.top, 1 - start.bottom),
          ),
        );
      } else {
        final left = _corner == 0 || _corner == 3;
        final top = _corner == 0 || _corner == 1;
        _crop = Rect.fromLTRB(
          left ? (start.left + dx).clamp(0, start.right - .05) : start.left,
          top ? (start.top + dy).clamp(0, start.bottom - .05) : start.top,
          left ? start.right : (start.right + dx).clamp(start.left + .05, 1),
          top ? start.bottom : (start.bottom + dy).clamp(start.top + .05, 1),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Fotoğrafı kırp'))),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr(
                'Köşeleri sürükleyerek kırp. Seçili alanı taşıyarak konumunu ayarla.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _image.width / _image.height,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      return GestureDetector(
                        key: const ValueKey('photo-crop-surface'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) => _start(details, size),
                        onPanUpdate: (details) => _update(details, size),
                        child: CustomPaint(
                          foregroundPainter: _CropOverlay(_crop),
                          child: RawImage(image: _image, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('photo-crop-reset'),
                  onPressed: () => setState(() => _crop = fullPhotoCrop),
                  icon: const Icon(Icons.crop_original),
                  label: Text(context.tr('Tamamını göster')),
                ),
                FilledButton.icon(
                  key: const ValueKey('photo-crop-apply'),
                  onPressed: () => Navigator.pop(context, _crop),
                  icon: const Icon(Icons.check),
                  label: Text(context.tr('Uygula')),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CropOverlay extends CustomPainter {
  const _CropOverlay(this.crop);
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(rect),
      Paint()..color = Colors.black54,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final grid = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(rect.left + rect.width * i / 3, rect.top),
        Offset(rect.left + rect.width * i / 3, rect.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top + rect.height * i / 3),
        Offset(rect.right, rect.top + rect.height * i / 3),
        grid,
      );
    }
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(corner, 7, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CropOverlay oldDelegate) => crop != oldDelegate.crop;
}
