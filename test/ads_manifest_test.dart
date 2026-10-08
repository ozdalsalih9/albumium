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
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

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

  test('iOS stays silent until its AdMob app exists', () {
    // AdMob issues a separate app and separate units per platform. Until the
    // iOS ones are made, the SDK must not start there: it throws without an
    // app id, and a crash is worse than no ads.
    if (AdIds.iosApplicationId.isEmpty) {
      expect(
        AdIds.iosRewardedUnitId,
        isEmpty,
        reason: 'a unit without an app id would be requested against nothing',
      );
      expect(
        infoPlist,
        isNot(contains('GADApplicationIdentifier')),
        reason: 'the plist would promise an SDK the code never starts',
      );
      return;
    }

    // Once they exist, the plist and the code have to agree, exactly as they
    // do on Android.
    expect(infoPlist, contains('GADApplicationIdentifier'));
    expect(infoPlist, contains(AdIds.iosApplicationId));
    expect(AdIds.iosApplicationId, contains('~'));
    expect(
      AdIds.iosRewardedUnitId,
      startsWith('${AdIds.iosApplicationId.split('~').first}/'),
    );
    // Apple requires the tracking prompt before personalised ads.
    expect(infoPlist, contains('NSUserTrackingUsageDescription'));
    expect(
      infoPlist,
      contains('SKAdNetworkItems'),
      reason: 'without these, iOS ad revenue cannot be attributed',
    );
  });

  test('live ads are off unless a build asks for them', () {
    // Watching your own live ads is invalid traffic, and Google suspends
    // accounts for it. Only a build passing ALBUMIUM_LIVE_ADS goes live.
    expect(AdIds.liveAds, isFalse);
    expect(AdIds.rewardedUnitId, AdIds.testRewardedUnitId);
  });
}
