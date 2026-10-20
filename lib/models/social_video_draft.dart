import 'album_models.dart';

enum SocialVideoTemplate {
  summer('Gün ışığı'),
  together('Birlikte'),
  year('Gece arşivi'),
  editorial('Editoryal'),
  botanical('Botanik');

  const SocialVideoTemplate(this.title);
  final String title;
}

enum SocialVideoSource { pages, photos }

enum SocialVideoPace {
  lively('Canlı', 72),
  natural('Doğal', 108),
  calm('Sakin', 150);

  const SocialVideoPace(this.title, this.pageFrames);
  final String title;
  final int pageFrames;
}

class SocialVideoShot {
  const SocialVideoShot({
    required this.index,
    required this.start,
    required this.frames,
    this.pageId,
  });
  final int index, start, frames;
  final String? pageId;
}

/// A video-only draft; source albums and their package format are untouched.
class SocialVideoDraft {
  SocialVideoDraft(AlbumModel album)
    : _album = album,
      pageIds = album.pages.map((p) => p.id).toList();
  final AlbumModel _album;
  SocialVideoSource source = SocialVideoSource.pages;
  late final List<AlbumPageModel> _photoPages = [
    for (final page in _album.pages)
      for (final photo in page.elements.where(
        (e) => e.type == AlbumElementType.photo && e.content.isNotEmpty,
      ))
        AlbumPageModel(
          id: 'video-photo:${page.id}:${photo.id}',
          backgroundColor: page.backgroundColor,
          paperPattern: page.paperPattern,
          elements: [
            AlbumElementModel.fromJson({
              ...photo.toJson(),
              'x': .05,
              'y': .05,
              'width': .9,
              'height': .9,
              'scale': 1.0,
              'rotation': 0.0,
            }),
          ],
        ),
  ];
  List<AlbumPageModel> get availablePages =>
      source == SocialVideoSource.pages ? _album.pages : _photoPages;
  AlbumPageModel pageById(String id) =>
      availablePages.firstWhere((p) => p.id == id);
  void selectSource(SocialVideoSource value) {
    if (value == source) return;
    source = value;
    coverPageId = null;
    pageIds
      ..clear()
      ..addAll(availablePages.map((p) => p.id));
  }

  SocialVideoTemplate template = SocialVideoTemplate.summer;
  SocialVideoPace pace = SocialVideoPace.natural;
  String? coverPageId;
  String closingNote = '';
  final List<String> pageIds;
  static const fps = 30;
  static const openingFrames = 60;
  static const closingFrames = 45;
  static const turnFrames = 27;
  int get totalFrames =>
      openingFrames + pageIds.length * pace.pageFrames + closingFrames;
  double get seconds => totalFrames / fps;
  Duration get duration => Duration(
    microseconds: (totalFrames * Duration.microsecondsPerSecond / fps).round(),
  );
  bool get canExport =>
      pageIds.isNotEmpty &&
      pageIds.toSet().length == pageIds.length &&
      pageIds.every(availablePages.map((p) => p.id).toSet().contains) &&
      (coverPageId == null || availablePages.any((p) => p.id == coverPageId));

  List<SocialVideoShot> get shots {
    if (!canExport) throw StateError('Choose at least one valid page.');
    var cursor = openingFrames;
    final result = <SocialVideoShot>[
      const SocialVideoShot(index: 0, start: 0, frames: openingFrames),
    ];
    for (var i = 0; i < pageIds.length; i++) {
      final count = pace.pageFrames;
      result.add(
        SocialVideoShot(
          index: i + 1,
          start: cursor,
          frames: count,
          pageId: pageIds[i],
        ),
      );
      cursor += count;
    }
    result.add(
      SocialVideoShot(
        index: result.length,
        start: cursor,
        frames: closingFrames,
      ),
    );
    return result;
  }

  SocialVideoShot shotAt(int frame) {
    final position = frame.clamp(0, totalFrames - 1);
    if (position < openingFrames) {
      return const SocialVideoShot(index: 0, start: 0, frames: openingFrames);
    }
    final page = (position - openingFrames) ~/ pace.pageFrames;
    if (page >= pageIds.length) {
      return SocialVideoShot(
        index: pageIds.length + 1,
        start: totalFrames - closingFrames,
        frames: closingFrames,
      );
    }
    return SocialVideoShot(
      index: page + 1,
      start: openingFrames + page * pace.pageFrames,
      frames: pace.pageFrames,
      pageId: pageIds[page],
    );
  }
}

/// A gift is an independent editable copy, using existing text/page elements.
AlbumModel createGiftAlbum(
  AlbumModel source,
  String recipient,
  String message, {
  DateTime? now,
}) {
  if (recipient.trim().isEmpty ||
      recipient.trim().length > 60 ||
      message.trim().length > 280) {
    throw ArgumentError('Invalid recipient or message length');
  }
  final json = source.toJson();
  json['id'] = newId();
  final timestamp = now ?? DateTime.now();
  json['createdAt'] = timestamp.toIso8601String();
  json['updatedAt'] = timestamp.toIso8601String();
  json['title'] = '${recipient.trim()} · ${source.title}';
  json.remove('importFingerprint');
  json.remove('memoryPeriod');
  final copy = AlbumModel.fromJson(json);
  final pages = [
    for (final page in copy.pages)
      AlbumPageModel(
        id: newId(),
        backgroundColor: page.backgroundColor,
        paperPattern: page.paperPattern,
        elements: [
          for (final e in page.elements)
            AlbumElementModel.fromJson({...e.toJson(), 'id': newId()}),
        ],
      ),
  ];
  copy.pages
    ..clear()
    ..add(
      AlbumPageModel(
        id: newId(),
        backgroundColor: themeById(copy.themeId).pageColor.toARGB32(),
        elements: [
          AlbumElementModel(
            id: newId(),
            type: AlbumElementType.text,
            content: recipient.trim(),
            x: .1,
            y: .24,
            width: .8,
            height: .18,
            fontSize: 28,
          ),
          AlbumElementModel(
            id: newId(),
            type: AlbumElementType.text,
            content: message.trim(),
            x: .1,
            y: .46,
            width: .8,
            height: .40,
            fontSize: 18,
          ),
        ],
      ),
    )
    ..addAll(pages);
  return copy;
}
