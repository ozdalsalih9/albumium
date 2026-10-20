import 'dart:async';
import 'package:albumium/l10n/albumium_localizations.dart';
import 'package:albumium/services/app_update_service.dart';
import 'package:albumium/widgets/app_update_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const channel = MethodChannel('com.albumium.albumium/app_updates');
Map<String, dynamic> apple({
  String version = '1.10.0',
  String minimum = '17.0',
}) => {
  'results': [
    {
      'bundleId': 'com.albumium.albumium',
      'version': version,
      'minimumOsVersion': minimum,
      'trackId': 123456789,
      'trackViewUrl': 'https://apps.apple.com/tr/app/albumium/id123456789',
    },
  ],
};

Widget app(
  AppUpdateService service, {
  String locale = 'tr',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AlbumiumLocalizations.supportedLocales,
  localizationsDelegates: const [
    AlbumiumLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: AppUpdateBanner(key: ObjectKey(service), service: service),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  void native(Future<Object?> Function(MethodCall) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);

  test(
    'versions compare numerically and reject prerelease or malformed values',
    () {
      expect(compareStoreVersions('1.10.0', '1.9.9'), 1);
      expect(compareStoreVersions('1.2', '1.2.0'), 0);
      expect(compareStoreVersions('1.2.0', '2.0'), -1);
      expect(compareStoreVersions('1.2-beta', '1.1'), isNull);
      expect(compareStoreVersions('', '1.0'), isNull);
    },
  );

  test(
    'Apple offers only a newer matching app compatible with this iOS version',
    () {
      StoreUpdate? parse(Map<String, dynamic> data) => updateFromAppleLookup(
        data,
        bundleId: 'com.albumium.albumium',
        installedVersion: '1.9.0',
        systemVersion: '17.4',
      );
      expect(parse(apple())?.version, '1.10.0');
      expect(parse(apple(version: '1.9')), isNull);
      expect(parse(apple(version: '1.8')), isNull);
      expect(parse(apple(minimum: '18.0')), isNull);
      expect(parse({'results': []}), isNull);
      expect(parse({'results': 'bad'}), isNull);
      final mismatch = apple();
      (mismatch['results'] as List).first['bundleId'] = 'another.app';
      expect(parse(mismatch), isNull);
      final wrongLink = apple();
      (wrongLink['results'] as List).first['trackViewUrl'] =
          'https://example.com/id123456789';
      expect(parse(wrongLink), isNull);
    },
  );

  test(
    'iOS lookup uses installed bundle and region and opens returned App Store listing',
    () async {
      MethodCall? opened;
      native((call) async {
        if (call.method == 'openStore') {
          opened = call;
          return true;
        }
        return {
          'bundleId': 'com.albumium.albumium',
          'country': 'TR',
          'version': '1.9',
          'systemVersion': '17.4',
        };
      });
      final service = AppUpdateService(
        platform: 'ios',
        lookup: (uri) async {
          expect(uri.host, 'itunes.apple.com');
          expect(uri.queryParameters['bundleId'], 'com.albumium.albumium');
          expect(uri.queryParameters['country'], 'TR');
          return apple();
        },
      );
      final update = await service.check();
      expect(update?.version, '1.10.0');
      expect(await service.openStore(update!), isTrue);
      expect((opened!.arguments as Map)['url'], update.storeUrl);
    },
  );

  test(
    'Play checks are coalesced and throttled; explicit refresh detects completion',
    () async {
      var calls = 0;
      var available = true;
      var now = DateTime(2026, 10, 20);
      native((call) async {
        calls++;
        return {'available': available, 'availableVersionCode': 64};
      });
      final service = AppUpdateService(platform: 'android', now: () => now);
      final results = await Future.wait([service.check(), service.check()]);
      expect(results.first?.id, 'play-64');
      expect(calls, 1);
      await service.check();
      expect(calls, 1);
      now = now.add(const Duration(hours: 6));
      await service.check();
      expect(calls, 2);
      available = false;
      expect(await service.check(force: true), isNull);
      expect(calls, 3);
    },
  );

  test('failed checks stay silent and retry after a short interval', () async {
    var calls = 0;
    var now = DateTime(2026);
    native((call) async {
      calls++;
      throw PlatformException(code: 'store_unavailable');
    });
    final service = AppUpdateService(platform: 'android', now: () => now);
    expect(await service.check(), isNull);
    await service.check();
    expect(calls, 1);
    now = now.add(const Duration(minutes: 15));
    await service.check();
    expect(calls, 2);
    expect(await service.openStore(const StoreUpdate(id: 'play-64')), isFalse);
  });

  test('unsupported desktops never contact stores', () async {
    native((call) async => fail('Unexpected native call'));
    expect(await AppUpdateService(platform: 'windows').check(), isNull);
  });

  testWidgets('update button opens store and resume removes completed update', (
    tester,
  ) async {
    var available = true;
    var opens = 0;
    native((call) async {
      if (call.method == 'openStore') {
        opens++;
        return true;
      }
      return {'available': available, 'availableVersionCode': 64};
    });
    final service = AppUpdateService(platform: 'android');
    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();
    expect(find.text('Yeni sürüm var'), findsOneWidget);
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    available = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-update-banner')), findsNothing);
  });

  testWidgets(
    'Later persists snooze for this release but does not hide a newer release',
    (tester) async {
      var code = 64;
      native((call) async => {'available': true, 'availableVersionCode': code});
      await tester.pumpWidget(app(AppUpdateService(platform: 'android')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daha sonra'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni sürüm var'), findsNothing);
      await tester.pumpWidget(app(AppUpdateService(platform: 'android')));
      await tester.pumpAndSettle();
      expect(find.text('Yeni sürüm var'), findsNothing);
      code = 65;
      await tester.pumpWidget(app(AppUpdateService(platform: 'android')));
      await tester.pumpAndSettle();
      expect(find.text('Yeni sürüm var'), findsOneWidget);
    },
  );

  testWidgets('store launch failure allows retry and shows a readable error', (
    tester,
  ) async {
    native(
      (call) async => call.method == 'openStore'
          ? false
          : {'available': true, 'availableVersionCode': 64},
    );
    await tester.pumpWidget(app(AppUpdateService(platform: 'android')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(
      find.text('Mağaza açılamadı. Biraz sonra tekrar dene.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('app-update-open-store')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'no banner on missing store and an in-flight check may finish after dispose',
    (tester) async {
      final pending = Completer<Object?>();
      native((call) => pending.future);
      await tester.pumpWidget(app(AppUpdateService(platform: 'android')));
      await tester.pump();
      expect(find.byKey(const ValueKey('app-update-banner')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      pending.complete({'available': true, 'availableVersionCode': 64});
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['tr', 'en']) {
    testWidgets('320px banner fits large text in $language', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      native((call) async => {'available': true, 'availableVersionCode': 64});
      await tester.pumpWidget(
        app(AppUpdateService(platform: 'android'), locale: language, scale: 2),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(language == 'tr' ? 'Güncelle' : 'Update'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
