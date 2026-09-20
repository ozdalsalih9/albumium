import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/widgets/album_page_canvas.dart';
import 'package:albumium/widgets/font_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testTheme = AlbumThemePreset(
  id: 'tap_to_edit',
  name: 'Tap to edit',
  subtitle: '',
  emoji: '',
  coverStart: Colors.white,
  coverEnd: Colors.white,
  pageColor: Colors.white,
  accent: Colors.black,
  textureLabel: '',
);

AlbumElementModel _text(String id, String content, {double y = 0.25}) =>
    AlbumElementModel(
      id: id,
      type: AlbumElementType.text,
      content: content,
      x: 0.15,
      y: y,
      width: 0.7,
      height: 0.16,
      fontSize: 20,
    );

AlbumModel _album(List<AlbumElementModel> elements) {
  final now = DateTime(2026);
  return AlbumModel(
    id: 'tap-to-edit',
    title: 'Dokun ve düzenle',
    themeId: 'vintage_diary',
    createdAt: now,
    updatedAt: now,
    pages: [
      AlbumPageModel(
        id: 'tap-page',
        backgroundColor: 0xFFF2E8D3,
        elements: elements,
      ),
    ],
  );
}

Future<void> _pumpEditor(WidgetTester tester, AlbumModel album) async {
  SharedPreferences.setMockInitialValues({});
  // Roomy on purpose: the test font is far wider than the real one, and the
  // font list inside the dialog overflows a phone-sized viewport because of it.
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: EditorScreen(album: album)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the canvas selects first and opens on the second tap', (
    tester,
  ) async {
    final element = _text('caption', 'Merhaba');
    final page = AlbumPageModel(
      id: 'page',
      backgroundColor: 0xFFFFFFFF,
      elements: [element],
    );
    final selected = <String?>[];
    final activated = <String>[];
    String? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 300,
                height: 400,
                child: AlbumPageCanvas(
                  page: page,
                  theme: _testTheme,
                  interactive: true,
                  selectedId: selectedId,
                  onSelect: (id) {
                    selected.add(id);
                    setState(() => selectedId = id);
                  },
                  onActivate: activated.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Merhaba'));
    await tester.pumpAndSettle();
    expect(selected, ['caption']);
    expect(activated, isEmpty, reason: 'the first tap only selects');

    await tester.tap(find.text('Merhaba'));
    await tester.pumpAndSettle();
    expect(activated, ['caption'], reason: 'the second tap opens the element');
    expect(selected, ['caption'], reason: 'selection does not change');
  });

  testWidgets('tapping selected text twice opens the album text editor', (
    tester,
  ) async {
    await _pumpEditor(tester, _album([_text('caption', 'Kapadokya')]));

    await tester.tap(find.text('Kapadokya').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextEditorDialog), findsNothing);

    await tester.tap(find.text('Kapadokya').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextEditorDialog), findsOneWidget);
  });

  testWidgets('a locked element stays shut however often it is tapped', (
    tester,
  ) async {
    final locked = _text('caption', 'Sabit')..locked = true;
    await _pumpEditor(tester, _album([locked]));

    await tester.tap(find.text('Sabit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sabit').first);
    await tester.pumpAndSettle();

    expect(find.byType(TextEditorDialog), findsNothing);
  });

  testWidgets('the same two taps open the editor on a greeting card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = createSpecialCardProject();
    final title = project.pages.first.elements.firstWhere(
      (element) => element.id.startsWith('card-title-'),
    );

    await tester.pumpWidget(
      MaterialApp(home: SpecialCardStudioScreen(project: project)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(title.content).first);
    await tester.pumpAndSettle();
    expect(find.byType(TextEditorDialog), findsNothing);

    await tester.tap(find.text(title.content).first);
    await tester.pumpAndSettle();
    expect(find.byType(TextEditorDialog), findsOneWidget);
  });
}
