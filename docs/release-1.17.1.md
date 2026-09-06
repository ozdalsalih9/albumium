# Albumium 1.17.1 (27)

## Localized welcome spacing

- The welcome headline now reserves its final height using the exact width available to the rendered text.
- Turkish therefore keeps its natural single-line height instead of leaving an empty second line between the headline and description.
- English keeps its intentional two-line layout on narrow phones.
- The typewriter effect still runs from beginning to end without causing the description or action button to jump.

## Verification

- Focused home redesign tests cover Turkish/English copy, typewriter motion, reduced motion, phones, tablets and enlarged text.
- Turkish and English 390 logical-pixel visual captures were reviewed under `dist/`.
- `flutter analyze --no-pub` completed without issues.
- `flutter build apk --release` produced `dist/Albumium-1.17.1-build27-release.apk` (version code 27).
