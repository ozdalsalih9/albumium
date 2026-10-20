import 'package:albumium/services/album_backup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(AlbumBackupService.channel, null),
  );

  test('save passes package path and reports provider completion', () async {
    messenger.setMockMethodCallHandler(AlbumBackupService.channel, (
      call,
    ) async {
      expect(call.method, 'save');
      expect(call.arguments, {'path': '/cache/memories.albumium'});
      return true;
    });
    expect(await AlbumBackupService.save('/cache/memories.albumium'), isTrue);
  });

  test(
    'cancellation is not reported as a successful backup or import',
    () async {
      messenger.setMockMethodCallHandler(
        AlbumBackupService.channel,
        (_) async => null,
      );
      expect(await AlbumBackupService.save('/cache/test.albumium'), isFalse);
      expect(await AlbumBackupService.pick(), isNull);
    },
  );

  test('provider errors reach the UI and can be retried', () async {
    messenger.setMockMethodCallHandler(
      AlbumBackupService.channel,
      (_) async => throw PlatformException(code: 'document_failed'),
    );
    await expectLater(
      AlbumBackupService.save('/cache/test.albumium'),
      throwsA(isA<PlatformException>()),
    );
    messenger.setMockMethodCallHandler(
      AlbumBackupService.channel,
      (_) async => '/cache/restored.albumium',
    );
    expect(await AlbumBackupService.pick(), '/cache/restored.albumium');
  });
}
