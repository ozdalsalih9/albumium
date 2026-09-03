import 'dart:convert';

import 'package:albumium/main.dart';
import 'package:albumium/models/album_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _albumsKey = 'albumium.albums.v1';

AlbumModel _project(int index) {
  final date = DateTime.utc(2026, 1, index + 1);
  return AlbumModel(
    id: 'project-$index',
    title: index == 0 ? 'İstanbul Hatırası' : 'Albüm $index',
    themeId: 'classic',
    createdAt: date,
    updatedAt: date,
    pages: const [],
    projectType: index == 11
        ? AlbumProjectType.occasionCard
        : AlbumProjectType.album,
  );
}

void _seedLibrary() {
  final projects = List.generate(13, _project);
  SharedPreferences.setMockInitialValues({
    _albumsKey: jsonEncode({
      'schemaVersion': 2,
      'albums': projects.map((project) => project.toJson()).toList(),
    }),
  });
}

int _visibleGridItems(WidgetTester tester) {
  final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
  return grid.delegate.estimatedChildCount ?? 0;
}

void main() {
  testWidgets('large libraries reveal projects in pages of twelve', (
    tester,
  ) async {
    _seedLibrary();
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();

    expect(find.text('Koleksiyonum'), findsOneWidget);
    expect(_visibleGridItems(tester), 12);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-load-more')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-load-more')));
    await tester.pumpAndSettle();

    expect(_visibleGridItems(tester), 13);
    expect(find.byKey(const ValueKey('library-load-more')), findsNothing);
  });

  testWidgets('search includes a project beyond the first visible page', (
    tester,
  ) async {
    _seedLibrary();
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();

    // project-0 is the oldest item, so it starts beyond the first 12 results.
    await tester.enterText(
      find.byKey(const ValueKey('library-search')),
      'istanbul',
    );
    await tester.pumpAndSettle();

    expect(_visibleGridItems(tester), 1);
    expect(
      find.byKey(const ValueKey('library-item-project-0')),
      findsOneWidget,
    );
    expect(find.text('1 / 13'), findsOneWidget);
  });

  testWidgets('library grid adapts across tablet viewports without overflow', (
    tester,
  ) async {
    _seedLibrary();
    tester.view.physicalSize = const Size(600, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();

    for (final viewport in const <Size>[
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 768),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'Home layout should not overflow at '
            '${viewport.width}×${viewport.height}.',
      );
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      expect(
        grid.gridDelegate,
        isA<SliverGridDelegateWithMaxCrossAxisExtent>(),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(delegate.maxCrossAxisExtent, 280);
    }

    tester.view.physicalSize = const Size(1366, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-hero-content'))).width,
      1280,
    );
  });
}
