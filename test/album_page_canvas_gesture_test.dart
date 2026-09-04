import 'dart:math' as math;

import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _testTheme = AlbumThemePreset(
  id: 'gesture_test',
  name: 'Gesture test',
  subtitle: '',
  emoji: '',
  coverStart: Colors.white,
  coverEnd: Colors.white,
  pageColor: Colors.white,
  accent: Colors.black,
  textureLabel: '',
);

AlbumElementModel _element({
  AlbumElementType type = AlbumElementType.sticker,
}) => AlbumElementModel(
  id: 'element',
  type: type,
  content: type == AlbumElementType.photo ? '' : '⭐',
  x: 0.2,
  y: 0.25,
  width: 0.4,
  height: 0.3,
);

Widget _canvas(
  AlbumElementModel element, {
  double ancestorScale = 1,
  bool selected = false,
  VoidCallback? onChanged,
}) {
  final page = AlbumPageModel(
    id: 'page',
    backgroundColor: Colors.white.toARGB32(),
    elements: [element],
  );

  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Transform.scale(
          scale: ancestorScale,
          child: SizedBox(
            width: 300,
            height: 400,
            child: AlbumPageCanvas(
              page: page,
              theme: _testTheme,
              interactive: true,
              selectedId: selected ? element.id : null,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

Offset _center(AlbumElementModel element) => Offset(
  (element.x + element.width / 2) * 300,
  (element.y + element.height / 2) * 400,
);

Offset _rotate(Offset point, double angle) => Offset(
  point.dx * math.cos(angle) - point.dy * math.sin(angle),
  point.dx * math.sin(angle) + point.dy * math.cos(angle),
);

void main() {
  testWidgets('single-finger drag uses page coordinates under a transform', (
    tester,
  ) async {
    final element = _element();
    var changeCount = 0;
    await tester.pumpWidget(
      _canvas(element, ancestorScale: 0.5, onChanged: () => changeCount++),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('⭐')));

    // Cross touch slop first; ScaleGestureRecognizer starts at this position.
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    final xBeforeDrag = element.x;
    final yBeforeDrag = element.y;

    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    expect(changeCount, 0, reason: 'drag updates stay inside one transaction');
    await gesture.up();
    await tester.pump();

    // The page is shown at half size, so 30x20 screen pixels are 60x40
    // logical page pixels.
    expect(element.x, closeTo(xBeforeDrag + 60 / 300, 0.001));
    expect(element.y, closeTo(yBeforeDrag + 40 / 400, 0.001));
    expect(changeCount, 1, reason: 'the completed drag commits once');
  });

  testWidgets('pinch and rotation keep the touched visual point anchored', (
    tester,
  ) async {
    final element = _element();
    await tester.pumpWidget(_canvas(element));

    final pageOrigin = tester.getTopLeft(find.byType(AlbumPageCanvas));
    final focalPoint = pageOrigin + _center(element) + const Offset(30, 20);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(focalPoint - const Offset(20, 0));
    await second.down(focalPoint + const Offset(20, 0));

    // This move starts the scale gesture. Capture the effective anchor after
    // Flutter's touch-slop threshold has been crossed.
    await first.moveTo(focalPoint - const Offset(40, 0));
    await tester.pump();
    final firstFocalOnPage = focalPoint - pageOrigin - const Offset(10, 0);
    final anchorInElement =
        _rotate(firstFocalOnPage - _center(element), -element.rotation) /
        element.scale;

    // Scale and rotate around an off-centre focal point.
    final secondPosition = focalPoint + const Offset(10, 40);
    await second.moveTo(secondPosition);
    await tester.pump();
    final finalFocalOnPage =
        ((focalPoint - const Offset(40, 0)) + secondPosition) / 2 - pageOrigin;
    final expectedCenter =
        finalFocalOnPage -
        _rotate(anchorInElement * element.scale, element.rotation);

    expect((_center(element) - expectedCenter).distance, lessThan(0.001));
    expect(element.scale, greaterThan(1));
    expect(element.rotation.abs(), greaterThan(0.1));

    await first.up();
    await second.up();
  });

  testWidgets(
    'selection chrome exposes corner handles and commits resize once',
    (tester) async {
      final element = _element();
      var changeCount = 0;
      await tester.pumpWidget(
        _canvas(element, selected: true, onChanged: () => changeCount++),
      );

      for (final corner in [
        'topLeft',
        'topRight',
        'bottomRight',
        'bottomLeft',
      ]) {
        expect(
          find.byKey(ValueKey('selection-resize-$corner')),
          findsOneWidget,
        );
      }

      final handle = find.byKey(const ValueKey('selection-resize-bottomRight'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(22, 22));
      await tester.pump();
      await gesture.moveBy(const Offset(30, 30));
      await tester.pump();

      expect(element.scale, greaterThan(1));
      expect(changeCount, 0);

      await gesture.up();
      await tester.pump();
      expect(changeCount, 1);
    },
  );

  testWidgets('rotation handle is visible for every selected element', (
    tester,
  ) async {
    final photo = _element(type: AlbumElementType.photo);
    await tester.pumpWidget(_canvas(photo, selected: true));

    final handle = find.byKey(const ValueKey('selection-rotate'));
    expect(handle, findsOneWidget);
    expect(tester.getSize(handle), const Size.square(48));
    expect(find.bySemanticsLabel('Fotoğrafı döndür'), findsOneWidget);

    for (final type in AlbumElementType.values) {
      await tester.pumpWidget(_canvas(_element(type: type), selected: true));
      expect(handle, findsOneWidget);
      await tester.pumpWidget(_canvas(_element(type: type), selected: false));
      expect(handle, findsNothing);
    }
  });

  for (final type in [
    AlbumElementType.photo,
    AlbumElementType.sticker,
    AlbumElementType.drawing,
  ]) {
    testWidgets(
      '$type rotation handle works under ancestor scale and commits once',
      (tester) async {
        final photo = _element(type: type);
        final originalX = photo.x;
        final originalY = photo.y;
        var changeCount = 0;
        await tester.pumpWidget(
          _canvas(
            photo,
            ancestorScale: 0.5,
            selected: true,
            onChanged: () => changeCount++,
          ),
        );

        final handle = find.byKey(const ValueKey('selection-rotate'));
        final gesture = await tester.startGesture(tester.getCenter(handle));

        // Cross touch slop before changing the angle around the photo centre.
        await gesture.moveBy(const Offset(24, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 42));
        await tester.pump();

        expect(photo.rotation.abs(), greaterThan(0.1));
        expect(photo.rotation.isFinite, isTrue);
        expect(photo.x, originalX);
        expect(photo.y, originalY);
        expect(
          changeCount,
          0,
          reason: 'rotation updates stay in one transaction',
        );

        await gesture.up();
        await tester.pump();
        expect(changeCount, 1, reason: 'the completed rotation commits once');
      },
    );
  }
}
