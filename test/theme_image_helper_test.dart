import 'dart:io';

import 'package:albumium/themes/theme_image_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackedFile implements File {
  _TrackedFile(this.path);

  @override
  final String path;

  int statCount = 0;

  @override
  bool existsSync() {
    statCount++;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('normal photo paths do not synchronously query the filesystem', () {
    final files = <_TrackedFile>[];
    IOOverrides.runZoned(
      () {
        for (final path in [
          '/data/user/0/albumium/files/photo.jpg',
          r'C:\albumium\photo.jpg',
          'albumium_images/photo.jpg',
        ]) {
          final provider = themeImageProvider(path) as ResizeImage;
          expect(provider.width, themeImageCacheWidth);
          expect((provider.imageProvider as FileImage).file.path, path);
        }
      },
      createFile: (path) {
        final file = _TrackedFile(path);
        files.add(file);
        return file;
      },
    );

    expect(files, hasLength(3));
    expect(files.every((file) => file.statCount == 0), isTrue);
  });

  test('bare asset fallback and export decode keys are unchanged', () {
    final file = _TrackedFile('paper.png');
    IOOverrides.runZoned(() {
      final provider = themeImageProvider('paper.png') as ResizeImage;
      expect(provider.imageProvider, const AssetImage('paper.png'));
    }, createFile: (_) => file);
    expect(file.statCount, 1);

    for (final path in [
      'assets/covers/cover-rose-heirloom.png',
      'https://example.com/photo.jpg',
      '/photos/original.jpg',
    ]) {
      expect(themeImageProvider(path), themeImageProvider(path));
      expect(
        themeImageProvider(path, cacheWidth: null),
        isNot(isA<ResizeImage>()),
      );
    }
  });
}
