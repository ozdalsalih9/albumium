# Albumium 1.30.3 (55)

The original Animals, Best Friends, Soft Romance, Dark Leather, Vintage Diary,
Travel Postcard and Minimal Editorial cover assets already contain a book
spine. Restore their full-width artwork, rounded left edge, original title
plate placement and spine lighting without adding an extra solid-color strip.

Other cover assets retain the front-face layout introduced in 1.30.2. Custom
cover photos also retain that layout, including on the seven original themes,
because the photos do not contain the pre-rendered spine.

The fix is in the shared Flutter cover widget used on Android and iOS. The text
dragging fix and the iOS Google Mobile Ads build compatibility settings remain.

Android release outputs use version name 1.30.3 and version code 55. Native iOS
build validation must be run on macOS/Codemagic.

Validation: Flutter analysis passed. All 21 permanent cover tests passed, plus
a temporary render check used to inspect Animals, Best Friends and Nikâh Kemeri
side by side. The temporary render harness was removed after visual inspection.
