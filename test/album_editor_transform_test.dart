import 'package:albumium/models/album_models.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumElementModel _element(
  String id, {
  double scale = 1,
  double rotation = 0,
}) => AlbumElementModel(
  id: id,
  type: AlbumElementType.sticker,
  content: id,
  x: .1,
  y: .1,
  width: .2,
  height: .2,
  scale: scale,
  rotation: rotation,
);

List<String> _ids(List<AlbumElementModel> elements) =>
    elements.map((element) => element.id).toList();

void main() {
  test('layer actions use list order for one-step and edge moves', () {
    final elements = [_element('back'), _element('middle'), _element('front')];

    expect(
      canMoveAlbumElementLayer(
        elements,
        'back',
        AlbumElementLayerAction.moveDown,
      ),
      isFalse,
    );
    expect(
      canMoveAlbumElementLayer(
        elements,
        'front',
        AlbumElementLayerAction.bringToFront,
      ),
      isFalse,
    );

    expect(
      moveAlbumElementLayer(elements, 'middle', AlbumElementLayerAction.moveUp),
      isTrue,
    );
    expect(_ids(elements), ['back', 'front', 'middle']);

    expect(
      moveAlbumElementLayer(
        elements,
        'middle',
        AlbumElementLayerAction.sendToBack,
      ),
      isTrue,
    );
    expect(_ids(elements), ['middle', 'back', 'front']);

    expect(
      moveAlbumElementLayer(elements, 'middle', AlbumElementLayerAction.moveUp),
      isTrue,
    );
    expect(_ids(elements), ['back', 'middle', 'front']);

    expect(
      moveAlbumElementLayer(
        elements,
        'middle',
        AlbumElementLayerAction.bringToFront,
      ),
      isTrue,
    );
    expect(_ids(elements), ['back', 'front', 'middle']);
  });

  test('scale steps clamp and transform reset restores the neutral state', () {
    final element = _element('scaled', scale: 1, rotation: .7);

    expect(scaleAlbumElementBy(element, albumElementScaleStep), isTrue);
    expect(element.scale, closeTo(albumElementScaleStep, .000001));

    element.scale = albumElementMaxScale;
    expect(scaleAlbumElementBy(element, albumElementScaleStep), isFalse);
    expect(element.scale, albumElementMaxScale);

    element.scale = albumElementMinScale;
    expect(scaleAlbumElementBy(element, 1 / albumElementScaleStep), isFalse);
    expect(element.scale, albumElementMinScale);

    expect(resetAlbumElementTransform(element), isTrue);
    expect(element.scale, 1);
    expect(element.rotation, 0);
    expect(resetAlbumElementTransform(element), isFalse);
  });
}
