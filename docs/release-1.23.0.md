# Albumium 1.23.0 (35)

## Experience

- Separate Albums and Cards destinations. Existing card projects remain in the same storage envelope and are shown in Cards; previously embedded cards remain editable in old albums.
- Weekend, month and year prompts open a photo ordering and optional note flow. Drafts contain at most 20 selected photos, two per page, with the first photo used as the cover. A period key offers continuation of an existing draft.
- Opt-in local Android reminders use inexact AlarmManager scheduling at a configurable local time. Calendar collisions produce one notification with multiple choices. Preferences default to disabled. Reboot, clock/timezone changes and app updates restore scheduling; old notifications are not replayed indefinitely.
- Eighteen card templates across six categories, plus a blank canvas. Theme changes preserve messages. Saved personal templates create independent project/page/element identities. Text alignment works with main's new compact selection toolbar.
- Personal stickers support transparent PNG upload, automatic subject cutout, manual erasing/restoring, zoom, stroke undo and a white outline. Library deletion retains files used by existing projects.

## Storage and integrations

- Optional `memoryPeriod`, `coverPhotoPath` and text alignment fields retain defaults for older records. Legacy card IDs remain readable.
- Personal stickers use a namespaced media reference with an encoded path and aspect ratio. Package export includes sticker media without JPEG conversion, validates package-local references during import, and copies media into permanent storage. Covers and period metadata also survive package import.
- PNG transparency is preserved in the picker and compositor; the source alpha is not multiplied twice.
- Card templates and personal sticker indexes are separate versioned local preference records. No server, account or analytics integration was added.
- Android uses ML Kit Subject Segmentation 16.0.0-beta1. The model is downloaded by Google Play services. Unavailable model/services or an empty result leave manual editing available. First-use automatic cutout needs the model download.

## Validation

- Full Flutter suite: 205 tests passed. The 13 feature tests were rerun after the final theme-layout adjustment and passed. Flutter analysis is clean.
- Five Android calendar unit tests passed. Signed release APK built successfully with version name 1.23.0 and version code 35; delivery copy: `dist/Albumium-1.23.0.apk`.
- Flutter tests cover period dates, original notification dates on cold start, combined notification routing, draft ordering, legacy records, independent templates, alpha compositing, sticker/cover package round trips, persistent media references and responsive card layouts.
- Android unit tests cover leap years, year boundaries, overlapping periods, repeat scheduling and device timezone handling.
- Rendered card previews are generated in `build/review/card-collection.png` for visual review.
- Physical-device checks remain necessary for notification delivery under OEM battery restrictions, permission dialogs, model download and real-photo cutout quality, and hardware video encoding. No emulator or device was attached during implementation.

## Integration

- Updated local main to `671ab69` before final validation and preserved its single-row selection toolbar.
- No push or remote publication is part of this work.
