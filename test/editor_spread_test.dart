import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/page_curl.dart';
import 'package:albumium/widgets/physical_book_spread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('editor shows and selects both pages in one physical spread', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'editor-spread',
      title: 'İki Sayfa',
      themeId: 'vintage_diary',
      bindingType: AlbumBindingType.spiral,
      createdAt: now,
      updatedAt: now,
      pages: [
        AlbumPageModel(id: 'left-page', backgroundColor: 0xFFF2E8D3),
        AlbumPageModel(id: 'right-page', backgroundColor: 0xFFE8C8CD),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: EditorScreen(album: album),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PhysicalBookSpread), findsOneWidget);
    expect(find.byType(AlbumPageCanvas), findsNWidgets(2));
    expect(find.text('Sayfalar 1–2 / 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Cilt merkezi: Telli Spiral'), findsOneWidget);

    var spread = tester.widget<PhysicalBookSpread>(
      find.byType(PhysicalBookSpread),
    );
    expect(spread.leftPageIndex, 0);
    expect(spread.rightPageIndex, 1);
    expect(spread.activePageIndex, 0);
    expect(spread.focusedPageIndex, 0);
    expect(spread.companionPageFraction, closeTo(0.11, 0.001));
    expect(find.byKey(const ValueKey('focused-book-viewport')), findsOneWidget);

    final viewportRect = tester.getRect(
      find.byKey(const ValueKey('focused-book-viewport')),
    );
    await tester.tapAt(Offset(viewportRect.right - 6, viewportRect.center.dy));
    await tester.pump();

    spread = tester.widget<PhysicalBookSpread>(find.byType(PhysicalBookSpread));
    expect(spread.activePageIndex, 1);
    expect(spread.focusedPageIndex, 1);
  });

  testWidgets('tablet editor keeps the complete two-page spread', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'tablet-spread',
      title: 'Tablet Albümü',
      themeId: 'midnight_atlas',
      bindingType: AlbumBindingType.hardcover,
      createdAt: now,
      updatedAt: now,
      pages: [
        AlbumPageModel(id: 'tablet-left', backgroundColor: 0xFFF2EADB),
        AlbumPageModel(id: 'tablet-right', backgroundColor: 0xFFF2EADB),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: EditorScreen(album: album),
      ),
    );
    await tester.pumpAndSettle();

    final spread = tester.widget<PhysicalBookSpread>(
      find.byType(PhysicalBookSpread),
    );
    expect(spread.focusedPageIndex, isNull);
    expect(find.byType(AlbumPageCanvas), findsNWidgets(2));
    expect(find.byKey(const ValueKey('focused-book-viewport')), findsNothing);
    expect(find.bySemanticsLabel('Cilt merkezi: Sert Kapak'), findsOneWidget);
  });

  testWidgets('phone focuses the companion then curls to the next spread', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026);
    final album = AlbumModel(
      id: 'editor-page-turn',
      title: 'Çevrilen Sayfalar',
      themeId: 'vintage_diary',
      createdAt: now,
      updatedAt: now,
      pages: List.generate(
        4,
        (index) =>
            AlbumPageModel(id: 'turn-page-$index', backgroundColor: 0xFFF2E8D3),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: EditorScreen(album: album),
      ),
    );
    await tester.pumpAndSettle();

    // Sol sayfadan sonraki sayfaya geçiş aynı yaprakta yatay odak kaymasıdır.
    await tester.tap(find.byTooltip('Sonraki sayfa'));
    await tester.pump(const Duration(milliseconds: 160));
    var spread = tester.widget<PhysicalBookSpread>(
      find.byType(PhysicalBookSpread),
    );
    expect(spread.activePageIndex, 1);
    expect(spread.focusedPageIndex, 1);
    expect(find.byType(PageCurl), findsNothing);
    await tester.pumpAndSettle();

    // Sağ sayfadan ilerlemek gerçek yaprak kıvrımını çalıştırır.
    await tester.tap(find.byTooltip('Sonraki sayfa'));
    await tester.pump(const Duration(milliseconds: 260));
    spread = tester.widget<PhysicalBookSpread>(find.byType(PhysicalBookSpread));
    expect(spread.nextLeftPageIndex, 2);
    expect(spread.nextRightPageIndex, 3);
    expect(find.byType(PageCurl), findsOneWidget);

    await tester.pumpAndSettle();
    spread = tester.widget<PhysicalBookSpread>(find.byType(PhysicalBookSpread));
    expect(spread.activePageIndex, 2);
    expect(spread.focusedPageIndex, 2);

    // Yeni sol yapraktan geri dönüş de aynalanmış kıvrımla önceki sağ sayfayı
    // açar; böylece ileri ve geri yönleri aynı motoru paylaşır.
    await tester.tap(find.byTooltip('Önceki sayfa'));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byType(PageCurl), findsOneWidget);
    await tester.pumpAndSettle();
    spread = tester.widget<PhysicalBookSpread>(find.byType(PhysicalBookSpread));
    expect(spread.activePageIndex, 1);
    expect(spread.focusedPageIndex, 1);
  });
}
