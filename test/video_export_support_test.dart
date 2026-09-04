import 'dart:io';

import 'package:albumium/models/single_page_export_storyboard.dart';
import 'package:albumium/services/video_export_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('video quality and rendering', () {
    test('balanced defaults reduce size and frame memory at the same FPS', () {
      const settings = VideoExportSettings();
      expect(settings.quality, VideoExportQuality.balanced);
      expect(settings.quality.width, 720);
      expect(settings.quality.height, 1280);
      expect(settings.quality.videoBitrate, 3000000);
      expect(settings.fps, 30);
      expect(settings.audioBitrate, 128000);
      expect(settings.estimatedBytes(const Duration(seconds: 60)), 23460000);
      expect(settings.estimatedBytes(Duration.zero), 0);
      expect(settings.estimatedBytes(const Duration(seconds: -1)), 0);
      expect(
        settings.quality.rgbaFrameBytes / (1080 * 1920 * 4),
        closeTo(4 / 9, 0.0001),
      );
    });

    test('Full HD preserves resolution with a lower target bitrate', () {
      const settings = VideoExportSettings(
        quality: VideoExportQuality.fullHd,
        includeSoundtrack: false,
      );
      expect(settings.quality.width, 1080);
      expect(settings.quality.height, 1920);
      expect(settings.quality.videoBitrate, 6000000);
      expect(settings.audioBitrate, 0);
      expect(settings.estimatedBytes(const Duration(seconds: 60)), 45000000);
      for (final quality in VideoExportQuality.values) {
        expect(quality.width / quality.height, 9 / 16);
        expect(quality.width.isEven, isTrue);
        expect(quality.height.isEven, isTrue);
      }
    });

    test('reuses static captures but captures every animation frame', () {
      final storyboard = SinglePageExportStoryboard.forPages(4);
      var captures = 0;
      var encodedFrames = 0;
      for (final beat in storyboard.beats) {
        var beatCaptures = 0;
        for (var frame = 0; frame < beat.frameCount; frame++) {
          if (shouldCaptureSinglePageVideoFrame(
            beat: beat,
            localFrame: frame,
          )) {
            beatCaptures++;
            captures++;
          }
          // Encoding (and its matching audio frame) runs even for reused holds.
          encodedFrames++;
        }
        expect(beatCaptures, beat.isTransition ? beat.frameCount : 1);
      }
      expect(encodedFrames, storyboard.totalFrames);
      expect(captures, lessThan(storyboard.totalFrames ~/ 2));
      expect(storyboard.fps, const VideoExportSettings().fps);
    });
  });

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
