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

    expect(
      albumThemes
          .where((theme) => theme.price == CoverPrice.premium)
          .map((t) => t.id),
      {
        'vintage_diary',
        'animals',
        'travel_postcard',
        'best_friends',
        'minimal_editorial',
        'dark_leather',
        'family_tree',
        'love_velvet',
        'wedding_silk',
        'friendship_knot',
        'animals_companions',
      },
    );
    expect(
      albumThemes
          .where((theme) => theme.price == CoverPrice.standard)
          .map((t) => t.id),
      {
        'family_nest',
        'love_swans',
        'wedding_arch',
        'friendship_promise',
        'animals_wreath',
      },
    );
  });

  test('every category can be tried without paying', () {
    // A locked category would be a dead end: the covers are the only way in.
    for (final category in AlbumThemeCategory.values) {
      expect(
        themesInCategory(category).where((theme) => !theme.isPremium),
        isNotEmpty,
        reason: '${category.label} has no free cover.',
      );
    }
  });

  test('a price is shown exactly when the cover is paid', () {
    for (final theme in albumThemes) {
      expect(
        theme.price.label != null,
        theme.isPremium,
        reason: '${theme.id} disagrees about whether it costs anything.',
      );
    }
    expect(CoverPrice.standard.label, '₺4,99');
    expect(CoverPrice.premium.label, '₺14,99');
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
