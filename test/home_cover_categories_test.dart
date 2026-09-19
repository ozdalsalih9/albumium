import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/home_screen.dart';
import 'package:albumium/screens/theme_screen.dart';
import 'package:albumium/services/language_controller.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(411, 914),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the home screen offers a card per cover category', (
    tester,
  ) async {
    // Wide enough for the whole row: the list builds only what is on screen.
    await _pumpHome(tester, size: const Size(1200, 900));

    expect(find.byKey(const ValueKey('home-cover-categories')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-cover-category-all')),
      findsOneWidget,
    );
    for (final category in AlbumThemeCategory.values) {
      expect(
        find.byKey(ValueKey('home-cover-category-${category.name}')),
        findsOneWidget,
        reason: '${category.label} is missing from the showcase.',
      );
    }
  });

  testWidgets('the showcase sits under the hero panel', (tester) async {
    await _pumpHome(tester);

    final hero = tester.getTopLeft(
      find.byKey(const ValueKey('home-hero-content')),
    );
    final showcase = tester.getTopLeft(
      find.byKey(const ValueKey('home-cover-categories')),
    );
    expect(showcase.dy, greaterThan(hero.dy));
  });

  testWidgets('a category card opens the picker filtered to it', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-cover-category-travel')));
    await tester.pumpAndSettle();

    final picker = tester.widget<ThemeScreen>(find.byType(ThemeScreen));
    expect(picker.initialCategory, AlbumThemeCategory.travel);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('selected-theme-summary')))
          .data,
      startsWith(themesInCategory(AlbumThemeCategory.travel).first.name),
    );
  });

  testWidgets('"Tümünü gör" opens the picker unfiltered', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Tümünü gör'));
    await tester.pumpAndSettle();

    final picker = tester.widget<ThemeScreen>(find.byType(ThemeScreen));
    expect(picker.initialCategory, isNull);
  });
}
