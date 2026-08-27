import 'package:albumium/services/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ErrorReporter.uninstall);

  test('install çerçeve ve platform kancalarını kurar', () {
    final before = PlatformDispatcher.instance.onError;
    ErrorReporter.install();

    expect(FlutterError.onError, isNot(FlutterError.presentError));
    expect(PlatformDispatcher.instance.onError, isNot(before));
  });

  test('install birden çok kez çağrılabilir', () {
    ErrorReporter.install();
    final first = PlatformDispatcher.instance.onError;
    ErrorReporter.install();

    expect(PlatformDispatcher.instance.onError, same(first));
  });

  test('çerçeve hatası rapora düşer ve önceki kanca da çağrılır', () {
    // install'dan ÖNCE bir kaydedici koy: zincirlemenin gerçekten olduğunu
    // doğrular ve presentError'ın konsola yazmasını da önler.
    final passedThrough = <FlutterErrorDetails>[];
    FlutterError.onError = passedThrough.add;

    ErrorReporter.install();
    Object? seen;
    String? seenContext;
    ErrorReporter.onReport = (error, stack, context) {
      seen = error;
      seenContext = context;
    };

    final error = StateError('bozuk düzen');
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: error,
        context: ErrorDescription('bir sayfa çizilirken'),
      ),
    );

    expect(seen, same(error));
    expect(seenContext, contains('bir sayfa çizilirken'));
    // Önceki kanca es geçilmedi.
    expect(passedThrough.single.exception, same(error));
  });

  test('yakalanmamış eşzamansız hata uygulamayı düşürmez, raporlanır', () {
    ErrorReporter.install();
    final reported = <Object>[];
    ErrorReporter.onReport = (error, stack, context) => reported.add(error);

    final error = Exception('albüm kaydedilemedi');
    final handled = PlatformDispatcher.instance.onError!(
      error,
      StackTrace.current,
    );

    // true = "ele alındı"; tek bir eşzamansız hata oturumu sonlandırmamalı.
    expect(handled, isTrue);
    expect(reported, [same(error)]);
  });

  test('kanca yokken report sessizce günlüğe yazar', () {
    ErrorReporter.onReport = null;
    expect(
      () => ErrorReporter.report(Exception('x'), StackTrace.current),
      returnsNormally,
    );
  });
}
