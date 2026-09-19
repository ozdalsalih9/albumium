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
      'midnight_atlas',
      'dark_leather',
    });
  });

  test('every cover ships artwork', () {
    for (final theme in albumThemes) {
      expect(theme.coverAsset, isNotNull, reason: '${theme.id} has no cover.');
    }
  });
}
