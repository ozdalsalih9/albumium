import 'cover_entitlements.dart';
import 'feature_entitlements.dart';

/// Everything the user has paid for, in one place.
///
/// Covers and features keep separate ledgers, but they are one process-wide
/// fact, so they are reached the way [AlbumStorage] is reached rather than
/// threaded through seven screen constructors. A screen may still be handed
/// its own instance for a test; when it is not, it falls back to [instance]
/// and never to a fresh object, or an ad watched on one screen would be
/// invisible on the next.
class AlbumiumEntitlements {
  AlbumiumEntitlements({
    CoverEntitlements? covers,
    FeatureEntitlements? features,
  }) : covers = covers ?? CoverEntitlements(),
       features = features ?? FeatureEntitlements();

  final CoverEntitlements covers;
  final FeatureEntitlements features;

  static AlbumiumEntitlements? _instance;

  static AlbumiumEntitlements get instance =>
      _instance ??= AlbumiumEntitlements();

  /// Installs the instance the app was started with.
  static void configure(AlbumiumEntitlements value) => _instance = value;

  /// Drops the shared instance so one test cannot inherit another's purchases.
  static void resetForTesting() => _instance = null;

  Future<void> initialize() =>
      Future.wait([covers.initialize(), features.initialize()]);
}
