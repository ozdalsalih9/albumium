import 'album_models.dart';

/// Limits the projects shown in the album library.
enum AlbumLibraryFilter { all, albums, cards }

/// Defines the order of projects shown in the album library.
enum AlbumLibrarySort { updatedNewest, createdNewest, createdOldest, titleAz }

/// Applies library search, project filtering, and sorting to [albums].
///
/// Search and filtering always run on the complete input list. The returned
/// list is a new, shallow list; [albums] and its order are never modified.
List<AlbumModel> queryAlbumLibrary(
  List<AlbumModel> albums, {
  String searchQuery = '',
  AlbumLibraryFilter filter = AlbumLibraryFilter.all,
  AlbumLibrarySort sort = AlbumLibrarySort.updatedNewest,
}) {
  final normalizedQuery = _toTurkishLowerCase(searchQuery.trim());

  final result = albums
      .where((album) {
        if (!_matchesFilter(album, filter)) {
          return false;
        }

        return normalizedQuery.isEmpty ||
            _toTurkishLowerCase(album.title).contains(normalizedQuery);
      })
      .toList(growable: true);

  result.sort((left, right) {
    final primaryComparison = switch (sort) {
      AlbumLibrarySort.updatedNewest => right.updatedAt.compareTo(
        left.updatedAt,
      ),
      AlbumLibrarySort.createdNewest => right.createdAt.compareTo(
        left.createdAt,
      ),
      AlbumLibrarySort.createdOldest => left.createdAt.compareTo(
        right.createdAt,
      ),
      AlbumLibrarySort.titleAz => _compareTurkishTitles(
        left.title,
        right.title,
      ),
    };

    return primaryComparison != 0
        ? primaryComparison
        : left.id.compareTo(right.id);
  });

  return result;
}

bool _matchesFilter(AlbumModel album, AlbumLibraryFilter filter) =>
    switch (filter) {
      AlbumLibraryFilter.all => true,
      AlbumLibraryFilter.albums => album.projectType == AlbumProjectType.album,
      AlbumLibraryFilter.cards =>
        album.projectType == AlbumProjectType.occasionCard,
    };

/// Dart's locale-independent lowercasing does not model the Turkish dotted
/// and dotless I pair. Replacing the capitals first gives the expected pairs:
/// I/ı and İ/i.
String _toTurkishLowerCase(String value) =>
    value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

int _compareTurkishTitles(String left, String right) {
  final leftRunes = _toTurkishLowerCase(left).runes.toList(growable: false);
  final rightRunes = _toTurkishLowerCase(right).runes.toList(growable: false);
  final sharedLength = leftRunes.length < rightRunes.length
      ? leftRunes.length
      : rightRunes.length;

  for (var index = 0; index < sharedLength; index++) {
    final comparison = _turkishCollationWeight(
      leftRunes[index],
    ).compareTo(_turkishCollationWeight(rightRunes[index]));
    if (comparison != 0) {
      return comparison;
    }

    // Preserve a total ordering when two distinct, unsupported characters
    // happen to receive the same fallback weight in a future implementation.
    final runeComparison = leftRunes[index].compareTo(rightRunes[index]);
    if (comparison == 0 &&
        runeComparison != 0 &&
        !_turkishAlphabetOrder.containsKey(leftRunes[index]) &&
        !_turkishAlphabetOrder.containsKey(rightRunes[index])) {
      return runeComparison;
    }
  }

  return leftRunes.length.compareTo(rightRunes.length);
}

int _turkishCollationWeight(int rune) {
  final alphabetIndex = _turkishAlphabetOrder[rune];
  if (alphabetIndex != null) {
    return 0x10000 + alphabetIndex;
  }
  return 0x20000 + rune;
}

const _turkishAlphabetOrder = <int, int>{
  0x61: 0, // a
  0x62: 1, // b
  0x63: 2, // c
  0xE7: 3, // ç
  0x64: 4, // d
  0x65: 5, // e
  0x66: 6, // f
  0x67: 7, // g
  0x11F: 8, // ğ
  0x68: 9, // h
  0x131: 10, // ı
  0x69: 11, // i
  0x6A: 12, // j
  0x6B: 13, // k
  0x6C: 14, // l
  0x6D: 15, // m
  0x6E: 16, // n
  0x6F: 17, // o
  0xF6: 18, // ö
  0x70: 19, // p
  0x72: 20, // r
  0x73: 21, // s
  0x15F: 22, // ş
  0x74: 23, // t
  0x75: 24, // u
  0xFC: 25, // ü
  0x76: 26, // v
  0x79: 27, // y
  0x7A: 28, // z
};
