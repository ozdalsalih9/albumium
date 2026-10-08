# iOS: one use per rewarded ad

This replaces the iOS purchase setup in `ios-release.md` and the previous
18-product App Store release checklist. Android retains its purchases and ads.

On iOS, billing is not started. Purchase and restore actions and catalogue
prices are hidden. Premium covers earn one new album, custom stickers earn
one new saved sticker, and Full HD earns one successfully generated 1080p video.
Grants live only in memory. Cancellation and failed work leave an earned use
available during the current app session; successful work consumes it. Closing
an ad before its reward callback, no inventory, or an SDK failure grants nothing.
Existing albums and saved stickers remain usable. Old purchase preferences
are retained but do not bypass the iOS ad gates.

## Ad configuration

The current iOS app uses Google's sample application ID and iOS rewarded test
unit. This is for simulator/TestFlight validation and earns no revenue.
Android's existing AdMob IDs and default test/live behavior are unchanged.

Before a public iOS ad release:

- Register the iOS app in AdMob and create a rewarded unit.
- Replace `AdIds.iosApplicationId` and the matching `GADApplicationIdentifier`
  in `ios/Runner/Info.plist`; set `AdIds.iosRewardedUnitId`.
- Pass `--dart-define=ALBUMIUM_LIVE_ADS=true` to the iOS IPA build only after
  real IDs are configured. A live release with the sample app or no unit will
  not initialize ads. Codemagic currently produces test-ad candidates.
- Configure Google's UMP privacy messages for the iOS app. The existing consent
  flow must allow ad requests; retry is available if consent/loading is not ready.
- Review App Store App Privacy and the final SDK privacy report. The previous
  ad-free "Data Not Collected" answer must be reassessed for the ad SDK. ATT is
  required if tracking is enabled; this change does not request tracking access.

## Acceptance

Run `flutter analyze`, `flutter test`, then Codemagic `ios-validation` and
`ios-testflight`. Windows cannot compile the iOS app.

On iPhone/iPad, validate reward completion, early close, no fill, consent refusal,
and retry. Verify each second album/sticker/export requests another ad, cancelled
or failed work preserves the current grant, and restarting discards unused grants.
Check both cover catalogue/detail and new album picker, both sticker entry points,
and both video export screens. Android must retain its price, purchase, restore,
and existing rewarded Full HD behavior.

Sources: https://developers.google.com/admob/flutter/rewarded
and https://developers.google.com/admob/ios/quick-start
