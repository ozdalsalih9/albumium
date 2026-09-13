import 'album_models.dart';
import 'cinematic_storyboard.dart';

enum SocialVideoTemplate {
  summer('Yaz Anıları'),
  together('Birlikte'),
  year('Yıl Özeti');

  const SocialVideoTemplate(this.title);
  final String title;
}

enum SocialVideoSource { pages, photos }

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
        (e) => e.type == AlbumElementType.photo,
      ))
        AlbumPageModel(
          id: 'video-photo:${page.id}:${photo.id}',
          backgroundColor: page.backgroundColor,
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
  int seconds = 15;
  String? coverPageId;
  String closingNote = '';
  final List<String> pageIds;
  static const fps = 30;
  int get totalFrames => seconds * fps;
  bool get canExport =>
      [15, 30].contains(seconds) &&
      pageIds.isNotEmpty &&
      pageIds.length <= 20 &&
      pageIds.toSet().length == pageIds.length;

  List<SocialVideoShot> get shots {
    if (!canExport) throw StateError('Choose between 1 and 20 pages.');
    final available = totalFrames - fps * 4;
    final base = available ~/ pageIds.length;
    final remainder = available % pageIds.length;
    var cursor = fps * 2;
    final result = <SocialVideoShot>[
      const SocialVideoShot(index: 0, start: 0, frames: fps * 2),
    ];
    for (var i = 0; i < pageIds.length; i++) {
      final count = base + (i < remainder ? 1 : 0);
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
      SocialVideoShot(index: result.length, start: cursor, frames: fps * 2),
    );
    return result;
  }

  SocialVideoShot shotAt(int frame) =>
      shots.lastWhere((s) => s.start <= frame.clamp(0, totalFrames - 1));
  CinematicStoryboard get soundtrack => CinematicStoryboard(
    fps: fps,
    beats: [
      for (final shot in shots)
        CinematicBeat(
          kind: shot.index == 0
              ? CinematicBeatKind.prologue
              : shot.pageId == null
              ? CinematicBeatKind.epilogue
              : CinematicBeatKind.memory,
          from: shot.index,
          frameCount: shot.frames,
          shotVariant: template.index,
        ),
    ],
  );
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
