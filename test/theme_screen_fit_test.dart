import 'package:albumium/screens/theme_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in const [
    Size(360, 780),
    Size(393, 851),
    Size(411, 914),
    Size(768, 1024),
    Size(1024, 768),
  ]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('album setup fits one screen without scrolling at $label', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: ThemeScreen()));
      await tester.pumpAndSettle();

      final page = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(page.maxScrollExtent, 0);
      expect(find.byKey(const ValueKey('binding-selector')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('album setup scrolls instead of overflowing with the keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ThemeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
