# Albumium 1.35.1 (66, 67, 68)

20 Ekim 2026 — editör seçim panellerinin yerleşim düzeltmeleri.

## iOS yerel test düzeltmesi — 21 Ekim 2026

- Codemagic `ios-validation` akışındaki `testDisabledAndElapsedToday`, boş
  ayarları kapalı sayan eski beklenti nedeniyle başarısız oluyordu. Güncel
  Flutter, Android ve iOS davranışında eksik `enabled` değeri açık kabul edilir.
- Test üç ayrı duruma ayrıldı: açıkça kapatılan bildirimler planlanmaz; eksik
  ayarlar varsayılan planı üretir; 31 Aralık bildirim saati geçince bir sonraki
  yılın 31 Aralık tarihi seçilir. Sabit tarih ve saat dilimi kullanılır.
- Uygulama kodu ve sürüm numarası değiştirilmedi. Yerel Xcode testleri Windows
  üzerinde çalıştırılamadığından `ios-validation` akışı tekrar çalıştırılmalı.

## Build 67

66 numaralı derleme Play'e yüklenmedi; üretime giden paket 67'dir.

- Uygulama görünümü sayfasındaki Parlaklık seçeneğinde "Sistem" etiketi iki
  satıra kırılıyordu. Üç düğme satırı eşit paylaşıyor ve ikon, en uzun etiketin
  ihtiyaç duyduğu yeri alıyordu: "Sistem" tek satırda 85 dp isterken denenen
  bütün telefon genişliklerinde 58–73 dp alıyordu. İngilizcede "Light" ve
  "System" de kırılıyordu. İkonlar tek sıradan kaldırıldı; dar ekranda ve büyük
  yazıda düğmeler alt alta dizildiği için orada korunuyor.
- Kırılan bir etiket taşma uyarısı veya istisna üretmediğinden regresyon testi,
  çizilen genişlik ile tek satırın gerektireceği genişliği karşılaştırır.
  `test/theme_brightness_labels_test.dart`, 320–600 dp arası altı genişlikte ve
  iki dilde çalışır ve eski kodda başarısız olduğu doğrulandı.
- Doğrulama: `flutter analyze --no-pub` sorunsuz, tam test paketi **486 geçti**.

## Build 68

67 numaralı derleme de Play'e yüklenmedi; üretime giden paket 68'dir.

- `assets/paper_kit` ve `assets/scrapbook` altındaki 78 üretilmiş görsel PNG'den
  WebP'ye çevrildi: **13,36 MB → 2,74 MB (%80 küçülme)**. Projenin geri kalanı
  zaten WebP kullanıyordu. Kalite 95 seçildi; kayıpsız sıkıştırma yalnızca %37
  kazandırıyordu, kalite 90 ise 0,7 MB daha kazandırıp riski artırıyordu.
- Saydamlık riski yok: libwebp alfa kanalını ayrı ve kayıpsız sıkıştırır. 78
  dosyanın 17'sinde alfa kanalı düştü; üçünün de orijinali tamamen opak olduğu
  için kaybolan saydamlık yoktur, git kayıtlarındaki PNG'lerle karşılaştırılarak
  doğrulandı.
- `tool/png_to_webp.py` eklendi. Üretici Dart araçları yalnızca PNG yazabiliyor
  (Flutter'ın `toByteData` metodunda başka biçim yok, `image` paketi WebP'yi
  okuyor ama yazamıyor), bu yüzden üretimden sonra bu betik çalıştırılır. İki
  üretici aracın başına da bu not düşüldü.
- `test/generated_art_format_test.dart`, bu klasörlerde PNG kalmadığını ve her
  desen, kâğıt parçası, şablon önizlemesi ve kolaj parçasının dosyasının
  bulunduğunu doğrular. Çevirmeyi unutan bir yeniden üretim testten geçemez.
- Doğrulama: `flutter analyze --no-pub` sorunsuz, tam test paketi **490 geçti**.

- Sayfa zemini panelindeki desenler ve renkler, aynı sütun genişliklerini ve
  önizleme yüksekliğini kullanır. Satır araları artık farklı genişlikteki Wrap
  elemanlarına göre kaymaz. Büyük yazıda sütun sayısı azalır; etiketler üç satıra
  kadar yer kaplayabilir. Alt seçeneklere kaydırarak ulaşılır.
- Şekil Nesneleri, albüm ve kart editöründe aynı açılış yordamıyla kullanılabilir
  yüksekliğin %96'sına açılır. Sistem güvenli alanı ve klavye hesaba katılır.
  Liste sabit 236/270 piksel yerine kalan alanı kullanır.
- Şekil kartları kendi kırpılan Material yüzeylerine çizilir. Kaydırılan
  kartların arama alanı ve başlığın arkasına çizilmesi giderildi. Etiketler iki
  satıra çıkabilir; yazı büyüdüğünde sütunlar azalır.
- Arama değiştiğinde şekil listesi başa döner; önceki kaydırma konumunun
  sonuçların ilk satırını gizlemesi önlenir.
- Flutter analizindeki blok parantezi uyarıları düzeltildi. Bildirimden albüm
  yükledikten sonra ekranın hâlâ açık olduğu kontrol edilir.

## Kayıt ve bildirim kontrollerinde giderilenler

- Albüm kaydı, Android/iOS bildirim planlamasının yanıtını beklemez. Kaydın
  tamamlanması, paylaşım ekranının açılması, editörden çıkış ve kapak hakkının
  tüketilmesi bu platform çağrısıyla gecikmez. Yavaş bildirim planlayıcısı için
  özel regresyon testi eklendi.
- Bildirim izni reddedildiğinde veya geri alındığında etkin ayar hem cihaz
  tarafında hem uygulama tercihlerinde kapatılır. Varsayılan ayar geçişi bunu
  yeniden açmaz; çağıranın ayar haritası değiştirilmez.
- Albümden yapılan arka plan bildirim yenilemesi kullanıcının bildirim
  tercihini değiştirmez; ilk izin sorusunu atlatmaz. Geciken bir yenileme,
  daha sonra yapılan elle kapatma işlemini geçersiz kılamaz.
- Uygulama açılışı ve dil değişikliği de aynı tercih koruyan yenilemeyi
  kullanır. İlk bildirim izni, ana ekran hazır olduğunda istenir.
- Kaydet ve Çık başarısız olursa çıkış koruması yeniden denemeye izin verir.
- Sistem animasyonları kapalıyken ilk kullanımın İleri/Geri geçişleri doğrudan
  sayfa atlaması kullanır. Sıfır süreli kaydırma animasyonunun ilk kullanımı
  durdurması, Android emülatöründe bulundu ve regresyon testiyle giderildi.
- Anı kartları ve kart stüdyosu testleri, güncel etkileşimli kartları ve Özel
  Kart düğmesini doğrular.

## Doğrulama

- `flutter analyze --no-pub`: sorun yok.
- Son tam Flutter test paketi: **473 geçti, 0 başarısız**.
- Android yerel `MemoryScheduleTest`: **5 geçti, 0 başarısız**.
- Panel testleri 320/393 piksel telefon, yatay ekran, 1×/2× yazı, kaydırma,
  arama, seçim ve zemin renginin uygulanmasını kapsar.
- Son test kaydı: `output/picker-fixes/flutter-test-final.log`.
- Android yerel test kaydı: `output/android-validation/native-tests.log`.
- Görsel çıktılar ve Android çalışma kontrolleri: `output/android-validation/`.
- Android 15 emülatöründe sistem animasyonları kapalı ilk kullanım, albüm
  oluşturma/açma, şekil paneli açılışı/kaydırma/klavyeyle arama/şekil ekleme,
  zemin seçimi, kaydetme ve Android dosya paylaşım penceresi kontrol edildi.
  Paylaşım penceresinden kimseye dosya gönderilmedi.
- Teslim paketiyle aynı son kaynaklardan üretilmiş release APK'de ilk
  bildirim izni sorusu ve izin reddinden sonra ayarın kapalı kalması ayrıca
  doğrulandı. Son çalışma kaydında uygulama istisnası bulunmadı.
- Emülatörün SwiftShader grafik yolunda Windows QEMU süreci iki kez kapandı;
  Windows olay kayıtları `emulator-host-crashes.txt` dosyasındadır. Host grafik
  ayarıyla çalışma kontrolü tamamlandı. Fiziksel Android cihaz bağlı değildi.

Android release derlemesi `--dart-define=ALBUMIUM_LIVE_ADS=true` ile çalıştırılır.
İmzalama mevcut `android/key.properties` ve yükleme anahtarıyla yapılır.

## iOS güncelleme sırası

1. Kaynak değişikliklerini,
   yeni eklenen dosyalar ve varlıklar dahil, Codemagic'in derlediği GitHub
   dalına commit edip gönder. Mevcut çalışma klasöründe henüz commit edilmemiş
   başka geliştirmeler de bulunduğundan sadece tek Dart dosyasını göndermek
   yeterli olmaz. Anahtar ve parolaları kaynak depoya ekleme.
2. Codemagic'te bu dalı seç ve `ios-validation` akışını çalıştır. Flutter
   testleri, iOS simülatör derlemesi ve yerel testler başarılı olmalı.
3. Mevcut `Albumium Codemagic` App Store Connect entegrasyonunu ve
   `com.albumium.albumium` için App Store imzalama profilini kontrol et.
   Güncelleme için yeni bir uygulama kaydı veya bundle kimliği oluşturulmaz.
4. `ios-testflight` akışını çalıştır. Marketing version bu kaynakta 1.35.1'dir;
   `--build-number=$PROJECT_BUILD_NUMBER` Codemagic sayacından gelir. App Store
   Connect'teki mevcut sürüm/build ile çakışmamalı; yayınlanmış sürüm bundan
   büyükse kaynak sürümü artırılmalıdır. Akış IPA'yı TestFlight'a gönderir,
   App Store incelemesine otomatik göndermez.
5. TestFlight'tan iPhone'a yükle. Albüm ve kart editöründe Şekiller'i aç;
   kaydırma, arama, büyük yazı ve klavyeyle seçimi dene. Sayfa zeminlerini
   değiştirip kaydet; uygulamayı yeniden açıp seçimin korunduğunu kontrol et.
6. App Store Connect → Albumium → iOS uygulaması altında 1.35.1 sürümünü
   oluştur. İşlenmiş TestFlight build'ini seç, sürüm notunu ekle ve incelemeye
   gönder. Onaydan sonra tercih ettiğin yayınlama yöntemiyle yayınla.

Bu çalışmada Windows üzerinde iOS derlemesi veya TestFlight yüklemesi yapılmadı.

Kaynaklar:
- https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version
- https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit
- https://docs.codemagic.io/knowledge-codemagic/build-versioning/
- https://docs.codemagic.io/yaml-quick-start/first-signed-build/
