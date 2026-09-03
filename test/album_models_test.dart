import 'dart:convert';

import 'package:albumium/models/album_models.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel _album() => AlbumModel(
  id: 'alb-1',
  title: 'Bizim Yazımız',
  themeId: 'soft_romance',
  bindingType: AlbumBindingType.stitched,
  createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
  updatedAt: DateTime.utc(2026, 6, 7, 8, 9, 10),
  pages: [
    AlbumPageModel(
      id: 'p-1',
      backgroundColor: 0xFFFFF7F2,
      elements: [
        AlbumElementModel(
          id: 'e-1',
          type: AlbumElementType.photo,
          content: '/tmp/a.jpg',
          x: 0.1,
          y: 0.2,
          width: 0.7,
          height: 0.5,
          rotation: -0.03,
          scale: 1.4,
          frameStyle: 3,
          photoShape: AlbumPhotoShape.arch,
          textColor: 0xFF112233,
          fontSize: 19.5,
          extraData: 'kart:dogumgunu',
        ),
      ],
    ),
    AlbumPageModel(id: 'p-2', backgroundColor: 0xFFFFFFFF),
  ],
);

void main() {
  group('serileştirme', () {
    test('albüm JSON turundan bozulmadan geçer', () {
      final before = _album();
      final after = AlbumModel.fromJson(
        jsonDecode(jsonEncode(before.toJson())) as Map<String, dynamic>,
      );

      expect(after.id, before.id);
      expect(after.title, before.title);
      expect(after.themeId, before.themeId);
      expect(after.bindingType, before.bindingType);
      expect(after.createdAt, before.createdAt);
      expect(after.updatedAt, before.updatedAt);
      expect(after.pages, hasLength(2));

      final element = after.pages.first.elements.single;
      final original = before.pages.first.elements.single;
      expect(element.id, original.id);
      expect(element.type, original.type);
      expect(element.content, original.content);
      expect(element.x, original.x);
      expect(element.y, original.y);
      expect(element.width, original.width);
      expect(element.height, original.height);
      expect(element.rotation, original.rotation);
      expect(element.scale, original.scale);
      expect(element.frameStyle, original.frameStyle);
      expect(element.photoShape, original.photoShape);
      expect(element.textColor, original.textColor);
      expect(element.fontSize, original.fontSize);
      expect(element.extraData, original.extraData);

      expect(after.pages[1].elements, isEmpty);
    });

    test('isteğe bağlı alanlar eksikken varsayılana düşer', () {
      final element = AlbumElementModel.fromJson({
        'id': 'e',
        'type': 'text',
        'content': 'merhaba',
        'x': 0,
        'y': 0,
        'width': 1,
        'height': 1,
      });

      expect(element.rotation, 0);
      expect(element.scale, 1);
      expect(element.frameStyle, 0);
      expect(element.photoShape, AlbumPhotoShape.free);
      expect(element.textColor, 0xFF2B2521);
      expect(element.fontSize, 24);
      expect(element.extraData, '');
    });

    test('bilinmeyen fotoğraf biçimi güvenli varsayılana düşer', () {
      final element = AlbumElementModel.fromJson({
        'id': 'e',
        'type': 'photo',
        'content': '/tmp/a.jpg',
        'x': 0,
        'y': 0,
        'width': 1,
        'height': 1,
        'photoShape': 'holografik',
      });

      expect(element.photoShape, AlbumPhotoShape.free);
    });

    test('bilinmeyen cilt tipi spiral olarak okunur', () {
      final json = _album().toJson()..['bindingType'] = 'holografik-cilt';
      expect(AlbumModel.fromJson(json).bindingType, AlbumBindingType.spiral);
    });

    test('cilt tipi hiç yoksa spiral olur', () {
      final json = _album().toJson()..remove('bindingType');
      expect(AlbumModel.fromJson(json).bindingType, AlbumBindingType.spiral);
    });

    test('özel gün kartı proje türü ve teması JSON turundan korunur', () {
      final source = _album()
        ..projectType = AlbumProjectType.occasionCard
        ..cardThemeId = 'anniversary';
      final restored = AlbumModel.fromJson(
        jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>,
      );
      expect(restored.projectType, AlbumProjectType.occasionCard);
      expect(restored.cardThemeId, 'anniversary');
    });

    test('eski kayıtlarda yeni proje alanları güvenli varsayılana düşer', () {
      final json = _album().toJson()
        ..remove('projectType')
        ..remove('cardThemeId');
      final restored = AlbumModel.fromJson(json);
      expect(restored.projectType, AlbumProjectType.album);
      expect(restored.cardThemeId, 'birthday');
    });
  });

  group('bozuk girdi', () {
    test('bilinmeyen öğe tipi hata fırlatır', () {
      expect(
        () => AlbumElementModel.fromJson({
          'id': 'e',
          'type': 'hologram',
          'content': '',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
        }),
        throwsArgumentError,
      );
    });

    test('zorunlu alan eksikse hata fırlatır', () {
      expect(
        () => AlbumPageModel.fromJson({'id': 'p', 'elements': []}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('newId', () {
    test('art arda üretilen kimlikler benzersiz olmalı', () {
      final ids = List.generate(500, (_) => newId());
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason:
            'Aynı senkron blokta üretilen kimlikler çakışırsa aynı Stack '
            'içinde iki özdeş ValueKey oluşur ve Flutter assertion hatası verir.',
      );
    });
  });
}
