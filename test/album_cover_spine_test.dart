import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/album_cover.dart';
import 'package:albumium/widgets/album_cover_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [120.0, 300.0]) {
    testWidgets('cover artwork stays outside spine at width $width', (
      tester,
    ) async {
      final album = AlbumModel(
        id: 'spine-preview',
        title: 'Our memories',
        themeId: 'wedding_arch',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        pages: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              height: width * 1.47,
              child: AlbumCover3D(
                album: album,
                compact: width < 200,
                perspective: false,
                showTitle: false,
              ),
            ),
          ),
        ),
      );
      final book = tester.getRect(find.byType(AlbumCover3D));
      final artwork = tester.getRect(find.byType(AlbumCover));
      expect(artwork.left, closeTo(book.left + width * .085, .01));
      expect(artwork.right, closeTo(book.right, .01));
      expect(artwork.center.dx, greaterThan(book.center.dx));
      expect(tester.takeException(), isNull);
    });
  }
}
