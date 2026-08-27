import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/widgets/page_flip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel _album() {
  final now = DateTime(2026, 1, 1);
  final theme = albumThemes.first;
  return AlbumModel(
    id: 'a1',
    title: 'Test Albümü',
    themeId: theme.id,
    createdAt: now,
    updatedAt: now,
    pages: [
      AlbumPageModel(id: 'p1', backgroundColor: theme.pageColor.toARGB32()),
      AlbumPageModel(id: 'p2', backgroundColor: theme.pageColor.toARGB32()),
    ],
  );
}

void main() {
  testWidgets('kitabın sağına dokunmak ileri, soluna dokunmak geri çevirir', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: PreviewScreen(album: _album())));
    await tester.pumpAndSettle();

    // Üç slayt: kapak + iki sayfa.
    expect(find.textContaining('Kapak'), findsOneWidget);

    final book = find.byType(BookFrame);
    final size = tester.getSize(book);
    final topLeft = tester.getTopLeft(book);

    await tester.tapAt(topLeft + Offset(size.width * 0.8, size.height / 2));
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 1 / 2'), findsOneWidget);

    await tester.tapAt(topLeft + Offset(size.width * 0.8, size.height / 2));
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 2 / 2'), findsOneWidget);

    // Sol yarıya dokunmak geri getirir.
    await tester.tapAt(topLeft + Offset(size.width * 0.15, size.height / 2));
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 1 / 2'), findsOneWidget);
  });
}
