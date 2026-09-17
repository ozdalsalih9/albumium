
import 'package:albumium/models/cinematic_storyboard.dart';
import 'package:albumium/models/single_page_export_storyboard.dart';
import 'package:albumium/services/cinematic_soundtrack.dart';
import 'package:albumium/services/video_export_support.dart';
import 'package:albumium/widgets/photo_crop_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Export enhancements verification', () {
    test('5-page album storyboard duration is ~15-16 seconds with gentle pacing', () {
      final story = SinglePageExportStoryboard.forPages(5);

      expect(story.pageCount, 5);
      // 5 holds (63 frames) + 2 pans (29 frames) + 2 page turns (39 frames) = 451 frames = 15.033s
      expect(story.duration.inMilliseconds, 15033);
      expect(formatExportDuration(story.duration), '00:15');
    });

    test('video export quality has distinct bitrate and profile expectations', () {
      expect(VideoExportQuality.balanced.width, 720);
      expect(VideoExportQuality.balanced.videoBitrate, 4000000);

      expect(VideoExportQuality.fullHd.width, 1080);
      expect(VideoExportQuality.fullHd.videoBitrate, 10000000);
      expect(
        VideoExportQuality.fullHd.videoBitrate /
            VideoExportQuality.balanced.videoBitrate,
        2.5,
      );
    });

    test('melodic soundtrack generates varied musical content across time', () {
      final storyboard = CinematicStoryboard.forPositions(3);

      final frameAtBar1 = CinematicSoundtrack.pcmFrame(
        storyboard: storyboard,
        frameIndex: 30,
        fps: 30,
      );
      final frameAtBar2 = CinematicSoundtrack.pcmFrame(
        storyboard: storyboard,
        frameIndex: 120,
        fps: 30,
      );

      expect(frameAtBar1, hasLength(6400));
      expect(frameAtBar2, hasLength(6400));
      expect(frameAtBar1, isNot(orderedEquals(frameAtBar2)));
    });

    test('photo crop editor peekLoadedAlbumPhoto returns null for unknown path safely', () {
      expect(peekLoadedAlbumPhoto('unknown_path_not_in_cache'), isNull);
    });
  });
}
