import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:albumium/models/album_models.dart';
import 'package:albumium/main.dart';
import 'package:albumium/services/reminder_service.dart';
import 'package:albumium/models/memory_period.dart';
import 'package:albumium/screens/memory_album_screen.dart';
import 'package:albumium/screens/personal_stickers_screen.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/services/card_template_storage.dart';
import 'package:albumium/services/personal_sticker_storage.dart';
import 'package:albumium/services/album_package_service.dart';
import 'package:albumium/widgets/occasion_cards.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/screens/cards_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test('weekends use Sunday dates including year boundaries', () {
    expect(
      MemoryPeriod.current(MemoryKind.weekend, DateTime(2026, 1, 1)).key,
      'weekend:2025-12-28',
    );
    expect(
      MemoryPeriod.current(MemoryKind.weekend, DateTime(2026, 9, 6, 20)).key,
      'weekend:2026-9-6',
    );
    expect(
      MemoryPeriod.current(MemoryKind.month, DateTime(2028, 2, 29)).key,
      'month:2028-2-1',
    );
  });
  testWidgets(
    'cold notification opens its original period after a later launch',
    (tester) async {
      ReminderService.pending.value = {
        'kinds': 'year',
        'year': 2028,
        'month': 12,
        'day': 31,
      };
      await tester.pumpWidget(
        const AlbumiumApp(showOnboarding: false, showLaunchAnimation: false),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<MemoryAlbumScreen>(
        find.byType(MemoryAlbumScreen),
      );
      expect(screen.period.key, 'year:2028-1-1');
      expect(ReminderService.pending.value, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('combined notification offers all matching periods', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AlbumiumApp(showOnboarding: false, showLaunchAnimation: false),
    );
    await tester.pumpAndSettle();
    ReminderService.pending.value = {
      'kinds': 'weekend,month,year',
      'year': 2028,
      'month': 12,
      'day': 31,
    };
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bu ay neler yaptın?').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MemoryAlbumScreen>(find.byType(MemoryAlbumScreen))
          .period
          .key,
      'month:2028-12-1',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  test(
    'deleting a library sticker preserves media used by existing projects',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'albumium_sticker_reference_',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/sticker.png');
      await file.writeAsBytes([1, 2, 3]);
      final sticker = PersonalSticker(
        'one',
        'My sticker',
        personalSticker(file.path, 1),
      );
      SharedPreferences.setMockInitialValues({
        PersonalStickerStorage.key: jsonEncode([sticker.toJson()]),
      });
      await PersonalStickerStorage.delete('one');
      expect(await PersonalStickerStorage.load(), isEmpty);
      expect(await file.exists(), isTrue);
    },
  );
  test('draft keeps photo ordering, cover and two photos per page', () {
    final album = buildMemoryAlbum(
      MemoryPeriod.current(MemoryKind.month, DateTime(2026, 9, 30)),
      ['a', 'b', 'c'],
      'My note',
    );
    expect(album.coverPhotoPath, 'a');
    expect(album.pages, hasLength(2));
    expect(
      album.pages.first.elements
          .where((e) => e.type == AlbumElementType.photo)
          .map((e) => e.content),
      ['a', 'b'],
    );
    final restored = AlbumModel.fromJson(album.toJson());
    expect(restored.memoryPeriod, 'month:2026-9-1');
    expect(restored.coverPhotoPath, 'a');
    expect(
      () => buildMemoryAlbum(
        MemoryPeriod(MemoryKind.year, DateTime(2026)),
        [],
        '',
      ),
      throwsArgumentError,
    );
  });
  test('legacy records and card ids stay readable', () {
    final json = createSpecialCardProject().toJson()
      ..remove('memoryPeriod')
      ..remove('coverPhotoPath');
    final card = AlbumModel.fromJson(json);
    expect(card.memoryPeriod, isNull);
    expect(occasionTemplateById('birthday').id, 'birthday');
    expect(occasionCardTemplates, hasLength(18));
    expect(occasionCardTemplates.map((t) => t.category).toSet(), hasLength(6));
    expect(
      createSpecialCardProject(
        template: blankCardTemplate,
      ).pages.first.elements,
      isEmpty,
    );
  });
  test('templates are independent snapshots with fresh nested IDs', () async {
    final card = createSpecialCardProject();
    card.pages.first.elements.first.content = 'Custom greeting';
    await CardTemplateStorage.save(card);
    card.pages.first.elements.first.content = 'Changed original';
    final stored = (await CardTemplateStorage.load()).single;
    final copy = cloneCard(stored);
    expect(copy.id, isNot(card.id));
    expect(copy.pages.first.id, isNot(stored.pages.first.id));
    expect(copy.pages.first.elements.first.content, 'Custom greeting');
    copy.pages.first.elements.first.content = 'Changed copy';
    expect(
      (await CardTemplateStorage.load())
          .single
          .pages
          .first
          .elements
          .first
          .content,
      'Custom greeting',
    );
  });
  test(
    'personal stickers retain alpha, cover and alignment across package import',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'albumium_personal_roundtrip_',
      );
      addTearDown(() => root.delete(recursive: true));
      final original = img.Image(width: 16, height: 8, numChannels: 4);
      original.setPixelRgba(8, 4, 200, 50, 80, 128);
      final file = File('${root.path}/transparent.png');
      await file.writeAsBytes(img.encodePng(original));
      final album = buildMemoryAlbum(
        MemoryPeriod(MemoryKind.year, DateTime(2026)),
        [file.path],
        '',
      );
      album.pages.first.elements.add(
        AlbumElementModel(
          id: 'personal',
          type: AlbumElementType.sticker,
          content: personalSticker(file.path, 2),
          x: .1,
          y: .2,
          width: .5,
          height: .2,
          textAlign: TextAlign.left,
        ),
      );
      final temp = await Directory('${root.path}/temp').create();
      final docs = await Directory('${root.path}/docs').create();
      final service = AlbumPackageService(
        temporaryDirectoryProvider: () async => temp,
        documentsDirectoryProvider: () async => docs,
      );
      final exported = await service.createPackage(album);
      final preview = await service.openPackage(exported.file.path);
      final imported = await service.importCopy(preview);
      await preview.dispose();
      final content = imported.pages.first.elements.last.content;
      expect(
        personalStickerPath(personalSticker(r'C:\my photos\a:b.png', 2)),
        r'C:\my photos\a:b.png',
      );
      expect(personalStickerAspect(content), 2);
      final decoded = img.decodePng(
        await File(personalStickerPath(content)).readAsBytes(),
      )!;
      expect(decoded.getPixel(0, 0).a, 0);
      expect(decoded.getPixel(8, 4).a, 128);
      expect(imported.pages.first.elements.last.textAlign, TextAlign.left);
      expect(await File(imported.coverPhotoPath!).exists(), isTrue);
      expect(imported.memoryPeriod, album.memoryPeriod);
    },
  );
  testWidgets('cutout eraser and restore compose alpha correctly', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final source = img.Image(width: 32, height: 32, numChannels: 4);
      img.fill(source, color: img.ColorRgba8(220, 50, 80, 255));
      source.setPixelRgba(0, 0, 220, 50, 80, 128);
      final codec = await ui.instantiateImageCodec(img.encodePng(source));
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final strokes = [
        StickerStroke(false, .5, const Offset(.5, .5)),
        StickerStroke(true, .15, const Offset(.5, .5)),
      ];
      final recorder = ui.PictureRecorder();
      StickerCutoutPainter(
        image,
        image,
        strokes,
        checker: false,
      ).paint(Canvas(recorder), const Size(32, 32));
      final picture = recorder.endRecording();
      final result = await picture.toImage(32, 32);
      picture.dispose();
      final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
      final decoded = img.decodePng(bytes!.buffer.asUint8List())!;
      expect(decoded.getPixel(16, 16).a, 255);
      expect(decoded.getPixel(21, 16).a, lessThan(50));
      expect(decoded.getPixel(0, 0).a, 128);
      image.dispose();
      result.dispose();
    });
  });
  testWidgets('card theme changes preserve custom text', (tester) async {
    final project = createSpecialCardProject();
    project.pages.first.elements[1].content = 'Hayırlı Cumalar, ailem!';
    await tester.pumpWidget(
      MaterialApp(home: SpecialCardStudioScreen(project: project)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('İyi Bayramlar').last);
    await tester.pumpAndSettle();
    expect(project.cardThemeId, 'eid_garden');
    expect(project.pages.first.elements.first.y, .15);
    expect(project.pages.first.elements[1].content, 'Hayırlı Cumalar, ailem!');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  for (final size in [const Size(320, 640), const Size(960, 600)]) {
    testWidgets('cards hub fits $size with larger text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const Scaffold(body: CardsHub()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('render representative card artwork for visual review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1120);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final key = GlobalKey();
    final samples = [
      'friday_gold',
      'eid_garden',
      'birthday_confetti',
      'love_letter',
      'birthday_photo',
      'morning_sun',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 5 / 7,
              children: [
                for (final id in samples)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: AlbumPageCanvas(
                      page: createSpecialCardProject(
                        template: occasionTemplateById(id),
                      ).pages.first,
                      theme: specialCardThemeFor(occasionTemplateById(id)),
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
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/review').create(recursive: true);
      await File(
        'build/review/card-collection.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
