import 'package:albumium/models/album_models.dart';
import 'package:albumium/models/social_video_draft.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel socialTestAlbum({int pages = 3}) => AlbumModel(
  id: 'source',
  title: 'Yaz',
  themeId: 'travel_postcard',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  coverPhotoPath: '/photos/cover.jpg',
  importFingerprint: 'imported',
  memoryPeriod: 'month',
  pages: List.generate(
    pages,
    (i) => AlbumPageModel(
      id: 'p$i',
      backgroundColor: 0xFFF0E0D0,
      elements: [
        AlbumElementModel(
          id: 'e$i',
          type: AlbumElementType.text,
          content: 'Anı $i',
          x: .1,
          y: .2,
          width: .8,
          height: .2,
        ),
      ],
    ),
  ),
);

void main() {
  test('individual photos can be reordered without changing page layouts', () {
    final album = socialTestAlbum();
    for (var i = 0; i < 2; i++) {
      album.pages.first.elements.add(
        AlbumElementModel(
          id: 'photo$i',
          type: AlbumElementType.photo,
          content: '/photo$i.png',
          x: .2,
          y: .3,
          width: .4,
          height: .5,
          rotation: .2,
        ),
      );
    }
    final before = album.toJson();
    final draft = SocialVideoDraft(album)
      ..selectSource(SocialVideoSource.photos);
    expect(draft.availablePages.length, 2);
    expect(draft.canExport, true);
    final ids = draft.pageIds.reversed.toList();
    draft.pageIds
      ..clear()
      ..addAll(ids);
    expect(
      draft.pageById(draft.shots[1].pageId!).elements.single.content,
      '/photo1.png',
    );
    expect(album.toJson(), before);
    draft.selectSource(SocialVideoSource.pages);
    expect(draft.pageIds, ['p0', 'p1', 'p2']);
    expect(album.toJson(), before);
  });
  for (final seconds in [15, 30]) {
    for (final pages in [1, 3, 7, 20]) {
      test(
        '$seconds seconds with $pages pages has continuous exact timing and audio',
        () {
          final draft = SocialVideoDraft(socialTestAlbum(pages: pages))
            ..seconds = seconds;
          var cursor = 0;
          for (final shot in draft.shots) {
            expect(shot.start, cursor);
            expect(shot.frames, greaterThan(0));
            expect(draft.shotAt(cursor).index, shot.index);
            expect(draft.shotAt(cursor + shot.frames - 1).index, shot.index);
            cursor += shot.frames;
          }
          expect(cursor, seconds * 30);
          expect(draft.soundtrack.totalFrames, cursor);
          expect(
            draft.shots.where((s) => s.pageId != null).map((s) => s.pageId),
            draft.pageIds,
          );
        },
      );
    }
  }
  test(
    'reorder, selection, duration and cover do not change saved content',
    () {
      final album = socialTestAlbum();
      final before = album.toJson();
      final draft = SocialVideoDraft(album)
        ..seconds = 30
        ..coverPageId = 'p2'
        ..closingNote = 'Yeniden buluşalım';
      draft.pageIds
        ..clear()
        ..addAll(['p2', 'p0']);
      expect(draft.shots.where((s) => s.pageId != null).map((s) => s.pageId), [
        'p2',
        'p0',
      ]);
      expect(album.toJson(), before);
      // Switching resolution lives outside the draft and does not discard it.
      expect(draft.closingNote, 'Yeniden buluşalım');
    },
  );
  test(
    'empty, duplicate, oversized and unsupported duration drafts cannot export',
    () {
      expect(SocialVideoDraft(socialTestAlbum(pages: 0)).canExport, false);
      expect(SocialVideoDraft(socialTestAlbum(pages: 21)).canExport, false);
      final draft = SocialVideoDraft(socialTestAlbum());
      draft.pageIds.add('p0');
      expect(draft.canExport, false);
      draft.pageIds.removeLast();
      draft.seconds = 16;
      expect(draft.canExport, false);
    },
  );
  test('gift is a deep independent copy using the existing album schema', () {
    final source = socialTestAlbum();
    final before = source.toJson();
    final gift = createGiftAlbum(
      source,
      '  Ada  ',
      '  İyi ki varsın!  ',
      now: DateTime(2026, 9, 13),
    );
    expect(source.toJson(), before);
    expect(gift.id, isNot(source.id));
    expect(gift.coverPhotoPath, source.coverPhotoPath);
    expect(gift.importFingerprint, isNull);
    expect(gift.memoryPeriod, isNull);
    expect(gift.pages, hasLength(4));
    expect(gift.pages.first.elements.map((e) => e.content), [
      'Ada',
      'İyi ki varsın!',
    ]);
    for (var i = 0; i < source.pages.length; i++) {
      expect(gift.pages[i + 1].id, isNot(source.pages[i].id));
      expect(
        gift.pages[i + 1].elements.first.id,
        isNot(source.pages[i].elements.first.id),
      );
      expect(
        gift.pages[i + 1].elements.first.content,
        source.pages[i].elements.first.content,
      );
    }
    gift.pages[1].elements.first.content = 'Değişti';
    expect(source.toJson(), before);
    expect(AlbumModel.fromJson(gift.toJson()).toJson(), gift.toJson());
  });
  test('gift rejects missing or excessive recipient and message', () {
    final source = socialTestAlbum();
    expect(() => createGiftAlbum(source, ' ', 'Hi'), throwsArgumentError);
    expect(() => createGiftAlbum(source, 'a' * 61, ''), throwsArgumentError);
    expect(
      () => createGiftAlbum(source, 'Ada', 'a' * 281),
      throwsArgumentError,
    );
  });
}
