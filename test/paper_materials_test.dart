import 'dart:io';
import 'dart:ui' as ui;
import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/paper_materials.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old pages default to plain and patterned pages round trip', () {
    final legacy = AlbumPageModel.fromJson({
      'id': 'old',
      'backgroundColor': 0xFFFFFFFF,
      'elements': [],
    });
    expect(legacy.paperPattern, 'plain');
    legacy.paperPattern = 'toile';
    expect(AlbumPageModel.fromJson(legacy.toJson()).paperPattern, 'toile');
  });

  test('frames have transparent photo openings at export resolution', () async {
    for (final design in paperKitLabels.keys.where(
      (key) => key.startsWith('frame_'),
    )) {
      final recorder = ui.PictureRecorder();
      PaperKitPainter(design).paint(Canvas(recorder), const Size(200, 264));
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 264);
      final bytes = (await image.toByteData())!;
      expect(bytes.getUint8((132 * 200 + 100) * 4 + 3), 0, reason: design);
      expect(bytes.getUint8((5 * 200 + 100) * 4 + 3), lessThan(255));
      image.dispose();
      picture.dispose();
    }
  });

  test('catalog renders and can produce a review contact sheet', () async {
    final font = FontLoader('ReviewSans')
      ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf'));
    await font.load();
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawColor(const Color(0xFFF0ECE3), BlendMode.src);
    void label(String value, double x, double y, {double size = 15}) {
      final text = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: 'ReviewSans',
            color: const Color(0xFF443B33),
            fontSize: size,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 1100);
      text.paint(c, Offset(x, y));
      text.dispose();
    }

    label('ALBUMIUM / KÂĞIT ATÖLYESİ', 40, 28, size: 30);
    label('Kodla çizilen desenler, kâğıt parçaları ve mum mühürleri', 40, 74);
    var index = 0;
    for (final entry in paperPatterns.entries.where((e) => e.key != 'plain')) {
      final x = 40.0 + index * 126;
      c.save();
      c.translate(x, 116);
      PaperMaterialPainter(entry.key).paint(c, const Size(110, 140));
      c.restore();
      label(entry.value, x, 268, size: 10);
      index++;
    }
    index = 0;
    for (final entry in paperKitLabels.entries) {
      final id = 'albumium:paperkit_${entry.key}';
      expect(isIllustratedSticker(id), isTrue);
      expect(albumStickerAspectRatio(id), paperKitAspect(entry.key));
      final x = 40.0 + (index % 6) * 190;
      final y = 330.0 + (index ~/ 6) * 260;
      final aspect = paperKitAspect(entry.key);
      final w = aspect < 1 ? 150.0 : 168.0;
      final h = w / aspect;
      c.save();
      c.translate(x + (168 - w) / 2, y + (204 - h) / 2);
      PaperKitPainter(entry.key).paint(c, Size(w, h));
      c.restore();
      label(entry.value, x, y + 214, size: 10);
      index++;
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1210, 1660);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes!.lengthInBytes, greaterThan(20000));
    if (Platform.environment['PAPER_KIT_PREVIEW'] == '1') {
      await Directory('output/paper-atelier').create(recursive: true);
      await File(
        'output/paper-atelier/collection.png',
      ).writeAsBytes(bytes.buffer.asUint8List());
    }
    image.dispose();
    picture.dispose();
  });
}
