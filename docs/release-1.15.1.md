# Albumium 1.15.1 (24)

- Fixed empty bands between cropped photos and their frames. The previous renderer fitted the photo inside an independently sized frame; both the physical page aspect ratio and frame padding could introduce letterboxing.
- Free-aspect cropped photos now size their frame around the exact source crop and scale the complete framed image uniformly into the element bounds. No additional image content is cut off or stretched. Existing saved crops automatically use the fix without recropping.
- Frame insets include asymmetric mats and Container border padding. Regression coverage measures all 16 actual frame layouts for full/cropped photos at three page sizes (96 combinations).
- The album model and legacy shape masks are unchanged; the same rendering path is used in the editor, reader and exports.
- Includes the photo-cropping and all-element rotation features from 1.15.0.

## Verification

- `flutter test --no-pub -r expanded`: all 163 tests passed.
- `flutter analyze --no-pub`: no issues.
- `flutter build apk --release`: succeeded; `dist/Albumium-1.15.1-build24-release.apk` (version code 24).
- The frame regression checks include exact child dimensions and transformed aspect ratios, so incorrect padding or independently stretched frames fail the test.
