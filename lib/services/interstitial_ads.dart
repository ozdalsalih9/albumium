import 'monetization_policy.dart';

/// Where a full-screen ad may appear.
///
/// Both are moments where the user has just finished something. Google's
/// policy forbids a full-screen ad in the middle of a task or at launch, and
/// an album half-made is exactly the task that must not be interrupted.
enum InterstitialPlacement {
  /// Leaving the editor, after the album is saved.
  editorExit,

  /// Closing the reader after looking through an album.
  previewExit,
}

/// Where a full-screen ad comes from.
///
/// The seam that keeps the ad SDK out of the screens, like [RewardedAdSource].
abstract class InterstitialAdSource {
  Future<void> show(InterstitialPlacement placement);
}

/// The source used where there is no ad SDK, and in every test.
class NoInterstitialAdSource implements InterstitialAdSource {
  const NoInterstitialAdSource();

  @override
  Future<void> show(InterstitialPlacement placement) async {}
}

/// Decides whether a full-screen ad may be shown right now.
///
/// A rewarded ad is asked for; a full-screen one is imposed. Without a limit
/// the app would interrupt someone who makes three albums in a row three
/// times, which is how an app earns a one-star review and, if Google reads it
/// as disruptive, an account strike.
class InterstitialCadence {
  InterstitialCadence({
    this.minimumGap = const Duration(minutes: 3),
    this.maximumPerSession = 4,
    this.skipFirst = true,
  });

  /// Quiet time after one has been shown.
  final Duration minimumGap;

  /// Nothing after this many in one run of the app.
  final int maximumPerSession;

  /// Whether the very first opportunity is let through without an ad.
  ///
  /// Someone who opens the app and leaves one album should not meet a
  /// full-screen ad on their way out; it reads as a toll on having used the
  /// app at all.
  final bool skipFirst;

  DateTime? _lastShown;
  int _shown = 0;
  int _opportunities = 0;

  int get shownThisSession => _shown;

  /// Call once at each natural break. True when an ad may be shown now.
  bool allow({DateTime? now}) {
    _opportunities++;
    if (skipFirst && _opportunities == 1) return false;
    if (_shown >= maximumPerSession) return false;
    final last = _lastShown;
    final moment = now ?? DateTime.now();
    if (last != null && moment.difference(last) < minimumGap) return false;
    _lastShown = moment;
    _shown++;
    return true;
  }

  void resetForTesting() {
    _lastShown = null;
    _shown = 0;
    _opportunities = 0;
  }
}

/// The full-screen ads the app is running with.
abstract final class InterstitialAds {
  static InterstitialAdSource _source = const NoInterstitialAdSource();
  static InterstitialCadence _cadence = InterstitialCadence();

  static InterstitialAdSource get source => _source;
  static InterstitialCadence get cadence => _cadence;

  static void configure(
    InterstitialAdSource value, {
    InterstitialCadence? cadence,
  }) {
    _source = value;
    if (cadence != null) _cadence = cadence;
  }

  static void resetForTesting() {
    _source = const NoInterstitialAdSource();
    _cadence = InterstitialCadence();
  }

  /// Shows one if the platform uses ads and the cadence allows it.
  ///
  /// Android sells these features instead, so it never reaches the ad.
  static Future<void> maybeShow(InterstitialPlacement placement) async {
    if (!MonetizationPolicy.rewardedOnly) return;
    if (!_cadence.allow()) return;
    await _source.show(placement);
  }
}
