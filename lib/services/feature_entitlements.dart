import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_reporter.dart';

/// A one-time unlock that is not a cover.
///
/// The price sits next to the product for the same reason [CoverPrice] sits in
/// the catalogue next to the theme: a feature and its price cannot drift apart.
enum AlbumiumFeature {
  fullHdExport('video_fullhd', '₺4,99'),
  customStickers('custom_stickers', '₺29,99');

  const AlbumiumFeature(this.id, this.priceLabel);

  final String id;
  final String priceLabel;

  /// Product ids are derived, so Play Console entries need no second table.
  String get productId => 'albumium.feature.$id';
}

/// Where a feature purchase actually happens.
///
/// This is the seam for real billing, mirroring `CoverPurchaseSource`: today
/// [LocalFeaturePurchaseSource] just says yes.
abstract class FeaturePurchaseSource {
  String priceLabelFor(AlbumiumFeature feature);

  Future<bool> purchase(AlbumiumFeature feature);

  /// Feature ids the store already considers owned.
  Future<Set<String>> restore();
}

class LocalFeaturePurchaseSource implements FeaturePurchaseSource {
  const LocalFeaturePurchaseSource();

  @override
  String priceLabelFor(AlbumiumFeature feature) => feature.priceLabel;

  @override
  Future<bool> purchase(AlbumiumFeature feature) async => true;

  @override
  Future<Set<String>> restore() async => const <String>{};
}

/// Knows which paid features the user may use.
///
/// Two ways in, kept apart on purpose: a purchase is money and is remembered
/// forever, while a rewarded ad buys a single use and is never written down.
class FeatureEntitlements extends ChangeNotifier {
  FeatureEntitlements({
    SharedPreferences? preferences,
    FeaturePurchaseSource source = const LocalFeaturePurchaseSource(),
  }) : _preferences = preferences,
       _source = source;

  static const purchasedFeaturesPreferenceKey =
      'albumium.purchased_features.v1';

  FeaturePurchaseSource _source;
  SharedPreferences? _preferences;
  Future<void>? _initialization;
  bool _isInitialized = false;
  Set<String> _purchased = <String>{};
  final Set<String> _granted = <String>{};

  /// Swaps in the real store once it answers; see CoverEntitlements.
  void useSource(FeaturePurchaseSource source) {
    _source = source;
    notifyListeners();
  }

  bool get isInitialized => _isInitialized;
  Set<String> get purchasedFeatureIds => Set.unmodifiable(_purchased);

  Future<void> initialize() {
    return _initialization ??= _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = _preferences ??=
          await SharedPreferences.getInstance();
      _purchased =
          preferences.getStringList(purchasedFeaturesPreferenceKey)?.toSet() ??
          <String>{};
    } catch (error, stack) {
      // Reaching storage can fail on a device whose data is locked, and it
      // throws in tests that build a screen without mock preferences. Owning
      // nothing is the safe reading: paid features stay shut, the screen opens.
      ErrorReporter.report(
        error,
        stack,
        context: 'FeatureEntitlements.initialize',
      );
      _purchased = <String>{};
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Whether the feature can be used right now, bought or earned.
  bool isUnlocked(AlbumiumFeature feature) =>
      _purchased.contains(feature.id) || _granted.contains(feature.id);

  /// Whether the feature was paid for, so it outlives this session.
  bool isPurchased(AlbumiumFeature feature) => _purchased.contains(feature.id);

  String priceLabelFor(AlbumiumFeature feature) =>
      _source.priceLabelFor(feature);

  /// Records that an ad was watched to the end.
  ///
  /// Deliberately not persisted: the reward is one use, and it dies with the
  /// process rather than quietly becoming a free purchase.
  void grant(AlbumiumFeature feature) {
    if (!_granted.add(feature.id)) return;
    notifyListeners();
  }

  bool hasGrant(AlbumiumFeature feature) => _granted.contains(feature.id);

  /// Spends an earned use. Returns true when there was one to spend.
  ///
  /// A purchased feature has nothing to spend, so this leaves it untouched.
  bool consumeGrant(AlbumiumFeature feature) {
    if (!_granted.remove(feature.id)) return false;
    notifyListeners();
    return true;
  }

  /// Returns true when the feature is owned afterwards.
  Future<bool> purchase(AlbumiumFeature feature) async {
    final preferences = await _getPreferences();
    if (_purchased.contains(feature.id)) return true;
    if (!await _source.purchase(feature)) return false;
    _purchased = {..._purchased, feature.id};
    notifyListeners();
    await preferences?.setStringList(
      purchasedFeaturesPreferenceKey,
      _purchased.toList()..sort(),
    );
    return true;
  }

  /// Adds anything the store already considers owned.
  Future<void> restore() async {
    final preferences = await _getPreferences();
    final owned = await _source.restore();
    final merged = {..._purchased, ...owned};
    if (merged.length == _purchased.length) return;
    _purchased = merged;
    notifyListeners();
    await preferences?.setStringList(
      purchasedFeaturesPreferenceKey,
      _purchased.toList()..sort(),
    );
  }

  /// Makes the store's list the whole truth.
  ///
  /// Unlike [restore], which only adds, this also closes a feature the store
  /// no longer reports — a refund, a chargeback, a purchase made on another
  /// account. Only call it with a real store's answer: an empty set from a
  /// store that could not be reached would wipe what the user paid for.
  Future<void> applyStoreOwnership(Set<String> owned) async {
    final preferences = await _getPreferences();
    final ids = {
      for (final feature in AlbumiumFeature.values)
        if (owned.contains(feature.id)) feature.id,
    };
    if (ids.length == _purchased.length && ids.containsAll(_purchased)) return;
    _purchased = ids;
    notifyListeners();
    await preferences?.setStringList(
      purchasedFeaturesPreferenceKey,
      _purchased.toList()..sort(),
    );
  }

  Future<void> reset() async {
    final preferences = await _getPreferences();
    final changed = _purchased.isNotEmpty || _granted.isNotEmpty;
    _purchased = <String>{};
    _granted.clear();
    if (changed) notifyListeners();
    await preferences?.remove(purchasedFeaturesPreferenceKey);
  }

  /// Null when storage is unreachable; the ledger then lives for this session
  /// only, which is better than refusing a purchase the user just made.
  Future<SharedPreferences?> _getPreferences() async {
    await initialize();
    return _preferences;
  }
}
