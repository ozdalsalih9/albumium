import 'dart:io';

import 'package:albumium/services/ad_ids.dart';
import 'package:flutter_test/flutter_test.dart';

/// The manifest carries values the SDK reads before any Dart runs, so nothing
/// in the app can check them at runtime. This test is the only place they are
/// compared with what the code expects.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('the ad SDK gets the network and the advertising id', () {
    // Albumium ran without either until rewarded ads arrived; both are now
    // required, and their absence would only show up as ads never loading.
    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
  });

  test('the declared AdMob app id is the one the code was built against', () {
    expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
    // A placeholder or a mismatched id crashes the app as the SDK starts.
    expect(manifest, contains(AdIds.androidApplicationId));
    expect(AdIds.androidApplicationId, startsWith('ca-app-pub-'));
    expect(AdIds.androidApplicationId, contains('~'));
  });

  test('the rewarded unit belongs to the same AdMob account', () {
    final account = AdIds.androidApplicationId.split('~').first;
    expect(AdIds.androidRewardedUnitId, startsWith('$account/'));
  });

  test('live ads are off unless a build asks for them', () {
    // Watching your own live ads is invalid traffic, and Google suspends
    // accounts for it. Only a build passing ALBUMIUM_LIVE_ADS goes live.
    expect(AdIds.liveAds, isFalse);
    expect(AdIds.rewardedUnitId, AdIds.testRewardedUnitId);
  });
}
