import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/editor_screen.dart';
import 'package:albumium/screens/personal_stickers_screen.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/services/albumium_entitlements.dart';
import 'package:albumium/services/feature_entitlements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Installs the app-wide ledger the screens read when nothing is injected.
Future<FeatureEntitlements> _install({bool unlocked = false}) async {
  SharedPreferences.setMockInitialValues({});
  final features = FeatureEntitlements(
    preferences: await SharedPreferences.getInstance(),
  );
  await features.initialize();
  if (unlocked) await features.purchase(AlbumiumFeature.customStickers);
  AlbumiumEntitlements.configure(AlbumiumEntitlements(features: features));
  addTearDown(AlbumiumEntitlements.resetForTesting);
  return features;
}

AlbumModel _album() => AlbumModel(
  id: 'paywall',
  title: 'Paywall',
  themeId: 'minimal_editorial',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  pages: [AlbumPageModel(id: 'page', backgroundColor: 0xFFFFFFFF)],
);

Future<void> _tapStickerTool(WidgetTester tester) async {
  await tester.tap(find.text('Sticker'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the album editor asks for payment before the cutout screen', (
    tester,
  ) async {
    final features = await _install();
    await tester.pumpWidget(MaterialApp(home: EditorScreen(album: _album())));
    await tester.pumpAndSettle();

    await _tapStickerTool(tester);

    expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsOneWidget);
    expect(find.textContaining('₺29,99'), findsOneWidget);
    expect(
      find.byType(PersonalStickersScreen),
      findsNothing,
      reason: 'the paid screen must not open before it is paid for',
    );
    // Watching an ad is not on offer here; this one is bought outright.
    expect(find.byKey(const ValueKey('feature-unlock-watch-ad')), findsNothing);
    expect(features.isUnlocked(AlbumiumFeature.customStickers), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('buying it opens the cutout screen straight away', (
    tester,
  ) async {
    final features = await _install();
    await tester.pumpWidget(MaterialApp(home: EditorScreen(album: _album())));
    await tester.pumpAndSettle();

    await _tapStickerTool(tester);
    await tester.tap(find.byKey(const ValueKey('feature-unlock-buy')));
    await tester.pumpAndSettle();

    expect(features.isPurchased(AlbumiumFeature.customStickers), isTrue);
    expect(find.byType(PersonalStickersScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('someone who owns it is not asked again', (tester) async {
    await _install(unlocked: true);
    await tester.pumpWidget(MaterialApp(home: EditorScreen(album: _album())));
    await tester.pumpAndSettle();

    await _tapStickerTool(tester);

    expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsNothing);
    expect(find.byType(PersonalStickersScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the card studio is gated the same way', (tester) async {
    await _install();
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: SpecialCardStudioScreen(project: _album())),
    );
    await tester.pumpAndSettle();

    await _tapStickerTool(tester);

    expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsOneWidget);
    expect(find.byType(PersonalStickersScreen), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
