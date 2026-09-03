# Serverless album sharing

## Decision

Albumium should add a portable `.albumium` package as its primary app-to-app
sharing format. The package can be sent with the standard Android Sharesheet
and opened by another Albumium installation in a read-only viewer. This needs
no server, domain, account, or recurring infrastructure cost.

MP4 remains useful for social media, but it should not be the main way two
Albumium users exchange an interactive album.

## Why this is smaller than MP4

The current MP4 export renders many 1080 × 1920 frames for every second of the
album. A portable package stores the album structure once and each source
photo once. Decorations, fonts, themes, and animations already bundled in the
receiving app are referenced by identifier instead of copied into every video
frame.

The package should contain:

```text
albumium-package/
  manifest.json
  preview.webp
  media/
    <content-hash>.webp
```

- `manifest.json`: format version, minimum compatible app version, album data,
  media hashes, and read-only/import metadata.
- `preview.webp`: a small cover thumbnail for confirmation before import.
- `media/`: deduplicated, orientation-corrected photos. Cap the long edge for
  viewing and encode as WebP/JPEG at a measured quality setting.

Use a custom MIME type such as `application/vnd.albumium.album+zip`. Android
can send the file with `ACTION_SEND` and a temporary `content://` permission,
then route `ACTION_VIEW` for that MIME type back to Albumium. Android's
official guidance recommends the Sharesheet for sending binary content and a
`FileProvider` content URI for secure file sharing.

## User flow

1. The sender chooses **Share interactive album**.
2. Albumium creates the package locally and shows its estimated size.
3. The Android Sharesheet sends it through Quick Share, Bluetooth, WhatsApp,
   Telegram, email, Drive, or any installed file-capable app.
4. The receiver taps the file and Albumium shows the cover, sender-independent
   metadata, size, and page count.
5. The receiver chooses **View only** or **Import a copy**.

This works at a distance through any file-sharing service the users already
have, and in the same room through Quick Share/Bluetooth, without Albumium
operating storage infrastructure.

## Optional second phase: nearby transfer inside Albumium

Google Nearby Connections can discover another nearby device and transfer an
arbitrary file without internet connectivity. It is a good later enhancement
for a “Send to nearby Albumium user” button, but it adds Google Play services,
Bluetooth/Wi-Fi runtime permissions, connection confirmation, and more failure
states. The portable package should be built first because Nearby Connections
can transfer the same package later.

Direct Wi-Fi P2P is another serverless option, but Android's lower-level API
requires device discovery, connection management, sockets, permissions, and
hardware support handling. It offers little MVP benefit over the Sharesheet.

## Approaches not selected

- **Verified web/App Links:** require an HTTPS domain and a hosted
  `assetlinks.json`, so they conflict with the zero-infrastructure constraint.
- **QR code containing the album:** a QR code cannot carry the photos; without
  a server it can only carry a small handshake or metadata.
- **Public cloud database/storage:** free tiers can expire or change, introduce
  privacy and abuse controls, and eventually create an operating cost.

## Safety requirements

Treat every received package as untrusted input:

- enforce compressed and uncompressed size, media count, page count, and image
  dimension limits;
- reject absolute paths and `..` path traversal during extraction;
- validate schema and supported format version before writing anything;
- verify every media file against its declared SHA-256 hash;
- extract into a temporary directory and commit the import atomically;
- default to read-only viewing and create new local IDs when importing a copy;
- never execute package content or accept arbitrary font/script files.

## Recommended delivery order

1. Package encoder/decoder and round-trip/security tests.
2. Android Sharesheet export using a secure content URI.
3. Incoming `ACTION_VIEW` handling and read-only viewer.
4. Photo deduplication, downscaling, size estimate, and package preview.
5. Optional Nearby Connections transfer using the same package.

## Primary references

- [Android: send data to other apps](https://developer.android.com/develop/ui/compose/sharing/send)
- [Android: secure file sharing with FileProvider](https://developer.android.com/training/secure-file-sharing)
- [Android: intents and MIME-type filters](https://developer.android.com/guide/components/intents-filters)
- [Google Nearby Connections overview](https://developers.google.com/nearby/overview)
- [Google Nearby Connections setup and permissions](https://developers.google.com/nearby/connections/android/get-started)
- [Android Wi-Fi Direct overview](https://developer.android.com/develop/connectivity/wifi/wifip2p)
- [Android App Links and domain verification](https://developer.android.com/training/app-links/about)
