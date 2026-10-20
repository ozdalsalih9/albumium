# Paper atelier and selected cloud backups

## Artwork

The **Paper atelier** contains 8 photo frames, 6 paper/fabric scraps,
1 lace note, 4 corners, 5 tapes, and 6 wax seals. The page material picker
includes 16 patterned grounds. The scrapbook set adds 24 separate objects.

All new artwork is drawn by `lib/widgets/paper_materials.dart` and
`lib/widgets/scrapbook_art.dart` using original vector geometry and seeded
texture marks, then baked into bundled PNG assets. No image-generation model, downloaded
artwork, reference-image pixels, or third-party asset license is involved in this
collection. It is a stylized interpretation of the references, not scanned paper.
Existing collections are unchanged.

Use **Süsler** for paper scraps, tapes, corners, lace and seals; category chips
and a persisted recent-items list provide quick access. New paper frames are in
**Fotoğraf Stüdyosu → Çerçeve**, attached to their photo. Old albums containing
standalone frame stickers still render those objects.
Objects support move, rotate, scale, duplicate, layer order and locking.
Material identifiers survive saves, page duplication, gifts, video source copies,
and `.albumium` export/import. Old pages default to `plain`. Unknown future
patterns fall back to the existing theme decoration.

The review sheet is `output/paper-atelier/collection.png`. Regenerate it with:

```powershell
$env:PAPER_KIT_PREVIEW='1'
flutter test test/paper_materials_test.dart
```

## Photo Studio and scrapbook layouts

- Select a photo and choose **Düzenle**, or long-press it and choose **Düzenle**.
- **Şekil**, **Çerçeve**, and **Kırp** are separate groups. The live preview stays
  visible while scrolling controls. Frame thickness and inner spacing are adjustable.
- **Uygula** commits the draft; **Vazgeç**, close, and dismiss discard it.
- Apply a style to the selected photo, the page, or the album. Other photos keep
  their own crop and source; locked photos are skipped. Shapes may adjust their
  bounds around the original center. Grouped slots keep their layout geometry.
- Long-press decorations to lock/unlock them. The selected-object toolbar also
  exposes locking; locked pieces cannot be dragged or resized.
- **Sayfa → Kolaj sayfası ekle** inserts a new editable page after the current
  page. The card catalogue has the same seven themes under **Kolaj**:
  denim, western, fabric board, green botanical, red ribbons, birthday, and vinyl.
- Layouts contain independent photo slots, text and decorations. Re-theming a
  card retains filled photos (including excess photos), custom captions, user
  objects and locked pieces. Untouched template copy is replaced. Undo remains
  available. The artwork toggle hides generated decoration layers without deletion.

Runtime rendering uses shared asset-image caching rather than executing the
procedural artwork painters. Picker decodes are 120–160 pixels wide (narrow
strips are smaller); full artwork uses 200–600 pixels. Page backgrounds have a
separate repaint boundary. No on-device frame-time benchmark has been recorded.

Regenerate bundled artwork and actual-canvas thumbnails in this order:

```text
flutter test --no-pub tool/render_scrapbook_assets.dart
flutter test --no-pub tool/render_scrapbook_previews.dart
```

The seven-theme review sheet is `output/scrapbook-studio/templates.png`.
`test/scrapbook_studio_test.dart` covers legacy settings, serialization, draft
apply/cancel, crop-preserving style copy, locked objects, theme preservation,
small raster previews, recent items and long-press editing. The focused regression
run passed 72 tests, including package import, canvas gestures, crop geometry,
localization, theme switching and phone accessibility. Physical-device smoothness
still needs a device check.

## Back up and restore

- Preview → **Paylaş → Google Drive’a yedekle / iCloud’a yedekle**.
- Select the desired cloud folder in the system document picker.
- Collection → **Yedekten geri yükle** → select the `.albumium` file.
- The existing import screen validates and previews it before adding it to the
  library. Restore makes a copy; existing albums are not overwritten.

This is a user-initiated snapshot, not automatic synchronization. On Android,
Drive must be installed and signed in and exposed by the system file picker.
On iOS, iCloud Drive must be enabled in Files. Other installed providers and local
folders remain available. The app does not claim that a provider's local write
confirmation means a remote cloud upload is finished; the success message directs
users to Drive/Files to check upload status.

Backup mode preserves original media bytes. Ordinary interactive sharing keeps
its existing image optimization. Existing archive limits still apply: 160 MiB
package, 220 MiB expanded content, 32 MiB per media file, 160 media files,
80 pages, 1,200 elements. Export also reserves manifest space within the expanded
size limit so a saved backup remains eligible for restore.

Android uses [Storage Access Framework](https://developer.android.com/guide/topics/providers/document-provider)
with `ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT`. iOS uses
[UIDocumentPickerViewController export-as-copy](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init(forexporting:ascopy:)).
No OAuth client, broad storage permission, or private iCloud container is needed
for this user-selected document-provider workflow. Imports use bounded local
copies and the existing archive/path/hash validation. Provider reads/writes run
off the main thread. Cancellation produces no success message or imported album.

## Validation

- Tests cover legacy/default materials, serialization, transparent frame openings,
  artwork rendering, source-byte preservation after backup/restore, channel success,
  cancellation and failure/retry, translated artwork names, and the share menu.
- Android `:app:compileDebugKotlin --offline` passed on Windows.
- Before release, test on real Android and iPhone devices: cloud save, cancellation,
  offline/pending upload, restore after download on another device, missing provider,
  storage full, large package rejection, and iPad document presentation.
- iOS compilation and actual Drive/iCloud account transfers are not verified by
  the Windows tests.
- The focused set passes 58 tests across artwork, backup, package integrity,
  editor assets, localization, preview, and video-draft coverage. Analysis of the
  new artwork/backup files and directly related export code reports no issues.
- Separately, `test/editor_save_test.dart` fails its existing return-to-`Library`
  assertion after save-and-exit. Its original contents are retained; this check
  is not counted among the 58 passing tests. Full-project analysis also reports
  existing style/async-context notices outside the new feature code.
