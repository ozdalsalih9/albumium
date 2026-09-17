import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../models/social_video_draft.dart';
import '../services/cinematic_soundtrack.dart';
import '../services/platform_album_services.dart';
import '../services/personal_sticker_storage.dart';
import '../services/video_export_support.dart';
import '../themes/theme_image_helper.dart';
import '../widgets/album_cover.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/sticker_packs.dart';

class SocialVideoScreen extends StatefulWidget {
  const SocialVideoScreen({super.key, required this.album});
  final AlbumModel album;
  @override
  State<SocialVideoScreen> createState() => _SocialVideoScreenState();
}

class _SocialVideoScreenState extends State<SocialVideoScreen>
    with SingleTickerProviderStateMixin {
  late final SocialVideoDraft _draft = SocialVideoDraft(widget.album);
  late final AnimationController _play =
      AnimationController(
        vsync: this,
        duration: Duration(seconds: _draft.seconds),
      )..addListener(() {
        if (!_exporting && mounted) {
          setState(
            () => _frame = (_play.value * (_draft.totalFrames - 1)).round(),
          );
        }
      });
  final _captureKey = GlobalKey();
  final _note = TextEditingController();
  VideoExportQuality _quality = VideoExportQuality.fullHd;
  bool _sound = true, _exporting = false, _cancelled = false;
  int _frame = 0;
  @override
  void dispose() {
    _play.dispose();
    _note.dispose();
    super.dispose();
  }

  Widget _preview() => AspectRatio(
    aspectRatio: 9 / 16,
    child: FittedBox(
      fit: BoxFit.contain,
      child: RepaintBoundary(
        key: _captureKey,
        child: SizedBox(
          width: 360,
          height: 640,
          child: SocialVideoFrame(
            album: widget.album,
            draft: _draft,
            frame: _frame,
          ),
        ),
      ),
    ),
  );

  void _change(VoidCallback change) {
    _play.stop();
    setState(() {
      change();
      _frame = 0;
      _play.duration = Duration(seconds: _draft.seconds);
    });
  }

  Future<void> _warmPage(AlbumPageModel page) async {
    for (final e in page.elements) {
      if (!mounted || _cancelled) return;
      if (e.type == AlbumElementType.photo) {
        await _warmImage(themeImageProvider(e.content));
      }
      if (e.type == AlbumElementType.sticker &&
          isAlbumStickerAsset(e.content)) {
        await _warmImage(AssetImage(albumStickerAssetPath(e.content)));
      }
      if (e.type == AlbumElementType.sticker && isPersonalSticker(e.content)) {
        await _warmImage(FileImage(File(personalStickerPath(e.content))));
      }
    }
  }

  Future<void> _warmImage(ImageProvider provider) async {
    Object? failure;
    await precacheImage(
      provider,
      context,
      onError: (error, _) => failure = error,
    );
    if (failure != null) throw StateError('Cannot load export image: $failure');
  }

  Future<void> _export() async {
    if (!_draft.canExport || _exporting) return;
    _play.stop();
    setState(() {
      _exporting = true;
      _cancelled = false;
      _frame = 0;
    });
    File? output;
    bool encoderAttempted = false;
    Object? failure;
    try {
      final folder = await getTemporaryDirectory();
      await cleanupStaleAlbumiumExports(folder);
      output = File(
        '${folder.path}/${albumiumExportFilename(title: widget.album.title, createdAt: DateTime.now(), extension: 'mp4')}',
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _cancelled) throw const _SocialExportCancelled();
      if (widget.album.coverPhotoPath case final path?) {
        await _warmImage(themeImageProvider(path, cacheWidth: 1200));
      }
      if (_draft.coverPageId case final id?) {
        await _warmPage(_draft.pageById(id));
      }
      await GoogleFonts.pendingFonts();
      encoderAttempted = true;
      await FlutterQuickVideoEncoder.setup(
        width: _quality.width,
        height: _quality.height,
        fps: 30,
        videoBitrate: _quality.videoBitrate,
        profileLevel: ProfileLevel.highAutoLevel,
        audioChannels: _sound ? 2 : 0,
        audioBitrate: _sound ? 128000 : 0,
        sampleRate: _sound ? 48000 : 0,
        filepath: output.path,
      );
      final soundtrack = _draft.soundtrack;
      var previousShot = -1;
      for (var frame = 0; frame < _draft.totalFrames; frame++) {
        if (!mounted || _cancelled) throw const _SocialExportCancelled();
        final shot = _draft.shotAt(frame);
        if (shot.index != previousShot) {
          if (shot.pageId case final id?) {
            await _warmPage(_draft.pageById(id));
          }
          previousShot = shot.index;
        }
        if (!mounted || _cancelled) throw const _SocialExportCancelled();
        setState(() => _frame = frame);
        await WidgetsBinding.instance.endOfFrame;
        // New page/font decodes must finish before reading the first frame.
        if (frame == shot.start) {
          await GoogleFonts.pendingFonts();
          await Future<void>.delayed(const Duration(milliseconds: 16));
          await WidgetsBinding.instance.endOfFrame;
        }
        if (!mounted || _cancelled) throw const _SocialExportCancelled();
        final boundary =
            _captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _quality.width / 360);
        ByteData? data;
        try {
          data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        } finally {
          image.dispose();
        }
        if (data == null) throw StateError('Frame capture failed');
        await FlutterQuickVideoEncoder.appendVideoFrame(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        if (_sound) {
          await FlutterQuickVideoEncoder.appendAudioFrame(
            CinematicSoundtrack.pcmFrame(
              storyboard: soundtrack,
              frameIndex: frame,
              fps: 30,
            ),
          );
        }
      }
      await FlutterQuickVideoEncoder.finish();
      encoderAttempted = false;
      if (!mounted || _cancelled) throw const _SocialExportCancelled();
      if (!await output.exists() || await output.length() == 0) {
        throw StateError('Empty video');
      }
      if (!mounted) return;
    } catch (error) {
      failure = error;
      if (encoderAttempted) {
        try {
          await FlutterQuickVideoEncoder.finish();
        } catch (_) {}
      }
      if (output != null && await output.exists()) {
        try {
          await output.delete();
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _frame = 0;
        });
      }
    }
    if (mounted && !_cancelled && failure == null && output != null) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(output.path, mimeType: 'video/mp4')],
            title: widget.album.title,
            sharePositionOrigin: albumShareOrigin(context),
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('Paylaşım açılamadı. Tekrar deneyebilirsin.'),
              ),
            ),
          );
        }
      }
    }
    if (!mounted ||
        _cancelled ||
        failure is _SocialExportCancelled ||
        failure == null) {
      return;
    }
    if (_quality == VideoExportQuality.fullHd) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('Video hazırlanamadı')),
          content: Text(
            context.tr(
              'Aynı sayfaları ve kurguyu 720p ile yeniden deneyebilirsin.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Vazgeç')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('720p ile yeniden dene')),
            ),
          ],
        ),
      );
      if (retry == true && mounted) {
        setState(() => _quality = VideoExportQuality.balanced);
        await _export();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Video hazırlanamadı. Tasarımın korundu; tekrar deneyebilirsin.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_exporting,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _exporting) setState(() => _cancelled = true);
    },
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('Kısa video stüdyosu'))),
      body: SafeArea(
        child: _exporting
            ? Column(
                children: [
                  Expanded(child: Center(child: _preview())),
                  LinearProgressIndicator(value: _frame / _draft.totalFrames),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${(_frame / _draft.totalFrames * 100).round()}%',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _cancelled = true),
                    child: Text(
                      context.tr(_cancelled ? 'İptal ediliyor…' : 'İptal et'),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SizedBox(height: 320, child: Center(child: _preview())),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        key: const ValueKey('social-preview-play'),
                        tooltip: context.tr('Önizle'),
                        onPressed: !_draft.canExport
                            ? null
                            : () => setState(() {
                                if (_play.isAnimating) {
                                  _play.stop();
                                } else {
                                  _play.forward(from: 0);
                                }
                              }),
                        icon: Icon(
                          _play.isAnimating ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      Text('${_draft.seconds} ${context.tr('saniye')}'),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final template in SocialVideoTemplate.values)
                        ChoiceChip(
                          label: Text(context.tr(template.title)),
                          selected: _draft.template == template,
                          onSelected: (_) =>
                              _change(() => _draft.template = template),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final seconds in [15, 30])
                        ChoiceChip(
                          label: Text('$seconds ${context.tr('saniye')}'),
                          selected: _draft.seconds == seconds,
                          onSelected: (_) =>
                              _change(() => _draft.seconds = seconds),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final source in SocialVideoSource.values)
                        ChoiceChip(
                          label: Text(
                            context.tr(
                              source == SocialVideoSource.pages
                                  ? 'Albüm sayfaları'
                                  : 'Fotoğraflar',
                            ),
                          ),
                          selected: _draft.source == source,
                          onSelected: _draft.source == source
                              ? null
                              : (_) => _change(() {
                                  _draft.selectSource(source);
                                  _orderedPages
                                    ..clear()
                                    ..addAll(_draft.availablePages);
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_draft.source),
                    initialValue: 'album-cover',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Video kapağı'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'album-cover',
                        child: Text(context.tr('Albüm kapağı')),
                      ),
                      for (var i = 0; i < _draft.availablePages.length; i++)
                        DropdownMenuItem(
                          value: _draft.availablePages[i].id,
                          child: Text(
                            context.tr(
                              _draft.source == SocialVideoSource.pages
                                  ? 'Sayfa {number}'
                                  : 'Fotoğraf {number}',
                              values: {'number': i + 1},
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) => _change(
                      () => _draft.coverPageId = value == 'album-cover'
                          ? null
                          : value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(
                      'İçeriği seç ve sıralamak için sürükle. En fazla 20 öğe.',
                    ),
                  ),
                  SizedBox(
                    height: 230,
                    child: ReorderableListView.builder(
                      itemCount: _draft.availablePages.length,
                      onReorder: (from, to) => _change(() {
                        // Reorder a view-only list; never reorder the user's saved album.
                        if (to > from) to--;
                        final page = _orderedPages.removeAt(from);
                        _orderedPages.insert(to, page);
                        final selected = _draft.pageIds.toSet();
                        _draft.pageIds
                          ..clear()
                          ..addAll(
                            _orderedPages
                                .where((p) => selected.contains(p.id))
                                .map((p) => p.id),
                          );
                      }),
                      itemBuilder: (context, index) {
                        final page = _orderedPages[index];
                        final original =
                            _draft.availablePages.indexWhere(
                              (p) => p.id == page.id,
                            ) +
                            1;
                        return CheckboxListTile(
                          key: ValueKey(page.id),
                          title: Text(
                            context.tr(
                              _draft.source == SocialVideoSource.pages
                                  ? 'Sayfa {number}'
                                  : 'Fotoğraf {number}',
                              values: {'number': original},
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(right: 48),
                          value: _draft.pageIds.contains(page.id),
                          onChanged: (selected) => _change(() {
                            final ids = _draft.pageIds.toSet();
                            if (selected == true) {
                              ids.add(page.id);
                            } else {
                              ids.remove(page.id);
                            }
                            _draft.pageIds
                              ..clear()
                              ..addAll(
                                _orderedPages
                                    .where((p) => ids.contains(p.id))
                                    .map((p) => p.id),
                              );
                          }),
                        );
                      },
                    ),
                  ),
                  if (!_draft.canExport)
                    Text(
                      context.tr('Devam etmek için 1–20 öğe seç.'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  TextField(
                    controller: _note,
                    maxLength: 120,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: context.tr('Kapanış notu'),
                    ),
                    onChanged: (value) =>
                        _change(() => _draft.closingNote = value),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final quality in VideoExportQuality.values)
                        ChoiceChip(
                          label: Text('${quality.width}p'),
                          selected: _quality == quality,
                          onSelected: (_) => _change(() => _quality = quality),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('Müzik')),
                    value: _sound,
                    onChanged: (v) => setState(() => _sound = v),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('social-export'),
                    onPressed: _draft.canExport ? _export : null,
                    icon: const Icon(Icons.ios_share),
                    label: Text(context.tr('Videoyu hazırla ve paylaş')),
                  ),
                ],
              ),
      ),
    ),
  );
  late final List<AlbumPageModel> _orderedPages = List.of(
    _draft.availablePages,
  );
}

class _SocialExportCancelled implements Exception {
  const _SocialExportCancelled();
}

/// Preview and encoder use this exact 360x640 composition. Page content is
/// contained, never cropped; titles stay inside the social safe area.
class SocialVideoFrame extends StatelessWidget {
  const SocialVideoFrame({
    super.key,
    required this.album,
    required this.draft,
    required this.frame,
  });
  final AlbumModel album;
  final SocialVideoDraft draft;
  final int frame;
  @override
  Widget build(BuildContext context) {
    if (!draft.canExport) return const ColoredBox(color: Color(0xFFF5EFE6));
    final shot = draft.shotAt(frame);
    final progress = ((frame - shot.start) / shot.frames).clamp(0.0, 1.0);
    final ending = shot.pageId == null && shot.index > 0;
    final accent = switch (draft.template) {
      SocialVideoTemplate.summer => const Color(0xFF95613B),
      SocialVideoTemplate.together => const Color(0xFFA04763),
      SocialVideoTemplate.year => const Color(0xFF28435B),
    };
    final pageId = shot.index == 0 ? draft.coverPageId : shot.pageId;
    final title = ending
        ? (draft.closingNote.trim().isEmpty
              ? context.tr('Bazı anlar bir albümü hak eder.')
              : draft.closingNote.trim())
        : shot.index == 0
        ? album.title
        : context.tr(draft.template.title);
    Widget artwork;
    if (pageId != null) {
      artwork = AspectRatio(
        aspectRatio: 5 / 7,
        child: AlbumPageCanvas(
          page: draft.pageById(pageId),
          theme: themeById(album.themeId),
          showPageNumber: false,
        ),
      );
    } else {
      artwork = AspectRatio(
        aspectRatio: 5 / 7,
        child: AlbumCover(album: album, showTitle: false),
      );
    }
    return MediaQuery.withNoTextScaling(
      child: ColoredBox(
        color: ending ? accent : const Color(0xFFF5EFE6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 60, 46, 82),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'albumium',
                style: TextStyle(
                  fontFamily: 'AlbumiumDisplay',
                  fontSize: 20,
                  color: ending ? Colors.white : accent,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: ending ? 116 : 65,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 288,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'AlbumiumSans',
                        fontSize: ending ? 20 : 19,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: ending ? Colors.white : accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Opacity(
                  opacity: ((frame - shot.start) / 6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(
                      (1 - progress) *
                          (draft.template == SocialVideoTemplate.year ? 0 : 5),
                      (1 - progress) * 5,
                    ),
                    child: Transform.scale(
                      scale: .96 + progress * .025,
                      child: Center(child: artwork),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ending
                    ? context.tr('Anılarına yeniden dokun')
                    : context.tr(draft.template.title),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'AlbumiumSans',
                  fontSize: 11,
                  color: ending ? Colors.white : accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
