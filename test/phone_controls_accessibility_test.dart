import 'package:albumium/l10n/albumium_localizations.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:albumium/widgets/occasion_cards.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/widgets/element_edit_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['AlbumiumSans', 'Roboto', 'AlbumiumDisplay']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
          .load();
    }
  });
  for (final width in [320.0, 360.0, 384.0, 390.0, 412.0]) {
    testWidgets(
      '$width phone labels stay whole at all text sizes and locales',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 780);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final scale in [1.0, 1.3, 1.6, 2.0]) {
          for (final language in ['tr', 'en']) {
            for (final dark in [false, true]) {
              SharedPreferences.setMockInitialValues({});
              final loc = AlbumiumLocalizations(Locale(language));
              await tester.pumpWidget(
                MaterialApp(
                  key: UniqueKey(),
                  theme: dark
                      ? AlbumiumAppTheme.dark(AlbumiumThemeId.rose)
                      : AlbumiumAppTheme.light(AlbumiumThemeId.rose),
                  locale: Locale(language),
                  supportedLocales: AlbumiumLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AlbumiumLocalizationsDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: SpecialCardStudioScreen(
                    project: createSpecialCardProject(),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final controls = find.byKey(
                const ValueKey('card-controls-bottom'),
              );
              for (final label in [
                'Fotoğraf',
                'Şekiller',
                'Özel Kart',
                'Yazı',
                occasionCardTemplates.first.title,
              ]) {
                final found = find.descendant(
                  of: controls,
                  matching: find.text(loc.text(label)),
                );
                expect(found, findsOneWidget);
                final paragraph = tester.renderObject<RenderParagraph>(found);
                expect(
                  paragraph.didExceedMaxLines,
                  isFalse,
                  reason: '$width / $scale / $language / $label',
                );
                final widget = tester.widget<Text>(found);
                expect(widget.maxLines, 1);
                expect(widget.softWrap, false);
                final boxes = paragraph.getBoxesForSelection(
                  TextSelection(
                    baseOffset: 0,
                    extentOffset: loc.text(label).length,
                  ),
                );
                expect(
                  boxes.every((box) => box.right <= paragraph.size.width + .5),
                  isTrue,
                  reason: 'Text clipped: $width / $scale / $language / $label',
                );
              }
              expect(
                tester.takeException(),
                isNull,
                reason: '$width / $scale / $language / $dark',
              );
            }
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
  for (final size in [const Size(640, 320), const Size(960, 600)]) {
    testWidgets(
      '$size landscape at 2x retains canvas and scrollable controls',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: SpecialCardStudioScreen(project: createSpecialCardProject()),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(AlbumPageCanvas)).height,
          greaterThan(40),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
  for (final width in [320.0, 360.0, 384.0, 390.0, 412.0]) {
    testWidgets('$width album editor and selected tools fit accessibility matrix', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 780);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 1.3, 1.6, 2.0]) {
        for (final language in ['tr', 'en']) {
          for (final dark in [false, true]) {
            SharedPreferences.setMockInitialValues({});
            final album = AlbumModel(id: 'responsive-editor', title: 'Anılar', themeId: 'vintage_diary',
              createdAt: DateTime(2026), updatedAt: DateTime(2026), pages: [
                AlbumPageModel(id: 'page', backgroundColor: 0xFFF2E8D3, elements: [
                  AlbumElementModel(id: 'label', type: AlbumElementType.text, content: 'Seçilebilir', x: .2, y: .3, width: .6, height: .2),
                ]),
              ]);
            await tester.pumpWidget(MaterialApp(key: UniqueKey(),
              theme: dark ? AlbumiumAppTheme.dark(AlbumiumThemeId.rose) : AlbumiumAppTheme.light(AlbumiumThemeId.rose),
              locale: Locale(language), supportedLocales: AlbumiumLocalizations.supportedLocales,
              localizationsDelegates: const [AlbumiumLocalizationsDelegate(), GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
              builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
              home: EditorScreen(album: album),
            ));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$width / $scale / $language / $dark');
            await tester.tap(find.text('Seçilebilir').first);
            await tester.pumpAndSettle();
            expect(find.byType(ElementEditPanel), findsOneWidget);
            expect(tester.takeException(), isNull, reason: 'Selected: $width / $scale / $language / $dark');
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
