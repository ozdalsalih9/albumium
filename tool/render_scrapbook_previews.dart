// Run after render_scrapbook_assets.dart using flutter test.
// These write PNG because Flutter's toByteData has no other format.
// The app ships WebP, so follow this with: python -I tool/png_to_webp.py
import 'dart:io';
import 'dart:ui' as ui;
import 'package:albumium/models/album_models.dart';
import 'package:albumium/models/scrapbook_templates.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('render shared page and card template previews', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
        .load();
    tester.view.physicalSize = const Size(500, 700);
    tester.view.devicePixelRatio = 1;
    final images = <ui.Image>[];
    for (final template in scrapbookTemplates) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: RepaintBoundary(
              key: key,
              child: AlbumPageCanvas(
                showPageNumber: false,
                page: createScrapbookPage(template),
                theme: themeById('minimal_editorial'),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await GoogleFonts.pendingFonts();
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: template.id);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File(
          'assets/scrapbook/template_${template.id}.png',
        ).writeAsBytes(bytes.buffer.asUint8List());
        images.add(image);
      });
    }
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      // Record a separate review contact sheet with all seven full-size layouts.
      final c = Canvas(recorder);
      c.drawColor(const Color(0xFFF3EEE5), BlendMode.src);
      for (var i = 0; i < images.length; i++) {
        final x = 24.0 + (i % 4) * 270, y = 24.0 + (i ~/ 4) * 410;
        c.drawImageRect(
          images[i],
          const Rect.fromLTWH(0, 0, 500, 700),
          Rect.fromLTWH(x, y, 250, 350),
          Paint(),
        );
        final label = TextPainter(
          text: TextSpan(
            text: scrapbookTemplates[i].title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              color: Color(0xFF51473D),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 250);
        label.paint(c, Offset(x, y + 362));
        label.dispose();
      }
      final picture = recorder.endRecording();
      final sheet = await picture.toImage(1104, 830);
      await Directory('output/scrapbook-studio').create(recursive: true);
      await File('output/scrapbook-studio/templates.png').writeAsBytes(
        (await sheet.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List(),
      );
      sheet.dispose();
      picture.dispose();
      for (final image in images) {
        image.dispose();
      }
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
