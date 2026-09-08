import 'dart:io';
import 'dart:ui' as ui;
import 'package:albumium/models/memory_period.dart';
import 'package:albumium/widgets/memory_prompt_cards.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/personal_stickers_screen.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('AlbumiumSans')
          ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [320.0, 760.0]) {
    testWidgets('memory cards fit width $width and open the chosen period', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      MemoryKind? selected;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'AlbumiumSans'),
          home: Scaffold(
            backgroundColor: const Color(0xFF242126),
            body: RepaintBoundary(
              key: key,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MemoryPromptCards(onSelect: (kind) => selected = kind),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('memory-card-year')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('memory-card-year')));
      expect(selected, MemoryKind.year);
      if (width == 760) {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/review').create(recursive: true);
          await File(
            'build/review/memory-cards.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
  testWidgets('personal stickers are a toolbar action next to handwriting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final album = AlbumModel(
      id: 'test',
      title: 'Test',
      themeId: 'minimal_editorial',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: [AlbumPageModel(id: 'page', backgroundColor: 0xFFFFFFFF)],
    );
    await tester.pumpWidget(MaterialApp(home: EditorScreen(album: album)));
    await tester.pumpAndSettle();
    expect(find.text('Elle Yaz'), findsOneWidget);
    expect(find.text('Sticker'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Sticker')).dx,
      greaterThan(tester.getCenter(find.text('Elle Yaz')).dx),
    );
    await tester.tap(find.text('Sticker'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalStickersScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('decorations picker no longer includes personal sticker entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StickerPackPickerSheet())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stickerlarım'), findsNothing);
  });
}
