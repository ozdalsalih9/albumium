# Albumium MVP

Albumium, fotoğrafları oyun hissi veren etkileşimli dijital albümlere dönüştüren Android uygulamasının ilk çalışan sürümüdür.

## MVP özellikleri

- Altı hazır kapak ve sayfa teması
- Albüm kitaplığı ve cihazda otomatik kayıt
- Android fotoğraf seçiciyle çoklu fotoğraf alma
- Fotoğrafları taşıma, ölçekleme ve döndürme
- Dört fotoğraf çerçevesi
- Metin, emoji sticker ve sayfa rengi araçları
- Sayfa ekleme, çoğaltma ve silme
- Animasyonlu kitap önizleme ve otomatik oynatma
- Donanım H.264 kodlayıcısıyla MP4 oluşturma ve Android paylaşım menüsü

## Geliştirme

```sh
flutter pub get
flutter test
flutter run
```

Release APK üretmek için:

```sh
flutter build apk --release
```

## Kapsam notu

Bu sürüm offline-first çalışır. Uygulama yüklemeden tarayıcıda albüm görüntüleme, kullanıcı hesabı, bulut senkronizasyonu ve özel paylaşım bağlantıları backend/web görüntüleyici fazına ayrılmıştır.
