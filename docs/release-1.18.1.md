# Albumium 1.18.1 (29)

## Supplied fabric background

- The generated weave has been replaced by the supplied natural fabric image at `assets/textures/home-fabric.png`.
- The 816 × 1056 source is rendered at half scale and repeated in both directions, covering phones and tablets without stretching or visible empty areas.
- Theme background and accent colors are blended into the texture, preserving the real fibers across every light and dark palette.
- The cached image layer remains inside a repaint boundary so library scrolling and headline animation do not repaint it.

## Verification

- Focused background and home layout tests passed in Turkish and English across phone, portrait tablet and landscape tablet dimensions.
- Automated checks confirm the supplied image is bundled, repeated and recolored when the theme changes.
- Light phone and dark landscape-tablet QA captures were visually reviewed without visible tile seams or readability regressions.
- `flutter analyze --no-pub` completed without issues.
- `flutter build apk --release` produced `dist/Albumium-1.18.1-build29-release.apk` (version code 29).
