# Albumium 1.30.2 (54)

- Dragging a selected text element selects it for transformation without opening
  the text editor. A deliberate tap on the selected element still opens editing.
- The physical cover reserves 8.5% of its width for the spine. Artwork and the
  title plate occupy the front face; the spine no longer overlays the design.
- These changes use shared Flutter widgets on Android and iOS.

## Validation

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 373 tests passed, including selected-text drag
  regression coverage with Android and iOS target platforms and small/large
  cover layout checks.
- Rendered and visually checked the wedding-arch cover with its reserved spine.
- Native iOS compilation and physical-device checks remain pending.

## Android

Build the signed bundle with `flutter build appbundle --release`. The version in
`pubspec.yaml` is 1.30.2+54. Release signing uses the existing local
`android/key.properties`; never commit credentials.

## iOS via Codemagic

1. Commit and push these changes to the GitHub branch to be built.
2. In the Albumium Codemagic project, select that branch and run `ios-validation`
   for analysis, Flutter tests, the simulator build and native tests.
3. Run `ios-testflight` with the `Albumium Codemagic` App Store Connect
   integration and App Store signing configured for `com.albumium.albumium`.
4. Ensure Codemagic's `PROJECT_BUILD_NUMBER` is greater than the last uploaded
   App Store Connect build number. This overrides the local build number 54.
5. The workflow produces an IPA and uploads it to TestFlight. It does not submit
   the app for App Store review. Check the text gestures and cover layout on an
   iPhone/iPad before release.

Windows cannot run the native iOS build. Shared-widget tests with the iOS theme
are not a substitute for a Codemagic build or real-device validation.

## iOS Google Mobile Ads build compatibility

Codemagic reported a non-modular-header compile error in
`google_mobile_ads.FLTAd_Internal` and `google_mobile_ads.FLTAdPreloader`.
The plugin version 9.1.0 imports `GoogleMobileAds_Beta.h`, shipped in the SDK's
private headers rather than its public module map.

The Podfile enables `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`
for the `google_mobile_ads` pod in all configurations. Runner's Debug and
Release/Profile xcconfigs also enable it because the plugin is imported by the
generated registrant. Other pod targets keep their existing settings.

Run `ios-validation` on the updated GitHub commit to verify the native fix, then
`ios-testflight`. This configuration change does not alter the Android bundle.
