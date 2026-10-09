import 'package:flutter/foundation.dart';

import 'rewarded_ads.dart';

/// AdMob identifiers.
///
/// None of these are secret: they ship inside the app and are readable by
/// anyone who opens it. They live in one file so the value in the Android
/// manifest, the value in the iOS Info.plist and the value the code loads can
/// be checked against each other.
///
/// Every id belongs to one platform. AdMob issues a separate app and separate
/// ad units for Android and iOS, and using the wrong one earns nothing while
/// looking like it works.
abstract final class AdIds {
  /// The AdMob app id, also declared in AndroidManifest.xml.
  ///
  /// A wrong or missing value crashes the app the moment the SDK starts, so a
  /// test compares this constant with the manifest.
  static const androidApplicationId = 'ca-app-pub-3816017115155014~2314787625';

  /// The rewarded unit that pays for one Full HD export on Android.
  static const androidRewardedUnitId = 'ca-app-pub-3816017115155014/8093727919';

  /// Google's sample app, kept only so [configured] can refuse a live build
  /// that still carries it.
  static const iosTestApplicationId = 'ca-app-pub-3940256099942544~1458002511';

  /// The AdMob app id for iOS, also declared in ios/Runner/Info.plist.
  ///
  /// The real id belongs here even in test builds: the app id names the app,
  /// while the *unit* decides whether an impression is billable.
  static const iosApplicationId = 'ca-app-pub-3816017115155014~2674915080';

  /// The rewarded units for iOS, one per place an ad can be watched.
  ///
  /// They could all be the same unit and the ads would work; separate ones
  /// exist so AdMob reports which placement actually earns, which is the only
  /// way to tell later whether a prompt is worth keeping.
  static const iosRewardedCoverUnitId =
      'ca-app-pub-3816017115155014/9325662920';
  static const iosRewardedStickerUnitId =
      'ca-app-pub-3816017115155014/7741118513';
  static const iosRewardedExportUnitId =
      'ca-app-pub-3816017115155014/1417584445';

  /// The unit [configured] checks before letting a live build start the SDK.
  static const iosRewardedUnitId = iosRewardedExportUnitId;

  /// The banner above the navigation bar, and the full-screen ad shown at a
  /// natural break. Empty until the units exist; empty means that surface
  /// simply does not appear.
  static const iosBannerUnitId = '';
  static const iosInterstitialUnitId = '';

  /// Google's public test units for those two surfaces.
  static const iosTestBannerUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const iosTestInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  /// Google's public test unit, which always fills and never earns revenue.
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const iosTestRewardedUnitId = 'ca-app-pub-3940256099942544/1712485313';

  /// Whether this build may request real, paying ads.
  ///
  /// Off unless a build asks for it explicitly:
  ///
  ///     flutter build appbundle --release --dart-define=ALBUMIUM_LIVE_ADS=true
  ///
  /// Watching your own live ads is invalid traffic, and Google suspends
  /// accounts over it. Since every test build anyone hands round is a release
  /// build, the safe default has to be the test unit, and going live has to be
  /// a deliberate act.
  static const liveAds = bool.fromEnvironment('ALBUMIUM_LIVE_ADS');

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// The app id for the platform the app is running on.
  static String get applicationId =>
      _isIOS ? iosApplicationId : androidApplicationId;

  /// Whether ads can run here at all.
  ///
  /// iOS test builds use the sample app; live builds require real iOS IDs.
  /// Other platforms retain their existing configuration behavior.
  static bool get configured {
    if (!_isIOS) return applicationId.isNotEmpty;
    if (kIsWeb) return false;
    if (liveAds && kReleaseMode) {
      return iosApplicationId.isNotEmpty &&
          iosApplicationId != iosTestApplicationId &&
          iosRewardedUnitId.isNotEmpty;
    }
    return iosApplicationId.isNotEmpty;
  }

  /// The banner unit, or null when there is none to show.
  static String? get bannerUnitId {
    if (!_isIOS) return null;
    if (!liveAds || !kReleaseMode) return iosTestBannerUnitId;
    return iosBannerUnitId.isEmpty ? null : iosBannerUnitId;
  }

  /// The full-screen unit, or null when there is none to show.
  static String? get interstitialUnitId {
    if (!_isIOS) return null;
    if (!liveAds || !kReleaseMode) return iosTestInterstitialUnitId;
    return iosInterstitialUnitId.isEmpty ? null : iosInterstitialUnitId;
  }

  /// The unit to request for one place in the app.
  ///
  /// Android sells its covers and stickers instead of showing ads for them,
  /// so it has the one unit; the placement only matters on iOS.
  static String rewardedUnitIdFor(RewardedAdPlacement placement) {
    if (!liveAds || !kReleaseMode) {
      return _isIOS ? iosTestRewardedUnitId : testRewardedUnitId;
    }
    if (!_isIOS) return androidRewardedUnitId;
    return switch (placement) {
      RewardedAdPlacement.cover => iosRewardedCoverUnitId,
      RewardedAdPlacement.customStickers => iosRewardedStickerUnitId,
      RewardedAdPlacement.fullHdExport => iosRewardedExportUnitId,
    };
  }
}
