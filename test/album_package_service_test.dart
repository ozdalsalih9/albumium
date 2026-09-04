import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/services/album_package_service.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

AlbumElementModel _photo(String id, String path, double x) => AlbumElementModel(
  id: id,
  type: AlbumElementType.photo,
  content: path,
  x: x,
  y: .2,
  width: .35,
  height: .3,
);

AlbumModel _album({String? photoPath}) {
  final now = DateTime(2026, 9, 4);
  return AlbumModel(
    id: 'shared-album',
    title: 'Paylaşılan Yaz',
    themeId: 'travel_postcard',
    bindingType: AlbumBindingType.stitched,
    createdAt: now,
    updatedAt: now,
    pages: [
      AlbumPageModel(
        id: 'page-one',
        backgroundColor: 0xFFF4E7CE,
        elements: [
          if (photoPath != null) ...[
            _photo('photo-one', photoPath, .08),
            _photo('photo-two', photoPath, .5),
          ],
          AlbumElementModel(
            id: 'caption',
            type: AlbumElementType.text,
            content: 'Bir yaz hatırası',
            x: .2,
            y: .65,
            width: .6,
            height: .12,
          ),
        ],
      ),
    ],
  );
}

Future<File> _writeArchive(
  Directory directory,
  Map<String, List<int>> entries,
) async {
  final archive = Archive();
  for (final entry in entries.entries) {
    archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
  }
  final encoded = ZipEncoder().encode(archive);
  final file = File(
    '${directory.path}${Platform.pathSeparator}test.$albumPackageExtension',
  );
  await file.writeAsBytes(encoded, flush: true);
  return file;
}

void main() {
  late Directory root;
  late Directory temporary;
  late Directory documents;
  late AlbumPackageService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('albumium_package_test_');
    temporary = Directory('${root.path}${Platform.pathSeparator}temporary');
    documents = Directory('${root.path}${Platform.pathSeparator}documents');
    await temporary.create(recursive: true);
    await documents.create(recursive: true);
    service = AlbumPackageService(
      temporaryDirectoryProvider: () async => temporary,
      documentsDirectoryProvider: () async => documents,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('round trip deduplicates photos and regenerates imported IDs', () async {
    final sourceImage = image.Image(width: 480, height: 320, numChannels: 3);
    image.fill(sourceImage, color: image.ColorRgb8(192, 116, 92));
    final source = File('${root.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsBytes(image.encodeJpg(sourceImage, quality: 96));
    final original = _album(photoPath: source.path);
    const crop = Rect.fromLTRB(.1, .2, .8, .9);
    original.pages.first.elements.first.photoCrop = crop;

    final exported = await service.createPackage(original);
    expect(await exported.file.exists(), isTrue);
    expect(exported.mediaCount, 1);
    expect(exported.packageBytes, greaterThan(0));

    final archive = ZipDecoder().decodeBytes(await exported.file.readAsBytes());
    final manifest =
        jsonDecode(utf8.decode(archive.findFile('manifest.json')!.content))
            as Map<String, dynamic>;
    expect(jsonEncode(manifest), isNot(contains(source.path)));
    expect(manifest['format'], AlbumPackageService.formatName);
    expect(manifest['formatVersion'], AlbumPackageService.formatVersion);
    expect(manifest['media'], hasLength(1));

    final preview = await service.openPackage(exported.file.path);
    addTearDown(preview.dispose);
    expect(preview.album.title, original.title);
    expect(preview.album.bindingType, original.bindingType);
    final previewPhotos = preview.album.pages.first.elements
        .where((element) => element.type == AlbumElementType.photo)
        .toList();
    expect(previewPhotos, hasLength(2));
    expect(previewPhotos.first.photoCrop, crop);
    expect(previewPhotos.first.content, previewPhotos.last.content);
    expect(await File(previewPhotos.first.content).exists(), isTrue);

    final imported = await service.importCopy(preview);
    expect(imported.id, isNot(original.id));
    expect(imported.pages.first.id, isNot(original.pages.first.id));
    expect(
      imported.pages.first.elements.map((element) => element.id).toSet(),
      isNot(containsAll(original.pages.first.elements.map((e) => e.id))),
    );
    final importedPhotos = imported.pages.first.elements
        .where((element) => element.type == AlbumElementType.photo)
        .toList();
    expect(importedPhotos.first.content, importedPhotos.last.content);
    expect(importedPhotos.first.photoCrop, crop);
    expect(await File(importedPhotos.first.content).exists(), isTrue);
  });

  test('creates and opens an album that has no photos', () async {
    final exported = await service.createPackage(_album());
    final preview = await service.openPackage(exported.file.path);
    addTearDown(preview.dispose);

    expect(exported.mediaCount, 0);
    expect(preview.mediaCount, 0);
    expect(preview.album.pages, hasLength(1));
  });

  test('rejects a package with path traversal content', () async {
    final file = await _writeArchive(temporary, {
      '../escape.jpg': [1, 2, 3],
    });

    await expectLater(
      service.openPackage(file.path),
      throwsA(
        isA<AlbumPackageException>().having(
          (error) => error.failure,
          'failure',
          AlbumPackageFailure.unsafeContent,
        ),
      ),
    );
    expect(
      await File('${root.path}${Platform.pathSeparator}escape.jpg').exists(),
      isFalse,
    );
  });

  test('rejects media whose SHA-256 does not match the manifest', () async {
    final albumJson = _album().toJson();
    final elements =
        ((albumJson['pages'] as List).first as Map<String, dynamic>)['elements']
            as List;
    elements.insert(0, _photo('remote-photo', 'media/photo.jpg', .1).toJson());
    final manifest = {
      'format': AlbumPackageService.formatName,
      'formatVersion': AlbumPackageService.formatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'album': albumJson,
      'media': [
        {
          'path': 'media/photo.jpg',
          'sha256': List.filled(64, '0').join(),
          'bytes': 3,
        },
      ],
    };
    final file = await _writeArchive(temporary, {
      'manifest.json': utf8.encode(jsonEncode(manifest)),
      'media/photo.jpg': [1, 2, 3],
    });

    await expectLater(
      service.openPackage(file.path),
      throwsA(
        isA<AlbumPackageException>().having(
          (error) => error.failure,
          'failure',
          AlbumPackageFailure.corruptMedia,
        ),
      ),
    );
  });

  test('rejects package versions newer than the app understands', () async {
    final manifest = {
      'format': AlbumPackageService.formatName,
      'formatVersion': AlbumPackageService.formatVersion + 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'album': _album().toJson(),
      'media': <Object>[],
    };
    final file = await _writeArchive(temporary, {
      'manifest.json': utf8.encode(jsonEncode(manifest)),
    });

    await expectLater(
      service.openPackage(file.path),
      throwsA(
        isA<AlbumPackageException>().having(
          (error) => error.failure,
          'failure',
          AlbumPackageFailure.unsupportedVersion,
        ),
      ),
    );
  });
}
