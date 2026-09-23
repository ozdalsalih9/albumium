import 'package:albumium/models/album_models.dart';
import 'package:albumium/services/cover_entitlements.dart';
import 'package:albumium/services/feature_entitlements.dart';
import 'package:albumium/services/play_billing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that answers from a script instead of from Google.
class _FakeStore implements BillingClient {
  _FakeStore({Set<String>? owned, this.sells = true})
    : owned_ = owned ?? <String>{};

  final Map<String, String> prices = <String, String>{};
  final Set<String> owned_;
  final bool sells;
  final List<String> bought = [];
  int ownedCalls = 0;

  @override
  Future<Map<String, String>> loadPrices(Set<String> productIds) async => {
    for (final id in productIds)
      if (prices.containsKey(id)) id: prices[id]!,
  };

  @override
  Future<bool> buy(String productId) async {
    bought.add(productId);
    if (!sells) return false;
    owned_.add(productId);
    return true;
  }

  @override
  Future<Set<String>> owned() async {
    ownedCalls++;
    return Set.of(owned_);
  }
}

Future<CoverEntitlements> _covers(CoverPurchaseSource source) async {
  SharedPreferences.setMockInitialValues({});
  final covers = CoverEntitlements(
    preferences: await SharedPreferences.getInstance(),
    source: source,
  );
  await covers.initialize();
  return covers;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the store is asked about every paid product and nothing else', () {
    final ids = albumiumProductIds();

    expect(ids, contains('albumium.feature.video_fullhd'));
    expect(ids, contains('albumium.feature.custom_stickers'));
    expect(ids, contains('albumium.cover.dark_leather'));
    // Free covers are not sold, so Play never hears about them.
    expect(ids, isNot(contains('albumium.cover.soft_romance')));
    expect(ids, isNot(contains('albumium.cover.travel_istanbul')));
    expect(
      ids.length,
      albumThemes.where((theme) => theme.isPremium).length +
          AlbumiumFeature.values.length,
    );
  });

  test('buying a cover asks the store for that cover s product', () async {
    final store = _FakeStore();
    final source = PlayCoverPurchaseSource(store);

    expect(await source.purchase('dark_leather'), isTrue);

    expect(store.bought, ['albumium.cover.dark_leather']);
  });

  test('a refused purchase stays refused', () async {
    final store = _FakeStore(sells: false);
    final covers = await _covers(PlayCoverPurchaseSource(store));

    expect(await covers.purchase('dark_leather'), isFalse);
    expect(covers.isUnlocked('dark_leather'), isFalse);
  });

  test('the store price wins over the catalogue label', () async {
    final source = PlayCoverPurchaseSource(_FakeStore())
      ..cachePrices({'albumium.cover.dark_leather': '€1.99'});

    expect(source.priceLabelFor('dark_leather'), '€1.99');
    // A cover the store did not price falls back to the catalogue, so a
    // locked cover never shows an empty button.
    expect(
      source.priceLabelFor('vintage_diary'),
      themeById('vintage_diary').price.label,
    );
  });

  test('a feature price falls back to its own label', () {
    final source = PlayFeaturePurchaseSource(_FakeStore())
      ..cachePrices({AlbumiumFeature.fullHdExport.productId: '\$0.99'});

    expect(source.priceLabelFor(AlbumiumFeature.fullHdExport), '\$0.99');
    expect(
      source.priceLabelFor(AlbumiumFeature.customStickers),
      AlbumiumFeature.customStickers.priceLabel,
    );
  });

  test('restore reports what the store owns, in theme ids', () async {
    final store = _FakeStore(
      owned: {'albumium.cover.dark_leather', 'albumium.feature.video_fullhd'},
    );

    expect(await PlayCoverPurchaseSource(store).restore(), {'dark_leather'});
    expect(await PlayFeaturePurchaseSource(store).restore(), {'video_fullhd'});
  });

  test('a refunded cover closes again', () async {
    final store = _FakeStore(owned: {'albumium.cover.dark_leather'});
    final source = PlayCoverPurchaseSource(store);
    final covers = await _covers(source);

    await covers.applyStoreOwnership(await source.restore());
    expect(covers.isUnlocked('dark_leather'), isTrue);

    // Google refunded it, so Play stops reporting it.
    store.owned_.clear();
    await covers.applyStoreOwnership(await source.restore());

    expect(
      covers.isUnlocked('dark_leather'),
      isFalse,
      reason: 'the store is the truth about what was paid for',
    );
  });

  test('a refunded feature closes again', () async {
    SharedPreferences.setMockInitialValues({});
    final store = _FakeStore(owned: {'albumium.feature.custom_stickers'});
    final source = PlayFeaturePurchaseSource(store);
    final features = FeatureEntitlements(
      preferences: await SharedPreferences.getInstance(),
      source: source,
    );
    await features.initialize();

    await features.applyStoreOwnership(await source.restore());
    expect(features.isPurchased(AlbumiumFeature.customStickers), isTrue);

    store.owned_.clear();
    await features.applyStoreOwnership(await source.restore());

    expect(features.isPurchased(AlbumiumFeature.customStickers), isFalse);
  });

  test('a purchase made on another device arrives', () async {
    final store = _FakeStore();
    final source = PlayCoverPurchaseSource(store);
    final covers = await _covers(source);
    expect(covers.isUnlocked('vintage_diary'), isFalse);

    store.owned_.add('albumium.cover.vintage_diary');
    await covers.applyStoreOwnership(await source.restore());

    expect(covers.isUnlocked('vintage_diary'), isTrue);
  });

  test('free covers are untouched by what the store says', () async {
    final store = _FakeStore();
    final covers = await _covers(PlayCoverPurchaseSource(store));

    await covers.applyStoreOwnership(const <String>{});

    expect(covers.isUnlocked('soft_romance'), isTrue);
    expect(covers.isUnlocked('travel_istanbul'), isTrue);
  });

  test('the app can start on the stand-in and move to the store', () async {
    SharedPreferences.setMockInitialValues({});
    final covers = CoverEntitlements(
      preferences: await SharedPreferences.getInstance(),
    );
    await covers.initialize();
    expect(covers.priceLabelFor('dark_leather'), '₺14,99');

    covers.useSource(
      PlayCoverPurchaseSource(_FakeStore())
        ..cachePrices({'albumium.cover.dark_leather': '₺19,99'}),
    );

    expect(covers.priceLabelFor('dark_leather'), '₺19,99');
  });
}
