import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlbumElementModel _role(AlbumModel project, String prefix) => project
    .pages
    .first
    .elements
    .firstWhere((element) => element.id.startsWith(prefix));

Future<void> _pumpStudio(WidgetTester tester, AlbumModel project) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(720, 1280);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: SpecialCardStudioScreen(project: project)),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseTheme(WidgetTester tester, String title) async {
  final tile = find.text(title).first;
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switching theme replaces untouched copy and the card name', (
    tester,
  ) async {
    final project = createSpecialCardProject();
    expect(project.title, 'İyi ki Doğdun! Kartı');

    await _pumpStudio(tester, project);
    await _chooseTheme(tester, 'Senin Günün');

    expect(project.cardThemeId, 'birthday_flower');
    expect(project.title, 'Senin Günün Kartı');
    expect(_role(project, 'card-title-').content, 'Senin Günün');
    expect(
      _role(project, 'card-message-').content,
      'İyi ki varsın, iyi ki hayatımdasın.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching theme keeps wording and a name the user wrote', (
    tester,
  ) async {
    final project = createSpecialCardProject()..title = 'Annemin Kartı';
    _role(project, 'card-title-').content = 'Canım Annem';

    await _pumpStudio(tester, project);
    await _chooseTheme(tester, 'Senin Günün');

    expect(project.cardThemeId, 'birthday_flower');
    expect(project.title, 'Annemin Kartı');
    expect(_role(project, 'card-title-').content, 'Canım Annem');
    // The message was never edited, so it still follows the theme.
    expect(
      _role(project, 'card-message-').content,
      'İyi ki varsın, iyi ki hayatımdasın.',
    );
    expect(tester.takeException(), isNull);
  });
}
