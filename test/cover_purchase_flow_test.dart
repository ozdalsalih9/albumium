import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/theme_screen.dart';
import 'package:albumium/services/cover_entitlements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPicker(
  WidgetTester tester, {
  required CoverEntitlements entitlements,
  AlbumThemeCategory? category,
  Size size = const Size(411, 914),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ThemeScreen(initialCategory: category, entitlements: entitlements),
    ),
  );
  await tester.pumpAndSettle();
}

Future<CoverEntitlements> _emptyStore() async {
  SharedPreferences.setMockInitialValues({});
  final entitlements = CoverEntitlements(
    preferences: await SharedPreferences.getInstance(),
  );
  await entitlements.initialize();
  return entitlements;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a locked cover shows its price instead of the start button', (
    tester,
  ) async {
    final entitlements = await _emptyStore();
    await _pumpPicker(
      tester,
      entitlements: entitlements,
      category: AlbumThemeCategory.animals,
    );

    final locked = themesInCategory(AlbumThemeCategory.animals).first;
    expect(locked.isPremium, isTrue);
    expect(
      find.byKey(ValueKey('theme-lock-badge-${locked.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('theme-lock-note')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('theme-primary-action')),
        matching: find.textContaining(locked.price.label!),
      ),
      findsOneWidget,
    );
  });

  testWidgets('buying unlocks the cover and then the album can be created', (
    tester,
  ) async {
    final entitlements = await _emptyStore();
    await _pumpPicker(
      tester,
      entitlements: entitlements,
      category: AlbumThemeCategory.animals,
    );

    final locked = themesInCategory(AlbumThemeCategory.animals).first;
    await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cover-purchase-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cover-purchase-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cover-purchase-sheet')), findsNothing);
    expect(entitlements.isUnlocked(locked.id), isTrue);
    expect(find.byKey(ValueKey('theme-lock-badge-${locked.id}')), findsNothing);
    expect(find.byKey(const ValueKey('theme-lock-note')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('theme-primary-action')),
        matching: find.textContaining('ile Başla'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving the sheet keeps the cover locked', (tester) async {
    final entitlements = await _emptyStore();
    await _pumpPicker(
      tester,
      entitlements: entitlements,
      category: AlbumThemeCategory.animals,
    );

    await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    final locked = themesInCategory(AlbumThemeCategory.animals).first;
    expect(entitlements.isUnlocked(locked.id), isFalse);
    expect(
      find.byKey(ValueKey('theme-lock-badge-${locked.id}')),
      findsOneWidget,
    );
  });

  testWidgets('the free cover needs no purchase', (tester) async {
    final entitlements = await _emptyStore();
    await _pumpPicker(tester, entitlements: entitlements);

    expect(find.byKey(const ValueKey('theme-lock-note')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('theme-primary-action')),
        matching: find.textContaining('ile Başla'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a locked cover still fits the screen on a small phone', (
    tester,
  ) async {
    final entitlements = await _emptyStore();
    await _pumpPicker(
      tester,
      entitlements: entitlements,
      category: AlbumThemeCategory.animals,
      size: const Size(360, 780),
    );

    final page = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(page.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });
}
