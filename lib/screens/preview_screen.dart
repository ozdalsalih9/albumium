import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/album_models.dart';
import '../themes/theme_image_helper.dart';
import '../widgets/physical_book_spread.dart';
import '../widgets/sticker_packs.dart';

const _exportLogicalWidth = 360.0;
const _exportLogicalHeight = 640.0;
const _exportVideoWidth = 1080;
const _exportVideoHeight = 1920;
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
  bool _draggingPage = false;
  double _dragDistance = 0;
  double _dragExtent = 1;
  int _exportFrom = 0;
  int? _exportTo;
  double _exportTurnProgress = 0;
  bool _exportTurningForward = true;
  final Set<int> _preloadedExportPositions = <int>{};
  double _exportProgress = 0;
  String _exportStatus = '';
  Timer? _timer;

  /// Cover + inside title spread + the remaining two-page spreads.
  int get previewCount => 2 + widget.album.pages.length ~/ 2;

  @override
  void initState() {
    super.initState();
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 940),
    );
    // Immersive-reader dalındaki en değerli parçalardan biri: önizleme ekranı
    // albümü yatay tutunca gerçek iki sayfalı bir kitap gibi kullanılabilir.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
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
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
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

  void _handleDragStart(DragStartDetails details) {
    if (_target != null) return;
    _draggingPage = true;
    _dragDistance = 0;
    _dragExtent = math.max(180, context.size?.width ?? 1) * 0.72;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_draggingPage) return;
    _dragDistance += details.delta.dx;
    if (_reduceMotion) return;

    if (_target == null) {
      if (_dragDistance.abs() < 3) return;
      final forward = _dragDistance < 0;
      final candidate = _current + (forward ? 1 : -1);
      if (candidate < 0 || candidate >= previewCount) return;
      setState(() {
        _target = candidate;
        _turningForward = forward;
      });
      HapticFeedback.selectionClick();
    }

    final directedDistance = _turningForward ? -_dragDistance : _dragDistance;
    _turnController.value = (directedDistance / _dragExtent).clamp(0.0, 0.985);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_draggingPage) return;
    _draggingPage = false;

    final velocity = details.primaryVelocity ?? 0;
    if (_reduceMotion) {
      final wantsNext = _dragDistance < -34 || velocity < -360;
      final wantsPrevious = _dragDistance > 34 || velocity > 360;
      _dragDistance = 0;
      if (wantsNext) {
        _goTo(_current + 1);
      } else if (wantsPrevious) {
        _goTo(_current - 1);
      }
      return;
    }

    if (_target == null) {
      _dragDistance = 0;
      return;
    }

    final directedVelocity = _turningForward ? -velocity : velocity;
    final complete = _turnController.value > 0.34 || directedVelocity > 360;
    _dragDistance = 0;
    unawaited(_settleDraggedPage(complete: complete));
  }

  void _handleDragCancel() {
    if (!_draggingPage) return;
    _draggingPage = false;
    _dragDistance = 0;
    if (_target != null) unawaited(_settleDraggedPage(complete: false));
  }

  Future<void> _settleDraggedPage({required bool complete}) async {
    final target = _target;
    if (target == null) return;
    try {
      if (complete) {
        await _turnController
            .animateTo(
              1,
              duration: Duration(
                milliseconds: math.max(
                  170,
                  (520 * (1 - _turnController.value)).round(),
                ),
              ),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } else {
        await _turnController
            .animateBack(
              0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      }
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() {
      if (complete) _current = target;
      _target = null;
    });
    _turnController.value = 0;
  }

  void _handleBookTap(TapUpDetails details, BoxConstraints constraints) {
    if (_target != null || constraints.maxWidth <= 0) return;
    final position = details.localPosition.dx / constraints.maxWidth;
    if (position <= 0.28) {
      _goTo(_current - 1);
    } else if (position >= 0.72) {
      _goTo(_current + 1);
    }
  }

  Future<void> _precacheExportPositionImages(int previewIndex) async {
    if (!_preloadedExportPositions.add(previewIndex)) return;
    final sources = <String>[];
    final position = _positionFor(previewIndex);
    if (position.closed) {
      final coverAsset = themeById(widget.album.themeId).coverAsset;
      if (coverAsset != null) sources.add(coverAsset);
    }

    for (final pageIndex in {position.left, position.right}) {
      if (pageIndex < 0 || pageIndex >= widget.album.pages.length) continue;
      for (final element in widget.album.pages[pageIndex].elements) {
        if (element.type == AlbumElementType.photo &&
            element.content.trim().isNotEmpty) {
          sources.add(element.content);
        } else if (element.type == AlbumElementType.sticker &&
            isAlbumStickerAsset(element.content)) {
          sources.add(albumStickerAssetPath(element.content));
        }
      }
    }

    Object? loadError;
    for (final source in sources.toSet()) {
      await precacheImage(
        themeImageProvider(source),
        context,
        size: const Size(1080, 1920),
        onError: (error, stackTrace) => loadError ??= error,
      );
      if (loadError != null) {
        throw StateError('Fotoğraf okunamadı: $source ($loadError)');
      }
    }
  }

  Future<Uint8List> _captureExportBookFrame({
    required int from,
    int? to,
    double progress = 0,
  }) async {
    await _precacheExportPositionImages(from);
    if (to != null) await _precacheExportPositionImages(to);
    if (!mounted) throw StateError('Dışa aktarma iptal edildi.');
    setState(() {
      _exportFrom = from;
      _exportTo = to;
      _exportTurnProgress = progress.clamp(0.0, 1.0);
      _exportTurningForward = to == null || to > from;
    });

    // Build once to start every Google Font and asset decode, wait for those
    // futures, then paint two stable frames. Capturing after only one frame was
    // the source of intermittent fallback-font metrics and missing photos.
    await WidgetsBinding.instance.endOfFrame;
    await GoogleFonts.pendingFonts();
    await Future<void>.delayed(const Duration(milliseconds: 18));
    await WidgetsBinding.instance.endOfFrame;
    final renderObject = _exportBoundary.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Video sahnesi hazırlanamadı.');
    }
    final boundary = renderObject;
    final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) throw StateError('Görüntü karesi üretilemedi.');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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
    _preloadedExportPositions.clear();

    var encoderStarted = false;
    try {
      final count = previewCount;
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}${_safeFilename(widget.album.title)}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
      await FlutterQuickVideoEncoder.setup(
        width: _exportVideoWidth,
        height: _exportVideoHeight,
        fps: 24,
        videoBitrate: 14000000,
        profileLevel: ProfileLevel.baselineAutoLevel,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: path,
      );
      encoderStarted = true;

      const holdFrames = 38; // ~1.6 seconds per physical spread at 24 fps
      const transitionFrames = 22; // same ~0.92 s cadence as live preview
      final total = count * holdFrames + (count - 1) * transitionFrames;
      var completed = 0;
      var currentFrame = await _captureExportBookFrame(from: 0);
      for (var index = 0; index < count; index++) {
        if (mounted) setState(() => _exportStatus = 'HD MP4 oluşturuluyor…');
        for (var frame = 0; frame < holdFrames; frame++) {
          await FlutterQuickVideoEncoder.appendVideoFrame(currentFrame);
          completed++;
          if (mounted && completed % 8 == 0) {
            setState(() => _exportProgress = completed / total * 0.96);
          }
        }
        if (index < count - 1) {
          if (mounted) {
            setState(
              () => _exportStatus = 'Gerçekçi sayfa hareketi işleniyor…',
            );
          }
          for (
            var transition = 1;
            transition <= transitionFrames;
            transition++
          ) {
            final turned = await _captureExportBookFrame(
              from: index,
              to: index + 1,
              progress: transition / transitionFrames,
            );
            await FlutterQuickVideoEncoder.appendVideoFrame(turned);
            completed++;
            if (mounted && completed % 3 == 0) {
              setState(() => _exportProgress = completed / total * 0.96);
            }
          }
          currentFrame = await _captureExportBookFrame(from: index + 1);
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
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh.withValues(
                        alpha: 0.82,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: albumTheme.accent.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: albumTheme.coverEnd.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: albumTheme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              size: 20,
                              color: albumTheme.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.album.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.18),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  _positionLabel(),
                                  key: ValueKey(_current),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _exportAndShare,
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('MP4'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ],
                    ),
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
                      LayoutBuilder(
                        builder: (context, bookConstraints) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) =>
                              _handleBookTap(details, bookConstraints),
                          onHorizontalDragStart: _handleDragStart,
                          onHorizontalDragUpdate: _handleDragUpdate,
                          onHorizontalDragEnd: _handleDragEnd,
                          onHorizontalDragCancel: _handleDragCancel,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
                            child: _buildBookPreview(),
                          ),
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
                if (previewCount > 12)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 12, 36, 14),
                    child: Semantics(
                      label: 'Albüm ilerlemesi ${_current + 1} / $previewCount',
                      child: LinearProgressIndicator(
                        value: previewCount <= 1
                            ? 1
                            : _current / (previewCount - 1),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(99),
                        color: albumTheme.accent,
                      ),
                    ),
                  )
                else
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
                                        : colors.onSurface.withValues(
                                            alpha: 0.2,
                                          ),
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
                        SizedBox(
                          width: 216,
                          height: 384,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: RepaintBoundary(
                              key: _exportBoundary,
                              child: _ExportBookFrame(
                                album: widget.album,
                                current: _positionFor(_exportFrom),
                                target: _exportTo == null
                                    ? null
                                    : _positionFor(_exportTo!),
                                turnProgress: _exportTurnProgress,
                                turningForward: _exportTurningForward,
                                position: _exportFrom,
                                positionCount: previewCount,
                              ),
                            ),
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

class _ExportBookFrame extends StatelessWidget {
  const _ExportBookFrame({
    required this.album,
    required this.current,
    required this.target,
    required this.turnProgress,
    required this.turningForward,
    required this.position,
    required this.positionCount,
  });

  final AlbumModel album;
  final _BookPosition current;
  final _BookPosition? target;
  final double turnProgress;
  final bool turningForward;
  final int position;
  final int positionCount;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    return SizedBox(
      width: _exportLogicalWidth,
      height: _exportLogicalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.12),
            radius: 1.08,
            colors: [
              Color.lerp(theme.coverStart, Colors.white, 0.18)!,
              Color.lerp(theme.coverEnd, const Color(0xFF171311), 0.46)!,
              const Color(0xFF100E0D),
            ],
            stops: const [0, 0.62, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 28,
              right: 28,
              top: 34,
              child: Column(
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    current.closed
                        ? 'ALBÜM KAPAĞI'
                        : 'ANILAR · ${position + 1} / $positionCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 116,
              bottom: 96,
              child: PhysicalBookSpread(
                album: album,
                leftPageIndex: current.left,
                rightPageIndex: current.right,
                closed: current.closed,
                nextLeftPageIndex: target?.left,
                nextRightPageIndex: target?.right,
                nextClosed: target?.closed ?? false,
                turnProgress: turnProgress,
                turningForward: turningForward,
              ),
            ),
            Positioned(
              left: 76,
              right: 76,
              bottom: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 15,
                      color: theme.accent,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
