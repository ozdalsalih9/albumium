# Albumium 1.14.0 (22)

## Experience

- Replaced full-screen cork/paper backdrops with a quiet studio surface across the library, editor, reader, theme chooser and card studio. Album paper, covers and decorations are unchanged.
- Added a labelled Share action to album cards and the editor app bar. Both open the existing export choices immediately.
- Removed infrastructure-oriented sharing copy in Turkish and English.
- Library cards are aligned, rounded surfaces; the hero fills tablet width without floating tape decorations.

## Performance

- Static page paper and ornaments repaint independently from dragged elements.
- Interactive element visuals retain their display lists during transforms.
- Normal imported photo paths no longer trigger synchronous filesystem checks during builds.
- ThemeData is cached for the active palette; library filtering/sorting is reused until the query or collection changes.
- Static MP4 holds reuse one captured RGBA buffer. Transition frames and audio samples are still encoded on the unchanged 30 FPS timeline.

## MP4 profiles

| Profile | Resolution | Video | Optional audio | 60-second bitrate estimate |
| --- | --- | --- | --- | --- |
| Previous default | 1080 × 1920 | 12 Mbps | 192 kbps | 91.44 MB |
| Balanced (new default) | 720 × 1280 | 3 Mbps | 128 kbps | 23.46 MB |
| High | 1080 × 1920 | 6 Mbps | 128 kbps | 45.96 MB |

These are bitrate estimates, not file-size guarantees. Content and hardware encoding affect actual output. Balanced reduces each captured RGBA buffer from 8,294,400 to 3,686,400 bytes. PNG output remains 1080 × 1920.

## Verification

- All 155 automated tests passed. Final home-only polish was followed by 10 focused tests and a clean analysis.
- Android release APK built successfully.
- Phone and landscape-tablet UI checked on a temporary Android API 35 emulator.
- A three-page test album exported to H.264/AAC MP4, 720 × 1280, 5.6667 seconds, 1,923,616 bytes, and reached the system share sheet. No external recipient was selected.
- Visual QA artifacts remain local in `dist/`; physical-device throughput has not been benchmarked.
