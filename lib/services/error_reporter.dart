import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Yakalanmamış hataları tek bir yerde toplar.
///
/// Uygulamada bugün çok az `try`/`catch` var; bu yüzden bir arayüz hatası ya da
/// beklemeye alınmamış bir `Future` sessizce kaybolabiliyor. Buradaki iki kanca
/// bunları görünür kılar:
///
/// * [FlutterError.onError] — çerçeve hataları (build, layout, paint)
/// * [PlatformDispatcher.onError] — yakalanmamış eşzamansız hatalar
///
/// İleride bir çökme raporlama servisi bağlanacaksa değiştirilecek tek yer
/// [report]; çağrı noktalarının hiçbirine dokunmak gerekmez.
abstract final class ErrorReporter {
  /// Rapor akışını gözlemlemek isteyenler için kanca.
  ///
  /// Varsayılan davranış geliştirici günlüğüne yazmaktır; testler bunu geçici
  /// olarak değiştirip raporlanan hataları doğrulayabilir.
  static void Function(Object error, StackTrace? stack, String? context)?
  onReport;

  static bool _installed = false;

  /// Kancaları kurar. Birden çok kez çağrılması güvenlidir.
  static void install() {
    if (_installed) return;
    _installed = true;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Konsoldaki tanıdık kırmızı hata çıktısı korunur; rapor onun yanına
      // eklenir, yerine geçmez.
      previousOnError?.call(details);
      report(
        details.exception,
        details.stack,
        context: details.context?.toString(),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, context: 'PlatformDispatcher');
      // true = "ele alındı". Kullanıcı bir albümü düzenlerken tek bir
      // eşzamansız hata yüzünden uygulamanın kapanması, hatayı kaydedip devam
      // etmekten daha kötü bir sonuç.
      return true;
    };
  }

  /// Test yalıtımı için kancaları söker.
  @visibleForTesting
  static void uninstall() {
    _installed = false;
    onReport = null;
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = null;
  }

  static void report(Object error, StackTrace? stack, {String? context}) {
    final hook = onReport;
    if (hook != null) {
      hook(error, stack, context);
      return;
    }
    developer.log(
      error.toString(),
      name: 'albumium',
      error: error,
      stackTrace: stack,
    );
  }
}
