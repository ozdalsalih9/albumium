import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:albumium/models/album_models.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/element_edit_panel.dart';

AlbumElementModel shape(
  String id,
  String content,
  double x,
  double y,
  double width,
  double height, {
  double scale = 1,
}) => AlbumElementModel(
  id: id,
  type: AlbumElementType.sticker,
  content: content,
  x: x,
  y: y,
  width: width,
  height: height,
  scale: scale,
);
void main() {
  for (final type in AlbumElementType.values) {
    testWidgets('layer actions and rotation are available for ${type.name}', (
      tester,
    ) async {
      final e = AlbumElementModel(
        id: 'selected',
        type: type,
        content: '',
        x: .2,
        y: .2,
        width: .2,
        height: .2,
      );
      AlbumElementLayerAction? action;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElementEditPanel(
              element: e,
              onChanged: () {},
              onClose: () {},
              onStyle: () {},
              onCrop: () {},
              onDuplicate: () {},
              onDelete: () {},
              onLayer: (value) => action = value,
              canMoveLayer: (_) => true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Öne al'));
      expect(action, AlbumElementLayerAction.moveUp);
      await tester.tap(find.text('Arkaya al'));
      expect(action, AlbumElementLayerAction.moveDown);
      await tester.ensureVisible(find.text('Sağa döndür'));
      await tester.tap(find.text('Sağa döndür'));
      expect(e.rotation, greaterThan(0));
      await tester.ensureVisible(find.text('Katmanlar'));
      await tester.tap(find.text('Katmanlar'));
      await tester.pump();
      for (final entry in {
        'Bir alta gönder': AlbumElementLayerAction.moveDown,
        'Bir üste getir': AlbumElementLayerAction.moveUp,
        'En alta gönder': AlbumElementLayerAction.sendToBack,
        'En üste getir': AlbumElementLayerAction.bringToFront,
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        expect(action, entry.value);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test('lock and card color survive saving; locked items do not snap', () {
    final e = shape('a', 'albumium_shape:circle_blush', .399, .399, .2, .2)
      ..locked = true
      ..cardColor = 0xFFFCE4EC;
    final copy = AlbumElementModel.fromJson(e.toJson());
    expect(copy.locked, isTrue);
    expect(copy.cardColor, e.cardColor);
    snapAlbumElement(copy, const Size(500, 700));
    expect(copy.x, e.x);
    copy.locked = false;
    snapAlbumElement(copy, const Size(500, 700));
    expect(copy.x, closeTo(.4, .0001));
    expect(copy.y, closeTo(.4, .0001));
  });
  testWidgets(
    'large circle empty corner passes taps to adjacent object; lock prevents drag',
    (tester) async {
      final small = shape(
        'small',
        'albumium_shape:square_gold',
        .17,
        .22,
        .15,
        .11,
      );
      final big = shape(
        'big',
        'albumium_shape:circle_blush',
        .375,
        .411,
        .25,
        .178,
        scale: 3,
      );
      final page = AlbumPageModel(
        id: 'test',
        backgroundColor: 0xFFFFFFFF,
        elements: [small, big],
      );
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 560,
                child: AlbumPageCanvas(
                  page: page,
                  theme: albumThemes.first,
                  interactive: true,
                  onSelect: (id) => selected = id,
                ),
              ),
            ),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(AlbumPageCanvas));
      await tester.tapAt(origin + const Offset(98, 154));
      await tester.pump();
      expect(selected, 'small');
      big.locked = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 560,
                child: AlbumPageCanvas(
                  page: page,
                  theme: albumThemes.first,
                  interactive: true,
                  onSelect: (id) => selected = id,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.dragFrom(
        origin + const Offset(200, 280),
        const Offset(30, 20),
      );
      await tester.pump();
      expect(big.x, .375);
      expect(big.y, .411);
    },
  );
  testWidgets('precision opens on request and lock disables movement', (
    tester,
  ) async {
    final e = shape('a', 'albumium_shape:circle_blush', .2, .2, .2, .2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ElementEditPanel(
              element: e,
              onChanged: () {},
              onClose: () {},
              onStyle: () {},
              onCrop: () {},
              onDuplicate: () {},
              onDelete: () {},
              onLayer: (_) {},
              canMoveLayer: (_) => true,
            ),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Sağa'), findsNothing);
    await tester.tap(find.text('Hassas ayar'));
    await tester.pump();
    await tester.tap(find.byTooltip('Sağa'));
    expect(e.x, closeTo(.202, .00001));
    await tester.tap(find.text('Sabitle'));
    await tester.pump();
    await tester.tap(find.byTooltip('Sağa'));
    expect(e.x, closeTo(.202, .00001));
    expect(tester.takeException(), isNull);
  });
}
