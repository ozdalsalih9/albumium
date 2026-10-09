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

/// A banner sized to the screen it sits on.
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
  BannerAd? _ad;
  bool _loaded = false;
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
      final size =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
            MediaQuery.orientationOf(context),
            width,
          );
      if (size == null || !mounted) return;
      final ad = BannerAd(
        adUnitId: widget.unitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) setState(() => _loaded = false);
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
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
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
