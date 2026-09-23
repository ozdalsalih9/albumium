import 'package:albumium/services/feature_entitlements.dart';
import 'package:albumium/services/rewarded_ads.dart';
import 'package:albumium/widgets/feature_unlock_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAds implements RewardedAdSource {
  _FakeAds(this.outcome);

  final RewardedAdOutcome outcome;
  int shown = 0;

  @override
  Future<RewardedAdOutcome> show(AlbumiumFeature feature) async {
    shown++;
    return outcome;
  }
}

class _SlowStore implements FeaturePurchaseSource {
  int attempts = 0;

  @override
  String priceLabelFor(AlbumiumFeature feature) => feature.priceLabel;

  @override
  Future<bool> purchase(AlbumiumFeature feature) async {
    attempts++;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<Set<String>> restore() async => const <String>{};
}

Future<FeatureEntitlements> _store({FeaturePurchaseSource? source}) async {
  SharedPreferences.setMockInitialValues({});
  final features = FeatureEntitlements(
    preferences: await SharedPreferences.getInstance(),
    source: source ?? const LocalFeaturePurchaseSource(),
  );
  await features.initialize();
  return features;
}

/// Opens the sheet from a button, the way a screen does, and reports the
/// result the sheet handed back.
Future<List<bool>> _openSheet(
  WidgetTester tester, {
  required FeatureEntitlements features,
  required AlbumiumFeature feature,
  RewardedAdSource? ads,
  bool offerAd = false,
}) async {
  final results = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showFeatureUnlockSheet(
                context,
                feature: feature,
                entitlements: features,
                ads: ads,
                offerAd: offerAd,
                title: 'Full HD videoyu aç',
                description: 'Albümünü 1080p paylaş.',
                bullets: const [
                  (Icons.hd_outlined, 'Tek seferlik satın alma.'),
                ],
              ),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a purchase-only sheet shows the price and no ad button', (
    tester,
  ) async {
    final features = await _store();
    await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.customStickers,
    );

    expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('feature-unlock-watch-ad')), findsNothing);
    expect(find.textContaining('₺29,99'), findsOneWidget);
  });

  testWidgets('buying closes the sheet and keeps the feature', (tester) async {
    final features = await _store();
    final results = await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.customStickers,
    );

    await tester.tap(find.byKey(const ValueKey('feature-unlock-buy')));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(features.isPurchased(AlbumiumFeature.customStickers), isTrue);
  });

  testWidgets('a second tap while buying is ignored', (tester) async {
    final store = _SlowStore();
    final features = await _store(source: store);
    await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.customStickers,
    );

    final buy = find.byKey(const ValueKey('feature-unlock-buy'));
    await tester.tap(buy);
    await tester.pump();
    await tester.tap(buy, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(store.attempts, 1);
  });

  testWidgets('watching an ad earns one use without buying', (tester) async {
    final features = await _store();
    final ads = _FakeAds(RewardedAdOutcome.earned);
    final results = await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.fullHdExport,
      ads: ads,
      offerAd: true,
    );

    expect(find.textContaining('₺4,99'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('feature-unlock-watch-ad')));
    await tester.pumpAndSettle();

    expect(ads.shown, 1);
    expect(results, [true]);
    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isTrue);
    expect(features.isPurchased(AlbumiumFeature.fullHdExport), isFalse);
  });

  testWidgets('closing the ad early explains why nothing was earned', (
    tester,
  ) async {
    final features = await _store();
    await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.fullHdExport,
      ads: _FakeAds(RewardedAdOutcome.dismissed),
      offerAd: true,
    );

    await tester.tap(find.byKey(const ValueKey('feature-unlock-watch-ad')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('feature-unlock-error')), findsOneWidget);
    expect(find.textContaining('sonuna kadar izlemelisin'), findsOneWidget);
    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
    // The sheet stays open so the purchase is still one tap away.
    expect(find.byKey(const ValueKey('feature-unlock-buy')), findsOneWidget);
  });

  testWidgets('with no ad to show the button stops offering one', (
    tester,
  ) async {
    final features = await _store();
    await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.fullHdExport,
      ads: _FakeAds(RewardedAdOutcome.unavailable),
      offerAd: true,
    );

    await tester.tap(find.byKey(const ValueKey('feature-unlock-watch-ad')));
    await tester.pumpAndSettle();

    expect(find.textContaining('gösterilecek reklam yok'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('feature-unlock-watch-ad')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('a failed ad can be tried again', (tester) async {
    final features = await _store();
    await _openSheet(
      tester,
      features: features,
      feature: AlbumiumFeature.fullHdExport,
      ads: _FakeAds(RewardedAdOutcome.failed),
      offerAd: true,
    );

    await tester.tap(find.byKey(const ValueKey('feature-unlock-watch-ad')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Reklam açılamadı'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('feature-unlock-watch-ad')),
          )
          .onPressed,
      isNotNull,
    );
  });
}
