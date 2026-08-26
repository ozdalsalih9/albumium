import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/album_models.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_page_canvas.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.album});

  final AlbumModel album;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _pageController = PageController(viewportFraction: 0.86);
  final _exportBoundary = GlobalKey();
  int _current = 0;
  int _exportSlide = 0;
  bool _autoPlay = false;
  bool _exporting = false;
  double _exportProgress = 0;
  String _exportStatus = '';
  Timer? _timer;

  int get slideCount => widget.album.pages.length + 1;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    _timer?.cancel();
    if (!_autoPlay) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted || !_autoPlay) return;
      final next = (_current + 1) % slideCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<Uint8List> _captureExportSlide(int index) async {
    setState(() => _exportSlide = index);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 45));
    final boundary =
        _exportBoundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4 / 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) throw StateError('Görüntü karesi üretilemedi.');
    return data.buffer.asUint8List();
  }

  Uint8List _blend(Uint8List first, Uint8List second, double amount) {
    final output = Uint8List(first.length);
    final inverse = 1 - amount;
    for (var i = 0; i < first.length; i += 4) {
      output[i] = (first[i] * inverse + second[i] * amount).round();
      output[i + 1] = (first[i + 1] * inverse + second[i + 1] * amount).round();
      output[i + 2] = (first[i + 2] * inverse + second[i + 2] * amount).round();
      output[i + 3] = 255;
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

    try {
      final frames = <Uint8List>[];
      for (var index = 0; index < slideCount; index++) {
        frames.add(await _captureExportSlide(index));
        if (!mounted) return;
        setState(() => _exportProgress = (index + 1) / slideCount * 0.24);
      }

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

      const holdFrames = 13;
      const transitionFrames = 3;
      final total =
          frames.length * holdFrames + (frames.length - 1) * transitionFrames;
      var completed = 0;
      setState(() => _exportStatus = 'MP4 oluşturuluyor…');
      for (var index = 0; index < frames.length; index++) {
        for (var frame = 0; frame < holdFrames; frame++) {
          await FlutterQuickVideoEncoder.appendVideoFrame(frames[index]);
          completed++;
          if (mounted && completed % 4 == 0) {
            setState(() => _exportProgress = 0.24 + completed / total * 0.72);
          }
        }
        if (index < frames.length - 1) {
          for (
            var transition = 1;
            transition <= transitionFrames;
            transition++
          ) {
            final mixed = _blend(
              frames[index],
              frames[index + 1],
              transition / (transitionFrames + 1),
            );
            await FlutterQuickVideoEncoder.appendVideoFrame(mixed);
            completed++;
          }
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFF12100F),
      appBar: AppBar(
        title: const Text('Albüm önizleme'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _toggleAutoPlay,
            tooltip: _autoPlay ? 'Durdur' : 'Otomatik oynat',
            icon: Icon(
              _autoPlay
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
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
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 14),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _current == 0
                                  ? 'Kapak'
                                  : 'Sayfa $_current / ${widget.album.pages.length}',
                              style: const TextStyle(
                                color: Color(0xFF9B8F84),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _exportAndShare,
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('MP4 paylaş'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slideCount,
                    onPageChanged: (index) => setState(() => _current = index),
                    itemBuilder: (context, index) => AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        var delta = 0.0;
                        if (_pageController.hasClients &&
                            _pageController.position.haveDimensions) {
                          delta =
                              (_pageController.page ?? _current.toDouble()) -
                              index;
                        }
                        final angle = delta.clamp(-1.0, 1.0) * -0.16;
                        return Transform(
                          alignment: delta > 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(angle),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 9 / 14,
                            child: index == 0
                                ? AlbumCover(album: widget.album)
                                : AlbumPageCanvas(
                                    page: widget.album.pages[index - 1],
                                    theme: theme,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < slideCount; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: index == _current ? 20 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == _current
                                ? theme.accent
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                ),
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
                        const Text(
                          'Uygulamayı kapatma',
                          style: TextStyle(
                            color: Color(0xFF9B8F84),
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

class _ExportSlide extends StatelessWidget {
  const _ExportSlide({required this.album, required this.index});

  final AlbumModel album;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
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
