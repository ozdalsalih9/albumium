import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/album_cover_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact library covers use lightweight static rendering', (
    tester,
  ) async {
    final album = AlbumModel(
      id: 'performance-cover',
      title: 'Hatıralarım',
      themeId: 'soft_romance',
      createdAt: DateTime.utc(2026, 8, 31),
      updatedAt: DateTime.utc(2026, 8, 31),
      pages: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 150,
            height: 220,
            child: AlbumCover3D(
              album: album,
              compact: true,
              perspective: false,
            ),
          ),
        ),
      ),
    );

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, isNotEmpty);
    final resizedProviders = images
        .map((image) => image.image)
        .whereType<ResizeImage>();
    expect(resizedProviders.any((provider) => provider.width == 600), isTrue);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
}
