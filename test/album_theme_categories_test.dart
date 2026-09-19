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

  test('the starter cover and the city covers are free', () {
    // A first album must be possible without paying, and the city covers are
    // the draw for the travel category.
    expect(albumThemes.first.id, 'soft_romance');
    expect(albumThemes.first.isPremium, isFalse);

    final cityCovers = albumThemes.where(
      (theme) =>
          theme.id.startsWith('travel_') && theme.id != 'travel_postcard',
    );
    expect(cityCovers, isNotEmpty);
    expect(cityCovers.every((theme) => !theme.isPremium), isTrue);

    expect(albumThemes.where((theme) => theme.isPremium).map((t) => t.id), {
      'vintage_diary',
      'animals',
      'travel_postcard',
      'best_friends',
      'minimal_editorial',
      'dark_leather',
    });
  });

  test('every cover ships artwork', () {
    for (final theme in albumThemes) {
      expect(theme.coverAsset, isNotNull, reason: '${theme.id} has no cover.');
    }
  });

  test('a retired cover keeps the artwork its albums were made with', () {
    // Midnight Atlas shared Travel Postcard's artwork and was dropped; albums
    // saved with it must not fall back to the first cover in the catalogue.
    expect(albumThemes.any((theme) => theme.id == 'midnight_atlas'), isFalse);
    expect(themeById('midnight_atlas').id, 'travel_postcard');
    expect(
      themeById('midnight_atlas').coverAsset,
      themeById('travel_postcard').coverAsset,
    );
    // An id that never existed still falls back to the free starter cover.
    expect(themeById('no_such_theme').id, 'soft_romance');
  });
}
