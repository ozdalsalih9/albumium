import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:albumium/models/album_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every album theme paints a distinct page style layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: [
                for (final theme in albumThemes)
                  SizedBox(
                    width: 180,
                    height: 280,
                    child: AlbumPageCanvas(
                      page: AlbumPageModel(
                        id: 'page-${theme.id}',
                        backgroundColor: theme.pageColor.toARGB32(),
                      ),
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final theme in albumThemes) {
      expect(
        find.byKey(ValueKey('page-style-${theme.id}')),
        findsOneWidget,
        reason: '${theme.name} needs its own page decoration layer',
      );
    }
    expect(tester.takeException(), isNull);
  });

  test('photo frame catalogue exposes unique, labelled styles', () {
    expect(albumPhotoFrameCount, greaterThanOrEqualTo(12));
    expect(albumPhotoFrameLabels.toSet(), hasLength(albumPhotoFrameCount));
    for (var index = 0; index < albumPhotoFrameCount; index++) {
      expect(albumPhotoFrameLabel(index), isNotEmpty);
    }
  });

  test('shape objects contain circle, square and heart variants', () {
    expect(albumShapeObjects, hasLength(9));
    expect(
      albumShapeObjects.where((value) => value.contains(':circle_')),
      hasLength(3),
    );
    expect(
      albumShapeObjects.where((value) => value.contains(':square_')),
      hasLength(3),
    );
    expect(
      albumShapeObjects.where((value) => value.contains(':heart_')),
      hasLength(3),
    );
    for (final shape in albumShapeObjects) {
      expect(isAlbumShape(shape), isTrue);
      expect(albumStickerLabel(shape), isNotEmpty);
    }
  });

  testWidgets('every illustrated sticker paints from bundled or vector art', (
    tester,
  ) async {
    final illustrated = stickerPacks
        .expand((pack) => pack.stickers)
        .where(isIllustratedSticker)
        .toSet()
        .toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final sticker in illustrated)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: AlbumStickerView(content: sticker, preview: true),
                ),
            ],
          ),
        ),
      ),
    );

    expect(illustrated, hasLength(greaterThanOrEqualTo(17)));
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
