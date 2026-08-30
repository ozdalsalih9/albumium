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
    expect(find.byType(PageCurl), findsOneWidget);
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

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('İç kapak · Sayfa 1'), findsOneWidget);
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
}
