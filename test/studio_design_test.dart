import 'dart:io';
import 'dart:ui' as ui;
import 'package:albumium/models/album_models.dart';
import 'package:albumium/models/card_design_history.dart';
import 'package:albumium/models/social_video_draft.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/screens/social_video_screen.dart';
import 'package:albumium/themes/theme_image_helper.dart';
import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/card_color_picker.dart';
import 'package:albumium/widgets/occasion_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'social_video_draft_test.dart' show socialTestAlbum;

Future<void> saveReview(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('STUDIO_REVIEW')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/review').create(recursive: true);
    await File(
      'build/review/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final family in ['AlbumiumSans', 'Roboto']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
          .load();
    }
    await (FontLoader('AlbumiumDisplay')..addFont(
          rootBundle.load('assets/fonts/google/Marcellus-Regular.ttf'),
        ))
        .load();
  });
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'undo restores removed layers, custom colors and artwork after theme changes',
    () {
      final project = createSpecialCardProject();
      final original = project.toJson();
      final history = CardDesignHistory(project);
      project.pages.first.elements.removeLast();
      project.pages.first.elements.first.locked = true;
      project.pages.first.backgroundColor = 0xFF134658;
      project.cardArtworkVisible = false;
      history.record(project);
      final edited = project.toJson();
      project.cardThemeId = 'midnight_vow';
      history.record(project);
      history.undo(project);
      expect(project.toJson(), edited);
      history.undo(project);
      expect(project.toJson(), original);
      history.redo(project);
      expect(project.toJson(), edited);
      project.title = 'My own card';
      history.record(project);
      expect(history.canRedo, false);
      expect(AlbumModel.fromJson(project.toJson()).cardArtworkVisible, false);
      expect(
        AlbumModel.fromJson(
          {...original}..remove('cardArtworkVisible'),
        ).cardArtworkVisible,
        true,
      );
    },
  );

  testWidgets('artwork toggle, undo and redo keep the card contents intact', (
    tester,
  ) async {
    final project = createSpecialCardProject(
      template: atelierCardTemplates.first,
    );
    final before = project.pages.first.toJson();
    await tester.pumpWidget(
      MaterialApp(home: SpecialCardStudioScreen(project: project)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('card-artwork-toggle')));
    await tester.pumpAndSettle();
    expect(project.cardArtworkVisible, false);
    expect(project.pages.first.toJson(), before);
    await tester.tap(find.byKey(const ValueKey('card-undo')));
    await tester.pumpAndSettle();
    expect(project.cardArtworkVisible, true);
    await tester.tap(find.byKey(const ValueKey('card-redo')));
    await tester.pumpAndSettle();
    expect(project.cardArtworkVisible, false);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'custom hex color accepts exact values and rejects invalid input',
    (tester) async {
      int? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  chosen = await showDialog<int>(
                    context: context,
                    builder: (_) =>
                        const CardColorPicker(initialColor: Colors.white),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('card-color-hex')),
        'no',
      );
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(find.text('6 haneli bir renk kodu gir.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('card-color-hex')),
        '123ABC',
      );
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();
      expect(chosen, 0xFF123ABC);
    },
  );

  testWidgets('all new card layouts render at export proportions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 980);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFE4DFD5),
          body: RepaintBoundary(
            key: key,
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 5 / 7,
              children: [
                for (final template in atelierCardTemplates)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: AlbumPageCanvas(
                      page: createSpecialCardProject(
                        template: template,
                      ).pages.first,
                      theme: specialCardThemeFor(template),
                      showPageNumber: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await GoogleFonts.pendingFonts();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await saveReview(tester, key, 'new-card-collection');
  });

  testWidgets('phone studios keep the artwork and primary actions visible', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final album = socialTestAlbum()..coverPhotoPath = null;
    for (final entry in <String, Widget>{
      'card-studio': SpecialCardStudioScreen(
        project: createSpecialCardProject(template: atelierCardTemplates[2]),
      ),
      'video-studio': SocialVideoScreen(album: album),
    }.entries) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: AlbumiumAppTheme.light(AlbumiumThemeId.rose),
            home: entry.value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await GoogleFonts.pendingFonts();
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await saveReview(tester, key, entry.key);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'page-turn preview renders cover, front, back and closing frames',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 640);
      addTearDown(tester.view.reset);
      final album = socialTestAlbum()
        ..coverPhotoPath = null
        ..title = 'Bir yaz defteri';
      for (var i = 0; i < album.pages.length; i++) {
        album.pages[i].elements.add(
          AlbumElementModel(
            id: 'photo-$i',
            type: AlbumElementType.photo,
            content: 'assets/covers/cover-travel-kapadokya.webp',
            x: .1,
            y: .4,
            width: .8,
            height: .45,
          ),
        );
      }
      final draft = SocialVideoDraft(album);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Row(
                children: [
                  for (final frame in [30, 70, 80, 125])
                    SizedBox(
                      width: 360,
                      height: 640,
                      child: SocialVideoFrame(
                        album: album,
                        draft: draft,
                        frame: frame,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(SocialVideoFrame).first);
        await precacheImage(
          themeImageProvider('assets/covers/cover-travel-kapadokya.webp'),
          context,
        );
        if (themeById(album.themeId).coverAsset case final asset?) {
          if (context.mounted) {
            await precacheImage(themeImageProvider(asset), context);
          }
        }
        await GoogleFonts.pendingFonts();
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('social-turning-leaf')),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
      await saveReview(tester, key, 'video-page-turn');
    },
  );
}
