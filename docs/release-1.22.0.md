# Albumium 1.22.0 (34)

- 19 additional vector shape types in five colors (122 total choices), with searchable labels. Shape hit testing follows the same paths, including hollow centers.
- Reader zoom controls support 1–4x magnification, pan while enlarged and fit-to-screen. Existing page arrows remain available while zoomed.
- Android uses singleTask with normal application affinity and documentLaunchMode=never, routing incoming packages into the existing Albumium task through onNewIntent.
- Imported packages carry a content fingerprint independent of file names and archive/save timestamps. A serialized import operation reuses an existing local record without copying media or overwriting local edits. A changed source revision can be imported separately; deleting an imported record permits a fresh import.
- Imports retain locked state and custom card colors. Library reads refresh preferences to avoid stale cached data.

Validation: 24 focused shape, reader zoom, storage, package and intent-filter tests passed. Native WhatsApp task switching requires physical-device verification. Existing legacy duplicate records are not deleted automatically.
Android task behavior reference: https://developer.android.com/guide/components/activities/tasks-and-back-stack
Build: flutter build appbundle --release using the existing upload key.
