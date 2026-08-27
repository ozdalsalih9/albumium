import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/widgets/page_flip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('önizleme sayfalar çevrilirken tek kitabı korur', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'preview-album',
      title: 'Hatıralar',
      themeId: 'soft_romance',
      createdAt: now,
      updatedAt: now,
      pages: List.generate(
        3,
        (index) =>
            AlbumPageModel(id: 'page-$index', backgroundColor: 0xFFF2E5D4),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PreviewScreen(album: album),
      ),
    );
    await tester.pumpAndSettle();

    // Kitap tek bir görünüm olarak yaşar ve bir karusel değildir; sayfalar
    // yaprak olarak çevrilir.
    expect(find.byType(PageFlipView), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Kapak'), findsOneWidget);

    final book = find.byType(BookFrame);
    final size = tester.getSize(book);
    final topLeft = tester.getTopLeft(book);
    final rightSide = topLeft + Offset(size.width * 0.8, size.height / 2);

    await tester.tapAt(rightSide);
    // Çevirmenin ortasında kitap hâlâ tek olmalı: yeniden yaratılırsa
    // yaprağın durumu ve sayfa indeksi bozulur.
    await tester.pump(const Duration(milliseconds: 380));
    expect(find.byType(PageFlipView), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Sayfa 1 / 3'), findsOneWidget);

    await tester.tapAt(rightSide);
    await tester.pumpAndSettle();
    expect(find.byType(PageFlipView), findsOneWidget);
    expect(find.text('Sayfa 2 / 3'), findsOneWidget);
  });
}
