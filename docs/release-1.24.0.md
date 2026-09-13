# Albumium 1.24.0+38

## Kullanım

Albüm önizlemesinde paylaşım menüsünü aç:

- **Video şablonları:** Yaz Anıları / Birlikte / Yıl Özeti; 15 veya 30 saniye. Albüm sayfalarını veya tek tek fotoğrafları seç ve sırala. Albüm kapağı veya seçilen içerikten bir kareyi kapak yap; kapanış notunu ekle. Dikey video 1080×1920 veya 720×1280 olarak, isteğe bağlı müzikle hazırlanır. En fazla 20 öğe seçilir; daha fazlasında içerik sessizce atılmaz, seçim istenir. Önizleme görseldir; ses MP4 oluşturulurken eklenir.
- **Görseller:** Mevcut görünümü veya bütün albümü PNG paylaş.
- **Etkileşimli albüm:** Mevcut `.albumium` formatını paylaş. Alıcıda Albumium gerekir; hesap/bulut/tarayıcı görüntüleyici eklenmedi.
- **Hediye albümü oluştur:** Alıcı adı ve kişisel mesajla ayrı bir albüm kopyası kaydet. Asıl albüm değişmez. Mevcut metin/sayfa öğeleri kullanılır; paket sürümü değişmez.

Küçük telefonlardaki araç ve tema etiketleri metne göre büyür; yatay kaydırma ve erişilebilirlik yazı ölçeği korunur. Kısa yatay ekranlarda kontrol panelleri kaydırılabilir.

## Teslimler

- `dist/Albumium-1.23.2.apk`: yalnız dar ekran düzeltmesi için önce hazırlanan Android güncellemesi.
- `dist/Albumium-1.24.0.apk`: yeni paylaşım özelliklerini de içeren imzalı Android APK.
- `ios/`: iOS 17+ kaynak projesi; yerel bildirim, Vision kesimi, dosya açma ve paylaşım uyarlamaları.
- `codemagic.yaml`: iOS simülatör doğrulaması ve ayrı imzalı TestFlight iş akışı.

## Doğrulama

Flutter analiz, test ve Android derleme raporları sırasıyla `build/analyze-1.24.0.txt`, `build/test-results-1.24.0.txt`, `build/apk-1.24.0.txt` dosyalarındadır.

Son doğrulama: **243 test geçti**, statik analizde sorun bulunmadı; imzalı Android derlemesi başarılı.

Ekran matrisi: 320/360/384/390/412 mantıksal piksel, 1/1.3/1.6/2 metin ölçeği, Türkçe/İngilizce, açık/koyu tema. Kart stüdyosu, albüm editörü ve seçili nesne paneli kontrol edildi. 640×320 ve 960×600 kart stüdyosu yatay kontrolleri de test edildi. Bu sonuçlar widget testleridir, gerçek telefon testi değildir.

Video zamanlama testleri 1/3/7/20 öğe ile tam 15/30 saniyeyi, müzik uzunluğunu, sayfa/fotoğraf sırasını ve asıl albümün korunmasını doğrular. Hediye albümü testleri bağımsız kimlikleri ve çift paket turunda kapak/fotoğraf/metin/sticker/sıra korunmasını kontrol eder. Bildirim kanal testleri ret, sonradan kapatılan iOS izni ve soğuk açılış tarihini doğrular.

## Yayın öncesinde kalanlar

**Bu sürüm iOS'ta henüz derlenmedi ve App Store'a gönderilmedi.** Windows ortamında Xcode, iPhone/iPad veya A21s erişimi bulunmadığından fiziksel cihaz, yerel Vision ve donanımsal video/ses testleri yapılmadı. Codemagic/Apple imzalama bağlantıları henüz sağlanmadı.

`ios-release.md` içindeki cihaz ve gizlilik kontrol listesi ile `app-store-copy.md` metin taslakları yayın hazırlığı içindir. Destek URL'si, mağaza ekran görüntüleri, App Store gizlilik formu, SDK manifest doğrulaması ve TestFlight kabulü tamamlanmalı. App Store gönderimi ayrı adımdır.

## Sonraki ürün paketi adayları

Genel geri al/ileri al, toplu yedekleme ve otomatik sayfa yerleşimi bu sürüme dahil edilmedi; sonraki paket için aday olarak tutuluyor.
