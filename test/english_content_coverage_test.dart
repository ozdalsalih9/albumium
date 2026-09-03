import 'package:albumium/l10n/albumium_localizations.dart';
import 'package:albumium/widgets/occasion_cards.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _englishApp(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AlbumiumLocalizations.supportedLocales,
  localizationsDelegates: const [AlbumiumLocalizationsDelegate()],
  home: Scaffold(body: child),
);

void main() {
  test(
    'all occasion cards, decoration packs, and shapes have English copy',
    () {
      final keys = <String>{
        for (final template in occasionCardTemplates) ...[
          template.title,
          template.subtitle,
          template.badge,
        ],
        for (final pack in stickerPacks) pack.name,
        for (final pack in stickerPacks)
          for (final sticker in pack.stickers)
            if (isIllustratedSticker(sticker)) albumStickerLabel(sticker),
        for (final shape in albumShapeObjects) albumStickerLabel(shape),
      };

      final missing = keys
          .where((key) => !AlbumiumLocalizations.hasEnglishTranslation(key))
          .toList(growable: false);

      expect(missing, isEmpty);
      expect(albumShapeObjects, hasLength(27));
      expect(albumShapeObjects.toSet(), hasLength(albumShapeObjects.length));
    },
  );

  testWidgets('occasion card picker renders its content in English', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_englishApp(const OccasionCardPickerSheet()));
    await tester.pump();

    expect(find.text('Add Occasion Card'), findsOneWidget);
    expect(find.text('Happy Birthday!'), findsOneWidget);
    expect(find.text('BIRTHDAY'), findsOneWidget);
    expect(find.text('İyi ki Doğdun!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shape and decoration panels are English on a tablet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_englishApp(const ShapeObjectPickerSheet()));
    await tester.pump();
    expect(find.text('Shape Objects'), findsOneWidget);
    expect(find.text('Blush circle'), findsOneWidget);
    expect(find.text('Şekil Nesneleri'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_englishApp(const StickerPackPickerSheet()));
    await tester.pump();
    expect(find.text('All Decorations'), findsOneWidget);
    expect(find.text('Botanical keepsake bouquet'), findsOneWidget);
    expect(find.text('Tüm Süsler'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
