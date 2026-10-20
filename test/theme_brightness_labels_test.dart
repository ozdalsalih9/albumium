import 'package:albumium/l10n/albumium_localizations.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:albumium/widgets/app_theme_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The brightness control reads Koyu / Açık / Sistem across one row. Three
/// segments split that row, and anything else inside a segment comes out of
/// the label: with an icon beside it "Sistem" broke across two lines while
/// its neighbours stayed on one, and the control looked crooked.
///
/// A wrapped label has nothing to raise - no overflow, no exception - so the
/// only way to catch it is to compare what was drawn with what one line would
/// have needed.
const _labels = {'Koyu', 'Açık', 'Sistem', 'Dark', 'Light', 'System'};

Future<void> _openPicker(
  WidgetTester tester, {
  required double width,
  required String language,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width * 3, 1200 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final controller = ThemeController();
  await controller.initialize();
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AlbumiumLocalizations.supportedLocales,
      localizationsDelegates: const [
        AlbumiumLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAlbumiumThemePicker(context, controller),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

List<String> _wrappedLabels(WidgetTester tester) {
  final wrapped = <String>[];
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final label = paragraph.text.toPlainText();
    if (!_labels.contains(label)) continue;
    if (paragraph.size.width + 0.5 <
        paragraph.getMaxIntrinsicWidth(double.infinity)) {
      wrapped.add(label);
    }
  }
  return wrapped;
}

void main() {
  // The narrow end, the common phones, and a tablet.
  for (final width in [320.0, 360.0, 390.0, 412.0, 430.0, 600.0]) {
    for (final language in ['tr', 'en']) {
      testWidgets('brightness labels fit on one line at $width ($language)', (
        tester,
      ) async {
        await _openPicker(tester, width: width, language: language);

        expect(
          _wrappedLabels(tester),
          isEmpty,
          reason: 'a label broke across two lines at ${width}dp',
        );
      });
    }
  }

  testWidgets('all three choices are still offered and selectable', (
    tester,
  ) async {
    await _openPicker(tester, width: 412, language: 'tr');

    final control = find.byType(SegmentedButton<ThemeMode>);
    expect(control, findsOneWidget);
    for (final label in ['Koyu', 'Açık', 'Sistem']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();

    expect(tester.widget<SegmentedButton<ThemeMode>>(control).selected, {
      ThemeMode.dark,
    });
  });
}
