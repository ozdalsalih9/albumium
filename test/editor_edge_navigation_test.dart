import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/widgets/physical_book_spread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPhoneEditor(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final now = DateTime(2026);
  await tester.pumpWidget(
    MaterialApp(
      home: EditorScreen(
        album: AlbumModel(
          id: 'edge-navigation',
          title: 'Kenarlar',
          themeId: 'vintage_diary',
          createdAt: now,
          updatedAt: now,
          pages: List.generate(
            4,
            (index) =>
                AlbumPageModel(id: 'edge-$index', backgroundColor: 0xFFF2E8D3),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int _activePage(WidgetTester tester) => tester
    .widget<PhysicalBookSpread>(find.byType(PhysicalBookSpread))
    .activePageIndex!;

void main() {
  testWidgets('tapping the book edges walks across and onto the next leaf', (
    tester,
  ) async {
    await _pumpPhoneEditor(tester);
    final next = find.byKey(const ValueKey('editor-edge-next'));
    final previous = find.byKey(const ValueKey('editor-edge-previous'));

    expect(_activePage(tester), 0);
    expect(previous, findsNothing);

    // Right edge on the left page: move across the open spread.
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(_activePage(tester), 1);

    // Right edge on the right page: turn the leaf to the next spread.
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(_activePage(tester), 2);

    // Left edge on a left page: turn back and land on the previous right page.
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(_activePage(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tool row shows a scroll thumb when it overflows', (
    tester,
  ) async {
    await _pumpPhoneEditor(tester);

    final bars = tester
        .widgetList<Scrollbar>(find.byType(Scrollbar))
        .where((bar) => bar.thumbVisibility == true);
    expect(bars, hasLength(1));

    final row = tester.state<ScrollableState>(
      find.descendant(
        of: find.byWidget(bars.single),
        matching: find.byType(Scrollable),
      ),
    );
    expect(row.position.axis, Axis.horizontal);
    expect(row.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
