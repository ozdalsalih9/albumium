# Albumium 1.15.0 (23)

## Photos and transforms

- Album and occasion-card photo imports use the decoded original aspect ratio and fit within the page. New photos explicitly show their full source, including inside padded frames.
- Added a photo crop action to both editors. Drag corners to choose a region, drag inside to reposition, apply to save, or show the full original again. Back cancels without changing the element.
- Cropping is non-destructive: normalized source coordinates are stored in album JSON; the original image file is not rewritten. The photo shape returns to Free when a crop is applied.
- Legacy photos retain their existing appearance until explicitly edited. Use Crop photo > Show full photo > Apply to reveal previously hidden edges.
- Crop metadata survives element/page duplication, package preview and imported copies. The shared canvas renderer applies it to reader, PNG and MP4 captures.
- The visible rotation stem/handle now works for every selected element, including shapes, decorative icons and saved handwriting. Existing pinch, resize and save-transaction behavior is unchanged.
- All new interface copy is available in Turkish and English.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub -r expanded`: 163 passing tests.
- `flutter build apk --release`: succeeded; `dist/Albumium-1.15.0-build23-release.apk`.
- Added portrait/landscape/panorama geometry tests, crop serialization and malformed-data recovery tests, package crop round-trip checks, and pixel checks for full-source versus cropped rendering.
- Crop dragging, reset, apply and cancellation tested at 390x844 and 960x600 logical pixels.
- Rotation handle gestures tested under ancestor scaling for photos, stickers/shapes and drawing elements; updates commit once on completion.
- Physical-device gallery/WhatsApp testing remains a manual follow-up; widget and rendering tests do not simulate the OS photo picker or WhatsApp.
