# Albumium 1.21.0 (32)

- Contextual, labeled object controls replace the main toolbar in album and special-card editors; tap empty space or Done to return.
- Optional fine-adjustment directional controls and nine-position alignment; page center/edge guides and drag snapping account for scale and rotation.
- Persistent object locking prevents canvas transforms and disables editing actions until unlocked.
- Shape hit regions follow the painted paths; fitted sticker whitespace and unframed circular/arched photo corners pass taps through.
- Crop gestures start at pointer-down, with larger visible corners and an interactive gutter outside the photo.
- Special-card background colors and embedded card colors persist with the project.
- Theme-picker bottom padding includes the Android navigation inset.

Validation: nine focused selection/lock/fine-adjustment/crop tests passed. Full suite and physical-device checks were not run, per the request to keep verification short.
Build: flutter build appbundle --release, using the existing upload signing configuration.
