import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../l10n/albumium_localizations.dart';

/// What to do with a finished photo or video export.
enum ExportDelivery { saveToGallery, share }

/// Asks whether a finished export should be saved to the device gallery or
/// handed to the share sheet. Returns null when the sheet is dismissed.
Future<ExportDelivery?> showExportDeliverySheet(
  BuildContext context, {
  required bool video,
  int count = 1,
}) {
  final saveHint = video
      ? context.tr('Videoyu telefonunun galerisine indir')
      : count > 1
      ? context.tr(
          '{count} görseli telefonunun galerisine indir',
          values: {'count': count},
        )
      : context.tr('Görseli telefonunun galerisine indir');

  return showModalBottomSheet<ExportDelivery>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                video ? context.tr('Video hazır') : context.tr('Görsel hazır'),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ListTile(
              key: const ValueKey('export-save-gallery'),
              leading: const Icon(Icons.download_rounded),
              title: Text(context.tr('Galeriye kaydet')),
              subtitle: Text(saveHint),
              onTap: () =>
                  Navigator.pop(sheetContext, ExportDelivery.saveToGallery),
            ),
            ListTile(
              key: const ValueKey('export-share'),
              leading: const Icon(Icons.ios_share_rounded),
              title: Text(context.tr('Paylaş')),
              subtitle: Text(context.tr('Uygulamalara veya kişilere gönder')),
              onTap: () => Navigator.pop(sheetContext, ExportDelivery.share),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Copies finished export files into the device gallery and reports the
/// outcome in a snack bar. [onShare], when given, is offered as a follow-up
/// action so a saved export can still be sent on without exporting again.
Future<void> saveExportsToGallery(
  BuildContext context,
  List<String> paths, {
  required bool video,
  VoidCallback? onShare,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final localizations =
      AlbumiumLocalizations.maybeOf(context) ??
      const AlbumiumLocalizations(Locale('tr'));

  void report(String message, {bool offerShare = false}) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        // A snack bar with an action persists by default; this one is only a
        // confirmation, so let it time out while leaving time to tap Share.
        persist: false,
        duration: const Duration(seconds: 6),
        action: offerShare && onShare != null
            ? SnackBarAction(
                label: localizations.text('Paylaş'),
                onPressed: onShare,
              )
            : null,
      ),
    );
  }

  final permissionMessage = localizations.text(
    'Galeriye kaydetmek için izin vermen gerekiyor.',
  );
  try {
    // Android 10 and below ask for write access once; newer Android and iOS
    // save through the system without a broad gallery permission.
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      report(permissionMessage);
      return;
    }
    for (final path in paths) {
      if (video) {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }
    }
    report(
      video
          ? localizations.text('Video galeriye kaydedildi.')
          : paths.length > 1
          ? localizations.text(
              '{count} görsel galeriye kaydedildi.',
              values: {'count': paths.length},
            )
          : localizations.text('Görsel galeriye kaydedildi.'),
      offerShare: true,
    );
  } on GalException catch (error) {
    report(switch (error.type) {
      GalExceptionType.accessDenied => permissionMessage,
      GalExceptionType.notEnoughSpace => localizations.text(
        'Telefonda yeterli boş alan yok.',
      ),
      _ => localizations.text('Galeriye kaydedilemedi. Tekrar dene.'),
    });
  }
}
