import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../widgets/ad_banner.dart';
import 'ad_ids.dart';
import 'error_reporter.dart';
import 'interstitial_ads.dart';

/// The banner and full-screen implementations, the only other file besides
/// `google_rewarded_ad_source.dart` that touches the ad SDK.

/// Shows a full-screen ad through AdMob.
class GoogleInterstitialAdSource implements InterstitialAdSource {
  const GoogleInterstitialAdSource();

  @override
  Future<void> show(InterstitialPlacement placement) async {
    final unitId = AdIds.interstitialUnitId;
    if (unitId == null) return;
    final InterstitialAd ad;
    try {
      ad = await _load(unitId);
    } on _NoAd {
      // No fill is not a failure worth reporting: the user simply carries on.
      return;
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'InterstitialAd.load');
      return;
    }

    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    try {
      await ad.show();
      await closed.future;
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'InterstitialAd.show');
    }
  }

  Future<InterstitialAd> _load(String unitId) {
    final loaded = Completer<InterstitialAd>();
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.completeError(const _NoAd()),
      ),
    );
    return loaded.future;
  }
}

class _NoAd implements Exception {
  const _NoAd();
}

/// A banner sized to the ad inside it.
///
/// It reserves no space until an ad actually loads, so a screen never opens
/// with an empty grey strip where an ad might one day appear.
class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({required this.unitId});

  final String unitId;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  /// The tallest the strip may grow, in logical pixels.
  ///
  /// A ceiling, not a size: a shorter ad takes a shorter strip. Google would
  /// allow about 100 at the bottom of a phone screen, which is a third again
  /// as tall as this; the 320x100 class of ad is given up for the room, and
  /// most banner demand is 50 to 60 tall anyway.
  static const _maximumHeight = 80;

  BannerAd? _ad;
  AdSize? _filled;
  double? _requestedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_load());
  }

  Future<void> _load() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_requestedWidth == width.toDouble()) return;
    _requestedWidth = width.toDouble();
    try {
      final ad = BannerAd(
        adUnitId: widget.unitId,
        // Asked for as a ceiling rather than a fixed slot. A tall ad is still
        // allowed, but a shorter one comes back short instead of being
        // centred in a tall box with app background showing above and below
        // it. That background was the gap around the ad.
        size: AdSize.getInlineAdaptiveBannerAdSize(width, _maximumHeight),
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) async {
            // A ceiling says what was allowed, not what arrived; the height
            // actually filled is only known once the ad is there.
            final filled = await (ad as BannerAd).getPlatformAdSize();
            if (!mounted) return;
            setState(
              () => _filled =
                  filled ?? AdSize(width: width, height: _maximumHeight),
            );
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) setState(() => _filled = null);
          },
        ),
      );
      _ad?.dispose();
      _ad = ad;
      await ad.load();
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'BannerAd.load');
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final filled = _filled;
    if (ad == null || filled == null) return const SizedBox.shrink();
    return SizedBox(
      width: filled.width.toDouble(),
      height: filled.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

/// Installs both surfaces. Called once the SDK has started.
void configureAdSurfaces() {
  InterstitialAds.configure(const GoogleInterstitialAdSource());
  BannerAds.configure((context) {
    final unitId = AdIds.bannerUnitId;
    if (unitId == null) return null;
    return _AdaptiveBanner(unitId: unitId);
  });
}
