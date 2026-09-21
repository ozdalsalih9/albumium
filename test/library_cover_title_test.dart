import 'dart:convert';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/home_screen.dart';
import 'package:albumium/services/language_controller.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:albumium/widgets/album_cover_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _albumsKey = 'albumium.albums.v1';

void _seed(AlbumModel album) {
  SharedPreferences.setMockInitialValues({
    _albumsKey: jsonEncode({
      'schemaVersion': 2,
      'albums': [album.toJson()],
    }),
  });
}

AlbumModel _album(String title) {
  final date = DateTime.utc(2026, 3, 4);
  return AlbumModel(
    id: 'library-cover',
    title: title,
    themeId: 'travel_istanbul',
    createdAt: date,
    updatedAt: date,
    pages: const [],
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        themeController: ThemeController(preferences: preferences),
        languageController: LanguageController(preferences: preferences),
        heroMotionEnabled: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a library cover carries the name written on it', (tester) async {
    _seed(_album('Bahar Yolculuğu'));
    await _pumpHome(tester);

    final cover = find.byKey(const ValueKey('library-cover-library-cover'));
    await tester.scrollUntilVisible(
      cover,
      240,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(
      tester
          .widget<AlbumCover3D>(
            find.descendant(of: cover, matching: find.byType(AlbumCover3D)),
          )
          .showTitle,
      isTrue,
    );
    // The plate on the artwork, not only the caption underneath.
    expect(
      find.descendant(of: cover, matching: find.text('Bahar Yolculuğu')),
      findsOneWidget,
    );
  });

  testWidgets('an untitled album falls back to a placeholder on the plate', (
    tester,
  ) async {
    _seed(_album('   '));
    await _pumpHome(tester);

    final cover = find.byKey(const ValueKey('library-cover-library-cover'));
    await tester.scrollUntilVisible(
      cover,
      240,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(
      find.descendant(of: cover, matching: find.text('İsimsiz Albüm')),
      findsOneWidget,
    );
  });
}
