import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/services/cover_entitlements.dart';
import 'package:albumium/widgets/album_cover.dart';
import 'package:albumium/widgets/album_cover_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An album made before the covers were put on sale, or on another device.
AlbumModel _albumWithPremiumCover() {
  final date = DateTime(2026);
  return AlbumModel(
    id: 'inherited-album',
    title: 'Eski Albüm',
    themeId: 'dark_leather',
    createdAt: date,
    updatedAt: date,
    pages: [AlbumPageModel(id: 'page-1', backgroundColor: 0xFFEFE7D8)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an album keeps its premium cover without any purchase', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final entitlements = CoverEntitlements(
      preferences: await SharedPreferences.getInstance(),
    );
    await entitlements.initialize();
    expect(entitlements.isUnlocked('dark_leather'), isFalse);

    final album = _albumWithPremiumCover();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: AspectRatio(
                aspectRatio: 15 / 22,
                child: AlbumCover3D(album: album),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlbumCover), findsOneWidget);
    expect(
      find.byKey(const ValueKey('theme-lock-badge-dark_leather')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the editor opens an album with a locked cover', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: EditorScreen(album: _albumWithPremiumCover())),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('theme-lock-badge-dark_leather')),
      findsNothing,
    );
    expect(
      find.textContaining(themeById('dark_leather').price.label!),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  test('the rendering path never consults entitlements', () {
    // Album JSON carries only the theme id, so a shared or imported album
    // cannot smuggle someone else's purchase, and cannot lose its cover.
    final album = _albumWithPremiumCover();
    final restored = AlbumModel.fromJson(album.toJson());

    expect(restored.themeId, 'dark_leather');
    expect(album.toJson().containsKey('unlocked'), isFalse);
    expect(album.toJson().containsKey('purchased'), isFalse);
    expect(themeById(restored.themeId).coverAsset, isNotNull);
  });
}
