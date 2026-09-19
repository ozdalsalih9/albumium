import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/theme_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPicker(
  WidgetTester tester, {
  AlbumThemeCategory? start,
  // Wide enough for the whole category strip, so the chips can be tapped
  // without scrolling them into view first.
  Size size = const Size(900, 1300),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: ThemeScreen(initialCategory: start)),
  );
  await tester.pumpAndSettle();
}

String _summary(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('selected-theme-summary')))
    .data!;

int _coverCount(WidgetTester tester) => tester
    .widget<PageView>(find.byKey(const ValueKey('theme-carousel')))
    .childrenDelegate
    .estimatedChildCount!;

/// The strip is capped at the screen's content width, so a chip has to be
/// brought into view before it can be tapped. Rewind first, then scan forward:
/// the strip keeps its scroll position between taps.
Future<void> _tapCategory(WidgetTester tester, String key) async {
  final strip = find.byKey(const ValueKey('theme-category-strip'));
  final chip = find.byKey(ValueKey(key));
  for (var rewind = 0; rewind < 8; rewind++) {
    await tester.drag(strip, const Offset(200, 0));
    await tester.pumpAndSettle();
  }
  for (var attempt = 0; attempt < 12; attempt++) {
    final viewport = tester.getRect(strip);
    if (chip.evaluate().isNotEmpty) {
      final rect = tester.getRect(chip);
      if (rect.left >= viewport.left && rect.right <= viewport.right) break;
    }
    await tester.drag(strip, const Offset(-100, 0));
    await tester.pumpAndSettle();
  }
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the picker opens on every cover with the first one chosen', (
    tester,
  ) async {
    await _pumpPicker(tester);

    expect(find.byKey(const ValueKey('theme-category-strip')), findsOneWidget);
    expect(_coverCount(tester), albumThemes.length);
    expect(_summary(tester), startsWith('Soft Romance ·'));
    expect(_summary(tester), endsWith('1/${albumThemes.length}'));
  });

  testWidgets('choosing a category narrows the carousel and moves the pick', (
    tester,
  ) async {
    await _pumpPicker(tester);

    await _tapCategory(tester, 'theme-category-animals');

    final animals = themesInCategory(AlbumThemeCategory.animals);
    expect(_coverCount(tester), animals.length);
    expect(_summary(tester), startsWith('${animals.first.name} ·'));

    await _tapCategory(tester, 'theme-category-all');
    expect(_coverCount(tester), albumThemes.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cover that stays in the category keeps being the chosen one', (
    tester,
  ) async {
    await _pumpPicker(tester);

    // Soft Romance is a love cover, so filtering to love must not move it.
    await _tapCategory(tester, 'theme-category-love');

    expect(_summary(tester), startsWith('Soft Romance ·'));
  });

  testWidgets('the carousel shows the cover the screen is describing', (
    tester,
  ) async {
    await _pumpPicker(tester);

    await _tapCategory(tester, 'theme-category-travel');
    await _tapCategory(tester, 'theme-category-all');

    // Going back to "Tümü" used to leave the carousel on the first cover
    // while the summary and the primary button still described the travel
    // one, so a free cover looked locked.
    final travel = themesInCategory(AlbumThemeCategory.travel).first;
    final page = tester
        .widget<PageView>(find.byKey(const ValueKey('theme-carousel')))
        .controller!
        .page!
        .round();
    expect(albumThemes[page].id, travel.id);
    expect(_summary(tester), startsWith('${travel.name} ·'));
  });

  testWidgets('the picker can open already filtered to one category', (
    tester,
  ) async {
    await _pumpPicker(tester, start: AlbumThemeCategory.wedding);

    final wedding = themesInCategory(AlbumThemeCategory.wedding);
    expect(_coverCount(tester), wedding.length);
    expect(_summary(tester), startsWith('${wedding.first.name} ·'));
    expect(tester.takeException(), isNull);
  });
}
