import 'package:albumium/l10n/albumium_localizations.dart';
import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/cover_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the label through a real context so the translations are used.
Future<String> _label(
  WidgetTester tester, {
  required AlbumThemePreset theme,
  required bool locked,
  String? priceLabel,
  String language = 'tr',
}) async {
  late String label;
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
        builder: (context) {
          label = coverStatusLabel(
            context,
            theme: theme,
            locked: locked,
            priceLabel: priceLabel,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return label;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a locked cover shows its price', (tester) async {
    expect(
      await _label(
        tester,
        theme: themeById('dark_leather'),
        locked: true,
        priceLabel: '₺14,99',
      ),
      '₺14,99',
    );
  });

  testWidgets('a cover that was paid for says so, not "free"', (tester) async {
    // After a reinstall the store reopens the cover. Calling it free would
    // read as though the purchase had been given away to everyone.
    expect(
      await _label(tester, theme: themeById('dark_leather'), locked: false),
      'Satın alındı',
    );
  });

  testWidgets('a free cover is still free', (tester) async {
    expect(
      await _label(tester, theme: themeById('travel_istanbul'), locked: false),
      'Ücretsiz',
    );
  });

  testWidgets('both readings are translated', (tester) async {
    expect(
      await _label(
        tester,
        theme: themeById('dark_leather'),
        locked: false,
        language: 'en',
      ),
      'Purchased',
    );
    expect(
      await _label(
        tester,
        theme: themeById('soft_romance'),
        locked: false,
        language: 'en',
      ),
      'Free',
    );
  });
}
