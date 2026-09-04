import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlbumElementModel _sticker(
  String id,
  String content,
  double x, {
  double scale = 1,
  double rotation = 0,
}) => AlbumElementModel(
  id: id,
  type: AlbumElementType.sticker,
  content: content,
  x: x,
  y: .28,
  width: .18,
  height: .14,
  scale: scale,
  rotation: rotation,
);

AlbumModel _album(List<AlbumElementModel> elements) {
  final now = DateTime(2026);
  return AlbumModel(
    id: 'editor-controls',
    title: 'Kontroller',
    themeId: 'vintage_diary',
    createdAt: now,
    updatedAt: now,
    pages: [
      AlbumPageModel(
        id: 'controls-page',
        backgroundColor: 0xFFF2E8D3,
        elements: elements,
      ),
    ],
  );
}

Future<void> _pumpEditor(
  WidgetTester tester,
  AlbumModel album, {
  Size physicalSize = const Size(900, 1600),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: EditorScreen(album: album),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('editor exposes sharing without first opening the reader', (
    tester,
  ) async {
    await _pumpEditor(tester, _album([]), physicalSize: const Size(780, 1688));
    expect(find.byKey(const ValueKey('editor-share')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-share')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('share_interactive_album')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('share_mp4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layer menu labels four moves and disables edge actions', (
    tester,
  ) async {
    final elements = [
      _sticker('back', '🟥', .1),
      _sticker('middle', '🟡', .4),
      _sticker('front', '🔵', .7),
    ];
    await _pumpEditor(tester, _album(elements));

    await tester.tap(find.text('🔵'));
    await tester.pump();
    await tester.tap(find.byTooltip('Katman sırası'));
    await tester.pumpAndSettle();

    expect(find.text('Bir alta gönder'), findsOneWidget);
    expect(find.text('Bir üste getir'), findsOneWidget);
    expect(find.text('En alta gönder'), findsOneWidget);
    expect(find.text('En üste getir'), findsOneWidget);
    expect(
      tester
          .widget<PopupMenuItem<AlbumElementLayerAction>>(
            find.byKey(const ValueKey('layer-action-moveUp')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<PopupMenuItem<AlbumElementLayerAction>>(
            find.byKey(const ValueKey('layer-action-bringToFront')),
          )
          .enabled,
      isFalse,
    );

    await tester.tap(find.text('Bir alta gönder'));
    await tester.pumpAndSettle();
    expect(elements.map((element) => element.id), ['back', 'front', 'middle']);

    await tester.tap(find.byTooltip('Katman sırası'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En alta gönder'));
    await tester.pumpAndSettle();
    expect(elements.map((element) => element.id), ['front', 'back', 'middle']);
  });

  testWidgets('scale buttons and reset transform update the selected object', (
    tester,
  ) async {
    final element = _sticker('transform', '🟣', .35, rotation: .45);
    await _pumpEditor(tester, _album([element]));

    await tester.tap(find.text('🟣'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byTooltip('Büyüt'),
        matching: find.byIcon(Icons.zoom_in_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byTooltip('Küçült'),
        matching: find.byIcon(Icons.zoom_out_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Büyüt'));
    await tester.pump();
    expect(element.scale, closeTo(albumElementScaleStep, .000001));
    expect(element.rotation, .45);

    await tester.tap(find.byTooltip('Dönüş ve ölçeği sıfırla'));
    await tester.pump();
    expect(element.scale, 1);
    expect(element.rotation, 0);

    await tester.tap(find.byTooltip('Küçült'));
    await tester.pump();
    expect(element.scale, closeTo(1 / albumElementScaleStep, .000001));
  });

  testWidgets('landscape tablet uses the compact single-row inspector', (
    tester,
  ) async {
    final element = _sticker('tablet-transform', '🟢', .35);
    await _pumpEditor(
      tester,
      _album([element]),
      physicalSize: const Size(1600, 1200),
    );

    await tester.tap(find.text('🟢'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('selection-toolbar-wide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selection-toolbar-stacked')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('binding picker stays scrollable on a short tablet', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      _album([_sticker('binding', '🟤', .35)]),
      physicalSize: const Size(1600, 1200),
    );

    await tester.tap(find.byTooltip('Cilt Tipi (Telli Spiral)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('binding-options-list')), findsOneWidget);
    expect(find.text('Albüm Ciltleme Tipi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
