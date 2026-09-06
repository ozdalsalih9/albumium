# Albumium 1.17.0 (26)

## Branded home experience

- The illustrated brand mark supplies the initial A; the adjacent wordmark now renders `lbumium`. TalkBack still announces the complete `Albumium` brand.
- The welcome area is one intentional, theme-aware gradient card with a subtle border, soft depth and orbit-like memory lines. Search, filters and library items remain open and unboxed.
- The localized welcome headline uses the Albumium display face and types once from beginning to end after the launch overlay leaves the screen. Its final geometry is reserved, so the subtitle and button do not jump while letters appear.
- The finite animation does not replay for search, filter, theme or navigation rebuilds. Language changes show the translated final copy without character-by-character announcements.
- Android reduced-motion/disabled-animation preference skips directly to the complete headline.

## Book proportions

- Album covers are constrained to their original 300:440 book ratio instead of stretching into arbitrary grid slots. Occasion cards retain their 5:7 ratio.
- The library uses a 220 logical-pixel maximum column width, keeping two columns on phones while presenting a denser shelf on tablets.
- Title and metadata sizing continue to support 1.6x system text without overflow.

## Verification

- `flutter test --no-pub -r expanded`: all 173 tests passed.
- `flutter analyze --no-pub`: no issues.
- `flutter build apk --release`: succeeded; `dist/Albumium-1.17.0-build26-release.apk` (version code 26).
- Focused tests cover launch synchronization, a visible intermediate typewriter frame, full headline semantics, reduced motion, 300:440 cover geometry, Turkish/English copy, phones, portrait/landscape tablets, and enlarged text.
- Real bundled-font visual captures are generated under `dist/` by the optional golden QA mode.
