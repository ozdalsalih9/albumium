import 'dart:io';
import 'dart:ui' as ui;
import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('PICKER_REVIEW')) return;
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isNotEmpty) {
    final context = tester.element(find.byType(Image).first);
    await tester.runAsync(() async {
      await Future.wait(
        images.map((image) => precacheImage(image.image, context)),
      );
    });
    await tester.pumpAndSettle();
  }
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('output/picker-fixes').create(recursive: true);
    await File(
      'output/picker-fixes/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final family in ['Roboto', 'AlbumiumSans', 'AlbumiumDisplay']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(320, 780),
    const Size(393, 852),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'shape picker uses available height and clips scrolling cards $size $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          String? result;
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                theme: AlbumiumAppTheme.light(AlbumiumThemeId.rose),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () async =>
                          result = await showShapeObjectPicker(context),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          final body = find.byKey(const ValueKey('shape-picker-body'));
          final grid = find.byKey(const ValueKey('shape-picker-grid'));
          expect(tester.getSize(body).height, greaterThan(size.height * .78));
          final header = tester.getRect(find.text('Şekil Nesneleri'));
          final gridRect = tester.getRect(grid);
          expect(
            gridRect.top,
            greaterThan(tester.getRect(find.byType(TextField)).bottom),
          );
          await tester.drag(grid, const Offset(0, -420));
          await tester.pumpAndSettle();
          expect(tester.getRect(find.text('Şekil Nesneleri')), header);
          expect(tester.takeException(), isNull);
          if (size.width == 393 && scale == 1) {
            await capture(tester, key, 'shapes-scrolled');
          }
          await tester.enterText(find.byType(TextField), 'Lavanta');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final tile = find
              .byWidgetPredicate(
                (w) =>
                    w is Material &&
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'shape-tile-',
                    ),
              )
              .first;
          await tester.tap(tile);
          await tester.pumpAndSettle();
          expect(result, isNotNull);
          expect(find.byType(ShapeObjectPickerSheet), findsNothing);
        },
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'paper patterns and colors share aligned cells at $scale text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(393, 852);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final album = AlbumModel(
          id: 'picker-review',
          title: 'Anılarımız',
          themeId: 'vintage_diary',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          pages: [AlbumPageModel(id: 'page', backgroundColor: 0xFFF2E8D3)],
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: AlbumiumAppTheme.light(AlbumiumThemeId.rose),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: EditorScreen(album: album),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Sayfa'));
        await tester.tap(find.text('Sayfa'));
        await tester.pumpAndSettle();
        final grid = find.byKey(const ValueKey('paper-background-grid'));
        final widget = tester.widget<GridView>(grid);
        final delegate =
            widget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, scale == 1 ? 3 : 2);
        final first = find.byKey(const ValueKey('paper-pattern-linen'));
        final second = find.byKey(const ValueKey('paper-pattern-navydots'));
        expect(
          tester.getSize(first).width,
          closeTo(tester.getSize(second).width, .01),
        );
        await tester.drag(
          find
              .ancestor(of: grid, matching: find.byType(SingleChildScrollView))
              .first,
          const Offset(0, -310),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, key, 'paper-grid-${scale.toInt()}x');
        await tester.ensureVisible(find.text('Bordo'));
        await tester.tap(find.text('Bordo'));
        await tester.pumpAndSettle();
        expect(album.pages.first.backgroundColor, 0xFF4A292F);
        expect(album.pages.first.paperPattern, 'plain');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
