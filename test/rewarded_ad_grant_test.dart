import 'package:albumium/services/feature_entitlements.dart';
import 'package:albumium/services/rewarded_ads.dart';
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

Future<FeatureEntitlements> _store() async {
  SharedPreferences.setMockInitialValues({});
  final features = FeatureEntitlements(
    preferences: await SharedPreferences.getInstance(),
  );
  await features.initialize();
  return features;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(RewardedAds.resetForTesting);

  test('a build with no ad SDK reports that no ad is available', () async {
    expect(RewardedAds.source, isA<NoRewardedAdSource>());
    expect(
      await RewardedAds.source.show(AlbumiumFeature.fullHdExport),
      RewardedAdOutcome.unavailable,
    );
  });

  test('a watched ad opens the feature without buying it', () async {
    final features = await _store();

    features.grant(AlbumiumFeature.fullHdExport);

    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isTrue);
    expect(features.isPurchased(AlbumiumFeature.fullHdExport), isFalse);
  });

  test('an earned use is spent once and does not come back', () async {
    final features = await _store();
    features.grant(AlbumiumFeature.fullHdExport);

    expect(features.consumeGrant(AlbumiumFeature.fullHdExport), isTrue);
    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
    expect(features.consumeGrant(AlbumiumFeature.fullHdExport), isFalse);
  });

  test('a purchase has no use to spend', () async {
    final features = await _store();
    await features.purchase(AlbumiumFeature.fullHdExport);

    expect(features.consumeGrant(AlbumiumFeature.fullHdExport), isFalse);
    expect(
      features.isUnlocked(AlbumiumFeature.fullHdExport),
      isTrue,
      reason: 'spending nothing must not close a feature that was paid for',
    );
  });

  test('an earned use is never written down as a purchase', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final features = FeatureEntitlements(preferences: preferences);
    await features.initialize();

    features.grant(AlbumiumFeature.fullHdExport);

    expect(
      preferences.getStringList(
        FeatureEntitlements.purchasedFeaturesPreferenceKey,
      ),
      anyOf(isNull, isEmpty),
    );

    // A new session starts from the ledger, so the reward is gone with it.
    final next = FeatureEntitlements(preferences: preferences);
    await next.initialize();
    expect(next.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
  });

  test('every other outcome earns nothing', () async {
    for (final outcome in [
      RewardedAdOutcome.dismissed,
      RewardedAdOutcome.unavailable,
      RewardedAdOutcome.failed,
    ]) {
      final features = await _store();
      final ads = _FakeAds(outcome);
      RewardedAds.configure(ads);

      final result = await RewardedAds.source.show(
        AlbumiumFeature.fullHdExport,
      );
      if (result == RewardedAdOutcome.earned) {
        features.grant(AlbumiumFeature.fullHdExport);
      }

      expect(ads.shown, 1);
      expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
    }
  });
}
