import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:albumium/widgets/handmade_craft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('studio surface supports all themes on phones and tablets', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const <Size>[Size(390, 844), Size(1024, 768)]) {
      tester.view.physicalSize = size;
      for (final themeId in AlbumiumThemeId.values) {
        for (final theme in <ThemeData>[
          AlbumiumAppTheme.light(themeId),
          AlbumiumAppTheme.dark(themeId),
        ]) {
          await tester.pumpWidget(
            _host(
              theme: theme,
              child: const Center(child: Text('Albumium')),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(CraftBackdrop)), size);
          expect(find.text('Albumium'), findsOneWidget);
          final paint = _backgroundPaint(tester);
          expect(paint.isComplex, isFalse);
          expect(paint.willChange, isFalse);
          final paintElement = tester.element(_backgroundFinder());
          expect(
            paintElement.findAncestorWidgetOfExactType<RepaintBoundary>(),
            isNotNull,
          );
        }
      }
    }
  });

  testWidgets('child-only updates do not invalidate the studio painter', (
    tester,
  ) async {
    final theme = AlbumiumAppTheme.light(AlbumiumThemeId.amber);
    await tester.pumpWidget(
      _host(theme: theme, child: const Text('First page')),
    );
    final firstPainter = _backgroundPaint(tester).painter!;

    await tester.pumpWidget(
      _host(theme: theme, child: const Text('Next page')),
    );
    final nextPainter = _backgroundPaint(tester).painter!;
    expect(nextPainter.shouldRepaint(firstPainter), isFalse);

    await tester.pumpWidget(
      _host(
        theme: AlbumiumAppTheme.dark(AlbumiumThemeId.amber),
        child: const Text('Next page'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _backgroundPaint(tester).painter!.shouldRepaint(nextPainter),
      isTrue,
    );
  });

  testWidgets('paper stays the default for existing craft content', (
    tester,
  ) async {
    expect(const CraftBackdrop().variant, CraftBackdropVariant.paper);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CraftBackdrop(
            child: Center(
              child: PaperPanel(child: const Text('Original paper')),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Original paper'), findsOneWidget);
    expect(_backgroundPaint(tester).isComplex, isTrue);
  });

  testWidgets('fabric surface repeats the supplied texture and follows theme', (
    tester,
  ) async {
    const textureKey = ValueKey('fabric-texture-image');
    Color? previousColor;
    for (final theme in <ThemeData>[
      AlbumiumAppTheme.light(AlbumiumThemeId.rose),
      AlbumiumAppTheme.dark(AlbumiumThemeId.navy),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              final colors = AlbumiumAppTheme.colorsOf(context);
              return CraftBackdrop(
                variant: CraftBackdropVariant.velvet,
                baseColor: colors.background,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.widget<DecoratedBox>(find.byKey(textureKey));
      final decoration = box.decoration as BoxDecoration;
      final image = decoration.image!;
      expect(
        (image.image as AssetImage).assetName,
        'assets/textures/home-fabric.png',
      );
      expect(image.repeat, ImageRepeat.repeat);
      expect(image.scale, 2);
      expect(image.colorFilter, isNotNull);
      expect(decoration.color, isNot(previousColor));
      previousColor = decoration.color;
      expect(
        tester
            .element(find.byKey(textureKey))
            .findAncestorWidgetOfExactType<RepaintBoundary>(),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _host({required ThemeData theme, required Widget child}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: CraftBackdrop(variant: CraftBackdropVariant.studio, child: child),
    ),
  );
}

Finder _backgroundFinder() => find
    .descendant(
      of: find.byType(CraftBackdrop),
      matching: find.byType(CustomPaint),
    )
    .first;

CustomPaint _backgroundPaint(WidgetTester tester) =>
    tester.widget<CustomPaint>(_backgroundFinder());
