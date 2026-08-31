import 'package:albumium/models/album_library_query.dart';
import 'package:albumium/models/album_models.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel _album({
  required String id,
  required String title,
  required DateTime createdAt,
  required DateTime updatedAt,
  AlbumProjectType projectType = AlbumProjectType.album,
}) => AlbumModel(
  id: id,
  title: title,
  themeId: 'classic',
  createdAt: createdAt,
  updatedAt: updatedAt,
  pages: const [],
  projectType: projectType,
);

void main() {
  final baseDate = DateTime.utc(2026, 1, 1);

  group('queryAlbumLibrary search', () {
    test(
      'searches the full collection, including beyond a conceptual page',
      () {
        final albums = List.generate(
          13,
          (index) => _album(
            id: 'album-$index',
            title: index == 12 ? 'İSTANBUL Hatıraları' : 'Albüm $index',
            createdAt: baseDate.add(Duration(days: index)),
            updatedAt: baseDate.add(Duration(days: index)),
          ),
        );

        final result = queryAlbumLibrary(albums, searchQuery: 'istanbul');

        expect(result.map((album) => album.id), ['album-12']);
      },
    );

    test('handles both Turkish dotted and dotless I case pairs', () {
      final albums = [
        _album(
          id: 'dotless',
          title: 'IŞIK Defteri',
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
        _album(
          id: 'dotted',
          title: 'İNCİ Albümü',
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      ];

      expect(
        queryAlbumLibrary(albums, searchQuery: 'ışık').single.id,
        'dotless',
      );
      expect(
        queryAlbumLibrary(albums, searchQuery: 'inci').single.id,
        'dotted',
      );
    });
  });

  test('filters albums and occasion cards while all keeps both', () {
    final album = _album(
      id: 'album',
      title: 'Albüm',
      createdAt: baseDate,
      updatedAt: baseDate,
    );
    final card = _album(
      id: 'card',
      title: 'Kart',
      createdAt: baseDate,
      updatedAt: baseDate,
      projectType: AlbumProjectType.occasionCard,
    );
    final input = [album, card];

    expect(
      queryAlbumLibrary(
        input,
        filter: AlbumLibraryFilter.albums,
      ).map((item) => item.id),
      ['album'],
    );
    expect(
      queryAlbumLibrary(
        input,
        filter: AlbumLibraryFilter.cards,
      ).map((item) => item.id),
      ['card'],
    );
    expect(queryAlbumLibrary(input).map((item) => item.id), ['album', 'card']);
  });

  group('sorting', () {
    late List<AlbumModel> albums;

    setUp(() {
      albums = [
        _album(
          id: 'c',
          title: 'Zambak',
          createdAt: baseDate.add(const Duration(days: 1)),
          updatedAt: baseDate.add(const Duration(days: 3)),
        ),
        _album(
          id: 'b',
          title: 'İnci',
          createdAt: baseDate.add(const Duration(days: 3)),
          updatedAt: baseDate.add(const Duration(days: 1)),
        ),
        _album(
          id: 'a',
          title: 'Irmak',
          createdAt: baseDate.add(const Duration(days: 3)),
          updatedAt: baseDate.add(const Duration(days: 3)),
        ),
        _album(
          id: 'd',
          title: 'Anılar',
          createdAt: baseDate.add(const Duration(days: 2)),
          updatedAt: baseDate.add(const Duration(days: 2)),
        ),
      ];
    });

    test('sorts by most recently updated with id as the tie-breaker', () {
      expect(
        queryAlbumLibrary(
          albums,
          sort: AlbumLibrarySort.updatedNewest,
        ).map((album) => album.id),
        ['a', 'c', 'd', 'b'],
      );
    });

    test('sorts by newest created with id as the tie-breaker', () {
      expect(
        queryAlbumLibrary(
          albums,
          sort: AlbumLibrarySort.createdNewest,
        ).map((album) => album.id),
        ['a', 'b', 'd', 'c'],
      );
    });

    test('sorts by oldest created with id as the tie-breaker', () {
      expect(
        queryAlbumLibrary(
          albums,
          sort: AlbumLibrarySort.createdOldest,
        ).map((album) => album.id),
        ['c', 'd', 'a', 'b'],
      );
    });

    test('sorts titles with Turkish alphabet rules', () {
      expect(
        queryAlbumLibrary(
          albums,
          sort: AlbumLibrarySort.titleAz,
        ).map((album) => album.id),
        ['d', 'a', 'b', 'c'],
      );
    });

    test('uses id as a deterministic tie-breaker for every sort', () {
      final ties = [
        _album(
          id: 'z-id',
          title: 'İNCİ',
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
        _album(
          id: 'a-id',
          title: 'inci',
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      ];

      for (final sort in AlbumLibrarySort.values) {
        expect(
          queryAlbumLibrary(ties, sort: sort).map((album) => album.id),
          ['a-id', 'z-id'],
          reason: 'failed for $sort',
        );
      }
    });
  });

  test('returns a new list and never reorders the input', () {
    final input = [
      _album(
        id: 'later',
        title: 'Sonra',
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(days: 1)),
      ),
      _album(
        id: 'earlier',
        title: 'Önce',
        createdAt: baseDate,
        updatedAt: baseDate,
      ),
    ];

    final result = queryAlbumLibrary(
      input,
      sort: AlbumLibrarySort.createdOldest,
    );

    expect(identical(result, input), isFalse);
    expect(result.map((album) => album.id), ['earlier', 'later']);
    expect(input.map((album) => album.id), ['later', 'earlier']);
  });
}
