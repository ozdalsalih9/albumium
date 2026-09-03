import 'dart:io';

import 'package:albumium/services/video_export_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('video export progress', () {
    test('estimates weighted progress and remaining time', () {
      final estimate = estimateVideoExportProgress(
        completedFrames: 25,
        totalFrames: 100,
        elapsed: const Duration(seconds: 10),
      );

      expect(estimate.progress, closeTo(0.2425, 0.0001));
      expect(estimate.estimatedRemaining, const Duration(seconds: 30));
      expect(estimate.label, '24% · Geçen 00:10 · Tahmini kalan 00:30');
    });

    test('formats long elapsed times with hours', () {
      expect(
        formatExportDuration(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2:03:04',
      );
    });
  });

  group('temporary export files', () {
    test('uses a fixed app prefix and safe title segment', () {
      final name = albumiumExportFilename(
        title: '  Yaz / Anıları  ',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234),
        extension: '.MP4',
      );

      expect(name, 'albumium_export_Yaz_An_lar_1234.mp4');
      expect(
        () => albumiumExportFilename(
          title: 'Albüm',
          createdAt: DateTime(2026),
          extension: 'mov',
        ),
        throwsArgumentError,
      );
    });

    test('recognizes only old Albumium MP4 and PNG files', () {
      final now = DateTime(2026, 9, 1, 12);
      final old = now.subtract(const Duration(hours: 25));
      final recent = now.subtract(const Duration(hours: 2));

      expect(
        isStaleAlbumiumExportFile(
          path: '/tmp/albumium_export_story_1.mp4',
          modifiedAt: old,
          now: now,
        ),
        isTrue,
      );
      expect(
        isStaleAlbumiumExportFile(
          path: '/tmp/albumium_export_story_1.png',
          modifiedAt: recent,
          now: now,
        ),
        isFalse,
      );
      expect(
        isStaleAlbumiumExportFile(
          path: '/tmp/someone_else.mp4',
          modifiedAt: old,
          now: now,
        ),
        isFalse,
      );
      expect(
        isStaleAlbumiumExportFile(
          path: '/tmp/albumium_export_story_1.json',
          modifiedAt: old,
          now: now,
        ),
        isFalse,
      );
    });

    test(
      'cleanup stays shallow and preserves protected or unrelated files',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'albumium_export_test_',
        );
        addTearDown(() async {
          if (await directory.exists()) await directory.delete(recursive: true);
        });
        final nested = await Directory(
          '${directory.path}${Platform.pathSeparator}nested',
        ).create();
        final now = DateTime.now();
        final old = now.subtract(const Duration(hours: 25));

        Future<File> createFile(String name, {Directory? parent}) async {
          final file = File(
            '${(parent ?? directory).path}${Platform.pathSeparator}$name',
          );
          await file.writeAsString('data');
          await file.setLastModified(old);
          return file;
        }

        final staleMp4 = await createFile('albumium_export_old_1.mp4');
        final stalePng = await createFile('albumium_export_old_2.png');
        final protected = await createFile('albumium_export_active_3.mp4');
        final unrelated = await createFile('camera_roll.mp4');
        final nestedExport = await createFile(
          'albumium_export_nested_4.png',
          parent: nested,
        );

        final deleted = await cleanupStaleAlbumiumExports(
          directory,
          now: now,
          protectedPaths: {protected.path},
        );

        expect(deleted.toSet(), {staleMp4.path, stalePng.path});
        expect(await staleMp4.exists(), isFalse);
        expect(await stalePng.exists(), isFalse);
        expect(await protected.exists(), isTrue);
        expect(await unrelated.exists(), isTrue);
        expect(await nestedExport.exists(), isTrue);
      },
    );

    test('completed video must exist and contain bytes', () async {
      final directory = await Directory.systemTemp.createTemp(
        'albumium_video_validation_test_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final missing =
          '${directory.path}${Platform.pathSeparator}missing_export.mp4';
      final empty = File(
        '${directory.path}${Platform.pathSeparator}empty_export.mp4',
      );
      final valid = File(
        '${directory.path}${Platform.pathSeparator}valid_export.mp4',
      );
      await empty.create();
      await valid.writeAsBytes([0, 1, 2, 3]);

      await expectLater(requireNonEmptyVideoExport(missing), throwsStateError);
      await expectLater(
        requireNonEmptyVideoExport(empty.path),
        throwsStateError,
      );
      expect((await requireNonEmptyVideoExport(valid.path)).path, valid.path);
    });
  });
}
