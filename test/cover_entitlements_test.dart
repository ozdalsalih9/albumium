import 'package:albumium/models/album_models.dart';
import 'package:albumium/services/cover_entitlements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that can be told to fail, and that reports what it was asked.
class _FakeSource implements CoverPurchaseSource {
  _FakeSource({this.succeeds = true, this.owned = const <String>{}});

  final bool succeeds;
  final Set<String> owned;
  final List<String> attempted = [];

  @override
  String priceLabelFor(String themeId) => '₺14,99';

  @override
  Future<bool> purchase(String themeId) async {
    attempted.add(themeId);
    return succeeds;
  }

  @override
  Future<Set<String>> restore() async => owned;
}

Future<CoverEntitlements> _entitlements({
  Map<String, Object> stored = const {},
  CoverPurchaseSource? source,
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final entitlements = CoverEntitlements(
    preferences: await SharedPreferences.getInstance(),
    source: source ?? _FakeSource(),
  );
  await entitlements.initialize();
  return entitlements;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('free covers are open and premium covers start locked', () async {
    final entitlements = await _entitlements();

    expect(entitlements.isUnlocked('soft_romance'), isTrue);
    expect(entitlements.isUnlocked('dark_leather'), isFalse);
    expect(entitlements.isUnlockedTheme(themeById('vintage_diary')), isFalse);
  });

  test('a purchase unlocks the cover and survives a restart', () async {
    final entitlements = await _entitlements();
    var notifications = 0;
    entitlements.addListener(() => notifications++);

    expect(await entitlements.purchase('dark_leather'), isTrue);
    expect(entitlements.isUnlocked('dark_leather'), isTrue);
    expect(notifications, 1);

    final reopened = CoverEntitlements(
      preferences: await SharedPreferences.getInstance(),
    );
    await reopened.initialize();
    expect(reopened.isUnlocked('dark_leather'), isTrue);
    expect(reopened.isUnlocked('animals'), isFalse);
  });

  test('buying the same cover twice does not duplicate it', () async {
    final source = _FakeSource();
    final entitlements = await _entitlements(source: source);

    await entitlements.purchase('animals');
    await entitlements.purchase('animals');

    expect(entitlements.purchasedThemeIds, {'animals'});
    expect(source.attempted, ['animals'], reason: 'the store is asked once');
  });

  test('a failed purchase leaves the cover locked', () async {
    final entitlements = await _entitlements(
      source: _FakeSource(succeeds: false),
    );

    expect(await entitlements.purchase('animals'), isFalse);
    expect(entitlements.isUnlocked('animals'), isFalse);
    expect(entitlements.purchasedThemeIds, isEmpty);
  });

  test('restore adds covers the store already owns', () async {
    final entitlements = await _entitlements(
      source: _FakeSource(owned: {'animals', 'minimal_editorial'}),
    );

    await entitlements.restore();

    expect(entitlements.isUnlocked('animals'), isTrue);
    expect(entitlements.isUnlocked('minimal_editorial'), isTrue);
  });

  test('unknown saved ids are ignored instead of breaking', () async {
    final entitlements = await _entitlements(
      stored: {
        CoverEntitlements.purchasedCoversPreferenceKey: <String>[
          'retired_cover',
          'animals',
        ],
      },
    );

    expect(entitlements.isUnlocked('animals'), isTrue);
    expect(entitlements.isUnlocked('dark_leather'), isFalse);
  });

  test('reset locks the premium covers again', () async {
    final entitlements = await _entitlements();
    await entitlements.purchase('animals');

    await entitlements.reset();

    expect(entitlements.isUnlocked('animals'), isFalse);
    expect(entitlements.isUnlocked('soft_romance'), isTrue);
  });

  test('product ids are derived from the theme id', () {
    expect(
      CoverEntitlements.productIdFor('dark_leather'),
      'albumium.cover.dark_leather',
    );
  });
}
