import 'feature_entitlements.dart';

/// How showing a rewarded ad ended.
enum RewardedAdOutcome {
  /// Watched to the end: the user earned one use of the feature.
  earned,

  /// Closed early, so nothing was earned.
  dismissed,

  /// No ad could be loaded, usually offline or no inventory.
  unavailable,

  /// The ad SDK itself failed.
  failed,
}

/// Where a rewarded ad comes from.
///
/// This is the seam that keeps the ad SDK out of the widgets, exactly as
/// `CoverPurchaseSource` keeps the store out of them. Only one file ever
/// imports the SDK, and it is not this one.
abstract class RewardedAdSource {
  Future<RewardedAdOutcome> show(AlbumiumFeature feature);
}

/// The source used until the real SDK is installed, and in every test.
///
/// It reports that no ad is available, which is the truth for a build with no
/// ad SDK, and it means no test ever reaches the network.
class NoRewardedAdSource implements RewardedAdSource {
  const NoRewardedAdSource();

  @override
  Future<RewardedAdOutcome> show(AlbumiumFeature feature) async =>
      RewardedAdOutcome.unavailable;
}

/// The rewarded ad source the app is running with.
abstract final class RewardedAds {
  static RewardedAdSource _source = const NoRewardedAdSource();

  static RewardedAdSource get source => _source;

  /// Installs the real source at startup, or a fake one in a test.
  static void configure(RewardedAdSource value) => _source = value;

  static void resetForTesting() => _source = const NoRewardedAdSource();
}
