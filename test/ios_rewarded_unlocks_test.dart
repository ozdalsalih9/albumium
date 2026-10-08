import 'dart:async';

import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/cover_catalog_screen.dart';
import 'package:albumium/screens/personal_stickers_screen.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/screens/social_video_screen.dart';
import 'package:albumium/screens/theme_screen.dart';
import 'package:albumium/services/album_storage.dart';
import 'package:albumium/services/albumium_entitlements.dart';
import 'package:albumium/services/billing_startup.dart';
import 'package:albumium/services/cover_entitlements.dart';
import 'package:albumium/services/feature_entitlements.dart';
import 'package:albumium/services/monetization_policy.dart';
import 'package:albumium/services/rewarded_ads.dart';
import 'package:albumium/services/video_export_support.dart';
import 'package:albumium/widgets/feature_unlock_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ads implements RewardedAdSource {
  _Ads(this.outcome);
  RewardedAdOutcome outcome;
  final placements = <RewardedAdPlacement>[];
  Completer<RewardedAdOutcome>? pending;

  @override
  Future<RewardedAdOutcome> show(RewardedAdPlacement placement) async {
    placements.add(placement);
    return pending == null ? outcome : await pending!.future;
  }
}

Future<AlbumiumEntitlements> _install() async {
  final preferences = await SharedPreferences.getInstance();
  final entitlements = AlbumiumEntitlements(
    covers: CoverEntitlements(preferences: preferences),
    features: FeatureEntitlements(preferences: preferences),
  );
  await entitlements.initialize();
  AlbumiumEntitlements.configure(entitlements);
  return entitlements;
}

Future<void> _picker(WidgetTester tester, CoverEntitlements covers) async {
  tester.view.physicalSize = const Size(411, 914);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<AlbumModel>(
                builder: (_) => ThemeScreen(
                  initialThemeId: 'animals',
                  entitlements: covers,
                ),
              ),
            ),
            child: const Text('open picker'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open picker'));
  await tester.pumpAndSettle();
}

AlbumModel _videoAlbum() => AlbumModel(
  id: 'reward-video',
  title: 'Anılar',
  themeId: 'vintage_diary',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  pages: [AlbumPageModel(id: 'reward-page', backgroundColor: 0xFFF2E8D3)],
);

void _videoViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void _iosTestWidgets(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    RewardedAds.resetForTesting();
    AlbumiumEntitlements.resetForTesting();
  });

  test(
    'iOS ignores old permanent unlocks and never starts the store',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      SharedPreferences.setMockInitialValues({
        CoverEntitlements.purchasedCoversPreferenceKey: ['animals'],
        FeatureEntitlements.purchasedFeaturesPreferenceKey: [
          'video_fullhd',
          'custom_stickers',
        ],
      });
      var storeCalls = 0;
      final ledger = await _install();
      await startBilling(
        ledger,
        createClient: () {
          storeCalls++;
          throw StateError('iOS must not contact the store');
        },
      );
      expect(storeCalls, 0);
      expect(ledger.covers.isUnlocked('animals'), isFalse);
      for (final feature in AlbumiumFeature.values) {
        expect(ledger.features.isUnlocked(feature), isFalse);
        expect(await ledger.features.purchase(feature), isFalse);
      }
      expect(await ledger.covers.purchase('animals'), isFalse);
      // The iOS policy must not erase Android's purchase records.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(ledger.covers.isUnlocked('animals'), isTrue);
      expect(ledger.features.isPurchased(AlbumiumFeature.fullHdExport), isTrue);
      expect(MonetizationPolicy.rewardedOnly, isFalse);
    },
  );

  test(
    'cover and feature rewards are one use and do not survive restart',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ledger = await _install();
      ledger.covers.grant('animals');
      ledger.features.grant(AlbumiumFeature.customStickers);
      ledger.features.grant(AlbumiumFeature.fullHdExport);
      final restarted = await _install();
      expect(restarted.covers.isUnlocked('animals'), isFalse);
      for (final feature in AlbumiumFeature.values) {
        expect(restarted.features.isUnlocked(feature), isFalse);
        expect(ledger.features.consumeGrant(feature), isTrue);
        expect(ledger.features.isUnlocked(feature), isFalse);
        expect(ledger.features.consumeGrant(feature), isFalse);
      }
      expect(ledger.covers.consumeGrant('animals'), isTrue);
      expect(ledger.covers.isUnlocked('animals'), isFalse);
      expect(ledger.covers.consumeGrant('animals'), isFalse);
      expect(ledger.covers.isUnlocked('soft_romance'), isTrue);
    },
  );

  for (final feature in AlbumiumFeature.values) {
    _iosTestWidgets(
      'iOS $feature offers only an ad and grants exactly one use',
      (tester) async {
        final ledger = await _install();
        final ads = _Ads(RewardedAdOutcome.earned);
        RewardedAds.configure(ads);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showFeatureUnlockSheet(
                    context,
                    feature: feature,
                    title: 'unlock',
                    description: 'description',
                    bullets: const [(Icons.sell, 'Tek seferlik satın alma.')],
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('feature-unlock-buy')), findsNothing);
        expect(
          find.byKey(const ValueKey('feature-unlock-restore')),
          findsNothing,
        );
        expect(find.textContaining('₺'), findsNothing);
        expect(find.text('Tek seferlik satın alma.'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('feature-unlock-watch-ad')));
        await tester.pumpAndSettle();
        expect(ads.placements, [RewardedAdPlacement.forFeature(feature)]);
        expect(ledger.features.hasGrant(feature), isTrue);
        expect(ledger.features.isPurchased(feature), isFalse);
        ledger.features.consumeGrant(feature);
        expect(ledger.features.isUnlocked(feature), isFalse);
      },
    );
  }

  _iosTestWidgets('a rewarded cover is consumed only when its album is saved', (
    tester,
  ) async {
    final ledger = await _install();
    final ads = _Ads(RewardedAdOutcome.earned);
    RewardedAds.configure(ads);
    await _picker(tester, ledger.covers);
    expect(find.textContaining('₺'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cover-purchase-confirm')), findsNothing);
    expect(find.byKey(const ValueKey('cover-purchase-restore')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cover-unlock-watch-ad')));
    await tester.pumpAndSettle();
    expect(ads.placements, [RewardedAdPlacement.cover]);
    expect(ledger.covers.hasGrant('animals'), isTrue);
    // The unlock confirmation snackbar temporarily covers the start button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
    await tester.pumpAndSettle();
    expect(ledger.covers.hasGrant('animals'), isFalse);
    expect(ledger.covers.isUnlocked('animals'), isFalse);
    expect(
      (await AlbumStorage.instance.loadAlbums()).single.themeId,
      'animals',
    );
    await _picker(tester, ledger.covers);
    await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cover-unlock-watch-ad')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  _iosTestWidgets(
    'repeated cover taps request only one ad and wait for reward',
    (tester) async {
      final ledger = await _install();
      final ads = _Ads(RewardedAdOutcome.earned)
        ..pending = Completer<RewardedAdOutcome>();
      RewardedAds.configure(ads);
      await _picker(tester, ledger.covers);
      await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('cover-unlock-watch-ad'));
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      expect(ads.placements, [RewardedAdPlacement.cover]);
      expect(ledger.covers.hasGrant('animals'), isFalse);
      ads.pending!.complete(RewardedAdOutcome.earned);
      await tester.pumpAndSettle();
      expect(ledger.covers.hasGrant('animals'), isTrue);
    },
  );

  _iosTestWidgets(
    'social video requests another ad after its Full HD grant is spent',
    (tester) async {
      _videoViewport(tester);
      final ledger = await _install();
      ledger.features.grant(AlbumiumFeature.fullHdExport);
      await tester.pumpWidget(
        MaterialApp(
          home: SocialVideoScreen(
            album: _videoAlbum(),
            entitlements: ledger.features,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 12 &&
            find.byKey(const ValueKey('social-export')).evaluate().isEmpty;
        i++
      ) {
        await tester.dragFrom(const Offset(8, 700), const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const ValueKey('social-export')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('social-quality-1080')),
            )
            .selected,
        isTrue,
      );
      // Keep the selected quality, as happens after a successful first export.
      ledger.features.consumeGrant(AlbumiumFeature.fullHdExport);
      await tester.tap(find.byKey(const ValueKey('social-export')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('feature-unlock-watch-ad')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('feature-unlock-buy')), findsNothing);
      expect(ledger.features.hasGrant(AlbumiumFeature.fullHdExport), isFalse);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  _iosTestWidgets('MP4 export rechecks a spent Full HD grant before encoding', (
    tester,
  ) async {
    _videoViewport(tester);
    final ledger = await _install();
    ledger.features.grant(AlbumiumFeature.fullHdExport);
    await tester.pumpWidget(
      MaterialApp(
        home: PreviewScreen(
          album: _videoAlbum(),
          entitlements: ledger.features,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview_share_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share_mp4')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yüksek · 1080p'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<VideoExportQuality>>(
            find.byKey(const ValueKey('mp4_quality_selector')),
          )
          .selected,
      {VideoExportQuality.fullHd},
    );
    ledger.features.consumeGrant(AlbumiumFeature.fullHdExport);
    await tester.ensureVisible(find.byKey(const ValueKey('start_mp4_export')));
    await tester.tap(find.byKey(const ValueKey('start_mp4_export')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('feature-unlock-watch-ad')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('feature-unlock-buy')), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final outcome in [
    RewardedAdOutcome.dismissed,
    RewardedAdOutcome.unavailable,
    RewardedAdOutcome.failed,
  ]) {
    _iosTestWidgets('a $outcome cover ad grants nothing and can be retried', (
      tester,
    ) async {
      final ledger = await _install();
      final ads = _Ads(outcome);
      RewardedAds.configure(ads);
      await _picker(tester, ledger.covers);
      await tester.tap(find.byKey(const ValueKey('theme-primary-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cover-unlock-watch-ad')));
      await tester.pumpAndSettle();
      expect(ledger.covers.isUnlocked('animals'), isFalse);
      expect(
        find.byKey(const ValueKey('cover-purchase-error')),
        findsOneWidget,
      );
      expect(find.textContaining('Satın'), findsNothing);
      ads.outcome = RewardedAdOutcome.earned;
      await tester.tap(find.byKey(const ValueKey('cover-unlock-watch-ad')));
      await tester.pumpAndSettle();
      expect(ledger.covers.hasGrant('animals'), isTrue);
    });
  }

  _iosTestWidgets(
    'sticker library is free; creating a sticker requests an ad',
    (tester) async {
      await _install();
      await tester.pumpWidget(
        const MaterialApp(home: PersonalStickersScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('feature-unlock-sheet')), findsNothing);
      await tester.tap(find.text('Fotoğraftan oluştur'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('feature-unlock-watch-ad')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('feature-unlock-buy')), findsNothing);
      expect(
        find.text('Bir reklam izle, bir sticker oluştur.'),
        findsOneWidget,
      );
    },
  );

  _iosTestWidgets('catalogue uses ad labels instead of price or purchased', (
    tester,
  ) async {
    final theme = themeById('animals');
    String? locked, ready;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            locked = coverStatusLabel(context, theme: theme, locked: true);
            ready = coverStatusLabel(context, theme: theme, locked: false);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(locked, 'Reklamla aç');
    expect(ready, 'Bir kullanım hazır');
  });
}
