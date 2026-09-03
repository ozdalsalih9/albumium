# Remotion MP4 export değerlendirmesi

Tarih: 1 Eylül 2026

## Karar

Remotion, Albumium'un Android APK'sına doğrudan gömülü bir MP4 renderer olarak
eklenmemelidir. Albumium Flutter ile yazılmış, cihaz içinde çalışan ve Android
manifestinde internet izni bulunmayan offline-first bir uygulamadır. Remotion'ın
üretim renderer'ı ise React kompozisyonlarını Node.js/Bun üzerinde Chromium ve
FFmpeg kullanarak işler.

Bu nedenle mevcut cihaz içi Flutter -> RGBA kare -> Android MediaCodec H.264
hattı korunur. Remotion'dan alınan deterministik storyboard, kare bazlı zamanlama,
ilerleme/iptal ve gerçek geçiş ilkeleri native hatta uygulanır.

## Neden APK içine Remotion eklenmedi?

- Remotion'ın sunucu renderer'ı Node.js/Bun API'sidir; bir Flutter/Dart veya
  Android-native renderer sağlamaz.
- Remotion ekibi React Native desteğini, her karede React render etmenin mobil
  native performansına ulaşamaması ve gereken mimari değişiklik nedeniyle
  planlamadığını belirtir. Flutter için de resmî runtime veya Player yoktur.
- `@remotion/web-renderer` modern tarayıcı ve WebCodecs içindir. Tek concurrency,
  sınırlı CSS/medya desteği, bellek/ısı baskısı ve WebView-Dart dosya köprüsü
  nedeniyle Android WebView içinde güvenilir bir offline export motoru değildir.
- Bir Node/Lambda servisi eklemek fotoğrafları cihaz dışına taşır; kimlik
  doğrulama, açık kullanıcı onayı, iş kuyruğu, depolama, silme politikası,
  progress/cancel ve yeni gizlilik yükümlülükleri gerektirir.
- Remotion özel lisans kullanır. Bireyler ve üç çalışana kadar şirketler ücretsiz
  kapsama girebilir; daha büyük ticari kuruluşların şirket lisansını doğrulaması
  gerekir.

## İleride çevrimiçi “Pro kalite” istenirse

Bu özellik ayrı ve açıkça çevrimiçi bir seçenek olarak tasarlanmalıdır:

1. Flutter, albüm manifestini ve kanonik 1080 x 1920 sahne görsellerini üretir.
2. Kullanıcı fotoğrafların işlenmek üzere yükleneceğini açıkça onaylar.
3. Bir API işi kuyruğa alır; önceden bundle edilmiş Remotion kompozisyonu bu
   manifesti input props olarak alır.
4. Node/Bun worker `selectComposition()` ve `renderMedia()` ile H.264/AAC MP4
   üretir. Bundle video başına yeniden oluşturulmaz.
5. Uygulama progress/cancel durumunu izler, sonucu indirir; kaynaklar ve çıktı
   tanımlı saklama süresi sonunda silinir.
6. Mevcut MediaCodec export'u her zaman offline fallback olarak kalır.

## Resmî kaynaklar

- Remotion repository: https://github.com/remotion-dev/remotion
- Server-side rendering: https://www.remotion.dev/docs/ssr
- Node.js/Bun rendering: https://www.remotion.dev/docs/ssr-node
- Client-side rendering: https://www.remotion.dev/docs/client-side-rendering/
- Client renderer sınırlamaları: https://www.remotion.dev/docs/client-side-rendering/limitations
- React Native değerlendirmesi: https://www.remotion.dev/docs/react-native
- Renderer seçenekleri karşılaştırması: https://www.remotion.dev/docs/compare-ssr
- Lisans: https://github.com/remotion-dev/remotion/blob/main/LICENSE.md
