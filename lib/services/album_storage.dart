import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/album_models.dart';
import 'error_reporter.dart';

/// Ham veriden okunan kütüphane ile o okumanın ne kadar güvenilir olduğunu
/// birlikte taşır.
///
/// "Boş kütüphane" ile "okunamadı" ayrımı kritik: ikisi de boş bir liste
/// döndürür, ama ikincisinin üzerine yazmak kullanıcının bütün albümlerini
/// geri dönüşsüz siler.
class _Library {
  const _Library({
    required this.albums,
    required this.isIntact,
    required this.raw,
  });

  /// Kurtarılabilen albümler. Çağıran üzerinde değişiklik yapabilsin diye
  /// her zaman büyütülebilir bir listedir.
  final List<AlbumModel> albums;

  /// Ham veri eksiksiz okunabildiyse true. False ise kurtarılamayan kayıtlar
  /// vardı; üzerine yazmadan önce ham veri karantinaya alınır.
  final bool isIntact;

  /// Diskteki ham metin; karantina için saklanır.
  final String? raw;
}

class AlbumStorage {
  AlbumStorage._();

  static final AlbumStorage instance = AlbumStorage._();

  static const _albumsKey = 'albumium.albums.v1';

  /// Okunamayan ham verinin, silinmeden bir kenara alındığı anahtar.
  static const quarantineKey = 'albumium.albums.corrupt';

  /// Yazılan zarfın sürümü. Sürümsüz (çıplak liste) veri sürüm 1 sayılır.
  static const _schemaVersion = 2;

  /// Large album libraries can contain many page elements and embedded asset
  /// paths. Decode those JSON payloads away from the UI isolate so opening the
  /// library does not stall scrolling or the launch transition.
  static const _backgroundDecodeThreshold = 256 * 1024;

  /// Yazma işlemleri bu zincire dizilir.
  ///
  /// `saveAlbum` atomik olmayan bir oku-değiştir-yaz; editörde kaydetme
  /// zamanlayıcısı, `dispose` ve `PopScope` neredeyse aynı anda tetiklendiği
  /// için iki yazma çakışıp birbirini eziyordu.
  Future<void> _writes = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writes = _writes.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<List<AlbumModel>> loadAlbums() async => (await _read()).albums;

  Future<_Library> _read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_albumsKey);
    if (raw == null || raw.isEmpty) {
      return _Library(albums: <AlbumModel>[], isIntact: true, raw: null);
    }

    Object? decoded;
    try {
      decoded = raw.length >= _backgroundDecodeThreshold
          ? await Isolate.run<Object?>(() => jsonDecode(raw))
          : jsonDecode(raw);
    } catch (error, stack) {
      // Zarfın kendisi okunamıyor: tek bir kayıt değil, her şey şüpheli.
      ErrorReporter.report(error, stack, context: 'albüm verisi çözümlenemedi');
      return _Library(albums: <AlbumModel>[], isIntact: false, raw: raw);
    }

    // Sürüm 1 çıplak bir listeydi; sürüm 2'den itibaren zarf kullanılıyor.
    final entries = switch (decoded) {
      List<dynamic> list => list,
      Map<String, dynamic> envelope => envelope['albums'],
      _ => null,
    };
    if (entries is! List) {
      ErrorReporter.report(
        StateError('albüm listesi beklenen biçimde değil'),
        StackTrace.current,
      );
      return _Library(albums: <AlbumModel>[], isIntact: false, raw: raw);
    }

    final albums = <AlbumModel>[];
    var intact = true;
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) {
        intact = false;
        continue;
      }
      try {
        albums.add(AlbumModel.fromJson(entry));
      } catch (error, stack) {
        // Tek bir bozuk albüm, sağlam olanları da götürmemeli.
        intact = false;
        ErrorReporter.report(error, stack, context: 'albüm kaydı okunamadı');
      }
    }

    albums.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _Library(albums: albums, isIntact: intact, raw: raw);
  }

  /// Okunamayan ham veriyi silmeden bir kenara alır, böylece elle kurtarma
  /// mümkün kalır. Yalnızca ilk kez yazar; sonraki kayıtlar ilk karantinayı
  /// ezmez.
  Future<void> _quarantine(SharedPreferences preferences, String? raw) async {
    if (raw == null || raw.isEmpty) return;
    if (preferences.getString(quarantineKey) != null) return;
    await preferences.setString(quarantineKey, raw);
  }

  Future<void> _persist(
    SharedPreferences preferences,
    List<AlbumModel> albums,
  ) async {
    await preferences.setString(
      _albumsKey,
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'albums': albums.map((album) => album.toJson()).toList(),
      }),
    );
  }

  Future<void> saveAlbum(AlbumModel album) => _serialized(() async {
    final library = await _read();
    final preferences = await SharedPreferences.getInstance();
    if (!library.isIntact) await _quarantine(preferences, library.raw);

    final albums = library.albums;
    album.updatedAt = DateTime.now();
    final index = albums.indexWhere((item) => item.id == album.id);
    if (index == -1) {
      albums.insert(0, album);
    } else {
      albums[index] = album;
    }
    await _persist(preferences, albums);
  });

  Future<void> deleteAlbum(AlbumModel album) => _serialized(() async {
    final library = await _read();
    final preferences = await SharedPreferences.getInstance();
    if (!library.isIntact) await _quarantine(preferences, library.raw);

    final albums = library.albums..removeWhere((item) => item.id == album.id);
    await _persist(preferences, albums);
  });

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
