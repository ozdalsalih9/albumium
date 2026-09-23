import 'package:albumium/services/cover_entitlements.dart';
import 'package:albumium/services/feature_entitlements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that can be told to fail, and that reports what it was asked.
class _FakeSource implements FeaturePurchaseSource {
  _FakeSource({this.succeeds = true, this.owned = const <String>{}});

  final bool succeeds;
  final Set<String> owned;
  final List<AlbumiumFeature> attempted = [];

  @override
  String priceLabelFor(AlbumiumFeature feature) => feature.priceLabel;

  @override
  Future<bool> purchase(AlbumiumFeature feature) async {
    attempted.add(feature);
    return succeeds;
  }

  @override
  Future<Set<String>> restore() async => owned;
}

Future<FeatureEntitlements> _store({
  FeaturePurchaseSource? source,
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final entitlements = FeatureEntitlements(
    preferences: await SharedPreferences.getInstance(),
    source: source ?? _FakeSource(),
  );
  await entitlements.initialize();
  return entitlements;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every paid feature starts locked', () async {
    final features = await _store();
    for (final feature in AlbumiumFeature.values) {
      expect(features.isUnlocked(feature), isFalse);
      expect(features.isPurchased(feature), isFalse);
    }
  });

  test('a purchase is remembered across a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = FeatureEntitlements(preferences: preferences);
    await first.initialize();
    expect(await first.purchase(AlbumiumFeature.customStickers), isTrue);

    final second = FeatureEntitlements(preferences: preferences);
    await second.initialize();
    expect(second.isPurchased(AlbumiumFeature.customStickers), isTrue);
    expect(second.isPurchased(AlbumiumFeature.fullHdExport), isFalse);
  });

  test('a failed purchase leaves the feature shut', () async {
    final source = _FakeSource(succeeds: false);
    final features = await _store(source: source);

    expect(await features.purchase(AlbumiumFeature.fullHdExport), isFalse);
    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
    expect(source.attempted, [AlbumiumFeature.fullHdExport]);
  });

  test('buying the same feature twice does not ask the store twice', () async {
    final source = _FakeSource();
    final features = await _store(source: source);

    await features.purchase(AlbumiumFeature.customStickers);
    await features.purchase(AlbumiumFeature.customStickers);

    expect(source.attempted, [AlbumiumFeature.customStickers]);
  });

  test('restore adds what the store already owns', () async {
    final features = await _store(
      source: _FakeSource(owned: {AlbumiumFeature.fullHdExport.id}),
    );

    await features.restore();

    expect(features.isPurchased(AlbumiumFeature.fullHdExport), isTrue);
    expect(features.isPurchased(AlbumiumFeature.customStickers), isFalse);
  });

  test('an unknown stored id is ignored rather than fatal', () async {
    final features = await _store(
      initial: {
        FeatureEntitlements.purchasedFeaturesPreferenceKey: ['no_such_feature'],
      },
    );

    for (final feature in AlbumiumFeature.values) {
      expect(features.isUnlocked(feature), isFalse);
    }
  });

  test('reset locks everything again', () async {
    final features = await _store();
    await features.purchase(AlbumiumFeature.customStickers);
    features.grant(AlbumiumFeature.fullHdExport);

    await features.reset();

    expect(features.isUnlocked(AlbumiumFeature.customStickers), isFalse);
    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
  });

  test('features and covers keep separate ledgers', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final features = FeatureEntitlements(preferences: preferences);
    final covers = CoverEntitlements(preferences: preferences);
    await Future.wait([features.initialize(), covers.initialize()]);

    await features.purchase(AlbumiumFeature.customStickers);

    // Buying a feature must not hand out a cover, nor the other way round.
    expect(covers.purchasedThemeIds, isEmpty);
    expect(
      preferences.getStringList(CoverEntitlements.purchasedCoversPreferenceKey),
      anyOf(isNull, isEmpty),
    );

    await covers.purchase('dark_leather');
    expect(features.purchasedFeatureIds, {AlbumiumFeature.customStickers.id});
  });

  test('product ids follow the Play Console scheme', () {
    expect(
      AlbumiumFeature.fullHdExport.productId,
      'albumium.feature.video_fullhd',
    );
    expect(
      AlbumiumFeature.customStickers.productId,
      'albumium.feature.custom_stickers',
    );
    expect(AlbumiumFeature.fullHdExport.priceLabel, '₺4,99');
    expect(AlbumiumFeature.customStickers.priceLabel, '₺29,99');
  });
}
