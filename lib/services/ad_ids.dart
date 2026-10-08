import 'package:flutter/foundation.dart';

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

  /// The AdMob app id for iOS, also declared in ios/Runner/Info.plist.
  ///
  /// Google's sample app for simulator/TestFlight validation. Replace it in
  /// this file AND Info.plist before enabling live iOS ads.
  static const iosTestApplicationId = 'ca-app-pub-3940256099942544~1458002511';
  static const iosApplicationId = iosTestApplicationId;

  /// The rewarded unit for iOS. Empty until it exists; see [iosApplicationId].
  static const iosRewardedUnitId = '';

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

  static String get rewardedUnitId {
    if (!liveAds || !kReleaseMode) {
      return _isIOS ? iosTestRewardedUnitId : testRewardedUnitId;
    }
    return _isIOS ? iosRewardedUnitId : androidRewardedUnitId;
  }
}
