import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photo frame catalogue exposes unique, labelled styles', () {
    expect(albumPhotoFrameCount, greaterThanOrEqualTo(12));
    expect(albumPhotoFrameLabels.toSet(), hasLength(albumPhotoFrameCount));
    for (var index = 0; index < albumPhotoFrameCount; index++) {
      expect(albumPhotoFrameLabel(index), isNotEmpty);
    }
  });

  testWidgets('every illustrated sticker paints without an image asset', (
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
