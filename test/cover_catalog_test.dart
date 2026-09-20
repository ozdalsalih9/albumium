import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/cover_catalog_screen.dart';
import 'package:albumium/screens/home_screen.dart';
import 'package:albumium/screens/theme_screen.dart';
import 'package:albumium/services/cover_entitlements.dart';
import 'package:albumium/services/language_controller.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CoverEntitlements> _emptyStore() async {
  SharedPreferences.setMockInitialValues({});
  final entitlements = CoverEntitlements(
    preferences: await SharedPreferences.getInstance(),
  );
  await entitlements.initialize();
  return entitlements;
}

Future<List<String>> _pumpCatalog(
  WidgetTester tester, {
  required CoverEntitlements entitlements,
  // Tall enough that the whole shelf is laid out: the grid builds lazily,
  // and the free covers now sit below the paid ones.
  Size size = const Size(1200, 4200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final started = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CoverCatalogScreen(
          entitlements: entitlements,
          onStartAlbum: (themeId) async => started.add(themeId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return started;
}

/// The shelf scrolls, so a tile further down has to be brought into view.
Future<void> _tapCover(WidgetTester tester, String themeId) async {
  final tile = find.byKey(ValueKey('catalog-cover-$themeId'));
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find.descendant(
      of: find.byKey(const ValueKey('catalog-grid')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the catalogue lists every cover and filters by category', (
    tester,
  ) async {
    await _pumpCatalog(tester, entitlements: await _emptyStore());

    expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
    expect(
      find.byKey(ValueKey('catalog-cover-${albumThemes.first.id}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('catalog-category-animals')));
    await tester.pumpAndSettle();

    final animals = themesInCategory(AlbumThemeCategory.animals);
    expect(
      find.byKey(ValueKey('catalog-cover-${animals.first.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('catalog-cover-${albumThemes.first.id}')),
      findsNothing,
    );
  });

  testWidgets('searching narrows the shelf and says when nothing matches', (
    tester,
  ) async {
    await _pumpCatalog(tester, entitlements: await _emptyStore());

    await tester.enterText(
      find.byKey(const ValueKey('catalog-search')),
      'kapadokya',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('catalog-cover-travel_kapadokya')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('catalog-cover-travel_istanbul')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('catalog-search')),
      'zzzz',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-empty')), findsOneWidget);
  });

  testWidgets('a free cover opens its page and starts an album', (
    tester,
  ) async {
    final started = await _pumpCatalog(
      tester,
      entitlements: await _emptyStore(),
    );

    await _tapCover(tester, 'travel_istanbul');

    expect(
      find.byKey(const ValueKey('cover-detail-travel_istanbul')),
      findsOneWidget,
    );
    // Other travel covers sit under the big one so they can be compared.
    expect(find.byKey(const ValueKey('cover-detail-siblings')), findsOneWidget);
    expect(find.text('Hikâyeni Başlat'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cover-detail-action')));
    await tester.pumpAndSettle();
    expect(started, ['travel_istanbul']);
  });

  testWidgets('a locked cover offers unlocking rather than starting', (
    tester,
  ) async {
    final entitlements = await _emptyStore();
    final started = await _pumpCatalog(tester, entitlements: entitlements);

    await _tapCover(tester, 'dark_leather');

    expect(find.text('Kapağı aç'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cover-detail-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cover-purchase-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cover-purchase-confirm')));
    await tester.pumpAndSettle();

    expect(entitlements.isUnlocked('dark_leather'), isTrue);
    expect(find.text('Hikâyeni Başlat'), findsOneWidget);
    expect(started, isEmpty);
  });

  testWidgets('paid covers lead and names follow the Turkish alphabet', (
    tester,
  ) async {
    await _pumpCatalog(tester, entitlements: await _emptyStore());

    // Read the shelf in the order it is laid out, not catalogue order.
    final placed = <(Offset, AlbumThemePreset)>[];
    for (final theme in albumThemes) {
      final tile = find.byKey(ValueKey('catalog-cover-${theme.id}'));
      if (tile.evaluate().isEmpty) continue;
      placed.add((tester.getTopLeft(tile), theme));
    }
    placed.sort((a, b) {
      final byRow = a.$1.dy.compareTo(b.$1.dy);
      return byRow != 0 ? byRow : a.$1.dx.compareTo(b.$1.dx);
    });
    final shown = placed.map((entry) => entry.$2).toList();

    final firstFree = shown.indexWhere((theme) => !theme.isPremium);
    final lastPaid = shown.lastIndexWhere((theme) => theme.isPremium);
    expect(firstFree, isNonNegative);
    expect(lastPaid, lessThan(firstFree), reason: 'paid covers come first');

    // Within the paid ones the dearer tier leads.
    final lastPremium = shown.lastIndexWhere(
      (theme) => theme.price == CoverPrice.premium,
    );
    final firstStandard = shown.indexWhere(
      (theme) => theme.price == CoverPrice.standard,
    );
    expect(firstStandard, isNonNegative);
    expect(lastPremium, lessThan(firstStandard));

    // İstanbul sorts by "i", so it belongs before Kapadokya rather than after
    // Trabzon where a code-unit sort puts it.
    final freeNames = shown.skip(firstFree).map((theme) => theme.name).toList();
    expect(
      freeNames.indexOf('İstanbul'),
      lessThan(freeNames.indexOf('Kapadokya')),
    );
    expect(
      freeNames.indexOf('İstanbul'),
      greaterThan(freeNames.indexOf('Edirne')),
    );
  });

  testWidgets('the themes tab replaces the old home showcase', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: ThemeController(preferences: preferences),
          languageController: LanguageController(preferences: preferences),
          heroMotionEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-cover-categories')), findsNothing);

    // Themes sits between the library and the cards.
    final destinations = tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .destinations
        .cast<NavigationDestination>()
        .map((destination) => destination.label)
        .toList();
    expect(destinations, ['Albümler', 'Temalar', 'Kartlar']);

    await tester.tap(find.text('Temalar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
  });

  testWidgets('the picker can open straight on one cover', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: ThemeScreen(initialThemeId: 'travel_kapadokya')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('selected-theme-summary')))
          .data,
      startsWith('Kapadokya ·'),
    );
  });
}
