import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// User-selected document providers own cloud upload and account authentication.
/// Completion means the provider accepted the file, not that it has synced.
class AlbumBackupService {
  static const channel = MethodChannel('com.albumium.albumium/album_backup');
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static bool get usesICloud => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<bool> save(String path) async =>
      await channel.invokeMethod<bool>('save', {'path': path}) ?? false;

  /// A bounded local copy. Null means the user dismissed the picker.
  static Future<String?> pick() => channel.invokeMethod<String>('pick');
}
