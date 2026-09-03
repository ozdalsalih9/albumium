import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/photo_style_picker.dart';
import 'package:albumium/widgets/physical_book_spread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumElementModel _photoElement() => AlbumElementModel(
  id: 'photo',
  type: AlbumElementType.photo,
  content: '/tmp/photo.jpg',
  x: .2,
  y: .2,
  width: .4,
  height: .5,
);

void main() {
  testWidgets('köşebant çocuğu çerçevenin tamamına yayar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 240,
                height: 100,
                child: PhotoCornerMounts(
                  style: 4,
                  child: SizedBox(
                    key: ValueKey('gold-corner-photo'),
                    width: 80,
                    height: 40,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                height: 120,
                child: PhotoCornerMounts(
                  style: 5,
                  child: SizedBox(
                    key: ValueKey('black-corner-photo'),
                    width: 60,
                    height: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('gold-corner-photo'))),
      const Size(240, 100),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('black-corner-photo'))),
      const Size(180, 120),
    );
  });

  test('sabit oranlı fotoğraf biçimleri merkezi ve görsel oranı korur', () {
    const pageAspect = 5 / 7;
    const expectedAspects = <AlbumPhotoShape, double>{
      AlbumPhotoShape.square: 1,
      AlbumPhotoShape.circle: 1,
      AlbumPhotoShape.landscape: 4 / 3,
      AlbumPhotoShape.torn: 4 / 3,
      AlbumPhotoShape.portrait: 4 / 5,
      AlbumPhotoShape.arch: 4 / 5,
    };

    for (final entry in expectedAspects.entries) {
      final element = _photoElement();
      final centerX = element.x + element.width / 2;
      final centerY = element.y + element.height / 2;

      applyAlbumPhotoShape(element, entry.key);

      expect(element.photoShape, entry.key);
      expect(element.x + element.width / 2, closeTo(centerX, 1e-9));
      expect(element.y + element.height / 2, closeTo(centerY, 1e-9));
      expect(
        element.width * pageAspect / element.height,
        closeTo(entry.value, 1e-9),
        reason: '${entry.key.name} sayfa üzerinde ezilmeden görünmeli.',
      );
    }
  });

  test('serbest biçim mevcut fotoğraf geometrisini değiştirmez', () {
    final element = _photoElement();
    final geometry = (element.x, element.y, element.width, element.height);

    applyAlbumPhotoShape(element, AlbumPhotoShape.free);

    expect(element.photoShape, AlbumPhotoShape.free);
    expect(
      (element.x, element.y, element.width, element.height),
      geometry,
    );
  });
}
