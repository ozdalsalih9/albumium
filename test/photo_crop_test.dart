import 'dart:ui' as ui;
import 'dart:io';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/photo_crop_editor.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumElementModel photo() => AlbumElementModel(
  id: 'photo',
  type: AlbumElementType.photo,
  content: 'original.jpg',
  x: .15,
  y: .2,
  width: .7,
  height: .5,
);

void main() {
  testWidgets(
    'canvas/export pixels show full source or precisely selected crop',
    (tester) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 20, 20),
        Paint()..color = Colors.red,
      );
      canvas.drawRect(
        const Rect.fromLTWH(0, 20, 20, 20),
        Paint()..color = Colors.blue,
      );
      final picture = recorder.endRecording();
      final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('albumium_crop_'),
      );
      final file = File('${directory!.path}/source.png');
      await tester.runAsync(() async {
        final image = await picture.toImage(20, 40);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      picture.dispose();
      addTearDown(() => directory.delete(recursive: true));
      // Warm the exact image provider used by MP4 capture.
      final info = await tester.runAsync(() => loadAlbumPhoto(file.path));
      info!.dispose();
      final key = GlobalKey();
      Future<List<int>> pixel(Rect crop, int y, double height) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 100,
                  height: height,
                  child: CroppedAlbumPhoto(path: file.path, crop: crop),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final output = await boundary.toImage();
          final data = await output.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          output.dispose();
          return data!.buffer.asUint8List();
        });
        return bytes!.sublist((y * 100 + 50) * 4, (y * 100 + 50) * 4 + 4);
      }

      expect(await pixel(fullPhotoCrop, 10, 200), [244, 67, 54, 255]);
      expect(await pixel(fullPhotoCrop, 190, 200), [33, 150, 243, 255]);
      expect(await pixel(const Rect.fromLTRB(0, .5, 1, 1), 10, 100), [
        33,
        150,
        243,
        255,
      ]);
      expect(tester.takeException(), isNull);

      // Reproduce the real 2:3 book page, a differently-proportioned card, and
      // export resolution. No frame may introduce letterboxing or stretching.
      for (final pageSize in [
        const Size(300, 450),
        const Size(500, 700),
        const Size(720, 1080),
      ]) {
        for (final crop in [
          fullPhotoCrop,
          const Rect.fromLTRB(.1, .15, .9, .7),
        ]) {
          for (var style = 0; style < albumPhotoFrameCount; style++) {
            final element = photo()
              ..content = file.path
              ..photoCrop = crop
              ..frameStyle = style;
            await tester.pumpWidget(
              MaterialApp(
                home: Center(
                  child: SizedBox(
                    width: pageSize.width,
                    height: pageSize.height,
                    child: AlbumPageCanvas(
                      page: AlbumPageModel(
                        id: 'frame-test',
                        backgroundColor: 0xFFFFFFFF,
                        elements: [element],
                      ),
                      theme: const AlbumThemePreset(
                        id: 'test',
                        name: '',
                        subtitle: '',
                        emoji: '',
                        coverStart: Colors.white,
                        coverEnd: Colors.white,
                        pageColor: Colors.white,
                        accent: Colors.black,
                        textureLabel: '',
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final imageRect = tester.getRect(
              find.byKey(const ValueKey('cropped-photo-pixels')),
            );
            final expectedAspect = .5 * crop.width / crop.height;
            expect(
              imageRect.width / imageRect.height,
              closeTo(expectedAspect, 1e-6),
              reason: 'Frame $style must hug the full crop at $pageSize',
            );
            expect(
              tester
                  .getSize(find.byKey(const ValueKey('cropped-photo-pixels')))
                  .width,
              closeTo(240, 1e-6),
              reason: 'Frame $style insets must match actual layout',
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
  test(
    'portrait, landscape and panoramic imports retain full aspect on page',
    () {
      for (final aspect in [924 / 1644, 4 / 3, 1.0, 4.0, .2]) {
        final size = albumPhotoSize(aspect);
        expect(size.width * (5 / 7) / size.height, closeTo(aspect, 1e-9));
        expect(size.width, lessThanOrEqualTo(.76));
        expect(size.height, lessThanOrEqualTo(.70000001));
      }
    },
  );

  test(
    'non-destructive crop persists and old albums retain legacy rendering',
    () {
      final element = photo();
      expect(AlbumElementModel.fromJson(element.toJson()).photoCrop, isNull);
      const crop = Rect.fromLTRB(.1, .2, .9, .8);
      applyAlbumPhotoCrop(element, crop, .5625);
      expect(element.content, 'original.jpg');
      expect(
        element.width * (5 / 7) / element.height,
        closeTo(.5625 * crop.width / crop.height, 1e-9),
      );
      expect(element.photoShape, AlbumPhotoShape.free);
      expect(AlbumElementModel.fromJson(element.toJson()).photoCrop, crop);
      applyAlbumPhotoCrop(element, fullPhotoCrop, .5625);
      expect(element.width * (5 / 7) / element.height, closeTo(.5625, 1e-9));
      expect(element.content, 'original.jpg');
    },
  );

  test('invalid crop metadata is ignored without losing the photo', () {
    for (final invalid in [
      [],
      [0, 0, 0, 1],
      [1, 1, 0, 0],
      [0, double.nan, 1, 1],
      ['x', 0, 1, 1],
      'crop',
    ]) {
      expect(
        AlbumElementModel.fromJson({
          ...photo().toJson(),
          'photoCrop': invalid,
        }).photoCrop,
        isNull,
      );
    }
    expect(parsePhotoCrop([-1, -1, 2, 2]), fullPhotoCrop);
  });

  for (final screen in [const Size(390, 844), const Size(960, 600)]) {
    testWidgets('crop drag, reset, apply and cancel at $screen', (
      tester,
    ) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Colors.blue, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(90, 160));
      picture.dispose();
      addTearDown(image!.dispose);
      Rect? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Rect>(
                    MaterialPageRoute(
                      builder: (_) => PhotoCropEditor(
                        image: image,
                        initialCrop: fullPhotoCrop,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final surface = find.byKey(const ValueKey('photo-crop-surface'));
      final bounds = tester.getRect(surface);
      final gesture = await tester.startGesture(
        bounds.topLeft + const Offset(3, 3),
      );
      await gesture.moveBy(const Offset(22, 22));
      await tester.pump();
      await gesture.moveBy(const Offset(25, 35));
      await tester.pump();
      await gesture.up();
      await tester.tap(find.byKey(const ValueKey('photo-crop-apply')));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.left, greaterThan(0));
      expect(result!.top, greaterThan(0));
      expect(result!.right, 1);
      expect(result!.bottom, 1);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-crop-reset')));
      await tester.tap(find.byKey(const ValueKey('photo-crop-apply')));
      await tester.pumpAndSettle();
      expect(result, fullPhotoCrop);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
