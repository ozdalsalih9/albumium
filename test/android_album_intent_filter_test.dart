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
}
