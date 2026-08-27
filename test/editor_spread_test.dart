import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
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

    await tester.tap(find.byType(AlbumPageCanvas).at(1));
    await tester.pump();

    spread = tester.widget<PhysicalBookSpread>(find.byType(PhysicalBookSpread));
    expect(spread.activePageIndex, 1);
  });
}
