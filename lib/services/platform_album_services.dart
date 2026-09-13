import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android and iOS keep the same channel contract; UI never calls a platform
/// segmentation implementation directly.
class StickerCutoutService {
  static const _channel = MethodChannel('com.albumium.albumium/memories');
  static Future<String?> cutout(String path) =>
      _channel.invokeMethod<String>('segment', {'path': path});
}

class AlbumAppSupportService {
  static const _channel = MethodChannel('com.albumium.albumium/app_support');
  static Future<void> openPrivacyPolicy() =>
      _channel.invokeMethod<void>('openPrivacyPolicy');
}

/// iPad requires a non-empty popover anchor inside the presenting view.
Rect albumShareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize && !box.size.isEmpty) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return Rect.fromCenter(
    center: MediaQuery.sizeOf(context).center(Offset.zero),
    width: 1,
    height: 1,
  );
}
