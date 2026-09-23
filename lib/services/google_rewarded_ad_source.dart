import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'error_reporter.dart';
import 'feature_entitlements.dart';
import 'rewarded_ads.dart';

/// The only file in the app that touches the ad SDK.
///
/// Everything else talks to [RewardedAdSource], so tests and the rest of the
/// code stay free of it.
class GoogleRewardedAdSource implements RewardedAdSource {
  const GoogleRewardedAdSource();

  @override
  Future<RewardedAdOutcome> show(AlbumiumFeature feature) async {
    final RewardedAd ad;
    try {
      ad = await _load();
    } on _NoAdAvailable {
      return RewardedAdOutcome.unavailable;
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'RewardedAd.load');
      return RewardedAdOutcome.failed;
    }

    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!closed.isCompleted) closed.completeError(error);
      },
    );

    try {
      // The reward callback fires before the ad is dismissed, so both are
      // awaited: nothing is granted until the ad is actually over.
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
      await closed.future;
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'RewardedAd.show');
      return RewardedAdOutcome.failed;
    }

    return earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissed;
  }

  Future<RewardedAd> _load() {
    final loaded = Completer<RewardedAd>();
    RewardedAd.load(
      adUnitId: AdIds.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        // No fill and no network look the same to the user: there is simply
        // no ad to watch, and the purchase is still there.
        onAdFailedToLoad: (_) => loaded.completeError(const _NoAdAvailable()),
      ),
    );
    return loaded.future;
  }
}

class _NoAdAvailable implements Exception {
  const _NoAdAvailable();
}

/// Starts the ad SDK and installs the real source.
///
/// Called without awaiting: a network round trip must not delay the first
/// frame, and a failure here only means the ad button reports that no ad is
/// available.
Future<void> initializeAds() async {
  try {
    await MobileAds.instance.initialize();
    RewardedAds.configure(const GoogleRewardedAdSource());
  } catch (error, stack) {
    ErrorReporter.report(error, stack, context: 'MobileAds.initialize');
  }
}
