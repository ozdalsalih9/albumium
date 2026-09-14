# Albumium iOS 17+ yayın hazırlığı

Bu depo artık iPhone/iPad projesi ve yerel platform uygulamalarını içeriyor. **iOS simülatör derlemesi ve 4 yerel XCTest, Codemagic macOS üzerinde geçti.** İmzalama ve gerçek cihaz doğrulaması henüz yapılmadı; simülatör sonucu fiziksel cihaz testinin yerine geçmez.

## Eklenenler

- iOS 17.0 hedefi, `com.albumium.albumium` bundle kimliği, simgeler ve açılış ekranı.
- Türkçe/İngilizce fotoğraf izin açıklamaları; iPhone ve iPad yönleri.
- UserNotifications ile yerel hatırlatmalar, izin reddi ve sonradan iptal edilen iznin kontrolü. Yaklaşan en fazla 60 tarih planlanır; çakışan dönemler tek bildirimde birleşir. Açılış, ön plana dönüş ve önemli saat/saat dilimi değişimlerinde yenilenir. Uygulama çok uzun süre açılmazsa sınırlı planlama ufkunun ötesinde bildirim üretilmez.
- Vision ile cihazda otomatik nesne kesimi; sonuç bulunamadığında mevcut manuel silme/geri getirme arayüzü. Şeffaf PNG ve beyaz kontur Dart tarafında korunur.
- Files/“Birlikte Aç” üzerinden `.albumium` dosyaları; soğuk ve açık uygulama için kuyruk. Security-scoped erişim, koordineli okuma, 160 MiB sınırı; Dart tarafındaki paket doğrulaması aynen kullanılır. Yalnız uygulamanın kendi eski geçici kopyaları temizlenir.
- iPad paylaşım penceresi konumu ve tarayıcıda gizlilik bağlantısı.
- Mevcut MP4 kodlayıcısı korunur. Yeni stüdyo 15/30 saniye, sayfa veya fotoğraf sırası, üç görsel kurgu, kapanış notu, müzik ve 1080p/720p seçimi sunar. Yakalanabilen dışa aktarım hatalarında aynı taslakla 720p tekrar denenebilir; işletim sisteminin uygulamayı bellek nedeniyle sonlandırması yakalanamaz.

## Codemagic

1. Bu depoyu Codemagic'e bağla ve kökteki `codemagic.yaml` dosyasını kullan.
2. Önce **ios-validation** çalıştır: Flutter 3.41.7, analiz, Flutter testleri, simülatör derlemesi ve `RunnerTests` takvim testleri. Çıktıyı ve Xcode hatalarını incele. Swift kodunun ilk başarılı derlemesi aşağıda kayıtlıdır.
3. Apple Developer üyeliğini ve App Store Connect'te `com.albumium.albumium` uygulama kaydını hazırla.
4. Codemagic takım ayarlarına **Albumium App Store Connect** adlı API entegrasyonunu ve bu kimliğe ait App Store imzalama sertifikası/profilini ekle. API özel anahtarı, sertifika ve parolalar depoya yazılmaz.
5. **ios-testflight** iş akışını çalıştır. Bu akış imzalı IPA oluşturur ve TestFlight'a gönderir; App Store incelemesine otomatik gönderim kapalıdır. Build numarası Codemagic proje sayacıdır; mevcut App Store kaydındaki numaralardan büyük olması sağlanmalıdır.
6. TestFlight cihaz kontrolleri ve mağaza hazırlığı tamamlandıktan sonra App Store gönderimini ayrı yap.

14 Eylül 2026: `codex/ios-validation` dalı Codemagic'e bağlandı. `ae5ef5d` değişikliğiyle Vision parametre etiketi düzeltildi; analiz, Flutter testleri, iOS simülatör derlemesi, ZIP paketleme ve 4 yerel XCTest başarılı. Test hedefi iPhone 17 Pro simülatörüydü; bu sonuç iOS 17 işletim sisteminde ayrıca test yapıldığı anlamına gelmez. [Başarılı derleme ve çıktılar](https://codemagic.io/app/6aa70313643642a209710ba7/build/6aa7c27ece14455b631ad9dd). Apple hesap/imzalama bilgileri henüz sağlanmış değil.

## Gerçek cihaz kabul listesi — henüz bekliyor

| Kontrol | Samsung A21s | Küçük iPhone, iOS 17+ | iPad |
|---|---|---|---|
| 1×–2× yazı, dikey/yatay, erişilebilir araçlar | Bekliyor | Bekliyor | Bekliyor |
| Fotoğraf seçimi, sınırlı/ret izinleri | Bekliyor | Bekliyor | Bekliyor |
| Nesne kesimi, nesne yok, sil/geri getir, beyaz kontur | Bekliyor | Bekliyor | Bekliyor |
| PNG, MP4, etkileşimli paylaşım | Bekliyor | Bekliyor | Bekliyor |
| 1080p/720p ses-görüntü, iptal, bellek | Bekliyor | Bekliyor | Bekliyor |
| Bildirim izni, dokunarak dönem açma, saat dilimi | Bekliyor | Bekliyor | Bekliyor |
| Files'dan kapalı/açık uygulamaya dosya açma | — | Bekliyor | Bekliyor |

Android → iOS → Android aktarımını fotoğraf, kırpma, yazı, kişisel sticker, kapak ve sayfa sırasını karşılaştırarak yap. Yerel çift paket turu testi mevcut; bu, gerçek cihazlar arası aktarımın yapıldığı anlamına gelmez. Bozuk/arşiv sınırını aşan dosyaları da dene.

## Gizlilik ve mağaza

- `PrivacyInfo.xcprivacy` uygulamanın UserDefaults ve kendi dosyalarının tarih bilgisi kullanımını beyan eder. Kaynak kodda hesap, reklam takibi veya sunucuya albüm yükleme eklenmedi.
- macOS arşivinde Flutter ve tüm eklentilerin privacy manifestlerini, App Store gizlilik raporunu ve üçüncü taraf SDK bildirimlerini ayrıca kontrol et. App Store “App Privacy” formu final arşive göre doldurulmalı; dosyanın bulunması tek başına mağaza uygunluğu kanıtı değildir.
- Mevcut gizlilik bağlantısının iOS özelliklerini de kapsadığını doğrula: https://sites.google.com/view/albumium-privacy/ana-sayfa
- Kamuya açık destek URL'si, telif/iletişim bilgileri, yaş derecelendirmesi, ihracat beyanı ve iPhone/iPad ekran görüntüleri mağaza kaydında tamamlanmalı. Destek adresi sağlanmadığı için uydurulmadı.
- Mağaza metin taslakları `app-store-copy.md` dosyasında. Gerçek iOS ekran görüntüleri TestFlight/simülatör doğrulamasından sonra alınmalı.

## Kaynaklar

- [Codemagic Flutter derleme rehberi](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [Mevcut video kodlayıcısı](https://pub.dev/packages/flutter_quick_video_encoder)
- [Apple yerel bildirim planlama](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [Apple Vision nesne maskesi](https://developer.apple.com/documentation/vision/vngenerateforegroundinstancemaskrequest)
