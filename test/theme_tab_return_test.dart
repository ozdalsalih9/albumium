import 'package:albumium/screens/home_screen.dart';
import 'package:albumium/services/language_controller.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _selectedTab(WidgetTester tester) => tester
    .widget<NavigationBar>(find.byType(NavigationBar, skipOffstage: false))
    .selectedIndex;

void main() {
  testWidgets('an album started from the Themes tab lands in the library', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 2400);
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

    await tester.tap(find.text('Temalar'));
    await tester.pumpAndSettle();
    expect(_selectedTab(tester), 1);

    // Search first: the shelf is long, and a tile scrolled to the edge of
    // the viewport gets its taps eaten by the navigation bar.
    await tester.enterText(
      find.byKey(const ValueKey('catalog-search')),
      'istanbul',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('catalog-cover-travel_istanbul')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cover-detail-action')));
    await tester.pumpAndSettle();

    // The picker opens on that cover; creating the album leaves it.
    await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      _selectedTab(tester),
      0,
      reason: 'closing the new album should reveal the library, not the shelf',
    );
  });
}
