import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/screens/social_video_screen.dart';
import 'package:albumium/services/feature_entitlements.dart';
import 'package:albumium/services/video_export_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'social_video_draft_test.dart' show socialTestAlbum;

Future<FeatureEntitlements> _features({bool unlocked = false}) async {
  SharedPreferences.setMockInitialValues({});
  final features = FeatureEntitlements(
    preferences: await SharedPreferences.getInstance(),
  );
  await features.initialize();
  if (unlocked) await features.purchase(AlbumiumFeature.fullHdExport);
  return features;
}

AlbumModel _album() {
  final now = DateTime(2026);
  return AlbumModel(
    id: 'gate-preview',
    title: 'Kalite',
    themeId: 'vintage_diary',
    createdAt: now,
    updatedAt: now,
    pages: [AlbumPageModel(id: 'gate-page', backgroundColor: 0xFFF2E8D3)],
  );
}

Future<void> _pumpSocial(
  WidgetTester tester,
  FeatureEntitlements features,
) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: SocialVideoScreen(album: socialTestAlbum(), entitlements: features),
    ),
  );
  await tester.pumpAndSettle();
  // The quality chips sit below the preview; drag the outer gutter, away from
  // the page list that scrolls on its own.
  for (
    var i = 0;
    i < 12 &&
        find.byKey(const ValueKey('social-quality-1080')).evaluate().isEmpty;
    i++
  ) {
    await tester.dragFrom(const Offset(8, 700), const Offset(0, -450));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.byKey(const ValueKey('social-quality-1080')));
  await tester.pumpAndSettle();
}

ChoiceChip _chip(WidgetTester tester, int width) =>
    tester.widget<ChoiceChip>(find.byKey(ValueKey('social-quality-$width')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the social studio opens on the quality everyone has', (
    tester,
  ) async {
    await _pumpSocial(tester, await _features());

    expect(_chip(tester, 720).selected, isTrue);
    expect(_chip(tester, 1080).selected, isFalse);
    expect(_chip(tester, 1080).avatar, isNotNull, reason: 'shows it is locked');
  });

  testWidgets('picking Full HD while locked offers the unlock instead', (
    tester,
  ) async {
    final features = await _features();
    await _pumpSocial(tester, features);

    await tester.tap(find.byKey(const ValueKey('social-quality-1080')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feature-unlock-watch-ad')),
      findsOneWidget,
    );

    // Dismissing leaves the export where it was.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(_chip(tester, 720).selected, isTrue);
    expect(features.isUnlocked(AlbumiumFeature.fullHdExport), isFalse);
  });

  testWidgets('buying in the sheet switches the studio to Full HD', (
    tester,
  ) async {
    final features = await _features();
    await _pumpSocial(tester, features);

    await tester.tap(find.byKey(const ValueKey('social-quality-1080')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feature-unlock-buy')));
    await tester.pumpAndSettle();

    expect(_chip(tester, 1080).selected, isTrue);
    expect(_chip(tester, 1080).avatar, isNull, reason: 'the lock is gone');
  });

  testWidgets('someone who paid opens straight on Full HD', (tester) async {
    await _pumpSocial(tester, await _features(unlocked: true));

    expect(_chip(tester, 1080).selected, isTrue);
    expect(_chip(tester, 1080).avatar, isNull);
  });

  testWidgets('the MP4 sheet refuses Full HD until it is unlocked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final features = await _features();
    await tester.pumpWidget(
      MaterialApp(
        home: PreviewScreen(album: _album(), entitlements: features),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('preview_share_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share_mp4')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yüksek · 1080p'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('feature-unlock-buy')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<VideoExportQuality>>(
            find.byKey(const ValueKey('mp4_quality_selector')),
          )
          .selected,
      {VideoExportQuality.fullHd},
    );
  });
}
