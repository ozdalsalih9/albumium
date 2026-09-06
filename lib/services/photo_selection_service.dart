import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/albumium_localizations.dart';

abstract final class PhotoSelectionService {
  static const explanationKey = 'albumium.photo_picker_explained.v1';
  static bool _busy = false;

  static void configure() {
    final platform = ImagePickerPlatform.instance;
    if (platform is ImagePickerAndroid) platform.useAndroidPhotoPicker = true;
  }

  static Future<List<XFile>> pick(
    BuildContext context, {
    bool multiple = false,
  }) async {
    if (_busy) return [];
    _busy = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!context.mounted) return [];
      if (!(preferences.getBool(explanationKey) ?? false)) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            title: Text(context.tr('Fotoğraflarını seç')),
            content: Text(
              context.tr(
                'Bir sonraki ekranda albümüne eklemek istediğin fotoğrafları seç. Yalnızca seçtiklerin cihazına kopyalanır; tüm galerine erişim izni istemiyoruz.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('Vazgeç')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('Galeriyi aç')),
              ),
            ],
          ),
        );
        if (proceed != true || !context.mounted) return [];
        await preferences.setBool(explanationKey, true);
      }
      if (!context.mounted) return [];
      configure();
      final picker = ImagePicker();
      if (multiple) {
        final files = await picker.pickMultiImage(
          limit: 20,
          imageQuality: 92,
          maxWidth: 2600,
          requestFullMetadata: false,
        );
        return files.take(20).toList();
      }
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 94,
        maxWidth: 2800,
        requestFullMetadata: false,
      );
      return file == null ? [] : [file];
    } on PlatformException catch (error) {
      if (context.mounted) {
        final denied =
            error.code.toLowerCase().contains('denied') ||
            error.code.toLowerCase().contains('restricted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                denied
                    ? 'Fotoğraf erişimi verilmedi. Cihaz ayarlarından erişimi kontrol edip tekrar deneyebilirsin.'
                    : 'Galeri açılamadı. Lütfen tekrar dene.',
              ),
            ),
          ),
        );
      }
      return [];
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Galeri açılamadı. Lütfen tekrar dene.')),
          ),
        );
      }
      return [];
    } finally {
      _busy = false;
    }
  }
}
