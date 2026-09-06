# Albumium 1.19.0 (30)

## A consistent design across the application

- Lighter neutral surfaces in all four light/dark palettes, restrained outlines,
  consistent rounded controls and clearer functional typography. Display titles
  retain the Albumium serif, while navigation uses the more compact sans face.
- The home welcome card uses a softer tint. Its typewriter reserves the headline's
  actual laid-out space, including enlarged text and tablet constraints, and reveals
  whole characters. The supplied fabric background and cover-only library stay intact.
- Album and card creation choices use clear, spacious rows. Cover selection keeps
  the natural 15:22 book proportion, and binding choices wrap on narrow screens.
- Album editing uses a neutral tool dock, quieter page navigation, a clearer
  selection toolbar and a compact phone header with a direct share action.
  Binding remains available in the page menu and tablet header.
- Card editing uses swatch-based theme choices, evenly spaced tools and an improved
  header/share action. Album and card artwork is unchanged.
- The appearance picker displays actual palette swatches and descriptions;
  brightness choices stack vertically on narrow screens or with larger system text.
- Shared-album import, reader controls and sharing sheets use the same hierarchy.
  MP4 settings have simpler rows. Export progress uses readable light text on its
  dark overlay and an adaptive, scrollable layout on short screens.

## Delivery

- Tests were deliberately skipped at the user's request.
- No device or emulator visual QA was performed for this release.
- `flutter build apk --release` completed successfully; the APK is 92,491,843
  bytes (approximately 88.2 MiB).
- Release artifact: `dist/Albumium-1.19.0-build30-release.apk`.
