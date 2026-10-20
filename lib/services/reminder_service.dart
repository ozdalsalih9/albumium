import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album_models.dart';
import '../models/memory_period.dart';

class ReminderService {
  static bool get _supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);
  static const channel = MethodChannel('com.albumium.albumium/memories');
  static final pending = ValueNotifier<Map<String, dynamic>?>(null);
  static final enabled = ValueNotifier(true);
  static int _settingsRevision = 0;

  static Future<void> initialize() async {
    if (!_supported) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openMemory') {
        pending.value = Map<String, dynamic>.from(call.arguments as Map);
      }
    });
    final initial = await channel.invokeMapMethod<String, dynamic>(
      'initialMemory',
    );
    if (initial != null) pending.value = initial;
  }

  static Future<Map<String, dynamic>> settings() async {
    final p = await SharedPreferences.getInstance();
    // Apply the new default once; explicit choices made afterwards survive.
    if (!(p.getBool('memories.defaults.v2') ?? false)) {
      if (!(p.getBool('memories.explicit_choice') ?? false)) {
        await p.setBool('memories.enabled', true);
      }
      await p.setBool('memories.defaults.v2', true);
    }
    final value = p.getBool('memories.enabled') ?? true;
    enabled.value = value;
    return {
      'enabled': value,
      'weekend': p.getBool('memories.weekend') ?? true,
      'month': p.getBool('memories.month') ?? true,
      'year': p.getBool('memories.year') ?? true,
      'continuation': p.getBool('memories.continuation') ?? true,
      'hour': p.getInt('memories.hour') ?? 20,
      'minute': p.getInt('memories.minute') ?? 0,
    };
  }

  static Future<bool> permissionGranted() async {
    if (!_supported) return false;
    try {
      return await channel.invokeMethod<bool>('permissionStatus') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> enableDefaultReminders(String language) async {
    final p = await SharedPreferences.getInstance();
    final values = await settings();
    if (!_supported || values['enabled'] != true) return;
    final ask = !(p.getBool('memories.permission_requested.v2') ?? false);
    if (ask) await p.setBool('memories.permission_requested.v2', true);
    try {
      await save(values, language, requestPermission: ask);
    } catch (_) {}
  }

  static Future<void> openSystemSettings() async {
    if (_supported) await channel.invokeMethod('openNotificationSettings');
  }

  static Future<void> syncAlbums(List<AlbumModel> albums) async {
    try {
      final p = await SharedPreferences.getInstance();
      final started =
          albums
              .where(
                (a) =>
                    MemoryPeriod.fromKey(a.memoryPeriod) != null &&
                    !a.memoryCompleted,
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final kinds = <MemoryKind>{};
      final recent = started.where(
        (a) => kinds.add(MemoryPeriod.fromKey(a.memoryPeriod)!.kind),
      );
      await p.setString(
        'memories.resume_albums',
        jsonEncode([
          for (final a in recent)
            {
              'albumId': a.id,
              'albumTitle': a.title,
              'period': a.memoryPeriod,
              'updatedAt': a.updatedAt.millisecondsSinceEpoch,
            },
        ]),
      );
      final activity = albums
          .where((a) => a.memoryPeriod != null)
          .fold<int>(
            0,
            (latest, a) => latest > a.updatedAt.millisecondsSinceEpoch
                ? latest
                : a.updatedAt.millisecondsSinceEpoch,
          );
      await p.setInt('memories.last_activity', activity);
      // The library is already on disk. Native notification scheduling must
      // not hold up sharing, closing the editor, or consuming a cover grant.
      unawaited(_refreshSchedule(p));
    } catch (_) {
      // Notification failures must not turn a successful album save into an error.
    }
  }

  static Future<void> refreshSchedule(String language) async {
    final p = await SharedPreferences.getInstance();
    await _refreshSchedule(p, language: language);
  }

  static Future<void> _refreshSchedule(
    SharedPreferences p, {
    String? language,
  }) async {
    if (!_supported) return;
    final revision = _settingsRevision;
    try {
      final values = await settings();
      final permitted = await permissionGranted();
      // A background library refresh never changes the user's reminder choice
      // or suppresses the first permission prompt. A newer explicit save wins.
      if (revision != _settingsRevision) return;
      final effective = {
        ...values,
        'enabled': values['enabled'] == true && permitted,
      };
      final scheduleLanguage =
          language ?? p.getString('albumium.language.code.v1') ?? 'tr';
      await channel.invokeMethod('configure', {
        ...effective,
        'language': scheduleLanguage,
        'followUps': jsonEncode(_followUps(p, effective, scheduleLanguage)),
        'lastActivity': p.getInt('memories.last_activity') ?? 0,
      });
    } catch (_) {
      // Native scheduling is best effort after the library has been saved.
    }
  }

  static List<Map<String, dynamic>> _followUps(
    SharedPreferences p,
    Map<String, dynamic> values,
    String language,
  ) {
    if (values['continuation'] != true) return [];
    final raw =
        jsonDecode(p.getString('memories.resume_albums') ?? '[]') as List;
    final jobs = <Map<String, dynamic>>[];
    for (final album in raw) {
      final period = MemoryPeriod.fromKey(album['period'] as String?);
      if (period == null || values[period.kind.name] != true) continue;
      final updated = DateTime.fromMillisecondsSinceEpoch(
        album['updatedAt'] as int,
      );
      for (var visit = 0; visit < 4; visit++) {
        final delay = 3 + visit * 7;
        final fire = DateTime(
          updated.year,
          updated.month,
          updated.day + delay,
          values['hour'] as int,
          values['minute'] as int,
        );
        if (!fire.isAfter(DateTime.now())) continue;
        final english = language == 'en';
        jobs.add({
          'at': fire.millisecondsSinceEpoch,
          'updatedAt': updated.millisecondsSinceEpoch,
          'delayDays': delay,
          'albumId': album['albumId'],
          'kinds': period.kind.name,
          'year': period.date.year,
          'month': period.date.month,
          'day': period.date.day,
          'title': english
              ? [
                  'Shall we keep one more moment?',
                  'Your story is right where you left it.',
                  'Small moments, a lovely story.',
                ][visit % 3]
              : [
                  'Bir an daha saklayalım mı?',
                  'Hikâyen kaldığın yerde.',
                  'Küçük anlar, güzel bir hikâye.',
                ][visit % 3],
          'body': english
              ? 'Add a photo or a little note to “${album['albumTitle']}” whenever you feel like it.'
              : '“${album['albumTitle']}” albümüne bir fotoğraf ya da küçük bir not ekleyebilirsin.',
        });
      }
    }
    jobs.sort((a, b) {
      final time = (a['at'] as int).compareTo(b['at'] as int);
      return time != 0
          ? time
          : (b['updatedAt'] as int).compareTo(a['updatedAt'] as int);
    });
    final selected = <Map<String, dynamic>>[];
    for (final job in jobs) {
      if (selected.isEmpty ||
          (job['at'] as int) - (selected.last['at'] as int) >=
              const Duration(days: 7).inMilliseconds) {
        selected.add(job);
      }
      if (selected.length == 4) break;
    }
    return selected;
  }

  static Future<bool> save(
    Map<String, dynamic> values,
    String language, {
    bool requestPermission = false,
    bool userInitiated = false,
  }) async {
    _settingsRevision++;
    var allowed = true;
    final p = await SharedPreferences.getInstance();
    final effective = Map<String, dynamic>.from(values);
    if (_supported) {
      if (requestPermission) {
        allowed =
            await channel.invokeMethod<bool>('requestPermission') ?? false;
      } else if (values['enabled'] == true) {
        allowed = await permissionGranted();
      }
      if (!allowed) effective['enabled'] = false;
      await channel.invokeMethod('configure', {
        ...effective,
        'language': language,
        'followUps': jsonEncode(_followUps(p, effective, language)),
        'lastActivity': p.getInt('memories.last_activity') ?? 0,
      });
    }
    for (final entry in effective.entries) {
      if (entry.value is bool) {
        await p.setBool('memories.${entry.key}', entry.value as bool);
      }
      if (entry.value is int) {
        await p.setInt('memories.${entry.key}', entry.value as int);
      }
    }
    // A saved permission result is authoritative; the one-time default
    // migration must not turn a rejected/revoked permission back on.
    await p.setBool('memories.defaults.v2', true);
    if (userInitiated) await p.setBool('memories.explicit_choice', true);
    enabled.value = effective['enabled'] == true;
    return allowed;
  }
}
