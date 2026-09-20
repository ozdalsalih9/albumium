import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/album_models.dart';

/// Where a cover purchase actually happens.
///
/// This is the seam for real billing: today [LocalCoverPurchaseSource] just
/// says yes, and swapping in a Google Play implementation should not require
/// touching [CoverEntitlements] or any widget.
abstract class CoverPurchaseSource {
  /// The price shown on locked covers and on the purchase sheet.
  String priceLabelFor(String themeId);

  /// Returns true once the cover belongs to the user.
  Future<bool> purchase(String themeId);

  /// Theme ids the store already considers owned.
  Future<Set<String>> restore();
}

/// A stand-in store that unlocks instantly and keeps nothing of its own.
///
/// Purchases live in [CoverEntitlements]'s preferences, so clearing app data
/// re-locks the covers. That is the honest behaviour for a local-only store;
/// real receipts arrive with the billing integration.
class LocalCoverPurchaseSource implements CoverPurchaseSource {
  const LocalCoverPurchaseSource();

  @override
  String priceLabelFor(String themeId) => themeById(themeId).price.label ?? '';

  @override
  Future<bool> purchase(String themeId) async => true;

  @override
  Future<Set<String>> restore() async => const <String>{};
}

/// Knows which covers the user may pick for a *new* album.
///
/// Nothing that renders or edits an existing album consults this: an album
/// saved with a premium theme keeps that theme forever, however it was made.
class CoverEntitlements extends ChangeNotifier {
  CoverEntitlements({
    SharedPreferences? preferences,
    CoverPurchaseSource source = const LocalCoverPurchaseSource(),
  }) : _preferences = preferences,
       _source = source;

  static const purchasedCoversPreferenceKey = 'albumium.purchased_covers.v1';

  /// Product ids are derived, so Play Console entries can be added later
  /// without a second mapping table.
  static String productIdFor(String themeId) => 'albumium.cover.$themeId';

  final CoverPurchaseSource _source;
  SharedPreferences? _preferences;
  Future<void>? _initialization;
  bool _isInitialized = false;
  Set<String> _purchased = <String>{};

  bool get isInitialized => _isInitialized;
  Set<String> get purchasedThemeIds => Set.unmodifiable(_purchased);

  /// Loads saved purchases. Multiple calls share the same initialization.
  Future<void> initialize() {
    return _initialization ??= _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    _purchased =
        preferences.getStringList(purchasedCoversPreferenceKey)?.toSet() ??
        <String>{};
    _isInitialized = true;
    notifyListeners();
  }

  /// Free covers are always available; premium ones need a purchase.
  bool isUnlocked(String themeId) {
    if (!themeById(themeId).isPremium) return true;
    return _purchased.contains(themeId);
  }

  bool isUnlockedTheme(AlbumThemePreset theme) =>
      !theme.isPremium || _purchased.contains(theme.id);

  String priceLabelFor(String themeId) => _source.priceLabelFor(themeId);

  /// Returns true when the cover is unlocked afterwards.
  Future<bool> purchase(String themeId) async {
    final preferences = await _getPreferences();
    if (_purchased.contains(themeId)) return true;
    if (!await _source.purchase(themeId)) return false;
    _purchased = {..._purchased, themeId};
    notifyListeners();
    await preferences.setStringList(
      purchasedCoversPreferenceKey,
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
    await preferences.setStringList(
      purchasedCoversPreferenceKey,
      _purchased.toList()..sort(),
    );
  }

  Future<void> reset() async {
    final preferences = await _getPreferences();
    final changed = _purchased.isNotEmpty;
    _purchased = <String>{};
    if (changed) notifyListeners();
    await preferences.remove(purchasedCoversPreferenceKey);
  }

  Future<SharedPreferences> _getPreferences() async {
    await initialize();
    return _preferences!;
  }
}
