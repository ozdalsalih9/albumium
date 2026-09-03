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

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../models/cinematic_storyboard.dart';
import '../models/single_page_export_storyboard.dart';
import '../services/album_package_service.dart';
import '../services/cinematic_soundtrack.dart';
import '../services/video_export_support.dart';
import '../theme/albumium_app_theme.dart';
import '../themes/theme_image_helper.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/physical_book_spread.dart';
import '../widgets/sticker_packs.dart';

const _exportLogicalWidth = 360.0;
const _exportLogicalHeight = 640.0;
const _exportVideoWidth = 1080;
const _exportVideoHeight = 1920;
const _exportPixelRatio = _exportVideoWidth / _exportLogicalWidth;

enum _ShareExportChoice { interactiveAlbum, currentPng, allPng, mp4 }

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
  double _turnGrabY = 0.64;
  int _exportFrom = 0;
  int? _exportTo;
  double _exportTurnProgress = 0;
  bool _exportTurningForward = true;
  CinematicBeatKind? _exportBeatKind;
  CinematicTransitionStyle _exportTransitionStyle =
      CinematicTransitionStyle.pageCurl;
  double _exportBeatProgress = 0;
  int _exportShotVariant = 0;
  int _exportFilmFrame = 0;
  final Set<int> _preloadedExportPositions = <int>{};
  final Set<int> _preloadedExportPageSpreads = <int>{};
  bool _exportingSinglePageVideo = false;
  int _exportFocusedPage = 0;
  int? _exportTargetFocusedPage;
  SinglePageExportBeatKind _exportSinglePageBeatKind =
      SinglePageExportBeatKind.hold;
  double _exportSinglePageProgress = 0;
  double _exportProgress = 0;
  String _exportStatus = '';
  String _exportProgressDetails = '';
  bool _exportCanCancel = false;
  bool _exportCancellationRequested = false;
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
      _turnGrabY = 0.64;
    });
    HapticFeedback.selectionClick();

    try {
      await _turnController
          .animateTo(
            1,
            duration: _turnController.duration,
            curve: Curves.easeInOutCubic,
          )
          .orCancel;
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

  void _handleDragStart(DragStartDetails details, BoxConstraints constraints) {
    if (_target != null) return;
    _draggingPage = true;
    _dragDistance = 0;
    _dragExtent = math.max(180, constraints.maxWidth) * 0.62;
    _turnGrabY = constraints.maxHeight <= 0
        ? 0.64
        : (details.localPosition.dy / constraints.maxHeight).clamp(0.14, 0.86);
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
    _turnController.value = (directedDistance / _dragExtent).clamp(0.0, 1.0);
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
    final localizations =
        AlbumiumLocalizations.maybeOf(context) ??
        const AlbumiumLocalizations(Locale('tr'));
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
        throw StateError(
          localizations.text(
            'Fotoğraf okunamadı: {source} ({error})',
            values: {'source': source, 'error': loadError!},
          ),
        );
      }
    }
  }

  Future<void> _precacheSinglePageSpreadImages(int pageIndex) async {
    final localizations =
        AlbumiumLocalizations.maybeOf(context) ??
        const AlbumiumLocalizations(Locale('tr'));
    if (pageIndex < 0 || pageIndex >= widget.album.pages.length) return;
    final spreadLeft = pageIndex.isEven ? pageIndex : pageIndex - 1;
    if (!_preloadedExportPageSpreads.add(spreadLeft)) return;

    final sources = <String>[];
    for (final index in {spreadLeft, spreadLeft + 1}) {
      if (index < 0 || index >= widget.album.pages.length) continue;
      for (final element in widget.album.pages[index].elements) {
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
        throw StateError(
          localizations.text(
            'Fotoğraf okunamadı: {source} ({error})',
            values: {'source': source, 'error': loadError!},
          ),
        );
      }
    }
  }

  Future<Uint8List> _captureSinglePageVideoFrame({
    required SinglePageExportBeat beat,
    required double progress,
    required bool settleAssets,
  }) async {
    final localizations =
        AlbumiumLocalizations.maybeOf(context) ??
        const AlbumiumLocalizations(Locale('tr'));
    _throwIfExportCancelled();
    await _precacheSinglePageSpreadImages(beat.fromPage);
    final targetPage = beat.toPage;
    if (targetPage != null) {
      await _precacheSinglePageSpreadImages(targetPage);
    }
    _throwIfExportCancelled();

    setState(() {
      _exportingSinglePageVideo = true;
      _exportFocusedPage = beat.fromPage;
      _exportTargetFocusedPage = targetPage;
      _exportSinglePageBeatKind = beat.kind;
      _exportSinglePageProgress = progress.clamp(0.0, 1.0);
    });

    await WidgetsBinding.instance.endOfFrame;
    _throwIfExportCancelled();
    if (settleAssets) {
      await GoogleFonts.pendingFonts();
      await Future<void>.delayed(const Duration(milliseconds: 18));
      await WidgetsBinding.instance.endOfFrame;
      _throwIfExportCancelled();
    }

    final renderObject = _exportBoundary.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        localizations.text('Tek sayfa dışa aktarma sahnesi hazırlanamadı.'),
      );
    }
    final image = await renderObject.toImage(pixelRatio: _exportPixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) {
      throw StateError(localizations.text('Görüntü karesi üretilemedi.'));
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uint8List> _captureExportBookFrame({
    required int from,
    int? to,
    double progress = 0,
    CinematicBeatKind? beatKind,
    CinematicTransitionStyle transitionStyle =
        CinematicTransitionStyle.pageCurl,
    double beatProgress = 0,
    int shotVariant = 0,
    int filmFrame = 0,
    bool settleAssets = false,
    ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba,
  }) async {
    final localizations =
        AlbumiumLocalizations.maybeOf(context) ??
        const AlbumiumLocalizations(Locale('tr'));
    _throwIfExportCancelled();
    await _precacheExportPositionImages(from);
    if (to != null) await _precacheExportPositionImages(to);
    _throwIfExportCancelled();
    setState(() {
      _exportFrom = from;
      _exportTo = to;
      _exportTurnProgress = progress.clamp(0.0, 1.0);
      _exportTurningForward = to == null || to > from;
      _exportBeatKind = beatKind;
      _exportTransitionStyle = transitionStyle;
      _exportBeatProgress = beatProgress.clamp(0.0, 1.0);
      _exportShotVariant = shotVariant;
      _exportFilmFrame = filmFrame;
    });

    await WidgetsBinding.instance.endOfFrame;
    _throwIfExportCancelled();
    if (settleAssets) {
      // The first capture starts every font and asset decode. Later cinematic
      // frames only need one paint boundary, otherwise hundreds of identical
      // font waits turn a short movie into a very slow export.
      await GoogleFonts.pendingFonts();
      await Future<void>.delayed(const Duration(milliseconds: 18));
      await WidgetsBinding.instance.endOfFrame;
      _throwIfExportCancelled();
    }
    final renderObject = _exportBoundary.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        localizations.text('Dışa aktarma sahnesi hazırlanamadı.'),
      );
    }
    final boundary = renderObject;
    final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
    final data = await image.toByteData(format: format);
    image.dispose();
    if (data == null) {
      throw StateError(localizations.text('Görüntü karesi üretilemedi.'));
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  void _requestExportCancellation() {
    if (!_exporting || !_exportCanCancel || _exportCancellationRequested) {
      return;
    }
    setState(() {
      _exportCancellationRequested = true;
      _exportStatus = context.tr('İptal ediliyor…');
    });
  }

  void _throwIfExportCancelled() {
    if (_exportCancellationRequested || !mounted) {
      throw const _VideoExportCancelled();
    }
  }

  Future<void> _showShareOptions() async {
    if (_exporting || _target != null) return;
    _timer?.cancel();
    if (_autoPlay && mounted) setState(() => _autoPlay = false);

    final choice = await showModalBottomSheet<_ShareExportChoice>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheetContext.tr('Dışa Aktar & Paylaş'),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              sheetContext.tr(
                'Her seçenek cihazında hazırlanır; internet gerekmez.',
              ),
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const ValueKey('share_interactive_album'),
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(sheetContext.tr('Etkileşimli albüm paylaş')),
              subtitle: Text(
                sheetContext.tr('Küçük bir Albumium dosyası · sunucu gerekmez'),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(
                sheetContext,
                _ShareExportChoice.interactiveAlbum,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _CinematicExportTile(
              key: const ValueKey('share_mp4'),
              onTap: () => Navigator.pop(sheetContext, _ShareExportChoice.mp4),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            ListTile(
              key: const ValueKey('share_current_png'),
              leading: const Icon(Icons.image_outlined),
              title: Text(sheetContext.tr('Bu görünümü PNG paylaş')),
              subtitle: Text(sheetContext.tr('Hızlı · 1080 × 1920 anı kartı')),
              onTap: () =>
                  Navigator.pop(sheetContext, _ShareExportChoice.currentPng),
            ),
            ListTile(
              key: const ValueKey('share_all_png'),
              leading: const Icon(Icons.collections_outlined),
              title: Text(sheetContext.tr('Tüm albümü PNG paylaş')),
              subtitle: Text(
                sheetContext.tr('Kapak ve bütün sayfa görünümleri'),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _ShareExportChoice.allPng),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case _ShareExportChoice.interactiveAlbum:
        await _exportInteractiveAlbum();
      case _ShareExportChoice.currentPng:
        await _exportPngAndShare(allPositions: false);
      case _ShareExportChoice.allPng:
        await _exportPngAndShare(allPositions: true);
      case _ShareExportChoice.mp4:
        final includeSoundtrack = await _showMp4ExportOptions();
        if (includeSoundtrack != null && mounted) {
          await _exportMp4AndShare(includeSoundtrack: includeSoundtrack);
        }
    }
  }

  Future<void> _exportInteractiveAlbum() async {
    if (_exporting) return;
    _timer?.cancel();
    final localizations =
        AlbumiumLocalizations.maybeOf(context) ??
        const AlbumiumLocalizations(Locale('tr'));
    final shareText = localizations.text(
      '“{title}” albümünü Albumium’da açmak için bu dosyaya dokun.',
      values: {'title': widget.album.title},
    );
    setState(() {
      _autoPlay = false;
      _exporting = true;
      _exportProgress = 0;
      _exportStatus = localizations.text('Albüm paketi hazırlanıyor…');
      _exportProgressDetails = '';
      _exportCanCancel = false;
      _exportCancellationRequested = false;
      _exportingSinglePageVideo = false;
    });

    try {
      final result = await AlbumPackageService().createPackage(
        widget.album,
        onProgress: (stage, progress) {
          if (!mounted) return;
          setState(() {
            _exportProgress = progress.clamp(0.0, 1.0);
            _exportStatus = switch (stage) {
              AlbumPackageStage.preparing => localizations.text(
                'Albüm paketi hazırlanıyor…',
              ),
              AlbumPackageStage.optimizingPhotos => localizations.text(
                'Fotoğraflar paylaşım için küçültülüyor…',
              ),
              AlbumPackageStage.packaging => localizations.text(
                'Albüm dosyası paketleniyor…',
              ),
            };
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _exportProgress = 1;
        _exportStatus = localizations.text('Paylaşım menüsü açılıyor…');
        _exportProgressDetails = localizations.text(
          '{size} · {count} fotoğraf',
          values: {
            'size': AlbumPackageService.formatBytes(result.packageBytes),
            'count': result.mediaCount,
          },
        );
      });
      final filename = result.file.uri.pathSegments.last;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.file.path, mimeType: albumPackageMimeType)],
          fileNameOverrides: [filename],
          title: widget.album.title,
          subject: '${widget.album.title} · Albumium',
          text: shareText,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.text(
                'Etkileşimli albüm hazırlanamadı: {error}',
                values: {
                  'error': _albumPackageExportError(localizations, error),
                },
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportCanCancel = false;
          _exportCancellationRequested = false;
        });
      }
    }
  }

  Future<bool?> _showMp4ExportOptions() async {
    if (widget.album.pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('MP4 oluşturmak için albümde en az bir sayfa olmalı.'),
          ),
        ),
      );
      return null;
    }
    var includeSoundtrack = true;
    final storyboard = SinglePageExportStoryboard.forPages(
      widget.album.pages.length,
    );
    final durationLabel = formatExportDuration(storyboard.duration);

    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bitrate = 12000000 + (includeSoundtrack ? 192000 : 0);
          final estimatedMegabytes = math.max(
            1,
            (bitrate * storyboard.duration.inMilliseconds / 8000000000).ceil(),
          );
          return SingleChildScrollView(
            key: const ValueKey('mp4_export_options'),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('Tek Sayfa MP4'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'Sayfalar editördeki gibi tek tek gösterilir; hiçbir fotoğraf yüklenmez.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.high_quality_rounded),
                    title: const Text('Full HD · 1080 × 1920'),
                    subtitle: Text(
                      context.tr(
                        '{fps} FPS · {duration} · yaklaşık {size} MB',
                        values: {
                          'fps': storyboard.fps,
                          'duration': durationLabel,
                          'size': estimatedMegabytes,
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile.adaptive(
                    key: const ValueKey('mp4_soundtrack_toggle'),
                    value: includeSoundtrack,
                    onChanged: (value) =>
                        setSheetState(() => includeSoundtrack = value),
                    secondary: const Icon(Icons.graphic_eq_rounded),
                    title: Text(context.tr('Arka plan sesi')),
                    subtitle: Text(
                      context.tr(
                        'Ambient ses ve gerçek sayfa çevirme dokusu cihazda üretilir.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(context.tr('Vazgeç')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        key: const ValueKey('start_mp4_export'),
                        onPressed: () =>
                            Navigator.pop(sheetContext, includeSoundtrack),
                        icon: const Icon(Icons.movie_creation_outlined),
                        label: Text(context.tr('MP4 oluştur')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPngAndShare({required bool allPositions}) async {
    if (_exporting) return;
    _timer?.cancel();
    setState(() {
      _autoPlay = false;
      _exporting = true;
      _exportProgress = 0;
      _exportStatus = context.tr('PNG görünümleri hazırlanıyor…');
      _exportProgressDetails = '';
      _exportCanCancel = false;
      _exportCancellationRequested = false;
      _exportingSinglePageVideo = false;
    });
    _preloadedExportPositions.clear();

    try {
      final positions = allPositions
          ? List<int>.generate(previewCount, (index) => index)
          : <int>[_current];
      final directory = await getTemporaryDirectory();
      await cleanupStaleAlbumiumExports(directory);
      final safeTitle = safeAlbumiumExportTitle(widget.album.title);
      final createdAt = DateTime.now();
      final files = <XFile>[];
      final names = <String>[];

      for (var index = 0; index < positions.length; index++) {
        final position = positions[index];
        if (mounted) {
          setState(() {
            _exportStatus = positions.length == 1
                ? context.tr('Anı kartı hazırlanıyor…')
                : context.tr(
                    'PNG {current} / {total} hazırlanıyor…',
                    values: {'current': index + 1, 'total': positions.length},
                  );
          });
        }
        final pngBytes = await _captureExportBookFrame(
          from: position,
          settleAssets: index == 0,
          format: ui.ImageByteFormat.png,
        );
        final suffix = positions.length == 1
            ? 'ani_karti'
            : (position + 1).toString().padLeft(2, '0');
        final displayName = '${safeTitle}_$suffix.png';
        final filename = albumiumExportFilename(
          title: widget.album.title,
          createdAt: createdAt,
          extension: 'png',
          suffix: suffix,
        );
        final path = '${directory.path}${Platform.pathSeparator}$filename';
        await File(path).writeAsBytes(pngBytes, flush: true);
        files.add(XFile(path, mimeType: 'image/png'));
        names.add(displayName);
        if (mounted) {
          setState(() => _exportProgress = (index + 1) / positions.length);
        }
      }

      if (!mounted) return;
      setState(() => _exportStatus = context.tr('Paylaşım menüsü açılıyor…'));
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          fileNameOverrides: names,
          title: widget.album.title,
          subject: '${widget.album.title} · Albumium',
          text: allPositions
              ? context.tr(
                  '“{title}” albümümün sayfalarını Albumium ile hazırladım.',
                  values: {'title': widget.album.title},
                )
              : context.tr(
                  '“{title}” albümümden bir anı kartı.',
                  values: {'title': widget.album.title},
                ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'PNG paylaşımı hazırlanamadı: {error}',
                values: {'error': error},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportCanCancel = false;
          _exportCancellationRequested = false;
        });
      }
    }
  }

  Future<void> _exportMp4AndShare({required bool includeSoundtrack}) async {
    if (_exporting) return;
    final localizedShareText = context.tr(
      '“{title}” albümümün sayfalarını Albumium ile hazırladım.',
      values: {'title': widget.album.title},
    );
    _timer?.cancel();
    final stopwatch = Stopwatch()..start();
    setState(() {
      _autoPlay = false;
      _exporting = true;
      _exportProgress = 0;
      _exportStatus = context.tr('Sayfalar hazırlanıyor…');
      _exportProgressDetails = _localizedProgressLabel(
        const VideoExportProgressEstimate(
          progress: 0,
          elapsed: Duration.zero,
          estimatedRemaining: null,
        ),
      );
      _exportCanCancel = true;
      _exportCancellationRequested = false;
      _exportingSinglePageVideo = true;
      _exportFocusedPage = 0;
      _exportTargetFocusedPage = null;
      _exportSinglePageBeatKind = SinglePageExportBeatKind.hold;
      _exportSinglePageProgress = 0;
    });
    _preloadedExportPositions.clear();
    _preloadedExportPageSpreads.clear();

    var encoderStarted = false;
    String? outputPath;
    Future<void> finishEncoderIfNeeded() async {
      if (!encoderStarted) return;
      try {
        await FlutterQuickVideoEncoder.finish();
      } finally {
        encoderStarted = false;
      }
    }

    Future<void> deletePartialOutput() async {
      final path = outputPath;
      if (path == null) return;
      final partialFile = File(path);
      if (!await partialFile.exists()) return;
      try {
        await partialFile.delete();
      } on FileSystemException {
        // The export has already stopped; a locked temp file can be retried by
        // the next age-based cleanup pass.
      }
    }

    try {
      _throwIfExportCancelled();
      final storyboard = SinglePageExportStoryboard.forPages(
        widget.album.pages.length,
      );
      if (storyboard.totalFrames == 0) {
        throw StateError(
          context.tr('MP4 oluşturmak için albümde sayfa bulunamadı.'),
        );
      }
      final soundtrackStoryboard = _soundtrackStoryboardFor(storyboard);
      final directory = await getTemporaryDirectory();
      await cleanupStaleAlbumiumExports(directory);
      _throwIfExportCancelled();
      final filename = albumiumExportFilename(
        title: widget.album.title,
        createdAt: DateTime.now(),
        extension: 'mp4',
      );
      final path = '${directory.path}${Platform.pathSeparator}$filename';
      outputPath = path;
      await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
      _throwIfExportCancelled();
      await FlutterQuickVideoEncoder.setup(
        width: _exportVideoWidth,
        height: _exportVideoHeight,
        fps: storyboard.fps,
        videoBitrate: 12000000,
        profileLevel: ProfileLevel.baselineAutoLevel,
        audioChannels: includeSoundtrack ? CinematicSoundtrack.channelCount : 0,
        audioBitrate: includeSoundtrack ? 192000 : 0,
        sampleRate: includeSoundtrack ? CinematicSoundtrack.sampleRate : 0,
        filepath: path,
      );
      encoderStarted = true;

      var completed = 0;
      var assetsSettled = false;
      var filmFrame = 0;
      var lastProgressUpdate = Duration.zero;
      for (final beat in storyboard.beats) {
        _throwIfExportCancelled();
        if (mounted) {
          setState(() {
            _exportStatus = switch (beat.kind) {
              SinglePageExportBeatKind.hold => context.tr(
                'Sayfa {page} hazırlanıyor…',
                values: {'page': beat.fromPage + 1},
              ),
              SinglePageExportBeatKind.pan => context.tr(
                'Sol sayfadan sağ sayfaya geçiliyor…',
              ),
              SinglePageExportBeatKind.pageTurn => context.tr(
                'Sonraki sayfa çevriliyor…',
              ),
            };
          });
        }

        Uint8List? sampledFrame;
        const captureCadence = 1;
        for (var localFrame = 0; localFrame < beat.frameCount; localFrame++) {
          _throwIfExportCancelled();
          final progress = beat.frameCount <= 1
              ? 1.0
              : localFrame / (beat.frameCount - 1);
          final shouldCapture =
              sampledFrame == null ||
              localFrame % captureCadence == 0 ||
              localFrame == beat.frameCount - 1;
          if (shouldCapture) {
            sampledFrame = await _captureSinglePageVideoFrame(
              beat: beat,
              progress: progress,
              settleAssets: !assetsSettled,
            );
            assetsSettled = true;
          }
          _throwIfExportCancelled();
          await FlutterQuickVideoEncoder.appendVideoFrame(sampledFrame);
          if (includeSoundtrack) {
            _throwIfExportCancelled();
            await FlutterQuickVideoEncoder.appendAudioFrame(
              CinematicSoundtrack.pcmFrame(
                storyboard: soundtrackStoryboard,
                frameIndex: filmFrame,
                fps: storyboard.fps,
              ),
            );
          }
          filmFrame++;
          completed++;
          _throwIfExportCancelled();
          final elapsed = stopwatch.elapsed;
          final shouldUpdateProgress =
              completed == storyboard.totalFrames ||
              elapsed - lastProgressUpdate >= const Duration(milliseconds: 750);
          if (mounted && shouldUpdateProgress) {
            final estimate = estimateVideoExportProgress(
              completedFrames: completed,
              totalFrames: storyboard.totalFrames,
              elapsed: elapsed,
            );
            lastProgressUpdate = elapsed;
            setState(() {
              _exportProgress = estimate.progress;
              _exportProgressDetails = _localizedProgressLabel(estimate);
            });
          }
        }
      }
      _throwIfExportCancelled();
      if (mounted) {
        setState(
          () => _exportStatus = context.tr('Video dosyası tamamlanıyor…'),
        );
      }
      await finishEncoderIfNeeded();
      _throwIfExportCancelled();
      final videoFile = await requireNonEmptyVideoExport(path);
      _throwIfExportCancelled();
      setState(() {
        _exportProgress = 1;
        _exportStatus = context.tr('Hazır! Paylaşım menüsü açılıyor…');
        _exportProgressDetails = _localizedProgressLabel(
          VideoExportProgressEstimate(
            progress: 1,
            elapsed: stopwatch.elapsed,
            estimatedRemaining: Duration.zero,
          ),
        );
        _exportCanCancel = false;
      });
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(videoFile.path)],
          fileNameOverrides: [
            '${safeAlbumiumExportTitle(widget.album.title)}.mp4',
          ],
          title: widget.album.title,
          subject: '${widget.album.title} · Albumium',
          text: localizedShareText,
        ),
      );
    } catch (error) {
      final cancelled =
          error is _VideoExportCancelled ||
          _exportCancellationRequested ||
          !mounted;
      try {
        await finishEncoderIfNeeded();
      } catch (_) {
        // The primary export error remains the useful diagnostic. A cancelled
        // export deliberately stays silent even if encoder shutdown also fails.
      }
      await deletePartialOutput();
      if (mounted && !cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Video hazırlanamadı: {error}',
                values: {'error': error},
              ),
            ),
          ),
        );
      }
    } finally {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportCanCancel = false;
          _exportCancellationRequested = false;
          _exportingSinglePageVideo = false;
          _exportTargetFocusedPage = null;
        });
      }
    }
  }

  String _positionLabel() {
    if (_current == 0) {
      return context.tr(
        'Kapak · {binding}',
        values: {'binding': context.tr(widget.album.bindingType.title)},
      );
    }
    if (_current == 1) {
      return widget.album.pages.isEmpty
          ? context.tr('İç kapak')
          : context.tr('İç kapak · Sayfa 1');
    }
    final position = _positionFor(_current);
    final visible = [
      position.left,
      position.right,
    ].where((index) => index >= 0).map((index) => index + 1).toList();
    return visible.length == 1
        ? context.tr('Sayfa {page}', values: {'page': visible.first})
        : context.tr(
            'Sayfalar {first}–{last}',
            values: {'first': visible.first, 'last': visible.last},
          );
  }

  String _localizedProgressLabel(VideoExportProgressEstimate estimate) {
    final remaining = estimate.estimatedRemaining;
    return context.tr(
      '{percent}% · Geçen {elapsed} · Tahmini kalan {remaining}',
      values: {
        'percent': (estimate.progress.clamp(0.0, 1.0) * 100).round(),
        'elapsed': formatExportDuration(estimate.elapsed),
        'remaining': remaining == null ? '—' : formatExportDuration(remaining),
      },
    );
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
          turnGrabY: _turnGrabY,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumTheme = themeById(widget.album.themeId);
    final colors = Theme.of(context).colorScheme;
    final craftColors = AlbumiumAppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(context.tr('Albüm Önizleme')),
        backgroundColor: craftColors.background,
        actions: [
          IconButton(
            onPressed: _toggleAutoPlay,
            tooltip: _autoPlay
                ? context.tr('Durdur')
                : context.tr('Otomatik oynat'),
            icon: Icon(
              _autoPlay
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: CraftBackdrop(
        variant: CraftBackdropVariant.cork,
        baseColor: craftColors.background,
        textureIntensity: .66,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                    child: PaperPanel(
                      color: craftColors.surface,
                      borderRadius: BorderRadius.circular(7),
                      rotationDegrees: -.25,
                      padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
                      tapePositions: const [CraftTapePosition.topCenter],
                      tapeColor: Color.lerp(
                        albumTheme.accent,
                        craftColors.elevatedSurface,
                        .58,
                      ),
                      tapeWidth: 48,
                      tapeHeight: 14,
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
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: craftColors.text,
                                        fontSize: 22,
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
                            key: const ValueKey('preview_share_button'),
                            onPressed: _target == null && !_exporting
                                ? _showShareOptions
                                : null,
                            icon: const Icon(Icons.ios_share_rounded, size: 18),
                            label: Text(context.tr('Paylaş')),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
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
                                Colors.transparent,
                                Colors.black.withValues(alpha: .12),
                              ],
                              stops: const [0, 0.64, 1],
                            ),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, bookConstraints) =>
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) =>
                                    _handleBookTap(details, bookConstraints),
                                onHorizontalDragStart: (details) =>
                                    _handleDragStart(details, bookConstraints),
                                onHorizontalDragUpdate: _handleDragUpdate,
                                onHorizontalDragEnd: _handleDragEnd,
                                onHorizontalDragCancel: _handleDragCancel,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    10,
                                    10,
                                    30,
                                  ),
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
                              tooltip: context.tr('Önceki sayfa'),
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
                              tooltip: context.tr('Sonraki sayfa'),
                              enabled:
                                  _current < previewCount - 1 &&
                                  _target == null,
                              onTap: () => _goTo(_current + 1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 4,
                          child: Center(
                            child: TornPaperLabel(
                              color: craftColors.surface.withValues(alpha: .92),
                              rotationDegrees: .25,
                              edgeDepth: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: Text(
                                _reduceMotion
                                    ? context.tr(
                                        'Oklarla gez · azaltılmış hareket',
                                      )
                                    : context.tr(
                                        'Kaydır veya oklarla sayfaları çevir',
                                      ),
                                style: TextStyle(
                                  color: craftColors.mutedText,
                                  fontSize: 10.5,
                                ),
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
                        label: context.tr(
                          'Albüm ilerlemesi {current} / {total}',
                          values: {
                            'current': _current + 1,
                            'total': previewCount,
                          },
                        ),
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
                                    ? context.tr('Kapak')
                                    : context.tr(
                                        'Kitap görünümü {index}',
                                        values: {'index': index},
                                      ),
                                selected: index == _current,
                                button: true,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: _target == null
                                      ? () => _goTo(
                                          index,
                                          animate:
                                              (index - _current).abs() == 1,
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
                                child: _exportingSinglePageVideo
                                    ? _SinglePageExportFrame(
                                        album: widget.album,
                                        focusedPageIndex: _exportFocusedPage,
                                        targetFocusedPageIndex:
                                            _exportTargetFocusedPage,
                                        beatKind: _exportSinglePageBeatKind,
                                        progress: _exportSinglePageProgress,
                                      )
                                    : _ExportBookFrame(
                                        album: widget.album,
                                        current: _positionFor(_exportFrom),
                                        target: _exportTo == null
                                            ? null
                                            : _positionFor(_exportTo!),
                                        turnProgress: _exportTurnProgress,
                                        turningForward: _exportTurningForward,
                                        position: _exportFrom,
                                        positionCount: previewCount,
                                        beatKind: _exportBeatKind,
                                        transitionStyle: _exportTransitionStyle,
                                        beatProgress: _exportBeatProgress,
                                        shotVariant: _exportShotVariant,
                                        filmFrame: _exportFilmFrame,
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
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          if (_exportProgressDetails.isNotEmpty)
                            Text(
                              _exportProgressDetails,
                              key: const ValueKey('export_progress_details'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          if (_exportCanCancel) ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              key: const ValueKey('cancel_video_export'),
                              onPressed: _exportCancellationRequested
                                  ? null
                                  : _requestExportCancellation,
                              icon: Icon(
                                _exportCancellationRequested
                                    ? Icons.hourglass_top_rounded
                                    : Icons.close_rounded,
                              ),
                              label: Text(
                                _exportCancellationRequested
                                    ? context.tr('İptal ediliyor…')
                                    : context.tr('İptal'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _exportCancellationRequested
                                ? context.tr('Video güvenle kapatılıyor')
                                : context.tr('Uygulamayı kapatma'),
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
      ),
    );
  }
}

String _albumPackageExportError(
  AlbumiumLocalizations localizations,
  Object error,
) {
  if (error is AlbumPackageException) {
    return switch (error.failure) {
      AlbumPackageFailure.missingSource => localizations.text(
        'Albümde kullanılan bir fotoğraf bulunamadı.',
      ),
      AlbumPackageFailure.tooLarge => localizations.text(
        'Albüm paketi izin verilen boyutu aşıyor.',
      ),
      AlbumPackageFailure.invalidArchive => localizations.text(
        'Dosya geçerli bir Albumium albümü değil.',
      ),
      AlbumPackageFailure.unsupportedVersion => localizations.text(
        'Bu albüm daha yeni bir Albumium sürümü gerektiriyor.',
      ),
      AlbumPackageFailure.unsafeContent => localizations.text(
        'Albüm paketi güvenli olmayan içerik barındırıyor.',
      ),
      AlbumPackageFailure.corruptMedia => localizations.text(
        'Albümdeki fotoğraflardan biri bozuk veya değiştirilmiş.',
      ),
    };
  }
  return localizations.text('Beklenmeyen bir dosya hatası oluştu.');
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

class _VideoExportCancelled implements Exception {
  const _VideoExportCancelled();
}

class _SinglePageExportFrame extends StatelessWidget {
  const _SinglePageExportFrame({
    required this.album,
    required this.focusedPageIndex,
    required this.targetFocusedPageIndex,
    required this.beatKind,
    required this.progress,
  });

  final AlbumModel album;
  final int focusedPageIndex;
  final int? targetFocusedPageIndex;
  final SinglePageExportBeatKind beatKind;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    final currentLeft = focusedPageIndex.isEven
        ? focusedPageIndex
        : focusedPageIndex - 1;
    final currentRight = currentLeft + 1 < album.pages.length
        ? currentLeft + 1
        : PhysicalBookSpread.blankPageIndex;
    final targetPage = targetFocusedPageIndex;
    final isPageTurn =
        beatKind == SinglePageExportBeatKind.pageTurn && targetPage != null;
    final targetLeft = targetPage == null
        ? null
        : (targetPage.isEven ? targetPage : targetPage - 1);
    final targetRight = targetLeft == null
        ? null
        : targetLeft + 1 < album.pages.length
        ? targetLeft + 1
        : PhysicalBookSpread.blankPageIndex;
    final motion = progress.clamp(0.0, 1.0);

    return SizedBox(
      key: const ValueKey('single-page-export-frame'),
      width: _exportLogicalWidth,
      height: _exportLogicalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.08),
            radius: 1.05,
            colors: [
              Color.lerp(theme.coverStart, const Color(0xFF2B2522), .62)!,
              Color.lerp(theme.coverEnd, const Color(0xFF171412), .72)!,
              const Color(0xFF100E0D),
            ],
            stops: const [0, .68, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: PhysicalBookSpread(
            album: album,
            leftPageIndex: currentLeft,
            rightPageIndex: currentRight,
            nextLeftPageIndex: isPageTurn ? targetLeft : null,
            nextRightPageIndex: isPageTurn ? targetRight : null,
            turnProgress: isPageTurn
                ? Curves.easeInOutSine.transform(motion)
                : 0,
            turningForward: true,
            interactive: false,
            focusedPageIndex: focusedPageIndex,
            targetFocusedPageIndex: beatKind == SinglePageExportBeatKind.hold
                ? null
                : targetPage,
            focusTransitionProgress: beatKind == SinglePageExportBeatKind.hold
                ? null
                : motion,
            companionPageFraction: 0,
          ),
        ),
      ),
    );
  }
}

CinematicStoryboard _soundtrackStoryboardFor(
  SinglePageExportStoryboard storyboard,
) {
  final lastPage = storyboard.pageCount - 1;
  return CinematicStoryboard(
    fps: storyboard.fps,
    beats: [
      for (final beat in storyboard.beats)
        CinematicBeat(
          kind: switch (beat.kind) {
            SinglePageExportBeatKind.pageTurn => CinematicBeatKind.pageTurn,
            SinglePageExportBeatKind.pan => CinematicBeatKind.memory,
            SinglePageExportBeatKind.hold
                when storyboard.pageCount > 1 && beat.fromPage == 0 =>
              CinematicBeatKind.prologue,
            SinglePageExportBeatKind.hold
                when storyboard.pageCount > 1 && beat.fromPage == lastPage =>
              CinematicBeatKind.epilogue,
            SinglePageExportBeatKind.hold => CinematicBeatKind.memory,
          },
          from: beat.fromPage,
          to: beat.kind == SinglePageExportBeatKind.pageTurn
              ? beat.toPage
              : null,
          frameCount: beat.frameCount,
        ),
    ],
  );
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
    required this.beatKind,
    required this.transitionStyle,
    required this.beatProgress,
    required this.shotVariant,
    required this.filmFrame,
  });

  final AlbumModel album;
  final _BookPosition current;
  final _BookPosition? target;
  final double turnProgress;
  final bool turningForward;
  final int position;
  final int positionCount;
  final CinematicBeatKind? beatKind;
  final CinematicTransitionStyle transitionStyle;
  final double beatProgress;
  final int shotVariant;
  final int filmFrame;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    final cinematic = beatKind != null;
    final pose = _cameraPoseFor(beatKind, beatProgress, shotVariant);
    final bookOpacity = switch (beatKind) {
      // Keep the opening title and cover in separate visual beats. In the old
      // export they occupied the same center area and their text overlapped.
      CinematicBeatKind.prologue => ((beatProgress - .72) / .26).clamp(
        0.0,
        1.0,
      ),
      CinematicBeatKind.epilogue => (1 - ((beatProgress - .08) / .58)).clamp(
        0.0,
        1.0,
      ),
      _ => 1.0,
    };
    final grabY = switch (shotVariant % 3) {
      1 => .36,
      2 => .76,
      _ => .58,
    };
    final transitionMix = beatKind == CinematicBeatKind.pageTurn
        ? turnProgress.clamp(0.0, 1.0)
        : 0.0;
    final book = PhysicalBookSpread(
      album: album,
      leftPageIndex: current.left,
      rightPageIndex: current.right,
      closed: current.closed,
      nextLeftPageIndex: beatKind == CinematicBeatKind.pageTurn
          ? target?.left
          : null,
      nextRightPageIndex: beatKind == CinematicBeatKind.pageTurn
          ? target?.right
          : null,
      nextClosed: target?.closed ?? false,
      turnProgress: transitionMix,
      turningForward: turningForward,
      turnGrabY: grabY,
    );
    final presentationScale = !cinematic
        ? 1.0
        : current.closed
        ? 1.24 + transitionMix * .1
        : 1.34;
    return SizedBox(
      width: _exportLogicalWidth,
      height: _exportLogicalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.12),
            radius: 1.08,
            colors: [
              Color.lerp(theme.coverStart, const Color(0xFF29211E), 0.68)!,
              Color.lerp(theme.coverEnd, const Color(0xFF171311), 0.74)!,
              const Color(0xFF100E0D),
            ],
            stops: const [0, 0.62, 1],
          ),
        ),
        child: Stack(
          children: [
            if (!cinematic)
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
                          ? context.tr('ALBÜM KAPAĞI')
                          : context.tr(
                              'ANILAR · {current} / {total}',
                              values: {
                                'current': position + 1,
                                'total': positionCount,
                              },
                            ),
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
              left: cinematic ? 0 : 10,
              right: cinematic ? 0 : 10,
              top: cinematic ? 86 : 116,
              bottom: cinematic ? 72 : 96,
              child: Opacity(
                opacity: bookOpacity,
                child: Transform.translate(
                  offset: pose.offset,
                  child: Transform.rotate(
                    angle: pose.rotation,
                    child: Transform.scale(
                      scale: pose.scale * presentationScale,
                      child: book,
                    ),
                  ),
                ),
              ),
            ),
            if (!cinematic)
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
            if (cinematic)
              Positioned.fill(
                child: _CinematicFilmOverlay(
                  kind: beatKind!,
                  transitionStyle: transitionStyle,
                  progress: beatProgress,
                  frameIndex: filmFrame,
                ),
              ),
            if (beatKind == CinematicBeatKind.prologue)
              Positioned.fill(
                child: _CinematicTitleCard(
                  eyebrow: context.tr('BİR HATIRA FİLMİ'),
                  title: album.title,
                  caption: context.tr('Her anının bir başlangıcı vardır.'),
                  opacity: _prologueTitleOpacity(beatProgress),
                ),
              ),
            if (beatKind == CinematicBeatKind.epilogue)
              Positioned.fill(
                child: _CinematicTitleCard(
                  eyebrow: 'ALBUMIUM',
                  title: album.title,
                  caption: context.tr('Bazı anılar bitmez. Yalnızca saklanır.'),
                  opacity: ((beatProgress - .18) / .42).clamp(0.0, 1.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraPose {
  const _CameraPose(this.scale, this.offset, this.rotation);

  final double scale;
  final Offset offset;
  final double rotation;
}

_CameraPose _cameraPoseFor(
  CinematicBeatKind? kind,
  double progress,
  int variant,
) {
  if (kind == null) return const _CameraPose(1, Offset.zero, 0);
  final position = progress.clamp(0.0, 1.0);
  final pulse = math.sin(position * math.pi);
  final arrival = Curves.easeOutCubic.transform(position);
  final departure = Curves.easeInOutCubic.transform(position);
  return switch (kind) {
    CinematicBeatKind.prologue => _CameraPose(
      .95 + arrival * .05,
      Offset(0, 10 * (1 - arrival)),
      -.006 * (1 - arrival),
    ),
    CinematicBeatKind.epilogue => _CameraPose(
      1 - departure * .025,
      Offset(0, departure * 8),
      .004 * departure,
    ),
    CinematicBeatKind.pageTurn => _CameraPose(
      1 + pulse * .024,
      Offset((variant - 1) * 3.2 * pulse, -4 * pulse),
      (variant - 1) * .005 * pulse,
    ),
    CinematicBeatKind.memory => switch (variant % 4) {
      1 => _CameraPose(
        1 + pulse * .035,
        Offset(5 * pulse, -3 * pulse),
        -.004 * pulse,
      ),
      2 => _CameraPose(
        1 + pulse * .032,
        Offset(-5 * pulse, -5 * pulse),
        .004 * pulse,
      ),
      3 => _CameraPose(
        1 + pulse * .034,
        Offset(3 * pulse, -5 * pulse),
        -.003 * pulse,
      ),
      _ => _CameraPose(
        1 + pulse * .036,
        Offset(-3 * pulse, -5 * pulse),
        .003 * pulse,
      ),
    },
  };
}

double _prologueTitleOpacity(double progress) {
  final position = progress.clamp(0.0, 1.0);
  if (position < .16) return Curves.easeOut.transform(position / .16);
  if (position <= .56) return 1;
  if (position < .78) {
    return 1 - Curves.easeIn.transform((position - .56) / .22);
  }
  return 0;
}

class _CinematicTitleCard extends StatelessWidget {
  const _CinematicTitleCard({
    required this.eyebrow,
    required this.title,
    required this.caption,
    required this.opacity,
  });

  final String eyebrow;
  final String title;
  final String caption;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .66),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'AlbumiumDisplay',
                  color: Colors.white,
                  fontSize: 34,
                  height: .96,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              Container(width: 34, height: 1, color: Colors.white38),
              const SizedBox(height: 12),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .76),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CinematicFilmOverlay extends StatelessWidget {
  const _CinematicFilmOverlay({
    required this.kind,
    required this.transitionStyle,
    required this.progress,
    required this.frameIndex,
  });

  final CinematicBeatKind kind;
  final CinematicTransitionStyle transitionStyle;
  final double progress;
  final int frameIndex;

  @override
  Widget build(BuildContext context) {
    final transitionPulse = kind == CinematicBeatKind.pageTurn
        ? math.sin(progress * math.pi)
        : 0.0;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (kind == CinematicBeatKind.pageTurn &&
              transitionStyle == CinematicTransitionStyle.pageCurl)
            ColoredBox(
              color: const Color(
                0xFFFFE8D0,
              ).withValues(alpha: transitionPulse * .10),
            ),
          if (transitionStyle == CinematicTransitionStyle.warmLightLeak)
            Opacity(
              opacity: transitionPulse * .32,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFFFD49A),
                      Color(0x99EE6544),
                      Colors.transparent,
                    ],
                    stops: [0, .34, .78],
                  ),
                ),
              ),
            ),
          if (transitionStyle == CinematicTransitionStyle.projectorDip)
            ColoredBox(
              color: Colors.black.withValues(alpha: transitionPulse * .24),
            ),
          CustomPaint(
            painter: _FilmGrainPainter(
              frameIndex: frameIndex,
              intensity: kind == CinematicBeatKind.memory ? .20 : .14,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: .94,
                colors: [Colors.transparent, Color(0x84000000)],
                stops: [.58, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  const _FilmGrainPainter({required this.frameIndex, required this.intensity});

  final int frameIndex;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    var state = (frameIndex + 17) * 1103515245;
    final paint = Paint();
    for (var index = 0; index < 84; index++) {
      state = (state * 1664525 + 1013904223) & 0x7fffffff;
      final x = (state % 1000) / 1000 * size.width;
      state = (state * 1664525 + 1013904223) & 0x7fffffff;
      final y = (state % 1000) / 1000 * size.height;
      final bright = state.isEven;
      paint.color = (bright ? Colors.white : Colors.black).withValues(
        alpha: intensity * (.12 + (state % 5) * .018),
      );
      canvas.drawCircle(Offset(x, y), .35 + (state % 3) * .18, paint);
    }
    paint.color = Colors.white.withValues(alpha: intensity * .08);
    for (var scratch = 0; scratch < 2; scratch++) {
      final x = ((frameIndex * 37 + scratch * 149) % 360).toDouble();
      canvas.drawLine(Offset(x, 0), Offset(x + 1.2, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) =>
      oldDelegate.frameIndex != frameIndex ||
      oldDelegate.intensity != intensity;
}

class _CinematicExportTile extends StatelessWidget {
  const _CinematicExportTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF281A20), Color(0xFF7A3344), Color(0xFFC26A4B)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x333B1118),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.movie_creation_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('TEK SAYFA VİDEO'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('Sayfalarını sırayla oynat'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                          'Sol → sağ kaydırma · gerçek sayfa çevirme · sade görünüm',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          const _ExportBadge('1080p'),
                          const _ExportBadge('30 FPS'),
                          _ExportBadge(context.tr('SES SEÇENEĞİ')),
                          const _ExportBadge('OFFLINE'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportBadge extends StatelessWidget {
  const _ExportBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
      ),
    );
  }
}
