# Albumium 1.16.0 (25)

## Home redesign

- Removed the library-card Share buttons. Sharing in the editor/reader is unchanged.
- Replaced the boxed welcome strip with a compact brand/settings row and a separate full-width welcome heading. Neither Turkish nor English welcome copy is truncated.
- Removed the hero panel, torn-paper collection heading, boxed library toolbar and album-tile backgrounds. Covers sit directly on the studio surface.
- Search uses a single underline; filters use understated underlined tabs, with sorting in a compact menu.
- Titles support two lines, with metadata directly beneath. Both reserve rounded line heights for larger system text settings.
- Kept creation accessible through an inline primary action and a smaller circular floating action, avoiding the previous wide overlay on covers.
- Search, pagination, long-press deletion, language switching, theme selection and album-opening animations remain in place.

## Verification

- `flutter test --no-pub --update-goldens --dart-define=UPDATE_HOME_QA=true -r expanded`: 171 passing tests.
- `flutter analyze --no-pub`: no issues.
- `flutter build apk --release`: succeeded; `dist/Albumium-1.16.0-build25-release.apk` (version code 25).
- Responsive widget tests cover Turkish and English at 320x740, 390x844, 768x1024 and 1024x768, including 1.4x/1.6x system text and a dark palette.
- Real bundled-font visual captures of phone and tablet layouts are generated with `flutter test test/home_redesign_test.dart --update-goldens --dart-define=UPDATE_HOME_QA=true` (ignored artifacts in `dist/`).
- Editor sharing remains covered by the existing editor controls test.
