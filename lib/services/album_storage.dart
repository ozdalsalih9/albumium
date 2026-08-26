import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/album_models.dart';

class AlbumStorage {
  AlbumStorage._();

  static final AlbumStorage instance = AlbumStorage._();
  static const _albumsKey = 'albumium.albums.v1';

  Future<List<AlbumModel>> loadAlbums() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_albumsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final items = jsonDecode(raw) as List<dynamic>;
      final albums = items
          .map((item) => AlbumModel.fromJson(item as Map<String, dynamic>))
          .toList();
      albums.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return albums;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAlbum(AlbumModel album) async {
    final albums = await loadAlbums();
    album.updatedAt = DateTime.now();
    final index = albums.indexWhere((item) => item.id == album.id);
    if (index == -1) {
      albums.insert(0, album);
    } else {
      albums[index] = album;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _albumsKey,
      jsonEncode(albums.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteAlbum(AlbumModel album) async {
    final albums = await loadAlbums()
      ..removeWhere((item) => item.id == album.id);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _albumsKey,
      jsonEncode(albums.map((item) => item.toJson()).toList()),
    );
  }

  Future<String> importImage(XFile source) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}albumium_images',
    );
    await directory.create(recursive: true);
    final extension = source.path.contains('.')
        ? source.path.substring(source.path.lastIndexOf('.'))
        : '.jpg';
    final destination = File(
      '${directory.path}${Platform.pathSeparator}${newId()}$extension',
    );
    await File(source.path).copy(destination.path);
    return destination.path;
  }
}
