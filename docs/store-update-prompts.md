# Store update prompts

The library screen checks released store versions in the background and shows
**Yeni sürüm var / A new version is available** with **Güncelle / Update** and
**Daha sonra / Later**. It does not interrupt editors, onboarding or exports,
force an installation, or download an APK itself.

- Android uses Google's `app-update:2.1.0` availability API. The update button
  opens this application's Play listing, with an HTTPS fallback if Play cannot
  launch. Availability respects the user's eligible Play release/track.
- iOS reads the installed bundle identifier and marketing version from the app,
  then queries Apple's software lookup in the device's configured region.
  The returned bundle, version, App Store URL and minimum iOS version are checked
  before displaying a prompt. The button opens the corresponding App Store page.
  No manually entered numeric App Store ID is required. Devices configured for a
  region where the app is unavailable may get no result; a different Apple
  account storefront is not inferred from the device region.
- Checks run on entering the library and resuming the app. Successful checks
  are cached in process for six hours; failed checks retry after 15 minutes.
  Returning from the store forces a fresh check. No network request blocks UI.
- Later hides that specific release for 24 hours, persisted across restarts.
  A newer release can appear immediately. Connection/lookup failures stay silent;
  store-launch failure shows a retryable message.

## Rollout and verification

This code must first be shipped in a store release. It cannot add prompts to
older installed binaries that do not contain the update checker. Subsequent
published versions must increase Android `versionCode` and iOS marketing version
as usual. Do not require or assume a production update for a sideloaded/debug APK.

Android Kotlin compilation is verified on Windows. Flutter tests cover numeric
version comparison, matching/compatible Apple results, malformed responses,
store-opening failure, quiet offline behavior, concurrent checks, throttling,
resume after updating, per-release snooze and Turkish/English large-text layouts.
iOS native compilation requires macOS/Xcode and is not verified on Windows.

Before rollout, install an older build containing this feature through a Play
test track, publish a higher version in the same eligible track, and confirm the
banner opens the correct listing. Verify App Store lookup and opening on an
iPhone, including configured region, offline operation and post-update removal.

References:
- https://developer.android.com/guide/playcore/in-app-updates/kotlin-java
- https://developer.android.com/guide/playcore/in-app-updates/test
- https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/LookupExamples.html
