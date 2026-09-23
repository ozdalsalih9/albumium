import 'package:flutter/foundation.dart';

/// AdMob identifiers.
///
/// None of these are secret: they ship inside the APK and are readable by
/// anyone who opens it. They live in one file so the value in the Android
/// manifest and the value the code loads can be checked against each other.
abstract final class AdIds {
  /// The AdMob app id, also declared in AndroidManifest.xml.
  ///
  /// A wrong or missing value crashes the app the moment the SDK starts, so a
  /// test compares this constant with the manifest.
  static const androidApplicationId = 'ca-app-pub-3816017115155014~2314787625';

  /// The rewarded unit that pays for one Full HD export.
  static const androidRewardedUnitId = 'ca-app-pub-3816017115155014/8093727919';

  /// Google's public test unit, which always fills and never earns revenue.
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

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

  static String get rewardedUnitId =>
      liveAds && kReleaseMode ? androidRewardedUnitId : testRewardedUnitId;
}
