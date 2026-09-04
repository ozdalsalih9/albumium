import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../services/album_package_service.dart';
import '../services/album_storage.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover.dart';
import 'preview_screen.dart';

class AlbumImportScreen extends StatefulWidget {
  const AlbumImportScreen({
    super.key,
    required this.packagePath,
    this.packageService,
    this.initialPreview,
  });

  final String packagePath;
  final AlbumPackageService? packageService;
  final AlbumPackagePreview? initialPreview;

  @override
  State<AlbumImportScreen> createState() => _AlbumImportScreenState();
}

class _AlbumImportScreenState extends State<AlbumImportScreen> {
  late final AlbumPackageService _service;
  late final Future<AlbumPackagePreview> _previewFuture;
  AlbumPackagePreview? _preview;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _service = widget.packageService ?? AlbumPackageService();
    final initialPreview = widget.initialPreview;
    if (initialPreview != null) {
      _preview = initialPreview;
      _previewFuture = SynchronousFuture(initialPreview);
    } else {
      _previewFuture = _service.openPackage(widget.packagePath).then((preview) {
        _preview = preview;
        return preview;
      });
    }
  }

  @override
  void dispose() {
    final preview = _preview;
    if (preview != null) preview.dispose();
    super.dispose();
  }

  Future<void> _view(AlbumPackagePreview preview) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PreviewScreen(album: preview.album)),
    );
  }

  Future<void> _import(AlbumPackagePreview preview) async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final album = await _service.importCopy(preview);
      await AlbumStorage.instance.saveAlbum(album);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Albüm içe aktarıldı'))),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Albüm içe aktarılamadı: {error}',
              values: {'error': _packageErrorText(context, error)},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Paylaşılan Albüm'))),
      body: FutureBuilder<AlbumPackagePreview>(
        future: _previewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.tr('Albüm paketi açılıyor…')),
                ],
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 54,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('Albüm paketi açılamadı'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _packageErrorText(context, snapshot.error),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr('Kapat')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final preview = snapshot.data!;
          final album = preview.album;
          final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
          final cover = SizedBox(
            width: tablet ? 230 : 174,
            height: tablet ? 338 : 255,
            child: AlbumCover(album: album),
          );
          final details = _ImportDetails(
            preview: preview,
            importing: _importing,
            onView: () => _view(preview),
            onImport: () => _import(preview),
          );

          return DecoratedBox(
            decoration: BoxDecoration(color: colors.background),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: tablet ? 40 : 22,
                  vertical: tablet ? 34 : 22,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: tablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              cover,
                              const SizedBox(width: 38),
                              Expanded(child: details),
                            ],
                          )
                        : Column(
                            children: [
                              cover,
                              const SizedBox(height: 26),
                              details,
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImportDetails extends StatelessWidget {
  const _ImportDetails({
    required this.preview,
    required this.importing,
    required this.onView,
    required this.onImport,
  });

  final AlbumPackagePreview preview;
  final bool importing;
  final VoidCallback onView;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final album = preview.album;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          album.title,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            '{count} sayfa · {size} · {media} fotoğraf',
            values: {
              'count': album.pages.length,
              'size': AlbumPackageService.formatBytes(preview.packageBytes),
              'media': preview.mediaCount,
            },
          ),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      'Albümü görüntüle veya düzenlemek için koleksiyonuna bir kopyasını ekle.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          key: const ValueKey('view_shared_album'),
          onPressed: importing ? null : onView,
          icon: const Icon(Icons.menu_book_rounded),
          label: Text(context.tr('Salt okunur görüntüle')),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const ValueKey('import_shared_album'),
          onPressed: importing ? null : onImport,
          icon: importing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_done_rounded),
          label: Text(
            importing
                ? context.tr('İçe aktarılıyor…')
                : context.tr('Kopya olarak içe aktar'),
          ),
        ),
      ],
    );
  }
}

String _packageErrorText(BuildContext context, Object? error) {
  if (error is AlbumPackageException) {
    return switch (error.failure) {
      AlbumPackageFailure.missingSource => context.tr(
        'Albümde kullanılan bir fotoğraf bulunamadı.',
      ),
      AlbumPackageFailure.tooLarge => context.tr(
        'Albüm paketi izin verilen boyutu aşıyor.',
      ),
      AlbumPackageFailure.invalidArchive => context.tr(
        'Dosya geçerli bir Albumium albümü değil.',
      ),
      AlbumPackageFailure.unsupportedVersion => context.tr(
        'Bu albüm daha yeni bir Albumium sürümü gerektiriyor.',
      ),
      AlbumPackageFailure.unsafeContent => context.tr(
        'Albüm paketi güvenli olmayan içerik barındırıyor.',
      ),
      AlbumPackageFailure.corruptMedia => context.tr(
        'Albümdeki fotoğraflardan biri bozuk veya değiştirilmiş.',
      ),
    };
  }
  return context.tr('Beklenmeyen bir dosya hatası oluştu.');
}
