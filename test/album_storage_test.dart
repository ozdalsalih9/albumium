import 'dart:convert';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/services/album_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'albumium.albums.v1';

AlbumModel _album(String id, {String? title, DateTime? updatedAt}) =>
    AlbumModel(
      id: id,
      title: title ?? 'Albüm $id',
      themeId: 'soft_romance',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
      pages: [AlbumPageModel(id: 'p-$id', backgroundColor: 0xFFFFFFFF)],
    );

Future<void> _seedRaw(String raw) async {
  SharedPreferences.setMockInitialValues({_key: raw});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storage = AlbumStorage.instance;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('temel davranış', () {
    test('kaydedilen albüm geri yüklenir', () async {
      await storage.saveAlbum(_album('a'));

      final loaded = await storage.loadAlbums();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'a');
      expect(loaded.single.pages.single.id, 'p-a');
    });

    test('aynı kimlikle kaydetmek çoğaltmaz, günceller', () async {
      await storage.saveAlbum(_album('a', title: 'İlk'));
      await storage.saveAlbum(_album('a', title: 'Sonra'));

      final loaded = await storage.loadAlbums();
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Sonra');
    });

    test('silme yalnızca hedefi kaldırır', () async {
      await storage.saveAlbum(_album('a'));
      await storage.saveAlbum(_album('b'));

      await storage.deleteAlbum(_album('a'));

      final loaded = await storage.loadAlbums();
      expect(loaded.map((e) => e.id), ['b']);
    });

    test('en son güncellenen başa gelir', () async {
      await storage.saveAlbum(_album('eski'));
      await storage.saveAlbum(_album('yeni'));

      final loaded = await storage.loadAlbums();
      expect(loaded.first.id, 'yeni');
    });
  });

  group('bozuk veri — veri kaybı koruması', () {
    test('okunamayan kütüphane silinmeden karantinaya alınır', () async {
      await _seedRaw('{bu gecerli JSON degil');

      // Kullanıcı kütüphaneyi boş görüp yeni bir albüm oluşturur.
      await storage.saveAlbum(_album('yeni'));

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(AlbumStorage.quarantineKey),
        contains('bu gecerli JSON degil'),
        reason:
            'Yükleme başarısızken üzerine yazılırsa kullanıcının tüm albümleri '
            'geri dönüşsüz silinir; ham veri saklanmalı.',
      );
      // Uygulama yine de kullanılabilir kalmalı.
      expect((await storage.loadAlbums()).map((e) => e.id), ['yeni']);
    });

    test('karantina ilk hâlini korur, sonraki kayıtlar ezmez', () async {
      await _seedRaw('ilk bozulma');
      await storage.saveAlbum(_album('a'));
      await storage.saveAlbum(_album('b'));

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(AlbumStorage.quarantineKey), 'ilk bozulma');
    });

    test('tek bozuk albüm diğerlerini götürmez', () async {
      final saglam = _album('saglam').toJson();
      final bozuk = _album('bozuk').toJson()..remove('createdAt');
      await _seedRaw(jsonEncode([saglam, bozuk]));

      final loaded = await storage.loadAlbums();
      expect(
        loaded.map((e) => e.id),
        contains('saglam'),
        reason: 'Bozuk bir kayıt, sağlam kayıtları da düşürmemeli.',
      );
    });

    test('bozuk sayfa albümün geri kalanını götürmez', () async {
      final json = _album('a').toJson();
      (json['pages'] as List).add({'id': 'kirik'});
      await _seedRaw(jsonEncode([json]));

      final loaded = await storage.loadAlbums();
      expect(loaded, hasLength(1), reason: 'Albüm kurtarılabilmeli.');
      expect(loaded.single.pages.map((p) => p.id), contains('p-a'));
    });
  });

  group('şema geçişi', () {
    test('sürüm 1 verisi (çıplak liste) okunmaya devam eder', () async {
      // Kullanıcıların cihazında bugün duran biçim: zarf yok, doğrudan liste.
      await _seedRaw(jsonEncode([_album('eski').toJson()]));

      final loaded = await storage.loadAlbums();
      expect(loaded.map((e) => e.id), ['eski']);
    });

    test('sürüm 1 verisi kaybolmadan sürüm 2 zarfına yükseltilir', () async {
      await _seedRaw(jsonEncode([_album('eski').toJson()]));

      await storage.saveAlbum(_album('yeni'));

      final raw = (await SharedPreferences.getInstance()).getString(_key)!;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      expect(envelope['schemaVersion'], 2);
      expect(
        (await storage.loadAlbums()).map((e) => e.id).toSet(),
        {'eski', 'yeni'},
        reason: 'Yükseltme eski albümleri düşürmemeli.',
      );
    });

    test('sürüm 1 verisi karantinaya alınmaz', () async {
      await _seedRaw(jsonEncode([_album('eski').toJson()]));
      await storage.saveAlbum(_album('yeni'));

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(AlbumStorage.quarantineKey),
        isNull,
        reason: 'Sağlam eski veri bozuk sayılmamalı.',
      );
    });
  });

  group('eşzamanlı yazma', () {
    test('aynı anda kaydedilen iki albüm de kalır', () async {
      await Future.wait([
        storage.saveAlbum(_album('a')),
        storage.saveAlbum(_album('b')),
      ]);

      final loaded = await storage.loadAlbums();
      expect(
        loaded.map((e) => e.id).toSet(),
        {'a', 'b'},
        reason:
            'Atomik olmayan oku-değiştir-yaz nedeniyle ikinci kayıt '
            'birincinin okuduğu eski listeyi yazarsa güncelleme kaybolur.',
      );
    });
  });
}
