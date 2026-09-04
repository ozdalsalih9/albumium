import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _theme = AlbumThemePreset(
  id: 'performance-test',
  name: 'Test',
  subtitle: '',
  emoji: '',
  coverStart: Colors.white,
  coverEnd: Colors.white,
  pageColor: Colors.white,
  accent: Colors.black,
  textureLabel: '',
);

class _PaintCounter extends CustomPainter {
  _PaintCounter(this.delegate);

  final CustomPainter delegate;
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    delegate.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Widget _canvas(AlbumPageModel page, {required bool interactive}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 300,
      height: 400,
      child: AlbumPageCanvas(
        page: page,
        theme: _theme,
        interactive: interactive,
        showPageNumber: false,
      ),
    ),
  ),
);

void main() {
  testWidgets('dragging an element reuses the static page artwork', (
    tester,
  ) async {
    final element = AlbumElementModel(
      id: 'sticker',
      type: AlbumElementType.sticker,
      content: '⭐',
      x: .2,
      y: .25,
      width: .4,
      height: .3,
    );
    final page = AlbumPageModel(
      id: 'page',
      backgroundColor: 0xFFFFFFFF,
      elements: [element],
    );
    await tester.pumpWidget(_canvas(page, interactive: true));
    final background = find.byKey(const ValueKey('album-page-art-page'));
    final paper = tester.renderObject<RenderCustomPaint>(
      find.descendant(of: background, matching: find.byType(CustomPaint)).first,
    );
    final counter = _PaintCounter(paper.painter!);
    paper.painter = counter;
    await tester.pump();
    expect(counter.paints, 1);

    final startX = element.x;
    final gesture = await tester.startGesture(tester.getCenter(find.text('⭐')));
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(element.x, greaterThan(startX));
    expect(counter.paints, 1, reason: 'paper texture is not redrawn on drag');
    expect(
      find.byKey(const ValueKey('album-element-art-sticker')),
      findsOneWidget,
    );

    await tester.pumpWidget(_canvas(page, interactive: false));
    expect(find.text('⭐'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('album-element-art-sticker')),
      findsNothing,
      reason: 'read-only/export pages do not allocate a layer per element',
    );
    expect(tester.takeException(), isNull);
  });
}
