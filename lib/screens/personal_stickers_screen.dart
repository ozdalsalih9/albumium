import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../services/photo_selection_service.dart';
import '../services/personal_sticker_storage.dart';
import '../services/reminder_service.dart';

class PersonalStickersScreen extends StatefulWidget {
  const PersonalStickersScreen({super.key});
  @override
  State<PersonalStickersScreen> createState() => _PersonalStickersScreenState();
}

class _PersonalStickersScreenState extends State<PersonalStickersScreen> {
  List<PersonalSticker> _stickers = [];
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await PersonalStickerStorage.load();
      if (mounted) setState(() => _stickers = list);
    } catch (_) {
      _error();
    }
  }

  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('İşlem tamamlanamadı. Tekrar dene.')),
        ),
      );
    }
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final photos = await PhotoSelectionService.pick(
        context,
        preserveTransparency: true,
      );
      if (photos.isEmpty || !mounted) return;
      final content = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => StickerCutoutScreen(path: photos.first.path),
        ),
      );
      if (content != null && mounted) Navigator.pop(context, content);
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(PersonalSticker sticker, String action) async {
    final input = TextEditingController(text: sticker.name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr(
            action == 'delete'
                ? 'Stickerı kütüphaneden kaldır?'
                : 'Sticker adı',
          ),
        ),
        content: action == 'delete'
            ? Text(context.tr('Mevcut tasarımların korunur.'))
            : TextField(controller: input, maxLength: 60),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: Text(context.tr(action == 'delete' ? 'Sil' : 'Kaydet')),
          ),
        ],
      ),
    );
    input.dispose();
    if (value == null || value.isEmpty) return;
    try {
      if (action == 'delete') {
        await PersonalStickerStorage.delete(sticker.id);
      } else {
        await PersonalStickerStorage.rename(sticker, value);
      }
      await _load();
    } catch (_) {
      _error();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Stickerlarım'))),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(context.tr('Fotoğraftan oluştur')),
          ),
        ),
        Expanded(
          child: _stickers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.tr(
                        'Şeffaf PNG yükle veya fotoğrafından kendi stickerını kes.',
                      ),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 210,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _stickers.length,
                  itemBuilder: (context, i) {
                    final s = _stickers[i];
                    return Card(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, s.content),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.file(
                                  File(personalStickerPath(s.content)),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                            ListTile(
                              title: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) => _action(s, v),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text(context.tr('Yeniden adlandır')),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(context.tr('Sil')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

class StickerStroke {
  StickerStroke(this.restore, this.width, Offset first) : points = [first];
  final bool restore;
  final double width;
  final List<Offset> points;
}

class StickerCutoutPainter extends CustomPainter {
  StickerCutoutPainter(
    this.original,
    this.mask,
    this.strokes, {
    this.checker = true,
    this.border = false,
  });
  final ui.Image original, mask;
  final List<StickerStroke> strokes;
  final bool checker, border;
  void _subject(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    canvas.drawImageRect(
      original,
      Rect.fromLTWH(
        0,
        0,
        original.width.toDouble(),
        original.height.toDouble(),
      ),
      rect,
      Paint(),
    );
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.dstIn);
    if (identical(mask, original)) {
      // A transparent PNG already carries alpha in the source image. Applying
      // that alpha again would darken its antialiased edges.
      canvas.drawRect(rect, Paint()..color = Colors.white);
    } else {
      canvas.drawImageRect(
        mask,
        Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
        rect,
        Paint(),
      );
    }
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Colors.white
        ..blendMode = stroke.restore ? BlendMode.srcOver : BlendMode.clear
        ..strokeWidth = stroke.width * size.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(
          stroke.points.first.dx * size.width,
          stroke.points.first.dy * size.height,
        );
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(
            stroke.points.first.dx * size.width,
            stroke.points.first.dy * size.height,
          ),
          paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (checker) {
      for (double x = 0; x < size.width; x += 16) {
        for (double y = 0; y < size.height; y += 16) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, 16, 16),
            Paint()
              ..color = ((x / 16 + y / 16).toInt().isEven
                  ? const Color(0xFFE8E5E2)
                  : Colors.white),
          );
        }
      }
    }
    if (border) {
      for (final offset in [
        const Offset(-3, 0),
        const Offset(3, 0),
        const Offset(0, -3),
        const Offset(0, 3),
        const Offset(-2, -2),
        const Offset(2, 2),
        const Offset(-2, 2),
        const Offset(2, -2),
      ]) {
        canvas.save();
        canvas.translate(
          offset.dx * size.width / 500,
          offset.dy * size.width / 500,
        );
        canvas.saveLayer(
          Offset.zero & size,
          Paint()
            ..colorFilter = const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
        );
        _subject(canvas, size);
        canvas.restore();
        canvas.restore();
      }
    }
    _subject(canvas, size);
  }

  @override
  bool shouldRepaint(StickerCutoutPainter old) => true;
}

class StickerCutoutScreen extends StatefulWidget {
  const StickerCutoutScreen({super.key, required this.path});
  final String path;
  @override
  State<StickerCutoutScreen> createState() => _StickerCutoutScreenState();
}

class _StickerCutoutScreenState extends State<StickerCutoutScreen> {
  ui.Image? _original, _mask;
  final _strokes = <StickerStroke>[];
  final _name = TextEditingController();
  bool _busy = true, _restore = false, _navigate = false, _border = false;
  double _brush = .04;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<ui.Image> _decode(String path) async {
    final bytes = await File(path).readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale =
        1400 /
        (descriptor.width > descriptor.height
            ? descriptor.width
            : descriptor.height);
    final codec = await descriptor.instantiateCodec(
      targetWidth: scale < 1
          ? (descriptor.width * scale).round()
          : descriptor.width,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  Future<void> _load() async {
    try {
      final image = await _decode(widget.path);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _original = image;
        _mask = image;
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Fotoğraf açılamadı. Lütfen tekrar dene.';
        });
      }
    }
  }

  Future<void> _automatic() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    String? output;
    try {
      // Send the bounded, oriented source to the native model.
      final data = await _original!.toByteData(format: ui.ImageByteFormat.png);
      final source = File(
        '${Directory.systemTemp.path}/segment_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await source.writeAsBytes(data!.buffer.asUint8List());
      try {
        output = await ReminderService.channel.invokeMethod<String>('segment', {
          'path': source.path,
        });
      } finally {
        if (await source.exists()) await source.delete();
      }
      if (output == null) throw StateError('No mask');
      final mask = await _decode(output);
      final rgba = await mask.toByteData();
      var foreground = false;
      for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
        if (rgba.getUint8(i) > 0) {
          foreground = true;
          break;
        }
      }
      if (!foreground) {
        mask.dispose();
        throw StateError('No foreground');
      }
      if (!mounted) {
        mask.dispose();
        return;
      }
      setState(() {
        if (_mask != _original) _mask?.dispose();
        _mask = mask;
        _strokes.clear();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Otomatik kesme hazır değil. Model için internet bağlantını kontrol edip tekrar dene veya elle kes.',
        );
      }
    } finally {
      if (output != null) {
        final file = File(output);
        if (await file.exists()) await file.delete();
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final source = _original!;
      final recorder = ui.PictureRecorder();
      StickerCutoutPainter(
        source,
        _mask!,
        _strokes,
        checker: false,
        border: _border,
      ).paint(
        Canvas(recorder),
        Size(source.width.toDouble(), source.height.toDouble()),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(source.width, source.height);
      picture.dispose();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted) return;
      final sticker = await PersonalStickerStorage.save(
        Uint8List.sublistView(bytes!),
        source.width / source.height,
        _name.text.trim().isEmpty ? context.tr('Stickerım') : _name.text.trim(),
      );
      if (mounted) Navigator.pop(context, sticker.content);
    } catch (_) {
      if (mounted) setState(() => _error = 'Kaydedilemedi. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    if (_mask != _original) _mask?.dispose();
    _original?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('Sticker oluştur'))),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(context.tr(_error!)),
            ),
          Expanded(
            child: _original == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, box) => Center(
                      child: AspectRatio(
                        aspectRatio: _original!.width / _original!.height,
                        child: InteractiveViewer(
                          panEnabled: _navigate,
                          scaleEnabled: _navigate,
                          maxScale: 5,
                          child: LayoutBuilder(
                            builder: (context, constraints) => GestureDetector(
                              onPanStart: _busy || _navigate
                                  ? null
                                  : (event) => setState(
                                      () => _strokes.add(
                                        StickerStroke(
                                          _restore,
                                          _brush,
                                          Offset(
                                            event.localPosition.dx /
                                                constraints.maxWidth,
                                            event.localPosition.dy /
                                                constraints.maxHeight,
                                          ),
                                        ),
                                      ),
                                    ),
                              onPanUpdate: _busy || _navigate
                                  ? null
                                  : (event) => setState(
                                      () => _strokes.last.points.add(
                                        Offset(
                                          event.localPosition.dx /
                                              constraints.maxWidth,
                                          event.localPosition.dy /
                                              constraints.maxHeight,
                                        ),
                                      ),
                                    ),
                              child: CustomPaint(
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                painter: StickerCutoutPainter(
                                  _original!,
                                  _mask!,
                                  _strokes,
                                  border: _border,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Flexible(
            flex: 0,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .45,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              label: Text(context.tr('Otomatik kes')),
                              onPressed: _busy || _original == null
                                  ? null
                                  : _automatic,
                            ),
                            ChoiceChip(
                              label: Text(context.tr('Silgi')),
                              selected: !_restore && !_navigate,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _restore = false;
                                      _navigate = false;
                                    }),
                            ),
                            ChoiceChip(
                              label: Text(context.tr('Geri kazandır')),
                              selected: _restore && !_navigate,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _restore = true;
                                      _navigate = false;
                                    }),
                            ),
                            ChoiceChip(
                              label: Text(context.tr('Yakınlaştır')),
                              selected: _navigate,
                              onSelected: _busy
                                  ? null
                                  : (v) => setState(() => _navigate = v),
                            ),
                            ActionChip(
                              label: Text(context.tr('Geri al')),
                              onPressed: _busy || _strokes.isEmpty
                                  ? null
                                  : () => setState(() => _strokes.removeLast()),
                            ),
                            FilterChip(
                              label: Text(context.tr('Beyaz kenarlık')),
                              selected: _border,
                              onSelected: _busy
                                  ? null
                                  : (v) => setState(() => _border = v),
                            ),
                          ],
                        ),
                        Slider(
                          value: _brush,
                          min: .01,
                          max: .15,
                          label: context.tr('Fırça boyutu'),
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _brush = v),
                        ),
                        TextField(
                          controller: _name,
                          enabled: !_busy,
                          maxLength: 60,
                          decoration: InputDecoration(
                            labelText: context.tr('Sticker adı'),
                          ),
                        ),
                        FilledButton(
                          onPressed: _busy || _original == null ? null : _save,
                          child: Text(context.tr('Kaydet')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
