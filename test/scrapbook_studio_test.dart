import 'dart:io';
import 'dart:ui' as ui;
import 'package:albumium/models/album_models.dart';
import 'package:albumium/models/scrapbook_templates.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/occasion_cards.dart';
import 'package:albumium/widgets/photo_style_picker.dart';
import 'package:albumium/widgets/paper_materials.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlbumElementModel photo(String id) => AlbumElementModel(
  id: id,
  type: AlbumElementType.photo,
  content: '',
  photoSlot: true,
  x: .2,
  y: .2,
  width: .6,
  height: .4,
);

void main() {
  setUpAll(() async {
    for (final family in ['Roboto', 'AlbumiumSans']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'old albums retain frame geometry; new frame settings round trip safely',
    () {
      final original = photo('old')..frameStyle = 7;
      final json = original.toJson()
        ..remove('frameScale')
        ..remove('frameSpacing');
      final legacy = AlbumElementModel.fromJson(json);
      expect(albumElementFrameInsets(legacy), albumPhotoFrameInsets(7));
      original
        ..frameStyle = 18
        ..frameScale = .7
        ..frameSpacing = 6
        ..locked = true;
      expect(
        AlbumElementModel.fromJson(original.toJson()).toJson(),
        original.toJson(),
      );
      final malformed = AlbumElementModel.fromJson({
        ...json,
        'frameScale': double.nan,
        'frameSpacing': 500,
      });
      expect(malformed.frameScale, 1);
      expect(malformed.frameSpacing, 20);
    },
  );

  test('copy style keeps other photo crops and locked elements untouched', () {
    final draft = photo('source')
      ..photoCrop = const Rect.fromLTRB(.1, .2, .8, .9);
    final result = AlbumPhotoStyleSelection(
      frameStyle: 19,
      shape: AlbumPhotoShape.square,
      frameScale: .6,
      frameSpacing: 7,
      draft: draft,
      scope: PhotoStyleScope.album,
    );
    final other = photo('other')..photoCrop = const Rect.fromLTRB(0, 0, .5, .5);
    final crop = other.photoCrop;
    final locked = photo('locked')..locked = true;
    final before = locked.toJson();
    applyPhotoStudioResult(other, result);
    applyPhotoStudioResult(locked, result);
    expect(other.photoCrop, crop);
    expect(other.frameStyle, 19);
    expect(other.frameSpacing, 7);
    expect(other.frameScale, .6);
    expect(locked.toJson(), before);
  });

  test(
    'all seven layouts are available as cards and retain photos on re-theme',
    () {
      expect(scrapbookTemplateById('birthday'), isNull);
      for (final template in scrapbookTemplates) {
        final card = atelierCardTemplates.singleWhere(
          (c) => c.id == 'scrapbook_${template.id}',
        );
        final project = createSpecialCardProject(template: card);
        final page = project.pages.single;
        expect(page.paperPattern, template.pattern);
        expect(page.elements.where((e) => e.photoSlot), isNotEmpty);
      }
      final page = createScrapbookPage(scrapbookTemplates.first);
      final photos = page.elements.where((e) => e.photoSlot).toList();
      for (var i = 0; i < photos.length; i++) {
        photos[i].content = 'photo-$i.jpg';
      }
      photos.last.locked = true;
      final pinned = page.elements.first..locked = true;
      final pinnedJson = pinned.toJson();
      final lockedPhotoJson = photos.last.toJson();
      final caption = page.elements.firstWhere(
        (e) => e.type == AlbumElementType.text,
      )..content = 'My memory';
      applyScrapbookToPage(page, scrapbookTemplates[2]);
      expect(
        page.elements
            .where(
              (e) => e.type == AlbumElementType.photo && e.content.isNotEmpty,
            )
            .map((e) => e.content)
            .toSet(),
        {'photo-0.jpg', 'photo-1.jpg', 'photo-2.jpg'},
      );
      expect(
        page.elements.singleWhere((e) => e.id == pinned.id).toJson(),
        pinnedJson,
      );
      expect(
        page.elements.singleWhere((e) => e.id == photos.last.id).toJson(),
        lockedPhotoJson,
      );
      expect(page.elements.any((e) => e.content == caption.content), isTrue);
    },
  );

  testWidgets(
    'paper previews decode small rasters; legacy frame stickers still render',
    (tester) async {
      expect(
        stickerPacks
            .expand((p) => p.stickers)
            .where((s) => s.startsWith('albumium:paperkit_frame_')),
        isEmpty,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 130,
              child: AlbumStickerView(
                content: 'albumium:paperkit_frame_rose',
                preview: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PaperKitImage), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).width, 160);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 720.0]) {
    testWidgets('studio draft cancel and apply at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = photo('source');
      final before = source.toJson();
      AlbumPhotoStyleSelection? result;
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showAlbumPhotoStylePicker(
                      context,
                      selectedFrameStyle: source.frameStyle,
                      selectedShape: source.photoShape,
                      element: source,
                      allowAlbumScope: true,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('photo-shape-circle')),
      );
      await tester.tap(find.byKey(const ValueKey('photo-shape-circle')));
      await tester.pumpAndSettle();
      final preview = tester
          .widget<AlbumPageCanvas>(find.byType(AlbumPageCanvas))
          .page
          .elements
          .single;
      expect(preview.photoShape, AlbumPhotoShape.circle);
      expect(preview.width * (5 / 7) / preview.height, closeTo(1, .001));
      expect(source.toJson(), before);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(source.toJson(), before);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Çerçeve'));
      await tester.tap(find.text('Çerçeve'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('photo-frame-18')));
      await tester.tap(find.byKey(const ValueKey('photo-frame-18')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('photo-frame-spacing')),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('photo-frame-spacing'))),
      );
      await tester.pumpAndSettle();
      expect(source.toJson(), before);
      await tester.tap(find.byKey(const ValueKey('apply-photo-style')));
      await tester.pumpAndSettle();
      expect(result!.frameStyle, 18);
      expect(result!.frameSpacing, greaterThan(0));
      applyPhotoStudioResult(source, result!, includeCrop: true);
      expect(source.frameStyle, 18);
      expect(source.frameSpacing, result!.frameSpacing);
      expect(tester.takeException(), isNull);

      if (const bool.fromEnvironment('STUDIO_REVIEW') && width == 320) {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await GoogleFonts.pendingFonts();
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (capture.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          await File('output/scrapbook-studio/photo-studio.png').writeAsBytes(
            (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List(),
          );
          image.dispose();
        });
      }
    });
  }

  testWidgets('long press opens Edit and the Photo Studio in cards', (
    tester,
  ) async {
    final project = createSpecialCardProject(
      template: atelierCardTemplates.first,
    );
    final target = project.pages.first.elements.firstWhere((e) => e.photoSlot);
    await tester.pumpWidget(
      MaterialApp(home: SpecialCardStudioScreen(project: project)),
    );
    await tester.pumpAndSettle();
    await tester.longPress(
      find
          .descendant(
            of: find.byKey(ValueKey(target.id)),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Düzenle'), findsWidgets);
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Düzenle'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('photo-studio-live-preview')),
      findsOneWidget,
    );
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a locked paper remains stationary while dragging on the canvas',
    (tester) async {
      final paper = AlbumElementModel(
        id: 'locked-paper',
        type: AlbumElementType.sticker,
        content: 'albumium:paperkit_paper_rose',
        x: .2,
        y: .2,
        width: .5,
        height: .5,
        locked: true,
      );
      final before = paper.toJson();
      String? selected;
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 420,
              child: StatefulBuilder(
                builder: (context, setState) {
                  refresh = setState;
                  return AlbumPageCanvas(
                    page: AlbumPageModel(
                      id: 'page',
                      backgroundColor: 0xFFFFFFFF,
                      elements: [paper],
                    ),
                    theme: themeById('minimal_editorial'),
                    interactive: true,
                    onSelect: (id) => selected = id,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder target() => find
          .descendant(
            of: find.byKey(ValueKey(paper.id)),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.tap(target());
      await tester.pump();
      expect(selected, paper.id);
      await tester.drag(target(), const Offset(50, 50));
      await tester.pumpAndSettle();
      expect(paper.toJson(), before);
      refresh(() => paper.locked = false);
      await tester.pump();
      await tester.drag(target(), const Offset(50, 50));
      await tester.pumpAndSettle();
      expect(paper.x, greaterThan(.2));
      expect(paper.y, greaterThan(.2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('recent decorations are persisted and directly filterable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'albumium.decorations.recent': ['albumium:paperkit_seal_gold'],
    });
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const StickerPackPickerSheet(),
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
    await tester.tap(find.widgetWithText(FilterChip, 'Son kullanılanlar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumStickerView), findsOneWidget);
    await tester.tap(find.byType(AlbumStickerView));
    await tester.pumpAndSettle();
    expect(selected, 'albumium:paperkit_seal_gold');
    expect(
      (await SharedPreferences.getInstance())
          .getStringList('albumium.decorations.recent')!
          .first,
      selected,
    );
    expect(tester.takeException(), isNull);
  });
}
