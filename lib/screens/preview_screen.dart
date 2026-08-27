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
import '../theme/book_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/motion.dart';
import '../widgets/page_flip_view.dart';

/// Dışa aktarılan videodaki tek bir sayfanın ekranda kaldığı kare sayısı.
const _holdFrames = 12;

/// İki sayfa arasındaki çevirme hareketinin kaç kareye yayılacağı.
const _flipFrames = 5;

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.album});

  final AlbumModel album;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _flip = PageFlipController();
  final _exportBoundary = GlobalKey();
  int _current = 0;
  int _exportSlide = 0;
  double _exportFlip = 0;
  bool _autoPlay = false;
  bool _chromeVisible = true;
  bool _exporting = false;
  double _exportProgress = 0;
  String _exportStatus = '';
  Timer? _timer;

  int get slideCount => widget.album.pages.length + 1;

  @override
  void initState() {
    super.initState();
    // Uygulamanın geri kalanı dikey kilitlidir; okuma ekranı ise yatay
    // tutulduğunda iki sayfalı açık kitaba geçebilmeli.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Ekrandan çıkarken kilidi geri koy, yoksa albüm listesi de yan dönerdi.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]),
    );
    super.dispose();
  }

  void _toggleAutoPlay() {
    // Son sayfadayken oynatmaya basıldığında baştan başla.
    if (!_autoPlay && _current >= slideCount - 1) _flip.jumpTo(0);
    setState(() => _autoPlay = !_autoPlay);
    _timer?.cancel();
    if (!_autoPlay) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted || !_autoPlay) return;
      if (_current >= slideCount - 1) {
        _timer?.cancel();
        setState(() => _autoPlay = false);
        return;
      }
      _flip.next();
    });
  }

  void _stopAutoPlay() {
    if (!_autoPlay) return;
    _timer?.cancel();
    setState(() => _autoPlay = false);
  }

  /// Kitabın dış kenarlarına dokunmak sayfa çevirir, ortasına dokunmak
  /// kontrolleri gizleyip gösterir — okurken arayüz yoldan çekilsin diye.
  ///
  /// Dokunulan dikey nokta kıvrıma aktarılır: alt köşeye dokunulduğunda
  /// yaprak alt köşeden, üste dokunulduğunda üstten kıvrılır.
  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx / constraints.maxWidth;
    final grabY = (details.localPosition.dy / constraints.maxHeight).clamp(
      0.0,
      1.0,
    );
    if (x > 0.62) {
      _stopAutoPlay();
      _flip.next(grabY: grabY);
    } else if (x < 0.28) {
      _stopAutoPlay();
      _flip.previous(grabY: grabY);
    } else {
      setState(() => _chromeVisible = !_chromeVisible);
    }
  }

  Widget _slide(int index) {
    final theme = themeById(widget.album.themeId);
    if (index == 0) return AlbumCover(album: widget.album);
    return AlbumPageCanvas(page: widget.album.pages[index - 1], theme: theme);
  }

  Future<Uint8List> _captureExportFrame(int index, double flip) async {
    setState(() {
      _exportSlide = index;
      _exportFlip = flip;
    });
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final boundary =
        _exportBoundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4 / 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) throw StateError('Görüntü karesi üretilemedi.');
    return data.buffer.asUint8List();
  }

  String _safeFilename(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'albumium_album' : normalized;
  }

  Future<void> _exportAndShare() async {
    if (_exporting) return;
    _stopAutoPlay();
    setState(() {
      _exporting = true;
      _exportProgress = 0;
      _exportSlide = 0;
      _exportFlip = 0;
      _exportStatus = 'Sayfalar hazırlanıyor…';
    });

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}${_safeFilename(widget.album.title)}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
      await FlutterQuickVideoEncoder.setup(
        width: 360,
        height: 640,
        fps: 10,
        videoBitrate: 1600000,
        profileLevel: ProfileLevel.baselineAutoLevel,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: path,
      );

      final total = slideCount * _holdFrames + (slideCount - 1) * _flipFrames;
      var completed = 0;
      if (!mounted) return;
      setState(() => _exportStatus = 'MP4 oluşturuluyor…');

      // Kareler tek tek yakalanıp anında kodlanır; böylece uzun albümlerde
      // tüm video belleğe yığılmaz.
      for (var index = 0; index < slideCount; index++) {
        final still = await _captureExportFrame(index, 0);
        for (var frame = 0; frame < _holdFrames; frame++) {
          await FlutterQuickVideoEncoder.appendVideoFrame(still);
          completed++;
        }
        if (!mounted) return;
        setState(() => _exportProgress = completed / total);

        if (index == slideCount - 1) break;
        for (var step = 1; step <= _flipFrames; step++) {
          final frame = await _captureExportFrame(
            index,
            step / (_flipFrames + 1),
          );
          await FlutterQuickVideoEncoder.appendVideoFrame(frame);
          completed++;
        }
        if (!mounted) return;
        setState(() => _exportProgress = completed / total);
      }

      await FlutterQuickVideoEncoder.finish();
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
      try {
        await FlutterQuickVideoEncoder.finish();
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Video hazırlanamadı: $error')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(widget.album.themeId);
    // Okuma yüzeyi açık renktir; sistem simgeleri de koyuya döner.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: BookTheme.chrome,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: BookTheme.ground,
        body: Stack(
          children: [
            // Zemin: ortada açık, kenarlara doğru koyulaşarak kitabı toplar.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    colors: [BookTheme.ground, BookTheme.groundEdge],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildBook(constraints, theme),
                ),
              ),
            ),
            _buildChrome(theme),
            if (_exporting) _buildExportOverlay(),
          ],
        ),
      ),
    );
  }

  /// Kitabı ekrana yerleştirir. Yeterince geniş bir yatay ekranda iki sayfalı
  /// açık kitap, aksi hâlde tek yaprak gösterilir.
  Widget _buildBook(BoxConstraints constraints, AlbumThemePreset theme) {
    final spread =
        constraints.maxWidth > constraints.maxHeight &&
        constraints.maxWidth >= BookTheme.spreadMinWidth;
    final available =
        constraints.maxHeight -
        BookTheme.topChromeHeight -
        BookTheme.bottomChromeHeight;
    final margin =
        math.min(constraints.maxWidth, math.max(0.0, available)) *
        BookTheme.marginRatio;
    return Padding(
      padding:
          const EdgeInsets.only(
            top: BookTheme.topChromeHeight,
            bottom: BookTheme.bottomChromeHeight,
          ) +
          EdgeInsets.all(margin),
      child: Center(
        child: AspectRatio(
          aspectRatio: spread ? BookTheme.pageAspect * 2 : BookTheme.pageAspect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BookTheme.pageRadius),
              boxShadow: BookTheme.bookShadow,
            ),
            child: spread ? _spread(theme) : _leaf(theme),
          ),
        ),
      ),
    );
  }

  /// Çevrilen yaprak. Dokunma bölgeleri ve sürükleme burada toplanır.
  Widget _leaf(AlbumThemePreset theme) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTapUp: (details) => _handleTap(details, constraints),
        child: BookFrame(
          paperColor: theme.pageColor,
          remainingPages: slideCount - _current - 1,
          borderRadius: BookTheme.pageRadius,
          child: RepaintBoundary(
            child: PageFlipView(
              controller: _flip,
              itemCount: slideCount,
              paperColor: theme.pageColor,
              borderRadius: BookTheme.pageRadius,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) => _slide(index),
            ),
          ),
        ),
      ),
    );
  }

  /// Açık kitap: solda az önce çevrilen sayfa, sağda çevrilecek yaprak.
  ///
  /// Sol sayfa yaprak yerine oturana kadar değişmez — gerçek bir kitapta da
  /// öyledir.
  Widget _spread(AlbumThemePreset theme) {
    return Row(
      children: [
        Expanded(
          child: _FacingPage(
            paperColor: theme.pageColor,
            child: _current > 0 ? _slide(_current - 1) : null,
          ),
        ),
        Expanded(child: _leaf(theme)),
      ],
    );
  }

  /// Dokununca beliren üst ve alt kontroller.
  Widget _buildChrome(AlbumThemePreset theme) {
    return IgnorePointer(
      ignoring: !_chromeVisible,
      child: AnimatedOpacity(
        opacity: _chromeVisible ? 1 : 0,
        duration: Motion.medium,
        curve: Motion.curve,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ReaderTopBar(
              title: widget.album.title,
              autoPlay: _autoPlay,
              onToggleAutoPlay: _toggleAutoPlay,
              onExport: _exportAndShare,
            ),
            _ReaderBottomBar(
              current: _current,
              count: slideCount,
              accent: theme.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xF2141110),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _exportBoundary,
                child: _ExportSlide(
                  album: widget.album,
                  index: _exportSlide,
                  flip: _exportFlip,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Uygulamayı kapatma',
                style: TextStyle(color: Color(0xFF9B8F84), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Açık kitabın sol sayfası. Çevrilecek yaprak sağdadır; bu sayfa yalnızca
/// cilt payını ve kâğıdı taşır.
class _FacingPage extends StatelessWidget {
  const _FacingPage({required this.paperColor, this.child});

  final Color paperColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(BookTheme.pageRadius),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: paperColor),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?child,
            // Cilt payı sağ kenarda: iki sayfa ortada birleşir.
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.09,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.30),
                      ],
                      stops: const [0, 0.55, 1],
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
}

/// Okuma ekranının üst kontrolleri: geri, başlık ve eylemler.
class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.title,
    required this.autoPlay,
    required this.onToggleAutoPlay,
    required this.onExport,
  });

  final String title;
  final bool autoPlay;
  final VoidCallback onToggleAutoPlay;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return _ChromeSurface(
      edge: VerticalDirection.up,
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: BookTheme.ink,
            tooltip: 'Geri',
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BookTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleAutoPlay,
            color: BookTheme.ink,
            tooltip: autoPlay ? 'Durdur' : 'Otomatik oynat',
            icon: AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                autoPlay
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                key: ValueKey(autoPlay),
              ),
            ),
          ),
          IconButton(
            onPressed: onExport,
            color: BookTheme.ink,
            tooltip: 'MP4 paylaş',
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
    );
  }
}

/// Okuma ekranının alt göstergesi.
///
/// Sayfa sayısı azken noktalar, çoğaldığında ince bir ilerleme çubuğu gösterir;
/// yüzlerce nokta okumayı böler.
class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({
    required this.current,
    required this.count,
    required this.accent,
  });

  final int current;
  final int count;
  final Color accent;

  static const _dotLimit = 12;

  @override
  Widget build(BuildContext context) {
    return _ChromeSurface(
      edge: VerticalDirection.down,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count <= _dotLimit)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < count; index++)
                  AnimatedContainer(
                    duration: Motion.medium,
                    curve: Motion.curve,
                    width: index == current ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == current
                          ? accent
                          : BookTheme.inkSoft.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: count <= 1 ? 1 : current / (count - 1),
                minHeight: 3,
                backgroundColor: BookTheme.inkSoft.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            current == 0 ? 'Kapak' : 'Sayfa $current / ${count - 1}',
            style: const TextStyle(
              color: BookTheme.inkSoft,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kontrol çubuklarının ortak zemini.
class _ChromeSurface extends StatelessWidget {
  const _ChromeSurface({
    required this.child,
    required this.padding,
    required this.edge,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Çubuğun hangi kenarda durduğu. Güvenli alan yalnızca o kenarda bırakılır;
  /// aksi hâlde içerik durum çubuğunun ya da hareket çubuğunun altında kalır.
  final VerticalDirection edge;

  @override
  Widget build(BuildContext context) {
    final top = edge == VerticalDirection.up;
    return Material(
      color: BookTheme.chrome,
      child: SafeArea(
        top: top,
        bottom: !top,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: top
                  ? BorderSide.none
                  : const BorderSide(color: Color(0x14000000)),
              bottom: top
                  ? const BorderSide(color: Color(0x14000000))
                  : BorderSide.none,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Videoya yazılan tek kare.
///
/// Ekrandaki [PageFlipView] ile aynı [FlipFrame] çizimini kullanır; bu yüzden
/// paylaşılan MP4 uygulamadaki hareketin birebir aynısını gösterir.
class _ExportSlide extends StatelessWidget {
  const _ExportSlide({
    required this.album,
    required this.index,
    required this.flip,
  });

  final AlbumModel album;
  final int index;
  final double flip;

  static const _pageWidth = 205.0;
  static const _pageHeight = _pageWidth * 14 / 9;

  Widget _slide(int position, AlbumThemePreset theme) {
    if (position == 0) return AlbumCover(album: album);
    return AlbumPageCanvas(page: album.pages[position - 1], theme: theme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    final slideCount = album.pages.length + 1;
    final next = (index + 1).clamp(0, slideCount - 1);
    return SizedBox(
      width: 270,
      height: 480,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.coverEnd, const Color(0xFF151210)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 45,
              top: (480 - _pageHeight) / 2,
              width: _pageWidth,
              height: _pageHeight,
              child: BookFrame(
                paperColor: theme.pageColor,
                remainingPages: slideCount - index - 1,
                child: flip <= 0
                    ? _slide(index, theme)
                    : FlipFrame(
                        progress: flip,
                        paperColor: theme.pageColor,
                        borderRadius: BookTheme.pageRadius,
                        front: _slide(index, theme),
                        back: _slide(next, theme),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
