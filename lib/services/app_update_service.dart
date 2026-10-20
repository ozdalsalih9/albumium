import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class StoreUpdate {
  const StoreUpdate({required this.id, this.version, this.storeUrl});
  final String id;
  final String? version;
  final String? storeUrl;
}

/// Only released store versions count. No Play Store HTML scraping or server
/// configuration is needed: Play uses its availability API, Apple uses lookup.
class AppUpdateService {
  AppUpdateService({
    MethodChannel? channel,
    String? platform,
    Future<Map<String, dynamic>> Function(Uri)? lookup,
    DateTime Function()? now,
  }) : _channel =
           channel ?? const MethodChannel('com.albumium.albumium/app_updates'),
       _platform = platform ?? Platform.operatingSystem,
       _lookup = lookup ?? _loadLookup,
       _now = now ?? DateTime.now;

  static final instance = AppUpdateService();
  final MethodChannel _channel;
  final String _platform;
  final Future<Map<String, dynamic>> Function(Uri) _lookup;
  final DateTime Function() _now;
  StoreUpdate? _cached;
  DateTime? _nextCheck;
  Future<StoreUpdate?>? _inFlight;

  Future<StoreUpdate?> check({bool force = false}) {
    if (_platform != 'android' && _platform != 'ios') return Future.value(null);
    if (_inFlight != null) return _inFlight!;
    if (!force && _nextCheck != null && _now().isBefore(_nextCheck!)) {
      return Future.value(_cached);
    }
    return _inFlight = _check().whenComplete(() => _inFlight = null);
  }

  Future<StoreUpdate?> _check() async {
    try {
      final data = await _channel
          .invokeMapMethod<String, dynamic>('check')
          .timeout(const Duration(seconds: 12));
      if (data == null) throw const FormatException('Missing store metadata');
      if (_platform == 'android') {
        final code = data['availableVersionCode'];
        _cached = data['available'] == true && code is num && code > 0
            ? StoreUpdate(id: 'play-$code')
            : null;
      } else {
        final bundle = data['bundleId'] as String;
        final country = data['country'] as String? ?? 'US';
        final response = await _lookup(
          Uri.https('itunes.apple.com', '/lookup', {
            'bundleId': bundle,
            'country': country,
            'entity': 'software',
          }),
        ).timeout(const Duration(seconds: 12));
        _cached = updateFromAppleLookup(
          response,
          bundleId: bundle,
          installedVersion: data['version'] as String,
          systemVersion: data['systemVersion'] as String,
        );
      }
      _nextCheck = _now().add(const Duration(hours: 6));
    } catch (_) {
      // Offline, sideloaded builds, unpublished apps and absent stores must not
      // block startup or incorrectly claim that the installed version is old.
      _nextCheck = _now().add(const Duration(minutes: 15));
    }
    return _cached;
  }

  Future<bool> openStore(StoreUpdate update) async {
    try {
      return await _channel
              .invokeMethod<bool>('openStore', {
                if (update.storeUrl != null) 'url': update.storeUrl,
              })
              .timeout(const Duration(seconds: 10)) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> _loadLookup(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          throw const HttpException('Store unavailable');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 1024 * 1024) {
            throw const FormatException('Oversized store response');
          }
        }
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      })().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
    }
  }
}

/// Returns null for malformed versions rather than suggesting an unsafe update.
int? compareStoreVersions(String a, String b) {
  List<int>? parts(String value) {
    if (!RegExp(r'^\d+(\.\d+){0,3}$').hasMatch(value)) return null;
    final result = value.split('.').map(int.tryParse).toList();
    return result.any((v) => v == null) ? null : result.cast<int>();
  }

  final left = parts(a), right = parts(b);
  if (left == null || right == null) return null;
  for (var i = 0; i < left.length || i < right.length; i++) {
    final result = (i < left.length ? left[i] : 0).compareTo(
      i < right.length ? right[i] : 0,
    );
    if (result != 0) return result;
  }
  return 0;
}

StoreUpdate? updateFromAppleLookup(
  Map<String, dynamic> response, {
  required String bundleId,
  required String installedVersion,
  required String systemVersion,
}) {
  final results = response['results'];
  if (results is! List) return null;
  for (final item in results) {
    if (item is! Map || item['bundleId'] != bundleId) continue;
    final version = item['version'];
    final minimumOs = item['minimumOsVersion'];
    final trackId = item['trackId'];
    final url = Uri.tryParse(item['trackViewUrl']?.toString() ?? '');
    if (version is! String ||
        compareStoreVersions(version, installedVersion) != 1 ||
        trackId is! num ||
        trackId <= 0 ||
        url == null ||
        url.scheme != 'https' ||
        url.host != 'apps.apple.com' ||
        !url.pathSegments.contains('id${trackId.toInt()}')) {
      continue;
    }
    if (minimumOs is! String ||
        (compareStoreVersions(systemVersion, minimumOs) ?? -1) < 0) {
      continue;
    }
    return StoreUpdate(
      id: 'appstore-$version',
      version: version,
      storeUrl: url.toString(),
    );
  }
  return null;
}
