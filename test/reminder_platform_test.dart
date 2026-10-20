import 'dart:async';
import 'package:albumium/services/reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(ReminderService.channel, null);
    ReminderService.channel.setMethodCallHandler(null);
    ReminderService.pending.value = null;
  });
  test(
    'album synchronization preserves the first permission request',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var permitted = false;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(ReminderService.channel, (call) async {
        calls.add(call);
        if (call.method == 'permissionStatus') return permitted;
        if (call.method == 'requestPermission') return permitted = true;
        return null;
      });
      await ReminderService.refreshSchedule('tr');
      expect((await ReminderService.settings())['enabled'], true);
      await ReminderService.syncAlbums([]);
      await Future<void>.delayed(Duration.zero);
      expect((await ReminderService.settings())['enabled'], true);
      await ReminderService.enableDefaultReminders('tr');
      expect(
        calls.where((call) => call.method == 'requestPermission'),
        hasLength(1),
      );
      expect((await ReminderService.settings())['enabled'], true);
      expect(calls.last.arguments['enabled'], true);
    },
  );
  test(
    'a delayed background refresh cannot override a manual disable',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final started = Completer<void>();
      final permission = Completer<bool>();
      final configurations = <Map<dynamic, dynamic>>[];
      messenger.setMockMethodCallHandler(ReminderService.channel, (call) async {
        if (call.method == 'permissionStatus') {
          started.complete();
          return permission.future;
        }
        if (call.method == 'configure') {
          configurations.add(call.arguments as Map);
        }
        return null;
      });
      await ReminderService.syncAlbums([]);
      await started.future;
      await ReminderService.save({'enabled': false}, 'tr', userInitiated: true);
      permission.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(configurations, hasLength(1));
      expect(configurations.single['enabled'], false);
      expect((await ReminderService.settings())['enabled'], false);
    },
  );
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test(
      '$platform denied permission persists disabled and configures native disabled',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(ReminderService.channel, (
          call,
        ) async {
          calls.add(call);
          return call.method == 'requestPermission' ? false : null;
        });
        final input = {'enabled': true, 'weekend': true, 'hour': 20};
        expect(
          await ReminderService.save(input, 'tr', requestPermission: true),
          false,
        );
        expect(input['enabled'], true);
        expect((await ReminderService.settings())['enabled'], false);
        expect((await ReminderService.settings())['enabled'], false);
        expect(ReminderService.enabled.value, false);
        expect(calls.last.method, 'configure');
        expect(calls.last.arguments['enabled'], false);
      },
    );
  }
  test(
    'iOS revoked permission is detected without prompting on app launch',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final methods = <String>[];
      messenger.setMockMethodCallHandler(ReminderService.channel, (call) async {
        methods.add(call.method);
        return call.method == 'permissionStatus' ? false : null;
      });
      await ReminderService.save({'enabled': true}, 'en');
      expect(methods, ['permissionStatus', 'configure']);
      expect((await ReminderService.settings())['enabled'], false);
    },
  );
  test('iOS notification cold launch supplies the memory date', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final payload = {
      'kinds': 'month,year',
      'year': 2026,
      'month': 12,
      'day': 31,
    };
    messenger.setMockMethodCallHandler(
      ReminderService.channel,
      (call) async => payload,
    );
    await ReminderService.initialize();
    expect(ReminderService.pending.value, payload);
  });
}
