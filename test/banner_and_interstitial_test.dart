import 'package:albumium/services/ad_ids.dart';
import 'package:albumium/services/interstitial_ads.dart';
import 'package:albumium/widgets/ad_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingInterstitials implements InterstitialAdSource {
  final List<InterstitialPlacement> shown = [];

  @override
  Future<void> show(InterstitialPlacement placement) async {
    shown.add(placement);
  }
}

Future<void> _pumpBanner(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdBanner())));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    BannerAds.resetForTesting();
    InterstitialAds.resetForTesting();
  });

  group('banner', () {
    testWidgets('draws nothing where the app sells instead of advertising', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      BannerAds.configure((context) => const Text('reklam'));

      await _pumpBanner(tester);

      // Android charges for the covers and stickers; a banner there would be
      // asking twice.
      expect(find.text('reklam'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('draws nothing until an ad actually loads', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await _pumpBanner(tester);

      // The default builder returns null, which is what an unfilled banner
      // looks like: no reserved grey strip above the navigation bar.
      expect(find.byKey(const ValueKey('ad-banner')), findsNothing);
      expect(tester.getSize(find.byType(AdBanner)).height, 0);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shows the ad it is given on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      BannerAds.configure((context) => const SizedBox(height: 50));

      await _pumpBanner(tester);

      expect(find.byKey(const ValueKey('ad-banner')), findsOneWidget);
      expect(tester.getSize(find.byType(AdBanner)).height, 50);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('full-screen cadence', () {
    test('the first break of a session is left alone', () {
      final cadence = InterstitialCadence();

      // Someone who opens the app, makes one album and leaves should not be
      // charged a full-screen ad on the way out.
      expect(cadence.allow(), isFalse);
      expect(cadence.shownThisSession, 0);
    });

    test('a quiet gap is kept between two ads', () {
      final cadence = InterstitialCadence(
        minimumGap: const Duration(minutes: 3),
        skipFirst: false,
      );
      final start = DateTime(2026, 10, 9, 12);

      expect(cadence.allow(now: start), isTrue);
      expect(
        cadence.allow(now: start.add(const Duration(minutes: 1))),
        isFalse,
      );
      expect(cadence.allow(now: start.add(const Duration(minutes: 4))), isTrue);
    });

    test('a session has a ceiling', () {
      final cadence = InterstitialCadence(
        minimumGap: Duration.zero,
        maximumPerSession: 2,
        skipFirst: false,
      );

      expect(cadence.allow(), isTrue);
      expect(cadence.allow(), isTrue);
      expect(cadence.allow(), isFalse, reason: 'the ceiling holds');
      expect(cadence.shownThisSession, 2);
    });
  });

  group('maybeShow', () {
    test('Android never reaches the ad', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final ads = _CountingInterstitials();
      InterstitialAds.configure(
        ads,
        cadence: InterstitialCadence(
          minimumGap: Duration.zero,
          skipFirst: false,
        ),
      );

      await InterstitialAds.maybeShow(InterstitialPlacement.editorExit);

      expect(ads.shown, isEmpty);
    });

    test('iOS shows one once the cadence allows it', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ads = _CountingInterstitials();
      InterstitialAds.configure(
        ads,
        cadence: InterstitialCadence(
          minimumGap: Duration.zero,
          skipFirst: true,
        ),
      );

      await InterstitialAds.maybeShow(InterstitialPlacement.editorExit);
      await InterstitialAds.maybeShow(InterstitialPlacement.previewExit);

      expect(ads.shown, [InterstitialPlacement.previewExit]);
    });
  });

  test('the test build asks for test units on both surfaces', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(AdIds.bannerUnitId, AdIds.iosTestBannerUnitId);
    expect(AdIds.interstitialUnitId, AdIds.iosTestInterstitialUnitId);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    // Android has neither surface at all.
    expect(AdIds.bannerUnitId, isNull);
    expect(AdIds.interstitialUnitId, isNull);
  });
}
