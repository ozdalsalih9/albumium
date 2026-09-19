import 'package:albumium/models/album_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every category offers at least one cover', () {
    for (final category in AlbumThemeCategory.values) {
      expect(
        themesInCategory(category),
        isNotEmpty,
        reason: '${category.label} has no cover to show.',
      );
    }
  });

  test('theme ids are unique and the catalogue is the unfiltered view', () {
    expect(
      albumThemes.map((theme) => theme.id).toSet(),
      hasLength(albumThemes.length),
    );
    expect(themesInCategory(null), albumThemes);
  });

  test('filtering keeps catalogue order', () {
    final travel = themesInCategory(AlbumThemeCategory.travel);
    expect(
      travel.map((theme) => theme.id).toList(),
      albumThemes
          .where((theme) => theme.category == AlbumThemeCategory.travel)
          .map((theme) => theme.id)
          .toList(),
    );
  });

  test('one cover is free so a first album needs no purchase', () {
    final free = albumThemes.where((theme) => !theme.isPremium).toList();
    expect(free.map((theme) => theme.id), ['soft_romance']);
    expect(albumThemes.first.isPremium, isFalse);
  });

  test('every cover ships artwork', () {
    for (final theme in albumThemes) {
      expect(theme.coverAsset, isNotNull, reason: '${theme.id} has no cover.');
    }
  });
}
