import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/widgets/page_curl.dart';
import 'package:albumium/widgets/physical_book_spread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview keeps one book while its pages turn', (tester) async {
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

    expect(find.byType(PhysicalBookSpread), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.textContaining('Kapak ·'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonraki sayfa'));
    await tester.pump(const Duration(milliseconds: 470));
    expect(find.byType(PhysicalBookSpread), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('İç kapak · Sayfa 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonraki sayfa'));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byType(PageCurl), findsNWidgets(2));
    expect(
      tester
          .widget<PageCurl>(find.byKey(const ValueKey('book-page-curl-front')))
          .surface,
      PageCurlSurface.front,
    );
    expect(
      tester
          .widget<PageCurl>(find.byKey(const ValueKey('book-page-curl-back')))
          .surface,
      PageCurlSurface.back,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhysicalBookSpread), findsOneWidget);
    expect(find.text('Sayfalar 2–3'), findsOneWidget);
  });

  testWidgets('page curl follows the drag before settling', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'drag-preview',
      title: 'Sürüklenen Yaprak',
      themeId: 'vintage_diary',
      createdAt: now,
      updatedAt: now,
      pages: List.generate(
        4,
        (index) =>
            AlbumPageModel(id: 'drag-$index', backgroundColor: 0xFFF2E8D3),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PreviewScreen(album: album),
      ),
    );
    await tester.pumpAndSettle();

    // Open the cover first; the next gesture then exercises the page mesh,
    // rather than the separate hardcover opening animation.
    await tester.tap(find.byTooltip('Sonraki sayfa'));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PhysicalBookSpread)),
    );
    // İlk küçük hareket gesture arena'da yatay sürüklemeyi seçer; ikinci
    // hareket yaprağın ilerlemesini gerçekten denetleyiciye taşır.
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-166, 0));
    await tester.pump();

    final spread = tester.widget<PhysicalBookSpread>(
      find.byType(PhysicalBookSpread),
    );
    expect(spread.nextLeftPageIndex, isNotNull);
    expect(spread.turnProgress, greaterThan(0));
    final frontCurl = tester.widget<PageCurl>(
      find.byKey(const ValueKey('book-page-curl-front')),
    );
    final backCurl = tester.widget<PageCurl>(
      find.byKey(const ValueKey('book-page-curl-back')),
    );
    expect(frontCurl.surface, PageCurlSurface.front);
    expect(backCurl.surface, PageCurlSurface.back);
    expect(frontCurl.grabY, closeTo(.5, .12));
    expect(backCurl.grabY, frontCurl.grabY);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Sayfalar 2–3'), findsOneWidget);
  });

  testWidgets('long albums use a compact progress bar', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'long-preview',
      title: 'Uzun Albüm',
      themeId: 'minimal_editorial',
      createdAt: now,
      updatedAt: now,
      pages: List.generate(
        24,
        (index) =>
            AlbumPageModel(id: 'long-$index', backgroundColor: 0xFFF0ECE4),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PreviewScreen(album: album),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Albüm ilerlemesi 1 / 14'), findsOneWidget);
  });

  testWidgets('share menu exposes offline PNG and MP4 choices', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'share-preview',
      title: 'Paylaşılacak Albüm',
      themeId: 'vintage_diary',
      createdAt: now,
      updatedAt: now,
      pages: [AlbumPageModel(id: 'share-page', backgroundColor: 0xFFF2E8D3)],
    );

    await tester.pumpWidget(MaterialApp(home: PreviewScreen(album: album)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('preview_share_button')), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('preview_share_button')));
    await tester.pumpAndSettle();

    expect(find.text('Dışa Aktar & Paylaş'), findsOneWidget);
    expect(find.byKey(const ValueKey('share_current_png')), findsOneWidget);
    expect(find.byKey(const ValueKey('share_all_png')), findsOneWidget);
    expect(find.byKey(const ValueKey('share_mp4')), findsOneWidget);
    expect(find.textContaining('internet gerekmez'), findsOneWidget);
  });
}
