import 'dart:io';

import 'package:albumium/models/scrapbook_templates.dart';
import 'package:albumium/widgets/paper_materials.dart';
import 'package:albumium/widgets/scrapbook_art.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paper and scrapbook art is generated, and the generators in `tool/`
/// can only write PNG. The app ships WebP, which costs a fifth of the bytes
/// for the same picture, so the generators are followed by
/// `python -I tool/png_to_webp.py`.
///
/// Forgetting that step leaves PNGs beside a widget asking for `.webp`: the
/// art silently disappears from pages that have no other failure to show.
/// These tests are what notices instead.
const _generatedFolders = ['assets/paper_kit', 'assets/scrapbook'];

List<File> _filesIn(String folder, String extension) => Directory(folder)
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith(extension))
    .toList();

void main() {
  test('the generated art ships as WebP, with no PNG left behind', () {
    for (final folder in _generatedFolders) {
      expect(
        _filesIn(folder, '.png').map((file) => file.path),
        isEmpty,
        reason:
            'run "python -I tool/png_to_webp.py" after regenerating $folder',
      );
      expect(_filesIn(folder, '.webp'), isNotEmpty);
    }
  });

  test('every scrapbook template has the preview its card asks for', () {
    for (final template in scrapbookTemplates) {
      final preview = File('assets/scrapbook/template_${template.id}.webp');
      expect(
        preview.existsSync(),
        isTrue,
        reason: '${template.id} would show an empty card',
      );
    }
  });

  test('every paper pattern and kit piece has its file', () {
    for (final pattern in paperPatterns.keys) {
      expect(
        File('assets/paper_kit/material_$pattern.webp').existsSync(),
        isTrue,
        reason: '$pattern would leave the page background blank',
      );
    }
    for (final design in paperKitLabels.keys) {
      expect(
        File('assets/paper_kit/$design.webp').existsSync(),
        isTrue,
        reason: '$design is offered in the picker but has no file',
      );
    }
  });

  test('every collage piece the art map names exists', () {
    for (final design in scrapbookArt.keys) {
      expect(
        File('assets/scrapbook/$design.webp').existsSync(),
        isTrue,
        reason: '$design is placed on pages but has no file',
      );
    }
  });
}
