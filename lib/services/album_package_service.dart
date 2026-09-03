import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';

import '../models/album_models.dart';

const albumPackageMimeType = 'application/vnd.albumium.album+zip';
const albumPackageExtension = 'albumium';

enum AlbumPackageFailure {
  missingSource,
  tooLarge,
  invalidArchive,
  unsupportedVersion,
  unsafeContent,
  corruptMedia,
}

class AlbumPackageException implements Exception {
  const AlbumPackageException(this.failure, [this.details]);

  final AlbumPackageFailure failure;
  final String? details;

  @override
  String toString() => details == null
      ? 'AlbumPackageException(${failure.name})'
      : 'AlbumPackageException(${failure.name}: $details)';
}

enum AlbumPackageStage { preparing, optimizingPhotos, packaging }

typedef AlbumPackageProgress =
    void Function(AlbumPackageStage stage, double progress);

class AlbumPackageExport {
  const AlbumPackageExport({
    required this.file,
    required this.mediaCount,
    required this.originalMediaBytes,
    required this.packageBytes,
  });

  final File file;
  final int mediaCount;
  final int originalMediaBytes;
  final int packageBytes;
}

class AlbumPackagePreview {
  AlbumPackagePreview({
    required this.album,
    required this.packagePath,
    required this.packageBytes,
    required this.mediaCount,
    required Directory extractedDirectory,
  }) : _extractedDirectory = extractedDirectory;

  final AlbumModel album;
  final String packagePath;
  final int packageBytes;
  final int mediaCount;
  final Directory _extractedDirectory;

  Future<void> dispose() => _deleteDirectoryQuietly(_extractedDirectory);
}

class AlbumPackageService {
  AlbumPackageService({
    Future<Directory> Function()? temporaryDirectoryProvider,
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const formatName = 'albumium.album';
  static const formatVersion = 1;
  static const maxPackageBytes = 160 * 1024 * 1024;
  static const maxUncompressedBytes = 220 * 1024 * 1024;
  static const maxManifestBytes = 2 * 1024 * 1024;
  static const maxMediaFileBytes = 32 * 1024 * 1024;
  static const maxMediaCount = 160;
  static const maxPages = 80;
  static const maxElements = 1200;
  static const _photoLongEdge = 2048;
  static const _jpegQuality = 82;

  final Future<Directory> Function() _temporaryDirectoryProvider;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<AlbumPackageExport> createPackage(
    AlbumModel album, {
    AlbumPackageProgress? onProgress,
  }) async {
    if (album.projectType != AlbumProjectType.album) {
      throw const AlbumPackageException(
        AlbumPackageFailure.unsafeContent,
        'Only album projects can be packaged.',
      );
    }
    _validateAlbumLimits(album);
    onProgress?.call(AlbumPackageStage.preparing, 0);

    final temporary = await _temporaryDirectoryProvider();
    final workspace = Directory(
      '${temporary.path}${Platform.pathSeparator}albumium_package_${newId()}',
    );
    final mediaDirectory = Directory(
      '${workspace.path}${Platform.pathSeparator}media',
    );
    final exportDirectory = Directory(
      '${temporary.path}${Platform.pathSeparator}albumium_exports',
    );
    await mediaDirectory.create(recursive: true);
    await exportDirectory.create(recursive: true);
    await _cleanupOldPackageExports(exportDirectory);

    final photoSources = <String>[];
    for (final page in album.pages) {
      for (final element in page.elements) {
        if (element.type == AlbumElementType.photo &&
            element.content.trim().isNotEmpty &&
            !photoSources.contains(element.content)) {
          photoSources.add(element.content);
        }
      }
    }
    if (photoSources.length > maxMediaCount) {
      await _deleteDirectoryQuietly(workspace);
      throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
    }

    final sourceToPackagePath = <String, String>{};
    final packagedMedia = <String, Map<String, Object>>{};
    var originalMediaBytes = 0;

    try {
      for (var index = 0; index < photoSources.length; index++) {
        final source = photoSources[index];
        final sourceFile = File(source);
        if (!await sourceFile.exists()) {
          throw AlbumPackageException(
            AlbumPackageFailure.missingSource,
            source,
          );
        }
        final sourceLength = await sourceFile.length();
        if (sourceLength > maxMediaFileBytes) {
          throw AlbumPackageException(AlbumPackageFailure.tooLarge, source);
        }
        originalMediaBytes += sourceLength;
        final original = await sourceFile.readAsBytes();
        final optimized = await Isolate.run<Uint8List?>(() {
          return _optimizeAlbumPhoto(
            original,
            longEdge: _photoLongEdge,
            quality: _jpegQuality,
          );
        });
        final outputBytes = optimized ?? original;
        if (outputBytes.length > maxMediaFileBytes) {
          throw AlbumPackageException(AlbumPackageFailure.tooLarge, source);
        }
        final digest = sha256.convert(outputBytes).toString();
        final extension = optimized == null
            ? _safeSourceExtension(source)
            : '.jpg';
        final packagePath = 'media/$digest$extension';
        sourceToPackagePath[source] = packagePath;
        if (!packagedMedia.containsKey(packagePath)) {
          final staged = File(
            '${workspace.path}${Platform.pathSeparator}${packagePath.replaceAll('/', Platform.pathSeparator)}',
          );
          await staged.writeAsBytes(outputBytes, flush: true);
          packagedMedia[packagePath] = <String, Object>{
            'path': packagePath,
            'sha256': digest,
            'bytes': outputBytes.length,
          };
        }
        onProgress?.call(
          AlbumPackageStage.optimizingPhotos,
          photoSources.isEmpty ? 1 : (index + 1) / photoSources.length,
        );
      }

      final albumJson = _deepJsonMap(album.toJson());
      final pages = albumJson['pages']! as List<dynamic>;
      for (final page in pages.cast<Map<String, dynamic>>()) {
        final elements = page['elements']! as List<dynamic>;
        for (final element in elements.cast<Map<String, dynamic>>()) {
          if (element['type'] == AlbumElementType.photo.name) {
            final source = element['content'] as String;
            final packagePath = sourceToPackagePath[source];
            if (packagePath == null) {
              throw AlbumPackageException(
                AlbumPackageFailure.missingSource,
                source,
              );
            }
            element['content'] = packagePath;
          }
        }
      }

      final manifest = <String, Object>{
        'format': formatName,
        'formatVersion': formatVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'album': albumJson,
        'media': packagedMedia.values.toList(growable: false),
      };
      final manifestText = jsonEncode(manifest);
      if (utf8.encode(manifestText).length > maxManifestBytes) {
        throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
      }
      final manifestFile = File(
        '${workspace.path}${Platform.pathSeparator}manifest.json',
      );
      await manifestFile.writeAsString(manifestText, flush: true);

      onProgress?.call(AlbumPackageStage.packaging, .82);
      final output = File(
        '${exportDirectory.path}${Platform.pathSeparator}${albumPackageFilename(album.title)}',
      );
      final encoder = ZipFileEncoder();
      encoder.create(output.path, level: ZipFileEncoder.gzip);
      try {
        await encoder.addFile(manifestFile, 'manifest.json');
        var written = 0;
        for (final packagePath in packagedMedia.keys) {
          final staged = File(
            '${workspace.path}${Platform.pathSeparator}${packagePath.replaceAll('/', Platform.pathSeparator)}',
          );
          await encoder.addFile(staged, packagePath);
          written++;
          onProgress?.call(
            AlbumPackageStage.packaging,
            .82 + .18 * written / packagedMedia.length.clamp(1, maxMediaCount),
          );
        }
      } finally {
        await encoder.close();
      }
      final packageBytes = await output.length();
      if (packageBytes <= 0 || packageBytes > maxPackageBytes) {
        if (await output.exists()) await output.delete();
        throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
      }
      onProgress?.call(AlbumPackageStage.packaging, 1);
      return AlbumPackageExport(
        file: output,
        mediaCount: packagedMedia.length,
        originalMediaBytes: originalMediaBytes,
        packageBytes: packageBytes,
      );
    } finally {
      await _deleteDirectoryQuietly(workspace);
    }
  }

  Future<AlbumPackagePreview> openPackage(String path) async {
    final packageFile = File(path);
    if (!await packageFile.exists()) {
      throw AlbumPackageException(AlbumPackageFailure.missingSource, path);
    }
    final packageBytes = await packageFile.length();
    if (packageBytes <= 0 || packageBytes > maxPackageBytes) {
      throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(
        await packageFile.readAsBytes(),
        verify: true,
      );
    } catch (error) {
      throw AlbumPackageException(AlbumPackageFailure.invalidArchive, '$error');
    }

    final entries = <String, ArchiveFile>{};
    var totalUncompressed = 0;
    for (final entry in archive) {
      final name = entry.name;
      if (!_isSafeArchivePath(name) ||
          entry.isDirectory ||
          entry.isSymbolicLink ||
          entries.containsKey(name)) {
        throw AlbumPackageException(AlbumPackageFailure.unsafeContent, name);
      }
      if (entry.size < 0 || entry.size > maxMediaFileBytes) {
        throw AlbumPackageException(AlbumPackageFailure.tooLarge, name);
      }
      totalUncompressed += entry.size;
      if (totalUncompressed > maxUncompressedBytes) {
        throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
      }
      entries[name] = entry;
    }
    final manifestEntry = entries['manifest.json'];
    if (manifestEntry == null || manifestEntry.size > maxManifestBytes) {
      throw const AlbumPackageException(AlbumPackageFailure.invalidArchive);
    }

    Map<String, dynamic> manifest;
    try {
      final decoded = jsonDecode(utf8.decode(manifestEntry.content));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Manifest is not an object.');
      }
      manifest = decoded;
    } catch (error) {
      throw AlbumPackageException(AlbumPackageFailure.invalidArchive, '$error');
    }
    if (manifest['format'] != formatName) {
      throw const AlbumPackageException(AlbumPackageFailure.invalidArchive);
    }
    if (manifest['formatVersion'] != formatVersion) {
      throw const AlbumPackageException(AlbumPackageFailure.unsupportedVersion);
    }

    final mediaRaw = manifest['media'];
    final albumRaw = manifest['album'];
    if (mediaRaw is! List || albumRaw is! Map<String, dynamic>) {
      throw const AlbumPackageException(AlbumPackageFailure.invalidArchive);
    }
    if (mediaRaw.length > maxMediaCount) {
      throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
    }
    _validateAlbumJsonLimits(albumRaw);

    final declaredMedia = <String, ({String digest, int bytes})>{};
    for (final raw in mediaRaw) {
      if (raw is! Map<String, dynamic>) {
        throw const AlbumPackageException(AlbumPackageFailure.invalidArchive);
      }
      final mediaPath = raw['path'];
      final digest = raw['sha256'];
      final bytes = raw['bytes'];
      if (mediaPath is! String ||
          !mediaPath.startsWith('media/') ||
          !_isSafeArchivePath(mediaPath) ||
          digest is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
          bytes is! int ||
          bytes < 0 ||
          bytes > maxMediaFileBytes ||
          declaredMedia.containsKey(mediaPath)) {
        throw const AlbumPackageException(AlbumPackageFailure.unsafeContent);
      }
      declaredMedia[mediaPath] = (digest: digest, bytes: bytes);
    }
    if (entries.length != declaredMedia.length + 1 ||
        entries.keys.any(
          (name) => name != 'manifest.json' && !declaredMedia.containsKey(name),
        )) {
      throw const AlbumPackageException(AlbumPackageFailure.unsafeContent);
    }

    final temporary = await _temporaryDirectoryProvider();
    final extractedDirectory = Directory(
      '${temporary.path}${Platform.pathSeparator}albumium_incoming_${newId()}',
    );
    await extractedDirectory.create(recursive: true);
    final extractedPaths = <String, String>{};
    try {
      for (final declaration in declaredMedia.entries) {
        final archiveEntry = entries[declaration.key];
        if (archiveEntry == null) {
          throw AlbumPackageException(
            AlbumPackageFailure.corruptMedia,
            declaration.key,
          );
        }
        final content = archiveEntry.content;
        final expected = declaration.value;
        if (content.length != expected.bytes ||
            sha256.convert(content).toString() != expected.digest) {
          throw AlbumPackageException(
            AlbumPackageFailure.corruptMedia,
            declaration.key,
          );
        }
        final filename = declaration.key.substring('media/'.length);
        final destination = File(
          '${extractedDirectory.path}${Platform.pathSeparator}$filename',
        );
        await destination.writeAsBytes(content, flush: true);
        extractedPaths[declaration.key] = destination.path;
      }

      final albumJson = _deepJsonMap(albumRaw);
      final pages = albumJson['pages']! as List<dynamic>;
      for (final page in pages.cast<Map<String, dynamic>>()) {
        final elements = page['elements']! as List<dynamic>;
        for (final element in elements.cast<Map<String, dynamic>>()) {
          if (element['type'] != AlbumElementType.photo.name) continue;
          final mediaPath = element['content'];
          final extractedPath = extractedPaths[mediaPath];
          if (mediaPath is! String || extractedPath == null) {
            throw const AlbumPackageException(AlbumPackageFailure.corruptMedia);
          }
          element['content'] = extractedPath;
        }
      }

      AlbumModel album;
      try {
        album = AlbumModel.fromJson(albumJson);
      } catch (error) {
        throw AlbumPackageException(
          AlbumPackageFailure.invalidArchive,
          '$error',
        );
      }
      if (album.projectType != AlbumProjectType.album ||
          album.pages.length != pages.length) {
        throw const AlbumPackageException(AlbumPackageFailure.unsafeContent);
      }
      return AlbumPackagePreview(
        album: album,
        packagePath: path,
        packageBytes: packageBytes,
        mediaCount: declaredMedia.length,
        extractedDirectory: extractedDirectory,
      );
    } catch (_) {
      await _deleteDirectoryQuietly(extractedDirectory);
      rethrow;
    }
  }

  Future<AlbumModel> importCopy(AlbumPackagePreview preview) async {
    _validateAlbumLimits(preview.album);
    final documents = await _documentsDirectoryProvider();
    final mediaDirectory = Directory(
      '${documents.path}${Platform.pathSeparator}albumium_images',
    );
    await mediaDirectory.create(recursive: true);
    final copiedPaths = <String, String>{};
    final createdFiles = <File>[];
    try {
      Future<String> copyPhoto(String source) async {
        final existing = copiedPaths[source];
        if (existing != null) return existing;
        final sourceFile = File(source);
        if (!await sourceFile.exists()) {
          throw AlbumPackageException(
            AlbumPackageFailure.missingSource,
            source,
          );
        }
        final extension = _safeSourceExtension(source);
        final destination = File(
          '${mediaDirectory.path}${Platform.pathSeparator}${newId()}$extension',
        );
        final partial = File('${destination.path}.part');
        await sourceFile.copy(partial.path);
        await partial.rename(destination.path);
        createdFiles.add(destination);
        copiedPaths[source] = destination.path;
        return destination.path;
      }

      final pages = <AlbumPageModel>[];
      for (final page in preview.album.pages) {
        final elements = <AlbumElementModel>[];
        for (final element in page.elements) {
          final content = element.type == AlbumElementType.photo
              ? await copyPhoto(element.content)
              : element.content;
          elements.add(
            AlbumElementModel(
              id: newId(),
              type: element.type,
              content: content,
              x: element.x,
              y: element.y,
              width: element.width,
              height: element.height,
              rotation: element.rotation,
              scale: element.scale,
              frameStyle: element.frameStyle,
              photoShape: element.photoShape,
              textColor: element.textColor,
              fontSize: element.fontSize,
              extraData: element.extraData,
            ),
          );
        }
        pages.add(
          AlbumPageModel(
            id: newId(),
            backgroundColor: page.backgroundColor,
            elements: elements,
          ),
        );
      }
      final now = DateTime.now();
      return AlbumModel(
        id: newId(),
        title: preview.album.title,
        themeId: preview.album.themeId,
        bindingType: preview.album.bindingType,
        createdAt: now,
        updatedAt: now,
        pages: pages,
      );
    } catch (_) {
      for (final file in createdFiles) {
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static void _validateAlbumLimits(AlbumModel album) {
    if (album.pages.isEmpty || album.pages.length > maxPages) {
      throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
    }
    final elements = album.pages.fold<int>(
      0,
      (total, page) => total + page.elements.length,
    );
    if (elements > maxElements) {
      throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
    }
  }

  static void _validateAlbumJsonLimits(Map<String, dynamic> album) {
    final pages = album['pages'];
    if (pages is! List || pages.isEmpty || pages.length > maxPages) {
      throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
    }
    var elementCount = 0;
    for (final page in pages) {
      if (page is! Map<String, dynamic>) {
        throw const AlbumPackageException(AlbumPackageFailure.invalidArchive);
      }
      final elements = page['elements'];
      if (elements is! List) {
        throw const AlbumPackageException(AlbumPackageFailure.invalidArchive);
      }
      elementCount += elements.length;
      if (elementCount > maxElements ||
          elements.any((element) => element is! Map<String, dynamic>)) {
        throw const AlbumPackageException(AlbumPackageFailure.tooLarge);
      }
    }
  }
}

Uint8List? _optimizeAlbumPhoto(
  Uint8List source, {
  required int longEdge,
  required int quality,
}) {
  var decoded = image.decodeImage(source);
  if (decoded == null) return null;
  decoded = image.bakeOrientation(decoded);
  final longest = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  if (longest > longEdge) {
    decoded = decoded.width >= decoded.height
        ? image.copyResize(
            decoded,
            width: longEdge,
            interpolation: image.Interpolation.cubic,
          )
        : image.copyResize(
            decoded,
            height: longEdge,
            interpolation: image.Interpolation.cubic,
          );
  }
  return image.encodeJpg(
    decoded.convert(numChannels: 3),
    quality: quality,
    chroma: image.JpegChroma.yuv420,
  );
}

Map<String, dynamic> _deepJsonMap(Map<String, dynamic> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

String _safeSourceExtension(String source) {
  final filename = source.replaceAll('\\', '/').split('/').last;
  final dot = filename.lastIndexOf('.');
  if (dot <= 0) return '.img';
  final extension = filename.substring(dot).toLowerCase();
  return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension) ? extension : '.img';
}

bool _isSafeArchivePath(String value) {
  if (value.isEmpty || value.contains('\\') || value.contains('\u0000')) {
    return false;
  }
  if (value.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(value)) {
    return false;
  }
  final parts = value.split('/');
  return parts.every((part) => part.isNotEmpty && part != '.' && part != '..');
}

String albumPackageFilename(String title) {
  final normalized = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9ğüşöçıİĞÜŞÖÇ]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final safe = normalized.isEmpty ? 'albumium_album' : normalized;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return '${safe}_$stamp.$albumPackageExtension';
}

Future<void> _cleanupOldPackageExports(Directory directory) async {
  final cutoff = DateTime.now().subtract(const Duration(days: 1));
  try {
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !entity.path.toLowerCase().endsWith('.$albumPackageExtension')) {
        continue;
      }
      try {
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) await entity.delete();
      } catch (_) {
        // One inaccessible export must not prevent a new share.
      }
    }
  } catch (_) {
    // Export cleanup is best effort and deliberately stays shallow.
  }
}

Future<void> _deleteDirectoryQuietly(Directory directory) async {
  try {
    if (await directory.exists()) await directory.delete(recursive: true);
  } catch (_) {
    // Temporary cleanup is best effort and must not hide the primary result.
  }
}
