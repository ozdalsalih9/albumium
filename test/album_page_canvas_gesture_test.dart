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

AlbumElementModel _element() => AlbumElementModel(
  id: 'element',
  type: AlbumElementType.sticker,
  content: '⭐',
  x: 0.2,
  y: 0.25,
  width: 0.4,
  height: 0.3,
);

Widget _canvas(AlbumElementModel element, {double ancestorScale = 1}) {
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
    await tester.pumpWidget(_canvas(element, ancestorScale: 0.5));

    final gesture = await tester.startGesture(tester.getCenter(find.text('⭐')));

    // Cross touch slop first; ScaleGestureRecognizer starts at this position.
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    final xBeforeDrag = element.x;
    final yBeforeDrag = element.y;

    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.up();

    // The page is shown at half size, so 30x20 screen pixels are 60x40
    // logical page pixels.
    expect(element.x, closeTo(xBeforeDrag + 60 / 300, 0.001));
    expect(element.y, closeTo(yBeforeDrag + 40 / 400, 0.001));
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
}
