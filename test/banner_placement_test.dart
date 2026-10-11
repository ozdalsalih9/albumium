import 'package:albumium/main.dart';
import 'package:albumium/widgets/ad_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the banner sits relative to the navigation bar, which is the whole
/// of what was asked for and the one thing a unit test of the widget alone
/// cannot show.
Future<void> _openHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  BannerAds.configure((context) => const SizedBox(height: 50, width: 320));
  await tester.pumpWidget(
    const AlbumiumApp(showOnboarding: false, showLaunchAnimation: false),
  );
  await tester.pumpAndSettle();
}

void _expectAboveTheTabs(WidgetTester tester) {
  final banner = tester.getRect(find.byKey(const ValueKey('ad-banner')));
  final tabs = tester.getRect(find.byType(NavigationBar));
  expect(banner.bottom, lessThanOrEqualTo(tabs.top));
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    BannerAds.resetForTesting();
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform keeps the banner above the tabs', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      // A phone whose bottom edge belongs to the system, whichever way it
      // draws it: keys on Android, the home indicator on iOS.
      tester.view.padding = const FakeViewPadding(bottom: 144);
      addTearDown(tester.view.reset);

      await _openHome(tester);

      // Below the bar would put the ad in the path of the back key and the
      // swipe up, where a tap meant for the system lands on an ad instead.
      _expectAboveTheTabs(tester);

      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('every tab carries it, the cards tab included', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await _openHome(tester);

    for (final tab in ['Temalar', 'Kartlar']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('ad-banner')),
        findsOneWidget,
        reason: 'the $tab tab lost its banner',
      );
      _expectAboveTheTabs(tester);
    }

    debugDefaultTargetPlatformOverride = null;
  });
}
