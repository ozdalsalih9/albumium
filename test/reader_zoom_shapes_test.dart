import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:albumium/widgets/reader_zoom_view.dart';
import 'package:albumium/widgets/sticker_packs.dart';
import 'package:albumium/services/album_package_service.dart';

void main() {
  test(
    'package identity ignores transport timestamps but detects changed content',
    () {
      final a = {
        'id': 'source',
        'updatedAt': 'one',
        'pages': [
          {
            'elements': [
              {'content': 'media/hash.jpg'},
            ],
          },
        ],
      };
      final b = {...a, 'updatedAt': 'two'};
      expect(albumPackageFingerprint(a), albumPackageFingerprint(b));
      expect(
        albumPackageFingerprint({...b, 'title': 'New revision'}),
        isNot(albumPackageFingerprint(a)),
      );
    },
  );
  test(
    'new shapes have unique IDs and hollow shapes leave their centers selectable',
    () {
      expect(albumShapeObjects.length, greaterThan(100));
      expect(albumShapeObjects.toSet().length, albumShapeObjects.length);
      for (final id in albumShapeObjects) {
        expect(
          albumShapePath(id, const Size(100, 100)).getBounds().isEmpty,
          isFalse,
        );
        expect(albumStickerLabel(id), isNot(id));
      }
      expect(
        albumShapePath(
          'albumium_shape:ring_gold',
          const Size(100, 100),
        ).contains(const Offset(50, 50)),
        isFalse,
      );
    },
  );
  testWidgets(
    'zoom buttons magnify and reset; dragging zoomed content does not turn a page',
    (tester) async {
      var drags = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderZoomView(
              child: GestureDetector(
                onHorizontalDragUpdate: (_) => drags++,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Yakınlaştır'));
      await tester.pump();
      final view = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(
        view.transformationController!.value.getMaxScaleOnAxis(),
        closeTo(1.5, .001),
      );
      await tester.dragFrom(const Offset(300, 300), const Offset(50, 0));
      await tester.pump();
      expect(drags, 0);
      await tester.tap(find.byTooltip('Ekrana sığdır'));
      await tester.pump();
      expect(view.transformationController!.value.getMaxScaleOnAxis(), 1);
    },
  );
}
