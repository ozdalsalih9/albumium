import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderService {
  static const channel = MethodChannel('com.albumium.albumium/memories');
  static final pending = ValueNotifier<Map<String, dynamic>?>(null);
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
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
    return {
      'enabled': p.getBool('memories.enabled') ?? false,
      'weekend': p.getBool('memories.weekend') ?? true,
      'month': p.getBool('memories.month') ?? true,
      'year': p.getBool('memories.year') ?? true,
      'hour': p.getInt('memories.hour') ?? 20,
      'minute': p.getInt('memories.minute') ?? 0,
    };
  }

  static Future<bool> save(
    Map<String, dynamic> values,
    String language, {
    bool requestPermission = false,
  }) async {
    var allowed = true;
    if (Platform.isAndroid) {
      if (requestPermission) {
        allowed =
            await channel.invokeMethod<bool>('requestPermission') ?? false;
      }
      await channel.invokeMethod('configure', {
        ...values,
        'language': language,
      });
    }
    final p = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      if (entry.value is bool) {
        await p.setBool('memories.${entry.key}', entry.value as bool);
      }
      if (entry.value is int) {
        await p.setInt('memories.${entry.key}', entry.value as int);
      }
    }
    return allowed;
  }
}
