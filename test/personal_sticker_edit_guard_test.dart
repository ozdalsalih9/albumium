import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/services/personal_sticker_storage.dart';
import 'package:albumium/widgets/element_edit_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlbumElementModel _sticker(String content) => AlbumElementModel(
  id: 'sticker',
  type: AlbumElementType.sticker,
  content: content,
  x: .2,
  y: .25,
  width: .4,
  height: .3,
);

AlbumModel _album(AlbumElementModel element) => AlbumModel(
  id: 'guard',
  title: 'Süs koruması',
  themeId: 'minimal_editorial',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  pages: [
    AlbumPageModel(
      id: 'guard-page',
      backgroundColor: 0xFFFFFFFF,
      elements: [element],
    ),
  ],
);

Future<void> _pumpPanel(WidgetTester tester, AlbumElementModel element) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ElementEditPanel(
          element: element,
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
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the replace tool is hidden for a sticker cut from a photo', (
    tester,
  ) async {
    final personal = _sticker(personalSticker('/tmp/kedi.png', 1));
    expect(isPersonalStickerElement(personal), isTrue);

    await _pumpPanel(tester, personal);

    // "Düzenle" opens the ornament catalogue, which replaces the content and
    // would throw the photo away.
    expect(find.byTooltip('Düzenle'), findsNothing);
  });

  testWidgets('an ornament and a shape keep their replace tool', (
    tester,
  ) async {
    for (final content in ['albumium:washi_tape', 'albumium_shape:circle']) {
      await _pumpPanel(tester, _sticker(content));
      expect(
        find.byTooltip('Düzenle'),
        findsOneWidget,
        reason: 'replacing $content is the point of the tool',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });

  testWidgets('the editor refuses to replace a personal sticker', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final content = personalSticker('/tmp/kedi.png', 1);
    final element = _sticker(content);
    final album = _album(element);

    await tester.pumpWidget(MaterialApp(home: EditorScreen(album: album)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('album-element-art-sticker')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Düzenle'), findsNothing);
    expect(
      element.content,
      content,
      reason: 'the file reference must survive every toolbar action',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
