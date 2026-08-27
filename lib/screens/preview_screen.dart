import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/album_models.dart';
import '../themes/theme_image_helper.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/physical_book_spread.dart';

const _exportLogicalWidth = 270.0;
const _exportLogicalHeight = 480.0;
const _exportVideoWidth = 720;
const _exportVideoHeight = 1280;
const _exportPixelRatio = _exportVideoWidth / _exportLogicalWidth;

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.album});

  final AlbumModel album;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  final _exportBoundary = GlobalKey();
  late final AnimationController _turnController;

  int _current = 0;
  int? _target;
  bool _turningForward = true;
  bool _autoPlay = false;
  bool _exporting = false;
  bool _reduceMotion = false;
  double _dragDistance = 0;
  int _exportSlide = 0;
  double _exportProgress = 0;
  String _exportStatus = '';
  Timer? _timer;

  int get singleSlideCount => widget.album.pages.length + 1;

  /// Cover + inside title spread + the remaining two-page spreads.
  int get previewCount => 2 + widget.album.pages.length ~/ 2;

  @override
  void initState() {
    super.initState();
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 940),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _turnController.dispose();
    super.dispose();
  }

  _BookPosition _positionFor(int previewIndex) {
    if (previewIndex == 0) {
      return const _BookPosition(
        left: PhysicalBookSpread.titlePageIndex,
        right: PhysicalBookSpread.blankPageIndex,
        closed: true,
      );
    }

    final spread = previewIndex - 1;
    if (spread == 0) {
      return _BookPosition(
        left: PhysicalBookSpread.titlePageIndex,
        right: widget.album.pages.isEmpty
            ? PhysicalBookSpread.blankPageIndex
            : 0,
      );
    }

    final left = spread * 2 - 1;
    final right = left + 1;
    return _BookPosition(
      left: left < widget.album.pages.length
          ? left
          : PhysicalBookSpread.blankPageIndex,
      right: right < widget.album.pages.length
          ? right
          : PhysicalBookSpread.blankPageIndex,
    );
  }

  Future<void> _goTo(int target, {bool animate = true}) async {
    if (_target != null || target == _current) return;
    if (target < 0 || target >= previewCount) return;

    if (_reduceMotion || !animate) {
      setState(() => _current = target);
      return;
    }

    setState(() {
      _target = target;
      _turningForward = target > _current;
    });
    HapticFeedback.selectionClick();

    try {
      await _turnController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() {
      _current = target;
      _target = null;
    });
    _turnController.value = 0;
  }

  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    _timer?.cancel();
    if (!_autoPlay) return;

    _timer = Timer.periodic(const Duration(milliseconds: 2750), (_) {
      if (!mounted || !_autoPlay || _target != null) return;
      if (_current == previewCount - 1) {
        _goTo(0, animate: false);
      } else {
        _goTo(_current + 1);
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final wantsNext = _dragDistance < -34 || velocity < -360;
    final wantsPrevious = _dragDistance > 34 || velocity > 360;
    _dragDistance = 0;
    if (wantsNext) {
      _goTo(_current + 1);
    } else if (wantsPrevious) {
      _goTo(_current - 1);
    }
  }

  Future<void> _precacheExportSlideImages(int index) async {
    final sources = <String>[];
    if (index == 0) {
      final coverAsset = themeById(widget.album.themeId).coverAsset;
      if (coverAsset != null) sources.add(coverAsset);
    } else {
      sources.addAll(
        widget.album.pages[index - 1].elements
            .where((element) => element.type == AlbumElementType.photo)
            .map((element) => element.content)
            .where((source) => source.trim().isNotEmpty),
      );
    }

    Object? loadError;
    for (final source in sources.toSet()) {
      await precacheImage(
        themeImageProvider(source),
        context,
        size: const Size(720, 1280),
        onError: (error, stackTrace) => loadError ??= error,
      );
      if (loadError != null) {
        throw StateError('Fotoğraf okunamadı: $source ($loadError)');
      }
    }
  }

  Future<Uint8List> _captureExportSlide(int index) async {
    await _precacheExportSlideImages(index);
    if (!mounted) throw StateError('Dışa aktarma iptal edildi.');
    setState(() => _exportSlide = index);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 24));
    final boundary =
        _exportBoundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) throw StateError('Görüntü karesi üretilemedi.');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Uint8List _pageTurnTransition(
    Uint8List currentFrame,
    Uint8List nextFrame,
    double progress, {
    int width = _exportVideoWidth,
    int height = _exportVideoHeight,
  }) {
    final expectedLength = width * height * 4;
    if (currentFrame.length != expectedLength ||
        nextFrame.length != expectedLength) {
      throw StateError('Video karesi beklenen HD boyutta değil.');
    }
    final output = Uint8List(currentFrame.length);
    final eased = Curves.easeInOutCubic.transform(progress);
    final splitX = (width * (1.0 - eased)).round().clamp(0, width);
    final highlightWidth = math.max(1, (22 * width / 360).round());
    final shadowWidth = math.max(1, (46 * width / 360).round());

    for (var y = 0; y < height; y++) {
      final rowOffset = y * width * 4;
      final splitOffset = rowOffset + splitX * 4;
      final rowEnd = rowOffset + width * 4;
      output.setRange(rowOffset, splitOffset, currentFrame, rowOffset);
      output.setRange(splitOffset, rowEnd, nextFrame, splitOffset);

      for (var x = math.max(0, splitX - highlightWidth); x < splitX; x++) {
        final pixelIndex = rowOffset + x * 4;
        final distance = splitX - x;
        final highlight =
            (math.sin(
                      (highlightWidth - distance) /
                          highlightWidth *
                          math.pi *
                          0.5,
                    ) *
                    36)
                .round();
        output[pixelIndex] = (output[pixelIndex] + highlight).clamp(0, 255);
        output[pixelIndex + 1] = (output[pixelIndex + 1] + highlight).clamp(
          0,
          255,
        );
        output[pixelIndex + 2] = (output[pixelIndex + 2] + highlight).clamp(
          0,
          255,
        );
        output[pixelIndex + 3] = 255;
      }

      for (var x = splitX; x < math.min(width, splitX + shadowWidth); x++) {
        final pixelIndex = rowOffset + x * 4;
        final distance = x - splitX;
        final shadowFactor =
            math.sin((shadowWidth - distance) / shadowWidth * math.pi * 0.5) *
            0.54;
        output[pixelIndex] = (output[pixelIndex] * (1 - shadowFactor)).round();
        output[pixelIndex + 1] = (output[pixelIndex + 1] * (1 - shadowFactor))
            .round();
        output[pixelIndex + 2] = (output[pixelIndex + 2] * (1 - shadowFactor))
            .round();
        output[pixelIndex + 3] = 255;
      }
    }
    return output;
  }

  String _safeFilename(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'albumium_album' : normalized;
  }

  Future<void> _exportAndShare() async {
    if (_exporting) return;
    _timer?.cancel();
    setState(() {
      _autoPlay = false;
      _exporting = true;
      _exportProgress = 0;
      _exportStatus = 'Sayfalar hazırlanıyor…';
    });

    var encoderStarted = false;
    try {
      final count = singleSlideCount;
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}${_safeFilename(widget.album.title)}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
      await FlutterQuickVideoEncoder.setup(
        width: _exportVideoWidth,
        height: _exportVideoHeight,
        fps: 24,
        videoBitrate: 8000000,
        profileLevel: ProfileLevel.baselineAutoLevel,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: path,
      );
      encoderStarted = true;

      const holdFrames = 42; // 1.75 seconds per slide at 24 fps
      const transitionFrames = 16; // ~0.67 seconds per page turn
      final total = count * holdFrames + (count - 1) * transitionFrames;
      var completed = 0;
      var currentFrame = await _captureExportSlide(0);
      for (var index = 0; index < count; index++) {
        Uint8List? nextFrame;
        if (index < count - 1) {
          if (mounted) {
            setState(() => _exportStatus = 'Fotoğraflar HD hazırlanıyor…');
          }
          nextFrame = await _captureExportSlide(index + 1);
        }
        if (mounted) setState(() => _exportStatus = 'HD MP4 oluşturuluyor…');
        for (var frame = 0; frame < holdFrames; frame++) {
          await FlutterQuickVideoEncoder.appendVideoFrame(currentFrame);
          completed++;
          if (mounted && completed % 8 == 0) {
            setState(() => _exportProgress = completed / total * 0.96);
          }
        }
        if (nextFrame != null) {
          for (
            var transition = 1;
            transition <= transitionFrames;
            transition++
          ) {
            final turned = _pageTurnTransition(
              currentFrame,
              nextFrame,
              transition / (transitionFrames + 1),
            );
            await FlutterQuickVideoEncoder.appendVideoFrame(turned);
            completed++;
            if (mounted && completed % 3 == 0) {
              setState(() => _exportProgress = completed / total * 0.96);
            }
          }
          currentFrame = nextFrame;
        }
      }
      await FlutterQuickVideoEncoder.finish();
      encoderStarted = false;
      if (!mounted) return;
      setState(() {
        _exportProgress = 1;
        _exportStatus = 'Hazır!';
      });
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          fileNameOverrides: ['${_safeFilename(widget.album.title)}.mp4'],
          title: widget.album.title,
          subject: '${widget.album.title} · Albumium',
          text: '“${widget.album.title}” albümümü Albumium ile hazırladım.',
        ),
      );
    } catch (error) {
      if (encoderStarted) {
        try {
          await FlutterQuickVideoEncoder.finish();
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Video hazırlanamadı: $error')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _positionLabel() {
    if (_current == 0) return 'Kapak · ${widget.album.bindingType.title}';
    if (_current == 1) {
      return widget.album.pages.isEmpty ? 'İç kapak' : 'İç kapak · Sayfa 1';
    }
    final position = _positionFor(_current);
    final visible = [
      position.left,
      position.right,
    ].where((index) => index >= 0).map((index) => index + 1).toList();
    return visible.length == 1
        ? 'Sayfa ${visible.first}'
        : 'Sayfalar ${visible.first}–${visible.last}';
  }

  Widget _buildBookPreview() {
    final current = _positionFor(_current);
    return AnimatedBuilder(
      animation: _turnController,
      builder: (context, _) {
        final target = _target == null ? null : _positionFor(_target!);
        return PhysicalBookSpread(
          album: widget.album,
          leftPageIndex: current.left,
          rightPageIndex: current.right,
          closed: current.closed,
          nextLeftPageIndex: target?.left,
          nextRightPageIndex: target?.right,
          nextClosed: target?.closed ?? false,
          turnProgress: _turnController.value,
          turningForward: _turningForward,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumTheme = themeById(widget.album.themeId);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Albüm Önizleme'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _toggleAutoPlay,
            tooltip: _autoPlay ? 'Durdur' : 'Otomatik oynat',
            icon: Icon(
              _autoPlay
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.album.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                _positionLabel(),
                                key: ValueKey(_current),
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _exportAndShare,
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('MP4 Paylaş'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.2),
                            radius: 1.08,
                            colors: [
                              albumTheme.coverEnd.withValues(alpha: 0.16),
                              colors.surface,
                              Color.lerp(colors.surface, Colors.black, 0.16)!,
                            ],
                            stops: const [0, 0.64, 1],
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (_) => _dragDistance = 0,
                        onHorizontalDragUpdate: (details) {
                          _dragDistance += details.delta.dx;
                        },
                        onHorizontalDragEnd: _handleDragEnd,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
                          child: _buildBookPreview(),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 0,
                        bottom: 20,
                        child: Center(
                          child: _PageArrow(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Önceki sayfa',
                            enabled: _current > 0 && _target == null,
                            onTap: () => _goTo(_current - 1),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: 0,
                        bottom: 20,
                        child: Center(
                          child: _PageArrow(
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'Sonraki sayfa',
                            enabled:
                                _current < previewCount - 1 && _target == null,
                            onTap: () => _goTo(_current + 1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Center(
                          child: Text(
                            _reduceMotion
                                ? 'Oklarla gez · azaltılmış hareket'
                                : 'Kaydır veya oklarla sayfaları çevir',
                            style: TextStyle(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.68,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < previewCount; index++)
                          Semantics(
                            label: index == 0
                                ? 'Kapak'
                                : 'Kitap görünümü $index',
                            selected: index == _current,
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: _target == null
                                  ? () => _goTo(
                                      index,
                                      animate: (index - _current).abs() == 1,
                                    )
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: index == _current ? 22 : 7,
                                height: 7,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: index == _current
                                      ? albumTheme.accent
                                      : colors.onSurface.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (_exporting)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xED12100F),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RepaintBoundary(
                          key: _exportBoundary,
                          child: _ExportSlide(
                            album: widget.album,
                            index: _exportSlide,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 270,
                          child: LinearProgressIndicator(
                            value: _exportProgress,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _exportStatus,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uygulamayı kapatma',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookPosition {
  const _BookPosition({
    required this.left,
    required this.right,
    this.closed = false,
  });

  final int left;
  final int right;
  final bool closed;
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.2,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.76),
        shape: const CircleBorder(),
        elevation: enabled ? 4 : 0,
        child: IconButton(
          onPressed: enabled ? onTap : null,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _ExportSlide extends StatelessWidget {
  const _ExportSlide({required this.album, required this.index});

  final AlbumModel album;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    return SizedBox(
      width: _exportLogicalWidth,
      height: _exportLogicalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              theme.coverEnd.withValues(alpha: 0.65),
              const Color(0xFF151210),
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 240,
            height: 373.333,
            child: index == 0
                ? AlbumCover(album: album)
                : AlbumPageCanvas(page: album.pages[index - 1], theme: theme),
          ),
        ),
      ),
    );
  }
}
