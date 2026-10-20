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

Albüm verisi cihazda otomatik saklanır. Kullanıcı, düzenlenebilir `.albumium` yedeğini Android sistem dosya seçicisinden Google Drive’a veya iOS Dosyalar üzerinden iCloud Drive’a kaydedebilir; koleksiyondaki “Yedekten geri yükle” ile tekrar açabilir. Bulut aktarımını seçilen dosya sağlayıcısı yönetir. Otomatik bulut senkronizasyonu, tarayıcıda albüm görüntüleme ve özel paylaşım bağlantıları bu akışa dahil değildir.

Yeni kâğıt desenleri, 30 parçalık çizim koleksiyonu ve yedekleme ayrıntıları: [Kâğıt atölyesi ve yedekler](docs/paper-atelier-and-backups.md).
