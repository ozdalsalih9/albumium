import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android can receive Albumium files normalized by messaging apps', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    for (final mimeType in const [
      'application/vnd.albumium.album+zip',
      'application/octet-stream',
      'application/zip',
      'application/x-zip-compressed',
    ]) {
      expect(
        RegExp(
          RegExp.escape('android:mimeType="$mimeType"'),
        ).allMatches(manifest),
        hasLength(2),
        reason: '$mimeType must support both VIEW and SEND intents.',
      );
    }
  });

  test(
    'native bridge accepts the normalized MIME before package validation',
    () {
      final source = File(
        'android/app/src/main/kotlin/com/albumium/albumium/MainActivity.kt',
      ).readAsStringSync();

      expect(source, contains('resolvedType in ALBUM_CONTAINER_MIMES'));
      for (final mimeType in const [
        'application/octet-stream',
        'application/zip',
        'application/x-zip-compressed',
      ]) {
        expect(source, contains('"$mimeType"'));
      }
    },
  );
}
