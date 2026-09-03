import 'dart:async';

import 'package:flutter/services.dart';

typedef IncomingAlbumPackageCallback = FutureOr<void> Function(String path);
typedef IncomingAlbumPackageErrorCallback =
    FutureOr<void> Function(String message);

class AlbumIncomingIntentService {
  AlbumIncomingIntentService({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('com.albumium.albumium/incoming_album_package');

  final MethodChannel _channel;
  bool _started = false;

  Future<void> start({
    required IncomingAlbumPackageCallback onPackage,
    required IncomingAlbumPackageErrorCallback onError,
  }) async {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'albumPackageReceived':
          final path = call.arguments;
          if (path is String && path.isNotEmpty) await onPackage(path);
        case 'albumPackageReceiveError':
          await onError('${call.arguments ?? ''}');
      }
    });
    try {
      final initialPath = await _channel.invokeMethod<String>('startListening');
      if (initialPath != null && initialPath.isNotEmpty) {
        await onPackage(initialPath);
      }
    } on MissingPluginException {
      // Non-Android platforms and widget tests have no incoming intent bridge.
    }
  }

  Future<void> dispose() async {
    _started = false;
    _channel.setMethodCallHandler(null);
  }
}
