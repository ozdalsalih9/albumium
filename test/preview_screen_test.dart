import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/preview_screen.dart';
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
    await tester.pumpAndSettle();
    expect(find.byType(PhysicalBookSpread), findsOneWidget);
    expect(find.text('Sayfalar 2–3'), findsOneWidget);
  });
}
