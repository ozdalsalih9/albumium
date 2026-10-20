// Run with: flutter test tool/render_scrapbook_assets.dart
// Original procedural artwork is baked once; no generative image service is used.
// These write PNG because Flutter's toByteData has no other format.
// The app ships WebP, so follow this with: python -I tool/png_to_webp.py
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:albumium/widgets/paper_materials.dart';
import 'package:albumium/widgets/scrapbook_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bake original materials and collage artwork', () async {
    Future<void> bake(String path, CustomPainter painter, Size size) async {
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.round(),
        size.height.round(),
      );
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await File(path).writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (final pattern in paperPatterns.keys) {
      await bake(
        'assets/paper_kit/material_$pattern.png',
        PaperMaterialPainter(pattern),
        const Size(600, 840),
      );
    }
    for (final key in paperKitLabels.keys) {
      await bake(
        'assets/paper_kit/$key.png',
        PaperKitPainter(key),
        Size(600, 600 / paperKitAspect(key)),
      );
    }
    for (final entry in scrapbookArt.entries) {
      final aspect = entry.value.$2;
      final width = aspect < .4 ? 200.0 : 600.0;
      await bake(
        'assets/scrapbook/${entry.key}.png',
        ScrapbookArtPainter(entry.key),
        Size(width, width / aspect),
      );
    }
  });
}
