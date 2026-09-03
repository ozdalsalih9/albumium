import 'dart:io';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/album_import_screen.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/services/album_package_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumModel _sharedAlbum() {
  final now = DateTime(2026, 9, 4);
  return AlbumModel(
    id: 'incoming',
    title: 'Aile Albümü',
    themeId: 'soft_romance',
    createdAt: now,
    updatedAt: now,
    pages: [AlbumPageModel(id: 'page', backgroundColor: 0xFFF2E8D3)],
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Widget was not found before the bounded pump timeout.');
}

Future<
  ({
    Directory root,
    AlbumPackageService service,
    AlbumPackageExport exported,
    AlbumPackagePreview preview,
  })
>
_createFixture(String prefix) async {
  final root = await Directory.systemTemp.createTemp(prefix);
  final temporary = Directory('${root.path}${Platform.pathSeparator}temporary');
  final documents = Directory('${root.path}${Platform.pathSeparator}documents');
  await temporary.create(recursive: true);
  await documents.create(recursive: true);
  final service = AlbumPackageService(
    temporaryDirectoryProvider: () async => temporary,
    documentsDirectoryProvider: () async => documents,
  );
  final exported = await service.createPackage(_sharedAlbum());
  final preview = await service.openPackage(exported.file.path);
  return (root: root, service: service, exported: exported, preview: preview);
}

void main() {
  for (final size in const [Size(390, 844), Size(960, 600)]) {
    testWidgets('shared album preview fits ${size.width}x${size.height}', (
      tester,
    ) async {
      final fixture = (await tester.runAsync(
        () => _createFixture('albumium_import_screen_'),
      ))!;
      final root = fixture.root;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AlbumImportScreen(
            packagePath: fixture.exported.file.path,
            packageService: fixture.service,
            initialPreview: fixture.preview,
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text('Aile Albümü'));

      expect(find.text('Paylaşılan Albüm'), findsOneWidget);
      expect(find.text('Aile Albümü'), findsWidgets);
      expect(find.byKey(const ValueKey('view_shared_album')), findsOneWidget);
      expect(find.byKey(const ValueKey('import_shared_album')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('view-only action opens the album preview', (tester) async {
    final fixture = (await tester.runAsync(
      () => _createFixture('albumium_import_view_'),
    ))!;
    final root = fixture.root;
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumImportScreen(
          packagePath: fixture.exported.file.path,
          packageService: fixture.service,
          initialPreview: fixture.preview,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Aile Albümü'));
    await tester.tap(find.byKey(const ValueKey('view_shared_album')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(PreviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
