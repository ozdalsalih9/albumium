import 'dart:io';
import 'dart:ui' as ui;

import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:albumium/models/album_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every album theme paints a distinct page style layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: [
                for (final theme in albumThemes)
                  SizedBox(
                    width: 180,
                    height: 280,
                    child: AlbumPageCanvas(
                      page: AlbumPageModel(
                        id: 'page-${theme.id}',
                        backgroundColor: theme.pageColor.toARGB32(),
                      ),
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final theme in albumThemes) {
      expect(
        find.byKey(ValueKey('page-style-${theme.id}')),
        findsOneWidget,
        reason: '${theme.name} needs its own page decoration layer',
      );
    }
    expect(tester.takeException(), isNull);
  });

  test('photo frame catalogue exposes unique, labelled styles', () {
    expect(albumPhotoFrameCount, greaterThanOrEqualTo(12));
    expect(albumPhotoFrameLabels.toSet(), hasLength(albumPhotoFrameCount));
    for (var index = 0; index < albumPhotoFrameCount; index++) {
      expect(albumPhotoFrameLabel(index), isNotEmpty);
    }
  });

  test('shape objects contain circle, square and heart variants', () {
    expect(albumShapeObjects, hasLength(9));
    expect(
      albumShapeObjects.where((value) => value.contains(':circle_')),
      hasLength(3),
    );
    expect(
      albumShapeObjects.where((value) => value.contains(':square_')),
      hasLength(3),
    );
    expect(
      albumShapeObjects.where((value) => value.contains(':heart_')),
      hasLength(3),
    );
    for (final shape in albumShapeObjects) {
      expect(isAlbumShape(shape), isTrue);
      expect(albumStickerLabel(shape), isNotEmpty);
    }
  });

  testWidgets('every illustrated sticker paints from bundled or vector art', (
    tester,
  ) async {
    final illustrated = stickerPacks
        .expand((pack) => pack.stickers)
        .where(isIllustratedSticker)
        .toSet()
        .toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final sticker in illustrated)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: AlbumStickerView(content: sticker, preview: true),
                ),
            ],
          ),
        ),
      ),
    );

    expect(illustrated, hasLength(greaterThanOrEqualTo(17)));
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('reference-inspired decoration packs are exposed and labelled', () {
    const expectedPacks = {
      'Hatıra Koleksiyonu': 12,
      'Retro Çerçeve': 6,
      'Kâğıt Köşeleri': 5,
      'Disko Kolaj': 5,
      'Düğme Kutusu': 4,
      'Dikiş Sepeti': 6,
      'Analog Oda': 6,
      'Gökyüzü': 6,
      'Yolculuk Masası': 6,
      'Tatlı Mola': 6,
      'Kelime Etiketleri': 6,
      'Kedi Kulübü': 6,
      'Parti Maymunları': 6,
    };

    for (final entry in expectedPacks.entries) {
      final pack = stickerPacks.singleWhere((pack) => pack.name == entry.key);
      expect(pack.stickers, hasLength(entry.value));
      for (final sticker in pack.stickers) {
        expect(isIllustratedSticker(sticker), isTrue);
        expect(albumStickerLabel(sticker), isNot(sticker));
      }
    }
  });

  testWidgets('keepsake raster stickers retain their documented proportions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: AlbumStickerView(
              content: 'albumium_asset:assets/stickers/botanical_keepsake.png',
            ),
          ),
        ),
      ),
    );

    final artSize = tester.getSize(
      find.byKey(
        const ValueKey(
          'sticker-art-albumium_asset:assets/stickers/botanical_keepsake.png',
        ),
      ),
    );
    expect(artSize.width / artSize.height, closeTo(.67, .01));
  });

  test(
    'every keepsake PNG has real transparency and its natural ratio',
    () async {
      final keepsakes = stickerPacks
          .singleWhere((pack) => pack.name == 'Hatıra Koleksiyonu')
          .stickers;

      for (final sticker in keepsakes) {
        final path = albumStickerAssetPath(sticker);
        final bytes = await File(path).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final rgba = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );

        expect(rgba, isNotNull, reason: '$path could not be decoded as RGBA');
        var hasTransparentPixel = false;
        for (var offset = 3; offset < rgba!.lengthInBytes; offset += 4) {
          if (rgba.getUint8(offset) == 0) {
            hasTransparentPixel = true;
            break;
          }
        }
        expect(
          hasTransparentPixel,
          isTrue,
          reason: '$path must contain transparent canvas pixels',
        );
        expect(
          albumStickerAspectRatio(sticker),
          closeTo(frame.image.width / frame.image.height, .015),
          reason: '$path must render without horizontal squeezing',
        );
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  testWidgets('shape and square sticker art preserve pixel aspect ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 280,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AlbumStickerView(
                    content: 'albumium_shape:circle_blush',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final artSize = tester.getSize(
      find.byKey(const ValueKey('sticker-art-albumium_shape:circle_blush')),
    );
    expect(artSize.width, closeTo(artSize.height, .01));
  });

  testWidgets('unified decoration browser searches without horizontal tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StickerPackPickerSheet())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tüm Süsler'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    await tester.enterText(find.byType(TextField), 'maymun');
    await tester.pump();
    expect(find.text('6 yaratıcı parça'), findsOneWidget);
  });

  testWidgets('surprise action returns an illustrated decoration', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  selected = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const StickerPackPickerSheet(),
                  );
                },
                child: const Text('Süsleri aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Süsleri aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rastgele sürpriz süs'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(isIllustratedSticker(selected!), isTrue);
  });
}
