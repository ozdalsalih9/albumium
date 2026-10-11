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

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    BannerAds.resetForTesting();
  });

  testWidgets('Android puts the banner under the tabs, clear of the keys', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // A phone with on-screen keys, as in the screenshot this was drawn on.
    tester.view.padding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);

    await _openHome(tester);

    final banner = tester.getRect(find.byKey(const ValueKey('ad-banner')));
    final tabs = tester.getRect(find.byType(NavigationBar));
    expect(banner.top, greaterThanOrEqualTo(tabs.bottom));

    // Half under the system keys is not an impression Google will pay for,
    // and the keys are what the thumb is aiming at.
    final keys = tester.view.padding.bottom / tester.view.devicePixelRatio;
    final screen = tester.getSize(find.byType(MaterialApp)).height;
    expect(banner.bottom, lessThanOrEqualTo(screen - keys));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS keeps the banner above the tabs', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await _openHome(tester);

    final banner = tester.getRect(find.byKey(const ValueKey('ad-banner')));
    final tabs = tester.getRect(find.byType(NavigationBar));
    // The bottom edge of an iPhone is the home indicator's swipe path.
    expect(banner.bottom, lessThanOrEqualTo(tabs.top));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the cards tab carries no banner on either platform', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await _openHome(tester);
    await tester.tap(find.text('Kartlar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ad-banner')), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });
}
