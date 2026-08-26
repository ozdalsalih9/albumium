import 'dart:io';

import 'package:albumium/models/album_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every album theme has a bundled physical cover', () {
    for (final theme in albumThemes) {
      expect(
        theme.coverAsset,
        isNotNull,
        reason: '${theme.name} needs a physical cover artwork',
      );
      expect(
        File(theme.coverAsset!).existsSync(),
        isTrue,
        reason: '${theme.name} cover asset is missing',
      );
    }
  });

  test('vintage and minimal covers are distinct from soft romance', () {
    final soft = themeById('soft_romance').coverAsset;
    final vintage = themeById('vintage_diary').coverAsset;
    final minimal = themeById('minimal_editorial').coverAsset;

    expect(vintage, isNot(soft));
    expect(minimal, isNot(soft));
    expect(minimal, isNot(vintage));
  });
}
