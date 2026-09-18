import 'package:albumium/widgets/export_delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _gal = MethodChannel('gal');

/// Records gallery calls and answers access checks with [access].
List<MethodCall> _mockGallery({required bool access}) {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_gal, (call) async {
        calls.add(call);
        return switch (call.method) {
          'hasAccess' || 'requestAccess' => access,
          _ => null,
        };
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_gal, null),
  );
  return calls;
}

/// Pumps a button that runs [action] with a context under a Scaffold.
Future<void> _run(
  WidgetTester tester,
  Future<void> Function(BuildContext context) action,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => action(context),
            child: const Text('run'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('run'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('finished export offers saving to the gallery or sharing', (
    tester,
  ) async {
    ExportDelivery? choice;
    await _run(tester, (context) async {
      choice = await showExportDeliverySheet(context, video: true);
    });

    expect(find.text('Video hazır'), findsOneWidget);
    expect(find.byKey(const ValueKey('export-share')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('export-save-gallery')));
    await tester.pumpAndSettle();
    expect(choice, ExportDelivery.saveToGallery);
  });

  testWidgets('a saved video lands in the gallery and can still be shared', (
    tester,
  ) async {
    final calls = _mockGallery(access: true);
    var shared = false;
    await _run(
      tester,
      (context) => saveExportsToGallery(
        context,
        ['/tmp/album.mp4'],
        video: true,
        onShare: () => shared = true,
      ),
    );

    final saves = calls.where((call) => call.method == 'putVideo').toList();
    expect(saves, hasLength(1));
    expect((saves.single.arguments as Map)['path'], '/tmp/album.mp4');
    expect(find.text('Video galeriye kaydedildi.'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Paylaş'));
    expect(shared, isTrue);
  });

  testWidgets('the saved confirmation goes away on its own', (tester) async {
    _mockGallery(access: true);
    await _run(
      tester,
      (context) => saveExportsToGallery(
        context,
        ['/tmp/album.mp4'],
        video: true,
        onShare: () {},
      ),
    );
    expect(find.text('Video galeriye kaydedildi.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Video galeriye kaydedildi.'), findsNothing);
  });

  testWidgets('every exported page is saved as its own image', (tester) async {
    final calls = _mockGallery(access: true);
    await _run(
      tester,
      (context) => saveExportsToGallery(context, [
        '/tmp/page_01.png',
        '/tmp/page_02.png',
      ], video: false),
    );

    expect(calls.where((call) => call.method == 'putImage'), hasLength(2));
    expect(find.text('2 görsel galeriye kaydedildi.'), findsOneWidget);
  });

  testWidgets('declining gallery access saves nothing and says why', (
    tester,
  ) async {
    final calls = _mockGallery(access: false);
    await _run(
      tester,
      (context) =>
          saveExportsToGallery(context, ['/tmp/album.mp4'], video: true),
    );

    expect(calls.map((call) => call.method), ['hasAccess', 'requestAccess']);
    expect(
      find.text('Galeriye kaydetmek için izin vermen gerekiyor.'),
      findsOneWidget,
    );
  });
}
