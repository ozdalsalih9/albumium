import 'dart:convert';

import 'package:albumium/main.dart';
import 'package:albumium/models/album_models.dart';
import 'package:albumium/services/language_controller.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:albumium/widgets/album_cover_3d.dart';
import 'package:albumium/widgets/handmade_craft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, assets) in [
      (
        'AlbumiumSans',
        [
          'assets/fonts/google/Inter-Regular.ttf',
          'assets/fonts/google/Inter-Medium.ttf',
          'assets/fonts/google/Inter-ExtraBold.ttf',
        ],
      ),
      ('AlbumiumDisplay', ['assets/fonts/google/Marcellus-Regular.ttf']),
      ('serif', ['assets/fonts/google/Marcellus-Regular.ttf']),
      ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
    ]) {
      final loader = FontLoader(family);
      for (final asset in assets) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  });

  testWidgets('welcome types only after the launch overlay has finished', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const AlbumiumApp(
        showLaunchAnimation: true,
        launchAnimationDuration: Duration(milliseconds: 300),
      ),
    );
    await tester.pump();
    final title = find.byKey(const ValueKey('home-welcome-title'));
    expect(tester.widget<Text>(title).data, isEmpty);

    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.widget<Text>(title).data, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(tester.widget<Text>(title).data, isNot('Anılarına hoş geldin'));

    await tester.pump(const Duration(milliseconds: 775));
    final partial = tester.widget<Text>(title).data!;
    expect(partial.length, greaterThan(2));
    expect(partial, isNot('Anılarına hoş geldin'));
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Anılarına hoş geldin'), findsOneWidget);
    semantics.dispose();

    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.widget<Text>(title).data, 'Anılarına hoş geldin');
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the complete welcome immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('home-welcome-title')))
          .data,
      'Anılarına hoş geldin',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final language in ['tr', 'en']) {
    for (final (size, scale) in [
      (const Size(320, 740), 1.6),
      (const Size(390, 844), 1.0),
      (const Size(768, 1024), 1.4),
      (const Size(1024, 768), 1.0),
    ]) {
      testWidgets(
        'open home layout fits $language $size at text scale $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final projects = List.generate(
            8,
            (i) => AlbumModel(
              id: 'qa-$i',
              title: [
                'My Album',
                'Paris, September',
                'Summer together',
                'Family stories',
              ][i % 4],
              themeId: [
                'vintage_diary',
                'soft_romance',
                'animals',
                'midnight_atlas',
              ][i % 4],
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              pages: [
                AlbumPageModel(id: 'page-$i', backgroundColor: 0xFFFFFFFF),
              ],
            ),
          );
          SharedPreferences.setMockInitialValues({
            LanguageController.languagePreferenceKey: language,
            ThemeController.themeModePreferenceKey: size.width == 1024
                ? 'dark'
                : 'light',
            'albumium.albums.v1': jsonEncode({
              'schemaVersion': 2,
              'albums': projects.map((p) => p.toJson()).toList(),
            }),
          });
          const root = ValueKey('home-qa-boundary');
          await tester.pumpWidget(
            const RepaintBoundary(
              key: root,
              child: AlbumiumApp(showLaunchAnimation: false),
            ),
          );
          await tester.pumpAndSettle();
          final title = find.byKey(const ValueKey('home-welcome-title'));
          expect(
            tester.widget<Text>(title).data,
            language == 'en'
                ? 'Welcome to your memories'
                : 'Anılarına hoş geldin',
          );
          final paragraph = tester.renderObject<RenderParagraph>(title);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(
            tester.widget<Text>(title).overflow,
            isNot(TextOverflow.ellipsis),
          );
          expect(find.byType(PaperPanel), findsNothing);
          expect(find.byType(TornPaperLabel), findsNothing);
          final backdrop = tester.widget<CraftBackdrop>(
            find.byKey(const ValueKey('home-velvet-backdrop')),
          );
          expect(backdrop.variant, CraftBackdropVariant.velvet);
          expect(
            find.byKey(const ValueKey('fabric-texture-image')),
            findsOneWidget,
          );
          for (final cover in tester.widgetList<AlbumCover3D>(
            find.byType(AlbumCover3D),
          )) {
            expect(cover.showTitle, isFalse);
          }
          expect(tester.takeException(), isNull);

          if (const bool.fromEnvironment('UPDATE_HOME_QA') && scale == 1) {
            await expectLater(
              find.byKey(root),
              matchesGoldenFile(
                '../dist/home-redesign-$language-${size.width.toInt()}.png',
              ),
            );
          }
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -550),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('UPDATE_HOME_QA') &&
              size.width == 390) {
            await expectLater(
              find.byKey(root),
              matchesGoldenFile('../dist/home-library-$language.png'),
            );
          }
        },
      );
    }
  }
}
