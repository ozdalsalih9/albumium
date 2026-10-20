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
import '../services/albumium_entitlements.dart';
import '../widgets/social_video_frame.dart';
export '../widgets/social_video_frame.dart' show SocialVideoFrame;
import '../services/feature_entitlements.dart';
import '../services/monetization_policy.dart';
import '../services/platform_album_services.dart';
import '../services/personal_sticker_storage.dart';
import '../services/video_export_support.dart';
import '../themes/theme_image_helper.dart';
import '../widgets/export_delivery.dart';
import '../widgets/feature_unlock_sheet.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/sticker_packs.dart';

class SocialVideoScreen extends StatefulWidget {
  const SocialVideoScreen({super.key, required this.album, this.entitlements});
  final AlbumModel album;

  /// Left null outside tests: the screen then reads the app-wide ledger.
  final FeatureEntitlements? entitlements;
  @override
  State<SocialVideoScreen> createState() => _SocialVideoScreenState();
}

class _SocialVideoScreenState extends State<SocialVideoScreen>
    with SingleTickerProviderStateMixin {
  late final SocialVideoDraft _draft = SocialVideoDraft(widget.album);
  late final AnimationController _play =
      AnimationController(vsync: this, duration: _draft.duration)
        ..addListener(() {
          if (!_exporting && mounted) {
            setState(
              () => _frame = (_play.value * (_draft.totalFrames - 1)).round(),
            );
          }
        });
  final _captureKey = GlobalKey();
  final _note = TextEditingController();
  late final FeatureEntitlements _features =
      widget.entitlements ?? AlbumiumEntitlements.instance.features;
  // Full HD is paid for, so the screen opens on the quality everyone has —
  // unless it was already bought, in which case starting lower would punish
  // the person who paid.
  late VideoExportQuality _quality =
      _features.isUnlocked(AlbumiumFeature.fullHdExport)
      ? VideoExportQuality.fullHd
      : VideoExportQuality.balanced;
  bool _exporting = false, _cancelled = false;
  int _frame = 0;

  bool get _fullHdLocked => !_features.isUnlocked(AlbumiumFeature.fullHdExport);

  /// Offers the unlock when Full HD is picked and not yet available.
  Future<void> _selectQuality(VideoExportQuality quality) async {
    if (quality != VideoExportQuality.fullHd || !_fullHdLocked) {
      _change(() => _quality = quality);
      return;
    }
    final unlocked = await showFeatureUnlockSheet(
      context,
      feature: AlbumiumFeature.fullHdExport,
      entitlements: _features,
      offerAd: true,
      title: 'Full HD videoyu aç',
      description:
          'Albümünü 1080p paylaş; yazılar ve fotoğraflar çok daha net görünür.',
      bullets: const [
        (
          Icons.play_circle_outline_rounded,
          'Bir reklam izle, bu videoyu 1080p dışa aktar.',
        ),
        (
          Icons.lock_open_rounded,
          'Satın alırsan her videoda 1080p açık kalır.',
        ),
        (Icons.hd_outlined, 'Tek seferlik satın alma.'),
      ],
    );
    if (!unlocked || !mounted) return;
    _change(() => _quality = VideoExportQuality.fullHd);
  }

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
      _play.duration = _draft.duration;
    });
  }

  Future<void> _warmPage(AlbumPageModel page) async {
    for (final e in page.elements) {
      if (!mounted || _cancelled) return;
      if (e.type == AlbumElementType.photo && e.content.isNotEmpty) {
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
    if (MonetizationPolicy.rewardedOnly &&
        _quality == VideoExportQuality.fullHd &&
        _fullHdLocked) {
      await _selectQuality(VideoExportQuality.fullHd);
      if (!mounted || _fullHdLocked || _exporting) return;
    }
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
      if (themeById(widget.album.themeId).coverAsset case final asset?) {
        await _warmImage(themeImageProvider(asset));
      }
      if (_draft.coverPageId case final id?) {
        await _warmPage(_draft.pageById(id));
      }
      await GoogleFonts.pendingFonts();
      await FlutterQuickVideoEncoder.setLogLevel(LogLevel.error);
      encoderAttempted = true;
      await FlutterQuickVideoEncoder.setup(
        width: _quality.width,
        height: _quality.height,
        fps: 30,
        videoBitrate: _quality.videoBitrate,
        profileLevel: ProfileLevel.highAutoLevel,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: output.path,
      );
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
      }
      await FlutterQuickVideoEncoder.finish();
      encoderAttempted = false;
      if (!mounted || _cancelled) throw const _SocialExportCancelled();
      if (!await output.exists() || await output.length() == 0) {
        throw StateError('Empty video');
      }
      // A watched ad buys exactly this one export; a purchase has nothing to
      // spend, so this is a no-op for someone who paid.
      if (_quality == VideoExportQuality.fullHd) {
        _features.consumeGrant(AlbumiumFeature.fullHdExport);
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
        final shareParams = ShareParams(
          files: [XFile(output.path, mimeType: 'video/mp4')],
          title: widget.album.title,
          sharePositionOrigin: albumShareOrigin(context),
        );
        final choice = await showExportDeliverySheet(context, video: true);
        if (!mounted) return;
        switch (choice) {
          case ExportDelivery.saveToGallery:
            await saveExportsToGallery(
              context,
              [output.path],
              video: true,
              onShare: () {
                SharePlus.instance.share(shareParams);
              },
            );
          case ExportDelivery.share:
            await SharePlus.instance.share(shareParams);
          case null:
            break;
        }
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

  String _time(double seconds) {
    final whole = seconds.floor();
    return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
  }

  void _seek(double value) {
    _play.stop();
    setState(() {
      _frame = value.round();
      _play.value = _frame / (_draft.totalFrames - 1);
    });
  }

  Widget _section(String number, String title, String subtitle, Widget child) =>
      Padding(
        padding: const EdgeInsets.only(top: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(title),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(subtitle),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _styles() => SizedBox(
    height: 124,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: SocialVideoTemplate.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final style = SocialVideoTemplate.values[index];
        final palette = socialVideoPalette(style);
        final selected = _draft.template == style;
        return Semantics(
          selected: selected,
          button: true,
          label: context.tr(style.title),
          child: InkWell(
            onTap: () => _change(() => _draft.template = style),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 112,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? palette.ink : palette.desk,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Transform.rotate(
                        angle: -.08,
                        child: Container(
                          width: 40,
                          height: 53,
                          decoration: BoxDecoration(
                            color: palette.desk,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: palette.ink.withValues(alpha: .15),
                                blurRadius: 8,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            selected
                                ? Icons.check_rounded
                                : Icons.auto_stories_outlined,
                            color: palette.ink,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(style.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _timeline() => SizedBox(
    height: 172,
    child: ReorderableListView.builder(
      key: const ValueKey('social-timeline'),
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      itemCount: _orderedPages.length,
      onReorder: (from, to) => _change(() {
        if (to > from) to--;
        _orderedPages.insert(to, _orderedPages.removeAt(from));
        _syncSelection(_draft.pageIds.toSet());
      }),
      itemBuilder: (context, index) {
        final page = _orderedPages[index];
        final selected = _draft.pageIds.contains(page.id);
        final number =
            _draft.availablePages.indexWhere((p) => p.id == page.id) + 1;
        return Container(
          key: ValueKey(page.id),
          width: 102,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _change(() {
                    final ids = _draft.pageIds.toSet();
                    selected ? ids.remove(page.id) : ids.add(page.id);
                    _syncSelection(ids);
                  }),
                  child: Semantics(
                    label: context.tr(
                      _draft.source == SocialVideoSource.pages
                          ? 'Sayfa {number}'
                          : 'Fotoğraf {number}',
                      values: {'number': number},
                    ),
                    checked: selected,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Opacity(
                            opacity: selected ? 1 : .35,
                            child: AspectRatio(
                              aspectRatio: 5 / 7,
                              child: IgnorePointer(
                                child: AlbumPageCanvas(
                                  page: page,
                                  theme: themeById(widget.album.themeId),
                                  showPageNumber: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        number.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.drag_indicator_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  void _syncSelection(Set<String> ids) {
    _draft.pageIds
      ..clear()
      ..addAll(_orderedPages.where((p) => ids.contains(p.id)).map((p) => p.id));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_exporting,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _exporting) setState(() => _cancelled = true);
    },
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('Video atölyesi'))),
      bottomNavigationBar: _exporting
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: FilledButton.icon(
                  key: const ValueKey('social-export'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _draft.canExport ? _export : null,
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: Text(context.tr('Videoyu oluştur')),
                ),
              ),
            ),
      body: SafeArea(
        child: _exporting
            ? Column(
                children: [
                  Expanded(child: Center(child: _preview())),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          context.tr('Anıların videoya dönüşüyor…'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (_frame + 1) / _draft.totalFrames,
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${((_frame + 1) / _draft.totalFrames * 100).round()}%',
                        ),
                        TextButton(
                          onPressed: _cancelled
                              ? null
                              : () => setState(() => _cancelled = true),
                          child: Text(
                            context.tr(
                              _cancelled ? 'İptal ediliyor…' : 'İptal et',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    context.tr('Sayfa sayfa, senin hikâyen.'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'AlbumiumDisplay',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('Albümün kadar uzun. Kendi ritminde.'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height < 650
                              ? 250
                              : 340,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _preview(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              key: const ValueKey('social-preview-play'),
                              tooltip: context.tr(
                                _play.isAnimating ? 'Duraklat' : 'Önizle',
                              ),
                              onPressed: !_draft.canExport
                                  ? null
                                  : () => setState(() {
                                      if (_play.isAnimating) {
                                        _play.stop();
                                      } else {
                                        _play.forward(
                                          from: _frame >= _draft.totalFrames - 1
                                              ? 0
                                              : _frame /
                                                    (_draft.totalFrames - 1),
                                        );
                                      }
                                    }),
                              icon: Icon(
                                _play.isAnimating
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                key: const ValueKey('social-scrubber'),
                                min: 0,
                                max: (_draft.totalFrames - 1).toDouble(),
                                value: _frame.toDouble(),
                                onChanged: _draft.canExport ? _seek : null,
                                semanticFormatterCallback: (v) =>
                                    _time(v / SocialVideoDraft.fps),
                              ),
                            ),
                            Text(
                              '${_time(_frame / SocialVideoDraft.fps)} / ${_time(_draft.seconds)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              context.tr(
                                '{count} sayfa',
                                values: {'count': _draft.pageIds.length},
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              context.tr('9:16 · Sessiz video'),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _section(
                    '01',
                    'Görünüm',
                    'Işığı ve kâğıdın hissini seç.',
                    _styles(),
                  ),
                  _section(
                    '02',
                    'Ritim',
                    'Süre, seçtiğin sayfa sayısına göre otomatik ayarlanır.',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final pace in SocialVideoPace.values)
                          ChoiceChip(
                            key: ValueKey('social-pace-${pace.name}'),
                            label: Text(context.tr(pace.title)),
                            selected: _draft.pace == pace,
                            onSelected: (_) =>
                                _change(() => _draft.pace = pace),
                          ),
                      ],
                    ),
                  ),
                  _section(
                    '03',
                    'Hikâyenin sırası',
                    'Eklemek için dokun, sıralamak için tutamacı sürükle.',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                        const SizedBox(height: 14),
                        if (_orderedPages.isNotEmpty) _timeline(),
                        if (!_draft.canExport)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              context.tr('Devam etmek için en az bir öğe seç.'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_draft.source),
                          initialValue: 'album-cover',
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.tr('Video kapağı'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'album-cover',
                              child: Text(context.tr('Albüm kapağı')),
                            ),
                            for (
                              var i = 0;
                              i < _draft.availablePages.length;
                              i++
                            )
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
                      ],
                    ),
                  ),
                  _section(
                    '04',
                    'Son dokunuş',
                    'Bir kapanış notuyla hikâyeyi tamamla.',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _note,
                          maxLength: 120,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: context.tr('Kapanış notu'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: (value) =>
                              _change(() => _draft.closingNote = value),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final quality in VideoExportQuality.values)
                              ChoiceChip(
                                key: ValueKey(
                                  'social-quality-${quality.width}',
                                ),
                                avatar:
                                    quality == VideoExportQuality.fullHd &&
                                        _fullHdLocked
                                    ? const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 15,
                                      )
                                    : null,
                                label: Text('${quality.width}p'),
                                selected: _quality == quality,
                                onSelected: (_) => _selectQuality(quality),
                              ),
                          ],
                        ),
                      ],
                    ),
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
