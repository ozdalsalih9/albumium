import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../widgets/photo_crop_editor.dart';
import 'album_storage.dart';
import 'photo_selection_service.dart';

Future<bool> pickPhotoIntoSlot(
  BuildContext context,
  AlbumElementModel slot,
) async {
  if (slot.locked) return false;
  final files = await PhotoSelectionService.pick(context);
  if (files.isEmpty || !context.mounted) return false;
  try {
    final path = await AlbumStorage.instance.importImage(files.first);
    final info = await loadAlbumPhoto(path);
    info.dispose();
    if (!context.mounted) return false;
    slot.content = path;
    slot.photoCrop = null;
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Fotoğraf açılamadı. Lütfen tekrar dene.')),
        ),
      );
    }
    return false;
  }
}
