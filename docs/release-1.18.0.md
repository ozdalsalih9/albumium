# Albumium 1.18.0 (28)

## Theme-aware velvet home surface

- The home page now uses a quiet woven velvet texture derived from the active theme's background, text and accent colors.
- The texture stays behind the complete home page, follows light/dark theme changes and is isolated in a repaint boundary so scrolling and headline motion do not repaint it.
- The weave is drawn locally without a bitmap asset, network request or additional package.

## Cleaner library covers

- Album names are hidden inside book artwork on the home page; each name appears once in the caption below its cover.
- Other uses of the reusable 3D cover keep their original title treatment by default.
- Occasion cards are unchanged.

## Verification

- All 173 tests passed; focused coverage includes Turkish/English, phones, portrait/landscape tablets, enlarged text, reduced motion, the velvet variant and home-only hidden cover titles.
- Updated phone and tablet visual QA captures were reviewed under `dist/`.
- `flutter analyze --no-pub` completed without issues.
- `flutter build apk --release` produced `dist/Albumium-1.18.0-build28-release.apk` (version code 28).
